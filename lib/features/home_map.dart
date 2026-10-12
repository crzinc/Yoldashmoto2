import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/map_ex.dart';
import '../core/models.dart';
import '../core/services.dart';
import '../core/store.dart';
import '../core/theme.dart';
import '../core/widgets.dart';

/// Bolt/Uber-grade map: live puck + heading, search (Nominatim),
/// OSRM route + ETA, pulsing SOS pins, animated mechanic,
/// draggable action sheet, dark tiles at night.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});
  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> with TickerProviderStateMixin {
  LatLng center = LatLng(40.4093, 49.8671);
  double heading = 0;
  final ctl = MapController();
  StreamSubscription<Position>? _posSub;
  final searchCtl = TextEditingController();
  List<PlaceHit> hits = [];
  bool searching = false;
  Timer? _deb;

  // selection + routing
  String? selSosId;
  String? selMechId;
  RouteInfo? route;
  bool routeLoading = false;
  LatLng? mechAnim;
  Timer? _animT;
  int _animI = 0;

  bool get dark => Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(crashServiceProvider).start());
    _locate();
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _animT?.cancel();
    _deb?.cancel();
    searchCtl.dispose();
    super.dispose();
  }

  Future<void> _locate() async {
    await Permission.locationWhenInUse.request();
    try {
      final p = await currentPos();
      if (p != null && mounted) {
        setState(() {
          center = LatLng(p.latitude, p.longitude);
          heading = p.heading;
        });
        ctl.move(center, 14);
      }
      _posSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5),
      ).listen((p) {
        if (!mounted) return;
        setState(() {
          center = LatLng(p.latitude, p.longitude);
          heading = p.heading;
        });
      });
    } catch (_) {}
  }

  LatLng _mechPoint(MechanicInfo m) =>
      LatLng(center.latitude + m.distKm * 0.008, center.longitude + m.distKm * 0.008);

  LatLng _towPoint(double d) =>
      LatLng(center.latitude - d * 0.006, center.longitude - d * 0.006);

  Future<void> _routeTo(LatLng dest) async {
    setState(() { routeLoading = true; route = null; });
    final r = await fetchRoute(center, dest);
    if (!mounted) return;
    setState(() { route = r; routeLoading = false; });
    if (r != null && r.points.isNotEmpty) {
      _animT?.cancel();
      _animI = 0;
      setState(() => mechAnim = r.points.first);
      _animT = Timer.periodic(const Duration(milliseconds: 600), (_) {
        if (!mounted || r.points.isEmpty) return;
        _animI = (_animI + 3) % r.points.length;
        setState(() => mechAnim = r.points[_animI]);
      });
    }
  }

  void _onSearch(String v) {
    _deb?.cancel();
    _deb = Timer(const Duration(milliseconds: 500), () async {
      if (v.trim().length < 3) {
        setState(() { hits = []; searching = false; });
        return;
      }
      setState(() => searching = true);
      final r = await searchPlaces(v, center);
      if (!mounted) return;
      setState(() { hits = r; searching = false; });
    });
  }

  void _goTo(LatLng p) {
    ctl.move(p, 15);
    setState(() { hits = []; searchCtl.clear(); });
    _routeTo(p);
  }

  @override
  Widget build(BuildContext context) {
    final l = ref.watch(l10nProvider);
    final feed = ref.watch(sosFeedProvider);
    final mySos = ref.watch(mySosProvider);
    final order = ref.watch(myOrderProvider);
    final mechs = [...ref.watch(mechanicsProvider)]..sort((a, b) => a.distKm.compareTo(b.distKm));
    final tows = ref.watch(towProvider);
    final crash = ref.watch(crashAlertProvider);
    if (crash) {
      Future.microtask(() {
        if (!mounted) return;
        ref.read(crashAlertProvider.notifier).state = false;
        context.push('/crash');
      });
    }
    final visible = ref.watch(settingsProvider).visibleOnMap;
    // Role visibility: riders see only masters/workshops (+SOS calls);
    // mechanics & tow see only riders in search (active SOS / orders).
    final role = ref.watch(sessionProvider).role;
    final mechView = role == UserRole.mechanic || role == UserRole.tow;
    final onlineMechs = mechView ? const <MechanicInfo>[] : mechs.where((e) => e.online).toList();
    final availTows = mechView ? const <TowInfo>[] : tows.where((e) => e.availableNow).toList();

    return Scaffold(
      body: Stack(children: [
        FlutterMap(
          mapController: ctl,
          options: MapOptions(
            initialCenter: center,
            initialZoom: 14,
            interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
          ),
          children: [
            TileLayer(
              urlTemplate: dark
                  ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                  : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            ),
            if (route != null && route!.points.isNotEmpty)
              PolylineLayer(polylines: [
                Polyline(points: route!.points, strokeWidth: 5, color: YmColors.accent),
              ]),
            MarkerLayer(markers: [
              for (final s in feed)
                Marker(
                  point: s.point, width: 56, height: 56,
                  child: GestureDetector(
                    onTap: () {
                      setState(() { selSosId = s.id; selMechId = null; });
                      _routeTo(s.point);
                    },
                    child: _SosPin(active: s.id == selSosId || (mySos != null && s.id == mySos.id)),
                  ),
                ),
              for (final m in onlineMechs)
                Marker(
                  point: _mechPoint(m), width: 44, height: 44,
                  child: GestureDetector(
                    onTap: () {
                      setState(() { selMechId = m.id; selSosId = null; });
                      _routeTo(_mechPoint(m));
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: selMechId == m.id ? YmColors.accent : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: YmColors.accent, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: Icon(Icons.build, size: 20, color: selMechId == m.id ? Colors.white : YmColors.accent),
                    ),
                  ),
                ),
              for (final t in availTows)
                Marker(
                  point: _towPoint(t.distKm), width: 40, height: 40,
                  child: const Icon(Icons.local_shipping, size: 28, color: Colors.green),
                ),
              if (mechAnim != null && (order != null || selSosId != null || selMechId != null))
                Marker(
                  point: mechAnim!, width: 48, height: 48,
                  child: Container(
                    decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)),
                    alignment: Alignment.center,
                    child: const Icon(Icons.two_wheeler, color: Colors.white, size: 22),
                  ),
                ),
              if (visible)
                Marker(
                  point: center, width: 52, height: 52,
                  child: Transform.rotate(
                    angle: heading * 3.14159 / 180,
                    child: Container(
                      decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.15), shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Container(
                        width: 22, height: 22,
                        decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)),
                      ),
                    ),
                  ),
                ),
            ]),
          ],
        ),

        // ---- top: search + online chip ----
        SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(16),
                child: TextField(
                  controller: searchCtl,
                  onChanged: _onSearch,
                  decoration: InputDecoration(
                    hintText: l.t('whereTo'),
                    prefixIcon: searching
                        ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))
                        : const Icon(Icons.search),
                    suffixIcon: searchCtl.text.isEmpty
                        ? null
                        : IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() { searchCtl.clear(); hits = []; })),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
              ),
            ),
            if (hits.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(16),
                  child: Column(children: [
                    for (final h in hits)
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.place_outlined),
                        title: Text(h.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                        onTap: () => _goTo(h.point),
                      ),
                  ]),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                Chip(
                  avatar: const CircleAvatar(backgroundColor: Colors.green, radius: 5),
                  label: Text(mechView ? '${feed.length} searching' : '${mechs.where((e) => e.online).length + 128} online'),
                ),
                const SizedBox(width: 8),
                if (routeLoading) const Chip(label: Text('…')),
                if (route != null)
                  Chip(
                    avatar: const Icon(Icons.navigation, size: 16, color: YmColors.accent),
                    label: Text('${route!.km.toStringAsFixed(1)} km · ${l.t('eta')} ${etaText(route!.minutes)}'),
                    onDeleted: () => setState(() { route = null; selSosId = null; selMechId = null; mechAnim = null; }),
                  ),
              ]),
            ),
          ]),
        ),

        // ---- right controls: locate / zoom / compass ----
        Positioned(
          right: 12, top: 190,
          child: Column(children: [
            _MapBtn(icon: Icons.my_location, onTap: () => ctl.move(center, 15)),
            const SizedBox(height: 8),
            _MapBtn(icon: Icons.add, onTap: () => ctl.move(ctl.camera.center, ctl.camera.zoom + 1)),
            const SizedBox(height: 8),
            _MapBtn(icon: Icons.remove, onTap: () => ctl.move(ctl.camera.center, ctl.camera.zoom - 1)),
          ]),
        ),

        // ---- bottom action sheet ----
        DraggableScrollableSheet(
          initialChildSize: order != null || mySos != null ? 0.34 : 0.26,
          minChildSize: 0.16, maxChildSize: 0.7,
          builder: (_, scroll) => Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: const [BoxShadow(blurRadius: 16, color: Colors.black26)],
            ),
            child: ListView(controller: scroll, padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 8),
              if (order != null)
                _OrderCard(onOpen: () => context.push('/call/track'))
              else if (mySos != null)
                _MySosCard(onOpen: () => context.push('/sos/track'))
              else if (mechView) ...[
                Row(children: [
                  Expanded(
                    child: Text(
                      ref.watch(sessionProvider).mechanicOnline ? l.t('online') : l.t('offline'),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ),
                  Switch(
                    value: ref.watch(sessionProvider).mechanicOnline,
                    onChanged: (v) => ref.read(sessionProvider.notifier).setOnline(v),
                  ),
                ]),
                FilledButton.icon(
                  onPressed: () => context.push('/mechanic/inbox'),
                  icon: const Icon(Icons.inbox_outlined),
                  label: const Text('Inbox'),
                ),
                const SizedBox(height: 8),
                Text(l.t('nearby'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 8),
                if (feed.isEmpty) YmEmpty(l.t('noOneNearby')),
                for (final s in feed)
                  YmCard(
                    child: Row(children: [
                      const CircleAvatar(backgroundColor: Colors.red, child: Icon(Icons.sos, color: Colors.white, size: 18)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${l.problemName(s.problemId)} · ${s.distKm ?? 1.2} km', style: const TextStyle(fontWeight: FontWeight.w800)),
                        Text('${s.responders} responders'),
                      ])),
                      TextButton(
                        onPressed: () {
                          setState(() { selSosId = s.id; selMechId = null; });
                          _routeTo(s.point);
                        },
                        child: Text(l.t('navigate')),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(minimumSize: const Size(88, 40)),
                        onPressed: () => context.push('/mechanic/inbox'),
                        child: Text(l.t('accept')),
                      ),
                    ]),
                  ),
              ] else ...[
                Row(children: [
                  Expanded(child: SosButton(onTap: () => context.push('/sos/new'))),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      FilledButton.icon(onPressed: () => context.push('/call/new'), icon: const Icon(Icons.build), label: Text(l.t('callMechanic'))),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => launchUrl(Uri.parse('tel:112')),
                        icon: const Icon(Icons.call, color: Colors.red),
                        label: Text(l.t('emergency')),
                        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                      ),
                    ]),
                  ),
                ]),
                const SizedBox(height: 12),
                Text(l.t('nearby'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 132,
                  child: ListView(scrollDirection: Axis.horizontal, children: [
                    for (final s in feed.take(3))
                      _NearbyCard(
                        icon: Icons.sos, color: Colors.red,
                        title: 'SOS · ${l.problemName(s.problemId)}',
                        sub: '${s.distKm ?? 1.2} km · ${s.responders} →',
                        onTap: () {
                          setState(() { selSosId = s.id; });
                          _routeTo(s.point);
                        },
                      ),
                    for (final m in mechs.take(4))
                      _NearbyCard(
                        icon: Icons.build, color: YmColors.accent,
                        title: m.name, sub: '${m.distKm} km · ★ ${m.rating}',
                        onTap: () {
                          setState(() { selMechId = m.id; });
                          _routeTo(_mechPoint(m));
                        },
                      ),
                    _NearbyCard(
                      icon: Icons.local_shipping, color: Colors.green,
                      title: l.t('tow'), sub: '${tows.first.distKm} km',
                      onTap: () => context.go('/tow'),
                    ),
                  ]),
                ),
              ],
            ]),
          ),
        ),
      ]),
    );
  }
}

