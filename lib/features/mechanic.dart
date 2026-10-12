import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/backend.dart';
import '../core/l10n.dart';
import '../core/models.dart';
import '../core/notify.dart';
import '../core/photos.dart';
import '../core/store.dart';
import '../core/widgets.dart';

class CallMechanicScreen extends ConsumerStatefulWidget {
  const CallMechanicScreen({super.key});
  @override
  ConsumerState<CallMechanicScreen> createState() => _CallState();
}

class _CallState extends ConsumerState<CallMechanicScreen> {
  String problem = 'engine';
  bool searching = false;
  bool noMech = false;
  int sec = 60;
  Timer? t;
  @override
  void dispose() { t?.cancel(); super.dispose(); }

  void _startSearch() {
    setState(() { searching = true; noMech = false; sec = 60; });
    t = Timer.periodic(const Duration(seconds: 1), (x) async {
      if (sec <= 1) {
        x.cancel();
        // widen once → still nobody → directory/SOS fallback (§12)
        setState(() { searching = false; noMech = true; });
        await loudPush(ref, 'No mechanic', 'Widened once — try directory or SOS');
      } else {
        setState(() => sec--);
        // demo: match after 4s (broadcast, first accept wins)
        if (sec == 56) {
          x.cancel();
          final m = ref.read(mechanicsProvider).firstWhere((e) => e.online, orElse: () => ref.read(mechanicsProvider).first);
          await Backend.claimOrderRpc(nid(), m.id);
          ref.read(myOrderProvider.notifier).state = MechOrder(id: nid(), problemId: problem, status: OrderStatus.accepted, createdAt: DateTime.now(), mechanic: m);
          await loudPush(ref, 'Mechanic accepted', m.name);
          if (mounted) context.go('/call/track');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = ref.watch(l10nProvider);
    final bikes = ref.watch(myBikesProvider);
    return YmScaffold(
      title: l.t('callMechanic'),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Wrap(spacing: 8, children: [
          for (final p in L10n.problems)
            YmChip(label: p.$2[l.lang] ?? p.$2['en']!, selected: problem == p.$1, onTap: () => setState(() => problem = p.$1)),
        ]),
        const SizedBox(height: 12),
        YmCard(child: Text('${bikes.isEmpty ? '—' : bikes.first.title} · ~15 ₼ call-out (cash, §15)', style: const TextStyle(fontWeight: FontWeight.w700))),
        if (searching)
          YmCard(child: Text('Searching… $sec s · broadcast to online mechanics')),
        if (noMech)
          YmCard(
            child: Column(children: [
              Text(l.t('noOneNearby')),
              Row(children: [
                Expanded(child: OutlinedButton(onPressed: () => context.go('/mechanics'), child: Text(l.t('mechanics')))),
                const SizedBox(width: 8),
                Expanded(child: OutlinedButton(onPressed: () => context.go('/tow'), child: Text(l.t('tow')))),
              ]),
              const SizedBox(height: 8),
              FilledButton(onPressed: _startSearch, child: Text('${l.t('retry')} · ${l.t('widen')}')),
            ]),
          )
        else if (!searching)
          FilledButton(onPressed: _startSearch, child: const Text('Confirm · broadcast nearby →')),
      ]),
    );
  }
}

class OrderTrackScreen extends ConsumerStatefulWidget {
  const OrderTrackScreen({super.key});
  @override
  ConsumerState<OrderTrackScreen> createState() => _OTState();
}

class _OTState extends ConsumerState<OrderTrackScreen> {
  final stages = [OrderStatus.accepted, OrderStatus.onTheWay, OrderStatus.arrived, OrderStatus.inProgress];
  @override
  Widget build(BuildContext context) {
    final l = ref.watch(l10nProvider);
    final o = ref.watch(myOrderProvider);
    if (o == null) return YmScaffold(title: 'Order', body: YmEmpty(l.t('noOneNearby')));
    final idx = stages.indexOf(o.status);
    return YmScaffold(
      title: '${l.problemName(o.problemId)} · ${o.status.name}',
      body: ListView(padding: const EdgeInsets.all(16), children: [
        YmCard(
            child: Row(children: [
          const CircleAvatar(child: Icon(Icons.build)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(o.mechanic?.name ?? '', style: const TextStyle(fontWeight: FontWeight.w800)),
            Stars(o.mechanic?.rating ?? 5),
            Text('${o.mechanic?.area ?? ''} · ETA ~8 min · live GPS (Realtime)'),
          ])),
          IconButton(onPressed: () => launchUrl(Uri.parse('tel:${o.mechanic?.phone ?? '+994501112233'}')), icon: const Icon(Icons.call)),
        ])),
        YmCard(
          child: Column(children: [
            for (var i = 0; i < stages.length; i++)
              ListTile(
                dense: true,
                leading: Icon(i <= idx ? Icons.check_circle : Icons.circle_outlined, color: i <= idx ? Colors.green : null),
                title: Text(stages[i].name),
                onTap: i == idx + 1 ? () {
                  ref.read(myOrderProvider.notifier).state = MechOrder(id: o.id, problemId: o.problemId, status: stages[i], createdAt: o.createdAt, mechanic: o.mechanic, priceAzn: o.priceAzn);
                } : null,
              ),
          ]),
        ),
        YmCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${l.t('receipt')}: call-out 10 ₼ + labor 15 ₼ = ${o.priceAzn + 10} ₼ (cash)'),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () async {
                final urls = await pickAndUpload('sos-photos', max: 1);
                await loudPush(ref, 'Report', 'Problem reported → admin ${urls.length} photo(s)');
              }, child: Text(l.t('report')))),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton(onPressed: () => context.go('/tow'), child: Text(l.t('tow')))),
            ]),
          ]),
        ),
        FilledButton(
            onPressed: () async {
              await loudPush(ref, 'Order', 'Completed — please rate');
              ref.read(myOrderProvider.notifier).state = null;
              if (context.mounted) context.go('/history');
            },
            child: Text(l.t('problemSolved'))),
        TextButton(
            onPressed: () async {
              await loudPush(ref, 'Order', 'Cancelled with reason → re-match offered');
              ref.read(myOrderProvider.notifier).state = null;
              if (context.mounted) context.go('/map');
            },
            child: Text(l.t('cancel'))),
      ]),
    );
  }
}

