import 'package:dynamic_height_grid_view/dynamic_height_grid_view.dart';
import 'package:flutter/material.dart';
import 'package:notes_hub/providers/order_provider.dart';
import 'package:notes_hub/providers/products_provider.dart';
import 'package:notes_hub/providers/viewed_recently_provider.dart';
import 'package:notes_hub/providers/wishlist_provider.dart';
import 'package:notes_hub/services/assets_manager.dart';
import 'package:notes_hub/widgets/empty_bag.dart';
import 'package:notes_hub/widgets/products/product_widget.dart';
import 'package:notes_hub/widgets/subtitle_text.dart';
import 'package:notes_hub/widgets/title_text.dart';
import 'package:provider/provider.dart';

enum CollectionNotesType {
  publicNotes,
  premiumNotes,
  personalLibrary,
}

class CollectionNotesScreen extends StatefulWidget {
  const CollectionNotesScreen.publicNotes({super.key})
      : type = CollectionNotesType.publicNotes;

  const CollectionNotesScreen.premiumNotes({super.key})
      : type = CollectionNotesType.premiumNotes;

  const CollectionNotesScreen.personalLibrary({super.key})
      : type = CollectionNotesType.personalLibrary;

  final CollectionNotesType type;

  @override
  State<CollectionNotesScreen> createState() => _CollectionNotesScreenState();
}

class _CollectionNotesScreenState extends State<CollectionNotesScreen> {
  late final Future<void> _screenLoader;

  @override
  void initState() {
    super.initState();
    _screenLoader = _loadScreenData();
  }

  Future<void> _loadScreenData() async {
    final futures = <Future<dynamic>>[
      Provider.of<ProductsProvider>(context, listen: false).fetchProducts(),
    ];

    if (widget.type == CollectionNotesType.personalLibrary) {
      futures.add(
        Provider.of<WishlistProvider>(context, listen: false).fetchWishlist(),
      );
      futures.add(
        Provider.of<OrderProvider>(context, listen: false).fetchOrder(),
      );
    }

    await Future.wait(futures);
  }

  String get _title {
    switch (widget.type) {
      case CollectionNotesType.publicNotes:
        return 'Javne beleske';
      case CollectionNotesType.premiumNotes:
        return 'Premium sadrzaj';
      case CollectionNotesType.personalLibrary:
        return 'Moje beleznice';
    }
  }

  String get _subtitle {
    switch (widget.type) {
      case CollectionNotesType.publicNotes:
        return 'Ovde su sve odobrene besplatne beleske koje korisnici mogu odmah da pregledaju.';
      case CollectionNotesType.premiumNotes:
        return 'Ovde su sve premium beleske za kupovinu, pregled i dalje otkljucavanje.';
      case CollectionNotesType.personalLibrary:
        return 'Na jednom mestu su sacuvane, kupljene i nedavno pregledane skripte.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: TitelesTextWidget(label: _title),
      ),
      body: FutureBuilder<void>(
        future: _screenLoader,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SelectableText(snapshot.error.toString()),
              ),
            );
          }

          switch (widget.type) {
            case CollectionNotesType.publicNotes:
              return _CollectionListBody(
                title: _title,
                subtitle: _subtitle,
                productIds: _publicProductIds(context),
                emptyTitle: 'Trenutno nema javnih beleski',
                emptySubtitle: 'Kada budu dostupne besplatne skripte, pojavice se ovde.',
              );
            case CollectionNotesType.premiumNotes:
              return _CollectionListBody(
                title: _title,
                subtitle: _subtitle,
                productIds: _premiumProductIds(context),
                emptyTitle: 'Trenutno nema premium sadrzaja',
                emptySubtitle: 'Kada premium skripte budu dodate ili odobrene, videces ih ovde.',
              );
            case CollectionNotesType.personalLibrary:
              return _PersonalLibraryBody(subtitle: _subtitle);
          }
        },
      ),
    );
  }

  List<String> _publicProductIds(BuildContext context) {
    final products = Provider.of<ProductsProvider>(context, listen: false).getProducts;
    return products.where((product) => product.isFree).map((product) => product.productId).toList();
  }

  List<String> _premiumProductIds(BuildContext context) {
    final products = Provider.of<ProductsProvider>(context, listen: false).getProducts;
    return products.where((product) => !product.isFree).map((product) => product.productId).toList();
  }
}

