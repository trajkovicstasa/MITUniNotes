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

class MyUnlockedScriptsScreen extends StatefulWidget {
  static const routeName = '/moje-otkljucane-skripte';

  const MyUnlockedScriptsScreen({super.key});

  @override
  State<MyUnlockedScriptsScreen> createState() => _MyUnlockedScriptsScreenState();
}

class _MyUnlockedScriptsScreenState extends State<MyUnlockedScriptsScreen> {
  Future<List<_UnlockedScriptViewModel>> _fetchUnlockedScripts() async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final productsProvider =
        Provider.of<ProductsProvider>(context, listen: false);

    final results = await Future.wait([
      orderProvider.fetchOrder(),
      productsProvider.fetchProducts(),
    ]);

    final orders = results[0] as List<OrdersModel>;
    final products = results[1] as List<ProductModel>;
    final purchasedProductIds = orders.map((order) => order.productId).toSet();

    final unlocked = <_UnlockedScriptViewModel>[];
    for (final product in products) {
      final isUnlocked = product.isFree || purchasedProductIds.contains(product.productId);
      if (!isUnlocked) {
        continue;
      }

      unlocked.add(
        _UnlockedScriptViewModel(
          product: product,
          unlockedByPurchase: !product.isFree,
        ),
      );
    }

    return unlocked;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const TitelesTextWidget(label: 'Moje otkljucane skripte'),
      ),
      body: FutureBuilder<List<_UnlockedScriptViewModel>>(
        future: _fetchUnlockedScripts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: SelectableText(snapshot.error.toString()));
          }

          final unlockedScripts = snapshot.data ?? const <_UnlockedScriptViewModel>[];
          if (unlockedScripts.isEmpty) {
            return EmptyBagWidget(
              imagePath: "${AssetsManager.imagePath}/bag/checkout.png",
              title: "Jos nemas otkljucane skripte",
              subtitle: "",
              buttonText: "Istrazi skripte",
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: unlockedScripts.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _UnlockedScriptCard(item: unlockedScripts[index]);
            },
          );
        },
      ),
    );
  }
}

class _UnlockedScriptViewModel {
  const _UnlockedScriptViewModel({
    required this.product,
    required this.unlockedByPurchase,
  });

  final ProductModel product;
  final bool unlockedByPurchase;
}

class _UnlockedScriptCard extends StatelessWidget {
  const _UnlockedScriptCard({required this.item});

  final _UnlockedScriptViewModel item;

  @override
  Widget build(BuildContext context) {
    final product = item.product;

    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          Navigator.pushNamed(
            context,
            ProductDetailsScreen.routName,
            arguments: product.productId,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.network(
                  product.productImage,
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
                        _UnlockedMetaPill(label: product.productCategory),
                        _UnlockedMetaPill(
                          label: product.isFree ? 'Besplatna' : 'Premium',
                        ),
                        _UnlockedMetaPill(
                          label: item.unlockedByPurchase
                              ? 'Otkljucano kupovinom'
                              : 'Dostupno odmah',
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      product.productTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SubtitleTextWidget(
                      label: product.productDescription,
                      color: AppColors.muted,
                      fontSize: 14,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.lock_open_rounded,
                          color: Colors.green,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: SubtitleTextWidget(
                            label: item.unlockedByPurchase
                                ? 'Preview i download su vec dostupni.'
                                : 'Skripta je besplatna i odmah dostupna.',
                            fontSize: 14,
                            color: AppColors.muted,
                            maxLines: 2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              ProductDetailsScreen.routName,
                              arguments: product.productId,
                            );
                          },
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

class _UnlockedMetaPill extends StatelessWidget {
  const _UnlockedMetaPill({required this.label});

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
