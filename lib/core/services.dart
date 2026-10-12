import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'store.dart';

/// Crash detection per README §5B: speed >15 km/h in last 10s + impact >3.5g.
/// Thresholds come from admin/app_settings (Supabase), defaults below.
class CrashService {
  final Ref ref;
  StreamSubscription? _sub;
  final List<(DateTime, double)> _speeds = []; // (at, km/h)
  CrashService(this.ref);

  void start() {
    if (_sub != null) return;
    // speed sampling
    Timer.periodic(const Duration(seconds: 2), (t) async {
      try {
        final p = await Geolocator.getCurrentPosition();
        _speeds.add((DateTime.now(), (p.speed) * 3.6));
        _speeds.removeWhere((e) => DateTime.now().difference(e.$1).inSeconds > 10);
      } catch (_) {}
    });
    _sub = userAccelerometerEventStream().listen((e) {
      final g = sqrt(e.x * e.x + e.y * e.y + e.z * e.z) / 9.81;
      final riding = _speeds.any((s) => s.$2 > 15);
      if (g > 3.5 && riding && ref.read(settingsProvider).crashOn) {
        ref.read(crashAlertProvider.notifier).state = true;
      }
    });
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
  }
}

final crashServiceProvider = Provider<CrashService>((ref) {
  final s = CrashService(ref);
  ref.onDispose(s.stop);
  return s;
});

/// Broadcast matching (MVP §12): first to accept wins (atomic rpc claim_order).
/// No-mechanic → widen once → directory + SOS fallback (UI flow).
class MatchingService {
  static const searchTimeoutSec = 60;
  static const widenKm = 10;

  /// Pure helper (unit-tested): eligible mechanics filter.
  static List<Map<String, dynamic>> eligible(
    List<Map<String, dynamic>> all, {
    required double radiusKm,
    required String problem,
  }) {
    return all.where((m) {
      if (m['online'] != true) return false;
      if (m['blocked'] == true) return false;
      if ((m['distKm'] as num) > radiusKm) return false;
      final sv = (m['services'] as List).cast<String>();
      return sv.contains(problem);
    }).toList();
  }
}

Future<Position?> currentPos() async {
  var p = await Geolocator.checkPermission();
  if (p == LocationPermission.denied) {
    p = await Geolocator.requestPermission();
  }
  if (p == LocationPermission.denied || p == LocationPermission.deniedForever) {
    return null;
  }
  return Geolocator.getCurrentPosition();
}

String mapsUrl(LatLng p) => 'https://www.google.com/maps/dir/?api=1&destination=${p.latitude},${p.longitude}';
String wazeUrl(LatLng p) => 'https://waze.com/ul?ll=${p.latitude},${p.longitude}&navigate=yes';