class _CollectionListBody extends StatelessWidget {
  const _CollectionListBody({
    required this.title,
    required this.subtitle,
    required this.productIds,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  final String title;
  final String subtitle;
  final List<String> productIds;
  final String emptyTitle;
  final String emptySubtitle;

  @override
  Widget build(BuildContext context) {
    if (productIds.isEmpty) {
      return EmptyBagWidget(
        imagePath: "${AssetsManager.imagePath}/bag/checkout.png",
        title: emptyTitle,
        subtitle: emptySubtitle,
        buttonText: 'Nazad na pocetnu',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TitelesTextWidget(label: title),
          const SizedBox(height: 6),
          SubtitleTextWidget(label: subtitle),
          const SizedBox(height: 18),
          _ProductsGrid(productIds: productIds),
        ],
      ),
    );
  }
}

class _PersonalLibraryBody extends StatelessWidget {
  const _PersonalLibraryBody({required this.subtitle});

  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final productsProvider = Provider.of<ProductsProvider>(context, listen: false);
    final wishlistProvider = Provider.of<WishlistProvider>(context);
    final viewedProvider = Provider.of<ViewedProdProvider>(context);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    final savedIds = _existingProductIds(
      wishlistProvider.getWishlists.values.map((item) => item.productId).toList(),
      productsProvider,
    );
    final purchasedIds = _existingProductIds(
      _uniqueProductIds(orderProvider.getOrders.map((order) => order.productId).toList()),
      productsProvider,
    );
    final viewedIds = _existingProductIds(
      viewedProvider.getViewedProds.values.map((item) => item.productId).toList(),
      productsProvider,
    );

    final isEmpty =
        savedIds.isEmpty && purchasedIds.isEmpty && viewedIds.isEmpty;

    if (isEmpty) {
      return EmptyBagWidget(
        imagePath: "${AssetsManager.imagePath}/bag/wishlist.png",
        title: 'Moje beleznice su trenutno prazne',
        subtitle:
            'Kada sacuvas, kupis ili otvoris neku skriptu, ona ce se pojaviti ovde.',
        buttonText: 'Nazad na pocetnu',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TitelesTextWidget(label: 'Moje beleznice'),
          const SizedBox(height: 6),
          SubtitleTextWidget(label: subtitle),
          if (savedIds.isNotEmpty) ...[
            const SizedBox(height: 20),
            const _CollectionSectionHeader(
              title: 'Sacuvane skripte',
              subtitle: 'Sve sto si oznacio kao omiljeno.',
            ),
            const SizedBox(height: 14),
            _ProductsGrid(productIds: savedIds),
          ],
          if (purchasedIds.isNotEmpty) ...[
            const SizedBox(height: 20),
            const _CollectionSectionHeader(
              title: 'Kupljene skripte',
              subtitle: 'Skripte koje su ti otkljucane kroz kupovinu.',
            ),
            const SizedBox(height: 14),
            _ProductsGrid(productIds: purchasedIds),
          ],
          if (viewedIds.isNotEmpty) ...[
            const SizedBox(height: 20),
            const _CollectionSectionHeader(
              title: 'Nedavno pregledane',
              subtitle: 'Poslednje skripte koje si otvorio.',
            ),
            const SizedBox(height: 14),
            _ProductsGrid(productIds: viewedIds),
          ],
        ],
      ),
    );
  }

  List<String> _existingProductIds(
    List<String> productIds,
    ProductsProvider productsProvider,
  ) {
    return productIds
        .where((productId) => productsProvider.findByProductId(productId) != null)
        .toList();
  }

  List<String> _uniqueProductIds(List<String> productIds) {
    final seen = <String>{};
    final uniqueIds = <String>[];
    for (final productId in productIds) {
      if (seen.add(productId)) {
        uniqueIds.add(productId);
      }
    }
    return uniqueIds;
  }
}

class _CollectionSectionHeader extends StatelessWidget {
  const _CollectionSectionHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TitelesTextWidget(label: title, fontSize: 20),
        const SizedBox(height: 4),
        SubtitleTextWidget(label: subtitle),
      ],
    );
  }
}

class _ProductsGrid extends StatelessWidget {
  const _ProductsGrid({required this.productIds});

  final List<String> productIds;

  @override
  Widget build(BuildContext context) {
    return DynamicHeightGridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      itemCount: productIds.length,
      crossAxisCount: 2,
      builder: (context, index) {
        return Padding(
          padding: const EdgeInsets.all(8),
          child: ProductWidget(productId: productIds[index]),
        );
      },
    );
  }
}
