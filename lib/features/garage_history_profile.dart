import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/backend.dart';
import '../core/models.dart';
import '../core/photos.dart';
import '../core/store.dart';
import '../core/widgets.dart';

class GarageScreen extends ConsumerWidget {
  const GarageScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bikes = ref.watch(myBikesProvider);
    final l = ref.watch(l10nProvider);
    return YmScaffold(
      title: l.t('garage'),
      actions: [IconButton(icon: const Icon(Icons.add), onPressed: () => _editBike(context, ref, null))],
      body: ListView(padding: const EdgeInsets.symmetric(vertical: 8), children: [
        for (final b in bikes)
          YmCard(
            onTap: () => _editBike(context, ref, b),
            child: Row(children: [
              const Icon(Icons.two_wheeler, size: 32),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(b.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                Text([b.cc != null ? '${b.cc}cc' : null, b.plate, b.color].whereType<String>().join(' · ')),
              ])),
              IconButton(icon: const Icon(Icons.delete_outline), onPressed: () {
                ref.read(myBikesProvider.notifier).state = bikes.where((x) => x.id != b.id).toList();
              }),
            ]),
          ),
        if (bikes.isEmpty) YmEmpty(l.t('garage')),
      ]),
    );
  }

  void _editBike(BuildContext ctx, WidgetRef ref, Bike? cur) {
    final make = TextEditingController(text: cur?.make ?? '');
    final model = TextEditingController(text: cur?.model ?? '');
    final year = TextEditingController(text: cur != null ? '${cur.year}' : '2023');
    final plate = TextEditingController(text: cur?.plate ?? '');
    showModalBottomSheet(
      context: ctx, isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          YmField(hint: 'make', ctrl: make),
          const SizedBox(height: 8),
          YmField(hint: 'model', ctrl: model),
          const SizedBox(height: 8),
          YmField(hint: 'year', ctrl: year),
          const SizedBox(height: 8),
          YmField(hint: 'plate', ctrl: plate),
          const SizedBox(height: 12),
          FilledButton(
              onPressed: () async {
                await pickAndUpload('avatars', max: 1);
                final bikes = ref.read(myBikesProvider);
                final b = Bike(id: cur?.id ?? nid(), make: make.text.isEmpty ? 'Honda' : make.text, model: model.text.isEmpty ? 'CB125F' : model.text,
                  year: int.tryParse(year.text) ?? 2023, cc: cur?.cc ?? 125, plate: plate.text);
                ref.read(myBikesProvider.notifier).state = cur == null ? [...bikes, b] : [for (final x in bikes) if (x.id == cur.id) b else x];
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(ref.watch(l10nProvider).t('save'))),
        ]),
      ),
    );
  }
}

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = ref.watch(l10nProvider);
    final feed = ref.watch(sosFeedProvider);
    return YmScaffold(
      title: l.t('history'),
      body: ListView(padding: const EdgeInsets.symmetric(vertical: 8), children: [
        for (final s in feed)
          YmCard(
              child: Row(children: [
            const Icon(Icons.sos, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${l.problemName(s.problemId)} · ${s.distKm} km'),
              Text('${l.t('receipt')}: cash · re-call available', style: const TextStyle(fontSize: 12)),
            ])),
            TextButton(onPressed: () => context.push('/sos/new'), child: const Text('↻')),
          ])),
        const YmCard(child: Text('Order #o1 · Engine · 25 ₼ · Completed · ★★★★★ (receipt)')),
        if (feed.isEmpty) YmEmpty(l.t('history')),
      ]),
    );
  }
}

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _PState();
}

