import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/backend.dart';
import '../core/models.dart';
import '../core/photos.dart';
import '../core/store.dart';
import '../core/widgets.dart';

class TermsScreen extends ConsumerWidget {
  const TermsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = ref.watch(l10nProvider);
    return YmScaffold(
      title: l.t('terms'),
      body: ListView(padding: const EdgeInsets.all(16), children: const [
        YmCard(child: Text('Terms of Service: SOS is community help, no guarantee. False SOS → block. Mechanic/tow paid in cash outside app at launch. Prices agreed on spot and confirmed in app. Cancellation free before acceptance.')),
        YmCard(child: Text('Privacy: location approximate on public map; exact only in active SOS/accepted order and only for its duration. Data deletable with account. Server-side RLS permission checks.')),
      ]),
    );
  }
}

class NotifsScreen extends ConsumerWidget {
  const NotifsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = ref.watch(l10nProvider);
    final items = ref.watch(notifProvider);
    return YmScaffold(
      title: l.t('notifs'),
      body: items.isEmpty
          ? YmEmpty(l.t('notifs'))
          : ListView(children: [for (final n in items) YmCard(child: ListTile(title: Text(n.title), subtitle: Text(n.body)))]),
    );
  }
}

class MechanicRegisterScreen extends ConsumerStatefulWidget {
  const MechanicRegisterScreen({super.key});
  @override
  ConsumerState<MechanicRegisterScreen> createState() => _MRState();
}

class _MRState extends ConsumerState<MechanicRegisterScreen> {
  String kind = 'mobile';
  final specs = TextEditingController(text: 'engine, brakes');
  final area = TextEditingController(text: 'Nizami');
  @override
  Widget build(BuildContext context) {
    final l = ref.watch(l10nProvider);
    return YmScaffold(
      title: l.t('becomeMechanic'),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Wrap(spacing: 8, children: [
          for (final v in ['mobile', 'garage', 'both']) YmChip(label: v, selected: kind == v, onTap: () => setState(() => kind = v)),
        ]),
        const SizedBox(height: 8),
        YmField(hint: 'specs + custom services', ctrl: specs),
        const SizedBox(height: 8),
        YmField(hint: 'garage name / area / pin', ctrl: area),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => pickAndUpload('docs'),
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          child: const Text('Upload ID document'),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () {
            ref.read(mechanicsProvider.notifier).state = [
              ...ref.read(mechanicsProvider),
              MechanicInfo(id: nid(), name: ref.read(profileNameProvider), rating: 5.0, distKm: 0.8,
                services: specs.text.split(',').map((e) => e.trim()).toList(), online: false, verified: false, area: area.text),
            ];
            ref.read(sessionProvider.notifier).setRole(UserRole.mechanic);
            context.pop();
          },
          child: const Text('Submit → Under review'),
        ),
        const Text('Until approval: not shown, no orders. Statuses: review/approved/rejected/suspended.', textAlign: TextAlign.center),
      ]),
    );
  }
}
