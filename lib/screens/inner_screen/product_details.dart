import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fancy_shimmer_image/fancy_shimmer_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:notes_hub/consts/app_colors.dart';
import 'package:notes_hub/models/product_model.dart';
import 'package:notes_hub/providers/cart_provider.dart';
import 'package:notes_hub/providers/products_provider.dart';
import 'package:notes_hub/providers/user_provider.dart';
import 'package:notes_hub/screens/inner_screen/pdf_preview_screen.dart';
import 'package:notes_hub/services/my_app_functions.dart';
import 'package:notes_hub/widgets/products/heart_btn.dart';
import 'package:notes_hub/widgets/subtitle_text.dart';
import 'package:notes_hub/widgets/title_text.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

class ProductDetailsScreen extends StatefulWidget {
  static const routName = "/detalji-skripte";
  const ProductDetailsScreen({super.key});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  bool _isDownloading = false;
  double _downloadProgress = 0;
  bool _isSubmittingReview = false;

  bool _hasPaidAccessFromOrdersSnapshot({
    required QuerySnapshot<Map<String, dynamic>>? snapshot,
    required ProductModel currentNote,
  }) {
    if (currentNote.isFree) {
      return true;
    }

    final orderDocs = snapshot?.docs ?? const [];
    for (final doc in orderDocs) {
      final data = doc.data();
      final orderProductId = (data['productId'] ?? '').toString();
      final paymentStatus = (data['paymentStatus'] ?? '').toString();
      if (orderProductId != currentNote.productId) {
        continue;
      }

      // Keep legacy orders valid, but explicitly honor paid PayPal orders.
      if (paymentStatus.isEmpty || paymentStatus == 'paid') {
        return true;
      }
    }

    return false;
  }

  Future<void> _previewPdf(ProductModel currentNote) async {
    if (currentNote.pdfUrl.trim().isEmpty) {
      await MyAppFunctions.showErrorOrWarningDialog(
        context: context,
        subtitle: 'PDF jos nije dostupan za ovu skriptu.',
        fct: () {},
      );
      return;
    }

    if (!mounted) {
      return;
    }

    await Navigator.pushNamed(
      context,
      PdfPreviewScreen.routeName,
      arguments: PdfPreviewArguments(
        title: currentNote.productTitle,
        pdfUrl: currentNote.pdfUrl,
      ),
    );
  }

  String _sanitizeFileName(String input) {
    final sanitized = input.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    return sanitized.isEmpty ? 'uninotes_skripta' : sanitized;
  }

