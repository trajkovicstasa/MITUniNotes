import 'package:dynamic_height_grid_view/dynamic_height_grid_view.dart';
import 'package:flutter/material.dart';
import 'package:notes_hub/providers/products_provider.dart';
import 'package:notes_hub/providers/wishlist_provider.dart';
import 'package:notes_hub/services/assets_manager.dart';
import 'package:notes_hub/services/my_app_functions.dart';
import 'package:notes_hub/widgets/empty_bag.dart';
import 'package:notes_hub/widgets/products/product_widget.dart';
import 'package:notes_hub/widgets/title_text.dart';
import 'package:provider/provider.dart';

class WishlistScreen extends StatefulWidget {
  static const routName = "/sacuvane-skripte";
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  late final Future<void> _screenLoader;

  @override
  void initState() {
    super.initState();
    _screenLoader = _loadScreenData();
  }

  Future<void> _loadScreenData() async {
    final productsProvider = Provider.of<ProductsProvider>(context, listen: false);
    final wishlistProvider = Provider.of<WishlistProvider>(context, listen: false);

    await productsProvider.fetchProducts();
    await wishlistProvider.fetchWishlist();
  }

  AppBar _buildAppBar(BuildContext context, int itemCount) {
    return AppBar(
      leading: IconButton(
        onPressed: () => Navigator.of(context).maybePop(),
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
      ),
      title: TitelesTextWidget(
        label: "Sacuvane skripte ($itemCount)",
      ),
      actions: [
        if (itemCount > 0)
          IconButton(
            onPressed: () {
              MyAppFunctions.showErrorOrWarningDialog(
                isError: false,
                context: context,
                subtitle: "Obrisati sve sacuvane skripte?",
                fct: () async {
                  await Provider.of<WishlistProvider>(context, listen: false)
                      .clearWishlistFromFirebase();
                },
              );
            },
            icon: const Icon(Icons.delete_forever_rounded),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final wishlistProvider = Provider.of<WishlistProvider>(context);

    return FutureBuilder<void>(
      future: _screenLoader,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: _buildAppBar(context, wishlistProvider.getWishlists.length),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SelectableText(snapshot.error.toString()),
              ),
            ),
          );
        }

        if (wishlistProvider.getWishlists.isEmpty) {
          return Scaffold(
            appBar: _buildAppBar(context, 0),
            body: EmptyBagWidget(
              imagePath: "${AssetsManager.imagePath}/bag/wishlist.png",
              title: "Jos nemas sacuvanih skripti",
              subtitle: "Ovde ces videti skripte koje oznacis kao omiljene.",
              buttonText: "Istrazi skripte",
            ),
          );
        }

        return Scaffold(
          appBar: _buildAppBar(context, wishlistProvider.getWishlists.length),
          body: DynamicHeightGridView(
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            builder: (context, index) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: ProductWidget(
                  productId: wishlistProvider.getWishlists.values
                      .toList()[index]
                      .productId,
                ),
              );
            },
            itemCount: wishlistProvider.getWishlists.length,
            crossAxisCount: 2,
          ),
        );
      },
    );
  }
}
