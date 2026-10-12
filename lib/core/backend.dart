import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

bool get hasSupabase {
  try {
    Supabase.instance.client;
    return true;
  } catch (_) {
    return false;
  }
}

String nid() => const Uuid().v4().substring(0, 8);

/// Unified backend: Supabase when keys provided, local mock otherwise.
/// All writes go through here so Realtime/RLS wiring is single-point.
/// Phone+password auth without SMS costs: phone maps to a synthetic
/// email (Supabase has no native phone+password). Enable Email provider
/// in dashboard; no SMS provider needed.
String phoneToEmail(String phone) {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  return '$digits@phone.yoldashmoto.app';
}

class Backend {
  static Future<void> insertSos({
    required String problemId,
    required LatLng point,
    String? comment,
    String? landmark,
    bool canMove = true,
    List<String> photos = const [],
  }) async {
    if (!hasSupabase) return;
    final c = Supabase.instance.client;
    await c.from('sos_events').insert({
      'sender': c.auth.currentUser?.id,
      'problem_id': problemId,
      'comment': comment,
      'landmark': landmark,
      'can_move': canMove,
      'geom': 'SRID=4326;POINT(${point.longitude} ${point.latitude})',
      'status': 'active',
    });
  }

  static Future<void> claimOrderRpc(String orderId, String mechId) async {
    if (!hasSupabase) return;
    await Supabase.instance.client.rpc('claim_order', params: {'o': orderId, 'm': mechId});
  }

  static Future<String?> uploadPhoto(String bucket, String path, List<int> bytes) async {
    if (!hasSupabase) return null;
    final c = Supabase.instance.client;
    await c.storage.from(bucket).uploadBinary(path, Uint8List.fromList(bytes));
    return c.storage.from(bucket).getPublicUrl(path);
  }

  static Future<void> signUp(String phone, String password) async {
    if (!hasSupabase) return;
    await Supabase.instance.client.auth.signUp(
      email: phoneToEmail(phone),
      password: password,
      data: {'phone': phone},
    );
  }

  static Future<void> signIn(String phone, String password) async {
    if (!hasSupabase) return;
    await Supabase.instance.client.auth.signInWithPassword(
      email: phoneToEmail(phone),
      password: password,
    );
  }

  static Future<void> signOut() async {
    if (!hasSupabase) return;
    await Supabase.instance.client.auth.signOut();
  }
}

// ---------- In-app notifications (Supabase-ready, local fallback) ----------
class AppNotif {
  final String id, title, body;
  final DateTime at;
  const AppNotif(this.id, this.title, this.body, this.at);
}

class NotifN extends StateNotifier<List<AppNotif>> {
  NotifN() : super([]);
  void push(String title, String body) =>
      state = [AppNotif(nid(), title, body, DateTime.now()), ...state];
}

final notifProvider = StateNotifierProvider<NotifN, List<AppNotif>>((_) => NotifN());

// ---------- Emergency contacts + offline queue ----------
final emergencyContactsProvider = StateProvider<List<String>>((_) => []);
final offlineQueueProvider = StateProvider<List<String>>((_) => []);
final favoritesProvider = StateProvider<Set<String>>((_) => {});
final myListingsProvider = StateProvider<List<String>>((_) => []);
