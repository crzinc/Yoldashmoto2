import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/backend.dart';
import '../core/l10n.dart';
import '../core/store.dart';
import '../core/widgets.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});
  @override
  ConsumerState<AdminScreen> createState() => _AState();
}

class _AState extends ConsumerState<AdminScreen> {
  int tab = 0;
  String q = '';
  @override
  Widget build(BuildContext context) {
    final l = ref.watch(l10nProvider);
    final tabs = ['Queue', 'Users', 'Ref-data', 'Settings', 'Stats'];
    return YmScaffold(
      title: '${l.t('admin')} · ${l.t('verifyQueue')}',
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(decoration: InputDecoration(hintText: l.t('search'), prefixIcon: const Icon(Icons.search), filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)),
            onChanged: (v) => setState(() => q = v)),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal, padding: const EdgeInsets.all(12),
          child: Row(children: [
            for (var i = 0; i < tabs.length; i++)
              Padding(padding: const EdgeInsets.only(right: 8), child: YmChip(label: tabs[i], selected: tab == i, onTap: () => setState(() => tab = i))),
          ]),
        ),
        Expanded(child: _body()),
      ]),
    );
  }

  Widget _body() {
    switch (tab) {
      case 0:
        return _queue();
      case 2:
        return ListView(padding: const EdgeInsets.all(16), children: [
          for (final p in L10n.problems) YmCard(child: Text('${p.$1} · ${p.$2['az']} · ${p.$2['ru']} · ${p.$2['en']}')),
          const Padding(padding: EdgeInsets.all(8), child: Text('Admin adds entries in 3 languages (problem_types/service_types/review_tags). Notifications follow user lang.')),
        ]);
      case 3:
        return ListView(padding: const EdgeInsets.all(16), children: const [
          YmCard(child: Text('SOS radius limits: 2 / 5 / 10 / 25 km (app_settings)')),
          YmCard(child: Text('Crash: speed > 15 km/h (10s), impact > 3.5 g, countdown 15 s')),
          YmCard(child: Text('Matching: broadcast MVP → queue (Bolt-style) Stage 2, all in app_settings')),
        ]);
      case 4:
        return ListView(padding: const EdgeInsets.all(16), children: const [
          YmCard(child: Text('SOS/day: 34 · avg response 3.2 min · online mechs: 12 · cancellations 4%')),
          YmCard(child: Text('Live map + heatmap → Stage 2 (Realtime + PostGIS). Finance Stage 3.')),
        ]);
      default:
        return ListView(children: [
          YmCard(child: Text('Users · mechanics · tow · listings · SOS · orders — “$q” filter')),
          YmCard(
            child: Row(children: [
              const Expanded(child: Text('+994 50 000 00 00 · false SOS ×3')),
              TextButton(onPressed: () => _block(true), child: const Text('Block')),
              TextButton(onPressed: () => _block(false), child: const Text('Unblock')),
            ]),
          ),
        ]);
    }
  }

  Widget _queue() {
    return ListView(children: [
      YmCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Kamran Usta · mobile+garage · ID ✓', style: TextStyle(fontWeight: FontWeight.w800)),
          Row(children: [
            Expanded(child: FilledButton(style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)), onPressed: () => _verify('m1', true), child: const Text('Approve'))),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton(onPressed: () => _verify('m1', false), child: const Text('Reject'))),
          ]),
        ]),
      ),
      YmCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('MotoEvak Baku · truck docs ✓', style: TextStyle(fontWeight: FontWeight.w800)),
          Row(children: [
            Expanded(child: FilledButton(style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)), onPressed: () => _verify('t1', true), child: const Text('Approve'))),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton(onPressed: () => _verify('t1', false), child: const Text('Reject'))),
          ]),
        ]),
      ),
    ]);
  }

  Future<void> _verify(String id, bool ok) async {
    try {
      if (hasSupabase) {
        await Supabase.instance.client.from('mechanic_profiles').update({'status': ok ? 'approved' : 'rejected'}).eq('id', id);
        await Supabase.instance.client.from('admin_logs').insert({'action': ok ? 'approve' : 'reject', 'ref': id});
      }
    } catch (_) {}
    if (mounted) {
      ref.read(notifProvider.notifier).push('Verification', ok ? 'Approved' : 'Rejected with reason');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Approved' : 'Rejected')));
    }
  }

  Future<void> _block(bool blocked) async {
    try {
      if (hasSupabase) {
        await Supabase.instance.client.from('profiles').update({'blocked': blocked}).eq('phone', '+994 50 000 00 00');
        await Supabase.instance.client.from('admin_logs').insert({'action': blocked ? 'block' : 'unblock', 'ref': 'user'});
      }
    } catch (_) {}
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(blocked ? 'Blocked' : 'Unblocked')));
  }
}
