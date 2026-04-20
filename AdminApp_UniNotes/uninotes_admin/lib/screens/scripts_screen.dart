import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:uninotes_admin/consts/app_colors.dart';
import 'package:uninotes_admin/models/product_model.dart';
import 'package:uninotes_admin/providers/products_provider.dart';
import 'package:uninotes_admin/screens/upload_script_screen.dart';
import 'package:uninotes_admin/widgets/app_subtitle_text.dart';
import 'package:uninotes_admin/widgets/app_title_text.dart';
import 'package:uninotes_admin/widgets/section_card.dart';

class ScriptsScreen extends StatefulWidget {
  const ScriptsScreen({super.key});

  @override
  State<ScriptsScreen> createState() => _ScriptsScreenState();
}

class _ScriptsScreenState extends State<ScriptsScreen> {
  late final TextEditingController searchTextController;

  Future<String?> _askRejectionReason() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Razlog odbijanja'),
          content: TextField(
            controller: controller,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Kratko objasni korisniku zasto skripta nije odobrena',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(null);
              },
              child: const Text('Odustani'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(controller.text.trim());
              },
              child: const Text('Sacuvaj'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    return result;
  }

  Future<void> _updateStatus(
    ProductModel product,
    String newStatus, {
    String rejectionReason = '',
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(product.productId)
          .update({
        'status': newStatus,
        'rejectionReason': newStatus == 'rejected' ? rejectionReason : '',
      });
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus == 'approved'
                ? 'Skripta je odobrena.'
                : 'Skripta je odbijena.',
          ),
        ),
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
  void initState() {
    searchTextController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    searchTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsProvider =
        Provider.of<ProductsProvider>(context, listen: false);

    return StreamBuilder<List<ProductModel>>(
      stream: productsProvider.fetchProductsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: SelectableText(snapshot.error.toString()));
        }
        if (snapshot.data == null) {
          return const Center(
            child: SelectableText("Jos nema dodatih skripti"),
          );
        }

        final allProducts = snapshot.data!;
        final visibleProducts = searchTextController.text.trim().isEmpty
            ? allProducts
            : productsProvider.searchQuery(
                searchText: searchTextController.text.trim(),
                passedList: allProducts,
              );

        return SingleChildScrollView(
          child: SectionCard(
            title: 'Sve skripte',
            subtitle:
                'Pregled svih skripti iz baze sa pretragom i ulazom u formu za izmenu.',
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: searchTextController,
                        onChanged: (_) {
                          setState(() {});
                        },
                        decoration: InputDecoration(
                          hintText: 'Pretraga po naslovu skripte',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: searchTextController.text.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () {
                                    searchTextController.clear();
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.close_rounded),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const Scaffold(
                              body: SafeArea(
                                child: Padding(
                                  padding: EdgeInsets.all(24),
                                  child: UploadScriptScreen(),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Dodaj skriptu'),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (visibleProducts.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const AppSubtitleText(
                      label: 'Nema skripti za prikaz.',
                      color: AppColors.text,
                    ),
                  )
                else
                  ...List.generate(visibleProducts.length, (index) {
                    final product = visibleProducts[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              product.productImage,
                              width: 54,
                              height: 70,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 54,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(Icons.picture_as_pdf_rounded),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppTitleText(
                                  label: product.productTitle,
                                  fontSize: 17,
                                ),
                                const SizedBox(height: 4),
                                AppSubtitleText(
                                  label:
                                      'Predmet: ${product.productCategory} | ${product.isFree ? 'Besplatna' : 'Premium'} | Cena: ${product.productPrice}',
                                  maxLines: 1,
                                ),
                                const SizedBox(height: 6),
                                 AppSubtitleText(
                                   label: product.productDescription,
                                   maxLines: 2,
                                 ),
                                 const SizedBox(height: 8),
                                 Wrap(
                                   spacing: 8,
                                   runSpacing: 8,
                                   children: [
                                     _StatusPill(status: product.status),
                                     if (product.authorName.isNotEmpty)
                                       AppSubtitleText(
                                         label: 'Autor: ${product.authorName}',
                                         color: AppColors.text,
                                       ),
                                   ],
                                 ),
                               ],
                             ),
                           ),
                           const SizedBox(width: 10),
                           Column(
                             children: [
                               IconButton(
                                 onPressed: () {
                                   Navigator.of(context).push(
                                     MaterialPageRoute(
                                       builder: (context) => Scaffold(
                                         body: SafeArea(
                                           child: Padding(
                                             padding: const EdgeInsets.all(24),
                                             child: UploadScriptScreen(
                                               productModel: product,
                                             ),
                                           ),
                                         ),
                                       ),
                                     ),
                                   );
                                 },
                                 icon: const Icon(Icons.edit_outlined),
                               ),
                               if (product.status != 'approved')
                                  IconButton(
                                    onPressed: () async {
                                      await _updateStatus(product, 'approved');
                                    },
                                    tooltip: 'Odobri',
                                    icon: const Icon(
                                     Icons.verified_rounded,
                                     color: Colors.green,
                                   ),
                                 ),
                               if (product.status != 'rejected')
                                  IconButton(
                                    onPressed: () async {
                                      final reason = await _askRejectionReason();
                                      if (!mounted || reason == null) {
                                        return;
                                      }
                                      await _updateStatus(
                                        product,
                                        'rejected',
                                        rejectionReason: reason,
                                      );
                                    },
                                    tooltip: 'Odbij',
                                    icon: const Icon(
                                     Icons.cancel_outlined,
                                     color: Colors.redAccent,
                                    ),
                                  ),
                                if (product.status == 'rejected' &&
                                    product.rejectionReason.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: ConstrainedBox(
                                      constraints:
                                          const BoxConstraints(maxWidth: 220),
                                      child: AppSubtitleText(
                                        label:
                                            'Razlog: ${product.rejectionReason}',
                                        maxLines: 3,
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                  ),
                              ],
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
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

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
