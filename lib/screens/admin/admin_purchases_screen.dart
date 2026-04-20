import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:notes_hub/consts/app_colors.dart';
import 'package:notes_hub/widgets/admin/admin_section_card.dart';
import 'package:notes_hub/widgets/subtitle_text.dart';
import 'package:notes_hub/widgets/title_text.dart';

class AdminPurchasesScreen extends StatelessWidget {
  const AdminPurchasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .orderBy('orderDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: SelectableText(snapshot.error.toString()));
        }

        final orderDocs = snapshot.data?.docs ?? const [];
        return SingleChildScrollView(
          child: AdminSectionCard(
            title: 'Kupovine',
            subtitle: 'Pregled stvarnih transakcija i kupljenih skripti iz baze.',
            child: orderDocs.isEmpty
                ? const SubtitleTextWidget(
                    label: 'Još nema kupovina za prikaz.',
                    color: AppColors.muted,
                  )
                : Column(
                    children: orderDocs.map((doc) {
                      final data = doc.data();
                      final productTitle =
                          (data['productTitle'] ?? 'Nepoznata skripta').toString();
                      final userName = (data['userName'] ?? 'Korisnik').toString();
                      final amount = (data['price'] ?? 0).toString();
                      final paymentProvider =
                          (data['paymentProvider'] ?? 'manual').toString();
                      final paymentStatus =
                          (data['paymentStatus'] ?? 'legacy').toString();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TitelesTextWidget(label: productTitle, fontSize: 17),
                                  const SizedBox(height: 4),
                                  SubtitleTextWidget(
                                    label:
                                        'Kupac: $userName | Status: $paymentStatus | Provider: $paymentProvider',
                                    maxLines: 2,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            SubtitleTextWidget(
                              label: '$amount RSD',
                              fontWeight: FontWeight.w800,
                              color: AppColors.accent,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
        );
      },
    );
  }
}