class _PState extends ConsumerState<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final s = ref.watch(settingsProvider);
    final sn = ref.read(settingsProvider.notifier);
    final sess = ref.watch(sessionProvider);
    final l = ref.watch(l10nProvider);
    final name = ref.watch(profileNameProvider);
    final phone = ref.watch(profilePhoneProvider);
    final contacts = ref.watch(emergencyContactsProvider);
    final nameC = TextEditingController(text: name);
    final phoneC = TextEditingController(text: phone);
    final contactC = TextEditingController();
    return YmScaffold(
      title: l.t('profile'),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const CircleAvatar(radius: 34, child: Icon(Icons.person, size: 34)),
        const SizedBox(height: 8),
        Center(child: Text('$name · Baku', style: const TextStyle(fontWeight: FontWeight.w700))),
        const SizedBox(height: 16),
        YmCard(
          child: Column(children: [
            YmField(hint: l.t('name'), ctrl: nameC),
            const SizedBox(height: 8),
            YmField(hint: l.t('phone'), ctrl: phoneC),
            const SizedBox(height: 8),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              onPressed: () async {
                ref.read(profileNameProvider.notifier).state = nameC.text;
                ref.read(profilePhoneProvider.notifier).state = phoneC.text;
                if (hasSupabase && Supabase.instance.client.auth.currentUser != null) {
                  await Supabase.instance.client.from('profiles').update({'name': nameC.text, 'phone': phoneC.text}).eq('id', Supabase.instance.client.auth.currentUser!.id);
                }
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.t('save'))));
              },
              child: Text(l.t('save')),
            ),
          ]),
        ),
        YmCard(
          child: Column(children: [
            ListTile(dense: true, title: Text(l.t('garage')), trailing: const Icon(Icons.chevron_right), onTap: () => context.push('/garage')),
            ListTile(dense: true, title: Text(l.t('myListings')), trailing: const Icon(Icons.chevron_right), onTap: () => context.push('/market')),
            ListTile(dense: true, title: Text(l.t('notifs')), trailing: const Icon(Icons.chevron_right), onTap: () => context.push('/notifs')),
            ListTile(dense: true, title: Text(l.t('terms')), trailing: const Icon(Icons.chevron_right), onTap: () => context.push('/terms')),
            ListTile(dense: true, title: const Text('Mechanic inbox'), trailing: const Icon(Icons.chevron_right), onTap: () => context.push('/mechanic/inbox')),
            if (sess.isAdmin)
              ListTile(dense: true, title: Text(l.t('admin'), style: const TextStyle(fontWeight: FontWeight.w800)), trailing: const Icon(Icons.chevron_right), onTap: () => context.push('/admin')),
          ]),
        ),
        YmCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.t('emergencyContacts'), style: const TextStyle(fontWeight: FontWeight.w800)),
            for (final c in contacts) ListTile(dense: true, title: Text(c), trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () {
              ref.read(emergencyContactsProvider.notifier).state = contacts.where((e) => e != c).toList();
            })),
            Row(children: [
              Expanded(child: YmField(hint: '+994 …', ctrl: contactC)),
              IconButton(icon: const Icon(Icons.add), onPressed: () {
                if (contactC.text.isNotEmpty) ref.read(emergencyContactsProvider.notifier).state = [...contacts, contactC.text];
              }),
            ]),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => launchUrl(Uri.parse('tel:112')), child: Text(l.t('emergency')))),
            ]),
          ]),
        ),
        YmCard(
          child: Column(children: [
            const Text('Language / Dil / Язык', style: TextStyle(fontWeight: FontWeight.w800)),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (final lang in ['az', 'ru', 'en'])
                TextButton(onPressed: () => sn.setLang(lang), child: Text(lang.toUpperCase(),
                  style: TextStyle(fontWeight: s.lang == lang ? FontWeight.w900 : FontWeight.w400))),
            ]),
            const Divider(),
            Text('SOS radius: ${s.sosRadiusKm.toStringAsFixed(0)} km (2/5/10/25)'),
            Slider(value: s.sosRadiusKm, min: 2, max: 25, divisions: 4, label: '${s.sosRadiusKm.toStringAsFixed(0)} km', onChanged: (v) => sn.setRadius(v)),
            SwitchListTile(title: const Text('Show me on map'), value: s.visibleOnMap, onChanged: sn.toggleVisible),
            SwitchListTile(title: const Text('Crash detection'), value: s.crashOn, onChanged: sn.toggleCrash),
            SwitchListTile(title: const Text('Dark theme'), value: s.themeMode == ThemeMode.dark, onChanged: (v) => sn.setTheme(v ? ThemeMode.dark : ThemeMode.light)),
          ]),
        ),
        OutlinedButton(
          onPressed: () => showModalBottomSheet(
            context: context,
            builder: (_) => SafeArea(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                for (final r in [UserRole.rider, UserRole.mechanic, UserRole.tow])
                  ListTile(title: Text(r.name), onTap: () {
                    ref.read(sessionProvider.notifier).setRole(r);
                    Navigator.pop(context);
                  }),
              ]),
            ),
          ),
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          child: const Text('Switch role'),
        ),
        TextButton(
          onPressed: () async {
            final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
              title: Text(l.t('deleteAccount')),
              actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.t('cancel'))), FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l.t('deleteAccount')))],
            ));
            if (ok == true) {
              try {
                if (hasSupabase) await Supabase.instance.client.from('profiles').update({'blocked': true}).eq('id', Supabase.instance.client.auth.currentUser!.id);
                await Backend.signOut();
              } catch (_) {}
              ref.read(sessionProvider.notifier).logout();
              if (context.mounted) context.go('/welcome');
            }
          },
          child: Text(l.t('deleteAccount')),
        ),
        TextButton(
          onPressed: () async {
            await Backend.signOut();
            ref.read(sessionProvider.notifier).logout();
            if (context.mounted) context.go('/welcome');
          },
          child: Text(l.t('logout')),
        ),
      ]),
    );
  }
}
