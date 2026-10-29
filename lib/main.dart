import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:webview_flutter/webview_flutter.dart';
import 'auth_flow.dart';
import 'firebase_options.dart';
import 'xendit_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    // Guest session: provides a Firebase UID for the cart and orders even without logging in.
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
    runApp(const SneakersApp());
  } catch (e) {
    runApp(MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Firebase error:\n$e', style: const TextStyle(color: Colors.redAccent)),
          ),
        ),
      ),
    ));
  }
}

// ================================================================ COLORS
const kNavy = Color(0xFF0B2250);
const kNavy2 = Color(0xFF12306E);
const kDeepNavy = Color(0xFF081A40);
const kBlue = Color(0xFF1E6BFF);
const kOrange = Color(0xFFFF7A1A);
const kLight = Color(0xFFF3F6FB);
const kLine = Color(0xFFD9E0EE);
const kText = Color(0xFF14213D);
const kSoft = Color(0xFF5B6781);
const kImgBg = Color(0xFFE6EDFB);
const kStockGreen = Color(0xFF12875A);
const kAmber = Color(0xFFD98200);
const kSoldOut = Color(0xFFE03B3B);
const kPaleBlue = Color(0xFFC9D7F5);

// Used by auth_flow.dart (intro and login = dark navy)
const kBg = Color(0xFF07122B);
const kSurface = Color(0xFF0F1F47);
const kCard = Color(0xFF14285A);
const kAccent = kOrange;
const kMuted = Color(0xFF9FB0D3);
const kRed = Color(0xFFFF5A36);
const kGreen = Color(0xFF2ED573);

const int kShipping = 99;
const Map<String, double> kDiscountCodes = {'SNEAK10': 0.10};
const String kPhone = '09817369646';
const String kFacebook = 'https://www.facebook.com/joshua.menor.958891/';

// ---------------- PAYMENT METHODS
const String kPayCod = 'Cash on Delivery';
const String kPayGcash = 'GCash';
const String kPayMaya = 'Maya';
const String kPayXendit = 'Xendit';
// REPLACE with your store's real GCash number and name
const String kGcashNumber = '09817369646';
const String kGcashName = 'SNEAKERS (Joshua M.)';

// REPLACE with your store's real Maya number and name
const String kMayaNumber = '09817369646';
const String kMayaName = 'SNEAKERS (Joshua M.)';

// QR code images (save a screenshot of the QR from your GCash/Maya app in the assets/ folder).
// If the file is missing, the app generates a QR code from the number.
const String kGcashQrAsset = 'assets/gcash_qr.png';
const String kMayaQrAsset = 'assets/maya_qr.png';

String unsplash(String id, {int w = 900}) =>
    'https://images.unsplash.com/photo-$id?auto=format&fit=crop&w=$w&q=80';

final String heroImage = unsplash('1542291026-7eec264c27ff');

List<int> _r(int a, int b) => [for (var i = a; i <= b; i++) i];

Map<String, dynamic> _s(String name, String brand, String category, String gender, int price, int stock,
        List<int> sizes, String img, String description,
        {bool isNew = false, bool sale = false, bool trending = false}) =>
    {
      'name': name,
      'brand': brand,
      'category': category,
      'gender': gender,
      'price': price,
      'stock': stock,
      'sizes': sizes,
      'imageUrl': unsplash(img),
      'description': description,
      'isNew': isNew,
      'sale': sale,
      'trending': trending,
    };

final List<Map<String, dynamic>> sampleProducts = [
 _s('Nike Star Runner 5', 'Nike', 'Lifestyle', 'Women', 5000, 12, _r(5, 10), 'https://static.nike.com/....png',
    'Short description here.',
    isNew: true, trending: true),

  _s('Air Force 1 High', 'Nike', 'Lifestyle', 'Men', 7995, 12, _r(7, 13), '1595950653106-6c9ebd614d3a',
      'Classic high-top with a clean leather look. Perfect for everyday wear and goes with any outfit.',
      isNew: true, trending: true),
  _s('Air Jordan 1', 'Nike', 'Jordan', 'Men', 10295, 8, _r(8, 13), '1628413993904-94ecb60f1239',
      'Iconic Jordan silhouette loved by sneakerheads. Durable and comfortable.',
      isNew: true, trending: true),
  _s('Air Force 1 \'07', 'Nike', 'Lifestyle', 'Unisex', 7595, 25, _r(5, 11), '1712167631738-4dab9e53c853',
      'White low-top with a cushioned sole. Timeless style.',
      sale: true),
  _s('Street Runner Red', 'Nike', 'Running', 'Men', 6195, 9, _r(7, 12), '1542291026-7eec264c27ff',
      'Bold red color and a lightweight feel. Made for the run and for the street.',
      isNew: true, trending: true),
  _s('Runner White / Red', 'Nike', 'Running', 'Women', 6895, 8, _r(5, 10), '1600185365483-26d7a4cc7519',
      'Lightweight running shoe with a breathable upper and a soft sole.',
      isNew: true),
  _s('High-Top Court White', 'Nike', 'Basketball', 'Men', 5495, 15, _r(8, 13), '1512374382149-233c42b6a83b',
      'High-top with ankle support. Great on the court and outside.',
      sale: true),
  _s('Training Pro Black / White', 'Nike', 'Training & Gym', 'Men', 4995, 6, _r(6, 12), '1605408499391-6368c628ef42',
      'Stable and comfortable for the gym and workouts. Firm grip on the floor.'),
  _s('Street Low Black / Red', 'Nike', 'Skateboarding', 'Men', 5295, 20, _r(7, 12), '1615290642882-6b9501729a27',
      'Durable low-top for skating and everyday wear. Has grip and padding.'),
  _s('Chuck Taylor All Star High - Black', 'Converse', 'Lifestyle', 'Unisex', 3495, 30, _r(5, 12),
      '1565379793984-e65b51b33b37', 'The classic canvas high-top. Simple, lightweight and always in style.'),
  _s('Chuck Taylor All Star High - White', 'Converse', 'Lifestyle', 'Unisex', 3495, 4, _r(5, 11),
      '1528111610157-f0553810b46f', 'White canvas high-top that suits a casual look.',
      isNew: true),
  _s('Chuck Taylor All Star High - Gray', 'Converse', 'Lifestyle', 'Unisex', 3695, 18, _r(6, 11),
      '1578269174279-27814d45033f', 'Gray canvas high-top. A neutral color that is easy to match.',
      sale: true),
  _s('Chuck Taylor All Star - Blue', 'Converse', 'Lifestyle', 'Women', 3495, 7, _r(5, 10), '1641822841761-c1cb29e19420',
      'Blue canvas that adds a pop of color to your outfit.',
      isNew: true),
  _s('Air Jordan 1 Black / Red', 'Jordan', 'Jordan', 'Men', 10995, 6, _r(8, 13), '1552346154-21d32810aba3',
      'Black, white and red colorway of the classic Jordan 1. Always sought after by collectors.',
      isNew: true, trending: true),
  _s('Trail Runner Green / Black', 'Nike', 'Running', 'Men', 6495, 22, _r(7, 12), '1606107557195-0e29a4b5b4aa',
      'Bold green and black running shoe. Strong grip and lightweight.',
      isNew: true),
  _s('Gray Runner', 'Nike', 'Running', 'Unisex', 5995, 9, _r(5, 12), '1491553895911-0055eca6402d',
      'Simple gray running shoe that is perfect for daily runs.'),
  _s('Street Brown', 'Nike', 'Lifestyle', 'Men', 6295, 10, _r(7, 12), '1549298916-b41d501d3772',
      'Brown sneaker with a retro vibe. Pairs well with denim and a casual look.',
      sale: true),
  _s('Court Classic White / Red', 'Nike', 'Basketball', 'Men', 5795, 14, _r(8, 12), '1608667508764-33cf0726b13a',
      'White and red court shoe with great cushioning for the game.',
      isNew: true),
  _s('Air Force 1 Low White', 'Nike', 'Lifestyle', 'Women', 6995, 6, _r(5, 12), '1579338559194-a162d19bf842',
      'White low-top that never goes out of style. Easy to match with anything.',
      trending: true),
  _s('Adidas Runner Blue / White', 'Adidas', 'Running', 'Women', 5495, 11, _r(5, 10), '1571008887538-b36bb32f4571',
      'Blue and white running shoe that is lightweight and comfortable on long runs.',
      isNew: true, trending: true),
  _s('Adidas Athletic Black / Yellow', 'Adidas', 'Training & Gym', 'Men', 4995, 27, _r(7, 13),
      '1586091827070-ec6c37793c49', 'Black and yellow athletic shoe for the gym, training and everyday wear.'),
  _s('Vans Low-Top Pink', 'Vans', 'Skateboarding', 'Women', 3295, 8, _r(5, 10), '1501580979865-c37d96d28bba',
      'Pink low-top with a flat sole. Great for skating and for style.',
      isNew: true),
  _s('Vans Authentic', 'Vans', 'Skateboarding', 'Unisex', 2995, 16, _r(6, 11), '1553521014-3a56a6964ffe',
      'Simple canvas low-top. Lightweight, easy to wear and always popular on the street.',
      sale: true),
  _s('New Balance Classic Pink / Gray', 'New Balance', 'Lifestyle', 'Women', 5995, 10, _r(5, 11),
      '1551107696-a4b0c5a0d9a2', 'Retro silhouette in pink, gray and white. Comfortable all day long.',
      isNew: true),
  _s('Chuck Taylor Kids - Blue', 'Converse', 'Lifestyle', 'Kids', 2495, 12, _r(1, 5), '1641822841761-c1cb29e19420',
      'Blue canvas for kids. Easy to put on and lightweight.',
      isNew: true),
  _s('Mini Runner White / Blue', 'Adidas', 'Running', 'Kids', 2995, 8, _r(1, 5), '1571008887538-b36bb32f4571',
      'Running shoes for kids. Lightweight and comfortable for play.'),
  // ---------------- Added: Football
  _s('Striker Pro Red', 'Nike', 'Football', 'Men', 8495, 9, _r(6, 12), '1542291026-7eec264c27ff',
      'Red football boots built for speed. Studs give firm grip on the grass.',
      isNew: true, trending: true),
  _s('Predator Turf Black / Yellow', 'Adidas', 'Football', 'Men', 7995, 11, _r(6, 12), '1586091827070-ec6c37793c49',
      'Black and yellow turf shoes for fast games on artificial grass.'),
  _s('Futsal Court White / Blue', 'Adidas', 'Football', 'Unisex', 4995, 14, _r(5, 11), '1571008887538-b36bb32f4571',
      'Flat sole for futsal and indoor courts. Lightweight and gives good ball control.',
      sale: true),
  _s('Pitch Lite Gray', 'Puma', 'Football', 'Women', 5995, 7, _r(5, 10), '1491553895911-0055eca6402d',
      'Lightweight gray football shoes that stay comfortable the whole game.',
      isNew: true),
  _s('Mini Striker Red', 'Nike', 'Football', 'Kids', 2995, 10, _r(1, 5), '1542291026-7eec264c27ff',
      'Kids\' football shoes that are lightweight and durable for outdoor play.'),
  // ---------------- Added: Basketball
  _s('Court Jordan Mid Black / Red', 'Jordan', 'Basketball', 'Men', 9495, 8, _r(8, 13), '1552346154-21d32810aba3',
      'Mid-top with cushioning and ankle support for fast-paced games.',
      isNew: true),
  _s('Hoops Low Blue / White', 'Adidas', 'Basketball', 'Men', 5295, 13, _r(7, 12), '1571008887538-b36bb32f4571',
      'Low-top court shoes that are lightweight and easy to move in.',
      sale: true),
  _s('Court Gray High', 'Nike', 'Basketball', 'Unisex', 6695, 6, _r(6, 12), '1578269174279-27814d45033f',
      'Gray high-top that suits the court and the street.',
      isNew: true),
  _s('Court Classic Kids Red / White', 'Nike', 'Basketball', 'Kids', 3495, 9, _r(1, 5), '1608667508764-33cf0726b13a',
      'Kids\' court shoes with a firm grip and a comfortable sole.'),
  // ---------------- Added: Jordan
  _s('Air Jordan 1 Low White / Red', 'Jordan', 'Jordan', 'Women', 8995, 7, _r(5, 10), '1579338559194-a162d19bf842',
      'Low-cut white Jordan 1 with red details. Easy to match.',
      isNew: true),
  _s('Air Jordan 1 Mid Brown', 'Jordan', 'Jordan', 'Men', 9795, 5, _r(7, 12), '1549298916-b41d501d3772',
      'Brown mid-top with a retro vibe and a durable leather look.'),
  _s('Jordan Kids Black / Red', 'Jordan', 'Jordan', 'Kids', 4995, 6, _r(1, 5), '1552346154-21d32810aba3',
      'Jordans for kids. Black and red colorway that is a hit with young sneakerheads.',
      isNew: true),
  // ---------------- Added: Running
  _s('Cloud Runner Pink / Gray', 'New Balance', 'Running', 'Women', 6295, 12, _r(5, 10), '1551107696-a4b0c5a0d9a2',
      'Soft cushioning for comfortable everyday runs.',
      isNew: true),
  _s('Marathon Lite Green', 'Nike', 'Running', 'Unisex', 6995, 9, _r(5, 12), '1606107557195-0e29a4b5b4aa',
      'Lightweight running shoe for long distances. Breathable with strong grip.',
      sale: true),
  // ---------------- Added: Training & Gym
  _s('Gym Flex Black / Red', 'Nike', 'Training & Gym', 'Women', 4695, 15, _r(5, 10), '1615290642882-6b9501729a27',
      'Flexible training shoes for workouts, cardio and weights.'),
  _s('Power Lift White', 'Puma', 'Training & Gym', 'Men', 5495, 10, _r(7, 13), '1512374382149-233c42b6a83b',
      'Stable sole for lifting. Firm grip and non-slip.',
      isNew: true),
  _s('Cross Trainer Gray', 'Adidas', 'Training & Gym', 'Unisex', 4495, 18, _r(5, 12), '1491553895911-0055eca6402d',
      'All-around trainer for the gym, jogging and everyday wear.',
      sale: true),
  // ---------------- Added: Skateboarding
  _s('Skate Low Black / White', 'Vans', 'Skateboarding', 'Men', 3495, 20, _r(6, 12), '1553521014-3a56a6964ffe',
      'Classic skate low-top with a flat sole and durable stitching.',
      isNew: true),
  _s('Skate Classic Navy', 'Vans', 'Skateboarding', 'Unisex', 3895, 14, _r(5, 11), '1565379793984-e65b51b33b37',
      'Canvas skate shoes that are easy to wear and always popular on the street.'),
  _s('Skate Kids Pink', 'Vans', 'Skateboarding', 'Kids', 2495, 9, _r(1, 5), '1501580979865-c37d96d28bba',
      'Pink skate shoes for kids. Lightweight and easy to put on.',
      isNew: true),
  // ---------------- Added: Lifestyle
  _s('Retro Cream Low', 'New Balance', 'Lifestyle', 'Men', 6495, 12, _r(7, 12), '1528111610157-f0553810b46f',
      'Cream retro low-top that suits casual and smart-casual looks.',
      isNew: true),
  _s('Daily Walker Gray', 'Puma', 'Lifestyle', 'Women', 4995, 16, _r(5, 10), '1578269174279-27814d45033f',
      'Comfortable everyday sneaker that feels light on the feet.',
      sale: true),
  _s('Chuck Taylor Kids - White', 'Converse', 'Lifestyle', 'Kids', 2495, 15, _r(1, 5), '1528111610157-f0553810b46f',
      'White canvas for kids. Simple and easy to match.'),
];

