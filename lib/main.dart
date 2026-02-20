import 'package:flutter/material.dart';
import 'package:notes_hub/providers/cart_provider.dart';
import 'package:notes_hub/providers/products_provider.dart';
import 'package:notes_hub/providers/viewed_recently_provider.dart';
import 'package:notes_hub/providers/wishlist_provider.dart';
import 'package:notes_hub/screens/auth/forgot_password.dart';
import 'package:notes_hub/screens/auth/login.dart';
import 'package:notes_hub/screens/auth/register.dart';
import 'package:notes_hub/screens/inner_screen/orders/orders_screen.dart';
import 'package:notes_hub/screens/inner_screen/product_details.dart';
import 'package:notes_hub/screens/inner_screen/viewed_recently.dart';
import 'package:notes_hub/screens/inner_screen/wishlist.dart';
import 'package:notes_hub/screens/root_screen.dart';
import 'package:notes_hub/screens/search_screen.dart';
import 'package:provider/provider.dart';
import 'package:notes_hub/providers/theme_provider.dart';
import 'package:notes_hub/consts/theme_data.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) {
          return ThemeProvider();
        }),
        ChangeNotifierProvider(create: (_) {
          return ProductsProvider();
        }),
        ChangeNotifierProvider(create: (_) {
          return CartProvider();
        }),
        ChangeNotifierProvider(create: (_) {
          return WishlistProvider();
        }),
        ChangeNotifierProvider(create: (_) {
          return ViewedProdProvider();
        }),
      ],
      child: Consumer<ThemeProvider>(builder: (context, themeProvider, child) {
        return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'FTN Skriptarnica',
            theme: Styles.themeData(
                isDarkTheme: themeProvider.getIsDarkTheme, context: context),
            home: const LoginScreen(),
            routes: {
              RootScreen.routeName: (context) => const RootScreen(),
              ProductDetailsScreen.routName: (context) =>
                  const ProductDetailsScreen(),
              WishlistScreen.routName: (context) => const WishlistScreen(),
              ViewedRecentlyScreen.routName: (context) =>
                  const ViewedRecentlyScreen(),
              RegisterScreen.routName: (context) => const RegisterScreen(),
              LoginScreen.routeName: (context) => const LoginScreen(),
              OrdersScreen.routeName: (context) => const OrdersScreen(),
              ForgotPasswordScreen.routeName: (context) =>
              const ForgotPasswordScreen(),
              SearchScreen.routName: (context) => const SearchScreen(),
            });
      }),
    );
  }
}
