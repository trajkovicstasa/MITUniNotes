import 'package:dynamic_height_grid_view/dynamic_height_grid_view.dart';
import 'package:flutter/material.dart';
import 'package:notes_hub/providers/products_provider.dart';
import 'package:notes_hub/providers/viewed_recently_provider.dart';
import 'package:notes_hub/services/assets_manager.dart';
import 'package:notes_hub/widgets/empty_bag.dart';
import 'package:notes_hub/widgets/products/product_widget.dart';
import 'package:notes_hub/widgets/title_text.dart';
import 'package:provider/provider.dart';

class ViewedRecentlyScreen extends StatefulWidget {
  static const routName = "/nedavno-pregledano";
  const ViewedRecentlyScreen({super.key});

  @override
  State<ViewedRecentlyScreen> createState() => _ViewedRecentlyScreenState();
}

class _ViewedRecentlyScreenState extends State<ViewedRecentlyScreen> {
  late final Future<void> _screenLoader;

  @override
  void initState() {
    super.initState();
    _screenLoader = _loadScreenData();
  }

  Future<void> _loadScreenData() async {
    await Provider.of<ProductsProvider>(context, listen: false).fetchProducts();
  }

  AppBar _buildAppBar(BuildContext context, int itemCount) {
    return AppBar(
      leading: IconButton(
        onPressed: () => Navigator.of(context).maybePop(),
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
      ),
      title: TitelesTextWidget(
        label: "Nedavno pregledano ($itemCount)",
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewedProdProvider = Provider.of<ViewedProdProvider>(context);

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
            appBar: _buildAppBar(context, viewedProdProvider.getViewedProds.length),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SelectableText(snapshot.error.toString()),
              ),
            ),
          );
        }

        if (viewedProdProvider.getViewedProds.isEmpty) {
          return Scaffold(
            appBar: _buildAppBar(context, 0),
            body: EmptyBagWidget(
              imagePath: "${AssetsManager.imagePath}/bag/checkout.png",
              title: "Jos nema nedavno pregledanih skripti",
              subtitle: "Ovde ce se cuvati istorija skripti koje otvoris.",
              buttonText: "Istrazi skripte",
            ),
          );
        }

        return Scaffold(
          appBar: _buildAppBar(context, viewedProdProvider.getViewedProds.length),
          body: DynamicHeightGridView(
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            builder: (context, index) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: ProductWidget(
                  productId: viewedProdProvider.getViewedProds.values
                      .toList()[index]
                      .productId,
                ),
              );
            },
            itemCount: viewedProdProvider.getViewedProds.length,
            crossAxisCount: 2,
          ),
        );
      },
    );
  }
}
