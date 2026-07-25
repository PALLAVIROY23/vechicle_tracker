
import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../components/appSnackBaar.dart';
import '../../data/models/vehicle_model.dart';
import '../../data/models/search_result_model.dart';
import '../../../services/location_service.dart';
import '../../../services/places.dart';
import '../../data/repository/storage_repository.dart';
import '../../utils/constants.dart';
import 'package:geolocator/geolocator.dart';


class HomeController extends GetxController {
  HomeController({
    LocationProvider? locationProvider,
    required this.placesProvider,
    required this.repository,
  }) : _provider =
      locationProvider ??
          LocationProvider(
            route: AppConstants.mockRoute,
            driverName: 'Ramesh Kumar',
          );

  final LocationProvider _provider;
  final PlacesProvider placesProvider;
  final StorageRepository repository;
  LatLng? _destination;
  bool _hasAlertedThisTrip = false;

  StreamSubscription<VehicleModel>? _sub;
  Timer? _debounce;

  final Rxn<VehicleModel> vehicle = Rxn<VehicleModel>();
  final RxList<LatLng> travelledPath = <LatLng>[].obs;
  GoogleMapController? mapController;

  final RxString query = ''.obs;
  final RxList<SearchResultModel> suggestions = <SearchResultModel>[].obs;
  final RxBool isSearching = false.obs;
  final RxList<String> recentHistory = <String>[].obs;

  late final RxBool etaAlertsEnabled;

  final Map<VehicleStatus, BitmapDescriptor> _vehicleIcons = {};
  BitmapDescriptor _fallbackIcon = BitmapDescriptor.defaultMarker;

  @override
  void onInit() {
    super.onInit();

    etaAlertsEnabled = repository.etaAlertsEnabled.obs;
    recentHistory.assignAll(repository.searchHistory);

    _provider.onDestinationReached = () {
      AppSnackbar.success('Reached destination!');
    };
    _sub = _provider.stream.listen(_onVehicleUpdate);
    _provider.start();


    _loadVehicleIcons();
  }

  Future<BitmapDescriptor> _resizedMarkerIcon(String assetPath, int targetWidth) async {
    final ByteData data = await rootBundle.load(assetPath);
    final ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: targetWidth,
    );
    final ui.FrameInfo frame = await codec.getNextFrame();
    final ByteData? resizedBytes =
    await frame.image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(resizedBytes!.buffer.asUint8List());
  }

  Future<void> _loadVehicleIcons() async {
    const targetWidth = 48;

    _vehicleIcons[VehicleStatus.moving] =
    await _resizedMarkerIcon('assets/images/moving.png', targetWidth);
    _vehicleIcons[VehicleStatus.stopped] =
    await _resizedMarkerIcon('assets/images/stop.png', targetWidth);
    _vehicleIcons[VehicleStatus.offline] =
    await _resizedMarkerIcon('assets/images/offline.png', targetWidth);

    vehicle.refresh();
  }
  void _onVehicleUpdate(VehicleModel update) {
    vehicle.value = update;

    travelledPath.add(update.position);
    if (travelledPath.length > 60) {
      travelledPath.removeAt(0);
    }

    mapController?.animateCamera(CameraUpdate.newLatLng(update.position));

    if (etaAlertsEnabled.value && _destination != null && !_hasAlertedThisTrip) {
      final distanceMeters = Geolocator.distanceBetween(
        update.position.latitude,
        update.position.longitude,
        _destination!.latitude,
        _destination!.longitude,
      );
      if (distanceMeters < 500) {
        _hasAlertedThisTrip = true;
        AppSnackbar.info('Arriving soon — approaching destination');
      }
    }  }

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void toggleOffline() {
    if (vehicle.value?.status == VehicleStatus.offline) {
      _provider.resumeFromOffline();
    } else {
      _provider.goOffline();
    }
  }


  void _restartTracking({required String driverName, List<LatLng>? route}) {
    travelledPath.clear();
    vehicle.value = null;
    _provider.updateTrip(driverName: driverName, route: route);
  }
  List<LatLng> _buildRouteTo(LatLng start, LatLng end, {int steps = 20}) {
    return List.generate(steps + 1, (i) {
      final t = i / steps;
      return LatLng(
        start.latitude + (end.latitude - start.latitude) * t,
        start.longitude + (end.longitude - start.longitude) * t,
      );
    });
  }

  Marker get vehicleMarker {
    final v = vehicle.value;
    final icon = v != null
        ? (_vehicleIcons[v.status] ?? _fallbackIcon)
        : _fallbackIcon;

    return Marker(
      markerId: const MarkerId('tracked_vehicle'),
      position: v?.position ?? AppConstants.mockRoute.first,
      icon: icon,
      anchor: const Offset(0.5, 0.5), // center the icon on the exact point
      infoWindow: InfoWindow(
        title: v?.driverName ?? 'Vehicle',
        snippet: v != null ? '${v.status.label} • ${v.speedKmph} km/h' : '',
      ),
    );
  }

  Polyline get trailPolyline => Polyline(
    polylineId: const PolylineId('travelled_path'),
    points: travelledPath,
    width: 4,
    color: AppConstants.primaryColor,
  );

  void onQueryChanged(String value) {
    query.value = value;
    _debounce?.cancel();

    if (value.trim().isEmpty) {
      suggestions.clear();
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 250), () async {
      isSearching.value = true;
      final results = await placesProvider.search(value);
      suggestions.assignAll(results);
      isSearching.value = false;
    });
  }

  Future<void> selectDestination(SearchResultModel result) async {
    await repository.addSearchHistory(result.title);
    recentHistory.assignAll(repository.searchHistory);
    suggestions.clear();
    query.value = '';
    Get.back();

    final start = vehicle.value?.position ?? AppConstants.mockRoute.first;
    final newRoute = _buildRouteTo(start, result.location);
    _destination = result.location;      // <-- new
    _hasAlertedThisTrip = false;

    _restartTracking(driverName: result.driverName, route: newRoute);

    AppSnackbar.info('Destination set ${result.title} • Driver: ${result.driverName}');
  }
  Future<void> clearHistory() async {
    await repository.clearSearchHistory();
    recentHistory.clear();
  }

  Future<void> toggleEtaAlerts(bool value) async {
    etaAlertsEnabled.value = value;
    await repository.setEtaAlertsEnabled(value);
    AppSnackbar.success(value ? 'Alerts turned ON' : 'Alerts turned OFF');
  }

  @override
  void onClose() {
    _sub?.cancel();
    _debounce?.cancel();
    _provider.dispose();
    super.onClose();
  }
}