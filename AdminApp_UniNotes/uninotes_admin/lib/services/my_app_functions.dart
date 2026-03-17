import 'package:flutter/material.dart';

class MyAppFunctions {
  static Future<void> showErrorOrWarningDialog({
    required BuildContext context,
    required String subtitle,
    required VoidCallback fct,
    bool isError = true,
  }) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isError ? 'Notice' : 'Confirm'),
          content: Text(subtitle),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                fct();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
