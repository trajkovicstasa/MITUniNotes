import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_paypal_payment_plus/flutter_paypal_payment_plus.dart';
import 'package:notes_hub/consts/paypal_demo_config.dart';
import 'package:notes_hub/models/product_model.dart';
import 'package:notes_hub/providers/cart_provider.dart';
import 'package:notes_hub/providers/products_provider.dart';

enum PayPalCheckoutStatus {
  success,
  cancelled,
  error,
}

class PayPalCheckoutResult {
  const PayPalCheckoutResult({
    required this.status,
    this.payload,
    this.errorMessage,
  });

  final PayPalCheckoutStatus status;
  final Map<String, dynamic>? payload;
  final String? errorMessage;

  bool get isSuccess => status == PayPalCheckoutStatus.success;
}

class PayPalDemoService {
  const PayPalDemoService._();

  static Future<PayPalCheckoutResult> startCheckout({
    required BuildContext context,
    required CartProvider cartProvider,
    required ProductsProvider productsProvider,
  }) async {
    if (!PayPalDemoConfig.isConfigured) {
      return const PayPalCheckoutResult(
        status: PayPalCheckoutStatus.error,
        errorMessage:
            'PayPal sandbox nije podesen. Dodaj clientId i secretKey u paypal_demo_config.dart.',
      );
    }

    final transactions = _buildTransaction(
      cartProvider: cartProvider,
      productsProvider: productsProvider,
    );
    if (transactions == null) {
      return const PayPalCheckoutResult(
        status: PayPalCheckoutStatus.error,
        errorMessage: 'Korpa nema validne stavke za PayPal checkout.',
      );
    }

    final completer = Completer<PayPalCheckoutResult>();

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (checkoutContext) => PaypalCheckoutView(
          sandboxMode: true,
          clientId: PayPalDemoConfig.clientId,
          secretKey: PayPalDemoConfig.secretKey,
          returnURL: PayPalDemoConfig.returnUrl,
          cancelURL: PayPalDemoConfig.cancelUrl,
          transactions: transactions,
          note: 'UniNotes demo checkout',
          appBar: AppBar(
            title: const Text('PayPal Checkout'),
          ),
          onSuccess: (PaymentSuccessModel model) {
            if (!completer.isCompleted) {
              completer.complete(
                PayPalCheckoutResult(
                  status: PayPalCheckoutStatus.success,
                  payload: model.toJson(),
                ),
              );
            }
            Navigator.of(checkoutContext).pop();
          },
          onError: (error) {
            if (!completer.isCompleted) {
              completer.complete(
                PayPalCheckoutResult(
                  status: PayPalCheckoutStatus.error,
                  errorMessage: error.toString(),
                ),
              );
            }
            Navigator.of(checkoutContext).pop();
          },
          onCancel: () {
            if (!completer.isCompleted) {
              completer.complete(
                const PayPalCheckoutResult(
                  status: PayPalCheckoutStatus.cancelled,
                ),
              );
            }
            Navigator.of(checkoutContext).pop();
          },
        ),
      ),
    );

    if (!completer.isCompleted) {
      return const PayPalCheckoutResult(
        status: PayPalCheckoutStatus.cancelled,
      );
    }

    return completer.future;
  }

  static TransactionOption? _buildTransaction({
    required CartProvider cartProvider,
    required ProductsProvider productsProvider,
  }) {
    final items = <Item>[];
    double subtotal = 0;

    for (final cartItem in cartProvider.getCartitems.values) {
      final product = productsProvider.findByProductId(cartItem.productId);
      if (product == null) {
        continue;
      }

      final unitPriceEur = _convertRsdToEur(product: product);
      subtotal += unitPriceEur * cartItem.quantity;
      items.add(
        Item(
          name: product.productTitle,
          quantity: cartItem.quantity,
          price: _formatAmount(unitPriceEur),
          currency: PayPalDemoConfig.currencyCode,
        ),
      );
    }

    if (items.isEmpty) {
      return null;
    }

    final subtotalFormatted = _formatAmount(subtotal);
    return TransactionOption(
      payPalAmount: PayPalAmount(
        total: subtotalFormatted,
        currency: PayPalDemoConfig.currencyCode,
        details: PaymentDetails(
          subtotal: subtotalFormatted,
          shipping: '0',
          shippingDiscount: 0,
        ),
      ),
      description: 'UniNotes premium skripte',
      itemList: ItemList(items: items),
    );
  }

  static double _convertRsdToEur({required ProductModel product}) {
    final priceRsd = CartProvider.parsePriceValue(product.productPrice);
    final converted = priceRsd / PayPalDemoConfig.rsdPerEuro;
    return double.parse(converted.toStringAsFixed(2));
  }

  static String _formatAmount(double amount) {
    return amount.toStringAsFixed(2);
  }
}