class _MapBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MapBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
        elevation: 4, shape: const CircleBorder(),
        child: InkWell(customBorder: const CircleBorder(), onTap: onTap, child: Padding(padding: const EdgeInsets.all(10), child: Icon(icon, size: 20))),
      );
}

/// Pulsing SOS pin (selected = bigger + accent ring).
class _SosPin extends StatefulWidget {
  final bool active;
  const _SosPin({required this.active});
  @override
  State<_SosPin> createState() => _SosPinState();
}

class _SosPinState extends State<_SosPin> with SingleTickerProviderStateMixin {
  late final AnimationController c;
  @override
  void initState() {
    super.initState();
    c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: c,
        builder: (_, __) => Stack(alignment: Alignment.center, children: [
          Container(
            width: 48 * c.value + 20, height: 48 * c.value + 20,
            decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.25 * (1 - c.value)), shape: BoxShape.circle),
          ),
          Container(
            width: widget.active ? 40 : 32, height: widget.active ? 40 : 32,
            decoration: BoxDecoration(
              color: Colors.red, shape: BoxShape.circle,
              border: Border.all(color: widget.active ? YmColors.accent : Colors.white, width: 3),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.sos, color: Colors.white, size: 18),
          ),
        ]),
      );
}

class _NearbyCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, sub;
  final VoidCallback onTap;
  const _NearbyCard({required this.icon, required this.color, required this.title, required this.sub, required this.onTap});
  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(right: 10),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            width: 150,
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(icon, color: color),
              const SizedBox(height: 6),
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              Text(sub, style: const TextStyle(fontSize: 12)),
            ]),
          ),
        ),
      );
}

