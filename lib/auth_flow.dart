import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'main.dart'; // kAccent, kBg, kCard, kMuted, kRed, kGreen, AppBackground, StorePage, sampleProducts, userRef

// ================================================================ AUTH HELPERS
/// Tahimik na guest sign-in para may user id agad ang cart/favorites habang nagba-browse.
Future<void> ensureGuest() async {
  final auth = FirebaseAuth.instance;
  if (auth.currentUser == null) await auth.signInAnonymously();
}

/// True kung naka-login na gamit ang totoong account (hindi guest)
bool get isLoggedIn {
  final u = FirebaseAuth.instance.currentUser;
  return u != null && !u.isAnonymous;
}

/// Kapag guest pa lang, ilalabas ang LoginPage. Ibabalik ang true kung naka-login na.
Future<bool> requireLogin(BuildContext context, {String? message}) async {
  if (isLoggedIn) return true;
  final ok = await Navigator.push<bool>(
    context,
    MaterialPageRoute(
      builder: (_) => LoginPage(message: message ?? 'Mag-login para ma-complete ang order mo'),
    ),
  );
  return ok == true && isLoggedIn;
}

String authErrorMessage(Object e) {
  if (e is FirebaseAuthException) {
    switch (e.code) {
      case 'invalid-email':
        return 'Mali ang format ng email.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Mali ang email o password.';
      case 'email-already-in-use':
      case 'credential-already-in-use':
        return 'Ginagamit na ang email na ito. Mag-login na lang.';
      case 'weak-password':
        return 'Masyadong madali ang password (minimum 6 characters).';
      case 'user-disabled':
        return 'Naka-disable ang account na ito.';
      case 'too-many-requests':
        return 'Masyadong maraming subok. Subukan ulit mamaya.';
      case 'network-request-failed':
        return 'Walang internet. I-check ang connection mo.';
      case 'operation-not-allowed':
        return 'Naka-off ang Email/Password sign-in sa Firebase Console. '
            '(Authentication > Sign-in method > Email/Password > Enable)';
      case 'provider-already-linked':
        return 'Naka-register na ang account na ito. Mag-login na lang.';
    }
    return '[${e.code}] ${e.message ?? ''}';
  }
  return '$e';
}

double _iv(double t, double a, double b, [Curve c = Curves.linear]) =>
    c.transform(((t - a) / (b - a)).clamp(0.0, 1.0).toDouble());

double _fr(double v) => v - v.floorToDouble();

// ================================================================ STARTUP GATE
/// Pagbukas ng app: 12-second intro animation (habang tahimik na nagsa-sign in bilang guest),
/// tapos diretso sa shop. Walang login dito.
class StartupGate extends StatefulWidget {
  /// true = walang intro (ginagamit pagka-logout)
  final bool skipIntro;
  const StartupGate({super.key, this.skipIntro = false});
  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  late bool _introDone = widget.skipIntro;
  bool _guestReady = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _signIn();
  }

  Future<void> _signIn() async {
    setState(() => _error = null);
    try {
      await ensureGuest();
      if (mounted) setState(() => _guestReady = true);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget child;
    if (_error != null) {
      child = Scaffold(key: const ValueKey('error'), body: AppBackground(child: _errorView()));
    } else if (_introDone && _guestReady) {
      child = const StorePage(key: ValueKey('store'));
    } else if (_introDone) {
      // tapos na ang animation pero hinihintay pa ang connection
      child = const Scaffold(
        key: ValueKey('wait'),
        body: AppBackground(child: Center(child: CircularProgressIndicator())),
      );
    } else {
      child = IntroSplash(
        key: const ValueKey('intro'),
        onDone: () {
          if (mounted) setState(() => _introDone = true);
        },
      );
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      switchInCurve: Curves.easeOutCubic,
      transitionBuilder: (c, anim) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(scale: Tween<double>(begin: 0.94, end: 1.0).animate(anim), child: c),
      ),
      child: child,
    );
  }

  Widget _errorView() => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off, size: 48, color: kMuted),
            const SizedBox(height: 12),
            Text(
              'Hindi makapag-connect.\n'
              'Siguraduhing naka-enable ang Anonymous sign-in sa Firebase Console '
              '(Authentication > Sign-in method) at may internet.\n\n$_error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: kMuted),
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: _signIn, child: const Text('Try again')),
          ]),
        ),
      );
}