// ================================================================ THEMES
final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  scaffoldBackgroundColor: kLight,
  colorScheme: ColorScheme.fromSeed(seedColor: kBlue, brightness: Brightness.light)
      .copyWith(primary: kBlue, secondary: kOrange, surface: Colors.white),
  appBarTheme: const AppBarTheme(
    backgroundColor: kNavy,
    foregroundColor: Colors.white,
    elevation: 0,
    scrolledUnderElevation: 0,
    surfaceTintColor: Colors.transparent,
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: kNavy,
    contentTextStyle: const TextStyle(color: Colors.white),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: kBlue,
      foregroundColor: Colors.white,
      disabledBackgroundColor: Colors.black12,
      disabledForegroundColor: Colors.black38,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      minimumSize: const Size(0, 50),
      textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: .5),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: kBlue,
      side: const BorderSide(color: kBlue, width: 1.6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      minimumSize: const Size(0, 50),
      textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kLine)),
    enabledBorder:
        OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kLine)),
    focusedBorder:
        OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBlue, width: 1.6)),
  ),
);

/// For intro and login (auth_flow.dart) - dark navy
final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: kBg,
  colorScheme: const ColorScheme.dark(primary: kAccent, surface: kSurface),
  appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0, scrolledUnderElevation: 0),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: kAccent,
      foregroundColor: Colors.black,
      disabledBackgroundColor: Colors.white12,
      disabledForegroundColor: Colors.white38,
      shape: const StadiumBorder(),
      minimumSize: const Size(0, 54),
      textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: kCard,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: kAccent, width: 1.4),
    ),
  ),
);

class SneakersApp extends StatelessWidget {
  const SneakersApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'SNEAKERS',
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        home: const StartupGate(),
      );
}

/// Dark navy background used by the intro and login in auth_flow.dart
class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Theme(
        data: darkTheme,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [kBg, kNavy, kNavy2],
            ),
          ),
          child: DefaultTextStyle.merge(style: const TextStyle(color: Colors.white), child: child),
        ),
      );
}

// ================================================================ MODEL / HELPERS
class Product {
  final String id, name, brand, category, gender, imageUrl, description;
  final double price, rating;
  final int reviews, stock;
  final bool isNew, sale, trending;
  final List<int> sizes;
  final List<String> images;
  Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.gender,
    required this.price,
    required this.rating,
    required this.reviews,
    required this.imageUrl,
    required this.images,
    required this.description,
    required this.isNew,
    required this.sale,
    required this.trending,
    required this.sizes,
    required this.stock,
  });
  factory Product.fromMap(String id, Map<String, dynamic> m) => Product(
        id: id,
        name: m['name'] ?? '',
        brand: m['brand'] ?? 'Sneakers',
        category: m['category'] ?? 'Lifestyle',
        gender: m['gender'] ?? 'Men',
        price: (m['price'] ?? 0).toDouble(),
        rating: (m['rating'] as num?)?.toDouble() ?? 4.5,
        reviews: (m['reviews'] as num?)?.toInt() ?? 20,
        imageUrl: m['imageUrl'] ?? '',
        images: (m['images'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        description: m['description'] ?? '',
        isNew: m['isNew'] ?? false,
        sale: m['sale'] ?? false,
        trending: m['trending'] ?? false,
        sizes: (m['sizes'] as List?)?.map((e) => (e as num).toInt()).toList() ?? [6, 7, 8, 9, 10, 11, 12],
        stock: (m['stock'] as num?)?.toInt() ?? 10,
      );
  Map<String, dynamic> toMap() => {
        'name': name,
        'brand': brand,
        'category': category,
        'gender': gender,
        'price': price,
        'rating': rating,
        'reviews': reviews,
        'imageUrl': imageUrl,
        'images': images,
        'description': description,
        'isNew': isNew,
        'sale': sale,
        'trending': trending,
        'sizes': sizes,
        'stock': stock,
      };
}

String peso(num v) {
  final s = v.toStringAsFixed(0);
  return '₱${s.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',')}';
}

/// Old price for items on sale (15% off)
int oldPriceOf(double p) => ((p / 0.85) / 5).round() * 5;

Color stockColor(int s) => s <= 0 ? kSoldOut : (s <= 5 ? kAmber : kStockGreen);
String stockLabel(int s) => s <= 0 ? 'Sold out' : (s <= 5 ? 'Only $s left' : 'In stock: $s');

Widget stockLine(int stock, {double size = 12}) {
  final c = stockColor(stock);
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Flexible(
        child: Text(stockLabel(stock),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: c, fontSize: size, fontWeight: FontWeight.w700)),
      ),
    ],
  );
}

Widget shoeImage(String url, {BoxFit fit = BoxFit.cover}) {
  const fallback = Center(child: Icon(Icons.directions_run, size: 56, color: Colors.black26));
  if (url.isEmpty) return fallback;
  return Image.network(
    url,
    fit: fit,
    width: double.infinity,
    height: double.infinity,
    errorBuilder: (_, __, ___) => fallback,
    loadingBuilder: (context, child, progress) => progress == null
        ? child
        : const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
  );
}

Widget galleryView(Product p, int i) {
  final urls = p.images.isNotEmpty ? p.images : [p.imageUrl];
  final real = i < urls.length;
  const scales = [1.0, 1.7, 1.7, 1.45];
  const aligns = [Alignment.center, Alignment.bottomLeft, Alignment.centerRight, Alignment.topCenter];
  return ClipRect(
    child: Transform.scale(
      scale: real ? 1.0 : scales[i],
      alignment: aligns[i],
      child: shoeImage(urls[real ? i : 0]),
    ),
  );
}

Widget tag(String t, {Color bg = kOrange, Color fg = Colors.black}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(t, style: TextStyle(color: fg, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: .5)),
    );

// DESIGN: more rounded panel with a soft shadow
Widget panel(Widget child, {EdgeInsets padding = const EdgeInsets.all(16)}) => Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kLine),
        boxShadow: [BoxShadow(color: kNavy.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: child,
    );

// DESIGN: section title with a circular icon
Widget sectionTitle(String t, {Key? key, String? sub}) => Padding(
      key: key,
      padding: const EdgeInsets.fromLTRB(0, 30, 0, 14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: kImgBg,
            shape: BoxShape.circle,
            border: Border.all(color: kOrange, width: 1.5),
          ),
          child: const Icon(Icons.directions_run, size: 18, color: kNavy),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: kNavy, letterSpacing: .3)),
            if (sub != null) Text(sub, style: const TextStyle(color: kSoft, fontSize: 13.5)),
          ]),
        ),
      ]),
    );

Widget stars(double r, {double size = 16}) {
  final n = r.round().clamp(0, 5);
  return Text('${'★' * n}${'☆' * (5 - n)}', style: TextStyle(color: kOrange, fontSize: size, letterSpacing: 1));
}

void copyText(BuildContext context, String text, String message) {
  Clipboard.setData(ClipboardData(text: text));
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

class Hoverable extends StatefulWidget {
  final Widget Function(bool hover) builder;
  const Hoverable({super.key, required this.builder});
  @override
  State<Hoverable> createState() => _HoverableState();
}

class _HoverableState extends State<Hoverable> {
  bool hover = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => hover = true),
        onExit: (_) => setState(() => hover = false),
        child: widget.builder(hover),
      );
}

Widget pill(String label, bool selected, VoidCallback onTap) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? kNavy : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: selected ? kNavy : kLine),
        ),
        child: Text(label,
            style: TextStyle(color: selected ? Colors.white : kText, fontWeight: FontWeight.w600, fontSize: 13.5)),
      ),
    );

DocumentReference<Map<String, dynamic>> get userRef =>
    FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid);

int _qtyOf(QueryDocumentSnapshot<Map<String, dynamic>> d) => (d.data()['qty'] as num?)?.toInt() ?? 0;
String _pidOf(QueryDocumentSnapshot<Map<String, dynamic>> d) =>
    (d.data()['productId'] ?? d.id.split('_').first).toString();

// ================================================================ PAYMENT QR
/// GCash/Maya QR code. Shows the image in assets (QR code only).
/// If the image is missing, generates a QR code from [data] (the number).
class PayQr extends StatelessWidget {
  final String asset;
  final String data;
  final double size;

  const PayQr({
    super.key,
    required this.asset,
    required this.data,
    this.size = 280,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kLine),
      ),
      child: Image.asset(
        asset,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => QrImageView(
          data: data,
          version: QrVersions.auto,
          backgroundColor: Colors.white,
          padding: const EdgeInsets.all(14),
        ),
      ),
    );
  }
}

// ================================================================ STORE REVIEWS
class ReviewStats {
  final double avg;
  final int count;
  final List<int> dist; // index 0 = 1 star ... index 4 = 5 stars
  const ReviewStats(this.avg, this.count, this.dist);
}

ReviewStats statsOf(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
  final dist = [0, 0, 0, 0, 0];
  var sum = 0;
  for (final d in docs) {
    final r = ((d.data()['rating'] as num?)?.toInt() ?? 0).clamp(1, 5);
    dist[r - 1]++;
    sum += r;
  }
  final n = docs.length;
  return ReviewStats(n == 0 ? 0 : sum / n, n, dist);
}

/// Newest first
List<QueryDocumentSnapshot<Map<String, dynamic>>> sortedReviews(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
  final list = [...docs];
  list.sort((a, b) {
    final ta = (a.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 1 << 50;
    final tb = (b.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 1 << 50;
    return tb.compareTo(ta);
  });
  return list;
}

Widget bigStars(double r, {double size = 22}) {
  return Row(mainAxisSize: MainAxisSize.min, children: [
    for (var i = 1; i <= 5; i++)
      Icon(
        r >= i ? Icons.star : (r >= i - 0.5 ? Icons.star_half : Icons.star_border),
        color: kOrange,
        size: size,
      ),
  ]);
}

Widget ratingSummary(ReviewStats st) => Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Column(mainAxisSize: MainAxisSize.min, children: [
        Text(st.count == 0 ? '–' : st.avg.toStringAsFixed(1),
            style: const TextStyle(fontSize: 52, fontWeight: FontWeight.w900, color: kNavy, height: 1)),
        const SizedBox(height: 4),
        bigStars(st.avg),
        const SizedBox(height: 4),
        Text(st.count == 1 ? '1 review' : '${st.count} reviews', style: const TextStyle(color: kSoft, fontSize: 13)),
      ]),
      const SizedBox(width: 22),
      Expanded(
        child: Column(children: [
          for (var s = 5; s >= 1; s--)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(children: [
                SizedBox(width: 14, child: Text('$s', style: const TextStyle(color: kSoft, fontWeight: FontWeight.w700))),
                const Icon(Icons.star, size: 14, color: kOrange),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: st.count == 0 ? 0 : st.dist[s - 1] / st.count,
                      minHeight: 8,
                      backgroundColor: kImgBg,
                      valueColor: const AlwaysStoppedAnimation(kOrange),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(width: 26, child: Text('${st.dist[s - 1]}', style: const TextStyle(color: kSoft, fontSize: 12))),
              ]),
            ),
        ]),
      ),
    ]);

Widget reviewTile(Map<String, dynamic> r) {
  final rating = (r['rating'] as num?)?.toInt() ?? 0;
  final dt = (r['createdAt'] as Timestamp?)?.toDate();
  final date = dt == null ? '' : '${dt.day}/${dt.month}/${dt.year}';
  final name = (r['name'] ?? 'Customer').toString();
  final comment = (r['comment'] ?? '').toString();
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: kNavy,
          child: Text(name.isEmpty ? '?' : name[0].toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w800, color: kNavy)),
            Row(children: [
              bigStars(rating.toDouble(), size: 16),
              const SizedBox(width: 8),
              Text(date, style: const TextStyle(color: kSoft, fontSize: 12)),
            ]),
          ]),
        ),
      ]),
      if (comment.isNotEmpty) ...[
        const SizedBox(height: 8),
        Text(comment, style: const TextStyle(color: kText, height: 1.45)),
      ],
    ])),
  );
}

/// Section on the home page: store average rating + latest reviews
class ReviewsSection extends StatelessWidget {
  const ReviewsSection({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('reviews').snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        final st = statsOf(docs);
        final latest = sortedReviews(docs).take(3).toList();
        void open() => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReviewsPage()));
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          sectionTitle('CUSTOMER REVIEWS', sub: 'SNEAKERS store rating'),
          panel(
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ratingSummary(st),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: FilledButton(onPressed: open, child: const Text('WRITE A REVIEW'))),
                const SizedBox(width: 10),
                Expanded(child: OutlinedButton(onPressed: open, child: const Text('SEE ALL'))),
              ]),
            ]),
            padding: const EdgeInsets.all(20),
          ),
          const SizedBox(height: 12),
          if (latest.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('No reviews yet. Be the first!', style: TextStyle(color: kSoft)),
            )
          else
            for (final d in latest) reviewTile(d.data()),
        ]);
      },
    );
  }
}

