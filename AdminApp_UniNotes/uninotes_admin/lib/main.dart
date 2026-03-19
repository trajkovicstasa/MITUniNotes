import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uninotes_admin/consts/theme_data.dart';
import 'package:uninotes_admin/models/admin_nav_item.dart';
import 'package:uninotes_admin/providers/products_provider.dart';
import 'package:uninotes_admin/screens/dashboard_screen.dart';
import 'package:uninotes_admin/screens/purchases_screen.dart';
import 'package:uninotes_admin/screens/reviews_screen.dart';
import 'package:uninotes_admin/screens/scripts_screen.dart';
import 'package:uninotes_admin/screens/upload_script_screen.dart';
import 'package:uninotes_admin/screens/users_screen.dart';
import 'package:uninotes_admin/widgets/dashboard_shell.dart';

void main() {
  runApp(const MyApp());
}

class AdminNavigationController extends ChangeNotifier {
  int currentIndex = 0;

  void selectIndex(int index) {
    if (currentIndex == index) {
      return;
    }
    currentIndex = index;
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Firebase.initializeApp(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AdminTheme.themeData(),
            home: const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        } else if (snapshot.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AdminTheme.themeData(),
            home: Scaffold(
              body: Center(child: SelectableText(snapshot.error.toString())),
            ),
          );
        }
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AdminNavigationController()),
            ChangeNotifierProvider(create: (_) => ProductsProvider()),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'UniNotes Admin',
            theme: AdminTheme.themeData(),
            home: const AdminRoot(),
          ),
        );
      },
    );
  }
}

class AdminRoot extends StatelessWidget {
  const AdminRoot({super.key});

  static const items = [
    AdminNavItem(label: 'Dashboard', icon: Icons.dashboard_outlined),
    AdminNavItem(label: 'Skripte', icon: Icons.menu_book_outlined),
    AdminNavItem(label: 'Dodaj skriptu', icon: Icons.add_circle_outline_rounded),
    AdminNavItem(
      label: 'Kupovine',
      icon: Icons.shopping_cart_checkout_outlined,
    ),
    AdminNavItem(label: 'Korisnici', icon: Icons.group_outlined),
    AdminNavItem(label: 'Recenzije', icon: Icons.reviews_outlined),
  ];

  static const pages = [
    DashboardScreen(),
    ScriptsScreen(),
    UploadScriptScreen(),
    PurchasesScreen(),
    UsersScreen(),
    ReviewsScreen(),
  ];

  static const titles = [
    'Dashboard',
    'Skripte',
    'Dodaj skriptu',
    'Kupovine',
    'Korisnici',
    'Recenzije',
  ];

  static const subtitles = [
    'Pregled glavnih admin pokazatelja i prioriteta za UniNotes.',
    'Listing svih skripti sa mestom za odobravanje, izmenu i moderaciju.',
    'Forma za unos novih skripti, cover slika i PDF dokumenata.',
    'Pregled transakcija i kupljenih skripti kroz sistem.',
    'Administracija korisnickih naloga i korisnickih uloga.',
    'Moderacija ocena, komentara i prijavljenog sadrzaja.',
  ];

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AdminNavigationController>();

    return DashboardShell(
      currentIndex: controller.currentIndex,
      title: titles[controller.currentIndex],
      subtitle: subtitles[controller.currentIndex],
      items: items,
      onSelect: controller.selectIndex,
      child: pages[controller.currentIndex],
    );
  }
}
