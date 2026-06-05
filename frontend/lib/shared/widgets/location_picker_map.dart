import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:dio/dio.dart';

class LocationPickerMap extends StatefulWidget {
  final LatLng initialCenter;

  const LocationPickerMap({
    super.key,
    this.initialCenter = const LatLng(23.8378, 90.3575), // Default to BUP roughly
  });

  @override
  State<LocationPickerMap> createState() => _LocationPickerMapState();
}

class _LocationPickerMapState extends State<LocationPickerMap> {
  late LatLng _selectedLocation;
  late final MapController _mapController;
  final TextEditingController _searchController = TextEditingController();
  String _address = 'Loading address...';
  bool _isLoadingAddress = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialCenter;
    _mapController = MapController();
    _fetchAddress(_selectedLocation);
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAddress(LatLng point) async {
    setState(() => _isLoadingAddress = true);
    try {
      final response = await Dio().get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'lat': point.latitude,
          'lon': point.longitude,
          'format': 'json',
        },
        options: Options(headers: {'User-Agent': 'AnnexPoolApp/1.0'}),
      );
      if (response.data != null && response.data['display_name'] != null) {
        setState(() {
          _address = response.data['display_name'];
        });
      } else {
        setState(() => _address = 'Address not found');
      }
    } catch (e) {
      setState(() => _address = '${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}');
    } finally {
      setState(() => _isLoadingAddress = false);
    }
  }

  Future<void> _searchPlace(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _isSearching = true);
    
    try {
      final response = await Dio().get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': query,
          'format': 'json',
          'limit': 1,
        },
        options: Options(headers: {'User-Agent': 'AnnexPoolApp/1.0'}),
      );
      
      if (response.data != null && (response.data as List).isNotEmpty) {
        final result = response.data[0];
        final lat = double.parse(result['lat'].toString());
        final lon = double.parse(result['lon'].toString());
        final newPoint = LatLng(lat, lon);
        
        setState(() {
          _selectedLocation = newPoint;
          _address = result['display_name'] ?? 'Selected location';
        });
        _mapController.move(newPoint, 15.0);
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Place not found')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error searching place')));
    } finally {
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pick Location')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialCenter,
              initialZoom: 14.0,
              onTap: (tapPosition, point) {
                setState(() {
                  _selectedLocation = point;
                });
                _fetchAddress(point);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.annexpool.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedLocation,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search place...',
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                        ),
                        onSubmitted: _searchPlace,
                      ),
                    ),
                    if (_isSearching)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: () => _searchPlace(_searchController.text),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: Card(
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Selected Location:',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    _isLoadingAddress
                        ? const CircularProgressIndicator()
                        : Text(
                            _address,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoadingAddress
                            ? null
                            : () {
                                Navigator.of(context).pop(_address);
                              },
                        child: const Text('Confirm Location'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
