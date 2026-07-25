import 'package:google_maps_flutter/google_maps_flutter.dart';


class SearchResultModel {
  final String id;
  final String title;
  final String subtitle;
  final LatLng location;
  final String driverName;

  const SearchResultModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.location,
    required this.driverName,
  });
}