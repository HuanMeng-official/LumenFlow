import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../models/preset_import_result.dart';
import '../models/prompt_preset.dart';
import '../screens/preset_edit_screen.dart';
import '../utils/file_save_utils.dart';
import '../utils/import_file_picker.dart';
import '../utils/lumenflow_error_messages.dart';
import 'http_server_service.dart';
import 'preset_repository.dart';
import 'prompt_service.dart';

/// 预设浏览/管理/桌面工作室共用的 UI 操作集合（导入、编辑、复制、导出、删除与本地生成器启动）。
class PresetUiActions {
  PresetUiActions._();

  static final PromptService _promptService = PromptService();
  static final PresetRepository _repository = PresetRepository.instance;
  static final HttpServerService _httpServerService = HttpServerService();

  static Future<void> showMessage(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context)!;
    await showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: Text(l10n.ok),
            onPressed: () => Navigator.pop(dialogContext),
          ),
        ],
      ),
    );
  }

  static String _validationErrorText(
    PresetValidationError error,
    AppLocalizations l10n,
  ) {
    return switch (error) {
      PresetValidationError.emptyFile => l10n.presetImportErrorEmpty,
      PresetValidationError.fileTooLarge => l10n.presetImportErrorTooLarge,
      PresetValidationError.invalidUtf8 => l10n.presetImportErrorInvalidUtf8,
      PresetValidationError.invalidXml => l10n.presetImportErrorInvalidXml,
      PresetValidationError.invalidRoot => l10n.presetImportErrorInvalidRoot,
    };
  }

  static Future<void> showValidationErrors(
    BuildContext context,
    PresetValidationResult validation,
  ) async {
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context)!;
    await showMessage(
      context,
      title: l10n.presetImportErrorTitle,
      message: validation.errors
          .map((error) => _validationErrorText(error, l10n))
          .join('\n'),
    );
  }

  static Future<PromptPreset?> pickAndImportPreset(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final result = await pickImportFile(
        allowedExtensions: const ['xml', 'txt', 'lumenflow'],
      );
      if (result == null || !context.mounted) return null;

      final filePath = result.path;
      if (filePath == null) {
        await showMessage(
          context,
          title: l10n.error,
          message: l10n.filePathError,
        );
        return null;
      }

      if (!hasAllowedImportExtension(
        filePath,
        const ['xml', 'txt', 'lumenflow'],
      )) {
        await showMessage(
          context,
          title: l10n.error,
          message: l10n.unsupportedFileType,
        );
        return null;
      }

      final sourceFile = File(filePath);
      final lowerPath = filePath.toLowerCase();
      final isLumenflow = lowerPath.endsWith('.lumenflow');
      final isText = lowerPath.endsWith('.txt');

      Uint8List? characterArchiveBytes;
      CharacterCardArchivePreview? archivePreview;
      late final PresetValidationResult validation;

      if (isLumenflow) {
        characterArchiveBytes = await sourceFile.readAsBytes();
        try {
          archivePreview = await _promptService.inspectCharacterCardArchive(
            characterArchiveBytes,
          );
          validation = archivePreview.validation;
        } on PresetValidationException catch (error) {
          if (context.mounted) {
            await showValidationErrors(context, error.validation);
          }
          return null;
        } catch (error) {
          if (context.mounted) {
            await showMessage(
              context,
              title: l10n.error,
              message: l10n.importFailedError(
                lumenflowErrorMessage(error, l10n),
              ),
            );
          }
          return null;
        }
      } else {
        validation = isText
            ? await _promptService.validateTextFile(sourceFile)
            : await _promptService.validatePresetFile(sourceFile);
        if (!validation.isValid) {
          if (context.mounted) {
            await showValidationErrors(context, validation);
          }
          return null;
        }
      }

      if (!context.mounted) return null;
      return await Navigator.of(
        context,
        rootNavigator: true,
      ).push<PromptPreset?>(
        CupertinoPageRoute(
          builder: (_) => PresetImportScreen(
            sourceFile: sourceFile,
            validation: validation,
            isText: isText,
            characterArchiveBytes: characterArchiveBytes,
            archivePreview: archivePreview,
            onValidationError: (v) => showValidationErrors(context, v),
          ),
        ),
      );
    } catch (error) {
      if (context.mounted) {
        await showMessage(
          context,
          title: l10n.error,
          message: l10n.importFailedError(lumenflowErrorMessage(error, l10n)),
        );
      }
      return null;
    }
  }

  static Future<bool> editPreset(
    BuildContext context,
    PromptPreset preset,
  ) async {
    final saved = await Navigator.of(context, rootNavigator: true).push<bool>(
      CupertinoPageRoute(builder: (_) => PresetEditScreen(preset: preset)),
    );
    return saved == true;
  }

  static Future<PromptPreset?> duplicatePreset(
    BuildContext context,
    PromptPreset preset,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      return await _repository.duplicatePreset(
        preset,
        name: '${preset.name}${l10n.presetDuplicateSuffix}',
      );
    } catch (error) {
      if (context.mounted) {
        await showMessage(
          context,
          title: l10n.error,
          message: l10n.importFailedError(error.toString()),
        );
      }
      return null;
    }
  }

  static Future<void> exportPreset(
    BuildContext context,
    PromptPreset preset,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final safeName = preset.name
        .replaceAll(RegExp(r'[^\w一-鿿-]'), '')
        .replaceAll(RegExp(r'\s+'), '_');

    try {
      final isText =
          preset.promptFile?.toLowerCase().endsWith('.txt') ??
          !preset.systemPrompt.trimLeft().startsWith('<system_instruction');
      if (!isText) {
        final bytes = await _promptService.exportCharacterCardArchive(preset);
        final fileName = '${safeName.isEmpty ? preset.id : safeName}.lumenflow';
        final result = await saveExportBytes(fileName: fileName, bytes: bytes);
        if (result.isCancelled) return;
        if (context.mounted) {
          await showMessage(
            context,
            title: l10n.presetExportSuccess,
            message: result.filePath,
          );
        }
        return;
      }

      final content = preset.systemPrompt;
      if (content.trim().isEmpty) {
        if (context.mounted) {
          await showMessage(
            context,
            title: l10n.error,
            message: l10n.presetExportFailed,
          );
        }
        return;
      }
      final fileName =
          '${safeName.isEmpty ? preset.id : safeName}_${DateTime.now().millisecondsSinceEpoch}.txt';
      final result = await saveExportBytes(
        fileName: fileName,
        bytes: utf8.encode(content),
      );
      if (result.isCancelled) return;
      if (context.mounted) {
        await showMessage(
          context,
          title: l10n.presetExportSuccess,
          message: result.filePath,
        );
      }
    } catch (error) {
      if (context.mounted) {
        await showMessage(
          context,
          title: l10n.error,
          message: l10n.importFailedError(error.toString()),
        );
      }
    }
  }

  static Future<bool> confirmAndDeletePreset(
    BuildContext context,
    PromptPreset preset,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(l10n.deletePresetDialogTitle),
        content: Text(l10n.deletePresetConfirm(preset.name)),
        actions: [
          CupertinoDialogAction(
            child: Text(l10n.cancel),
            onPressed: () => Navigator.pop(dialogContext, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: Text(l10n.delete),
            onPressed: () => Navigator.pop(dialogContext, true),
          ),
        ],
      ),
    );
    if (confirmed != true) return false;
    try {
      await _repository.deletePreset(preset.id);
      return true;
    } catch (error) {
      if (context.mounted) {
        await showMessage(
          context,
          title: l10n.error,
          message: l10n.deleteFailedError(error.toString()),
        );
      }
      return false;
    }
  }

  static Future<void> toggleHttpServer(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await _httpServerService.toggle();
    } catch (error) {
      if (context.mounted) {
        await showMessage(
          context,
          title: l10n.error,
          message: l10n.httpServerOperationFailed(error.toString()),
        );
      }
    }
  }

  static Future<void> launchRoleCardGenerator(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    if (!_httpServerService.isRunning) {
      final confirmed = await showCupertinoDialog<bool>(
        context: context,
        builder: (dialogContext) => CupertinoAlertDialog(
          title: Text(l10n.httpServerNotRunningTitle),
          content: Text(l10n.httpServerNotRunningMessage),
          actions: [
            CupertinoDialogAction(
              child: Text(l10n.cancel),
              onPressed: () => Navigator.pop(dialogContext, false),
            ),
            CupertinoDialogAction(
              child: Text(l10n.startServerButton),
              onPressed: () => Navigator.pop(dialogContext, true),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      if (!context.mounted) return;
      await toggleHttpServer(context);
      await Future.delayed(const Duration(milliseconds: 300));
    }

    final serverUrl = _httpServerService.serverUrl;
    if (serverUrl == null) {
      if (context.mounted) {
        await showMessage(
          context,
          title: l10n.error,
          message: l10n.httpServerOperationFailed('server not running'),
        );
      }
      return;
    }

    try {
      final launched = await launchUrl(Uri.parse('$serverUrl/'));
      if (!launched) {
        throw Exception('Could not launch $serverUrl');
      }
    } catch (error) {
      if (context.mounted) {
        await showMessage(
          context,
          title: l10n.error,
          message: l10n.openLinkFailed(error.toString()),
        );
      }
    }
  }
}
