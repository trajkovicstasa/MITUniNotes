import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:notes_hub/consts/app_colors.dart';
import 'package:notes_hub/providers/cart_provider.dart';
import 'package:notes_hub/providers/products_provider.dart';
import 'package:notes_hub/providers/user_provider.dart';
import 'package:notes_hub/providers/wishlist_provider.dart';
import 'package:notes_hub/screens/cart/cart_screen.dart';
import 'package:notes_hub/screens/home_screen.dart';
import 'package:notes_hub/screens/profile_screen.dart';
import 'package:notes_hub/screens/search_screen.dart';
import 'package:provider/provider.dart';
import 'dart:developer';

class RootScreen extends StatefulWidget {
  static const String routeName = "/RootScreen";
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  late List<Widget> screens;
  int currentScreen = 0;
  late PageController controller;

  bool isLoadingProd = true;

  @override
  void initState() {
    super.initState();

    screens = const [
      HomeScreen(),
      SearchScreen(),
      CartScreen(),
      ProfileScreen(),
    ];
    controller = PageController(initialPage: currentScreen);
  }
  Future<void> fetchFCT() async {
    final productsProvider =
        Provider.of<ProductsProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final wishlistsProvider =
        Provider.of<WishlistProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    try {
      await Future.wait({
        productsProvider.fetchProducts(),
        userProvider.fetchUserInfo(),
      });
      await Future.wait({
        cartProvider.fetchCart(),
        wishlistsProvider.fetchWishlist(),
      });
    } catch (error) {
      log(error.toString());
    }
  }

  @override
  void didChangeDependencies() {
    if (isLoadingProd) {
      fetchFCT();
      isLoadingProd = false;
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    return Scaffold(
      body: PageView(
        physics: const NeverScrollableScrollPhysics(),
        controller: controller,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentScreen,
        backgroundColor: Theme.of(context).navigationBarTheme.backgroundColor,
        onDestinationSelected: (index) {
          setState(() {
            currentScreen = index;
          });

          controller.jumpToPage(currentScreen);
        },
        destinations: [
          const NavigationDestination(
            selectedIcon: Icon(IconlyBold.home),
            icon: Icon(IconlyLight.home),
            label: "Pocetna",
          ),
          const NavigationDestination(
            selectedIcon: Icon(IconlyBold.search),
            icon: Icon(IconlyLight.search),
            label: "Istrazi",
          ),
          NavigationDestination(
            selectedIcon: const Icon(IconlyBold.bag2),
            icon: Badge(
                isLabelVisible: cartProvider.getCartitems.isNotEmpty,
                backgroundColor: AppColors.darkPrimary,
                label: Text(cartProvider.getCartitems.length.toString()),
                child: const Icon(IconlyLight.bag2)),
                label: "Kupovine",
          ),
          const NavigationDestination(
            selectedIcon: Icon(IconlyBold.profile),
            icon: Icon(IconlyLight.profile),
            label: "Nalog",
          )
        ],
      ),
    );
  }
}
