import 'dart:convert';
import 'dart:typed_data';

class SoftEtherPack {
  final Map<String, dynamic> _data = {};

  void addString(String key, String value) {
    _data[key] = {'type': 'string', 'value': value};
  }

  void addInt(String key, int value) {
    _data[key] = {'type': 'int', 'value': value};
  }

  void addBool(String key, bool value) {
    _data[key] = {'type': 'bool', 'value': value};
  }

  void addData(String key, Uint8List data) {
    _data[key] = {'type': 'data', 'value': data};
  }

  String? getString(String key) {
    final item = _data[key];
    if (item != null && item['type'] == 'string') {
      return item['value'] as String;
    }
    return null;
  }

  int? getInt(String key) {
    final item = _data[key];
    if (item != null && item['type'] == 'int') {
      return item['value'] as int;
    }
    return null;
  }

  bool? getBool(String key) {
    final item = _data[key];
    if (item != null && item['type'] == 'bool') {
      return item['value'] as bool;
    }
    return null;
  }

  Uint8List? getData(String key) {
    final item = _data[key];
    if (item != null && item['type'] == 'data') {
      return item['value'] as Uint8List;
    }
    return null;
  }

  Uint8List serialize() {
    final buffer = BytesBuilder();

    // Pack header: "PACK" signature + version
    buffer.add(utf8.encode("PACK"));
    buffer.add(_writeUint32(1)); // Version 1
    buffer.add(_writeUint32(_data.length)); // Number of items

    for (final entry in _data.entries) {
      final key = entry.key;
      final item = entry.value;
      final type = item['type'] as String;
      final value = item['value'];

      // Write key length and key
      final keyBytes = utf8.encode(key);
      buffer.add(_writeUint32(keyBytes.length));
      buffer.add(keyBytes);

      // Write type and value
      switch (type) {
        case 'string':
          buffer.add(_writeUint32(0)); // Type: string
          final valueBytes = utf8.encode(value as String);
          buffer.add(_writeUint32(valueBytes.length));
          buffer.add(valueBytes);
          break;
        case 'int':
          buffer.add(_writeUint32(1)); // Type: int
          buffer.add(_writeUint32(4)); // Size: 4 bytes
          buffer.add(_writeUint32(value as int));
          break;
        case 'bool':
          buffer.add(_writeUint32(2)); // Type: bool
          buffer.add(_writeUint32(1)); // Size: 1 byte
          buffer.add([(value as bool) ? 1 : 0]);
          break;
        case 'data':
          buffer.add(_writeUint32(3)); // Type: data
          final data = value as Uint8List;
          buffer.add(_writeUint32(data.length));
          buffer.add(data);
          break;
      }
    }

    return buffer.toBytes();
  }

  static SoftEtherPack deserialize(Uint8List data) {
    final pack = SoftEtherPack();
    int offset = 0;

    // Read header
    final signature = utf8.decode(data.sublist(offset, offset + 4));
    offset += 4;

    if (signature != "PACK") {
      throw Exception("Invalid PACK signature: $signature");
    }

    final version = _readUint32(data, offset);
    offset += 4;

    if (version != 1) {
      throw Exception("Unsupported PACK version: $version");
    }

    final itemCount = _readUint32(data, offset);
    offset += 4;

    // Read items
    for (int i = 0; i < itemCount; i++) {
      // Read key
      final keyLength = _readUint32(data, offset);
      offset += 4;
      final key = utf8.decode(data.sublist(offset, offset + keyLength));
      offset += keyLength;

      // Read type and value
      final type = _readUint32(data, offset);
      offset += 4;
      final valueLength = _readUint32(data, offset);
      offset += 4;

      switch (type) {
        case 0: // string
          final value = utf8.decode(data.sublist(offset, offset + valueLength));
          pack.addString(key, value);
          break;
        case 1: // int
          final value = _readUint32(data, offset);
          pack.addInt(key, value);
          break;
        case 2: // bool
          final value = data[offset] == 1;
          pack.addBool(key, value);
          break;
        case 3: // data
          final value = data.sublist(offset, offset + valueLength);
          pack.addData(key, Uint8List.fromList(value));
          break;
        default:
          throw Exception("Unknown PACK type: $type");
      }

      offset += valueLength;
    }

    return pack;
  }

  static Uint8List _writeUint32(int value) {
    final bytes = Uint8List(4);
    bytes[0] = (value >> 24) & 0xFF;
    bytes[1] = (value >> 16) & 0xFF;
    bytes[2] = (value >> 8) & 0xFF;
    bytes[3] = value & 0xFF;
    return bytes;
  }

  static int _readUint32(Uint8List data, int offset) {
    return (data[offset] << 24) |
           (data[offset + 1] << 16) |
           (data[offset + 2] << 8) |
           data[offset + 3];
  }
}