class ReviewsPage extends StatefulWidget {
  const ReviewsPage({super.key});
  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  final comment = TextEditingController();
  int rating = 0;
  bool saving = false;
  bool hasMine = false;

  @override
  void initState() {
    super.initState();
    loadMine();
  }

  @override
  void dispose() {
    comment.dispose();
    super.dispose();
  }

  void snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  /// If the user has reviewed before, load it again so it can be edited
  Future<void> loadMine() async {
    if (!isLoggedIn) return;
    try {
      final d = await FirebaseFirestore.instance
          .collection('reviews')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get();
      if (d.exists && mounted) {
        setState(() {
          hasMine = true;
          rating = (d.data()?['rating'] as num?)?.toInt() ?? 0;
          comment.text = (d.data()?['comment'] ?? '').toString();
        });
      }
    } catch (_) {}
  }

  Future<void> submit() async {
    final ok = await requireLogin(context, message: 'Log in to write a review');
    if (!ok || !mounted) return;
    if (rating < 1) {
      snack('Please choose a star rating first');
      return;
    }
    setState(() => saving = true);
    try {
      final u = FirebaseAuth.instance.currentUser!;
      final dn = (u.displayName ?? '').trim();
      final name = dn.isNotEmpty ? dn : (u.email ?? 'Customer').split('@').first;
      await FirebaseFirestore.instance.collection('reviews').doc(u.uid).set({
        'uid': u.uid,
        'name': name,
        'rating': rating,
        'comment': comment.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) setState(() => hasMine = true);
      snack('Thank you for your review!');
    } catch (e) {
      snack('Could not save your review: $e');
    }
    if (mounted) setState(() => saving = false);
  }

  Widget starPicker() => Row(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 1; i <= 5; i++)
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            onPressed: saving ? null : () => setState(() => rating = i),
            icon: Icon(i <= rating ? Icons.star : Icons.star_border, color: kOrange, size: 36),
          ),
      ]);

  @override
  Widget build(BuildContext context) {
    const labels = ['', 'Poor', 'Fair', 'Good', 'Very good', 'Excellent'];
    return Scaffold(
      appBar: AppBar(title: const Text('Customer Reviews')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('reviews').snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = sortedReviews(snap.data!.docs);
          final st = statsOf(docs);
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  panel(ratingSummary(st), padding: const EdgeInsets.all(20)),
                  const SizedBox(height: 16),
                  panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(hasMine ? 'Edit your review' : 'Rate SNEAKERS',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: kNavy)),
                    const SizedBox(height: 8),
                    Row(children: [
                      starPicker(),
                      const SizedBox(width: 8),
                      Text(labels[rating], style: const TextStyle(color: kSoft, fontWeight: FontWeight.w700)),
                    ]),
                    const SizedBox(height: 8),
                    TextField(
                      controller: comment,
                      maxLines: 4,
                      maxLength: 500,
                      style: const TextStyle(color: kText),
                      decoration: const InputDecoration(
                        labelText: 'What do you think of the store? (optional)',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: saving ? null : submit,
                        child: saving
                            ? const SizedBox(
                                height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(hasMine ? 'UPDATE REVIEW' : 'SUBMIT REVIEW'),
                      ),
                    ),
                    if (!isLoggedIn)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text('You need to log in to write a review.', style: TextStyle(color: kSoft, fontSize: 12.5)),
                      ),
                  ])),
                  const SizedBox(height: 20),
                  Text('All reviews (${docs.length})',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: kNavy)),
                  const SizedBox(height: 10),
                  if (docs.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: Text('No reviews yet. Be the first!', style: TextStyle(color: kSoft))),
                    )
                  else
                    for (final d in docs) reviewTile(d.data()),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ================================================================ INFO PAGES (About, Size Guide, Shipping, Contact, Social)
class InfoPage extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final List<Widget> children;
  const InfoPage({super.key, required this.title, required this.subtitle, required this.icon, required this.children});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(colors: [kNavy, Color(0xFF1B49A8)]),
                  ),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(color: kOrange, shape: BoxShape.circle),
                      child: Icon(icon, color: Colors.black, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(title, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text(subtitle, style: const TextStyle(color: kPaleBlue, height: 1.35)),
                      ]),
                    ),
                  ]),
                ),
                ...children,
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      );
}

Widget h2(String t) => Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 8),
      child: Row(children: [
        Container(width: 4, height: 20, color: kOrange),
        const SizedBox(width: 8),
        Expanded(child: Text(t, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: kNavy))),
      ]),
    );

Widget para(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(t, style: const TextStyle(color: kText, height: 1.6, fontSize: 15)),
    );

Widget infoItem(IconData icon, String title, String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(color: kImgBg, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: kNavy, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: kNavy, fontSize: 15.5)),
            const SizedBox(height: 2),
            Text(text, style: const TextStyle(color: kSoft, height: 1.5)),
          ]),
        ),
      ]),
    );

Widget stepItem(int n, String title, String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: kNavy, shape: BoxShape.circle),
          child: Text('$n', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: kNavy, fontSize: 15.5)),
            const SizedBox(height: 2),
            Text(text, style: const TextStyle(color: kSoft, height: 1.5)),
          ]),
        ),
      ]),
    );

Widget dataTable(List<String> head, List<List<String>> rows) => ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: kLine), borderRadius: BorderRadius.circular(12)),
        child: Table(
          children: [
            TableRow(
              decoration: const BoxDecoration(color: kNavy),
              children: [
                for (final h in head)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(h, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                  ),
              ],
            ),
            for (var i = 0; i < rows.length; i++)
              TableRow(
                decoration: BoxDecoration(color: i.isEven ? Colors.white : kImgBg.withValues(alpha: 0.6)),
                children: [
                  for (var j = 0; j < rows[i].length; j++)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(rows[i][j],
                          style: TextStyle(fontWeight: j == 0 ? FontWeight.w800 : FontWeight.w500, color: kText)),
                    ),
                ],
              ),
          ],
        ),
      ),
    );

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});
  @override
  Widget build(BuildContext context) => InfoPage(
        title: 'About Us',
        subtitle: 'The online sneaker store for Men, Women and Kids.',
        icon: Icons.storefront,
        children: [
          h2('Who is SNEAKERS?'),
          para('SNEAKERS is an online sneaker store made for Filipinos who love shoes. '
              'From everyday wear, running, basketball and football, to skating and the gym, '
              'you only need one place to find a pair that fits your style and your needs.'),
          para('We believe ordering shoes online should not be hard or confusing. That is why at SNEAKERS, '
              'you can see the price, the available sizes and the remaining stock before you even check out. '
              'No hidden costs and no surprises in the total.'),
          h2('What can you buy from us?'),
          infoItem(Icons.style, 'Lifestyle', 'Classic everyday sneakers that suit school, work and hangouts.'),
          infoItem(Icons.star, 'Jordan', 'For lovers of the Jordan silhouette and the colorways sneakerheads look for.'),
          infoItem(Icons.directions_run, 'Running', 'Lightweight and comfortable shoes for running and exercise.'),
          infoItem(Icons.sports_basketball, 'Basketball', 'Court shoes with ankle support and a firm grip on the floor.'),
          infoItem(Icons.sports_soccer, 'Football', 'Football boots, turf shoes and futsal shoes for the field and indoor courts.'),
          infoItem(Icons.fitness_center, 'Training & Gym', 'Stable shoes for workouts, lifting and cardio.'),
          infoItem(Icons.skateboarding, 'Skateboarding', 'Durable flat-sole shoes made for skating and the street.'),
          para('We have shoes for Men, Women and Kids from brands like Nike, Jordan, Adidas, Converse, Vans, New Balance and Puma.'),
          h2('Our mission'),
          para('To make buying sneakers online easy, clear and safe for every Filipino, whatever their budget and style. '
              'We want every customer to leave happy with the pair they chose and confident enough to come back.'),
          h2('Why buy from SNEAKERS?'),
          infoItem(Icons.verified, 'Authentic and quality-checked',
              'We make sure every pair is genuine and in good condition before it is listed in the shop.'),
          infoItem(Icons.inventory_2_outlined, 'Real stock, live updates',
              'The stock you see is updated right away. Once the last pair is bought, you will see it marked Sold out.'),
          infoItem(Icons.sell_outlined, 'Clear pricing',
              'Shipping is a flat ₱99 per order and you can see it in the cart before you pay. We also have discount codes and sale items.'),
          infoItem(Icons.assignment_return_outlined, '30-day returns',
              'If it does not fit or there is a problem, you can return unworn pairs within 30 days.'),
          infoItem(Icons.straighten, 'Complete size guide',
              'We have a table of US, UK, EU and centimeter measurements so you do not pick the wrong size.'),
          infoItem(Icons.support_agent, 'Easy to reach',
              'Call, text or message us on Facebook for questions about your order, size or delivery.'),
          h2('How to order'),
          stepItem(1, 'Choose a shoe', 'Browse the shop, use the search and categories, or check Trending, New Arrivals and Sale.'),
          stepItem(2, 'Choose size and quantity', 'Open the product, pick a US size and quantity, then click Add to Cart.'),
          stepItem(3, 'Check your cart', 'You will see the subtotal, shipping and discount. Enter a discount code if you have one.'),
          stepItem(4, 'Check out', 'Enter your contact details and address, then choose a payment method (Cash on Delivery, GCash or Maya).'),
          stepItem(5, 'Wait for your order', 'You can see your order status in My Account → My Orders.'),
          h2('Our promise to you'),
          para('We will be honest about the information on every product, the price and the stock. If there is a problem with your order, '
              'we will listen and help you. Thank you for choosing SNEAKERS!'),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: FilledButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactPage())),
                child: const Text('CONTACT US'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SizeGuidePage())),
                child: const Text('SIZE GUIDE'),
              ),
            ),
          ]),
        ],
      );
}

class SizeGuidePage extends StatelessWidget {
  const SizeGuidePage({super.key});

  Widget chips(String label, List<int> sizes) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800, color: kNavy)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final s in sizes)
              Container(
                width: 52,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kNavy, width: 1.4),
                ),
                child: Text('$s', style: const TextStyle(fontWeight: FontWeight.w800, color: kNavy)),
              ),
          ]),
        ]),
      );

  @override
  Widget build(BuildContext context) => InfoPage(
        title: 'Size Guide',
        subtitle: 'Find the right size for a comfortable fit.',
        icon: Icons.straighten,
        children: [
          h2('Sizes available in the shop'),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('products').snapshots(),
            builder: (context, snap) {
              final kids = <int>{};
              final adult = <int>{};
              for (final d in snap.data?.docs ?? <QueryDocumentSnapshot<Map<String, dynamic>>>[]) {
                final p = Product.fromMap(d.id, d.data());
                if (p.stock <= 0) continue;
                (p.gender == 'Kids' ? kids : adult).addAll(p.sizes);
              }
              final kidList = kids.isEmpty ? _r(1, 5) : (kids.toList()..sort());
              final adultList = adult.isEmpty ? _r(5, 13) : (adult.toList()..sort());
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                para('These are all the US sizes currently in stock at SNEAKERS.'),
                chips('Men / Women / Unisex (US)', adultList),
                chips('Kids (US)', kidList),
              ]);
            },
          ),
          h2('How to measure your foot'),
          stepItem(1, 'Prepare', 'Place a sheet of paper on the floor against a wall and stand on it, wearing the socks you usually use.'),
          stepItem(2, 'Mark', 'Press your heel against the wall and mark the tip of your longest toe.'),
          stepItem(3, 'Measure', 'Measure the distance from the wall to the mark (in centimeters). Do this for both feet and use the longer one.'),
          stepItem(4, 'Compare', 'Find your measurement in the table below. It is best to measure in the afternoon, when your feet are slightly swollen.'),
          h2('Men / Women / Unisex (US)'),
          dataTable(['US', 'UK', 'EU', 'Foot (cm)'], const [
            ['5', '4.5', '37.5', '23'],
            ['6', '5.5', '38.5', '24'],
            ['7', '6', '40', '25'],
            ['8', '7', '41', '26'],
            ['9', '8', '42.5', '27'],
            ['10', '9', '44', '28'],
            ['11', '10', '45', '29'],
            ['12', '11', '46', '30'],
            ['13', '12', '47.5', '31'],
          ]),
          h2('Kids (US)'),
          dataTable(['US (Kids)', 'Foot (cm)'], const [
            ['1', '≈ 20'],
            ['2', '≈ 21'],
            ['3', '≈ 22'],
            ['4', '≈ 23'],
            ['5', '≈ 23.5'],
          ]),
          h2('Tips'),
          infoItem(Icons.arrow_upward, 'Between two sizes?', 'Choose the larger size so it is not tight, especially if you have wide feet.'),
          infoItem(Icons.compare_arrows, 'Men and Women', 'Usually, the Men\'s US size is 1.5 smaller than the Women\'s US size (for example, Women\'s 8.5 is Men\'s 7).'),
          infoItem(Icons.child_care, 'For kids', 'Kids\' feet grow fast. Leave about 1 cm of space in front of the toes.'),
          infoItem(Icons.info_outline, 'Note', 'Measurements are approximate because the fit differs by brand and model. If you are not sure, message us and we will help you.'),
        ],
      );
}

