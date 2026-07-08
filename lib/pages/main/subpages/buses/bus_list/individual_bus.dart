import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/pages/main/subpages/buses/bus_widgets.dart';
import 'package:runshaw/pages/main/subpages/buses/helpers.dart';
import 'package:runshaw/utils/api.dart';
import 'package:runshaw/utils/theme/appbar.dart';
import 'package:runshaw/utils/vendor/spinner/loading_indicator.dart';

class IndividualBusPage extends StatefulWidget {
  final String bay;
  final String busNumber;
  final Color? color;

  const IndividualBusPage({
    super.key,
    required this.bay,
    required this.busNumber,
    this.color = Colors.red,
  });

  @override
  State<IndividualBusPage> createState() => _IndividualBusPageState();
}

class _IndividualBusPageState extends State<IndividualBusPage> {
  final MapController _mapController = MapController();
  bool _isLoading = true;
  List<Map> _stops = [];
  String _routeDescription = "";
  int? _selectedStopIndex;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final BaseAPI api = context.read<BaseAPI>();
    final Map route = await api.getStopsForBus(widget.busNumber);
    final List<Map> stops = List<Map>.from(route['stops'] ?? []);
    String routeDescription = route['description'];

    // convert description to title case
    routeDescription = routeDescription
        .toLowerCase()
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');

    stops.add({
      'name': 'Runshaw College',
      'latitude': 53.6812335,
      'longitude': -2.6898653,
    });

    setState(() {
      _stops = stops;
      _routeDescription = routeDescription;
      _isLoading = false;
    });

    // automatically zoom map to fit all stops
    if (_stops.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fitMapToBounds();
      });
    }
  }

  void _fitMapToBounds() {
    if (_stops.isEmpty) return;

    final points =
        _stops.map((s) => LatLng(s['latitude'], s['longitude'])).toList();
    final bounds = LatLngBounds.fromPoints(points);

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(40.0),
      ),
    );
  }

  /// Selects a stop by index, highlights its pin, and pans the map to it.
  void _selectStop(int index) {
    final stop = _stops[index];
    final point = LatLng(stop['latitude'], stop['longitude']);

    setState(() {
      _selectedStopIndex = index;
    });

    // pan (not zoom) to the tapped stop so the user can see the pin light up.
    _mapController.move(point, _mapController.camera.zoom);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = widget.color ?? Colors.red;

    return Scaffold(
      appBar: RunshawAppBar(
        title: "Bus Info",
        backgroundColor: primaryColor,
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _isLoading
          ? Center(child: LoadingIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      SizedBox(
                        height: 350,
                        child: FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: const LatLng(
                              53.6812335,
                              -2.6898653,
                            ), // Runshaw default
                            initialZoom: 11,
                            interactionOptions: const InteractionOptions(
                              flags:
                                  InteractiveFlag.all & ~InteractiveFlag.rotate,
                            ),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                              subdomains: const ['a', 'b', 'c', 'd'],
                              userAgentPackageName: 'uk.danieldb.myrunshaw',
                            ),
                            MarkerLayer(
                              markers: List.generate(_stops.length, (index) {
                                final stop = _stops[index];
                                final isSelected = _selectedStopIndex == index;
                                return Marker(
                                  point: LatLng(
                                      stop['latitude'], stop['longitude']),
                                  // give the selected pin a little more room so it can render bigger
                                  width: isSelected ? 36 : 24,
                                  height: isSelected ? 36 : 24,
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    child: Icon(
                                      isSelected
                                          ? Icons.location_on
                                          : Icons.location_on_outlined,
                                      key: ValueKey(isSelected),
                                      color: isSelected
                                          ? primaryColor
                                          : Colors.black,
                                      size: isSelected ? 36 : 24,
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                      IgnorePointer(
                        child: Container(
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                theme.scaffoldBackgroundColor
                                    .withValues(alpha: 0.0),
                                theme.scaffoldBackgroundColor,
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: FloatingActionButton.small(
                          heroTag: "centerMapBtn",
                          backgroundColor: theme.cardColor,
                          foregroundColor: theme.colorScheme.onSurface,
                          elevation: 2,
                          onPressed: _fitMapToBounds,
                          child: const Icon(Icons.my_location_outlined),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.busNumber,
                                style: GoogleFonts.rubik(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: theme.colorScheme.onSurface,
                                  height: 1.0,
                                ),
                              ),
                              Text(
                                _routeDescription,
                                style: GoogleFonts.rubik(
                                    fontSize: 16,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.8),
                                    height: 1),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                height: 7,
                                width: 45,
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ],
                          ),
                        ),
                        BayBadge(
                            bus: BusInfo(
                              number: widget.busNumber,
                              bay: widget.bay,
                              status: widget.bay == "..." || widget.bay == "0"
                                  ? BusStatus.waiting
                                  : BusStatus.arrived,
                            ),
                            colorAt: (index) => primaryColor)
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      children: List.generate(_stops.length, (index) {
                        final stop = _stops[index];
                        final isLast = index == _stops.length - 1;
                        final isSelected = _selectedStopIndex == index;

                        return _buildStopItem(
                          stop['name'],
                          index: index,
                          isLast: isLast,
                          isSelected: isSelected,
                          primaryColor: primaryColor,
                          textColor: theme.colorScheme.onSurface,
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildStopItem(
    String name, {
    required int index,
    required bool isLast,
    required bool isSelected,
    required Color primaryColor,
    required Color textColor,
  }) {
    return GestureDetector(
      onTap: () => _selectStop(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withValues(alpha: 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
          child: Row(
            children: [
              Icon(
                isLast ? Icons.location_on_rounded : Icons.location_on_outlined,
                color: isSelected
                    ? primaryColor
                    : isLast
                        ? textColor
                        : textColor.withValues(alpha: 0.7),
                size: 26,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  name,
                  style: GoogleFonts.rubik(
                    fontSize: 16,
                    fontWeight: isLast || isSelected
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: isSelected ? primaryColor : textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
