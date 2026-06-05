import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/providers/ride_offer_provider.dart';
import '../../../../shared/widgets/location_picker_map.dart';

class CreateRideOfferScreen extends ConsumerStatefulWidget {
  const CreateRideOfferScreen({super.key});

  @override
  ConsumerState<CreateRideOfferScreen> createState() => _CreateRideOfferScreenState();
}

class _CreateRideOfferScreenState extends ConsumerState<CreateRideOfferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _sourceController = TextEditingController();
  final _destinationController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _seatsController = TextEditingController(text: '3');
  final _vehicleDetailsController = TextEditingController();
  final _priceController = TextEditingController(text: '0');

  String _vehicleType = 'Car';
  bool _womenOnly = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _sourceController.dispose();
    _destinationController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _seatsController.dispose();
    _vehicleDetailsController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(rideOfferServiceProvider).createRideOffer({
        'source': _sourceController.text.trim(),
        'destination': _destinationController.text.trim(),
        'travelDate': _dateController.text.trim(),
        'travelTime': _timeController.text.trim(),
        'totalSeats': int.parse(_seatsController.text.trim()),
        'vehicleType': _vehicleType,
        'vehicleDetails': _vehicleDetailsController.text.trim(),
        'pricePerSeat': double.tryParse(_priceController.text.trim()) ?? 0,
        'womenOnly': _womenOnly,
      });
      ref.invalidate(rideOffersProvider);
      ref.invalidate(myRideOffersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ride offer created!')),
        );
        context.go('/driver');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Offer a Ride')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
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
                        MaterialPageRoute(builder: (_) => const LocationPickerMap()),
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
                        MaterialPageRoute(builder: (_) => const LocationPickerMap()),
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
                decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _timeController,
                decoration: const InputDecoration(labelText: 'Time (e.g. 08:00 AM)'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _seatsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Total seats (1–6)'),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final n = int.tryParse(v);
                  if (n == null || n < 1 || n > 6) return 'Enter 1–6';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _vehicleType,
                decoration: const InputDecoration(labelText: 'Vehicle type'),
                items: const [
                  DropdownMenuItem(value: 'Car', child: Text('Car')),
                  DropdownMenuItem(value: 'Bike', child: Text('Bike')),
                  DropdownMenuItem(value: 'Rickshaw', child: Text('Rickshaw')),
                ],
                onChanged: (v) => setState(() => _vehicleType = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _vehicleDetailsController,
                decoration: const InputDecoration(
                  labelText: 'Vehicle details (optional)',
                  hintText: 'White Toyota Corolla',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Price per seat (BDT)'),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Women-only ride'),
                value: _womenOnly,
                onChanged: (v) => setState(() => _womenOnly = v),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Publish Offer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