class ShippingPage extends StatelessWidget {
  const ShippingPage({super.key});
  @override
  Widget build(BuildContext context) => InfoPage(
        title: 'Shipping & Returns',
        subtitle: 'Clear shipping and easy returns.',
        icon: Icons.local_shipping_outlined,
        children: [
          h2('Shipping'),
          infoItem(Icons.sell_outlined, 'Flat ₱99 shipping', 'A flat shipping fee of ₱99 applies to every order. You will see it in the cart and at checkout before you pay.'),
          infoItem(Icons.payments_outlined, 'Cash on Delivery', 'You can pay when your order arrives. Please prepare the exact amount if possible.'),
          infoItem(Icons.account_balance_wallet_outlined, 'GCash', 'You can also pay with GCash. Scan the QR code or send to our GCash number, enter the reference number at checkout, and we will confirm your payment.'),
          infoItem(Icons.account_balance_wallet_outlined, 'Maya', 'You can also pay with Maya. Scan the QR code or send to our Maya number, enter the reference number at checkout, and we will confirm your payment.'),
          infoItem(Icons.chat_outlined, 'Delivery updates', 'For updates on your order, message or call us using the details in Contact Us.'),
          h2('Returns'),
          para('You have 30 days to return shoes that are unworn and in their original condition.'),
          stepItem(1, 'Contact us', 'Message or call us and tell us your name, the product and the reason for the return.'),
          stepItem(2, 'Prepare the shoes', 'Send them back clean and unworn, with the box and tags.'),
          stepItem(3, 'Wait for confirmation', 'Once we have checked the shoes, we will let you know the next steps.'),
          h2('Size does not fit?'),
          para('Read the Size Guide before ordering. If the size is still wrong, contact us and we will help you get the right pair, depending on available stock.'),
        ],
      );
}

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  Widget card(BuildContext context, IconData icon, String label, String value, String copyMsg) => panel(
        Row(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(color: kNavy, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(color: kSoft, fontSize: 13)),
              const SizedBox(height: 2),
              SelectableText(value, style: const TextStyle(fontWeight: FontWeight.w900, color: kNavy, fontSize: 17)),
            ]),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            style: OutlinedButton.styleFrom(minimumSize: const Size(80, 42)),
            onPressed: () => copyText(context, value, copyMsg),
            child: const Text('COPY'),
          ),
        ]),
      );

  @override
  Widget build(BuildContext context) => InfoPage(
        title: 'Contact Us',
        subtitle: 'Questions about your order, size or delivery? Talk to us.',
        icon: Icons.support_agent,
        children: [
          const SizedBox(height: 16),
          card(context, Icons.phone, 'Call or Text', kPhone, 'Phone number copied'),
          const SizedBox(height: 12),
          card(context, Icons.facebook, 'Facebook', kFacebook, 'Facebook link copied'),
          h2('How can we help?'),
          infoItem(Icons.straighten, 'Size help', 'Not sure about your size? Tell us your foot measurement and we will recommend the right size.'),
          infoItem(Icons.receipt_long_outlined, 'Order status', 'Ask for an update on your order. Have your name and the product you ordered ready.'),
          infoItem(Icons.assignment_return_outlined, 'Returns and exchanges', 'Contact us if you need to return or exchange your shoes.'),
          infoItem(Icons.inventory_2_outlined, 'Availability', 'Looking for a pair that is not in the shop? Message us and we will check.'),
          para('Tip: tap COPY, then paste the number into your Phone app or the link into your browser.'),
        ],
      );
}

class SocialPage extends StatelessWidget {
  const SocialPage({super.key});
  @override
  Widget build(BuildContext context) => InfoPage(
        title: 'Social Media',
        subtitle: 'Follow us for new shoes and updates.',
        icon: Icons.thumb_up_alt_outlined,
        children: [
          const SizedBox(height: 16),
          panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.facebook, color: Color(0xFF1877F2), size: 40),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Facebook', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kNavy)),
              ),
            ]),
            const SizedBox(height: 10),
            const Text('That is where we post new arrivals, sales and updates. You can also message us with questions about your order.',
                style: TextStyle(color: kSoft, height: 1.5)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: kImgBg, borderRadius: BorderRadius.circular(8)),
              child: const SelectableText(kFacebook, style: TextStyle(color: kBlue, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => copyText(context, kFacebook, 'Facebook link copied'),
                child: const Text('COPY FACEBOOK LINK'),
              ),
            ),
          ])),
          const SizedBox(height: 10),
          para('Paste the link into your browser to open our Facebook page.'),
        ],
      );
}

// ================================================================ STORE (HOME)
class StorePage extends StatefulWidget {
  const StorePage({super.key});
  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  static const tabs = ['HOME', 'MEN', 'WOMEN', 'KIDS', 'RUNNING', 'NEW ARRIVALS', 'SALE'];
  static const categories = ['All', 'Lifestyle', 'Jordan', 'Running', 'Basketball', 'Football', 'Training & Gym', 'Skateboarding'];
  static const catIcons = {
    'Lifestyle': Icons.style,
    'Jordan': Icons.star,
    'Running': Icons.directions_run,
    'Basketball': Icons.sports_basketball,
    'Football': Icons.sports_soccer,
    'Training & Gym': Icons.fitness_center,
    'Skateboarding': Icons.skateboarding,
  };
  static const titles = {
    'HOME': 'All Sneakers',
    'MEN': "Men's Sneakers",
    'WOMEN': "Women's Sneakers",
    'KIDS': "Kids' Sneakers",
    'RUNNING': 'Running',
    'NEW ARRIVALS': 'New Arrivals',
    'SALE': 'Sale',
  };
  String tab = 'HOME';
  String cat = 'All';
  String brand = 'All';
  String q = '';
  final searchCtl = TextEditingController();
  final scroll = ScrollController();
  final allKey = GlobalKey();

  @override
  void dispose() {
    searchCtl.dispose();
    scroll.dispose();
    super.dispose();
  }

  bool matchTab(Product p) {
    switch (tab) {
      case 'MEN':
        return p.gender == 'Men' || p.gender == 'Unisex';
      case 'WOMEN':
        return p.gender == 'Women' || p.gender == 'Unisex';
      case 'KIDS':
        return p.gender == 'Kids';
      case 'RUNNING':
        return p.category == 'Running';
      case 'NEW ARRIVALS':
        return p.isNew;
      case 'SALE':
        return p.sale;
      default:
        return true;
    }
  }

