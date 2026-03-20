import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:notes_hub/providers/cart_provider.dart';
import 'package:notes_hub/providers/products_provider.dart';
import 'package:notes_hub/providers/user_provider.dart';
import 'package:notes_hub/screens/cart/bottom_checkout.dart';
import 'package:notes_hub/screens/cart/cart_widget.dart';
import 'package:notes_hub/services/assets_manager.dart';
import 'package:notes_hub/services/my_app_functions.dart';
import 'package:notes_hub/widgets/empty_bag.dart';
import 'package:notes_hub/widgets/title_text.dart';
import 'package:notes_hub/widgets/uninotes_logo.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final productsProvider =
        Provider.of<ProductsProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context);

    return cartProvider.getCartitems.isEmpty
        ? Scaffold(
            body: EmptyBagWidget(
              imagePath: "${AssetsManager.imagePath}/bag/checkout.png",
              title: "Korpa je trenutno prazna",
              subtitle:
                  "Kada dodas skripte za kupovinu, ovde ces videti svoju listu i ukupnu cenu.",
              buttonText: "Istrazi skripte",
            ),
          )
        : Scaffold(
            bottomSheet: CartBottomSheetWidget(
              function: () async {
                if (_isLoading) {
                  return;
                }
                await placeOrder(
                  cartProvider: cartProvider,
                  productProvider: productsProvider,
                  userProvider: userProvider,
                );
              },
            ),
            appBar: AppBar(
              leading: const Padding(
                padding: EdgeInsets.all(8.0),
                child: UniNotesLogo(size: 34),
              ),
              title: TitelesTextWidget(
                label: "Kupovine (${cartProvider.getCartitems.length})",
              ),
              actions: [
                IconButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          MyAppFunctions.showErrorOrWarningDialog(
                            isError: false,
                            context: context,
                            subtitle: "Obrisati sve stavke iz korpe?",
                            fct: () async {
                              await cartProvider.clearCartFromFirebase();
                            },
                          );
                        },
                  icon: const Icon(Icons.delete_forever_rounded),
                ),
              ],
            ),
            body: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cartProvider.getCartitems.length,
                    itemBuilder: (context, index) {
                      return ChangeNotifierProvider.value(
                        value: cartProvider.getCartitems.values.toList()[index],
                        child: const CartWidget(),
                      );
                    },
                  ),
                ),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: CircularProgressIndicator(),
                  ),
                const SizedBox(
                  height: kBottomNavigationBarHeight + 10,
                ),
              ],
            ),
          );
  }

  Future<void> placeOrder({
    required CartProvider cartProvider,
    required ProductsProvider productProvider,
    required UserProvider userProvider,
  }) async {
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;
    if (user == null) {
      return;
    }

    final uid = user.uid;
    try {
      setState(() {
        _isLoading = true;
      });

      for (final value in cartProvider.getCartitems.values) {
        final getCurrProduct = productProvider.findByProductId(value.productId);
        final orderId = const Uuid().v4();
        await FirebaseFirestore.instance.collection("orders").doc(orderId).set({
          'orderId': orderId,
          'userId': uid,
          'productId': value.productId,
          "productTitle": getCurrProduct!.productTitle,
          'price':
              CartProvider.parsePriceValue(getCurrProduct.productPrice) *
                  value.quantity,
          'totalPrice': cartProvider.getTotal(productsProvider: productProvider),
          'quantity': value.quantity,
          'imageUrl': getCurrProduct.productImage,
          'userName': userProvider.getUserModel!.userName,
          'orderDate': Timestamp.now(),
        });
      }

      await cartProvider.clearCartFromFirebase();
      cartProvider.clearLocalCart();
    } catch (e) {
      if (!mounted) {
        return;
      }
      await MyAppFunctions.showErrorOrWarningDialog(
        context: context,
        subtitle: e.toString(),
        fct: () {},
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
