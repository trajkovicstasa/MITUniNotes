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

  static Future<void> imagePickerDialog({
    required BuildContext context,
    required Future<void> Function() cameraFCT,
    required Future<void> Function() galleryFCT,
    required VoidCallback removeFCT,
    bool hasImage = false,
  }) async {
    await showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Gallery'),
                  onTap: () async {
                    Navigator.pop(context);
                    await galleryFCT();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Camera'),
                  onTap: () async {
                    Navigator.pop(context);
                    await cameraFCT();
                  },
                ),
                if (hasImage)
                  ListTile(
                    leading: const Icon(Icons.delete_outline),
                    title: const Text('Remove image'),
                    onTap: () {
                      Navigator.pop(context);
                      removeFCT();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
