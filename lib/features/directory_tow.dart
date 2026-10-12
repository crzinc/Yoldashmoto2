import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/backend.dart';
import '../core/l10n.dart';
import '../core/models.dart';
import '../core/store.dart';
import '../core/widgets.dart';

class DirectoryScreen extends ConsumerStatefulWidget {
  const DirectoryScreen({super.key});
  @override
  ConsumerState<DirectoryScreen> createState() => _DState();
}

class _DState extends ConsumerState<DirectoryScreen> {
  String? filter;
  @override
  Widget build(BuildContext context) {
    final l = ref.watch(l10nProvider);
    final mechs = [...ref.watch(mechanicsProvider)]..sort((a, b) => a.distKm.compareTo(b.distKm));
    final list = filter == null ? mechs : mechs.where((m) => m.services.contains(filter)).toList();
    return YmScaffold(
      title: l.t('mechanics'),
      actions: [IconButton(icon: const Icon(Icons.add_business_outlined), onPressed: () => context.push('/mechanic/register'), tooltip: l.t('becomeMechanic'))],
      body: Column(children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal, padding: const EdgeInsets.all(12),
          child: Row(children: [
            for (final p in L10n.problems)
              Padding(padding: const EdgeInsets.only(right: 8),
                child: YmChip(label: p.$2[l.lang] ?? p.$2['en']!, selected: filter == p.$1, onTap: () => setState(() => filter = filter == p.$1 ? null : p.$1))),
          ]),
        ),
        Expanded(
          child: ListView(children: [
            for (final m in list)
              YmCard(
                onTap: () => context.push('/garage-page/${m.id}'),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text('${m.verified ? '✓ ' : ''}${m.name}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
                    Stars(m.rating),
                  ]),
                  Text('${m.distKm} km · ${m.area ?? ''} · ${m.online ? l.t('online') : l.t('offline')} · ${m.availableNow ? l.t('availableNow') : 'Busy'}'),
                  Text(m.services.join(' · ')),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: FilledButton(style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)), onPressed: () => launchUrl(Uri.parse('tel:${m.phone}')), child: Text(l.t('call')))),
                    const SizedBox(width: 8),
                    Expanded(child: OutlinedButton(onPressed: () {}, child: Text(l.t('navigate')))),
                  ]),
                ]),
              ),
          ]),
        ),
      ]),
    );
  }
}

class GaragePageScreen extends ConsumerWidget {
  final String id;
  const GaragePageScreen({super.key, required this.id});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = ref.watch(l10nProvider);
    final mechs = ref.watch(mechanicsProvider);
    final m = mechs.firstWhere((e) => e.id == id, orElse: () => mechs.first);
    return YmScaffold(
      title: m.name,
      body: ListView(padding: const EdgeInsets.all(16), children: [
        YmCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Expanded(child: Text(m.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900))), Stars(m.rating)]),
          Text('${m.area} · 09:00–21:00 · ${l.t('availableNow')}'),
          Text('Services: ${m.services.join(', ')}'),
          const Text('Reviews: ★★★★★ “Fast, fair price” (only recorded calls/orders can rate)'),
        ])),
        FilledButton(onPressed: () => launchUrl(Uri.parse('tel:${m.phone}')), child: Text(l.t('call'))),
      ]),
    );
  }
}

class TowScreen extends ConsumerStatefulWidget {
  const TowScreen({super.key});
  @override
  ConsumerState<TowScreen> createState() => _TowState();
}

class _TowState extends ConsumerState<TowScreen> {
  @override
  Widget build(BuildContext context) {
    final l = ref.watch(l10nProvider);
    final tows = [...ref.watch(towProvider)]..sort((a, b) => a.distKm.compareTo(b.distKm));
    return YmScaffold(
      title: l.t('tow'),
      actions: [IconButton(icon: const Icon(Icons.add), onPressed: () => context.push('/tow/edit'), tooltip: l.t('becomeTow'))],
      body: ListView(padding: const EdgeInsets.symmetric(vertical: 8), children: [
        for (final t in tows)
          YmCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Expanded(child: Text('${t.verified ? '✓ ' : ''}${t.name}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800))), Stars(t.rating)]),
              Text('${t.distKm} km · ${t.availableNow ? l.t('availableNow') : 'Busy'}'),
              for (final p in t.priceLines) Text('• $p'),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: FilledButton(style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)), onPressed: () => launchUrl(Uri.parse('tel:${t.phone}')), child: Text(l.t('call')))),
                const SizedBox(width: 8),
                Expanded(child: OutlinedButton(onPressed: () => context.push('/tow/edit'), child: Text(l.t('save')))),
              ]),
            ]),
          ),
        Padding(padding: const EdgeInsets.all(16), child: Text(l.t('tow') + ': paid directly, outside the app.', textAlign: TextAlign.center)),
      ]),
    );
  }
}

class TowEditScreen extends ConsumerStatefulWidget {
  const TowEditScreen({super.key});
  @override
  ConsumerState<TowEditScreen> createState() => _TEState();
}

class _TEState extends ConsumerState<TowEditScreen> {
  final name = TextEditingController(text: 'My MotoEvak');
  final truck = TextEditingController(text: 'moto platform');
  final area = TextEditingController(text: 'Baku');
  final prices = TextEditingController(text: 'City: 25–35 ₼\nNight: 40 ₼');
  final hours = TextEditingController(text: '00:00–24:00');
  bool avail = true;
  @override
  Widget build(BuildContext context) {
    final l = ref.watch(l10nProvider);
    return YmScaffold(
      title: l.t('becomeTow'),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        YmField(hint: 'name / company', ctrl: name),
        const SizedBox(height: 8),
        YmField(hint: 'truck type', ctrl: truck),
        const SizedBox(height: 8),
        YmField(hint: 'area', ctrl: area),
        const SizedBox(height: 8),
        YmField(hint: l.t('priceLines'), ctrl: prices, maxLines: 3),
        const SizedBox(height: 8),
        YmField(hint: l.t('workingHours'), ctrl: hours),
        SwitchListTile(value: avail, onChanged: (v) => setState(() => avail = v), title: Text(l.t('availableNow'))),
        FilledButton(
          onPressed: () {
            ref.read(towProvider.notifier).state = [
              ...ref.read(towProvider),
              TowInfo(id: nid(), name: name.text, distKm: 0.5, rating: 5.0, priceLines: prices.text.split('\n'), availableNow: avail, verified: false, phone: '+994 50 000 00 00', area: area.text),
            ];
            context.pop();
          },
          child: Text(l.t('save')),
        ),
        const Text('Verification by admin (truck docs) before going public.', textAlign: TextAlign.center),
      ]),
    );
  }
}
