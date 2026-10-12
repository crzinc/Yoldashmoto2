import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/backend.dart';
import '../core/models.dart';
import '../core/notify.dart';
import '../core/store.dart';
import '../core/widgets.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = ref.watch(l10nProvider);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                for (final lang in ['az', 'ru', 'en'])
                  TextButton(
                    onPressed: () => ref.read(settingsProvider.notifier).setLang(lang),
                    child: Text(lang.toUpperCase(),
                        style: TextStyle(
                            fontWeight: ref.watch(settingsProvider).lang == lang
                                ? FontWeight.w900
                                : FontWeight.w400)),
                  ),
              ]),
              const Spacer(),
              Container(
                width: 84, height: 84,
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(28)),
                alignment: Alignment.center,
                child: const Icon(Icons.two_wheeler, size: 44, color: Colors.white),
              ),
              const SizedBox(height: 20),
              const Text('YoldashMoto', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(l.t('tagline'), style: Theme.of(context).textTheme.bodyLarge),
              const Spacer(),
              FilledButton(onPressed: () => context.push('/role'), child: Text(l.t('signup'))),
              const SizedBox(height: 12),
              OutlinedButton(
                  onPressed: () => context.push('/login'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: Text(l.t('login'))),
            ],
          ),
        ),
      ),
    );
  }
}

class RoleScreen extends ConsumerStatefulWidget {
  const RoleScreen({super.key});
  @override
  ConsumerState<RoleScreen> createState() => _RoleState();
}

class _RoleState extends ConsumerState<RoleScreen> {
  UserRole role = UserRole.rider;
  final name = TextEditingController();
  final phone = TextEditingController();
  String riding = 'personal';
  bool agree = false;
  // mechanic fields
  String mechKind = 'mobile';
  final specs = TextEditingController(text: 'engine, brakes');
  final area = TextEditingController();
  // tow fields
  final company = TextEditingController();
  final truck = TextEditingController(text: 'moto platform');
  final prices = TextEditingController(text: 'City: 25–35 ₼');

  @override
  Widget build(BuildContext context) {
    final l = ref.watch(l10nProvider);
    return YmScaffold(
      title: l.t('signup'),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Wrap(spacing: 8, children: [
          for (final r in [(UserRole.rider, '🏍 Rider'), (UserRole.mechanic, '🔧 Mechanic'), (UserRole.tow, '🚛 Tow')])
            YmChip(label: r.$2, selected: role == r.$1, onTap: () => setState(() => role = r.$1)),
        ]),
        const SizedBox(height: 12),
        YmField(hint: l.t('name'), ctrl: name),
        const SizedBox(height: 8),
        YmField(hint: '+994 50 000 00 00', ctrl: phone),
        if (role == UserRole.rider) ...[
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            for (final v in ['personal', 'courier', 'both'])
              YmChip(label: v, selected: riding == v, onTap: () => setState(() => riding = v)),
          ]),
        ],
        if (role == UserRole.mechanic) ...[
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            for (final v in ['mobile', 'garage', 'both'])
              YmChip(label: v, selected: mechKind == v, onTap: () => setState(() => mechKind = v)),
          ]),
          const SizedBox(height: 8),
          YmField(hint: 'specs: engine, brakes…', ctrl: specs),
          const SizedBox(height: 8),
          YmField(hint: 'area / address', ctrl: area),
          const SizedBox(height: 8),
          const Text('ID document photo attached at verification (Storage: docs). Application → admin, hidden until approved.'),
        ],
        if (role == UserRole.tow) ...[
          const SizedBox(height: 8),
          YmField(hint: 'name / company', ctrl: company),
          const SizedBox(height: 8),
          YmField(hint: 'truck type', ctrl: truck),
          const SizedBox(height: 8),
          YmField(hint: 'City: 25–35 ₼', ctrl: prices, maxLines: 3),
        ],
        CheckboxListTile(
          value: agree,
          onChanged: (v) => setState(() => agree = v ?? false),
          title: Text(l.t('agreeTerms')),
          subtitle: InkWell(onTap: () => context.push('/terms'), child: Text(l.t('terms'), style: const TextStyle(decoration: TextDecoration.underline))),
        ),
        FilledButton(
          onPressed: !agree || name.text.isEmpty && phone.text.isEmpty ? null : () async {
            await Backend.sendOtp(phone.text);
            ref.read(profileNameProvider.notifier).state = name.text;
            ref.read(profilePhoneProvider.notifier).state = phone.text;
            ref.read(sessionProvider.notifier).login(role);
            await loudPush(ref, 'YoldashMoto', 'OTP sent (demo: any code)');
            if (context.mounted) context.push('/login');
          },
          child: Text(l.t('sendCode')),
        ),
      ]),
    );
  }
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginState();
}

class _LoginState extends ConsumerState<LoginScreen> {
  final phone = TextEditingController();
  final code = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final l = ref.watch(l10nProvider);
    return YmScaffold(
      title: l.t('login'),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          YmField(hint: '+994 50 000 00 00', ctrl: phone),
          const SizedBox(height: 12),
          YmField(hint: l.t('smsCode'), ctrl: code),
          const SizedBox(height: 16),
          FilledButton(
              onPressed: () async {
                try {
                  await Backend.verifyOtp(phone.text, code.text);
                } catch (_) {}
                ref.read(sessionProvider.notifier).login(UserRole.rider);
                if (context.mounted) context.go('/map');
              },
              child: Text(l.t('login'))),
          const SizedBox(height: 8),
          const Text('Supabase Auth OTP wired (Backend.verifyOtp). Demo mode accepts any code.'),
        ]),
      ),
    );
  }
}
