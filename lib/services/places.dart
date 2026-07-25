import 'dart:math';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uuid/uuid.dart';

import '../app/data/models/search_result_model.dart';

class PlacesProvider {
  static const _uuid = Uuid();

  static final List<_PlaceSeed> _seedData = [
    _PlaceSeed('Green Valley High School', 'Sector 12, Delhi', 88.6139, 77.2090, 'Ramesh Kumar'),
    _PlaceSeed('Sunrise Public School', 'Dwarka, Delhi', 28.5921, 77.0460, 'Suresh Yadav'),
    _PlaceSeed('City Mall', 'Rajouri Garden, Delhi', 28.6469, 77.1200, 'Anil Sharma'),
    _PlaceSeed('Central Bus Depot', 'Kashmere Gate, Delhi', 28.6667, 77.2280, 'Vikram Singh'),
    _PlaceSeed('Riverside Apartments', 'Najafgarh, Delhi', 28.6091, 76.9800, 'Manoj Tiwari'),
    _PlaceSeed('Tech Park One', 'Gurugram', 28.4595, 77.0266, 'Sandeep Rana'),
    _PlaceSeed('Metro Station Hub', 'Rajiv Chowk, Delhi', 28.6328, 77.2197, 'Deepak Verma'),
    _PlaceSeed('Greenwood Public School', 'Vasant Kunj, Delhi', 28.5244, 77.1590, 'Rajesh Gupta'),
    _PlaceSeed('Lotus Hospital', 'Janakpuri, Delhi', 28.6219, 77.0878, 'Ashok Meena'),
    _PlaceSeed('Sunshine Daycare', 'Uttam Nagar, Delhi', 28.6194, 77.0590, 'Naveen Chauhan'),
  ];

  Future<List<SearchResultModel>> search(String query) async {
    await Future.delayed(const Duration(milliseconds: 350));

    if (query.trim().isEmpty) return [];

    final q = query.toLowerCase();
    final matches = _seedData
        .where((p) =>
    p.title.toLowerCase().contains(q) ||
        p.subtitle.toLowerCase().contains(q))
        .toList();

    final rnd = Random();
    return matches
        .map((p) => SearchResultModel(
      id: _uuid.v4(),
      title: p.title,
      subtitle: p.subtitle,
      driverName: p.driverName,
      location: LatLng(
        p.lat + (rnd.nextDouble() - 0.5) * 0.001,
        p.lng + (rnd.nextDouble() - 0.5) * 0.001,
      ),
    ))
        .toList();
  }
}

class _PlaceSeed {
  final String title;
  final String subtitle;
  final double lat;
  final double lng;
  final String driverName;
  const _PlaceSeed(this.title, this.subtitle, this.lat, this.lng, this.driverName);
}