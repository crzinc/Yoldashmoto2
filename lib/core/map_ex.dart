import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Free, keyless routing + geocoding (OSRM / Nominatim).
/// Bolt-style: route polyline, distance, ETA.

List<LatLng> decodePolyline(String s) {
  final out = <LatLng>[];
  var i = 0, lat = 0, lng = 0;
  while (i < s.length) {
    var b = 0, shift = 0, res = 0;
    do {
      b = s.codeUnitAt(i++) - 63;
      res |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    final dlat = (res & 1) != 0 ? ~(res >> 1) : (res >> 1);
    lat += dlat;
    shift = 0;
    res = 0;
    do {
      b = s.codeUnitAt(i++) - 63;
      res |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    final dlng = (res & 1) != 0 ? ~(res >> 1) : (res >> 1);
    lng += dlng;
    out.add(LatLng(lat / 1e5, lng / 1e5));
  }
  return out;
}

class RouteInfo {
  final List<LatLng> points;
  final double km, minutes;
  const RouteInfo(this.points, this.km, this.minutes);
}

Future<RouteInfo?> fetchRoute(LatLng a, LatLng b) async {
  try {
    final u = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/${a.longitude},${a.latitude};${b.longitude},${b.latitude}?overview=full&geometries=polyline');
    final r = await http.get(u).timeout(const Duration(seconds: 8));
    if (r.statusCode != 200) return null;
    final j = jsonDecode(r.body);
    final routes = (j['routes'] as List);
    if (routes.isEmpty) return null;
    final g = routes.first['geometry'] as String;
    final km = (routes.first['distance'] as num) / 1000;
    final min = (routes.first['duration'] as num) / 60;
    return RouteInfo(decodePolyline(g), km.toDouble(), min.toDouble());
  } catch (_) {
    return null;
  }
}

class PlaceHit {
  final String name;
  final LatLng point;
  const PlaceHit(this.name, this.point);
}

Future<List<PlaceHit>> searchPlaces(String q, LatLng near) async {
  if (q.trim().length < 3) return [];
  try {
    final u = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(q)}&format=json&limit=5&lat=${near.latitude}&lon=${near.longitude}');
    final r = await http.get(u, headers: {'User-Agent': 'YoldashMoto/1.0'}).timeout(const Duration(seconds: 8));
    if (r.statusCode != 200) return [];
    return (jsonDecode(r.body) as List).map((e) {
      final d = e['display_name'] as String;
      return PlaceHit(
        d.split(',').take(2).join(','),
        LatLng(double.parse(e['lat']), double.parse(e['lon'])),
      );
    }).toList();
  } catch (_) {
    return [];
  }
}

String etaText(double min) =>
    min < 1 ? '<1 min' : '${min.toStringAsFixed(0)} min';
