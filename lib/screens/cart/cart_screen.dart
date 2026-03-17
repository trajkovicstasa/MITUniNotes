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
              title: "Nema kupljenih beleški",
              subtitle:
                  "Kada dodaš beleške za kupovinu, ovde ćeš videti svoju listu i ukupnu cenu.",
              buttonText: "Istraži beleške",
            ),
          )
        : Scaffold(
            bottomSheet: CartBottomSheetWidget(function: () async {
              await placeOrder(
                cartProvider: cartProvider,
                productProvider: productsProvider,
                userProvider: userProvider,
              );
            }),
            appBar: AppBar(
              leading: const Padding(
                padding: EdgeInsets.all(8.0),
                child: UniNotesLogo(size: 34),
              ),
              title: TitelesTextWidget(
                  label: "Kupovine (${cartProvider.getCartitems.length})"),
              actions: [
                IconButton(
                  onPressed: () {
                    MyAppFunctions.showErrorOrWarningDialog(
                      isError: false,
                      context: context,
                      subtitle: "Obrisati sve stavke iz kupovine?",
                      fct: () async {
                        //cartProvider.clearLocalCart();
                        cartProvider.clearCartFromFirebase();
                      },
                    );
                  },
                  icon: const Icon(Icons.delete_forever_rounded),
                )
              ],
            ),
            body: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                      itemCount: cartProvider.getCartitems.length,
                      itemBuilder: (context, index) {
                        return ChangeNotifierProvider.value(
                            value: cartProvider.getCartitems.values
                                .toList()[index],
                            child: const CartWidget());
                      }),
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
    User? user = auth.currentUser;
    if (user == null) {
      return;
    }
    final uid = user.uid;
    try {
      setState(() {});
      cartProvider.getCartitems.forEach((key, value) async {
        final getCurrProduct = productProvider.findByProductId(value.productId);
        final orderId = const Uuid().v4();
        await FirebaseFirestore.instance.collection("orders").doc(orderId).set({
          'orderId': orderId,
          'userId': uid,
          'productId': value.productId,
          "productTitle": getCurrProduct!.productTitle,
          'price': double.parse(getCurrProduct.productPrice) * value.quantity,
          'totalPrice':
              cartProvider.getTotal(productsProvider: productProvider),
          'quantity': value.quantity,
          'imageUrl': getCurrProduct.productImage,
          'userName': userProvider.getUserModel!.userName,
          'orderDate': Timestamp.now(),
        });
      });
      await cartProvider.clearCartFromFirebase();
      cartProvider.clearLocalCart();
    } catch (e) {
      await MyAppFunctions.showErrorOrWarningDialog(
        // ignore: use_build_context_synchronously
        context: context,
        subtitle: e.toString(),
        fct: () {},
      );
    } finally {
      setState(() {});
    }
  }
}