class _OrderCard extends ConsumerWidget {
  final VoidCallback onOpen;
  const _OrderCard({required this.onOpen});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final o = ref.watch(myOrderProvider)!;
    final l = ref.watch(l10nProvider);
    return YmCard(
      onTap: onOpen,
      child: Row(children: [
        const CircleAvatar(child: Icon(Icons.build)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${l.problemName(o.problemId)} · ${o.status.name}', style: const TextStyle(fontWeight: FontWeight.w800)),
          Text('${o.mechanic?.name ?? ''} · ${l.t('eta')} ~8 min'),
        ])),
        const Icon(Icons.chevron_right),
      ]),
    );
  }
}

class _MySosCard extends ConsumerWidget {
  final VoidCallback onOpen;
  const _MySosCard({required this.onOpen});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(mySosProvider)!;
    final l = ref.watch(l10nProvider);
    return YmCard(
      onTap: onOpen,
      child: Row(children: [
        const CircleAvatar(backgroundColor: Colors.red, child: Icon(Icons.sos, color: Colors.white)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('SOS · ${l.problemName(s.problemId)}', style: const TextStyle(fontWeight: FontWeight.w800)),
          Text('${s.responders} responders · ${l.t('eta')} ~5 min'),
        ])),
        const Icon(Icons.chevron_right),
      ]),
    );
  }
}