// ================================================================ 12-SECOND INTRO
class IntroSplash extends StatefulWidget {
  final VoidCallback onDone;
  const IntroSplash({super.key, required this.onDone});
  @override
  State<IntroSplash> createState() => _IntroSplashState();
}

class _IntroSplashState extends State<IntroSplash> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 12));

  // Mga sapatos na iikot (kinukuha sa sampleProducts, mas maliit na size para mabilis mag-load)
  static const _innerPick = [0, 1, 3, 4, 8, 12, 13, 17];
  static const _outerPick = [2, 5, 6, 9, 10, 18];

  List<String> _urlsFor(List<int> pick) => [
        for (final i in pick)
          if (i < sampleProducts.length) (sampleProducts[i]['imageUrl'] as String).replaceAll('w=900', 'w=260'),
      ];
  late final List<String> _inner = _urlsFor(_innerPick);
  late final List<String> _outer = _urlsFor(_outerPick);

  // Mga lumulutang na props
  static const _fx = [
    Icons.bolt,
    Icons.star_rounded,
    Icons.local_fire_department,
    Icons.favorite,
    Icons.sell,
    Icons.emoji_events,
    Icons.shopping_bag,
    Icons.auto_awesome,
    Icons.celebration,
    Icons.rocket_launch,
    Icons.workspace_premium,
    Icons.thumb_up,
  ];
  static const _fxColors = [kAccent, Colors.amber, Colors.white, Colors.pinkAccent, Colors.cyanAccent];

  static const _chips = ['NEW', 'HOT', 'TRENDING', 'FREE DELIVERY'];
  static const _brands = ['NIKE', 'JORDAN', 'ADIDAS', 'VANS', 'CONVERSE', 'NEW BALANCE'];

  bool _precached = false;

  @override
  void initState() {
    super.initState();
    _c.forward().whenComplete(() {
      if (mounted) widget.onDone();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_precached) return;
    _precached = true;
    for (final u in [..._inner, ..._outer]) {
      precacheImage(NetworkImage(u), context, onError: (_, __) {});
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------ pieces
  Widget _prop(String url, double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: kCard,
          border: Border.all(color: kAccent, width: size > 56 ? 2.5 : 2),
          boxShadow: [BoxShadow(color: kAccent.withOpacity(.45), blurRadius: 18)],
        ),
        child: ClipOval(
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Center(child: Icon(Icons.directions_run, color: kAccent, size: size * .45)),
          ),
        ),
      );

  List<Widget> _stars(double t, Size s) => [
        for (int i = 0; i < 38; i++)
          () {
            final x = _fr(i * 0.754877666) * s.width;
            final y = _fr(i * 0.569840291) * s.height;
            final tw = 0.5 + 0.5 * math.sin(t * math.pi * 2 * (3 + i % 4) + i);
            final d = 1.5 + (i % 3) * 0.9;
            return Positioned(
              left: x,
              top: y,
              child: Opacity(
                opacity: (0.15 + 0.7 * tw).clamp(0.0, 1.0).toDouble(),
                child: Container(
                  width: d,
                  height: d,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                ),
              ),
            );
          }(),
      ];

  /// Meteor shower: bumabagsak pakaliwa-pababa
  List<Widget> _meteors(double t, Size s, double intro) => [
        for (int i = 0; i < 10; i++)
          () {
            final ph = ((t * 4.5) + i * 0.1) % 1.0;
            final len = 120.0 + (i % 3) * 55;
            final travel = s.height * 1.25;
            final x0 = _fr(i * 0.381966) * s.width * 1.3 + s.width * 0.15;
            final x = x0 - travel * 0.57 * ph;
            final y = -60 + travel * 0.82 * ph;
            final color = i % 3 == 0 ? kAccent : Colors.white;
            return Positioned(
              left: x,
              top: y,
              child: Opacity(
                opacity: (math.sin(math.pi * ph) * intro).clamp(0.0, 1.0).toDouble(),
                child: Transform.rotate(
                  angle: -0.96,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: len,
                    height: 3,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      gradient: LinearGradient(colors: [color, color.withOpacity(0.0)]),
                      boxShadow: [BoxShadow(color: color.withOpacity(.6), blurRadius: 8)],
                    ),
                  ),
                ),
              ),
            );
          }(),
      ];

  /// Lumalaking singsing mula sa logo
  List<Widget> _rings(double t, double glow, double exit) => [
        for (int i = 0; i < 3; i++)
          () {
            final ph = ((t * 1.6) + i / 3) % 1.0;
            final d = 130 + 380 * ph;
            final op = ((1 - ph) * .5 * glow * (1 - exit)).clamp(0.0, 1.0).toDouble();
            return Container(
              width: d,
              height: d,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: kAccent.withOpacity(op), width: 2),
              ),
            );
          }(),
      ];

  /// Mga icon na pumapailanlang (apoy, bituin, kidlat, puso...)
  List<Widget> _floaters(double t, Size s, double intro) => [
        for (int i = 0; i < _fx.length; i++)
          () {
            final ph = ((t * 1.4) + i * 0.083) % 1.0;
            final baseX = 24 + _fr(i * 0.618034 + 0.13) * (s.width - 48);
            final x = baseX + math.sin(t * math.pi * 2 * 3 + i) * 16;
            final y = s.height * (1.05 - 1.15 * ph);
            final col = _fxColors[i % _fxColors.length];
            return Positioned(
              left: x,
              top: y,
              child: Opacity(
                opacity: (math.sin(math.pi * ph) * .85 * intro).clamp(0.0, 1.0).toDouble(),
                child: Transform.rotate(
                  angle: math.sin(t * math.pi * 2 * 2 + i) * 0.6,
                  child: Icon(_fx[i], size: 20 + (i % 3) * 6.0, color: col),
                ),
              ),
            );
          }(),
      ];

  /// Confetti na sumasabog palabas at bumabagsak
  List<Widget> _confetti(Offset c, double p, int seed) {
    if (p <= 0 || p >= 1) return const <Widget>[];
    const colors = [kAccent, Colors.amber, Colors.white, Colors.pinkAccent, Colors.cyanAccent, kGreen];
    return [
      for (int i = 0; i < 30; i++)
        () {
          final a = 2 * math.pi * i / 30 + seed;
          final sp = 130.0 + ((i * 7 + seed) % 6) * 45;
          final dx = math.cos(a) * sp * p;
          final dy = math.sin(a) * sp * p + 260 * p * p;
          return Positioned(
            left: c.dx + dx - 4,
            top: c.dy + dy - 7,
            child: Opacity(
              opacity: (1 - p).clamp(0.0, 1.0).toDouble(),
              child: Transform.rotate(
                angle: i + p * 12,
                child: Container(
                  width: 8,
                  height: 14,
                  decoration: BoxDecoration(color: colors[i % colors.length], borderRadius: BorderRadius.circular(2)),
                ),
              ),
            ),
          );
        }(),
    ];
  }

  /// Mga "pop" na badge sa paligid ng logo
  List<Widget> _chipWidgets(double t, Size s, double exit) {
    final c = Offset(s.width / 2, s.height * 0.325);
    final ox = math.min(s.width * 0.30, 200.0);
    final oy = math.min(s.height * 0.15, 120.0);
    const dxs = [-1.0, 1.0, -1.05, 1.0];
    const dys = [-1.25, -0.8, 1.2, 1.3];
    const rots = [-0.2, 0.18, 0.15, -0.12];
    const bgs = [kAccent, Colors.white, kRed, kGreen];
    return [
      for (int i = 0; i < _chips.length; i++)
        () {
          final start = 0.34 + i * 0.06;
          final pop = _iv(t, start, start + 0.12, Curves.elasticOut);
          final bob = math.sin(t * math.pi * 2 * 4 + i) * 5;
          final op = (pop.clamp(0.0, 1.0).toDouble() * (1 - exit)).clamp(0.0, 1.0).toDouble();
          return Positioned(
            left: c.dx + dxs[i] * ox,
            top: c.dy + dys[i] * oy + bob,
            child: FractionalTranslation(
              translation: const Offset(-0.5, -0.5),
              child: Opacity(
                opacity: op,
                child: Transform.rotate(
                  angle: rots[i] + math.sin(t * math.pi * 2 * 3 + i) * 0.05,
                  child: Transform.scale(
                    scale: pop.clamp(0.0, 1.4).toDouble(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: bgs[i],
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: bgs[i].withOpacity(.55), blurRadius: 14)],
                      ),
                      child: Text(
                        _chips[i],
                        style: TextStyle(
                          color: bgs[i] == kRed ? Colors.white : Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }(),
    ];
  }

  Widget _brandRow(double t) => Wrap(
        alignment: WrapAlignment.center,
        spacing: 14,
        runSpacing: 6,
        children: [
          for (int i = 0; i < _brands.length; i++)
            () {
              final p = _iv(t, 0.42 + i * 0.06, 0.52 + i * 0.06, Curves.easeOut);
              return Opacity(
                opacity: p,
                child: Transform.translate(
                  offset: Offset(0, 10 * (1 - p)),
                  child: Text(
                    _brands[i],
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2),
                  ),
                ),
              );
            }(),
        ],
      );

  /// Tumatakbong sapatos sa ibaba na may trail
  Widget _runner(double t, Size s) {
    final p = _iv(t, 0.50, 0.90, Curves.easeInOut);
    final x = -90 + (s.width + 180) * p;
    final vis = math.sin(math.pi * p).clamp(0.0, 1.0).toDouble();
    final hop = (math.sin(t * math.pi * 2 * 14)).abs() * 8;
    final trackOp = (_iv(t, 0.45, 0.55) * .18 * (1 - _iv(t, 0.9, 0.96))).clamp(0.0, 1.0).toDouble();
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          left: 24,
          right: 24,
          bottom: 34,
          child: Opacity(opacity: trackOp, child: Container(height: 2, color: Colors.white)),
        ),
        Positioned(
          left: x,
          bottom: 36 + hop,
          child: Opacity(
            opacity: vis,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final wd in const [34.0, 24.0, 14.0])
                  Container(
                    width: wd,
                    height: 3,
                    margin: const EdgeInsets.only(right: 4, top: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      gradient: const LinearGradient(colors: [Colors.transparent, kAccent]),
                    ),
                  ),
                const Icon(Icons.directions_run, color: kAccent, size: 34),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------ scene
  Widget _scene(BuildContext context, double t) {
    final s = MediaQuery.of(context).size;
    final w = s.width, h = s.height;

    final fadeOut = (1 - _iv(t, 0.95, 1.0)).clamp(0.0, 1.0).toDouble();
    final glow = _iv(t, 0.0, 0.1, Curves.easeOut);
    final pulse = 1 + 0.06 * math.sin(t * math.pi * 24) * glow;
    final logoIn = _iv(t, 0.0, 0.09, Curves.easeOutBack);
    final exit = _iv(t, 0.86, 0.96, Curves.easeInCubic);
    final intro = _iv(t, 0.0, 0.08);

    // ---------- logo
    final logo = Transform.scale(
      scale: logoIn.clamp(0.0, 1.2).toDouble() * pulse,
      child: SizedBox(
        width: 128,
        height: 128,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.rotate(
              angle: t * math.pi * 12,
              child: Container(
                width: 128,
                height: 128,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(colors: [Colors.transparent, kAccent]),
                ),
              ),
            ),
            Container(
              width: 108,
              height: 108,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kAccent,
                boxShadow: [BoxShadow(color: kAccent.withOpacity(.6), blurRadius: 36, spreadRadius: 2)],
              ),
              child: Transform.rotate(
                angle: -0.25 + 0.1 * math.sin(t * math.pi * 12),
                child: const Icon(Icons.directions_run, size: 62, color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );

    // ---------- umiikot na sapatos: panloob (pakanan) at panlabas (pakaliwa)
    final rx = math.min(w * 0.38, 170.0);
    final ry = math.min(h * 0.15, 120.0);
    final rx2 = math.min(rx * 1.45, w * 0.5 - 30);
    final ry2 = ry * 1.35;
    final ni = _inner.length, no = _outer.length;

    final orbit = <MapEntry<double, Widget>>[
      for (int i = 0; i < ni; i++)
        () {
          final enter = _iv(t, 0.04 + i * 0.025, 0.24 + i * 0.025, Curves.easeOutBack);
          final ang = 2 * math.pi * i / ni + t * 2 * math.pi * 1.5;
          final rad = (2.8 - 1.8 * enter) + 1.8 * exit;
          final depth = (math.sin(ang) + 1) / 2;
          final dx = math.cos(ang) * rx * rad;
          final dy = math.sin(ang) * ry * rad + math.sin(t * math.pi * 10 + i) * 6;
          final sc = (0.7 + 0.4 * depth) * enter.clamp(0.0, 1.15).toDouble();
          final op = (enter.clamp(0.0, 1.0).toDouble() * (1 - exit) * (0.4 + 0.6 * depth)).clamp(0.0, 1.0).toDouble();
          return MapEntry(
            depth,
            Opacity(
              opacity: op,
              child: Transform.translate(
                offset: Offset(dx, dy),
                child: Transform.rotate(
                  angle: math.sin(t * math.pi * 6 + i) * 0.3,
                  child: Transform.scale(scale: sc, child: _prop(_inner[i], 66)),
                ),
              ),
            ),
          );
        }(),
      for (int i = 0; i < no; i++)
        () {
          final enter = _iv(t, 0.14 + i * 0.025, 0.34 + i * 0.025, Curves.easeOutBack);
          final ang = 2 * math.pi * i / no - t * 2 * math.pi * 1.0 + math.pi / no;
          final rad = (2.4 - 1.4 * enter) + 1.8 * exit;
          final depth = (math.sin(ang) + 1) / 2;
          final dx = math.cos(ang) * rx2 * rad;
          final dy = math.sin(ang) * ry2 * rad + math.sin(t * math.pi * 8 + i * 2) * 5;
          final sc = (0.65 + 0.35 * depth) * enter.clamp(0.0, 1.15).toDouble();
          final op = (enter.clamp(0.0, 1.0).toDouble() * (1 - exit) * (0.3 + 0.55 * depth)).clamp(0.0, 1.0).toDouble();
          return MapEntry(
            depth,
            Opacity(
              opacity: op,
              child: Transform.translate(
                offset: Offset(dx, dy),
                child: Transform.rotate(
                  angle: math.sin(t * math.pi * 5 + i) * 0.35,
                  child: Transform.scale(scale: sc, child: _prop(_outer[i], 48)),
                ),
              ),
            ),
          );
        }(),
      MapEntry(0.5, logo),
    ]..sort((a, b) => a.key.compareTo(b.key));

    // ---------- SNEAKERS letters + shimmer
    const word = 'SNEAKERS';
    final letters = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < word.length; i++)
          () {
            final start = 0.10 + i * 0.02;
            final raw = _iv(t, start, start + 0.12, Curves.easeOutBack);
            final op = _iv(t, start, start + 0.05);
            final fromTop = i.isEven;
            return Opacity(
              opacity: op,
              child: Transform.translate(
                offset: Offset(0, (fromTop ? -80 : 80) * (1 - raw)),
                child: Transform.rotate(
                  angle: (fromTop ? -0.6 : 0.6) * (1 - raw),
                  child: Transform.scale(
                    scale: (0.3 + 0.7 * raw).clamp(0.0, 1.4).toDouble(),
                    child: Text(
                      word[i],
                      style: const TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }(),
      ],
    );
    double st(double v) => v.clamp(0.0, 1.0).toDouble();
    final sh = -0.3 + 1.6 * ((t * 4) % 1.0);
    final shimmerWord = ShaderMask(
      shaderCallback: (r) => LinearGradient(
        colors: const [Colors.white, kAccent, Colors.white],
        stops: [st(sh - 0.15), st(sh), st(sh + 0.15)],
      ).createShader(r),
      blendMode: BlendMode.srcIn,
      child: letters,
    );
    final tag = _iv(t, 0.28, 0.40, Curves.easeOut);

    return Opacity(
      opacity: fadeOut,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ilaw sa likod
          Align(
            alignment: const Alignment(0, -0.35),
            child: Container(
              width: 420 * glow * pulse,
              height: 420 * glow * pulse,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [kAccent.withOpacity(.28 * glow), Colors.transparent]),
              ),
            ),
          ),
                    ..._stars(t, s),
          ..._meteors(t, s, intro),
          ..._floaters(t, s, intro),
          Align(
            alignment: const Alignment(0, -0.35),
            child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: _rings(t, glow, exit)),
          ),
          // orbit ng sapatos + logo
          Align(
            alignment: const Alignment(0, -0.35),
            child: SizedBox(
              width: 10,
              height: 10,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [for (final e in orbit) e.value],
              ),
            ),
          ),
                   ..._chipWidgets(t, s, exit),
          ..._confetti(Offset(w / 2, h * 0.325), _iv(t, 0.30, 0.50), 1),
          ..._confetti(Offset(w / 2, h * 0.325), _iv(t, 0.70, 0.90), 3),
          // pangalan at brands (walang loading bar)
          Align(
            alignment: const Alignment(0, 0.46),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    shimmerWord,
                    const SizedBox(height: 10),
                    Opacity(
                      opacity: tag,
                      child: Text(
                        'STEP INTO STYLE',
                        style: TextStyle(
                          color: kMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 7 - 4 * tag,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _brandRow(t),
                  ],
                ),
              ),
            ),
          ),
          _runner(t, s),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => _scene(context, _c.value),
        ),
      ),
    );
  }
}

// ================================================================ LOGIN / REGISTER
/// Lalabas lang kapag kailangan (checkout o menu). Ibinabalik ang `true` kapag nakapag-login na.
class LoginPage extends StatefulWidget {
  final String message;
  const LoginPage({super.key, this.message = 'Mag-login para ma-complete ang order mo'});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passFocus = FocusNode();
  bool _register = false;
  bool _hide = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  /// Malinaw na style para siguradong nakikita ang tina-type (puti sa dark navy)
  static const _fieldStyle = TextStyle(color: Colors.white, fontSize: 16);

  /// Register: ginagawang totoong account ang guest, kaya hindi nawawala ang bag at favorites.
  Future<void> _registerAccount(String email, String pass, String name) async {
    final auth = FirebaseAuth.instance;
    final cur = auth.currentUser;
    final UserCredential cred;
    if (cur != null && cur.isAnonymous) {
      cred = await cur.linkWithCredential(EmailAuthProvider.credential(email: email, password: pass));
    } else {
      cred = await auth.createUserWithEmailAndPassword(email: email, password: pass);
    }
    try {
      await cred.user?.updateDisplayName(name);
      await cred.user?.reload();
    } catch (e) {
      debugPrint('updateDisplayName error: $e');
    }
  }

  /// Login sa dati nang account: inililipat ang laman ng guest bag/favorites sa account.
  Future<void> _signInKeepingBag(String email, String pass) async {
    final auth = FirebaseAuth.instance;
    final guest = auth.currentUser;
    final guestUid = (guest != null && guest.isAnonymous) ? guest.uid : null;
    List<QueryDocumentSnapshot<Map<String, dynamic>>> cart = [], favs = [];
    if (guestUid != null) {
      try {
        cart = (await userRef.collection('cart').get()).docs;
        favs = (await userRef.collection('favorites').get()).docs;
      } catch (_) {}
    }
    await auth.signInWithEmailAndPassword(email: email, password: pass);
    final me = auth.currentUser;
    if (me == null || guestUid == null || me.uid == guestUid || (cart.isEmpty && favs.isEmpty)) return;
    try {
      final db = FirebaseFirestore.instance;
      final mine = db.collection('users').doc(me.uid);
      final batch = db.batch();
      for (final d in cart) {
        final data = d.data();
        batch.set(
          mine.collection('cart').doc(d.id),
          {...data, 'qty': FieldValue.increment((data['qty'] as num?)?.toInt() ?? 1)},
          SetOptions(merge: true),
        );
      }
      for (final d in favs) {
        batch.set(mine.collection('favorites').doc(d.id), d.data());
      }
      await batch.commit();
    } catch (_) {}
  }

  Future<void> _submit() async {
    if (_loading) return;
    final email = _email.text.trim();
    final pass = _password.text;
    final name = _name.text.trim();
    if (email.isEmpty || pass.isEmpty || (_register && name.isEmpty)) {
      setState(() => _error = 'Kumpletuhin ang lahat ng fields.');
      return;
    }
    if (_register && pass.length < 6) {
      setState(() => _error = 'Ang password ay dapat 6 characters o higit pa.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_register) {
        await _registerAccount(email, pass, name);
      } else {
        await _signInKeepingBag(email, pass);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e, st) {
      debugPrint('AUTH ERROR: $e');
      debugPrint('$st');
      if (mounted) setState(() => _error = authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgot() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Ilagay muna ang email mo, tapos pindutin ulit.');
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nag-send na ng reset link sa email mo')));
    } catch (e) {
      debugPrint('RESET ERROR: $e');
      if (mounted) setState(() => _error = authErrorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_register ? 'Register' : 'Log in')),
      body: AppBackground(
        // Material para siguradong gumagana ang TextField (ink, selection, cursor)
        child: Material(
          type: MaterialType.transparency,
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: kAccent,
                            boxShadow: [BoxShadow(color: kAccent.withOpacity(.5), blurRadius: 30)],
                          ),
                          child: const Icon(Icons.directions_run, size: 40, color: Colors.black),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Center(
                        child: Text('SNEAKERS',
                            style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                letterSpacing: 2,
                                color: Colors.white)),
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: Text(widget.message, textAlign: TextAlign.center, style: const TextStyle(color: kMuted)),
                      ),
                      const SizedBox(height: 28),
                      if (_register) ...[
                        TextField(
                          controller: _name,
                          focusNode: _nameFocus,
                          enabled: !_loading,
                          style: _fieldStyle,
                          cursorColor: kAccent,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) => _emailFocus.requestFocus(),
                          decoration: const InputDecoration(
                            labelText: 'Full name',
                            labelStyle: TextStyle(color: kMuted),
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextField(
                        controller: _email,
                        focusNode: _emailFocus,
                        enabled: !_loading,
                        style: _fieldStyle,
                        cursorColor: kAccent,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        enableSuggestions: false,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => _passFocus.requestFocus(),
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          labelStyle: TextStyle(color: kMuted),
                          prefixIcon: Icon(Icons.mail_outline),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _password,
                        focusNode: _passFocus,
                        enabled: !_loading,
                        style: _fieldStyle,
                        cursorColor: kAccent,
                        obscureText: _hide,
                        autocorrect: false,
                        enableSuggestions: false,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: const TextStyle(color: kMuted),
                          helperText: _register ? 'Minimum 6 characters' : null,
                          helperStyle: const TextStyle(color: kMuted),
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_hide ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                            onPressed: () => setState(() => _hide = !_hide),
                          ),
                        ),
                      ),
                      if (!_register)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _forgot,
                            child: const Text('Forgot password?', style: TextStyle(color: kMuted)),
                          ),
                        ),
                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent)),
                      ],
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _loading ? null : _submit,
                        child: _loading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                            : Text(_register ? 'Create account' : 'Log in'),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _loading
                            ? null
                            : () => setState(() {
                                  _register = !_register;
                                  _error = null;
                                }),
                        child: Text(
                          _register ? 'May account na? Log in' : 'Wala pang account? Mag-register',
                          style: const TextStyle(color: kAccent, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}