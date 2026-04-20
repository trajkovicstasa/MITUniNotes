import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:notes_hub/consts/app_colors.dart';
import 'package:notes_hub/models/product_model.dart';
import 'package:notes_hub/screens/admin/admin_upload_script_screen.dart';
import 'package:notes_hub/widgets/admin/admin_section_card.dart';
import 'package:notes_hub/widgets/subtitle_text.dart';
import 'package:notes_hub/widgets/title_text.dart';

class AdminScriptsScreen extends StatefulWidget {
  const AdminScriptsScreen({super.key});

  @override
  State<AdminScriptsScreen> createState() => _AdminScriptsScreenState();
}

class _AdminScriptsScreenState extends State<AdminScriptsScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
      await FirebaseFirestore.instance.collection('products').doc(product.productId).update({
        'status': newStatus,
        'rejectionReason': newStatus == 'rejected' ? rejectionReason : '',
      });
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus == 'approved' ? 'Skripta je odobrena.' : 'Skripta je odbijena.',
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
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('products').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: SelectableText(snapshot.error.toString()));
        }

        final allProducts = snapshot.data?.docs
                .map((doc) => ProductModel.fromFirestore(doc))
                .toList() ??
            const <ProductModel>[];
        final query = _searchController.text.trim().toLowerCase();
        final visibleProducts = query.isEmpty
            ? allProducts
            : allProducts.where((product) {
                return product.productTitle.toLowerCase().contains(query);
              }).toList();

        return SingleChildScrollView(
          child: AdminSectionCard(
            title: 'Sve skripte',
            subtitle: 'Pregled svih skripti iz baze sa odobravanjem, odbijanjem i izmenom.',
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) {
                          setState(() {});
                        },
                        decoration: InputDecoration(
                          hintText: 'Pretraga po naslovu skripte',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _searchController.text.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () {
                                    _searchController.clear();
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
                            builder: (context) => const AdminUploadScriptScreen(),
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
                    child: const SubtitleTextWidget(
                      label: 'Nema skripti za prikaz.',
                      color: AppColors.muted,
                    ),
                  )
                else
                  ...visibleProducts.map((product) {
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
                                    color: AppColors.lightPrimary.withValues(alpha: 0.10),
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
                                TitelesTextWidget(label: product.productTitle, fontSize: 17),
                                const SizedBox(height: 4),
                                SubtitleTextWidget(
                                  label:
                                      'Predmet: ${product.productCategory} | ${product.isFree ? 'Besplatna' : 'Premium'} | Cena: ${product.productPrice}',
                                  maxLines: 2,
                                ),
                                const SizedBox(height: 6),
                                SubtitleTextWidget(
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
                                      SubtitleTextWidget(
                                        label: 'Autor: ${product.authorName}',
                                        color: AppColors.textDark,
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
                                      builder: (context) => AdminUploadScriptScreen(
                                        productModel: product,
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