  Future<void> _downloadPdf(ProductModel currentNote) async {
    if (_isDownloading) {
      return;
    }
    if (currentNote.pdfUrl.trim().isEmpty) {
      await MyAppFunctions.showErrorOrWarningDialog(
        context: context,
        subtitle: 'PDF jos nije dostupan za ovu skriptu.',
        fct: () {},
      );
      return;
    }

    final pdfUri = Uri.tryParse(currentNote.pdfUrl.trim());
    if (pdfUri == null) {
      await MyAppFunctions.showErrorOrWarningDialog(
        context: context,
        subtitle: 'PDF link nije validan.',
        fct: () {},
      );
      return;
    }

    try {
      setState(() {
        _isDownloading = true;
        _downloadProgress = 0;
      });

      final request = http.Request('GET', pdfUri);
      final response = await request.send();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Preuzimanje nije uspelo. Status: ${response.statusCode}');
      }

      final directory = await getApplicationDocumentsDirectory();
      final fileBaseName = _sanitizeFileName(
        currentNote.pdfFileName.isNotEmpty
            ? currentNote.pdfFileName
            : currentNote.productTitle,
      );
      final fileName = fileBaseName.toLowerCase().endsWith('.pdf')
          ? fileBaseName
          : '$fileBaseName.pdf';
      final file = File('${directory.path}${Platform.pathSeparator}$fileName');

      final sink = file.openWrite();
      final totalBytes = response.contentLength ?? 0;
      var receivedBytes = 0;

      await for (final chunk in response.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (mounted && totalBytes > 0) {
          setState(() {
            _downloadProgress = receivedBytes / totalBytes;
          });
        }
      }
      await sink.flush();
      await sink.close();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF je sacuvan: $fileName'),
          action: SnackBarAction(
            label: 'Otvori',
            onPressed: () async {
              await OpenFilex.open(file.path);
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      await MyAppFunctions.showErrorOrWarningDialog(
        context: context,
        subtitle: e.toString(),
        fct: () {},
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadProgress = 0;
        });
      }
    }
  }

  Future<void> _submitReview({
    required ProductModel currentNote,
    required String userName,
    required int rating,
    required String comment,
    required String? existingReviewId,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      await MyAppFunctions.showErrorOrWarningDialog(
        context: context,
        subtitle: 'Prvo se prijavi da bi ostavila ocenu i komentar.',
        fct: () {},
      );
      return;
    }

    if (!currentNote.isFree) {
      final ordersSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: currentUser.uid)
          .get();
      final hasPurchasedAccess = _hasPaidAccessFromOrdersSnapshot(
        snapshot: ordersSnapshot,
        currentNote: currentNote,
      );
      if (!hasPurchasedAccess) {
        if (!mounted) {
          return;
        }
        await MyAppFunctions.showErrorOrWarningDialog(
          context: context,
          subtitle:
              'Ocenu za premium skriptu moze da ostavi samo korisnik koji ju je kupio.',
          fct: () {},
        );
        return;
      }
    }

    if (!mounted) {
      return;
    }

    final trimmedComment = comment.trim();
    if (trimmedComment.isEmpty) {
      await MyAppFunctions.showErrorOrWarningDialog(
        context: context,
        subtitle: 'Komentar je obavezan.',
        fct: () {},
      );
      return;
    }

    try {
      setState(() {
        _isSubmittingReview = true;
      });

      final reviewsDb = FirebaseFirestore.instance.collection('reviews');
      if (existingReviewId != null && existingReviewId.isNotEmpty) {
        await reviewsDb.doc(existingReviewId).update({
          'rating': rating,
          'comment': trimmedComment,
          'userName': userName,
          'updatedAt': Timestamp.now(),
        });
      } else {
        final reviewDoc = reviewsDb.doc();
        await reviewDoc.set({
          'reviewId': reviewDoc.id,
          'productId': currentNote.productId,
          'userId': currentUser.uid,
          'userName': userName,
          'rating': rating,
          'comment': trimmedComment,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });
      }

      if (!mounted) {
        return;
      }

      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ocena i komentar su sacuvani.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      await MyAppFunctions.showErrorOrWarningDialog(
        context: context,
        subtitle: error.toString(),
        fct: () {},
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingReview = false;
        });
      }
    }
  }

  Future<void> _deleteReview({
    required String reviewId,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      await MyAppFunctions.showErrorOrWarningDialog(
        context: context,
        subtitle: 'Prvo se prijavi da bi upravljala svojim komentarom.',
        fct: () {},
      );
      return;
    }

    try {
      setState(() {
        _isSubmittingReview = true;
      });

      await FirebaseFirestore.instance.collection('reviews').doc(reviewId).delete();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tvoja recenzija je obrisana.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      await MyAppFunctions.showErrorOrWarningDialog(
        context: context,
        subtitle: error.toString(),
        fct: () {},
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingReview = false;
        });
      }
    }
  }

  Future<void> _reportReview({
    required String reviewId,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      await MyAppFunctions.showErrorOrWarningDialog(
        context: context,
        subtitle: 'Prijavi se da bi prijavila komentar.',
        fct: () {},
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('reviews').doc(reviewId).set({
        'reported': true,
        'reportedAt': Timestamp.now(),
        'reportedBy': FieldValue.arrayUnion([currentUser.uid]),
        'reportCount': FieldValue.increment(1),
      }, SetOptions(merge: true));

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Komentar je prijavljen adminu.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      await MyAppFunctions.showErrorOrWarningDialog(
        context: context,
        subtitle: error.toString(),
        fct: () {},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final productsProvider = Provider.of<ProductsProvider>(context);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final productId = ModalRoute.of(context)!.settings.arguments as String?;
    final currentNote = productsProvider.findByProductId(productId!);
    final cartProvider = Provider.of<CartProvider>(context);
    final currentUser = FirebaseAuth.instance.currentUser;
    final ordersStream = currentNote == null || currentNote.isFree || currentUser == null
        ? null
        : FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: currentUser.uid)
            .snapshots();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
          ),
        ),
        title: const Text("Detalji skripte"),
      ),
      body: currentNote == null
          ? const SizedBox.shrink()
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: ordersStream,
              builder: (context, snapshot) {
                final hasAccess = _hasPaidAccessFromOrdersSnapshot(
                  snapshot: snapshot.data,
                  currentNote: currentNote,
                );
                final isCheckingAccess =
                    !currentNote.isFree &&
                    currentUser != null &&
                    snapshot.connectionState == ConnectionState.waiting;
                final canReview = currentUser != null &&
                    (currentNote.isFree || (!isCheckingAccess && hasAccess));
                final reviewLockMessage = currentUser == null
                    ? 'Prijavi se da bi ostavila ocenu i komentar.'
                    : currentNote.isFree
                        ? null
                        : 'Ocenu za premium skriptu moze da ostavi samo korisnik koji ju je kupio.';

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DocumentPreviewCard(
                        imageUrl: currentNote.productImage,
                        height: size.height * 0.38,
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _MetaBadge(label: currentNote.productCategory),
                          const _MetaBadge(label: "PDF skripta"),
                          _MetaBadge(
                              label: currentNote.isFree ? "Besplatna" : "Premium"),
                          if (!currentNote.isFree && hasAccess)
                            const _MetaBadge(label: "Otkljucano"),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TitelesTextWidget(
                        label: currentNote.productTitle,
                        fontSize: 28,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 10),
                      _ReviewHeader(productId: currentNote.productId),
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SubtitleTextWidget(
                              label: "Cena",
                              fontSize: 14,
                              color: AppColors.muted,
                            ),
                            const SizedBox(height: 6),
                            SubtitleTextWidget(
                              label: currentNote.isFree
                                  ? "Besplatno"
                                  : "${currentNote.productPrice} RSD",
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: AppColors.accent,
                            ),
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Expanded(
                                  child: _InfoStat(
                                    title: "Format",
                                    value: "PDF",
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _InfoStat(
                                    title: "Predmet",
                                    value: currentNote.productCategory,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _InfoStat(
                                    title: "Stranica",
                                    value: currentNote.productQuantity,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _InfoStat(
                                    title: "Objavljeno",
                                    value: _formatCreatedAt(currentNote.createdAt),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          HeartButtonWidget(
                            productId: currentNote.productId,
                            bkgColor: Theme.of(context).cardColor,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: hasAccess && !isCheckingAccess
                                  ? () async {
                                      await _previewPdf(currentNote);
                                    }
                                  : null,
                              icon: Icon(
                                hasAccess && !isCheckingAccess
                                    ? Icons.visibility_outlined
                                    : Icons.lock_outline_rounded,
                              ),
                              label: Text(
                                hasAccess && !isCheckingAccess
                                    ? "Pregled PDF-a"
                                    : "PDF nakon kupovine",
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: isCheckingAccess
                              ? null
                              : () async {
                                  if (hasAccess) {
                                    await _downloadPdf(currentNote);
                                    return;
                                  }

                                  try {
                                    await cartProvider.addToCartFirebase(
                                      productId: currentNote.productId,
                                      qty: 1,
                                      context: context,
                                    );
                                  } catch (e) {
                                    if (!context.mounted) {
                                      return;
                                    }
                                    await MyAppFunctions.showErrorOrWarningDialog(
                                      context: context,
                                      subtitle: e.toString(),
                                      fct: () {},
                                    );
                                  }
                                },
                          icon: Icon(
                            hasAccess
                                ? (_isDownloading
                                    ? Icons.downloading_rounded
                                    : Icons.download_rounded)
                                : cartProvider.isProdinCart(productId: currentNote.productId)
                                    ? Icons.check_circle_rounded
                                    : Icons.shopping_cart_checkout_rounded,
                          ),
                          label: Text(
                            isCheckingAccess
                                ? "Provera pristupa..."
                                : hasAccess
                                    ? (_isDownloading
                                        ? "Preuzimanje ${(_downloadProgress * 100).toStringAsFixed(0)}%"
                                        : "Preuzmi PDF")
                                    : cartProvider.isProdinCart(productId: currentNote.productId)
                                        ? "Vec dodato u kupovine"
                                        : "Kupi skriptu",
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _DetailsSection(
                        title: "O skripti",
                        child: SubtitleTextWidget(
                          label: currentNote.productDescription,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const _DetailsSection(
                        title: "Sta dobijas",
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _BulletLine(
                                text:
                                    "PDF dokument spreman za pregled i kasniji download"),
                            SizedBox(height: 8),
                            _BulletLine(
                                text: "Pristup kroz UniNotes nakon kupovine"),
                            SizedBox(height: 8),
                            _BulletLine(
                                text:
                                    "Mesto za recenzije, komentare i ocene korisnika"),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _ReviewsSection(
                        productId: currentNote.productId,
                        canReview: canReview,
                        reviewLockMessage: reviewLockMessage,
                        onReport: (reviewId) async {
                          await _reportReview(reviewId: reviewId);
                        },
                        onDelete: (reviewId) async {
                          await _deleteReview(reviewId: reviewId);
                        },
                        onSubmit:
                            (rating, comment, existingReview, existingReviewId) async {
                          final resolvedUserName = userProvider.getUserModel
                                      ?.userName
                                      .isNotEmpty ==
                                  true
                              ? userProvider.getUserModel!.userName
                              : (currentUser?.email?.split('@').first ??
                                  'Korisnik');
                          await _submitReview(
                            currentNote: currentNote,
                            userName: resolvedUserName,
                            rating: rating,
                            comment: comment,
                            existingReviewId: existingReviewId,
                          );
                        },
                        isSubmitting: _isSubmittingReview,
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  String _formatCreatedAt(dynamic createdAt) {
    final dateTime = createdAt?.toDate();
    if (dateTime == null) {
      return "N/A";
    }

    const monthNames = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];

    return "${dateTime.day} ${monthNames[dateTime.month - 1]} ${dateTime.year}";
  }
}

class _DocumentPreviewCard extends StatelessWidget {
  const _DocumentPreviewCard({
    required this.imageUrl,
    required this.height,
  });

  final String imageUrl;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: FancyShimmerImage(
              imageUrl: imageUrl,
              height: height,
              width: double.infinity,
              boxFit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  const _MetaBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.lightPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _InfoStat extends StatelessWidget {
  const _InfoStat({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SubtitleTextWidget(
            label: title,
            fontSize: 13,
            color: AppColors.muted,
          ),
          const SizedBox(height: 6),
          TitelesTextWidget(
            label: value,
            fontSize: 16,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

class _DetailsSection extends StatelessWidget {
  const _DetailsSection({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TitelesTextWidget(label: title, fontSize: 20),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _BulletLine extends StatelessWidget {
  const _BulletLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Icon(
            Icons.circle,
            size: 8,
            color: AppColors.lightPrimary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SubtitleTextWidget(
            label: text,
            color: AppColors.muted,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}

class _ReviewHeader extends StatelessWidget {
  const _ReviewHeader({required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('productId', isEqualTo: productId)
          .snapshots(),
      builder: (context, snapshot) {
        final reviews = snapshot.data?.docs.map((doc) => doc.data()).toList() ?? [];
        final reviewsCount = reviews.length;
        final averageRating = reviewsCount == 0
            ? 0.0
            : reviews.fold<num>(
                    0,
                    (total, review) => total + ((review['rating'] ?? 0) as num),
                  ) /
                reviewsCount;

        return Row(
          children: [
            const Icon(
              Icons.star_rounded,
              color: Color(0xFFF59E0B),
              size: 18,
            ),
            const SizedBox(width: 4),
            SubtitleTextWidget(
              label: averageRating == 0
                  ? 'Nema ocena'
                  : averageRating.toStringAsFixed(1),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
            const SizedBox(width: 4),
            SubtitleTextWidget(
              label: "($reviewsCount recenzija)",
              fontSize: 15,
              color: AppColors.muted,
            ),
          ],
        );
      },
    );
  }
}

class _ReviewsSection extends StatefulWidget {
  const _ReviewsSection({
    required this.productId,
    required this.canReview,
    required this.reviewLockMessage,
    required this.onReport,
    required this.onDelete,
    required this.onSubmit,
    required this.isSubmitting,
  });

  final String productId;
  final bool canReview;
  final String? reviewLockMessage;
  final Future<void> Function(String reviewId) onReport;
  final Future<void> Function(String reviewId) onDelete;
  final Future<void> Function(
    int rating,
    String comment,
    bool existingReview,
    String? existingReviewId,
  ) onSubmit;
  final bool isSubmitting;

  @override
  State<_ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<_ReviewsSection> {
  final TextEditingController _reviewController = TextEditingController();
  int _selectedRating = 5;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('productId', isEqualTo: widget.productId)
          .snapshots(),
      builder: (context, snapshot) {
        final reviewDocs = snapshot.data?.docs ?? [];
        final sortedReviewDocs = [...reviewDocs]..sort((a, b) {
          final aTime =
              (a.data()['updatedAt'] ?? a.data()['createdAt']) as Timestamp?;
          final bTime =
              (b.data()['updatedAt'] ?? b.data()['createdAt']) as Timestamp?;
          return (bTime?.millisecondsSinceEpoch ?? 0)
              .compareTo(aTime?.millisecondsSinceEpoch ?? 0);
        });

        final reviewsCount = sortedReviewDocs.length;
        final averageRating = reviewsCount == 0
            ? 0.0
            : sortedReviewDocs.fold<num>(
                    0,
                    (total, doc) => total + ((doc.data()['rating'] ?? 0) as num),
                  ) /
                reviewsCount;

        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
        QueryDocumentSnapshot<Map<String, dynamic>>? currentUserReviewDoc;
        if (currentUserId != null) {
          for (final reviewDoc in sortedReviewDocs) {
            if ((reviewDoc.data()['userId'] ?? '').toString() == currentUserId) {
              currentUserReviewDoc = reviewDoc;
              break;
            }
          }
        }

        if (currentUserReviewDoc != null && _reviewController.text.isEmpty) {
          _reviewController.text =
              (currentUserReviewDoc.data()['comment'] ?? '').toString();
          _selectedRating =
              ((currentUserReviewDoc.data()['rating'] ?? 5) as num).toInt();
        } else if (currentUserReviewDoc == null && _reviewController.text.isNotEmpty) {
          _reviewController.clear();
          _selectedRating = 5;
        }

        return _DetailsSection(
          title: "Ocene i komentari",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ReviewSummary(
                averageRating: averageRating,
                reviewsCount: reviewsCount,
              ),
              const SizedBox(height: 16),
              if (sortedReviewDocs.isEmpty)
                const _EmptyReviewsState()
              else
                ...sortedReviewDocs.map(
                  (reviewDoc) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _CommentCard(
                      reviewId: reviewDoc.id,
                      canReport: currentUserId != null &&
                          (reviewDoc.data()['userId'] ?? '').toString() != currentUserId,
                      isReportedByCurrentUser: currentUserId != null &&
                          (((reviewDoc.data()['reportedBy'] as List?) ?? const [])
                              .map((item) => item.toString())
                              .contains(currentUserId)),
                      onReport: () async {
                        await widget.onReport(reviewDoc.id);
                      },
                      userName:
                          (reviewDoc.data()['userName'] ?? 'Korisnik').toString(),
                      rating: ((reviewDoc.data()['rating'] ?? 0) as num).toInt(),
                      comment: (reviewDoc.data()['comment'] ?? '').toString(),
                    ),
                  ),
                ),
              _LeaveReviewBox(
                canReview: widget.canReview,
                lockedMessage: widget.reviewLockMessage,
                selectedRating: _selectedRating,
                onRatingSelected: (rating) {
                  setState(() {
                    _selectedRating = rating;
                  });
                },
                reviewController: _reviewController,
                isSubmitting: widget.isSubmitting,
                existingReview: currentUserReviewDoc != null,
                onDelete: currentUserReviewDoc == null
                    ? null
                    : () async {
                        final reviewId = currentUserReviewDoc!.id;
                        await widget.onDelete(reviewId);
                      },
                onSubmit: () async {
                  await widget.onSubmit(
                    _selectedRating,
                    _reviewController.text,
                    currentUserReviewDoc != null,
                    currentUserReviewDoc?.id,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ReviewSummary extends StatelessWidget {
  const _ReviewSummary({
    required this.averageRating,
    required this.reviewsCount,
  });

  final double averageRating;
  final int reviewsCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TitelesTextWidget(
                label: averageRating == 0
                    ? "-"
                    : averageRating.toStringAsFixed(1),
                fontSize: 30,
              ),
              const SizedBox(height: 4),
              const SubtitleTextWidget(
                label: "Prosecna ocena",
                fontSize: 14,
                color: AppColors.muted,
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StarRow(rating: averageRating),
                const SizedBox(height: 8),
                SubtitleTextWidget(
                  label: reviewsCount == 0
                      ? "Jos nema ostavljenih ocena za ovu skriptu."
                      : "$reviewsCount korisnika je ostavilo ocenu za ovu skriptu.",
                  fontSize: 14,
                  color: AppColors.muted,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({this.rating = 0});

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        IconData icon;
        if (rating >= starIndex) {
          icon = Icons.star_rounded;
        } else if (rating >= starIndex - 0.5) {
          icon = Icons.star_half_rounded;
        } else {
          icon = Icons.star_outline_rounded;
        }
        return Icon(icon, color: const Color(0xFFF59E0B));
      }),
    );
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({
    required this.reviewId,
    required this.canReport,
    required this.isReportedByCurrentUser,
    required this.onReport,
    required this.userName,
    required this.rating,
    required this.comment,
  });

  final String reviewId;
  final bool canReport;
  final bool isReportedByCurrentUser;
  final Future<void> Function() onReport;
  final String userName;
  final int rating;
  final String comment;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TitelesTextWidget(
                  label: userName,
                  fontSize: 16,
                  maxLines: 1,
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: const Color(0xFFF59E0B),
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SubtitleTextWidget(
            label: comment,
            color: AppColors.muted,
            fontSize: 14,
          ),
          if (canReport) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: isReportedByCurrentUser
                    ? null
                    : () async {
                        await onReport();
                      },
                icon: const Icon(Icons.flag_outlined, size: 18),
                label: Text(
                  isReportedByCurrentUser ? 'Prijavljeno' : 'Prijavi',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LeaveReviewBox extends StatelessWidget {
  const _LeaveReviewBox({
    required this.canReview,
    required this.lockedMessage,
    required this.selectedRating,
    required this.onRatingSelected,
    required this.reviewController,
    required this.isSubmitting,
    required this.existingReview,
    required this.onDelete,
    required this.onSubmit,
  });

  final bool canReview;
  final String? lockedMessage;
  final int selectedRating;
  final ValueChanged<int> onRatingSelected;
  final TextEditingController reviewController;
  final bool isSubmitting;
  final bool existingReview;
  final Future<void> Function()? onDelete;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TitelesTextWidget(
            label: existingReview
                ? "Izmeni svoju ocenu i komentar"
                : "Ostavi ocenu i komentar",
            fontSize: 17,
          ),
          const SizedBox(height: 8),
          SubtitleTextWidget(
            label: existingReview
                ? "Vec si ocenila skriptu. Novi unos menja prethodni komentar."
                : (lockedMessage ??
                    "Registrovani korisnik moze da ostavi jednu ocenu i komentar po skripti."),
            color: AppColors.muted,
            fontSize: 14,
            maxLines: 3,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 4,
            children: List.generate(
              5,
              (index) => IconButton(
                onPressed: canReview
                    ? () {
                        onRatingSelected(index + 1);
                      }
                    : null,
                icon: Icon(
                  index < selectedRating
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: const Color(0xFFF59E0B),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: reviewController,
            enabled: canReview && !isSubmitting,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: "Napisite svoje utiske o skripti",
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (existingReview && onDelete != null) ...[
                OutlinedButton.icon(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          await onDelete!();
                        },
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text("Obrisi"),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: !canReview || isSubmitting
                      ? null
                      : () async {
                          await onSubmit();
                        },
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.rate_review_outlined),
                  label: Text(
                    !canReview
                        ? "Ocena nije dostupna"
                        : isSubmitting
                            ? "Cuvanje..."
                            : existingReview
                                ? "Sacuvaj izmene"
                                : "Objavi komentar",
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyReviewsState extends StatelessWidget {
  const _EmptyReviewsState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const SubtitleTextWidget(
        label: "Jos nema komentara. Budi prva koja ce ostaviti utisak o ovoj skripti.",
        color: AppColors.muted,
        fontSize: 14,
        maxLines: 3,
      ),
    );
  }
}
