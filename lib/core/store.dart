import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'l10n.dart';
import 'models.dart';

// ---------- Settings (lang / theme / radius / crash) ----------
class Settings {
  final String lang;
  final ThemeMode themeMode;
  final double sosRadiusKm;
  final bool visibleOnMap, crashOn;
  const Settings({
    this.lang = 'az',
    this.themeMode = ThemeMode.dark,
    this.sosRadiusKm = 5,
    this.visibleOnMap = true,
    this.crashOn = true,
  });
  Settings copyWith({
    String? lang,
    ThemeMode? themeMode,
    double? sosRadiusKm,
    bool? visibleOnMap,
    bool? crashOn,
  }) =>
      Settings(
        lang: lang ?? this.lang,
        themeMode: themeMode ?? this.themeMode,
        sosRadiusKm: sosRadiusKm ?? this.sosRadiusKm,
        visibleOnMap: visibleOnMap ?? this.visibleOnMap,
        crashOn: crashOn ?? this.crashOn,
      );
}

class SettingsN extends StateNotifier<Settings> {
  SettingsN() : super(const Settings());
  void setLang(String v) => state = state.copyWith(lang: v);
  void setTheme(ThemeMode v) => state = state.copyWith(themeMode: v);
  void setRadius(double v) => state = state.copyWith(sosRadiusKm: v);
  void toggleVisible(bool v) => state = state.copyWith(visibleOnMap: v);
  void toggleCrash(bool v) => state = state.copyWith(crashOn: v);
}

final settingsProvider =
    StateNotifierProvider<SettingsN, Settings>((_) => SettingsN());
final l10nProvider = Provider<L10n>((ref) => L10n(ref.watch(settingsProvider).lang));

// ---------- Session / role ----------
class Session {
  final bool loggedIn;
  final UserRole role;
  final bool isAdmin;
  final bool mechanicOnline;
  const Session(
      {this.loggedIn = false,
      this.role = UserRole.rider,
      this.isAdmin = true, // demo: admin visible
      this.mechanicOnline = false});
  Session copyWith(
          {bool? loggedIn,
          UserRole? role,
          bool? isAdmin,
          bool? mechanicOnline}) =>
      Session(
        loggedIn: loggedIn ?? this.loggedIn,
        role: role ?? this.role,
        isAdmin: isAdmin ?? this.isAdmin,
        mechanicOnline: mechanicOnline ?? this.mechanicOnline,
      );
}

class SessionN extends StateNotifier<Session> {
  SessionN() : super(const Session());
  void login(UserRole r) => state = state.copyWith(loggedIn: true, role: r);
  void logout() => state = const Session();
  void setRole(UserRole r) => state = state.copyWith(role: r);
  void setOnline(bool v) => state = state.copyWith(mechanicOnline: v);
}

final sessionProvider =
    StateNotifierProvider<SessionN, Session>((_) => SessionN());

// ---------- Demo data (Baku), Supabase-ready repository shape ----------
LatLng baku([double lat = 40.4093, double lng = 49.8671]) => LatLng(lat, lng);

final myBikesProvider = StateProvider<List<Bike>>((_) => const [
      Bike(id: 'b1', make: 'Honda', model: 'CB125F', year: 2022, cc: 125, plate: '10-AB-123'),
      Bike(id: 'b2', make: 'Yamaha', model: 'NMAX', year: 2023, cc: 155),
    ]);

final mySosProvider = StateProvider<SosEvent?>((_) => null);
final sosFeedProvider = StateProvider<List<SosEvent>>((_) => [
      SosEvent(
          id: 's1',
          problemId: 'tire',
          point: LatLng(40.415, 49.875),
          createdAt: DateTime.now().subtract(const Duration(minutes: 6)),
          comment: 'Flat rear tire near Sahil',
          responders: 2,
          distKm: 1.2),
      SosEvent(
          id: 's2',
          problemId: 'fuel',
          point: LatLng(40.398, 49.852),
          createdAt: DateTime.now().subtract(const Duration(minutes: 18)),
          responders: 0,
          distKm: 2.4),
    ]);

final mechanicsProvider = StateProvider<List<MechanicInfo>>((_) => const [
      MechanicInfo(id: 'm1', name: 'Kamran Usta', rating: 4.9, distKm: 1.1, services: ['engine', 'chain', 'brake'], area: 'Nizami', phone: '+994 50 111 22 33'),
      MechanicInfo(id: 'm2', name: 'Elvin Moto', rating: 4.7, distKm: 2.8, services: ['tire', 'battery', 'electrical'], area: 'Yasamal', phone: '+994 55 444 55 66'),
      MechanicInfo(id: 'm3', name: 'Garage 28', rating: 4.8, distKm: 3.5, services: ['diagnostics', 'engine'], online: false, area: '28 May'),
    ]);

final towProvider = StateProvider<List<TowInfo>>((_) => const [
      TowInfo(id: 't1', name: 'MotoEvak Baku', distKm: 2.2, rating: 4.9, priceLines: ['City: 25–35 ₼', 'Night: 40 ₼'], phone: '+994 70 777 88 99'),
      TowInfo(id: 't2', name: 'Vusal Van', distKm: 4.7, rating: 4.6, priceLines: ['City: 20–30 ₼'], availableNow: false, phone: '+994 50 222 33 44'),
    ]);

final listingsProvider = StateProvider<List<Listing>>((_) => const [
      Listing(id: 'l1', title: 'Honda CB125F 2022', city: 'Baku', priceAzn: 3150, year: 2022, mileage: 9800, type: 'moto', vip: true, inspected: true),
      Listing(id: 'l2', title: 'Yamaha NMAX 2023', city: 'Baku', priceAzn: 4150, year: 2023, mileage: 4200, type: 'scooter', inspected: true),
      Listing(id: 'l3', title: 'Moped Tufan 2023', city: 'Sumgait', priceAzn: 850, year: 2023, mileage: 6100, type: 'moped'),
      Listing(id: 'l4', title: 'Electro Citycoco', city: 'Baku', priceAzn: 1200, year: 2024, mileage: 900, type: 'electro'),
    ]);

final myOrderProvider = StateProvider<MechOrder?>((_) => null);
final crashAlertProvider = StateProvider<bool>((_) => false);
final profileNameProvider = StateProvider<String>((_) => 'Rider');
final profilePhoneProvider = StateProvider<String>((_) => '');
final profileRidingProvider = StateProvider<String>((_) => 'personal');
