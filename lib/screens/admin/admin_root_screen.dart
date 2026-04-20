import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:notes_hub/models/admin_nav_item.dart';
import 'package:notes_hub/screens/admin/admin_dashboard_screen.dart';
import 'package:notes_hub/screens/admin/admin_purchases_screen.dart';
import 'package:notes_hub/screens/admin/admin_reviews_screen.dart';
import 'package:notes_hub/screens/admin/admin_scripts_screen.dart';
import 'package:notes_hub/screens/admin/admin_users_screen.dart';
import 'package:notes_hub/services/admin_access_service.dart';
import 'package:notes_hub/widgets/admin/admin_shell.dart';

class AdminRootScreen extends StatefulWidget {
  static const routeName = '/admin';

  const AdminRootScreen({super.key});

  @override
  State<AdminRootScreen> createState() => _AdminRootScreenState();
}

class _AdminRootScreenState extends State<AdminRootScreen> {
  int _currentIndex = 0;

  static const items = [
    AdminNavItem(label: 'Kontrolna tabla', icon: Icons.dashboard_outlined),
    AdminNavItem(label: 'Skripte', icon: Icons.menu_book_outlined),
    AdminNavItem(
      label: 'Kupovine',
      icon: Icons.shopping_cart_checkout_outlined,
    ),
    AdminNavItem(label: 'Korisnici', icon: Icons.group_outlined),
    AdminNavItem(label: 'Recenzije', icon: Icons.reviews_outlined),
  ];

  static const pages = [
    AdminDashboardScreen(),
    AdminScriptsScreen(),
    AdminPurchasesScreen(),
    AdminUsersScreen(),
    AdminReviewsScreen(),
  ];

  static const titles = [
    'Kontrolna tabla',
    'Skripte',
    'Kupovine',
    'Korisnici',
    'Recenzije',
  ];

  static const subtitles = [
    'Pregled glavnih admin pokazatelja i prioriteta za UniNotes.',
    'Listing svih skripti sa mestom za odobravanje, izmenu i moderaciju.',
    'Pregled transakcija i kupljenih skripti kroz sistem.',
    'Administracija korisnickih naloga i korisnickih uloga.',
    'Moderacija ocena, komentara i prijavljenog sadrzaja.',
  ];

  Future<bool> _isCurrentUserAdmin() async {
    return AdminAccessService.isAdminUser(FirebaseAuth.instance.currentUser);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isCurrentUserAdmin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final isAdmin = snapshot.data == true;
        if (!isAdmin) {
          return Scaffold(
            appBar: AppBar(title: const Text('Admin pristup')),
            body: const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Ovaj nalog nema admin pristup. Dodaj isAdmin: true, role: "admin" ili napravi dokument u admins kolekciji sa UID-jem ili email-om korisnika.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        return AdminShell(
          currentIndex: _currentIndex,
          title: titles[_currentIndex],
          subtitle: subtitles[_currentIndex],
          items: items,
          onSelect: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          child: pages[_currentIndex],
        );
      },
    );
  }
}
