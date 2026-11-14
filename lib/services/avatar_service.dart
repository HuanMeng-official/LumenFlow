import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

class AvatarService {
  const AvatarService._();

  static const List<int> _pngSignature = [
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
  ];

  /// 校验并归一化 PNG 头像。
  ///
  /// 最长边不超过 [maxDimension]；输出始终为 PNG。如果编码结果超过
  /// [maxBytes]，依次按 1024 / 768 / 512 降采样；仍超限则拒绝。
  static Future<Uint8List> normalizePng(
    Uint8List bytes, {
    int maxDimension = 1024,
    int maxBytes = 2 * 1024 * 1024,
  }) async {
    if (maxDimension <= 0) {
      throw ArgumentError.value(maxDimension, 'maxDimension');
    }
    if (maxBytes <= 0) {
      throw ArgumentError.value(maxBytes, 'maxBytes');
    }
    _validatePngSignature(bytes);
    _validatePngDimensions(bytes);

    final sourceSize = await _readSize(bytes);
    final caps = <int>{
      maxDimension,
      if (maxDimension >= 1024) 1024,
      if (maxDimension >= 768) 768,
      if (maxDimension >= 512) 512,
    }.toList()
      ..sort((a, b) => b.compareTo(a));

    Uint8List? encoded;
    for (final cap in caps) {
      final longest = math.max(sourceSize.$1, sourceSize.$2);
      final scale = longest > cap ? cap / longest : 1.0;
      final width = math.max(1, (sourceSize.$1 * scale).round());
      final height = math.max(1, (sourceSize.$2 * scale).round());
      encoded = await _encodePng(bytes, width, height);
      if (encoded.length <= maxBytes) {
        return encoded;
      }
    }

    throw const FormatException('PNG avatar exceeds the size limit');
  }

  static void _validatePngSignature(Uint8List bytes) {
    if (bytes.length < _pngSignature.length) {
      throw const FormatException('Not a PNG image');
    }
    for (var index = 0; index < _pngSignature.length; index++) {
      if (bytes[index] != _pngSignature[index]) {
        throw const FormatException('Not a PNG image');
      }
    }
  }

  static void _validatePngDimensions(Uint8List bytes) {
    if (bytes.length < 24) {
      throw const FormatException('Invalid PNG image');
    }
    final header = ByteData.sublistView(bytes);
    final width = header.getUint32(16);
    final height = header.getUint32(20);
    if (width == 0 ||
        height == 0 ||
        width > 4096 ||
        height > 4096) {
      throw const FormatException('PNG dimensions are too large');
    }
  }

  static Future<(int, int)> _readSize(Uint8List bytes) async {
    ui.Codec? codec;
    ui.Image? image;
    try {
      codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      image = frame.image;
      return (image.width, image.height);
    } catch (_) {
      throw const FormatException('Invalid PNG image');
    } finally {
      image?.dispose();
      codec?.dispose();
    }
  }

  static Future<Uint8List> _encodePng(
    Uint8List bytes,
    int width,
    int height,
  ) async {
    ui.Codec? codec;
    ui.Image? image;
    try {
      codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: width,
        targetHeight: height,
      );
      final frame = await codec.getNextFrame();
      image = frame.image;
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) {
        throw const FormatException('Failed to encode PNG avatar');
      }
      return data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
    } catch (error) {
      if (error is FormatException) rethrow;
      throw const FormatException('Invalid PNG image');
    } finally {
      image?.dispose();
      codec?.dispose();
    }
  }
}
