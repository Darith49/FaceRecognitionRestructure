import 'dart:io';

import 'package:camera/camera.dart';
import 'package:face_recognition_attendance/core/services/api_service.dart';
import 'package:face_recognition_attendance/core/utils/date_text.dart';
import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:face_recognition_attendance/features/auth/controller/login_controller.dart';
import 'package:face_recognition_attendance/features/face/view/widgets/face_overlay.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

class FaceCaptureScreen extends StatefulWidget {
  const FaceCaptureScreen({super.key});

  @override
  State<FaceCaptureScreen> createState() => _FaceCaptureScreenState();
}

class _FaceCaptureScreenState extends State<FaceCaptureScreen> {
  final ApiService _apiService = ApiService();

  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];

  bool _isProcessing = false;
  String _statusText = '';
  Position? _currentPosition;

  // Mode: 'register', 'check_in', or 'check_out'
  late String _action;
  int? _session;

  @override
  void initState() {
    super.initState();
    _action = Get.arguments?['action'] ?? 'register';
    _session = Get.arguments?['session'];
    _initCamera();
    if (_action != 'register') {
      _getCurrentLocation();
    }
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _statusText = 'No camera found on this device.');
        return;
      }

      // Prioritize front-facing camera for face capture
      final frontCamera = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        setState(() => _statusText = 'Camera initialization error: $e');
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() => _statusText = 'Finding GPS location...');

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() => _statusText = 'Please enable GPS on your device.');
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() => _statusText = 'Location permission denied.');
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(
            () => _statusText = 'Location permission permanently denied.',
          );
        }
        return;
      }

      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      if (mounted) setState(() => _statusText = '');
    } catch (e) {
      if (mounted) setState(() => _statusText = 'Error obtaining GPS: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _captureAndProcess() async {
    if (_isProcessing ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return;
    }

    if (_action != 'register' && _currentPosition == null) {
      Get.snackbar(
        'Location Required',
        'Waiting for GPS fix. Please ensure location is enabled.',
      );
      _getCurrentLocation();
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusText = 'Scanning and processing face...';
    });

    try {
      final XFile photo = await _cameraController!.takePicture();
      final File imageFile = File(photo.path);

      dynamic result;

      if (_action == 'register') {
        setState(() => _statusText = 'Registering face with ArcFace model...');
        result = await _apiService.postMultipart(
          '/face/register/',
          file: imageFile,
          fileField: 'image',
        );
        if (Get.isRegistered<LoginController>()) {
          Get.find<LoginController>().hasFaceRegistered.value = true;
        }
      } else if (_action == 'check_in') {
        setState(() => _statusText = 'Verifying face and geofence distance...');
        final Map<String, String> fields = {
          'latitude': _currentPosition!.latitude.toString(),
          'longitude': _currentPosition!.longitude.toString(),
        };
        if (_session != null) {
          fields['session'] = _session.toString();
        }
        result = await _apiService.postMultipart(
          '/attendance/check-in/',
          file: imageFile,
          fileField: 'image',
          fields: fields,
        );
      } else if (_action == 'check_out') {
        setState(
          () => _statusText = 'Verifying face and check-out geofence...',
        );
        final Map<String, String> fields = {
          'latitude': _currentPosition!.latitude.toString(),
          'longitude': _currentPosition!.longitude.toString(),
        };
        if (_session != null) {
          fields['session'] = _session.toString();
        }
        result = await _apiService.postMultipart(
          '/attendance/check-out/',
          file: imageFile,
          fileField: 'image',
          fields: fields,
        );
      }

      // Cleanup local photo file
      try {
        if (await imageFile.exists()) await imageFile.delete();
      } catch (_) {}

      String? timeDisplay;
      if (result is Map) {
        if (result['check_in_time'] != null) {
          final cambodiaTime = DateText.parseCambodia(
            result['check_in_time'].toString(),
          );
          timeDisplay =
              'Time: ${DateText.clock(cambodiaTime)} (Cambodia, UTC+7)';
        } else if (result['check_out_time'] != null) {
          final cambodiaTime = DateText.parseCambodia(
            result['check_out_time'].toString(),
          );
          timeDisplay =
              'Time: ${DateText.clock(cambodiaTime)} (Cambodia, UTC+7)';
        }
      }

      final message = (result is Map && result.containsKey('message'))
          ? result['message'].toString()
          : 'Operation completed successfully.';

      _showSuccessDialog(message, timeDisplay: timeDisplay, resultData: result);
    } on ApiException catch (e) {
      final msg = e.message;
      final isTimeIssue =
          msg.toLowerCase().contains('section') ||
          msg.toLowerCase().contains('scheduled') ||
          msg.toLowerCase().contains('day off') ||
          msg.toLowerCase().contains('current time');
      final isLocationIssue =
          msg.toLowerCase().contains('away from') ||
          msg.toLowerCase().contains('radius');

      if (isTimeIssue || isLocationIssue) {
        final title = isTimeIssue
            ? 'Outside Check-In Window'
            : 'Location Out of Range';
        _showRestrictionDialog(
          title: title,
          message: msg,
          isTimeRestriction: isTimeIssue,
        );
      } else {
        Get.snackbar(
          '${_getActionTitle()} Failed',
          e.message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade600,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not complete face scan: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusText = '';
        });
      }
    }
  }

  void _showSuccessDialog(
    String message, {
    String? timeDisplay,
    dynamic resultData,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 48,
                  color: Colors.green.shade600,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Success!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
              if (timeDisplay != null && timeDisplay.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFA5D6A7)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 18,
                        color: Colors.green.shade800,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          timeDisplay,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Get.back(result: resultData ?? true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRestrictionDialog({
    required String title,
    required String message,
    required bool isTimeRestriction,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: isTimeRestriction
                      ? const Color(0xFFFEF3C7)
                      : const Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isTimeRestriction
                      ? Icons.access_time_filled_rounded
                      : Icons.location_off_rounded,
                  size: 40,
                  color: isTimeRestriction
                      ? const Color(0xFFD97706)
                      : const Color(0xFFDC2626),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  message,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Get.back();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isTimeRestriction
                        ? const Color(0xFFD97706)
                        : const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Understood',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getActionTitle() {
    final sessionSuffix = _session != null ? ' (Section $_session)' : '';
    switch (_action) {
      case 'register':
        return 'Register Face';
      case 'check_in':
        return 'Check In$sessionSuffix';
      case 'check_out':
        return 'Check Out$sessionSuffix';
      default:
        return 'Face Attendance';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCameraReady =
        _cameraController != null && _cameraController!.value.isInitialized;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Live Camera Preview
          if (isCameraReady)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _cameraController!.value.previewSize!.height,
                  height: _cameraController!.value.previewSize!.width,
                  child: CameraPreview(_cameraController!),
                ),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: RequestColors.primary),
            ),

          // 2. Face Scanner Overlay
          if (isCameraReady) const FaceScannerOverlay(),

          // 3. Top Bar (Back Button + Title)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () => Get.back(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _getActionTitle(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                    ),
                  ),
                  const Spacer(),
                  // GPS Status Badge
                  if (_action != 'register')
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _currentPosition != null
                            ? Colors.green.withValues(alpha: 0.85)
                            : Colors.orange.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _currentPosition != null
                                ? Icons.location_on
                                : Icons.location_searching,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _currentPosition != null
                                ? 'GPS Ready'
                                : 'Locating...',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 4. Status Badge / Processing Pill
          if (_isProcessing || _statusText.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.14,
              left: 20,
              right: 20,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.blueAccent.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isProcessing)
                        const Padding(
                          padding: EdgeInsets.only(right: 10),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      Flexible(
                        child: Text(
                          _statusText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 5. Capture Shutter Button
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: GestureDetector(
                onTap: _captureAndProcess,
                child: Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    color: _isProcessing
                        ? Colors.grey.withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.25),
                  ),
                  child: Center(
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isProcessing ? Colors.grey : Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
