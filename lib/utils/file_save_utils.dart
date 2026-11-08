import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 导出文件的保存结果。
///
/// [locationType] 取值：
/// - `download`：桌面/Android 的下载目录
/// - `external`：Android 外部存储
/// - `app`：应用文档目录
/// - `saved`：iOS 系统保存面板中用户选择的位置
/// - `cancelled`：用户取消了保存
class SaveExportResult {
  const SaveExportResult({
    required this.filePath,
    required this.locationType,
  });

  final String filePath;
  final String locationType;

  bool get isCancelled => locationType == 'cancelled';
}

/// 保存导出文件。
///
/// iOS 使用系统保存面板（文件 App），让用户自行选择「我的 iPhone」或
/// iCloud Drive；其他平台保持原有行为，直接写入下载目录（不可用时逐级回退）。
Future<SaveExportResult> saveExportBytes({
  required String fileName,
  required List<int> bytes,
}) async {
  if (Platform.isIOS) {
    final uri = await FilePicker.saveFile(
      fileName: fileName,
      bytes: Uint8List.fromList(bytes),
      mimeType: _mimeTypeForFileName(fileName),
    );
    if (uri == null) {
      return const SaveExportResult(filePath: '', locationType: 'cancelled');
    }
    return SaveExportResult(
      filePath: uri.path.isNotEmpty ? uri.path : uri.toString(),
      locationType: 'saved',
    );
  }

  Directory? targetDir = await getDownloadsDirectory();
  String locationType = 'download';

  if (targetDir == null) {
    targetDir = await getExternalStorageDirectory();
    locationType = 'external';
  }

  if (targetDir == null) {
    targetDir = await getApplicationDocumentsDirectory();
    locationType = 'app';
  }

  if (!await targetDir.exists()) {
    await targetDir.create(recursive: true);
  }

  final targetFile = File('${targetDir.path}/$fileName');
  await targetFile.writeAsBytes(bytes);

  return SaveExportResult(
    filePath: targetFile.path,
    locationType: locationType,
  );
}

String _mimeTypeForFileName(String fileName) {
  switch (p.extension(fileName).toLowerCase()) {
    case '.json':
    case '.lumenflow':
      return 'application/json';
    case '.zip':
      return 'application/zip';
    case '.pdf':
      return 'application/pdf';
    case '.txt':
      return 'text/plain';
    default:
      return 'application/octet-stream';
  }
}
