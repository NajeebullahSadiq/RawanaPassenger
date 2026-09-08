import 'dart:typed_data';

/// Parse WKT `POINT(lng lat)`, GeoJSON, or PostGIS EWKB hex.
final _wktPoint = RegExp(r'POINT\(([-\d.]+)\s+([-\d.]+)\)');
final _wkbHex = RegExp(r'^[0-9a-fA-F]+$');

double? _asDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

({double lat, double lng})? parseGeographyPoint(Object? value) {
  if (value == null) return null;

  if (value is Map) {
    final coords = value['coordinates'];
    if (coords is List && coords.length >= 2) {
      final lng = _asDouble(coords[0]);
      final lat = _asDouble(coords[1]);
      if (lat != null && lng != null) return (lat: lat, lng: lng);
    }
    final lat = _asDouble(value['lat'] ?? value['latitude']);
    final lng = _asDouble(value['lng'] ?? value['longitude']);
    if (lat != null && lng != null) return (lat: lat, lng: lng);
    return null;
  }

  if (value is! String || value.isEmpty) return null;

  final wkt = _wktPoint.firstMatch(value);
  if (wkt != null) {
    final lng = double.tryParse(wkt.group(1)!);
    final lat = double.tryParse(wkt.group(2)!);
    if (lat != null && lng != null) return (lat: lat, lng: lng);
  }

  if (_wkbHex.hasMatch(value) && value.length >= 42) {
    try {
      final bytes = _decodeHex(value);
      if (bytes.length < 21) return null;
      var offset = 0;
      final le = bytes[offset] == 1;
      offset += 1;
      final type = _readUint32(bytes, offset, le);
      offset += 4;
      if (type & 0x20000000 != 0) offset += 4;
      final lng = _readDouble(bytes, offset, le);
      offset += 8;
      final lat = _readDouble(bytes, offset, le);
      return (lat: lat, lng: lng);
    } catch (_) {
      return null;
    }
  }

  return null;
}

double? parseWktLat(Object? value) => parseGeographyPoint(value)?.lat;

double? parseWktLng(Object? value) => parseGeographyPoint(value)?.lng;

List<int> _decodeHex(String hex) {
  final out = <int>[];
  for (var i = 0; i < hex.length; i += 2) {
    out.add(int.parse(hex.substring(i, i + 2), radix: 16));
  }
  return out;
}

int _readUint32(List<int> bytes, int offset, bool le) {
  final b0 = bytes[offset];
  final b1 = bytes[offset + 1];
  final b2 = bytes[offset + 2];
  final b3 = bytes[offset + 3];
  if (le) return b0 | (b1 << 8) | (b2 << 16) | (b3 << 24);
  return (b0 << 24) | (b1 << 16) | (b2 << 8) | b3;
}

double _readDouble(List<int> bytes, int offset, bool le) {
  final data = ByteData(8);
  for (var i = 0; i < 8; i++) {
    data.setUint8(i, bytes[offset + (le ? i : 7 - i)]);
  }
  return data.getFloat64(0, le ? Endian.little : Endian.big);
}
