import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:notes_hub/consts/app_colors.dart';
import 'package:notes_hub/widgets/admin/admin_section_card.dart';
import 'package:notes_hub/widgets/subtitle_text.dart';
import 'package:notes_hub/widgets/title_text.dart';

class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: SelectableText(snapshot.error.toString()));
        }

        final docs = snapshot.data?.docs.toList() ?? [];
        docs.sort((a, b) {
          final aTime = (a.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
          final bTime = (b.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
          return bTime.compareTo(aTime);
        });

        return SingleChildScrollView(
          child: AdminSectionCard(
            title: 'Korisnici',
            subtitle: 'Pregled stvarnih naloga iz Firestore baze.',
            child: docs.isEmpty
                ? const SubtitleTextWidget(
                    label: 'Još nema korisnika u bazi.',
                    color: AppColors.muted,
                  )
                : Column(
                    children: docs.map((doc) {
                      final data = doc.data();
                      final userName = (data['userName'] ?? 'Korisnik').toString();
                      final userEmail = (data['userEmail'] ?? 'Bez mejla').toString();
                      final role = data['isAdmin'] == true ||
                              (data['role'] ?? '').toString().toLowerCase() == 'admin'
                          ? 'Admin'
                          : 'User';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor:
                                  AppColors.lightPrimary.withValues(alpha: 0.12),
                              child: const Icon(Icons.person_outline_rounded),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TitelesTextWidget(label: userName, fontSize: 17),
                                  const SizedBox(height: 4),
                                  SubtitleTextWidget(label: userEmail),
                                ],
                              ),
                            ),
                            SubtitleTextWidget(
                              label: role,
                              fontWeight: FontWeight.w700,
                              color: role == 'Admin'
                                  ? AppColors.lightPrimary
                                  : AppColors.textDark,
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