  void jumpToAll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = allKey.currentContext;
      if (c != null) Scrollable.ensureVisible(c, duration: const Duration(milliseconds: 400));
    });
  }

  void goTab(String t) {
    setState(() {
      tab = t;
      cat = 'All';
      brand = 'All';
      q = '';
      searchCtl.clear();
    });
    if (scroll.hasClients) scroll.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  /// Replaces the contents of 'products' with the sample products
  Future<void> loadSamples() async {
    final db = FirebaseFirestore.instance;
    final col = db.collection('products');
    final old = await col.get();
    final batch = db.batch();
    for (final d in old.docs) {
      batch.delete(d.reference);
    }
    for (var i = 0; i < sampleProducts.length; i++) {
      batch.set(col.doc(), {
        ...sampleProducts[i],
        'rating': 4.3 + (i % 5) / 10,
        'reviews': 18 + (i * 7) % 90,
      });
    }
    await batch.commit();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sample products loaded')));
    }
  }

  Widget catPill(String c) {
    final sel = cat == c;
    return InkWell(
      onTap: () => setState(() => cat = c),
      borderRadius: BorderRadius.circular(30),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? kNavy : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: sel ? kNavy : kLine),
          boxShadow: sel ? [BoxShadow(color: kNavy.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3))] : null,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(c == 'All' ? Icons.apps : (catIcons[c] ?? Icons.style), size: 16, color: sel ? kOrange : kNavy),
          const SizedBox(width: 6),
          Text(c, style: TextStyle(color: sel ? Colors.white : kText, fontWeight: FontWeight.w700, fontSize: 13.5)),
        ]),
      ),
    );
  }

  Widget hdrBtn(IconData icon, String label, bool wide) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: Colors.white, size: 22),
          if (wide) ...[
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ]),
      );

  /// Small store rating strip above the header (live from reviews)
  Widget topStrip() => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('reviews').snapshots(),
        builder: (context, snap) {
          final st = statsOf(snap.data?.docs ?? <QueryDocumentSnapshot<Map<String, dynamic>>>[]);
          return InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReviewsPage())),
            child: Container(
              width: double.infinity,
              color: kDeepNavy,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Flexible(
                  child: Text(
                    'Flat ₱99 shipping  •  30-day returns  •  COD / GCash / Maya',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: kPaleBlue, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.star, size: 14, color: kOrange),
                const SizedBox(width: 3),
                Text(st.count == 0 ? 'No reviews yet' : '${st.avg.toStringAsFixed(1)} (${st.count})',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
              ]),
            ),
          );
        },
      );

  Widget header(bool wide) {
    // DESIGN: logo with a circular icon and a tagline
    final logo = InkWell(
      onTap: () => goTab('HOME'),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: kOrange, width: 2.5),
          ),
          child: const Icon(Icons.directions_run, color: kNavy, size: 26),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            const Text.rich(
              TextSpan(children: [
                TextSpan(text: 'SNEAKER', style: TextStyle(color: Colors.white)),
                TextSpan(text: 'S', style: TextStyle(color: kOrange)),
              ]),
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1),
            ),
            const Text('♡ Fresh Kicks, Happy Feet ♡',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: kPaleBlue, fontSize: 11.5)),
          ]),
        ),
      ]),
    );
    final search = SizedBox(
      height: 42,
      child: TextField(
        controller: searchCtl,
        onChanged: (v) => setState(() => q = v),
        style: const TextStyle(color: kText),
        decoration: InputDecoration(
          hintText: 'Search sneakers and brands...',
          prefixIcon: const Icon(Icons.search, color: kSoft),
          isDense: true,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        ),
      ),
    );
    final account = PopupMenuButton<String>(
      tooltip: 'My Account',
      child: hdrBtn(isLoggedIn ? Icons.account_circle : Icons.person_outline, 'My Account', wide),
      onSelected: (v) async {
        if (v == 'samples') loadSamples();
        if (v == 'add') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddProductPage()));
        }
        if (v == 'reviews') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ReviewsPage()));
        }
        // FIX: Goes straight to Order History (no login prompt) so orders are
        // visible right away, including the guest session's Xendit orders.
        if (v == 'orders') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderHistoryPage()));
        }
        if (v == 'login') {
          await requireLogin(context, message: 'Log in to access your account');
          if (!mounted) return;
          setState(() {});
        }
        if (v == 'logout') {
          await FirebaseAuth.instance.signOut();
          if (!mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const StartupGate(skipIntro: true)),
            (r) => false,
          );
        }
      },
      itemBuilder: (_) => [
        if (isLoggedIn)
          PopupMenuItem(enabled: false, child: Text(FirebaseAuth.instance.currentUser?.email ?? ''))
        else
          const PopupMenuItem(value: 'login', child: Text('Log in / Register')),
        const PopupMenuItem(value: 'orders', child: Text('My Orders')),
        const PopupMenuItem(value: 'reviews', child: Text('Rate our store')),
        const PopupMenuItem(value: 'add', child: Text('Add product')),
        const PopupMenuItem(value: 'samples', child: Text('Load sample products')),
        if (isLoggedIn) const PopupMenuItem(value: 'logout', child: Text('Log out')),
      ],
    );
    final wishlist = InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WishlistPage())),
      child: hdrBtn(Icons.favorite_border, 'Wishlist', wide),
    );
    final cart = StreamBuilder<QuerySnapshot>(
      stream: userRef.collection('cart').snapshots(),
      builder: (context, s) {
        final n = s.data?.docs.length ?? 0;
        return InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartPage())),
          child: wide
              ? hdrBtn(Icons.shopping_bag_outlined, 'Cart ($n)', true)
              : Badge(
                  isLabelVisible: n > 0,
                  label: Text('$n'),
                  child: hdrBtn(Icons.shopping_bag_outlined, '', false),
                ),
        );
      },
    );
    final nav = Container(
      color: kNavy2,
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: wide ? 24 : 8),
        child: Row(children: [
          for (final t in tabs)
            InkWell(
              onTap: () => goTab(t),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: tab == t ? kOrange : Colors.transparent, width: 3)),
                ),
                child: Text(t, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13.5)),
              ),
            ),
        ]),
      ),
    );
    // DESIGN: rounded bottom of the header
    return Material(
      color: kNavy,
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      child: SafeArea(
        bottom: false,
        child: Column(children: [
          topStrip(),
          Padding(
            padding: EdgeInsets.fromLTRB(wide ? 24 : 14, 10, wide ? 16 : 6, wide ? 10 : 6),
            child: wide
                ? Row(children: [
                    logo,
                    const SizedBox(width: 28),
                    Expanded(child: search),
                    const SizedBox(width: 12),
                    account,
                    wishlist,
                    cart,
                  ])
                : Row(children: [Flexible(child: logo), const SizedBox(width: 6), account, wishlist, cart]),
          ),
          if (!wide) Padding(padding: const EdgeInsets.fromLTRB(14, 0, 14, 10), child: search),
          nav,
        ]),
      ),
    );
  }

  Widget hero(bool wide) => Container(
        margin: const EdgeInsets.only(top: 18),
        height: wide ? 320 : 290,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [kNavy, Color(0xFF1B49A8)]),
        ),
        child: Stack(children: [
          Positioned(
            right: -70,
            top: -70,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(shape: BoxShape.circle, color: kOrange.withValues(alpha: 0.18)),
            ),
          ),
          Positioned(
            left: -50,
            bottom: -90,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.06)),
            ),
          ),
          if (wide)
            Positioned(
              right: 36,
              top: 28,
              bottom: 28,
              child: AspectRatio(
                aspectRatio: 1,
                child: Transform.rotate(
                  angle: 0.05,
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: kOrange, width: 3),
                      boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 24, offset: Offset(0, 12))],
                    ),
                    child: shoeImage(heroImage),
                  ),
                ),
              ),
            )
          else
            Align(
              alignment: Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                heightFactor: 1,
                child: ShaderMask(
                  shaderCallback: (r) => const LinearGradient(
                    colors: [Colors.transparent, Colors.black],
                    stops: [0.0, 0.55],
                  ).createShader(r),
                  blendMode: BlendMode.dstIn,
                  child: shoeImage(heroImage),
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.all(wide ? 36 : 22),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: wide ? 500 : 260),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  tag('NEW SEASON  •  NEW ARRIVALS'),
                  const SizedBox(height: 12),
                  Text('FIND YOUR NEXT\nFAVORITE SNEAKERS',
                      style: TextStyle(color: Colors.white, fontSize: wide ? 40 : 26, fontWeight: FontWeight.w900, height: 1.05)),
                  const SizedBox(height: 10),
                  Text('Fresh styles. Everyday comfort. Street-ready looks.',
                      style: TextStyle(color: kPaleBlue, fontSize: wide ? 15.5 : 13.5)),
                  const SizedBox(height: 16),
                  Wrap(spacing: 10, runSpacing: 10, children: [
                    FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor: kOrange, foregroundColor: Colors.black, minimumSize: const Size(0, 44)),
                      onPressed: jumpToAll,
                      child: const Text('SHOP THE COLLECTION'),
                    ),
                    if (wide)
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54, width: 1.6),
                            minimumSize: const Size(0, 44)),
                        onPressed: () => goTab('SALE'),
                        child: const Text('VIEW SALE'),
                      ),
                  ]),
                ],
              ),
            ),
          ),
        ]),
      );

  Widget featureCard(IconData icon, String title, String sub) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kLine),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: kImgBg, shape: BoxShape.circle),
            child: Icon(icon, color: kNavy, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: kNavy, fontSize: 14)),
              Text(sub, style: const TextStyle(color: kSoft, fontSize: 12)),
            ]),
          ),
        ]),
      );

  Widget features() => Padding(
        padding: const EdgeInsets.only(top: 18),
        child: LayoutBuilder(builder: (context, cons) {
          final cols = cons.maxWidth >= 760 ? 4 : 2;
          final w = (cons.maxWidth - (cols - 1) * 12) / cols;
          final items = [
            featureCard(Icons.verified, 'Authentic', 'Quality-checked'),
            featureCard(Icons.local_shipping_outlined, '₱99 Shipping', 'Flat rate'),
            featureCard(Icons.qr_code_2, 'COD / GCash / Maya', 'Scan to pay'),
            featureCard(Icons.lock_outline, 'Secure Checkout', 'Your order is safe'),
          ];
          return Wrap(spacing: 12, runSpacing: 12, children: [for (final i in items) SizedBox(width: w, child: i)]);
        }),
      );

  Widget categoryTiles(List<Product> all) => SizedBox(
        height: 118,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: categories.length - 1,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, i) {
            final c = categories[i + 1];
            final n = all.where((p) => p.category == c && p.stock > 0).length;
            final sel = cat == c;
            return InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                setState(() {
                  cat = sel ? 'All' : c;
                  brand = 'All';
                });
                jumpToAll();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 130,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: sel ? kNavy : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: sel ? kNavy : kLine),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: sel ? kOrange : kImgBg, shape: BoxShape.circle),
                    child: Icon(catIcons[c], color: sel ? Colors.black : kNavy, size: 22),
                  ),
                  const SizedBox(height: 8),
                  Text(c,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: sel ? Colors.white : kNavy)),
                  Text('$n in stock', style: TextStyle(fontSize: 11.5, color: sel ? kPaleBlue : kSoft)),
                ]),
              ),
            );
          },
        ),
      );

  Widget saleBanner() => Container(
        margin: const EdgeInsets.only(top: 30),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(colors: [kOrange, Color(0xFFFFB067)]),
        ),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('SALE', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.black)),
              const SizedBox(height: 2),
              const Text('Up to 15% off selected sneakers. Limited stock!',
                  style: TextStyle(color: Colors.black87, height: 1.3)),
              const SizedBox(height: 12),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: kNavy, foregroundColor: Colors.white, minimumSize: const Size(0, 44)),
                onPressed: () => goTab('SALE'),
                child: const Text('VIEW SALE'),
              ),
            ]),
          ),
          const Icon(Icons.local_offer, size: 72, color: Colors.black26),
        ]),
      );

  Widget brandTiles(List<Product> all) {
    final brands = {...all.map((p) => p.brand)}.toList()..sort();
    return Wrap(spacing: 10, runSpacing: 10, children: [
      for (final b in brands)
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() {
              tab = 'HOME';
              cat = 'All';
              brand = b;
              q = '';
              searchCtl.clear();
            });
            jumpToAll();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kLine),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(b.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w900, color: kNavy, letterSpacing: 1, fontSize: 13.5)),
              const SizedBox(width: 8),
              Text('${all.where((p) => p.brand == b).length}', style: const TextStyle(color: kSoft, fontSize: 12)),
            ]),
          ),
        ),
    ]);
  }

  Widget fLink(String t, VoidCallback f) => InkWell(
        onTap: f,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Text(t, style: const TextStyle(color: kPaleBlue, fontSize: 14)),
        ),
      );

  Widget fCol(String title, List<Widget> items) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 8),
          ...items,
        ],
      );

  Widget footer(bool wide) {
    void open(Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    final brandCol = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text.rich(
        TextSpan(children: [
          TextSpan(text: 'SNEAKER', style: TextStyle(color: Colors.white)),
          TextSpan(text: 'S', style: TextStyle(color: kOrange)),
        ]),
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1),
      ),
      const SizedBox(height: 8),
      const Text('Online sneaker store for Men, Women and Kids. Authentic, quality-checked and easy to order.',
          style: TextStyle(color: kPaleBlue, height: 1.5, fontSize: 13.5)),
    ]);
    final shopCol = fCol('SHOP', [
      fLink('Men', () => goTab('MEN')),
      fLink('Women', () => goTab('WOMEN')),
      fLink('Kids', () => goTab('KIDS')),
      fLink('Running', () => goTab('RUNNING')),
      fLink('New Arrivals', () => goTab('NEW ARRIVALS')),
      fLink('Sale', () => goTab('SALE')),
    ]);
    final helpCol = fCol('HELP', [
      fLink('ABOUT US', () => open(const AboutPage())),
      fLink('SIZE GUIDE', () => open(const SizeGuidePage())),
      fLink('SHIPPING & RETURNS', () => open(const ShippingPage())),
      fLink('CUSTOMER REVIEWS', () => open(const ReviewsPage())),
      fLink('CONTACT US', () => open(const ContactPage())),
      fLink('SOCIAL MEDIA', () => open(const SocialPage())),
    ]);
    final contactCol = fCol('CONTACT', [
      InkWell(
        onTap: () => copyText(context, kPhone, 'Phone number copied'),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 5),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.phone, color: kOrange, size: 18),
            SizedBox(width: 8),
            Text(kPhone, style: TextStyle(color: kPaleBlue, fontSize: 14)),
          ]),
        ),
      ),
      InkWell(
        onTap: () => open(const SocialPage()),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 5),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.facebook, color: kOrange, size: 18),
            SizedBox(width: 8),
            Text('Facebook', style: TextStyle(color: kPaleBlue, fontSize: 14)),
          ]),
        ),
      ),
    ]);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 36),
      color: kNavy,
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 16),
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(children: [
              wide
                  ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(flex: 2, child: brandCol),
                      const SizedBox(width: 24),
                      Expanded(child: shopCol),
                      Expanded(child: helpCol),
                      Expanded(child: contactCol),
                    ])
                  : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      brandCol,
                      const SizedBox(height: 22),
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(child: shopCol),
                        Expanded(child: helpCol),
                      ]),
                      const SizedBox(height: 22),
                      contactCol,
                    ]),
              const SizedBox(height: 22),
              const Divider(color: Colors.white24),
              const SizedBox(height: 6),
              Text('© ${DateTime.now().year} SNEAKERS. All rights reserved.',
                  style: const TextStyle(color: kPaleBlue, fontSize: 12)),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final wide = width >= 760;
    final side = width > 1140 ? (width - 1100) / 2 : 16.0;
    Widget pad(Widget sliver) => SliverPadding(padding: EdgeInsets.symmetric(horizontal: side), sliver: sliver);
    SliverGridDelegate grid() => const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 280,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.58,
        );

    return Scaffold(
      body: Column(
        children: [
          header(wide),
          Expanded(
            child: Stack(
              children: [
                const Positioned.fill(child: StoreBackdrop()),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance.collection('products').snapshots(),
                  builder: (context, snap) {
                    if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
                    if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                    final all = snap.data!.docs.map((d) => Product.fromMap(d.id, d.data())).toList();
                    if (all.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('No products yet.\nMy Account > Load sample products',
                              textAlign: TextAlign.center, style: TextStyle(color: kSoft)),
                        ),
                      );
                    }
                    final lower = q.toLowerCase();
                    final inTab = all.where(matchTab).toList();
                    final brands = ['All', ...{...inTab.map((p) => p.brand)}];
                    if (!brands.contains(brand)) brand = 'All';
                    final products = inTab
                        .where((p) =>
                            (cat == 'All' || p.category == cat) &&
                            (brand == 'All' || p.brand == brand) &&
                            (p.name.toLowerCase().contains(lower) || p.brand.toLowerCase().contains(lower)))
                        .toList();
                    final totalPairs = products.fold<int>(0, (a, p) => a + p.stock);
                    final home = tab == 'HOME' && q.isEmpty;
                    final trending = all.where((p) => p.trending).take(8).toList();

                    return CustomScrollView(
                      controller: scroll,
                      slivers: [
                        if (home) ...[
                          pad(SliverToBoxAdapter(child: hero(wide))),
                          pad(SliverToBoxAdapter(child: features())),
                          pad(SliverToBoxAdapter(child: sectionTitle('SHOP BY CATEGORY', sub: 'Choose by how you will use them'))),
                          pad(SliverToBoxAdapter(child: categoryTiles(all))),
                          if (trending.isNotEmpty) ...[
                            pad(SliverToBoxAdapter(child: sectionTitle('TRENDING SNEAKERS', sub: 'Today\'s favorites'))),
                            pad(SliverGrid.builder(
                              gridDelegate: grid(),
                              itemCount: trending.length,
                              itemBuilder: (_, i) => ProductCard(product: trending[i]),
                            )),
                          ],
                          pad(SliverToBoxAdapter(child: saleBanner())),
                        ],
                        pad(SliverToBoxAdapter(
                          child: Padding(
                            key: allKey,
                            padding: const EdgeInsets.fromLTRB(0, 30, 0, 12),
                            child: Row(children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                    color: kImgBg, shape: BoxShape.circle, border: Border.all(color: kOrange, width: 1.5)),
                                child: const Icon(Icons.local_fire_department, size: 20, color: kOrange),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text('${titles[tab]} (${products.length})',
                                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: kNavy)),
                                  const Text('Authentic. Quality-checked. Ready to ship.',
                                      style: TextStyle(color: kSoft, fontSize: 13)),
                                ]),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(color: kImgBg, borderRadius: BorderRadius.circular(20)),
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  const Icon(Icons.inventory_2_outlined, size: 14, color: kSoft),
                                  const SizedBox(width: 6),
                                  Text('$totalPairs pairs', style: const TextStyle(color: kSoft, fontSize: 12)),
                                ]),
                              ),
                            ]),
                          ),
                        )),
                        if (tab != 'RUNNING')
                          pad(SliverToBoxAdapter(
                            child: SizedBox(
                              height: 46,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: categories.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 8),
                                itemBuilder: (_, i) => Center(child: catPill(categories[i])),
                              ),
                            ),
                          )),
                        if (brands.length > 2)
                          pad(SliverToBoxAdapter(
                            child: SizedBox(
                              height: 46,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: brands.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 8),
                                itemBuilder: (_, i) => Center(
                                  child: ChoiceChip(
                                    label: Text(brands[i] == 'All' ? 'All brands' : brands[i]),
                                    selected: brand == brands[i],
                                    selectedColor: kImgBg,
                                    backgroundColor: Colors.white,
                                    side: BorderSide(color: brand == brands[i] ? kBlue : kLine),
                                    showCheckmark: false,
                                    onSelected: (_) => setState(() => brand = brands[i]),
                                  ),
                                ),
                              ),
                            ),
                          )),
                        const SliverToBoxAdapter(child: SizedBox(height: 12)),
                        if (products.isEmpty)
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.all(40),
                              child: Center(
                                child: Text('Nothing found. Try another category or brand.',
                                    textAlign: TextAlign.center, style: TextStyle(color: kSoft)),
                              ),
                            ),
                          )
                        else
                          pad(SliverGrid.builder(
                            gridDelegate: grid(),
                            itemCount: products.length,
                            itemBuilder: (_, i) => ProductCard(product: products[i]),
                          )),
                        if (home) ...[
                          pad(const SliverToBoxAdapter(child: ReviewsSection())),
                          pad(SliverToBoxAdapter(child: sectionTitle('SHOP BY BRAND', sub: 'Brands you can buy from us'))),
                          pad(SliverToBoxAdapter(child: brandTiles(all))),
                        ],
                        SliverToBoxAdapter(child: footer(wide)),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Sporty decorative backdrop for the SHOP area only; header and product cards are unchanged.
class StoreBackdrop extends StatelessWidget {
  const StoreBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 1100;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF07152F), Color(0xFF17386F), Color(0xFF0A1A3A)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(top: -100, left: -90, child: _glow(300, const Color(0xFF285A9C))),
          Positioned(bottom: -130, right: -80, child: _glow(360, const Color(0xFF173D76))),
          Positioned(
            top: 20, left: 0, right: 0, height: 8,
            child: Transform.rotate(
              angle: -0.035,
              child: Container(color: kOrange),
            ),
          ),
          Positioned(
            top: 70, left: -65, width: 280, height: 10,
            child: Transform.rotate(angle: -0.65, child: Container(color: const Color(0xFFFF7A1A))),
          ),
          Positioned(
            bottom: 110, right: -55, width: 310, height: 12,
            child: Transform.rotate(angle: -0.65, child: Container(color: const Color(0xFFFF7A1A))),
          ),
          if (wide) ...[
            Positioned(
              left: 22, top: 100,
              child: Transform.rotate(
                angle: -0.10,
                child: const Text('SNEAKERS', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0x66FFFFFF), letterSpacing: 1.4)),
              ),
            ),
            const Positioned(
              right: 22, top: 105,
              child: Text('JUST\nMOVE.', textAlign: TextAlign.right,
                style: TextStyle(fontSize: 25, height: 0.95, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0x55FFFFFF), letterSpacing: 1.1)),
            ),
            const Positioned(left: 25, bottom: 80, child: Icon(Icons.directions_run, size: 100, color: Color(0x22FFFFFF))),
            const Positioned(right: 18, bottom: 70, child: Icon(Icons.sports, size: 110, color: Color(0x22FFFFFF))),
          ],
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _SneakerDotsPainter()),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _glow(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.35),
          boxShadow: [BoxShadow(color: color.withOpacity(0.28), blurRadius: 70, spreadRadius: 25)]),
      );
}

