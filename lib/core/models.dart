import 'package:latlong2/latlong.dart';

enum UserRole { rider, mechanic, tow, admin }

enum SosStatus { active, responded, resolved, expired, escalated }

enum OrderStatus {
  created,
  searching,
  noMechanic,
  accepted,
  onTheWay,
  arrived,
  inProgress,
  completed,
  closed,
  cancelled,
  dispute,
}

class Bike {
  final String id, make, model;
  final int year;
  final int? cc;
  final String? plate, color;
  const Bike(
      {required this.id,
      required this.make,
      required this.model,
      required this.year,
      this.cc,
      this.plate,
      this.color});
  String get title => '$make $model · $year';
}

class SosEvent {
  final String id, problemId;
  final String? comment, landmark;
  final bool canMove;
  final LatLng point;
  final DateTime createdAt;
  final SosStatus status;
  final int responders;
  final double? distKm;
  const SosEvent({
    required this.id,
    required this.problemId,
    required this.point,
    required this.createdAt,
    this.comment,
    this.landmark,
    this.canMove = true,
    this.status = SosStatus.active,
    this.responders = 0,
    this.distKm,
  });
}

class MechanicInfo {
  final String id, name;
  final double rating;
  final double distKm;
  final List<String> services;
  final bool online, availableNow, verified;
  final String? area, phone;
  const MechanicInfo({
    required this.id,
    required this.name,
    required this.rating,
    required this.distKm,
    required this.services,
    this.online = true,
    this.availableNow = true,
    this.verified = true,
    this.area,
    this.phone,
  });
}

class TowInfo {
  final String id, name;
  final double distKm, rating;
  final List<String> priceLines;
  final bool availableNow, verified;
  final String? phone, area;
  const TowInfo({
    required this.id,
    required this.name,
    required this.distKm,
    required this.rating,
    required this.priceLines,
    this.availableNow = true,
    this.verified = true,
    this.phone,
    this.area,
  });
}

class Listing {
  final String id, title, city;
  final int priceAzn, year, mileage;
  final String type; // moto | moped | scooter | electro
  final bool vip, inspected, favorite;
  final String? desc;
  const Listing({
    required this.id,
    required this.title,
    required this.city,
    required this.priceAzn,
    required this.year,
    required this.mileage,
    required this.type,
    this.vip = false,
    this.inspected = false,
    this.favorite = false,
    this.desc,
  });
}

class MechOrder {
  final String id, problemId;
  final OrderStatus status;
  final MechanicInfo? mechanic;
  final DateTime createdAt;
  final int priceAzn;
  const MechOrder({
    required this.id,
    required this.problemId,
    required this.status,
    required this.createdAt,
    this.mechanic,
    this.priceAzn = 15,
  });
}
