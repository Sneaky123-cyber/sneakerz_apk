const { onCall, onRequest, HttpsError } = require('firebase-functions/v2/https');
const { defineSecret, defineString } = require('firebase-functions/params');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();

const XENDIT_KEY = defineSecret('XENDIT_SECRET_KEY');
const CALLBACK_TOKEN = defineSecret('XENDIT_CALLBACK_TOKEN');
// URL ng app mo (kung saan babalik ang customer pagkatapos magbayad)
const APP_URL = defineString('APP_URL', { default:'https://bmd-finals-project.web.app' });

// Walang card. E-wallet at QR Ph lang. (Dapat naka-activate ang mga ito sa Xendit dashboard mo)
const PAYMENT_METHODS = ['GCASH', 'PAYMAYA', 'GRABPAY', 'SHOPEEPAY', 'QRPH'];

const SEP = '__';

/** Gumagawa ng Xendit invoice para sa isang order. Ang halaga ay kinukuha sa Firestore, hindi sa app. */
exports.createXenditInvoice = onCall({ secrets: [XENDIT_KEY] }, async (req) => {
  const uid = req.auth && req.auth.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Mag-login muna.');
  const orderId = req.data && req.data.orderId;
  if (!orderId || typeof orderId !== 'string') throw new HttpsError('invalid-argument', 'Walang orderId.');

  const ref = db.collection('users').doc(uid).collection('orders').doc(orderId);
  const snap = await ref.get();
  if (!snap.exists) throw new HttpsError('not-found', 'Hindi mahanap ang order.');
  const o = snap.data();
  if (o.status !== 'Awaiting Payment') throw new HttpsError('failed-precondition', 'Hindi na ito puwedeng bayaran.');
  if (o.invoiceUrl) return { invoiceUrl: o.invoiceUrl }; // gamitin ulit kung meron na

  const body = {
    external_id: `${uid}${SEP}${orderId}`,
    amount: o.total,
    currency: 'PHP',
    description: `SNEAKERS order ${orderId}`,
    ...(o.email && o.email.trim() ? { payer_email: o.email.trim() } : {}),
    invoice_duration: 86400, // 24 oras
    payment_methods: PAYMENT_METHODS,
    success_redirect_url: `${APP_URL.value()}/?paid=1`,
    failure_redirect_url: `${APP_URL.value()}/?paid=0`,
    items: (o.items || []).map((i) => ({
      name: String(i.name || 'Sneakers'),
      quantity: Number(i.qty || 1),
      price: Number(i.price || 0),
    })),
    fees: [{ type: 'SHIPPING', value: o.shipping || 0 }],
  };

  const auth = Buffer.from(`${XENDIT_KEY.value()}:`).toString('base64');
  const res = await fetch('https://api.xendit.co/v2/invoices', {
    method: 'POST',
    headers: { Authorization: `Basic ${auth}`, 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  const json = await res.json();
  if (!res.ok) {
    console.error('Xendit error', json);
    throw new HttpsError('internal', json.message || 'Nabigo ang Xendit.');
  }
  await ref.update({ invoiceId: json.id, invoiceUrl: json.invoice_url });
  return { invoiceUrl: json.invoice_url };
});

/** Webhook ng Xendit. Ilagay ang URL nito sa Xendit Dashboard > Settings > Webhooks > Invoices paid + expired. */
exports.xenditWebhook = onRequest({ secrets: [CALLBACK_TOKEN] }, async (req, res) => {
  if (req.method !== 'POST') return res.status(405).send('POST only');
  if (req.get('x-callback-token') !== CALLBACK_TOKEN.value()) return res.status(401).send('Invalid token');

  const { external_id, status, payment_channel, payment_method } = req.body || {};
  const parts = String(external_id || '').split(SEP);
  if (parts.length !== 2) return res.status(200).send('ignored');
  const [uid, orderId] = parts;
  const ref = db.collection('users').doc(uid).collection('orders').doc(orderId);

  try {
    if (status === 'PAID' || status === 'SETTLED') {
      await db.runTransaction(async (tx) => {
        const s = await tx.get(ref);
        if (!s.exists || s.data().status === 'Paid') return;
        tx.update(ref, {
          status: 'Paid',
          paidAt: admin.firestore.FieldValue.serverTimestamp(),
          paymentChannel: payment_channel || payment_method || '',
        });
      });
    } else if (status === 'EXPIRED') {
      // Hindi nabayaran: ibalik ang stock
      await db.runTransaction(async (tx) => {
        const s = await tx.get(ref);
        if (!s.exists || s.data().status !== 'Awaiting Payment') return;
        const need = {};
        for (const i of s.data().items || []) {
          need[i.productId] = (need[i.productId] || 0) + Number(i.qty || 0);
        }
        const pRefs = Object.keys(need).map((id) => db.collection('products').doc(id));
        const pSnaps = await Promise.all(pRefs.map((r) => tx.get(r)));
        pSnaps.forEach((ps) => {
          if (ps.exists) tx.update(ps.ref, { stock: (ps.data().stock || 0) + need[ps.id] });
        });
        tx.update(ref, { status: 'Expired' });
      });
    }
    return res.status(200).send('ok');
  } catch (e) {
    console.error(e);
    return res.status(500).send('error');
  }
});