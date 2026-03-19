import 'package:flutter/material.dart';
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
            child: SelectableText("No products has been added"),
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
            title: 'Inspect All Products',
            subtitle:
                'Pregled svih proizvoda iz baze sa pretragom i ulazom u edit formu.',
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
                          hintText: 'Search by product title',
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
                      label: 'Nema proizvoda za prikaz.',
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
                                      'Predmet: ${product.productCategory} | Cena: ${product.productPrice}',
                                  maxLines: 1,
                                ),
                                const SizedBox(height: 6),
                                AppSubtitleText(
                                  label: product.productDescription,
                                  maxLines: 2,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
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
