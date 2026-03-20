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

  Future<bool> _hasPurchasedAccess(ProductModel currentNote) async {
    if (currentNote.isFree) {
      return true;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return false;
    }

    final ordersSnapshot = await FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: user.uid)
        .get();

    for (final doc in ordersSnapshot.docs) {
      if ((doc.data()['productId'] ?? '').toString() == currentNote.productId) {
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final productsProvider = Provider.of<ProductsProvider>(context);
    final productId = ModalRoute.of(context)!.settings.arguments as String?;
    final currentNote = productsProvider.findByProductId(productId!);
    final cartProvider = Provider.of<CartProvider>(context);

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
          : FutureBuilder<bool>(
              future: _hasPurchasedAccess(currentNote),
              builder: (context, snapshot) {
                final hasAccess = snapshot.data ?? currentNote.isFree;
                final isCheckingAccess =
                    snapshot.connectionState == ConnectionState.waiting &&
                        !currentNote.isFree;

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
                      const Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            color: Color(0xFFF59E0B),
                            size: 18,
                          ),
                          SizedBox(width: 4),
                          SubtitleTextWidget(
                            label: "4.8",
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                          SizedBox(width: 4),
                          SubtitleTextWidget(
                            label: "(12 recenzija)",
                            fontSize: 15,
                            color: AppColors.muted,
                          ),
                        ],
                      ),
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
                      const _DetailsSection(
                        title: "Ocene i komentari",
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _ReviewSummary(),
                            SizedBox(height: 16),
                            _CommentCard(
                              userName: "Student PMF",
                              rating: 5,
                              comment:
                                  "Jasno organizovana skripta, odlican pregled gradiva i korisni primeri.",
                            ),
                            SizedBox(height: 12),
                            _CommentCard(
                              userName: "Ana S.",
                              rating: 4,
                              comment:
                                  "Dobar materijal za pripremu ispita. Kasnije ovde ubacujemo prave komentare iz baze.",
                            ),
                            SizedBox(height: 16),
                            _LeaveReviewBox(),
                          ],
                        ),
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
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              children: [
                Icon(Icons.picture_as_pdf_rounded, color: AppColors.lightPrimary),
                SizedBox(width: 10),
                Expanded(
                  child: SubtitleTextWidget(
                    label:
                        "Ovde ce kasnije ici preview prve strane ili thumbnail PDF dokumenta.",
                    color: AppColors.muted,
                    fontSize: 14,
                    maxLines: 2,
                  ),
                ),
              ],
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

class _ReviewSummary extends StatelessWidget {
  const _ReviewSummary();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TitelesTextWidget(label: "4.8", fontSize: 30),
              SizedBox(height: 4),
              SubtitleTextWidget(
                label: "Prosecna ocena",
                fontSize: 14,
                color: AppColors.muted,
              ),
            ],
          ),
          SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StarRow(),
                SizedBox(height: 8),
                SubtitleTextWidget(
                  label: "12 korisnika je ostavilo ocenu za ovu skriptu.",
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
  const _StarRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.star_rounded, color: Color(0xFFF59E0B)),
        Icon(Icons.star_rounded, color: Color(0xFFF59E0B)),
        Icon(Icons.star_rounded, color: Color(0xFFF59E0B)),
        Icon(Icons.star_rounded, color: Color(0xFFF59E0B)),
        Icon(Icons.star_half_rounded, color: Color(0xFFF59E0B)),
      ],
    );
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({
    required this.userName,
    required this.rating,
    required this.comment,
  });

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
        ],
      ),
    );
  }
}

class _LeaveReviewBox extends StatelessWidget {
  const _LeaveReviewBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TitelesTextWidget(
            label: "Ostavi ocenu i komentar",
            fontSize: 17,
          ),
          SizedBox(height: 8),
          SubtitleTextWidget(
            label:
                "Kasnije ovde vezujemo prijavljenog korisnika, 5 zvezdica i komentar iz baze.",
            color: AppColors.muted,
            fontSize: 14,
            maxLines: 3,
          ),
        ],
      ),
    );
  }
}
