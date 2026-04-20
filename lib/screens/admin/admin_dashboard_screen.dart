import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:notes_hub/consts/app_colors.dart';
import 'package:notes_hub/services/admin_access_service.dart';
import 'package:notes_hub/widgets/admin/admin_section_card.dart';
import 'package:notes_hub/widgets/admin/admin_stat_card.dart';
import 'package:notes_hub/widgets/subtitle_text.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('products').snapshots(),
      builder: (context, productsSnapshot) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, usersSnapshot) {
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('orders').snapshots(),
              builder: (context, ordersSnapshot) {
                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance.collection('reviews').snapshots(),
                  builder: (context, reviewsSnapshot) {
                    if (productsSnapshot.connectionState == ConnectionState.waiting ||
                        usersSnapshot.connectionState == ConnectionState.waiting ||
                        ordersSnapshot.connectionState == ConnectionState.waiting ||
                        reviewsSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final productDocs = productsSnapshot.data?.docs ?? const [];
                    final userDocs = usersSnapshot.data?.docs ?? const [];
                    final orderDocs = ordersSnapshot.data?.docs ?? const [];
                    final reviewDocs = reviewsSnapshot.data?.docs ?? const [];

                    final pendingCount = productDocs.where((doc) {
                      return (doc.data()['status'] ?? '').toString() == 'pending';
                    }).length;
                    final reportedReviews = reviewDocs.where((doc) {
                      return doc.data()['reported'] == true;
                    }).length;
                    final adminCount = userDocs.where((doc) {
                      final data = doc.data();
                      return AdminAccessService.isAdminFromUserMap(data);
                    }).length;

                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final width = constraints.maxWidth;
                              final columns = width >= 1280
                                  ? 4
                                  : width >= 760
                                      ? 2
                                      : 1;
                              return GridView.count(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: columns,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: 1.55,
                                children: [
                                  AdminStatCard(
                                    title: 'Ukupno skripti',
                                    value: productDocs.length.toString(),
                                    icon: Icons.menu_book_rounded,
                                    color: AppColors.lightPrimary,
                                  ),
                                  AdminStatCard(
                                    title: 'Na cekanju',
                                    value: pendingCount.toString(),
                                    icon: Icons.pending_actions_rounded,
                                    color: Colors.orange,
                                  ),
                                  AdminStatCard(
                                    title: 'Korisnici',
                                    value: userDocs.length.toString(),
                                    icon: Icons.group_rounded,
                                    color: AppColors.accent,
                                  ),
                                  AdminStatCard(
                                    title: 'Kupovine',
                                    value: orderDocs.length.toString(),
                                    icon: Icons.shopping_cart_checkout_rounded,
                                    color: Colors.green,
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: AdminSectionCard(
                                  title: 'Prioritetne stavke',
                                  subtitle: 'Sažet pregled onoga što trenutno traži pažnju.',
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _ActionLine(
                                        '${pendingCount.toString()} skripti čeka odobrenje',
                                      ),
                                      const SizedBox(height: 10),
                                      _ActionLine(
                                        '${reportedReviews.toString()} prijavljenih recenzija za proveru',
                                      ),
                                      const SizedBox(height: 10),
                                      _ActionLine(
                                        '${adminCount.toString()} admin naloga evidentirano u sistemu',
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: AdminSectionCard(
                                  title: 'Stanje sistema',
                                  subtitle: 'Brz pregled podataka vezanih za sadržaj i promet.',
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _ActionLine(
                                        '${productDocs.where((doc) => (doc.data()['status'] ?? '').toString() == 'approved').length} odobrenih skripti je vidljivo korisnicima',
                                      ),
                                      const SizedBox(height: 10),
                                      _ActionLine(
                                        '${orderDocs.where((doc) => (doc.data()['paymentProvider'] ?? '').toString() == 'paypal').length} kupovina je prošlo kroz PayPal tok',
                                      ),
                                      const SizedBox(height: 10),
                                      _ActionLine(
                                        '${reviewDocs.length} ukupno recenzija postoji u bazi',
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _ActionLine extends StatelessWidget {
  const _ActionLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SubtitleTextWidget(
            label: text,
            color: AppColors.textDark,
            fontWeight: FontWeight.w600,
            maxLines: 3,
          ),
        ),
      ],
    );
  }
}