class _SneakerDotsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.075);
    for (double x = 12; x < size.width; x += 22) {
      for (double y = 12; y < size.height; y += 22) {
        if ((x < size.width * 0.16 || x > size.width * 0.84) &&
            ((x + y).toInt() % 3 != 0)) {
          canvas.drawCircle(Offset(x, y), 1.5, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Heart button saved in Firestore: users/{uid}/favorites/{productId}
class FavButton extends StatelessWidget {
  final Product product;
  const FavButton({super.key, required this.product});
  @override
  Widget build(BuildContext context) {
    final ref = userRef.collection('favorites').doc(product.id);
    return StreamBuilder<DocumentSnapshot>(
      stream: ref.snapshots(),
      builder: (context, s) {
        final fav = s.data?.exists ?? false;
        return Material(
          color: Colors.white,
          elevation: 1,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => fav ? ref.delete() : ref.set(product.toMap()),
            child: Padding(
              padding: const EdgeInsets.all(7),
              child: Icon(fav ? Icons.favorite : Icons.favorite_border, size: 19, color: fav ? kRed : kNavy),
            ),
          ),
        );
      },
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;
  const ProductCard({super.key, required this.product});

  Widget _chip(Widget child, {Color bg = Colors.white}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1))],
        ),
        child: child,
      );

  Widget _badge(String t, Color bg, {IconData? icon}) => _chip(
        Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 12, color: Colors.white), const SizedBox(width: 3)],
          Text(t, style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w900, letterSpacing: .6)),
        ]),
        bg: bg,
      );

  @override
  Widget build(BuildContext context) {
    final p = product;
    final soldOut = p.stock <= 0;
    final low = !soldOut && p.stock <= 5;
    final save = p.sale ? oldPriceOf(p.price) - p.price.round() : 0;
    return Hoverable(
      builder: (hover) => AnimatedScale(
        scale: hover ? 1.03 : 1,
        duration: const Duration(milliseconds: 180),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailPage(product: p))),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: hover ? kOrange : kLine, width: hover ? 1.8 : 1),
              boxShadow: [
                BoxShadow(
                  color: kNavy.withValues(alpha: hover ? 0.2 : 0.07),
                  blurRadius: hover ? 24 : 12,
                  offset: Offset(0, hover ? 12 : 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(children: [
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                              begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF4F7FF), kImgBg]),
                        ),
                        child: AnimatedScale(
                          scale: hover ? 1.08 : 1,
                          duration: const Duration(milliseconds: 350),
                          child: Opacity(opacity: soldOut ? 0.45 : 1, child: shoeImage(p.imageUrl)),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 80,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Colors.black.withValues(alpha: 0.4), Colors.transparent],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        if (p.sale) ...[_badge('-15% OFF', kRed), const SizedBox(height: 4)],
                        if (p.isNew) ...[_badge('NEW', kNavy), const SizedBox(height: 4)],
                        if (p.trending) _badge('HOT', kOrange, icon: Icons.local_fire_department),
                      ]),
                    ),
                    Positioned(top: 8, right: 8, child: FavButton(product: p)),
                    Positioned(
                      left: 10,
                      bottom: 10,
                      child: _chip(Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.star, size: 14, color: kOrange),
                        const SizedBox(width: 3),
                        Text(p.rating.toStringAsFixed(1),
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: kNavy)),
                        Text(' (${p.reviews})', style: const TextStyle(color: kSoft, fontSize: 11)),
                      ])),
                    ),
                    if (low)
                      Positioned(
                        right: 10,
                        bottom: 10,
                        child: _chip(
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.bolt, size: 13, color: Colors.white),
                            Text('Only ${p.stock} left',
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                          ]),
                          bg: kAmber,
                        ),
                      ),
                    if (soldOut)
                      Center(
                        child: Transform.rotate(
                          angle: -0.2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(color: kSoldOut, borderRadius: BorderRadius.circular(6)),
                            child: const Text('SOLD OUT',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 13)),
                          ),
                        ),
                      ),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.brand.toUpperCase(),
                          style: const TextStyle(color: kOrange, fontSize: 10.5, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                      const SizedBox(height: 2),
                      Text(p.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: kNavy, height: 1.2)),
                      const SizedBox(height: 4),
                      Text(p.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: kSoft, fontSize: 12, height: 1.3)),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 6, children: [
                              Text(peso(p.price),
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: kNavy)),
                              if (p.sale)
                                Text(peso(oldPriceOf(p.price)),
                                    style: const TextStyle(
                                        fontSize: 12.5, color: kSoft, decoration: TextDecoration.lineThrough)),
                            ]),
                            if (p.sale)
                              Text('Save ${peso(save)}',
                                  style: const TextStyle(color: kStockGreen, fontSize: 11.5, fontWeight: FontWeight.w800)),
                          ]),
                        ),
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: soldOut ? kLine : kOrange,
                            shape: BoxShape.circle,
                            boxShadow: soldOut
                                ? null
                                : [BoxShadow(color: kOrange.withValues(alpha: 0.45), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: Icon(soldOut ? Icons.block : Icons.shopping_bag_outlined,
                              color: soldOut ? kSoft : Colors.black, size: 20),
                        ),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ================================================================ WISHLIST
class WishlistPage extends StatelessWidget {
  const WishlistPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Wishlist')),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: userRef.collection('favorites').snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final favDocs = snap.data!.docs;
            if (favDocs.isEmpty) {
              return const Center(child: Text('Your wishlist is empty. Tap the ♡ on any shoe.', style: TextStyle(color: kSoft)));
            }
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('products').snapshots(),
              builder: (context, ps) {
                final live = {for (final d in ps.data?.docs ?? <QueryDocumentSnapshot<Map<String, dynamic>>>[]) d.id: d.data()};
                final items = favDocs.map((d) => Product.fromMap(d.id, live[d.id] ?? d.data())).toList();
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 280, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 0.58),
                  itemCount: items.length,
                  itemBuilder: (_, i) => ProductCard(product: items[i]),
                );
              },
            );
          },
        ),
      );
}

// ================================================================ PRODUCT DETAILS
class ProductDetailPage extends StatefulWidget {
  final Product product;
  const ProductDetailPage({super.key, required this.product});
  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int? size;
  int qty = 1;
  int img = 0;
  String tab = 'Product details';
  static const tabNames = ['Product details', 'Size & fit guide', 'Delivery & returns', 'Customer reviews'];

  void snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<bool> addToCart(Product p, {bool quiet = false}) async {
    if (p.stock <= 0) {
      snack('This shoe is already sold out');
      return false;
    }
    if (size == null) {
      snack('Please choose a size first');
      return false;
    }
    final cartSnap = await userRef.collection('cart').get();
    var inBag = 0;
    for (final d in cartSnap.docs) {
      if (_pidOf(d) == p.id) inBag += _qtyOf(d);
    }
    if (inBag + qty > p.stock) {
      snack('Only ${p.stock} pairs left in stock (you already have $inBag in your cart)');
      return false;
    }
    await userRef.collection('cart').doc('${p.id}_$size').set({
      'productId': p.id,
      'name': p.name,
      'brand': p.brand,
      'price': p.price,
      'imageUrl': p.imageUrl,
      'size': size,
      'qty': FieldValue.increment(qty),
    }, SetOptions(merge: true));
    if (!quiet) snack('Added to cart');
    return true;
  }

  Future<void> buyNow(Product p) async {
    final ok = await addToCart(p, quiet: true);
    if (!ok || !mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => const CartPage()));
  }

  Widget _infoRow(String a, String b) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kLine))),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(a, style: const TextStyle(color: kSoft)),
          const SizedBox(width: 16),
          Flexible(
            child: Text(b, textAlign: TextAlign.right, style: const TextStyle(color: kText, fontWeight: FontWeight.w600)),
          ),
        ]),
      );

  Widget productInfo(Product p) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.list_alt, color: kNavy),
          SizedBox(width: 8),
          Text('Product Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kNavy)),
        ]),
        const SizedBox(height: 6),
        _infoRow('Brand', p.brand),
        _infoRow('Category', p.category),
        _infoRow('Suitable for', p.gender),
        _infoRow('Sizes (US)', p.sizes.isEmpty ? '-' : '${p.sizes.first} to ${p.sizes.last}'),
        _infoRow('Care', 'Keep clean and dry'),
      ]);

  Widget _perk(IconData icon, String title, String sub) => Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: Icon(icon, color: kOrange, size: 22),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: kNavy, fontWeight: FontWeight.w800, fontSize: 13.5)),
            Text(sub, style: const TextStyle(color: kSoft, fontSize: 12)),
          ]),
        ),
      ]);

  Widget perksStrip() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: kImgBg, borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Expanded(child: _perk(Icons.local_shipping, 'Flat ₱99 Shipping', 'On all orders')),
          const SizedBox(width: 8),
          Expanded(child: _perk(Icons.verified, 'Authentic', 'Quality-checked')),
        ]),
      );

  Future<void> editStock(Product p) async {
    final c = TextEditingController(text: '${p.stock}');
    final v = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update stock'),
        content: TextField(
          controller: c,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Number of pairs'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(90, 44)),
            onPressed: () => Navigator.pop(ctx, int.tryParse(c.text.trim())),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (v == null) return;
    try {
      await FirebaseFirestore.instance.collection('products').doc(p.id).update({'stock': v < 0 ? 0 : v});
      snack('Stock updated');
    } catch (e) {
      snack('Could not update: $e');
    }
  }

  Widget qtyStepper(int max) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: kLine, width: 1.6),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(onPressed: () => setState(() => qty = qty > 1 ? qty - 1 : 1), icon: const Icon(Icons.remove)),
          SizedBox(width: 28, child: Center(child: Text('$qty', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)))),
          IconButton(onPressed: () => setState(() => qty = qty < max ? qty + 1 : qty), icon: const Icon(Icons.add)),
        ]),
      );

  Widget tabContent(Product p) {
    switch (tab) {
      case 'Size & fit guide':
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Sizes are in US. If you are between two sizes, choose the larger one.'),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SizeGuidePage())),
            child: const Text('Open the full Size Guide'),
          ),
        ]);
      case 'Delivery & returns':
        return const Text('Flat shipping fee of ₱99. 30-day returns on unworn pairs. Authentic and quality-checked. '
            'Payment: Cash on Delivery, GCash or Maya.');
      case 'Customer reviews':
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            stars(p.rating),
            const SizedBox(width: 8),
            Text('${p.rating.toStringAsFixed(1)} out of 5 from ${p.reviews} reviews'),
          ]),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReviewsPage())),
            child: const Text('Read store reviews / Rate us'),
          ),
        ]);
      default:
        return Text(p.description.isEmpty ? 'No description yet.' : p.description);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('products').doc(widget.product.id).snapshots(),
      builder: (context, snap) {
        final p = (snap.hasData && snap.data!.exists) ? Product.fromMap(widget.product.id, snap.data!.data()!) : widget.product;
        final soldOut = p.stock <= 0;
        final wishRef = userRef.collection('favorites').doc(p.id);

        final gallery = Column(children: [
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(color: kImgBg, child: Opacity(opacity: soldOut ? 0.5 : 1, child: galleryView(p, img))),
            ),
          ),
          const SizedBox(height: 10),
          Row(children: [
            for (var i = 0; i < 4; i++)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 3 ? 8 : 0),
                  child: InkWell(
                    onTap: () => setState(() => img = i),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: kImgBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: img == i ? kBlue : Colors.transparent, width: 2),
                        ),
                        child: galleryView(p, i),
                      ),
                    ),
                  ),
                ),
              ),
          ]),
        ]);

        final info = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(spacing: 6, children: [
              tag(p.brand.toUpperCase(), bg: kNavy, fg: Colors.white),
              tag(p.category.toUpperCase(), bg: kImgBg, fg: kNavy),
              if (p.isNew) tag('NEW'),
              if (p.sale) tag('-15%'),
            ]),
            const SizedBox(height: 10),
            Text(p.name, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: kNavy, height: 1.1)),
            const SizedBox(height: 6),
            Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 10, children: [
              Text(peso(p.price), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: kOrange)),
              if (p.sale)
                Text(peso(oldPriceOf(p.price)),
                    style: const TextStyle(fontSize: 17, color: kSoft, decoration: TextDecoration.lineThrough)),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              stars(p.rating),
              const SizedBox(width: 8),
              Text('${p.rating.toStringAsFixed(1)} | ${p.reviews} reviews', style: const TextStyle(color: kSoft)),
            ]),
            const SizedBox(height: 10),
            Text(p.description, style: const TextStyle(color: kSoft, height: 1.45)),
            const SizedBox(height: 20),
            Row(children: [
              const Expanded(child: Text('Select shoe size (US)', style: TextStyle(fontWeight: FontWeight.w800, color: kNavy))),
              InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SizeGuidePage())),
                child: const Text('Size guide', style: TextStyle(color: kBlue, fontWeight: FontWeight.w700, decoration: TextDecoration.underline)),
              ),
            ]),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final s in p.sizes)
                InkWell(
                  onTap: soldOut ? null : () => setState(() => size = s),
                  borderRadius: BorderRadius.circular(8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 54,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: size == s ? kNavy : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: size == s ? kNavy : kLine, width: 1.6),
                    ),
                    child: Text('$s',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: soldOut ? Colors.black26 : (size == s ? Colors.white : kText))),
                  ),
                ),
            ]),
            const SizedBox(height: 18),
            // DESIGN: Quantity + Buy Now + Add to Cart
            Row(children: [
              const Text('Quantity', style: TextStyle(fontWeight: FontWeight.w800, color: kNavy)),
              const Spacer(),
              qtyStepper(p.stock > 0 ? p.stock : 1),
            ]),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: kOrange,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(0, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: soldOut ? null : () => buyNow(p),
                icon: const Icon(Icons.flash_on),
                label: Text(soldOut ? 'SOLD OUT' : 'BUY NOW'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: soldOut ? null : () => addToCart(p),
                icon: const Icon(Icons.add),
                label: const Text('ADD TO CART'),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 10, children: [
              stockLine(p.stock, size: 14),
              const Text('|', style: TextStyle(color: kSoft)),
              StreamBuilder<DocumentSnapshot>(
                stream: wishRef.snapshots(),
                builder: (context, s) {
                  final fav = s.data?.exists ?? false;
                  return InkWell(
                    onTap: () => fav ? wishRef.delete() : wishRef.set(p.toMap()),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(fav ? Icons.favorite : Icons.favorite_border, size: 18, color: fav ? kRed : kBlue),
                      const SizedBox(width: 4),
                      Text(fav ? 'In Wishlist' : 'Add to Wishlist',
                          style: const TextStyle(color: kBlue, fontWeight: FontWeight.w700)),
                    ]),
                  );
                },
              ),
            ]),
            const SizedBox(height: 16),
            const Divider(color: kLine),
            productInfo(p),
            const SizedBox(height: 16),
            perksStrip(),
          ],
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(p.name),
            actions: [
              IconButton(tooltip: 'Update stock', icon: const Icon(Icons.edit_outlined), onPressed: () => editStock(p)),
              IconButton(
                icon: const Icon(Icons.shopping_bag_outlined),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartPage())),
              ),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
                    InkWell(onTap: () => Navigator.popUntil(context, (r) => r.isFirst), child: const Text('Home', style: TextStyle(color: kBlue))),
                    const Text('  /  Sneakers  /  ', style: TextStyle(color: kSoft)),
                    Text(p.name, style: const TextStyle(color: kSoft, fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, cons) => cons.maxWidth >= 720
                        ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Expanded(child: gallery),
                            const SizedBox(width: 32),
                            Expanded(child: info),
                          ])
                        : Column(children: [gallery, const SizedBox(height: 20), info]),
                  ),
                  const SizedBox(height: 28),
                  const Divider(color: kLine),
                  Wrap(spacing: 4, children: [
                    for (final t in tabNames)
                      InkWell(
                        onTap: () => setState(() => tab = t),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: tab == t ? kOrange : Colors.transparent, width: 3)),
                          ),
                          child: Text(t, style: TextStyle(fontWeight: FontWeight.w700, color: tab == t ? kNavy : kSoft)),
                        ),
                      ),
                  ]),
                  const SizedBox(height: 12),
                  tabContent(p),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ================================================================ ADD PRODUCT
