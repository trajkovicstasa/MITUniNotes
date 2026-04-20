import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:notes_hub/models/admin_nav_item.dart';
import 'package:notes_hub/screens/admin/admin_dashboard_screen.dart';
import 'package:notes_hub/screens/admin/admin_purchases_screen.dart';
import 'package:notes_hub/screens/admin/admin_reviews_screen.dart';
import 'package:notes_hub/screens/admin/admin_scripts_screen.dart';
import 'package:notes_hub/screens/admin/admin_users_screen.dart';
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return false;
    }

    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = userDoc.data();
    if (data == null) {
      return false;
    }

    return data['isAdmin'] == true ||
        (data['role'] ?? '').toString().toLowerCase() == 'admin';
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
                  'Ovaj nalog nema admin pristup. Dodaj role: "admin" ili isAdmin: true u Firestore users dokument ako zelis admin ulaz.',
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
