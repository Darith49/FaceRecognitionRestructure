import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:face_recognition_attendance/features/branch/controller/branch_controller.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

class CreateBranchScreen extends StatefulWidget {
  const CreateBranchScreen({super.key});

  @override
  State<CreateBranchScreen> createState() => _CreateBranchScreenState();
}

class _CreateBranchScreenState extends State<CreateBranchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _radiusController = TextEditingController(text: '100');

  bool _isGettingLocation = false;
  final RxBool _isSubmitting = false.obs;

  final BranchController _branchController = Get.isRegistered<BranchController>()
      ? Get.find<BranchController>()
      : Get.put(BranchController());

  @override
  void dispose() {
    _nameController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Get.snackbar('Location Service', 'Location services are disabled. Please turn on GPS.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Get.snackbar('Permission Denied', 'Location permissions are denied.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Get.snackbar('Permission Denied', 'Location permissions are permanently denied.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      setState(() {
        _latController.text = position.latitude.toStringAsFixed(6);
        _lngController.text = position.longitude.toStringAsFixed(6);
      });

      Get.snackbar(
        'GPS Located',
        'Coordinates updated (Accuracy: ${position.accuracy.toStringAsFixed(1)}m)',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.indigo.shade600,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar('Location Error', e.toString());
    } finally {
      if (mounted) {
        setState(() => _isGettingLocation = false);
      }
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting.value || _branchController.isLoading.value) return;
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());
    final radius = double.tryParse(_radiusController.text.trim()) ?? 100.0;

    if (lat == null || lng == null) {
      Get.snackbar('Invalid Input', 'Please enter valid latitude and longitude.');
      return;
    }

    _isSubmitting.value = true;
    try {
      final success = await _branchController.createBranch(
        name: name,
        latitude: lat,
        longitude: lng,
        radius: radius,
      );

      if (success) {
        Get.back(result: true);
        Get.snackbar(
          'Success',
          'Branch "$name" created successfully.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade600,
          colorText: Colors.white,
          icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          duration: const Duration(seconds: 3),
        );
      }
    } finally {
      _isSubmitting.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RequestScaffold(
      title: 'Create Branch',
      showBackButton: true,
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Branch Name
            const Text(
              'Branch Name',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: RequestColors.textPrimary),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                filled: true,
                fillColor: RequestColors.softSurface,
                hintText: 'e.g. Head Office / Phnom Penh Branch',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.business_rounded, color: RequestColors.primary),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter branch name' : null,
            ),
            const SizedBox(height: 20),

            // Coordinates Section Header with "Get Current Location" Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'GPS Coordinates',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: RequestColors.textPrimary),
                ),
                TextButton.icon(
                  onPressed: _isGettingLocation ? null : _getCurrentLocation,
                  icon: _isGettingLocation
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location_rounded, size: 16),
                  label: Text(_isGettingLocation ? 'Locating...' : 'Get Current Location'),
                  style: TextButton.styleFrom(
                    foregroundColor: RequestColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Latitude & Longitude Fields
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _latController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    decoration: InputDecoration(
                      labelText: 'Latitude',
                      hintText: 'e.g. 11.5564',
                      filled: true,
                      fillColor: RequestColors.softSurface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Tap "Get GPS" or enter Lat';
                      return double.tryParse(v.trim()) == null ? 'Invalid Lat' : null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lngController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    decoration: InputDecoration(
                      labelText: 'Longitude',
                      hintText: 'e.g. 104.9282',
                      filled: true,
                      fillColor: RequestColors.softSurface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Tap "Get GPS" or enter Lng';
                      return double.tryParse(v.trim()) == null ? 'Invalid Lng' : null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Radius
            const Text(
              'Allowed Geofence Radius (meters)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: RequestColors.textPrimary),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _radiusController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                filled: true,
                fillColor: RequestColors.softSurface,
                hintText: '100',
                suffixText: 'meters',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.radar_rounded, color: RequestColors.primary),
              ),
              validator: (v) {
                final r = double.tryParse(v ?? '');
                if (r == null || r <= 0) return 'Please enter a valid radius in meters';
                return null;
              },
            ),
            const SizedBox(height: 32),

            // Submit Button with double-tap & loading protection
            Obx(() {
              final isBusy = _isSubmitting.value || _branchController.isLoading.value;
              return SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: isBusy ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RequestColors.primary,
                    disabledBackgroundColor: RequestColors.primary.withValues(alpha: 0.65),
                    disabledForegroundColor: Colors.white,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: isBusy ? 0 : 2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isBusy) ...[
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Creating Branch...',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ] else ...[
                        const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Create Branch',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