class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});
  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final name = TextEditingController();
  final brand = TextEditingController();
  final price = TextEditingController();
  final stock = TextEditingController(text: '10');
  final imageUrl = TextEditingController();
  final description = TextEditingController();
  final cats = const ['Lifestyle', 'Jordan', 'Running', 'Basketball', 'Football', 'Training & Gym', 'Skateboarding'];
  final genders = const ['Men', 'Women', 'Kids', 'Unisex'];
  String category = 'Lifestyle';
  String gender = 'Men';
  final Set<int> sizes = {7, 8, 9, 10, 11};
  bool isNew = true;
  bool sale = false;
  bool trending = false;
  bool saving = false;

  Future<void> save() async {
    if (name.text.trim().isEmpty || brand.text.trim().isEmpty || price.text.trim().isEmpty || sizes.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter the name, brand, price and at least one size')));
      return;
    }
    setState(() => saving = true);
    await FirebaseFirestore.instance.collection('products').add({
      'name': name.text.trim(),
      'brand': brand.text.trim(),
      'category': category,
      'gender': gender,
      'price': double.tryParse(price.text.trim()) ?? 0,
      'stock': (int.tryParse(stock.text.trim()) ?? 0).clamp(0, 100000),
      'imageUrl': imageUrl.text.trim(),
      'description': description.text.trim(),
      'sizes': (sizes.toList()..sort()),
      'isNew': isNew,
      'sale': sale,
      'trending': trending,
      'rating': 4.5,
      'reviews': 0,
    });
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product added')));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Add product')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (imageUrl.text.trim().isNotEmpty)
                  Container(
                    height: 200,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: kImgBg),
                    child: shoeImage(imageUrl.text.trim()),
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: imageUrl,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Image link',
                    helperText: 'Right-click the picture > Copy image address, then paste it here',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(controller: name, decoration: const InputDecoration(labelText: 'Shoe name')),
                const SizedBox(height: 12),
                TextField(controller: brand, decoration: const InputDecoration(labelText: 'Brand (Nike, Adidas, ...)')),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: TextField(
                        controller: price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price (₱)')),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                        controller: stock,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Stock (pairs)', prefixIcon: Icon(Icons.inventory_2_outlined))),
                  ),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: category,
                      items: [for (final c in cats) DropdownMenuItem(value: c, child: Text(c))],
                      onChanged: (v) => setState(() => category = v!),
                      decoration: const InputDecoration(labelText: 'Category'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: gender,
                      items: [for (final g in genders) DropdownMenuItem(value: g, child: Text(g))],
                      onChanged: (v) => setState(() => gender = v!),
                      decoration: const InputDecoration(labelText: 'For'),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                TextField(controller: description, maxLines: 3, decoration: const InputDecoration(labelText: 'Description')),
                const SizedBox(height: 16),
                const Text('Available sizes (US)', style: TextStyle(fontWeight: FontWeight.w800, color: kNavy)),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final s in [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13])
                    pill('$s', sizes.contains(s), () => setState(() => sizes.contains(s) ? sizes.remove(s) : sizes.add(s))),
                ]),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Mark as "New arrival"'),
                  value: isNew,
                  activeColor: kBlue,
                  onChanged: (v) => setState(() => isNew = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('On sale'),
                  value: sale,
                  activeColor: kBlue,
                  onChanged: (v) => setState(() => sale = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Show in Trending'),
                  value: trending,
                  activeColor: kBlue,
                  onChanged: (v) => setState(() => trending = v),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: saving ? null : save,
                  child: saving
                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('SAVE PRODUCT'),
                ),
              ],
            ),
          ),
        ),
      );
}

// ================================================================ ORDER SUMMARY (cart + checkout)
class OrderSummary extends StatelessWidget {
  final int subtotal, discount, shipping;
  final Widget? actions;
  const OrderSummary({super.key, required this.subtotal, required this.discount, required this.shipping, this.actions});

  Widget row(String a, String b) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(a, style: const TextStyle(color: kSoft)),
          Text(b, style: const TextStyle(fontWeight: FontWeight.w700, color: kText)),
        ]),
      );

  @override
  Widget build(BuildContext context) => panel(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Order Summary', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: kNavy)),
          const SizedBox(height: 8),
          row('Subtotal', peso(subtotal)),
          row('Shipping', peso(shipping)),
          row('Discount', peso(discount)),
          const Divider(color: kNavy, thickness: 2, height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('TOTAL', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: kNavy)),
            Text(peso(subtotal - discount + shipping),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kNavy)),
          ]),
          if (actions != null) ...[const SizedBox(height: 14), actions!],
        ],
      ));
}

// ================================================================ CART
class CartPage extends StatefulWidget {
  const CartPage({super.key});
  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final codeCtl = TextEditingController();
  double rate = 0;
  String code = '';

  void snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  void applyCode() {
    final c = codeCtl.text.trim().toUpperCase();
    final r = kDiscountCodes[c];
    setState(() {
      rate = r ?? 0;
      code = r == null ? '' : c;
    });
    snack(r == null ? 'Invalid code. Try SNEAK10' : 'Discount applied: $c');
  }

  Future<void> plus(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, QueryDocumentSnapshot<Map<String, dynamic>> d) async {
    final pid = _pidOf(d);
    final ps = await FirebaseFirestore.instance.collection('products').doc(pid).get();
    final stock = (ps.data()?['stock'] as num?)?.toInt() ?? 10;
    var inBag = 0;
    for (final x in docs) {
      if (_pidOf(x) == pid) inBag += _qtyOf(x);
    }
    if (inBag + 1 > stock) {
      if (mounted) snack('Only $stock pairs left in stock');
      return;
    }
    await d.reference.update({'qty': FieldValue.increment(1)});
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Shopping Cart')),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: userRef.collection('cart').snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snap.data!.docs;
            if (docs.isEmpty) {
              return Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.shopping_bag_outlined, size: 64, color: kLine),
                  const SizedBox(height: 10),
                  const Text('Your cart is empty', style: TextStyle(color: kSoft, fontSize: 16)),
                  const SizedBox(height: 14),
                  FilledButton(
                    style: FilledButton.styleFrom(minimumSize: const Size(200, 48)),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('CONTINUE SHOPPING'),
                  ),
                ]),
              );
            }
            double sub = 0;
            for (final d in docs) {
              sub += (d['price'] as num) * (d['qty'] as num);
            }
            final subtotal = sub.round();
            final discount = (subtotal * rate).round();

            final items = panel(
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Your Sneaker Cart', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kNavy)),
                for (final d in docs) ...[
                  const Divider(color: kLine, height: 24),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(color: kImgBg, width: 84, height: 84, child: shoeImage(d['imageUrl'] ?? '')),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(d['name'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: kNavy)),
                        const SizedBox(height: 2),
                        Text('Size ${d['size']} • Quantity: ${d['qty']}', style: const TextStyle(color: kSoft)),
                        const SizedBox(height: 6),
                        Row(children: [
                          InkWell(
                            onTap: () => (d['qty'] as num) > 1 ? d.reference.update({'qty': FieldValue.increment(-1)}) : null,
                            child: const Icon(Icons.remove_circle_outline, color: kBlue),
                          ),
                          const SizedBox(width: 8),
                          InkWell(onTap: () => plus(docs, d), child: const Icon(Icons.add_circle_outline, color: kBlue)),
                          const SizedBox(width: 14),
                          InkWell(
                            onTap: () => d.reference.delete(),
                            child: const Text('Remove', style: TextStyle(color: kBlue, decoration: TextDecoration.underline)),
                          ),
                        ]),
                      ]),
                    ),
                    Text(peso((d['price'] as num) * (d['qty'] as num)),
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: kOrange)),
                  ]),
                ],
                const Divider(color: kLine, height: 28),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: codeCtl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(labelText: 'Discount code', isDense: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(minimumSize: const Size(90, 46)),
                    onPressed: applyCode,
                    child: const Text('APPLY'),
                  ),
                ]),
              ]),
            );

            final summary = OrderSummary(
              subtotal: subtotal,
              discount: discount,
              shipping: kShipping,
              actions: Column(children: [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      // Guest checkout: no login prompt.
                      final fresh = await userRef.collection('cart').get();
                      if (fresh.docs.isEmpty || !context.mounted) return;
                      double s2 = 0;
                      for (final d in fresh.docs) {
                        s2 += (d['price'] as num) * (d['qty'] as num);
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CheckoutPage(docs: fresh.docs, subtotal: s2.round(), rate: rate, code: code),
                        ),
                      );
                    },
                    child: const Text('PROCEED TO CHECKOUT'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Continue Shopping')),
                ),
              ]),
            );

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: LayoutBuilder(
                    builder: (context, cons) => cons.maxWidth >= 760
                        ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Expanded(flex: 3, child: items),
                            const SizedBox(width: 16),
                            Expanded(flex: 2, child: summary),
                          ])
                        : Column(children: [items, const SizedBox(height: 16), summary]),
                  ),
                ),
              ),
            );
          },
        ),
      );
}

