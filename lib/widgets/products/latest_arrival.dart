import 'package:fancy_shimmer_image/fancy_shimmer_image.dart';
import 'package:flutter/material.dart';
import 'package:notes_hub/consts/app_colors.dart';
import 'package:notes_hub/models/product_model.dart';
import 'package:notes_hub/providers/cart_provider.dart';
import 'package:notes_hub/providers/viewed_recently_provider.dart';
import 'package:notes_hub/screens/inner_screen/product_details.dart';
import 'package:notes_hub/services/my_app_functions.dart';
import 'package:notes_hub/widgets/products/heart_btn.dart';
import 'package:notes_hub/widgets/subtitle_text.dart';
import 'package:provider/provider.dart';

class LatestArrivalProductsWidget extends StatelessWidget {
  const LatestArrivalProductsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final productModel = Provider.of<ProductModel>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final viewedProdProvider = Provider.of<ViewedProdProvider>(context);

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () {
          viewedProdProvider.addOrRemoveFromViewedProd(
            productId: productModel.productId,
          );
          Navigator.pushNamed(
            context,
            ProductDetailsScreen.routName,
            arguments: productModel.productId,
          );
        },
        child: SizedBox(
          width: size.width * 0.78,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: FancyShimmerImage(
                      imageUrl: productModel.productImage,
                      height: size.width * 0.22,
                      width: size.width * 0.26,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          "Nova beleska",
                          style: TextStyle(
                            color: AppColors.lightPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        productModel.productTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FittedBox(
                        child: Row(
                          children: [
                            HeartButtonWidget(
                              productId: productModel.productId,
                            ),
                            IconButton(
                              onPressed: () async {
                                try {
                                  await cartProvider.addToCartFirebase(
                                    productId: productModel.productId,
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
                                cartProvider.isProdinCart(
                                  productId: productModel.productId,
                                )
                                    ? Icons.check_circle_rounded
                                    : Icons.add_shopping_cart_outlined,
                                size: 22,
                                color: AppColors.lightPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      SubtitleTextWidget(
                        label: "${productModel.productPrice} RSD",
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
