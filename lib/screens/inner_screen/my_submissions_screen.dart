import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:notes_hub/consts/app_colors.dart';
import 'package:notes_hub/models/product_model.dart';
import 'package:notes_hub/screens/inner_screen/product_details.dart';
import 'package:notes_hub/screens/inner_screen/submit_script_screen.dart';
import 'package:notes_hub/widgets/subtitle_text.dart';
import 'package:notes_hub/widgets/title_text.dart';

class MySubmissionsScreen extends StatelessWidget {
  static const routeName = '/moje-poslate-skripte';

  const MySubmissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Moje poslate skripte'),
      ),
      body: currentUser == null
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: SubtitleTextWidget(
                  label: 'Prijavi se da bi videla svoje poslate skripte.',
                  maxLines: 2,
                ),
              ),
            )
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .where('authorId', isEqualTo: currentUser.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: SelectableText(snapshot.error.toString()),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const _EmptySubmissionsState();
                }

                final submissions = snapshot.data!.docs
                    .map((doc) => ProductModel.fromFirestore(doc))
                    .toList()
                  ..sort((a, b) {
                    final aTime = a.createdAt?.millisecondsSinceEpoch ?? 0;
                    final bTime = b.createdAt?.millisecondsSinceEpoch ?? 0;
                    return bTime.compareTo(aTime);
                  });

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: submissions.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final note = submissions[index];
                    return _SubmissionCard(note: note);
                  },
                );
              },
            ),
    );
  }
}

class _SubmissionCard extends StatelessWidget {
  const _SubmissionCard({required this.note});

  final ProductModel note;

  @override
  Widget build(BuildContext context) {
    final isApproved = note.status == 'approved';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.network(
              note.productImage,
              width: 88,
              height: 112,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 88,
                  height: 112,
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.10),
                  child: const Icon(Icons.description_outlined),
                );
              },
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TitelesTextWidget(
                  label: note.productTitle,
                  fontSize: 18,
                  maxLines: 2,
                ),
                const SizedBox(height: 6),
                SubtitleTextWidget(
                  label: note.productCategory,
                  color: AppColors.muted,
                  fontSize: 14,
                  maxLines: 1,
                ),
                const SizedBox(height: 8),
                _SubmissionStatusPill(status: note.status),
                const SizedBox(height: 10),
                SubtitleTextWidget(
                  label: _statusDescription(note.status),
                  color: AppColors.muted,
                  fontSize: 14,
                  maxLines: 3,
                ),
                if (note.status == 'rejected' &&
                    note.rejectionReason.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SubtitleTextWidget(
                          label: 'Razlog odbijanja',
                          color: Colors.redAccent,
                          fontSize: 13,
                        ),
                        const SizedBox(height: 4),
                        SubtitleTextWidget(
                          label: note.rejectionReason,
                          color: AppColors.textDark,
                          fontSize: 14,
                          maxLines: 5,
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                if (isApproved)
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        ProductDetailsScreen.routName,
                        arguments: note.productId,
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: const Text('Otvori detalje'),
                  )
                else if (note.status == 'rejected')
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => SubmitScriptScreen(
                            productModel: note,
                          ),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.edit_note_rounded, size: 18),
                    label: const Text('Izmeni i posalji ponovo'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _statusDescription(String status) {
    switch (status) {
      case 'pending':
        return 'Skripta je poslata i ceka pregled administratora.';
      case 'rejected':
        return 'Skripta trenutno nije odobrena za objavu u aplikaciji.';
      default:
        return 'Skripta je odobrena i sada je vidljiva korisnicima u aplikaciji.';
    }
  }
}

class _SubmissionStatusPill extends StatelessWidget {
  const _SubmissionStatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final resolvedStatus = status.isEmpty ? 'approved' : status;
    late final Color backgroundColor;
    late final Color textColor;
    late final String label;

    switch (resolvedStatus) {
      case 'pending':
        backgroundColor = Colors.orange.withValues(alpha: 0.12);
        textColor = Colors.orange.shade800;
        label = 'Na cekanju';
        break;
      case 'rejected':
        backgroundColor = Colors.red.withValues(alpha: 0.10);
        textColor = Colors.red.shade700;
        label = 'Odbijena';
        break;
      default:
        backgroundColor = Colors.green.withValues(alpha: 0.12);
        textColor = Colors.green.shade800;
        label = 'Odobrena';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptySubmissionsState extends StatelessWidget {
  const _EmptySubmissionsState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.upload_file_outlined,
              size: 52,
              color: AppColors.lightPrimary,
            ),
            SizedBox(height: 12),
            TitelesTextWidget(label: 'Jos nema poslatih skripti'),
            SizedBox(height: 8),
            SubtitleTextWidget(
              label:
                  'Kada posaljes novu skriptu, ovde ces pratiti da li je na cekanju, odobrena ili odbijena.',
              color: AppColors.muted,
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}
