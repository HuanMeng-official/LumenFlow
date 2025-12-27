import 'dart:io';
import 'package:flutter/cupertino.dart';
import '../l10n/app_localizations.dart';

class ImagePreviewScreen extends StatelessWidget {
  final String imagePath;

  const ImagePreviewScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = CupertinoTheme.of(context).brightness;

    return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          backgroundColor: brightness == Brightness.dark
              ? CupertinoColors.systemBackground.darkColor.withAlpha(230)
              : CupertinoColors.systemBackground.color.withAlpha(230),
          border: null,
          middle: Text(
            l10n.imagePreview,
            style: TextStyle(
              color: CupertinoTheme.of(context).textTheme.textStyle.color,
            ),
          ),
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.of(context).pop(),
            child: const Icon(CupertinoIcons.xmark, size: 24),
          ),
        ),
        child: SafeArea(
          child: Container(
            color: brightness == Brightness.dark
                ? CupertinoColors.black
                : CupertinoColors.white,
            child: Center(
              child: InteractiveViewer(
                boundaryMargin: const EdgeInsets.all(100.0),
                minScale: 0.1,
                maxScale: 4.0,
                child: Image.file(
                  File(imagePath),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: CupertinoColors.systemGrey6,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              CupertinoIcons.exclamationmark_triangle,
                              size: 48,
                              color: CupertinoColors.systemRed,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l10n.unableToLoadImage,
                              style: TextStyle(
                                fontSize: 16,
                                color: CupertinoTheme.of(context)
                                    .textTheme
                                    .textStyle
                                    .color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ));
  }
}
