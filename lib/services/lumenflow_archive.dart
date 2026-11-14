import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';

const String _manifestPath = 'manifest.json';
const int _maxManifestBytes = 1 * 1024 * 1024;
const int _maxArchiveEntries = 5000;
const int _maxFileBytes = 256 * 1024 * 1024;
const int _maxTotalBytes = 512 * 1024 * 1024;

final RegExp _sha256Pattern = RegExp(r'^[a-f0-9]{64}$');

enum LumenflowArchiveType { settings, conversation, characterCard }

String _typeToJson(LumenflowArchiveType type) {
  switch (type) {
    case LumenflowArchiveType.settings:
      return 'settings';
    case LumenflowArchiveType.conversation:
      return 'conversation';
    case LumenflowArchiveType.characterCard:
      return 'character_card';
  }
}

LumenflowArchiveType _typeFromJson(String value) {
  switch (value) {
    case 'settings':
      return LumenflowArchiveType.settings;
    case 'conversation':
      return LumenflowArchiveType.conversation;
    case 'character_card':
      return LumenflowArchiveType.characterCard;
    default:
      throw FormatException('Unsupported lumenflow type: $value');
  }
}

class LumenflowArchiveFile {
  const LumenflowArchiveFile({
    required this.path,
    required this.role,
    required this.bytes,
  });

  final String path;
  final String role;
  final List<int> bytes;
}

class LumenflowManifestEntry {
  const LumenflowManifestEntry({
    required this.path,
    required this.role,
    required this.size,
    required this.sha256,
  });

  final String path;
  final String role;
  final int size;
  final String sha256;

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'role': role,
      'size': size,
      'sha256': sha256,
    };
  }
}

class LumenflowManifest {
  const LumenflowManifest({
    required this.type,
    required this.created,
    required this.appVersion,
    required this.title,
    required this.language,
    required this.files,
    this.containsSecrets = false,
    this.includesCharacter = false,
  });

  static const String format = 'lumenflow';
  static const String version = '2.0';
  static const String minReaderVersion = '2.0';

  final LumenflowArchiveType type;
  final DateTime created;
  final String appVersion;
  final String title;
  final String language;
  final bool containsSecrets;
  final bool includesCharacter;
  final List<LumenflowManifestEntry> files;

  Map<String, dynamic> toJson() {
    return {
      '_format': format,
      '_version': version,
      '_type': _typeToJson(type),
      '_created': created.toUtc().toIso8601String(),
      '_app_version': appVersion,
      '_min_reader_version': minReaderVersion,
      '_title': title,
      '_language': language,
      '_contains_secrets': containsSecrets,
      'includes_character': includesCharacter,
      'files': files.map((entry) => entry.toJson()).toList(),
    };
  }

  factory LumenflowManifest.fromJson(Map<String, dynamic> json) {
    if (json['_format'] != format) {
      throw const FormatException('Invalid lumenflow manifest format');
    }
    if (json['_version'] != version) {
      throw FormatException(
        'Unsupported lumenflow version: ${json['_version']}',
      );
    }
    if (json['_min_reader_version'] != minReaderVersion) {
      throw FormatException(
        'Unsupported minimum reader version: '
        '${json['_min_reader_version']}',
      );
    }

    final typeValue = json['_type'];
    if (typeValue is! String) {
      throw const FormatException('Missing lumenflow archive type');
    }
    final type = _typeFromJson(typeValue);

    final createdValue = json['_created'];
    if (createdValue is! String) {
      throw const FormatException('Missing lumenflow creation time');
    }
    final created = DateTime.tryParse(createdValue);
    if (created == null) {
      throw FormatException('Invalid lumenflow creation time: $createdValue');
    }

    final appVersion = json['_app_version'];
    if (appVersion is! String) {
      throw const FormatException('Missing lumenflow app version');
    }
    final title = json['_title'];
    if (title is! String) {
      throw const FormatException('Missing lumenflow title');
    }
    final language = json['_language'];
    if (language is! String) {
      throw const FormatException('Missing lumenflow language');
    }

    final containsSecrets = json['_contains_secrets'] ?? false;
    if (containsSecrets is! bool) {
      throw const FormatException('Invalid _contains_secrets');
    }
    final includesCharacter = json['includes_character'] ?? false;
    if (includesCharacter is! bool) {
      throw const FormatException('Invalid includes_character');
    }

    final filesValue = json['files'];
    if (filesValue is! List) {
      throw const FormatException('Missing lumenflow files list');
    }

    final files = <LumenflowManifestEntry>[];
    for (final item in filesValue) {
      if (item is! Map) {
        throw const FormatException('Invalid lumenflow file entry');
      }
      final path = item['path'];
      final role = item['role'];
      final size = item['size'];
      final sha = item['sha256'];
      if (path is! String ||
          role is! String ||
          size is! int ||
          size < 0 ||
          sha is! String) {
        throw const FormatException('Invalid lumenflow file entry');
      }
      files.add(
        LumenflowManifestEntry(
          path: path,
          role: role,
          size: size,
          sha256: sha,
        ),
      );
    }

    return LumenflowManifest(
      type: type,
      created: created,
      appVersion: appVersion,
      title: title,
      language: language,
      containsSecrets: containsSecrets,
      includesCharacter: includesCharacter,
      files: files,
    );
  }
}

