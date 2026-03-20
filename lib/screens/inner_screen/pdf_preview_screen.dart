import 'package:flutter/material.dart';
import 'package:notes_hub/consts/app_colors.dart';
import 'package:notes_hub/widgets/subtitle_text.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfPreviewArguments {
  const PdfPreviewArguments({
    required this.title,
    required this.pdfUrl,
  });

  final String title;
  final String pdfUrl;
}

class PdfPreviewScreen extends StatelessWidget {
  const PdfPreviewScreen({super.key});

  static const routeName = '/pdf-preview';

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as PdfPreviewArguments?;

    if (args == null || args.pdfUrl.trim().isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('PDF pregled'),
        ),
        body: const Center(
          child: SubtitleTextWidget(
            label: 'PDF nije dostupan za pregled.',
            color: AppColors.muted,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          args.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SfPdfViewer.network(
        args.pdfUrl,
        canShowScrollHead: true,
        canShowScrollStatus: true,
        onDocumentLoadFailed: (details) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PDF nije ucitan: ${details.description}'),
            ),
          );
        },
      ),
    );
  }
}
