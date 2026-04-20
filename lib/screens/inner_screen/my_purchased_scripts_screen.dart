import 'package:flutter/material.dart';
import 'package:notes_hub/consts/app_colors.dart';
import 'package:notes_hub/models/order_model.dart';
import 'package:notes_hub/models/product_model.dart';
import 'package:notes_hub/providers/order_provider.dart';
import 'package:notes_hub/providers/products_provider.dart';
import 'package:notes_hub/screens/inner_screen/product_details.dart';
import 'package:notes_hub/services/assets_manager.dart';
import 'package:notes_hub/widgets/empty_bag.dart';
import 'package:notes_hub/widgets/subtitle_text.dart';
import 'package:notes_hub/widgets/title_text.dart';
import 'package:provider/provider.dart';

class MyPurchasedScriptsScreen extends StatefulWidget {
  static const routeName = '/moje-kupljene-skripte';

  const MyPurchasedScriptsScreen({super.key});

  @override
  State<MyPurchasedScriptsScreen> createState() => _MyPurchasedScriptsScreenState();
}

class _MyPurchasedScriptsScreenState extends State<MyPurchasedScriptsScreen> {
  Future<List<_PurchasedScriptViewModel>> _fetchPurchasedScripts() async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final productsProvider =
        Provider.of<ProductsProvider>(context, listen: false);

    final results = await Future.wait([
      orderProvider.fetchOrder(),
      productsProvider.fetchProducts(),
    ]);

    final orders = results[0] as List<OrdersModel>;
    final products = results[1] as List<ProductModel>;
    final productsById = {
      for (final product in products) product.productId: product,
    };

    final seenProductIds = <String>{};
    final purchasedScripts = <_PurchasedScriptViewModel>[];

    for (final order in orders) {
      if (seenProductIds.contains(order.productId)) {
        continue;
      }
      seenProductIds.add(order.productId);

      purchasedScripts.add(
        _PurchasedScriptViewModel(
          order: order,
          product: productsById[order.productId],
        ),
      );
    }

    return purchasedScripts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const TitelesTextWidget(label: 'Moje kupljene skripte'),
      ),
      body: FutureBuilder<List<_PurchasedScriptViewModel>>(
        future: _fetchPurchasedScripts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: SelectableText(snapshot.error.toString()));
          }

          final purchasedScripts = snapshot.data ?? const <_PurchasedScriptViewModel>[];
          if (purchasedScripts.isEmpty) {
            return EmptyBagWidget(
              imagePath: "${AssetsManager.imagePath}/bag/checkout.png",
              title: "Jos nemas kupljene skripte",
              subtitle: "",
              buttonText: "Istrazi skripte",
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: purchasedScripts.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = purchasedScripts[index];
              return _PurchasedScriptCard(item: item);
            },
          );
        },
      ),
    );
  }
}

class _PurchasedScriptViewModel {
  const _PurchasedScriptViewModel({
    required this.order,
    required this.product,
  });

  final OrdersModel order;
  final ProductModel? product;
}

class _PurchasedScriptCard extends StatelessWidget {
  const _PurchasedScriptCard({required this.item});

  final _PurchasedScriptViewModel item;

  @override
  Widget build(BuildContext context) {
    final product = item.product;
    final imageUrl = product?.productImage ?? item.order.imageUrl;
    final title = product?.productTitle ?? item.order.productTitle;
    final category = product?.productCategory ?? 'Skripta';
    final accessType = product?.isFree == true ? 'Besplatna' : 'Premium';
    final canOpenDetails = product != null;

    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: canOpenDetails
            ? () {
                Navigator.pushNamed(
                  context,
                  ProductDetailsScreen.routName,
                  arguments: product.productId,
                );
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.network(
                  imageUrl,
                  width: 92,
                  height: 116,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 92,
                      height: 116,
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
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _PurchasedMetaPill(label: category),
                        _PurchasedMetaPill(label: accessType),
                        const _PurchasedMetaPill(label: 'Otkljucano'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SubtitleTextWidget(
                      label: 'Placeno: ${item.order.price} RSD | Kolicina: ${item.order.quantity}',
                      color: AppColors.muted,
                      fontSize: 14,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.download_done_rounded,
                          color: Colors.green,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: SubtitleTextWidget(
                            label: 'Detalji skripte otvaraju preview i download.',
                            fontSize: 14,
                            color: AppColors.muted,
                            maxLines: 2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: canOpenDetails
                              ? () {
                                  Navigator.pushNamed(
                                    context,
                                    ProductDetailsScreen.routName,
                                    arguments: product.productId,
                                  );
                                }
                              : null,
                          child: const Text('Otvori'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PurchasedMetaPill extends StatelessWidget {
  const _PurchasedMetaPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.lightPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
