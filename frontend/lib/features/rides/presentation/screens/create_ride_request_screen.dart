import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/providers/ride_request_provider.dart';
import '../../../../shared/widgets/location_picker_map.dart';

class CreateRideRequestScreen extends ConsumerStatefulWidget {
  const CreateRideRequestScreen({super.key});

  @override
  ConsumerState<CreateRideRequestScreen> createState() =>
      _CreateRideRequestScreenState();
}

class _CreateRideRequestScreenState
    extends ConsumerState<CreateRideRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _sourceController = TextEditingController();
  final _destinationController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  String _vehiclePreference = 'Any';
  bool _isLoading = false;

  @override
  void dispose() {
    _sourceController.dispose();
    _destinationController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  void _submitRequest() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final data = {
          'source': _sourceController.text.trim(),
          'destination': _destinationController.text.trim(),
          'travelDate': _dateController.text.trim(),
          'travelTime': _timeController.text.trim(),
          'vehiclePreference': _vehiclePreference,
        };
        await ref.read(rideRequestServiceProvider).createRideRequest(data);
        ref.invalidate(rideRequestsProvider);
        ref.invalidate(myRideRequestsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ride Request Created!')),
          );
          context.go('/my-requests');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request a Ride')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _sourceController,
                decoration: InputDecoration(
                  labelText: 'Source',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.map),
                    onPressed: () async {
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const LocationPickerMap(),
                        ),
                      );
                      if (result != null && result is String) {
                        _sourceController.text = result;
                      }
                    },
                  ),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _destinationController,
                decoration: InputDecoration(
                  labelText: 'Destination',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.map),
                    onPressed: () async {
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const LocationPickerMap(),
                        ),
                      );
                      if (result != null && result is String) {
                        _destinationController.text = result;
                      }
                    },
                  ),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(
                  labelText: 'Date (YYYY-MM-DD)',
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _timeController,
                decoration: const InputDecoration(
                  labelText: 'Time (e.g., 08:00 AM)',
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _vehiclePreference,
                decoration: const InputDecoration(
                  labelText: 'Vehicle Preference',
                ),
                items: const [
                  DropdownMenuItem(value: 'Any', child: Text('Any')),
                  DropdownMenuItem(value: 'Car', child: Text('Car')),
                  DropdownMenuItem(value: 'Bike', child: Text('Bike')),
                  DropdownMenuItem(value: 'Rickshaw', child: Text('Rickshaw')),
                ],
                onChanged: (v) => setState(() => _vehiclePreference = v!),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitRequest,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit Request'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
