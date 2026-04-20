import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:notes_hub/consts/app_colors.dart';
import 'package:notes_hub/models/product_model.dart';
import 'package:notes_hub/widgets/admin/admin_section_card.dart';
import 'package:notes_hub/widgets/subtitle_text.dart';
import 'package:notes_hub/widgets/title_text.dart';

class AdminReviewsScreen extends StatefulWidget {
  const AdminReviewsScreen({super.key});

  @override
  State<AdminReviewsScreen> createState() => _AdminReviewsScreenState();
}

class _AdminReviewsScreenState extends State<AdminReviewsScreen> {
  late final TextEditingController _searchController;
  bool _showOnlyReported = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _deleteReview({required String reviewId}) async {
    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Obrisi recenziju'),
              content: const Text(
                'Ova akcija trajno uklanja recenziju iz sistema. Nastavljamo?',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: const Text('Odustani'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  child: const Text('Obrisi'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!shouldDelete) {
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('reviews').doc(reviewId).delete();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recenzija je obrisana.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('products').snapshots(),
      builder: (context, productsSnapshot) {
        if (productsSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (productsSnapshot.hasError) {
          return Center(child: SelectableText(productsSnapshot.error.toString()));
        }

        final products = productsSnapshot.data?.docs
                .map((doc) => ProductModel.fromFirestore(doc))
                .toList() ??
            const <ProductModel>[];
        final productsById = {
          for (final product in products) product.productId: product,
        };

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('reviews')
              .orderBy('updatedAt', descending: true)
              .snapshots(),
          builder: (context, reviewsSnapshot) {
            if (reviewsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (reviewsSnapshot.hasError) {
              return Center(child: SelectableText(reviewsSnapshot.error.toString()));
            }

            final reviewDocs = reviewsSnapshot.data?.docs ?? const [];
            final query = _searchController.text.trim().toLowerCase();
            final visibleReviews = reviewDocs.where((reviewDoc) {
              final data = reviewDoc.data();
              final productId = (data['productId'] ?? '').toString();
              final linkedProduct = productsById[productId];
              final productTitle = linkedProduct?.productTitle ?? 'Nepoznata skripta';
              final comment = (data['comment'] ?? '').toString();
              final userName = (data['userName'] ?? '').toString();
              final isReported = data['reported'] == true;

              if (_showOnlyReported && !isReported) {
                return false;
              }

              if (query.isEmpty) {
                return true;
              }

              return productTitle.toLowerCase().contains(query) ||
                  comment.toLowerCase().contains(query) ||
                  userName.toLowerCase().contains(query);
            }).toList();

            return SingleChildScrollView(
              child: AdminSectionCard(
                title: 'Recenzije',
                subtitle: 'Pregled svih korisnickih ocena i komentara sa mogucnoscu moderacije.',
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Pretraga po skripti, korisniku ili komentaru',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _searchController.text.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        FilterChip(
                          label: const Text('Sve recenzije'),
                          selected: !_showOnlyReported,
                          onSelected: (_) {
                            setState(() {
                              _showOnlyReported = false;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('Samo prijavljene'),
                          selected: _showOnlyReported,
                          onSelected: (_) {
                            setState(() {
                              _showOnlyReported = true;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SubtitleTextWidget(
                        label: '${visibleReviews.length} recenzija za prikaz',
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (visibleReviews.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const SubtitleTextWidget(
                          label: 'Nema recenzija koje odgovaraju pretrazi.',
                          color: AppColors.textDark,
                        ),
                      )
                    else
                      ...visibleReviews.map((reviewDoc) {
                        final data = reviewDoc.data();
                        final productId = (data['productId'] ?? '').toString();
                        final linkedProduct = productsById[productId];
                        final productTitle =
                            linkedProduct?.productTitle ?? 'Nepoznata skripta';
                        final rating = ((data['rating'] ?? 0) as num).toInt();
                        final userName =
                            (data['userName'] ?? 'Nepoznat korisnik').toString();
                        final comment = (data['comment'] ?? '').toString();
                        final updatedAt =
                            (data['updatedAt'] ?? data['createdAt']) as Timestamp?;
                        final isReported = data['reported'] == true;
                        final reportCount = ((data['reportCount'] ?? 0) as num).toInt();

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        TitelesTextWidget(
                                          label: productTitle,
                                          fontSize: 17,
                                        ),
                                        const SizedBox(height: 4),
                                        SubtitleTextWidget(
                                          label: 'Korisnik: $userName | Ocena: $rating/5',
                                          maxLines: 1,
                                          color: AppColors.textDark,
                                        ),
                                        const SizedBox(height: 4),
                                        SubtitleTextWidget(
                                          label:
                                              'Azurirano: ${_formatTimestamp(updatedAt)}',
                                          maxLines: 1,
                                        ),
                                        if (isReported) ...[
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.red.withValues(alpha: 0.10),
                                              borderRadius: BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              'Prijavljeno $reportCount ${reportCount == 1 ? 'put' : 'puta'}',
                                              style: TextStyle(
                                                color: Colors.red.shade700,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () async {
                                      await _deleteReview(reviewId: reviewDoc.id);
                                    },
                                    tooltip: 'Obrisi recenziju',
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: SubtitleTextWidget(
                                  label: comment.isEmpty ? 'Komentar nije ostavljen.' : comment,
                                  color: AppColors.textDark,
                                  maxLines: 8,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    final date = timestamp?.toDate();
    if (date == null) {
      return 'N/A';
    }

    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
