import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:notes_hub/providers/cart_provider.dart';
import 'package:notes_hub/providers/order_provider.dart';
import 'package:notes_hub/providers/products_provider.dart';
import 'package:notes_hub/providers/user_provider.dart';
import 'package:notes_hub/providers/viewed_recently_provider.dart';
import 'package:notes_hub/providers/wishlist_provider.dart';
import 'package:notes_hub/screens/auth/forgot_password.dart';
import 'package:notes_hub/screens/auth/login.dart';
import 'package:notes_hub/screens/auth/register.dart';
import 'package:notes_hub/screens/admin/admin_root_screen.dart';
import 'package:notes_hub/screens/inner_screen/my_purchased_scripts_screen.dart';
import 'package:notes_hub/screens/inner_screen/my_unlocked_scripts_screen.dart';
import 'package:notes_hub/screens/inner_screen/orders/orders_screen.dart';
import 'package:notes_hub/screens/inner_screen/pdf_preview_screen.dart';
import 'package:notes_hub/screens/inner_screen/product_details.dart';
import 'package:notes_hub/screens/inner_screen/my_submissions_screen.dart';
import 'package:notes_hub/screens/inner_screen/submit_script_screen.dart';
import 'package:notes_hub/screens/inner_screen/viewed_recently.dart';
import 'package:notes_hub/screens/inner_screen/wishlist.dart';
import 'package:notes_hub/screens/root_screen.dart';
import 'package:notes_hub/screens/search_screen.dart';
import 'package:provider/provider.dart';
import 'package:notes_hub/providers/theme_provider.dart';
import 'package:notes_hub/consts/theme_data.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
        ChangeNotifierProvider(create: (_) {
          return UserProvider();
        }),
        ChangeNotifierProvider(create: (_) {
          return OrderProvider();
        }),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'UniNotes',
            theme: Styles.themeData(
              isDarkTheme: themeProvider.getIsDarkTheme,
              context: context,
            ),
            //home: const RootScreen(),
            home: const LoginScreen(),
            routes: {
              RootScreen.routeName: (context) => const RootScreen(),
              ProductDetailsScreen.routName: (context) =>
                  const ProductDetailsScreen(),
              PdfPreviewScreen.routeName: (context) =>
                  const PdfPreviewScreen(),
              WishlistScreen.routName: (context) => const WishlistScreen(),
              ViewedRecentlyScreen.routName: (context) =>
                  const ViewedRecentlyScreen(),
              RegisterScreen.routName: (context) => const RegisterScreen(),
              LoginScreen.routeName: (context) => const LoginScreen(),
              AdminRootScreen.routeName: (context) => const AdminRootScreen(),
              OrdersScreen.routeName: (context) => const OrdersScreen(),
              MyPurchasedScriptsScreen.routeName: (context) =>
                  const MyPurchasedScriptsScreen(),
              MyUnlockedScriptsScreen.routeName: (context) =>
                  const MyUnlockedScriptsScreen(),
              MySubmissionsScreen.routeName: (context) =>
                  const MySubmissionsScreen(),
              SubmitScriptScreen.routeName: (context) =>
                  const SubmitScriptScreen(),
              ForgotPasswordScreen.routeName: (context) =>
                  const ForgotPasswordScreen(),
              SearchScreen.routName: (context) => const SearchScreen(),
            },
          );
        },
      ),
    );
  }
}