class MechanicInboxScreen extends ConsumerStatefulWidget {
  const MechanicInboxScreen({super.key});
  @override
  ConsumerState<MechanicInboxScreen> createState() => _MIState();
}

class _MIState extends ConsumerState<MechanicInboxScreen> {
  double maxRadius = 10;
  final Set<String> accepted = {'engine', 'brake', 'chain'};
  int timer = 25;
  Timer? t;
  @override
  void initState() {
    super.initState();
    t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && timer > 0) setState(() => timer--);
    });
  }

  @override
  void dispose() { t?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final l = ref.watch(l10nProvider);
    final online = ref.watch(sessionProvider).mechanicOnline;
    return YmScaffold(
      title: 'Mechanic',
      actions: [Switch(value: online, onChanged: (v) => ref.read(sessionProvider.notifier).setOnline(v))],
      body: ListView(padding: const EdgeInsets.all(16), children: [
        YmCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Max radius: ${maxRadius.toStringAsFixed(0)} km · auto-offline on inactivity'),
            Slider(value: maxRadius, min: 2, max: 25, divisions: 4, onChanged: (v) => setState(() => maxRadius = v)),
            Wrap(spacing: 8, children: [
              for (final p in L10n.problems)
                YmChip(label: p.$2[l.lang] ?? '', selected: accepted.contains(p.$1), onTap: () => setState(() => accepted.contains(p.$1) ? accepted.remove(p.$1) : accepted.add(p.$1))),
            ]),
          ]),
        ),
        if (!online)
          YmCard(child: Text(l.t('offline'))),
        if (online)
          YmCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Engine · Honda CB125F · 1.4 km · ~15 ₼ · $timer s', style: const TextStyle(fontWeight: FontWeight.w800)),
              const Text('Photo · bike · mini-map · ETA (loud, works minimized)'),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: FilledButton(onPressed: () => context.push('/call/track'), child: Text(l.t('accept')))),
                const SizedBox(width: 8),
                Expanded(child: OutlinedButton(onPressed: () => setState(() => timer = 25), style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(54)), child: Text(l.t('decline')))),
              ]),
            ]),
          ),
      ]),
    );
  }
}
