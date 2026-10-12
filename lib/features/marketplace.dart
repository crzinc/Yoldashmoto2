import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/backend.dart';
import '../core/models.dart';
import '../core/notify.dart';
import '../core/photos.dart';
import '../core/store.dart';
import '../core/widgets.dart';

class MarketScreen extends ConsumerStatefulWidget {
  const MarketScreen({super.key});
  @override
  ConsumerState<MarketScreen> createState() => _MState();
}

class _MState extends ConsumerState<MarketScreen> {
  String type = 'all';
  String sort = 'new';
  String q = '';
  bool favOnly = false;
  final search = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(l10nProvider);
    final all = ref.watch(listingsProvider);
    final favs = ref.watch(favoritesProvider);
    var list = type == 'all' ? [...all] : all.where((e) => e.type == type).toList();
    if (q.isNotEmpty) list = list.where((e) => e.title.toLowerCase().contains(q.toLowerCase())).toList();
    if (favOnly) list = list.where((e) => favs.contains(e.id)).toList();
    list.sort((a, b) {
      if (a.vip != b.vip) return b.vip ? 1 : -1;
      return switch (sort) {
        'cheap' => a.priceAzn.compareTo(b.priceAzn),
        'exp' => b.priceAzn.compareTo(a.priceAzn),
        _ => b.year.compareTo(a.year),
      };
    });
    return YmScaffold(
      title: l10n.t('market'),
      actions: [
        IconButton(icon: const Icon(Icons.favorite_outline), onPressed: () => setState(() => favOnly = !favOnly), color: favOnly ? Colors.red : null),
        IconButton(icon: const Icon(Icons.add), onPressed: () => _editListing(context, ref, null)),
      ],
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(controller: search, decoration: InputDecoration(hintText: l10n.t('search'), prefixIcon: const Icon(Icons.search), filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)),
            onChanged: (v) => setState(() => q = v)),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal, padding: const EdgeInsets.all(12),
          child: Row(children: [
            for (final t in ['all', 'moto', 'moped', 'scooter', 'electro'])
              Padding(padding: const EdgeInsets.only(right: 8), child: YmChip(label: t, selected: type == t, onTap: () => setState(() => type = t))),
            for (final s in ['new', 'cheap', 'exp'])
              Padding(padding: const EdgeInsets.only(right: 8), child: YmChip(label: s, selected: sort == s, onTap: () => setState(() => sort = s))),
          ]),
        ),
        Expanded(
          child: ListView(children: [
            for (final e in list)
              YmCard(
                onTap: () => context.push('/listing/${e.id}'),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    if (e.vip) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(8)), child: const Text('VIP', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12))),
                    if (e.inspected) ...[const SizedBox(width: 6), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(8)), child: const Text('✓ Inspected', style: TextStyle(fontSize: 12)))],
                    const Spacer(),
                    IconButton(icon: Icon(favs.contains(e.id) ? Icons.favorite : Icons.favorite_border, color: favs.contains(e.id) ? Colors.red : null),
                      onPressed: () {
                        final s = {...favs};
                        favs.contains(e.id) ? s.remove(e.id) : s.add(e.id);
                        ref.read(favoritesProvider.notifier).state = s;
                      }),
                  ]),
                  const SizedBox(height: 6),
                  Text(e.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  Text('${e.priceAzn} ₼ · ${e.year} · ${e.mileage} km · ${e.city}'),
                ]),
              ),
            if (list.isEmpty) YmEmpty(l10n.t('search')),
          ]),
        ),
      ]),
    );
  }

  void _editListing(BuildContext ctx, WidgetRef ref, Listing? cur) {
    final title = TextEditingController(text: cur?.title ?? '');
    final price = TextEditingController(text: cur != null ? '${cur.priceAzn}' : '');
    String t = cur?.type ?? 'moto';
    showModalBottomSheet(
      context: ctx, isScrollControlled: true,
      builder: (_) => StatefulBuilder(builder: (c, setS) => Padding(
        padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          YmField(hint: 'Make / model / year', ctrl: title),
          const SizedBox(height: 8),
          YmField(hint: 'Price ₼', ctrl: price),
          Wrap(spacing: 8, children: [for (final v in ['moto', 'moped', 'scooter', 'electro']) YmChip(label: v, selected: t == v, onTap: () => setS(() => t = v))]),
          const SizedBox(height: 12),
          FilledButton(
              onPressed: () async {
                await pickAndUpload('listings');
                final all = ref.read(listingsProvider);
                if (cur == null) {
                  ref.read(listingsProvider.notifier).state = [...all, Listing(id: nid(), title: title.text.isEmpty ? 'Moto' : title.text, city: 'Baku', priceAzn: int.tryParse(price.text) ?? 2000, year: 2023, mileage: 5000, type: t)];
                  ref.read(myListingsProvider.notifier).state = [...ref.read(myListingsProvider), title.text];
                } else {
                  ref.read(listingsProvider.notifier).state = [for (final e in all) if (e.id == cur.id) Listing(id: e.id, title: title.text, city: e.city, priceAzn: int.tryParse(price.text) ?? e.priceAzn, year: e.year, mileage: e.mileage, type: t, vip: e.vip, inspected: e.inspected) else e];
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(ref.watch(l10nProvider).t('save'))),
        ]),
      )),
    );
  }
}

class ListingDetailScreen extends ConsumerWidget {
  final String id;
  const ListingDetailScreen({super.key, required this.id});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = ref.watch(l10nProvider);
    final list = ref.watch(listingsProvider);
    final e = list.firstWhere((x) => x.id == id, orElse: () => list.first);
    final mine = ref.watch(myListingsProvider).contains(e.title);
    return YmScaffold(
      title: e.title,
      actions: [
        IconButton(icon: const Icon(Icons.flag_outlined), onPressed: () {
          loudPush(ref, 'Report', 'Listing reported → admin moderation');
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.t('report'))));
        }),
      ],
      body: ListView(padding: const EdgeInsets.all(16), children: [
        YmCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${e.priceAzn} ₼', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
          Text('${e.year} · ${e.mileage} km · ${e.city} · ${e.type}'),
          if (e.desc != null) Text(e.desc!),
        ])),
        FilledButton(
            onPressed: () async {
              await loudPush(ref, 'Inspection', 'Mechanic inspection ordered');
              ref.read(listingsProvider.notifier).state = [for (final x in list) if (x.id == e.id) Listing(id: x.id, title: x.title, city: x.city, priceAzn: x.priceAzn, year: x.year, mileage: x.mileage, type: x.type, vip: x.vip, inspected: true) else x];
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ Inspected badge')));
            },
            child: Text(l.t('inspection'))),
        OutlinedButton(onPressed: () => launchUrl(Uri.parse('tel:+994501112233')), style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(54)), child: Text(l.t('callSeller'))),
        if (mine)
          TextButton(onPressed: () {
            ref.read(listingsProvider.notifier).state = list.where((x) => x.id != e.id).toList();
            context.pop();
          }, child: const Text('Delete my listing')),
      ]),
    );
  }
}
