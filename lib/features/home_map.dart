import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/services.dart';
import '../core/store.dart';
import '../core/widgets.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});
  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  LatLng center = LatLng(40.4093, 49.8671);
  final ctl = MapController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(crashServiceProvider).start());
    _locate();
  }

  Future<void> _locate() async {
    await Permission.locationWhenInUse.request();
    try {
      final p = await currentPos();
      if (p != null && mounted) {
        setState(() => center = LatLng(p.latitude, p.longitude));
        ctl.move(center, 13);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l = ref.watch(l10nProvider);
    final feed = ref.watch(sosFeedProvider);
    final mySos = ref.watch(mySosProvider);
    final mechs = ref.watch(mechanicsProvider);
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
    return Scaffold(
      body: Stack(children: [
        FlutterMap(
          mapController: ctl,
          options: MapOptions(initialCenter: center, initialZoom: 13),
          children: [
            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
            MarkerLayer(markers: [
              if (visible)
                Marker(point: center, width: 44, height: 44, child: const Icon(Icons.two_wheeler, size: 30, color: Colors.blue)),
              for (final s in feed)
                Marker(
                  point: s.point, width: 44, height: 44,
                  child: GestureDetector(onTap: () => context.push('/sos/track'),
                    child: Container(decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)), alignment: Alignment.center, child: const Icon(Icons.sos, color: Colors.white, size: 22))),
                ),
              for (final m in mechs.where((e) => e.online))
                Marker(point: LatLng(center.latitude + m.distKm * 0.008, center.longitude + m.distKm * 0.008), width: 40, height: 40,
                  child: const Icon(Icons.build_circle, size: 30, color: Colors.orange)),
              for (final t in tows.where((e) => e.availableNow))
                Marker(point: LatLng(center.latitude - t.distKm * 0.006, center.longitude - t.distKm * 0.006), width: 40, height: 40,
                  child: const Icon(Icons.local_shipping, size: 28, color: Colors.green)),
            ]),
          ],
        ),
        SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                Chip(avatar: const CircleAvatar(backgroundColor: Colors.green, radius: 5), label: Text('${mechs.where((e) => e.online).length + 128} online')),
                const SizedBox(width: 8),
                if (mySos != null || feed.isNotEmpty)
                  Expanded(
                      child: Card(
                          child: ListTile(
                              dense: true,
                              title: Text(mySos != null
                                  ? '${l.t('sos')} · ${l.problemName(mySos.problemId)}'
                                  : 'SOS · ${l.problemName(feed.first.problemId)} · ${feed.first.distKm} km'),
                              trailing: TextButton(
                                  onPressed: () => context.push(mySos != null ? '/sos/track' : '/sos/track'),
                                  child: Text(mySos != null ? '→' : l.t('imComing')))))),
              ]),
            ),
            const Spacer(),
            if (feed.isEmpty && mySos == null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(l.t('noOneNearby')),
                      Row(children: [
                        TextButton(onPressed: () => context.go('/mechanics'), child: Text(l.t('mechanics'))),
                        TextButton(onPressed: () => context.go('/tow'), child: Text(l.t('tow'))),
                        TextButton(onPressed: () => launchUrl(Uri.parse('tel:112')), child: Text(l.t('emergency'))),
                      ]),
                    ]),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FloatingActionButton.small(heroTag: 'loc', onPressed: _locate, child: const Icon(Icons.my_location)),
                  SosButton(onTap: () => context.push('/sos/new')),
                  FloatingActionButton.extended(heroTag: 'mech', onPressed: () => context.push('/call/new'), icon: const Icon(Icons.build), label: Text(l.t('callMechanic'))),
                ],
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
