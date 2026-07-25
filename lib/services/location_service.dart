import 'dart:async';
import 'dart:math';

import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../app/data/models/vehicle_model.dart';

class LocationProvider {
  LocationProvider({
    required List<LatLng> route,
    required String driverName,
    this.tickInterval = const Duration(seconds: 2),
    this.destinationPauseTicks = 3, // ~6 seconds, tweak as you like
  })  : route = route,
        driverName = driverName,
        vehicleId = 'VEH-${Random().nextInt(9000) + 1000}';

  final String vehicleId;
  String driverName;
  List<LatLng> route;
  final Duration tickInterval;
  final int destinationPauseTicks;

  /// Fired exactly once each time the vehicle reaches the last point
  /// in [route]. The controller wires this up to show a snackbar —
  /// this class stays UI-agnostic, it just reports the event.
  void Function()? onDestinationReached;

  final StreamController<VehicleModel> _controller =
  StreamController<VehicleModel>.broadcast();
  Timer? _timer;
  int _routeIndex = 0;
  int _stoppedTicks = 0;
  int _offlineTicks = 0;
  bool _hasNotifiedArrival = false;
  final Random _random = Random();

  Stream<VehicleModel> get stream => _controller.stream;

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(tickInterval, (_) => _emitNextTick());
    _emitNextTick();
  }

  void updateTrip({required String driverName, List<LatLng>? route}) {
    this.driverName = driverName;
    if (route != null) {
      this.route = route;
    }
    _routeIndex = 0;
    _stoppedTicks = 0;
    _offlineTicks = 0;
    _hasNotifiedArrival = false; // new trip → allow arrival notification again
    _emitNextTick();
  }

  void _emitNextTick() {
    if (route.isEmpty) return;

    // 1. Offline — takes priority over everything else.
    final bool simulateOffline =
        _random.nextDouble() < 0.06 && _offlineTicks == 0 && _stoppedTicks == 0;
    if (simulateOffline) {
      _offlineTicks = 2 + _random.nextInt(2);
    }

    if (_offlineTicks > 0) {
      _offlineTicks--;
      _controller.add(
        VehicleModel(
          id: vehicleId,
          driverName: driverName,
          position: route[_routeIndex],
          speedKmph: 0,
          status: VehicleStatus.offline,
          lastUpdated: DateTime.now(),
        ),
      );
      return;
    }

    // 2. Arrival check — last point in the route counts as "destination".
    final bool isAtDestination = _routeIndex == route.length - 1;
    if (isAtDestination && !_hasNotifiedArrival) {
      _hasNotifiedArrival = true;
      _stoppedTicks = destinationPauseTicks;
      onDestinationReached?.call();
    }

    // 3. Random stop — skipped if we're already paused for arrival.
    final bool simulateStop =
        _random.nextDouble() < 0.12 && _stoppedTicks == 0 && !isAtDestination;
    if (simulateStop) {
      _stoppedTicks = 1 + _random.nextInt(2);
    }

    VehicleStatus status;
    double speed;

    if (_stoppedTicks > 0) {
      _stoppedTicks--;
      status = VehicleStatus.stopped;
      speed = 0;
    } else {
      status = VehicleStatus.moving;
      speed = 22 + _random.nextDouble() * 28;
      _routeIndex = (_routeIndex + 1) % route.length;

      // Left the destination point → allow the next arrival to notify again.
      if (_routeIndex != route.length - 1) {
        _hasNotifiedArrival = false;
      }
    }

    _controller.add(
      VehicleModel(
        id: vehicleId,
        driverName: driverName,
        position: route[_routeIndex],
        speedKmph: double.parse(speed.toStringAsFixed(1)),
        status: status,
        lastUpdated: DateTime.now(),
      ),
    );
  }

  void goOffline() {
    _offlineTicks = 2;
    _controller.add(
      VehicleModel(
        id: vehicleId,
        driverName: driverName,
        position: route[_routeIndex],
        speedKmph: 0,
        status: VehicleStatus.offline,
        lastUpdated: DateTime.now(),
      ),
    );
  }

  void resumeFromOffline() {
    _offlineTicks = 0;
    _emitNextTick();
  }

  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}