class LumenflowArchive {
  const LumenflowArchive({required this.manifest, required this.files});

  final LumenflowManifest manifest;
  final Map<String, List<int>> files;

  static LumenflowArchive read(List<int> bytes) {
    if (bytes.length < 2 || bytes[0] != 0x50 || bytes[1] != 0x4B) {
      _throwNotArchive(bytes);
    }
    if (bytes.length > _maxTotalBytes) {
      throw const FormatException('Lumenflow archive is too large');
    }

    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (_) {
      return _throwNotArchive(bytes);
    }

    if (archive.files.length > _maxArchiveEntries) {
      throw const FormatException('Too many entries in lumenflow archive');
    }

    ArchiveFile? manifestFile;
    final archiveFiles = <String, ArchiveFile>{};
    final seenEntries = <String>{};
    var declaredTotal = 0;
    for (final file in archive.files) {
      if (!file.isFile) {
        continue;
      }
      if (file.isSymbolicLink) {
        throw const FormatException('Symlink entries are not supported');
      }
      final name = _validatePath(file.name);
      if (!seenEntries.add(name.toLowerCase())) {
        throw FormatException('Duplicate archive entry: $name');
      }

      final limit = name == _manifestPath ? _maxManifestBytes : _maxFileBytes;
      if (file.size > limit) {
        throw FormatException('File too large: $name');
      }
      declaredTotal += file.size;
      if (declaredTotal > _maxTotalBytes) {
        throw const FormatException('Lumenflow archive is too large');
      }

      if (name == _manifestPath) {
        manifestFile = file;
      } else {
        archiveFiles[name] = file;
      }
    }

    if (manifestFile == null) {
      throw const FormatException('Missing manifest.json');
    }

    final Map<String, dynamic> manifestJson;
    try {
      final manifestBytes = _decompressBounded(
        manifestFile,
        _maxManifestBytes,
      );
      if (manifestBytes.length > _maxManifestBytes ||
          manifestBytes.length != manifestFile.size) {
        throw const FormatException('Invalid manifest.json size');
      }
      final decoded = jsonDecode(
        utf8.decode(manifestBytes, allowMalformed: false),
      );
      if (decoded is! Map) {
        throw const FormatException('Invalid manifest.json');
      }
      manifestJson = decoded.cast<String, dynamic>();
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Invalid manifest.json');
    }

    final manifest = LumenflowManifest.fromJson(manifestJson);
    if (manifest.files.length + 1 > _maxArchiveEntries) {
      throw const FormatException('Too many files in lumenflow archive');
    }

    final files = <String, List<int>>{};
    final seenPaths = <String>{};
    var totalBytes = 0;
    for (final entry in manifest.files) {
      final path = _validatePath(entry.path);
      if (path != entry.path) {
        throw FormatException('Non-normalized path: ${entry.path}');
      }
      if (path.toLowerCase() == _manifestPath) {
        throw const FormatException('manifest.json cannot be a payload file');
      }
      if (!seenPaths.add(path.toLowerCase())) {
        throw FormatException('Duplicate manifest path: $path');
      }
      if (entry.size > _maxFileBytes) {
        throw FormatException('File too large: $path');
      }
      if (!_sha256Pattern.hasMatch(entry.sha256)) {
        throw FormatException('Invalid sha256 for $path');
      }
      final zipped = archiveFiles[path];
      if (zipped == null) {
        throw FormatException('Missing file: $path');
      }
      if (zipped.size != entry.size) {
        throw FormatException('Declared size mismatch for $path');
      }
      final remaining = _maxTotalBytes - totalBytes;
      if (remaining <= 0) {
        throw const FormatException('Lumenflow archive is too large');
      }
      final limit = remaining < _maxFileBytes ? remaining : _maxFileBytes;
      final content = _decompressBounded(zipped, limit);
      if (content.length != entry.size) {
        throw FormatException('Size mismatch for $path');
      }
      if (sha256.convert(content).toString() != entry.sha256) {
        throw FormatException('sha256 mismatch for $path');
      }
      totalBytes += content.length;
      if (totalBytes > _maxTotalBytes) {
        throw const FormatException('Lumenflow archive is too large');
      }
      files[path] = content;
    }

    return LumenflowArchive(manifest: manifest, files: files);
  }

