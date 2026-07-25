import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../data/models/search_result_model.dart';
import '../../data/models/vehicle_model.dart';
import '../../utils/constants.dart';
import 'controller.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return Scaffold(
      body: Stack(
        children: [
          Obx(
            () => GoogleMap(
              initialCameraPosition: CameraPosition(
                target: AppConstants.mockRoute.first,
                zoom: 15,
              ),
              onMapCreated: controller.onMapCreated,
              markers: {controller.vehicleMarker},
              polylines: {controller.trailPolyline},
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
            ),
          ),

          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: _SearchBar(onTap: () => _openSearchSheet(context)),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 16, bottom: 12),
                  child: Obx(() {
                    final isOffline =
                        controller.vehicle.value?.status ==
                        VehicleStatus.offline;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FloatingActionButton.small(
                          heroTag: 'offline_btn',
                          backgroundColor: isOffline
                              ? Colors.red
                              : Colors.green,
                          onPressed: controller.toggleOffline,
                          child: Icon(
                            isOffline ? Icons.wifi_off : Icons.wifi,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        FloatingActionButton(
                          heroTag: 'locate_btn',
                          onPressed: () {
                            final v = controller.vehicle.value;
                            if (v != null) {
                              controller.mapController?.animateCamera(
                                CameraUpdate.newLatLngZoom(v.position, 16),
                              );
                            }
                          },
                          child: const Icon(Icons.my_location),
                        ),
                      ],
                    );
                  }),
                ),
                const _VehicleBottomSheet(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openSearchSheet(BuildContext context) {
    Get.bottomSheet(
      const _SearchSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final VoidCallback onTap;

  const _SearchBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            children: [
              Icon(Icons.search, color: Colors.grey),
              SizedBox(width: 10),
              Text(
                'Search destination...',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchSheet extends StatelessWidget {
  const _SearchSheet();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.65,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              autofocus: true,
              onChanged: controller.onQueryChanged,
              decoration: InputDecoration(
                hintText: 'Search for a location or destination',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Obx(() {
                final q = controller.query.value;
                if (q.isEmpty) {
                  return const _RecentHistoryList();
                }
                if (controller.isSearching.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (controller.suggestions.isEmpty) {
                  return const Center(child: Text('No matches found'));
                }
                return ListView.separated(
                  itemCount: controller.suggestions.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final r = controller.suggestions[i];
                    return _SuggestionTile(
                      result: r,
                      onTap: () => controller.selectDestination(r),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentHistoryList extends StatelessWidget {
  const _RecentHistoryList();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return Obx(() {
      if (controller.recentHistory.isEmpty) {
        return const Center(child: Text('No recent searches yet'));
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              TextButton(
                onPressed: controller.clearHistory,
                child: const Text('Clear'),
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: controller.recentHistory.length,
              itemBuilder: (_, i) => ListTile(
                leading: const Icon(Icons.history),
                title: Text(controller.recentHistory[i]),
                onTap: () =>
                    controller.onQueryChanged(controller.recentHistory[i]),
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _SuggestionTile extends StatelessWidget {
  final SearchResultModel result;
  final VoidCallback onTap;

  const _SuggestionTile({required this.result, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.location_on_outlined),
      title: Text(result.title),
      subtitle: Text(result.subtitle),
      onTap: onTap,
    );
  }
}

class _VehicleBottomSheet extends StatelessWidget {
  const _VehicleBottomSheet();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 50 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Obx(() {
            final v = controller.vehicle.value;
            if (v == null) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: _statusColor(v.status).withOpacity(0.15),
                  child: Icon(
                    Icons.local_shipping,
                    color: _statusColor(v.status),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        v.driverName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Vehicle ID: ${v.id}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusChip(status: v.status),
              ],
            );
          }),
          const SizedBox(height: 18),
          Obx(() {
            final v = controller.vehicle.value;
            return Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    icon: Icons.speed,
                    label: 'Speed',
                    value: v == null ? '--' : '${v.speedKmph} km/h',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricTile(
                    icon: Icons.access_time,
                    label: 'Updated',
                    value: v == null
                        ? '--'
                        : '${v.lastUpdated.hour.toString().padLeft(2, '0')}:'
                              '${v.lastUpdated.minute.toString().padLeft(2, '0')}:'
                              '${v.lastUpdated.second.toString().padLeft(2, '0')}',
                  ),
                ),
              ],
            );
          }),
          const Divider(height: 28),
          const _EtaToggle(),
        ],
      ),
    );
  }

  Color _statusColor(VehicleStatus status) {
    switch (status) {
      case VehicleStatus.moving:
        return Colors.green;
      case VehicleStatus.stopped:
        return Colors.orange;
      case VehicleStatus.offline:
        return Colors.red;
    }
  }
}

class _StatusChip extends StatelessWidget {
  final VehicleStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      VehicleStatus.moving => Colors.green,
      VehicleStatus.stopped => Colors.orange,
      VehicleStatus.offline => Colors.red,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EtaToggle extends StatelessWidget {
  const _EtaToggle();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return Row(
      children: [
        const Icon(Icons.notifications_active_outlined, size: 20),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'ETA Alerts',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        Obx(
          () => Switch.adaptive(
            value: controller.etaAlertsEnabled.value,
            onChanged: controller.toggleEtaAlerts,
          ),
        ),
      ],
    );
  }
}
