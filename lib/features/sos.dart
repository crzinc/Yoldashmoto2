import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vibration/vibration.dart';
import '../core/backend.dart';
import '../core/l10n.dart';
import '../core/models.dart';
import '../core/notify.dart';
import '../core/photos.dart';
import '../core/services.dart';
import '../core/store.dart';
import '../core/theme.dart';
import '../core/widgets.dart';

class SosFormScreen extends ConsumerStatefulWidget {
  const SosFormScreen({super.key});
  @override
  ConsumerState<SosFormScreen> createState() => _SosFormState();
}

class _SosFormState extends ConsumerState<SosFormScreen> {
  final Set<String> problems = {'tire'};
  bool canMove = true;
  final comment = TextEditingController();
  final landmark = TextEditingController();
  List<String> photos = [];
  bool sending = false;

  @override
  Widget build(BuildContext context) {
    final l = ref.watch(l10nProvider);
    return YmScaffold(
      title: 'SOS',
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Wrap(spacing: 8, children: [
          for (final p in L10n.problems)
            YmChip(
              label: p.$2[l.lang] ?? p.$2['en']!,
              selected: problems.contains(p.$1),
              onTap: () => setState(() => problems.contains(p.$1) ? problems.remove(p.$1) : problems.add(p.$1)),
            ),
        ]),
        const SizedBox(height: 12),
        YmField(hint: l.t('comment'), ctrl: comment, maxLines: 2),
        const SizedBox(height: 8),
        YmField(hint: 'landmark', ctrl: landmark),
        SwitchListTile(value: canMove, onChanged: (v) => setState(() => canMove = v), title: Text(l.t('canMove'))),
        OutlinedButton(
          onPressed: () async {
            final urls = await pickAndUpload('sos-photos');
            setState(() => photos = [...photos, ...urls, if (urls.isEmpty) 'local-photo']);
          },
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          child: Text('${l.t('addPhoto')} (${photos.length})'),
        ),
        const SizedBox(height: 12),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: YmColors.sos),
          onPressed: sending || problems.isEmpty ? null : () async {
            setState(() => sending = true);
            Position? pos;
            try { pos = await currentPos(); } catch (_) {}
            final ev = SosEvent(
              id: nid(), problemId: problems.first, point: baku(pos?.latitude ?? 40.4093, pos?.longitude ?? 49.8671),
              createdAt: DateTime.now(), comment: comment.text, landmark: landmark.text,
              canMove: canMove, status: SosStatus.active,
            );
            ref.read(mySosProvider.notifier).state = ev;
            ref.read(sosFeedProvider.notifier).state = [ev, ...ref.read(sosFeedProvider)];
            await Backend.insertSos(problemId: ev.problemId, point: ev.point, comment: comment.text, landmark: landmark.text, canMove: canMove);
            await loudPush(ref, 'SOS sent', l.problemName(ev.problemId));
            if (context.mounted) context.go('/sos/track');
          },
          child: Text(l.t('sendSos')),
        ),
      ]),
    );
  }
}

class SosTrackScreen extends ConsumerWidget {
  const SosTrackScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = ref.watch(l10nProvider);
    final feed = ref.watch(sosFeedProvider);
    if (feed.isEmpty) return YmScaffold(title: 'SOS', body: YmEmpty(l.t('noOneNearby')));
    final sos = ref.watch(mySosProvider) ?? feed.first;
    return YmScaffold(
      title: 'SOS · ${l.problemName(sos.problemId)} · ${sos.status.name}',
      body: ListView(padding: const EdgeInsets.all(16), children: [
        YmCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${sos.responders} responders · ${sos.distKm ?? 1.2} km', style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('Kamran is on the way · 1.2 km'),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => launchUrl(Uri.parse(mapsUrl(sos.point))), child: Text(l.t('navigate')))),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton(onPressed: () => launchUrl(Uri.parse('tel:+994501112233')), child: Text(l.t('call')))),
            ]),
            TextButton(
              onPressed: () async {
                ref.read(sessionProvider.notifier);
                await loudPush(ref, 'SOS', 'I’m coming — 1 responder');
                final upd = SosEvent(id: sos.id, problemId: sos.problemId, point: sos.point, createdAt: sos.createdAt, comment: sos.comment, status: SosStatus.responded, responders: sos.responders + 1, distKm: sos.distKm);
                if (ref.read(mySosProvider) != null) ref.read(mySosProvider.notifier).state = upd;
              },
              child: Text(l.t('imComing')),
            ),
          ]),
        ),
        YmCard(
          child: Column(children: [
            ListTile(dense: true, title: Text(l.t('callMechanic')), trailing: const Icon(Icons.chevron_right), onTap: () => context.push('/call/new')),
            ListTile(dense: true, title: Text(l.t('tow')), trailing: const Icon(Icons.chevron_right), onTap: () => context.go('/tow')),
            ListTile(dense: true, title: Text(l.t('emergency')), trailing: const Icon(Icons.call),
              onTap: () => launchUrl(Uri.parse('tel:112'))),
          ]),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: YmColors.ok),
          onPressed: () {
            ref.read(mySosProvider.notifier).state = null;
            ref.read(sosFeedProvider.notifier).state = ref.read(sosFeedProvider).where((e) => e.id != sos.id).toList();
            context.go('/map');
          },
          child: Text(l.t('problemSolved')),
        ),
        TextButton(
          onPressed: () {
            ref.read(mySosProvider.notifier).state = null;
            loudPush(ref, 'SOS', 'False alarm — responders notified');
            context.go('/map');
          },
          child: Text(l.t('falseAlarm')),
        ),
      ]),
    );
  }
}

class CrashScreen extends ConsumerStatefulWidget {
  const CrashScreen({super.key});
  @override
  ConsumerState<CrashScreen> createState() => _CrashState();
}

class _CrashState extends ConsumerState<CrashScreen> {
  int sec = 15;
  Timer? t;
  @override
  void initState() {
    super.initState();
    Vibration.vibrate(pattern: [0, 400, 200, 400]);
    t = Timer.periodic(const Duration(seconds: 1), (x) async {
      if (sec <= 1) {
        x.cancel();
        ref.read(mySosProvider.notifier).state = SosEvent(id: nid(), problemId: 'accident', point: baku(), createdAt: DateTime.now());
        await loudPush(ref, 'CRASH auto-SOS', 'Accident SOS sent to nearby riders');
        // Stage 2: SMS to emergency contacts with location link
        for (final c in ref.read(emergencyContactsProvider)) {
          launchUrl(Uri.parse('sms:$c?body=YoldashMoto CRASH https://maps.google.com/?q=40.4093,49.8671'));
        }
        if (mounted) context.go('/sos/track');
      } else {
        setState(() => sec--);
      }
    });
  }

  @override
  void dispose() { t?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final l = ref.watch(l10nProvider);
    return Scaffold(
      backgroundColor: YmColors.sos,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(l.t('crashTitle'), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
            Text('$sec', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 84, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            OutlinedButton(
              style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white), minimumSize: const Size.fromHeight(50)),
              onPressed: () => launchUrl(Uri.parse('tel:112')),
              child: Text(l.t('emergency')),
            ),
            const SizedBox(height: 12),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
              onPressed: () { t?.cancel(); context.go('/map'); },
              child: Text(l.t('imOk'), style: const TextStyle(fontSize: 20)),
            ),
          ]),
        ),
      ),
    );
  }
}