  static List<int> write(
    LumenflowManifest manifest,
    List<LumenflowArchiveFile> files,
  ) {
    if (files.length + 1 > _maxArchiveEntries) {
      throw const FormatException('Too many entries in lumenflow archive');
    }

    final entries = <LumenflowManifestEntry>[];
    final contents = <String, List<int>>{};
    final seenPaths = <String>{};
    var totalBytes = 0;

    for (final file in files) {
      final path = _validatePath(file.path);
      if (path != file.path) {
        throw FormatException('Non-normalized path: ${file.path}');
      }
      if (path.toLowerCase() == _manifestPath) {
        throw const FormatException('manifest.json cannot be a payload file');
      }
      if (!seenPaths.add(path.toLowerCase())) {
        throw FormatException('Duplicate archive path: $path');
      }
      final content = List<int>.from(file.bytes);
      if (content.length > _maxFileBytes) {
        throw FormatException('File too large: $path');
      }
      totalBytes += content.length;
      if (totalBytes > _maxTotalBytes) {
        throw const FormatException('Lumenflow archive is too large');
      }
      entries.add(
        LumenflowManifestEntry(
          path: path,
          role: file.role,
          size: content.length,
          sha256: sha256.convert(content).toString(),
        ),
      );
      contents[path] = content;
    }

    final effectiveManifest = LumenflowManifest(
      type: manifest.type,
      created: manifest.created,
      appVersion: manifest.appVersion,
      title: manifest.title,
      language: manifest.language,
      containsSecrets: manifest.containsSecrets,
      includesCharacter: manifest.includesCharacter,
      files: entries,
    );

    final manifestBytes = utf8.encode(jsonEncode(effectiveManifest.toJson()));
    final archive = Archive()
      ..addFile(
        ArchiveFile(_manifestPath, manifestBytes.length, manifestBytes),
      );
    for (final entry in entries) {
      final content = contents[entry.path]!;
      archive.addFile(ArchiveFile(entry.path, content.length, content));
    }

    return ZipEncoder().encode(archive);
  }

  static List<int> _decompressBounded(ArchiveFile file, int limit) {
    final raw = file.rawContent;
    if (raw == null) {
      return List<int>.from(file.content);
    }
    final output = _BoundedOutputStream(limit);
    try {
      raw.decompress(output);
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Invalid compressed file');
    }
    return output.getBytes();
  }

  static Never _throwNotArchive(List<int> bytes) {
    var legacy = false;
    try {
      final decoded = jsonDecode(utf8.decode(bytes, allowMalformed: true));
      legacy = decoded is Map && decoded['_format'] == LumenflowManifest.format;
    } catch (_) {
      // Not JSON: fall through to the generic format error.
    }
    throw FormatException(
      legacy
          ? 'Legacy lumenflow v1 is not supported'
          : 'Not a lumenflow v2 ZIP archive',
    );
  }

  static String _validatePath(String path) {
    if (path.isEmpty) {
      throw const FormatException('Empty path in lumenflow archive');
    }
    if (path.contains('\\')) {
      throw FormatException('Backslash in lumenflow path: $path');
    }
    if (path.startsWith('/') || path.contains(':')) {
      throw FormatException('Absolute path in lumenflow archive: $path');
    }
    final segments = path.split('/');
    for (final segment in segments) {
      if (segment.isEmpty || segment == '.' || segment == '..') {
        throw FormatException('Unsafe path in lumenflow archive: $path');
      }
    }
    return segments.join('/');
  }
}

class _BoundedOutputStream extends OutputStream {
  _BoundedOutputStream(this.limit)
    : _delegate = OutputMemoryStream(),
      super(byteOrder: ByteOrder.littleEndian);

  final int limit;
  final OutputMemoryStream _delegate;

  void _check(int additional) {
    if (additional < 0 || _delegate.length + additional > limit) {
      throw const FormatException('Lumenflow archive entry is too large');
    }
  }

  @override
  int get length => _delegate.length;

  @override
  void writeByte(int value) {
    _check(1);
    _delegate.writeByte(value);
  }

  @override
  void writeBytes(List<int> bytes, {int? length}) {
    _check(length ?? bytes.length);
    _delegate.writeBytes(bytes, length: length);
  }

  @override
  void writeRange(Uint8List bytes, int start, int end) {
    _check(end - start);
    _delegate.writeRange(bytes, start, end);
  }

  @override
  void writeStream(InputStream stream) {
    _check(stream.length);
    _delegate.writeStream(stream);
  }

  @override
  Uint8List subset(int start, [int? end]) => _delegate.subset(start, end);

  @override
  void reserve(int total) {
    if (total > limit) {
      throw const FormatException('Lumenflow archive entry is too large');
    }
    _delegate.reserve(total);
  }

  @override
  void clear() => _delegate.clear();

  @override
  void flush() => _delegate.flush();

  @override
  bool get isOpen => _delegate.isOpen;

  @override
  void open() => _delegate.open();

  @override
  void closeSync() => _delegate.closeSync();

  @override
  Future<void> close() => _delegate.close();

  @override
  Uint8List getBytes() => _delegate.getBytes();
}