// ================================================================ CHECKOUT
class CheckoutPage extends StatefulWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  final int subtotal;
  final double rate;
  final String code;
  const CheckoutPage({super.key, required this.docs, required this.subtotal, required this.rate, required this.code});
  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  static const stepNames = ['Contact details', 'Delivery address', 'Payment method', 'Review order'];
  int step = 0;
  bool loading = false;
  final name = TextEditingController();
  final phone = TextEditingController();
  final address = TextEditingController();
  final emailCtl = TextEditingController();
  final city = TextEditingController();
  final payRef = TextEditingController();
  String payment = kPayCod;

  int get discount => (widget.subtotal * widget.rate).round();
  int get total => widget.subtotal - discount + kShipping;
  // GCash and Maya are chosen on the secure Xendit hosted payment page.
  bool get online => false;
  bool get useXendit => payment == kPayXendit;

  void snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  void next() {
    if (step == 0 && (name.text.trim().isEmpty || phone.text.trim().isEmpty)) {
      snack('Enter your name and phone number');
      return;
    }
    if (step == 0 && !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(emailCtl.text.trim())) {
      snack('Enter a valid email');
      return;
    }
    if (step == 1 && (address.text.trim().isEmpty || city.text.trim().isEmpty)) {
      snack('Enter your address and city');
      return;
    }
    if (step == 2 && online && payRef.text.trim().length < 6) {
      snack('Enter the $payment reference number of your payment');
      return;
    }
    if (step < 3) {
      setState(() => step++);
    } else {
      placeOrder();
    }
  }

  Future<void> placeOrder() async {
    setState(() => loading = true);
    final db = FirebaseFirestore.instance;
    final isOnline = online;
    // FIX: the declaration and the Firestore map line used to be mixed together here (syntax error).
    String? xenditInvoiceId;
    String? xenditRef;

    // Xendit: create an invoice, open the secure payment page, and
    // wait for a confirmed PAID/SETTLED status before creating the order.
    if (useXendit) {
      try {
        final invoice = await XenditService.createInvoice(
          amount: total,
          email: emailCtl.text.trim(),
          description: 'SNEAKERS order',
        );
        final id = invoice['id']?.toString();
        final url = invoice['invoice_url']?.toString();
        if (id == null || id.isEmpty || url == null || url.isEmpty) {
          throw Exception('Incomplete invoice details from Xendit.');
        }
        xenditInvoiceId = id;
        xenditRef = invoice['external_id']?.toString();
        if (!mounted) return;
        final paid = await payInvoice(context, id, url);
        if (!mounted) return;
        if (!paid) {
          setState(() => loading = false);
          snack('Payment not confirmed yet. If you already paid, check the Xendit dashboard first before trying again.');
          return;
        }
      } catch (e) {
        if (!mounted) return;
        setState(() => loading = false);
        snack('Could not start the Xendit payment: $e');
        return;
      }
    }

    final orderRef = userRef.collection('orders').doc();
    try {
      // Transaction: checks and deducts stock, then creates the order
      await db.runTransaction((tx) async {
        final need = <String, int>{};
        for (final d in widget.docs) {
          need[_pidOf(d)] = (need[_pidOf(d)] ?? 0) + _qtyOf(d);
        }
        final snaps = <String, DocumentSnapshot<Map<String, dynamic>>>{};
        for (final pid in need.keys) {
          snaps[pid] = await tx.get(db.collection('products').doc(pid));
        }
        for (final e in need.entries) {
          final s = snaps[e.key]!;
          if (!s.exists) continue;
          final stock = (s.data()?['stock'] as num?)?.toInt() ?? 10;
          if (stock < e.value) {
            throw StateError('Not enough stock for ${s.data()?['name'] ?? 'item'} (remaining: $stock)');
          }
          tx.update(s.reference, {'stock': stock - e.value});
        }
        tx.set(orderRef, {
          'items': widget.docs.map((d) {
            final m = d.data();
            return {...m, 'productId': _pidOf(d)};
          }).toList(),
          'subtotal': widget.subtotal,
          'shipping': kShipping,
          'discount': discount,
          'discountCode': widget.code,
          'total': total,
          'name': name.text.trim(),
          'phone': phone.text.trim(),
          'email': FirebaseAuth.instance.currentUser?.email ?? '',
          'address': '${address.text.trim()}, ${city.text.trim()}',
          'payment': payment,
          'paymentRef': isOnline ? payRef.text.trim() : '',
          'xenditInvoiceId': xenditInvoiceId ?? '',
          'xenditRef': xenditRef ?? '',
          'paymentStatus': useXendit ? 'PAID' : (isOnline ? 'AWAITING_VERIFICATION' : 'PENDING'),
          // Manual GCash/Maya needs manual verification; Xendit is saved as paid only after status check.
          'status': useXendit ? 'Paid' : (isOnline ? 'Awaiting Verification' : 'Pending'),
          'createdAt': FieldValue.serverTimestamp(),
        });
        for (final d in widget.docs) {
          tx.delete(d.reference);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      snack(e is StateError ? e.message : 'Could not complete the order: $e');
      return;
    }
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    navigator.popUntil((r) => r.isFirst);
    if (useXendit) {
      navigator.push(MaterialPageRoute(builder: (_) => const OrderHistoryPage()));
    }
    if (useXendit) {
      final names = widget.docs.map((d) => d['name'].toString()).toList();
      final label = names.isEmpty ? 'Order' : (names.length == 1 ? names.first : '${names.first} +${names.length - 1} more');
      messenger.showSnackBar(SnackBar(
        backgroundColor: kGreen,
        content: Text('Payment Verified: $label is PAID',
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
      ));
      return;
    }
    messenger.showSnackBar(SnackBar(
        content: Text(useXendit
            ? 'Payment confirmed! Order placed. Thank you for your order.'
            : isOnline
                ? 'Order placed! We will confirm your $payment payment.'
                : 'Order placed! Thank you for your order.')));
  }

  Widget stepBar() => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          for (var i = 0; i < 4; i++) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: i == step ? kBlue : (i < step ? kNavy : kLine),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text('${i + 1}. ${stepNames[i]}',
                  style: TextStyle(color: i <= step ? Colors.white : kSoft, fontWeight: FontWeight.w700, fontSize: 13)),
            ),
            if (i < 3) const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Icon(Icons.chevron_right, color: kSoft, size: 18)),
          ],
        ]),
      );

  /// Payment instructions + QR code for GCash or Maya
  Widget payBox() {
    final maya = payment == kPayMaya;
    final number = maya ? kMayaNumber : kGcashNumber;
    final accName = maya ? kMayaName : kGcashName;
    final asset = maya ? kMayaQrAsset : kGcashQrAsset;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: kImgBg, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('How to pay with $payment', style: const TextStyle(fontWeight: FontWeight.w900, color: kNavy)),
        const SizedBox(height: 10),
        Center(child: PayQr(asset: asset, data: number)),
        const SizedBox(height: 8),
        Center(
          child: Text('Scan the QR code with the $payment app',
              textAlign: TextAlign.center, style: const TextStyle(color: kSoft, fontSize: 12.5)),
        ),
        const SizedBox(height: 12),
        Text(
          '1. Open the $payment app > Scan QR (or Send Money).\n'
          '2. Send exactly ${peso(total)} to:\n'
          '    $number  ($accName)\n'
          '3. Copy the Reference No. from the receipt and enter it below.',
          style: const TextStyle(color: kText, height: 1.5),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
          onPressed: () => copyText(context, number, '$payment number copied'),
          child: Text('COPY ${payment.toUpperCase()} NUMBER'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: payRef,
          style: const TextStyle(color: kText),
          decoration: InputDecoration(
              labelText: '$payment reference number', prefixIcon: const Icon(Icons.receipt_long_outlined)),
        ),
      ]),
    );
  }

  Widget stepBody() {
    switch (step) {
      case 0:
        return Column(children: [
          TextField(
            controller: name,
            decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Phone number', prefixIcon: Icon(Icons.phone_outlined)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: emailCtl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
          ),
        ]);
      case 1:
        return Column(children: [
          TextField(
              controller: address,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Complete address', prefixIcon: Icon(Icons.home_outlined))),
          const SizedBox(height: 12),
          TextField(controller: city, decoration: const InputDecoration(labelText: 'City', prefixIcon: Icon(Icons.location_city_outlined))),
        ]);
      case 2:
        return Column(children: [
          RadioListTile<String>(
            value: kPayCod,
            groupValue: payment,
            onChanged: (v) => setState(() => payment = v!),
            title: const Text('Cash on Delivery'),
            subtitle: const Text('Pay when your order arrives'),
            activeColor: kBlue,
            contentPadding: EdgeInsets.zero,
          ),
          RadioListTile<String>(
            value: kPayXendit,
            groupValue: payment,
            onChanged: (v) => setState(() => payment = v!),
            title: const Text('Online payment (Xendit Test Mode)'),
            subtitle: const Text('Choose GCash or Maya on the secure Xendit payment page'),
            activeColor: kBlue,
            contentPadding: EdgeInsets.zero,
          ),
        ]);
      default:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (final d in widget.docs)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Text('${d['qty']}x ${d['name']} (US ${d['size']})', style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          const Divider(color: kLine, height: 24),
          Text('${name.text.trim()}  •  ${phone.text.trim()}'),
          const SizedBox(height: 4),
          Text('${address.text.trim()}, ${city.text.trim()}', style: const TextStyle(color: kSoft)),
          const SizedBox(height: 4),
          Text('Payment: $payment', style: const TextStyle(color: kSoft)),
          if (online) ...[
            const SizedBox(height: 4),
            Text('$payment ref: ${payRef.text.trim()}', style: const TextStyle(color: kSoft)),
          ],
        ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final form = panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(stepNames[step], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: kNavy)),
      const SizedBox(height: 14),
      stepBody(),
      const SizedBox(height: 18),
      Row(children: [
        if (step > 0) ...[
          OutlinedButton(
            style: OutlinedButton.styleFrom(minimumSize: const Size(90, 48)),
            onPressed: loading ? null : () => setState(() => step--),
            child: const Text('Back'),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: FilledButton(
            onPressed: loading ? null : next,
            child: loading
                ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(step < 3 ? 'CONTINUE' : 'PLACE ORDER'),
          ),
        ),
      ]),
    ]));
    final summary = OrderSummary(subtotal: widget.subtotal, discount: discount, shipping: kShipping);

    return Scaffold(
      appBar: AppBar(title: const Text('Secure checkout')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              stepBar(),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, cons) => cons.maxWidth >= 760
                    ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(flex: 3, child: form),
                        const SizedBox(width: 16),
                        Expanded(flex: 2, child: summary),
                      ])
                    : Column(children: [form, const SizedBox(height: 16), summary]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ================================================================ ORDERS
class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('My Orders')),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: userRef.collection('orders').orderBy('createdAt', descending: true).snapshots(),
          builder: (context, snap) {
            if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snap.data!.docs;
            if (docs.isEmpty) return const Center(child: Text('You have no orders yet', style: TextStyle(color: kSoft)));
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final o = docs[i].data();
                    final items = (o['items'] as List).cast<Map<String, dynamic>>();
                    final dt = (o['createdAt'] as Timestamp?)?.toDate();
                    final date = dt == null ? '' : '${dt.day}/${dt.month}/${dt.year}';
                    final status = (o['status'] ?? 'Pending').toString();
                    final statusBg = status == 'Paid'
                        ? kStockGreen
                        : (status == 'Expired' ? kSoldOut : (status == 'Awaiting Verification' ? kAmber : kOrange));
                    final statusFg = status == 'Pending' ? Colors.black : Colors.white;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text(date, style: const TextStyle(color: kSoft)),
                          tag(status.toUpperCase(), bg: statusBg, fg: statusFg),
                        ]),
                        const SizedBox(height: 8),
                        for (final it in items) Text('${it['qty']}x ${it['name']} (US ${it['size']})'),
                        const Divider(color: kLine, height: 20),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text('${o['payment']}', style: const TextStyle(color: kSoft)),
                          Text(peso(o['total']), style: const TextStyle(fontWeight: FontWeight.w900, color: kNavy, fontSize: 17)),
                        ]),
                        const SizedBox(height: 4),
                        Text(o['address'] ?? '', style: const TextStyle(color: kSoft)),
                        if ((o['paymentRef'] ?? '').toString().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('${o['payment']} ref: ${o['paymentRef']}', style: const TextStyle(color: kSoft)),
                        ],
                      ])),
                    );
                  },
                ),
              ),
            );
          },
        ),
      );
}

// ================================================================ ORDER HISTORY

/// Order history: reads users/{uid}/orders (the same path the checkout writes to).
class OrderHistoryPage extends StatelessWidget {
  const OrderHistoryPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Order History')),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: userRef.collection('orders').orderBy('createdAt', descending: true).snapshots(),
          builder: (context, snap) {
            if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snap.data!.docs;
            if (docs.isEmpty) {
              return const Center(child: Text('You have no orders yet', style: TextStyle(color: kSoft)));
            }
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final o = docs[i].data();
                    final items = ((o['items'] as List?) ?? const []).cast<Map<String, dynamic>>();
                    final dt = (o['createdAt'] as Timestamp?)?.toDate();
                    final date = dt == null ? 'Processing...' : '${dt.day}/${dt.month}/${dt.year}';
                    final status = (o['status'] ?? 'Pending').toString();
                    final statusBg = status == 'Paid'
                        ? kStockGreen
                        : (status == 'Expired' ? kSoldOut : (status == 'Awaiting Verification' ? kAmber : kOrange));
                    final statusFg = status == 'Pending' ? Colors.black : Colors.white;
                    final invoice = (o['xenditInvoiceId'] ?? '').toString();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text(date, style: const TextStyle(color: kSoft)),
                          tag(status.toUpperCase(), bg: statusBg, fg: statusFg),
                        ]),
                        const SizedBox(height: 8),
                        for (final it in items) Text('${it['qty']}x ${it['name']} (US ${it['size']})'),
                        const Divider(color: kLine, height: 20),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text('${o['payment'] ?? ''}', style: const TextStyle(color: kSoft)),
                          Text(peso((o['total'] as num?) ?? 0),
                              style: const TextStyle(fontWeight: FontWeight.w900, color: kNavy, fontSize: 17)),
                        ]),
                        const SizedBox(height: 4),
                        Text((o['address'] ?? '').toString(), style: const TextStyle(color: kSoft)),
                        if (invoice.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('Xendit invoice: $invoice', style: const TextStyle(color: kSoft, fontSize: 12)),
                        ],
                      ])),
                    );
                  },
                ),
              ),
            );
          },
        ),
      );
}

// ================================================================ XENDIT PAYMENT

/// Opens the Xendit checkout INSIDE the app (WebView) and automatically
/// verifies the payment. Returns true when PAID/SETTLED, false if
/// EXPIRED, cancelled (back), or unpaid.
Future<bool> payInvoice(BuildContext context, String invoiceId, String invoiceUrl) async {
  final r = await Navigator.push<bool>(
    context,
    MaterialPageRoute(builder: (_) => XenditCheckoutPage(invoiceId: invoiceId, url: invoiceUrl)),
  );
  return r ?? false;
}

class XenditCheckoutPage extends StatefulWidget {
  final String invoiceId, url;
  const XenditCheckoutPage({super.key, required this.invoiceId, required this.url});
  @override
  State<XenditCheckoutPage> createState() => _XenditCheckoutPageState();
}

class _XenditCheckoutPageState extends State<XenditCheckoutPage> {
  WebViewController? _web;
  bool _pageLoading = true;
  bool _stop = false;
  bool _paid = false; // true once the payment is confirmed

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      XenditService.openInvoice(widget.url).catchError((_) {});
    } else {
      _web = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(NavigationDelegate(onPageFinished: (_) {
          if (mounted) setState(() => _pageLoading = false);
        }))
        ..loadRequest(Uri.parse(widget.url));
    }
    _poll();
  }

  @override
  void dispose() {
    _stop = true;
    super.dispose();
  }

  /// Asks Xendit every 3 seconds while the checkout is open.
  Future<void> _poll() async {
    final deadline = DateTime.now().add(const Duration(minutes: 15));
    while (!_stop && DateTime.now().isBefore(deadline)) {
      await Future.delayed(const Duration(seconds: 3));
      if (_stop || !mounted) return;
      try {
        final status = await XenditService.getStatus(widget.invoiceId);
        if (status == 'PAID' || status == 'SETTLED') {
          _stop = true;
          // Show the "Done" screen. Do NOT close yet.
          if (mounted) setState(() => _paid = true);
          return;
        }
        if (status == 'EXPIRED') {
          if (!_stop && mounted) {
            _stop = true;
            Navigator.pop(context, false);
          }
          return;
        }
      } catch (_) {
        // network hiccup, try again
      }
    }
    if (!_stop && mounted) {
      _stop = true;
      Navigator.pop(context, false);
    }
  }

  void _done() {
    if (mounted) Navigator.pop(context, true);
  }

  Widget _successView() => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: const BoxDecoration(color: kStockGreen, shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Colors.white, size: 64),
              ),
              const SizedBox(height: 22),
              const Text('Payment Successful!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: kNavy)),
              const SizedBox(height: 8),
              const Text('We have received your payment.\nTap DONE to see your order.',
                  textAlign: TextAlign.center, style: TextStyle(color: kSoft, height: 1.4)),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: kOrange,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(0, 54),
                  ),
                  onPressed: _done,
                  child: const Text('DONE'),
                ),
              ),
            ]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => PopScope(
        // Once paid, going back is blocked without saving the order.
        canPop: !_paid,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && _paid) _done();
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(_paid ? 'Payment Complete' : 'Xendit Checkout'),
            automaticallyImplyLeading: !_paid,
          ),
          body: _paid
              ? _successView()
              : (_web == null
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('The Xendit payment page was opened in a new tab.\nWaiting for your payment...',
                              textAlign: TextAlign.center),
                        ]),
                      ),
                    )
                  : Stack(children: [
                      WebViewWidget(controller: _web!),
                      if (_pageLoading) const Center(child: CircularProgressIndicator()),
                    ])),
        ),
      );
}