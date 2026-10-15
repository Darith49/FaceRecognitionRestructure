import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:face_recognition_attendance/core/utils/file_picker_helper.dart';
import 'package:face_recognition_attendance/core/services/api_service.dart';
import 'package:face_recognition_attendance/core/services/local_auth_service.dart';
import 'package:face_recognition_attendance/core/services/local_database_service.dart';
import 'package:face_recognition_attendance/core/utils/date_text.dart';
import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:face_recognition_attendance/features/auth/controller/login_controller.dart';
import 'package:face_recognition_attendance/features/face/view/widgets/face_overlay.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

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
  bool _isPermissionDenied = false;
  Position? _currentPosition;
  int _failedAttempts = 0;
  Uint8List? _lastCapturedBytes;

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
      if (!kIsWeb) {
        final status = await Permission.camera.request();
        if (status.isPermanentlyDenied || status.isDenied) {
          if (mounted) {
            setState(() {
              _isPermissionDenied = true;
              _statusText = 'Camera permission denied.'.tr;
            });
          }
          return;
        }
      }

      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        if (mounted) setState(() => _statusText = 'No camera found on this device.'.tr);
        return;
      }

      // Prioritize front-facing camera for face capture
      final frontCamera = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isPermissionDenied = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPermissionDenied = true;
          _statusText = 'Camera unavailable or permission required.'.tr;
        });
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

      try {
        _currentPosition = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 4),
          ),
        );
      } catch (_) {
        _currentPosition = await Geolocator.getLastKnownPosition();
      }

      if (mounted) setState(() => _statusText = '');
    } catch (e) {
      if (mounted) setState(() => _statusText = '');
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
      _currentPosition = await Geolocator.getLastKnownPosition();
    }

    try {
      final XFile photo = await _cameraController!.takePicture();
      final bytes = await photo.readAsBytes();
      await _processImageBytes(
        bytes,
        photo.name.isNotEmpty ? photo.name : 'face_capture.jpg',
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not complete face scan: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    if (_isProcessing) return;

    if (_action != 'register' && _currentPosition == null) {
      _currentPosition = await Geolocator.getLastKnownPosition();
    }

    try {
      final file = await AppFilePicker.pickFile(
        isImageOnly: true,
      );
      if (file == null) return;
      await _processImageBytes(file.bytes, file.name);
    } catch (e) {
      Get.snackbar('Error', 'Failed to select image: $e', snackPosition: SnackPosition.TOP);
    }
  }

  Future<void> _processImageBytes(Uint8List bytes, String filename) async {
    setState(() {
      _isProcessing = true;
      _lastCapturedBytes = bytes;
      _statusText = 'Scanning and processing face...'.tr;
    });

    try {
      dynamic result;

      if (_action == 'register') {
        setState(() => _statusText = 'Extracting biometric face features on-device...');
        result = await _apiService.postMultipart(
          '/face/register/',
          bytes: bytes,
          filename: filename,
          fileField: 'image',
        );
        if (Get.isRegistered<LoginController>()) {
          Get.find<LoginController>().hasFaceRegistered.value = true;
        }
      } else if (_action == 'check_in') {
        setState(() => _statusText = 'Matching face biometrics & geofence on-device...');
        final Map<String, String> fields = {
          'latitude': (_currentPosition?.latitude ?? 0.0).toString(),
          'longitude': (_currentPosition?.longitude ?? 0.0).toString(),
        };
        if (_session != null) {
          fields['session'] = _session.toString();
        }
        result = await _apiService.postMultipart(
          '/attendance/check-in/',
          bytes: bytes,
          filename: filename,
          fileField: 'image',
          fields: fields,
        );
      } else if (_action == 'check_out') {
        setState(
          () => _statusText = 'Matching face biometrics for check-out on-device...',
        );
        final Map<String, String> fields = {
          'latitude': (_currentPosition?.latitude ?? 0.0).toString(),
          'longitude': (_currentPosition?.longitude ?? 0.0).toString(),
        };
        if (_session != null) {
          fields['session'] = _session.toString();
        }
        result = await _apiService.postMultipart(
          '/attendance/check-out/',
          bytes: bytes,
          filename: filename,
          fileField: 'image',
          fields: fields,
        );
      }

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

      _failedAttempts = 0;
      _showSuccessDialog(message, timeDisplay: timeDisplay, resultData: result);
    } on ApiException catch (e) {
      final code = e.errorCode ?? '';
      final status = e.statusCode;

      final isSecurityIssue = status == 403 ||
          code == 'BIOMETRIC_MISMATCH' ||
          code == 'SECURITY_ALERT';

      final isQualityOrEnrollIssue = status == 422 ||
          status == 404 ||
          code == 'FACE_QUALITY_LOW' ||
          code == 'FACE_NOT_ENROLLED' ||
          code == 'FACE_EXTRACTION_FAILED';

      final isTimeIssue = status == 423 || code == 'TIME_RESTRICTION';
      final isLocationIssue = status == 424 || code == 'LOCATION_RESTRICTION';

      if (isSecurityIssue || isQualityOrEnrollIssue) {
        _failedAttempts++;
        _showSecurityAlertDialog(
          title: isSecurityIssue
              ? 'Security Alert: Biometric Mismatch'.tr
              : 'Face Verification Failed'.tr,
          message: e.message.tr,
          details: e.details,
        );
      } else if (isTimeIssue || isLocationIssue) {
        final title = isTimeIssue
            ? 'Outside Check-In Window'.tr
            : 'Location Out of Range'.tr;
        _showRestrictionDialog(
          title: title,
          message: e.message.tr,
          isTimeRestriction: isTimeIssue,
        );
      } else {
        Get.snackbar(
          '${_getActionTitle()} Failed'.tr,
          e.message.tr,
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red.shade600,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not complete face scan: $e',
        snackPosition: SnackPosition.TOP,
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
              Text(
                'Success!'.tr,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                message.tr,
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
              if (resultData is Map && resultData['similarity'] != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_user_rounded, size: 16, color: Colors.green.shade700),
                      const SizedBox(width: 6),
                      Text(
                        '${'Biometric Match:'.tr} ${((resultData['similarity'] as num) * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
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
                  child: Text(
                    'Done'.tr,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSecurityAlertDialog({
    required String title,
    required String message,
    dynamic details,
  }) {
    Uint8List? enrolledBytes;
    if (details is Map && details['enrolled_photo'] != null) {
      final ep = details['enrolled_photo'];
      if (ep is Uint8List) {
        enrolledBytes = ep;
      } else if (ep is List) {
        enrolledBytes = Uint8List.fromList(List<int>.from(ep));
      } else if (ep is String && ep.isNotEmpty) {
        try {
          enrolledBytes = base64Decode(ep);
        } catch (_) {}
      }
    }

    if (enrolledBytes == null) {
      try {
        final db = LocalDatabaseService();
        final user = LocalAuthService().getCurrentUser();
        if (user != null) {
          final person = db.getPersons().firstWhereOrNull(
                (p) => p.id == user.uid || p.employeeId == user.uid,
              );
          if (person != null && person.faceJpg.isNotEmpty) {
            enrolledBytes = person.faceJpg;
          }
        }
      } catch (_) {}
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 24),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.gpp_bad_rounded,
                      size: 32,
                      color: Colors.red.shade600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 22, color: Colors.black45),
                    onPressed: () => Navigator.pop(ctx),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: _failedAttempts >= 3 ? Colors.red.shade100 : Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${"Attempt".tr}: $_failedAttempts / 3',
                  style: TextStyle(
                    color: _failedAttempts >= 3 ? Colors.red.shade900 : Colors.amber.shade900,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade800,
                  height: 1.3,
                ),
              ),
              if (_lastCapturedBytes != null || enrolledBytes != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.red.shade300, width: 2),
                              color: Colors.black12,
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: _lastCapturedBytes != null && _lastCapturedBytes!.isNotEmpty
                                ? Image.memory(_lastCapturedBytes!, fit: BoxFit.cover)
                                : const Icon(Icons.person_outline, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Captured Face'.tr,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red),
                          ),
                        ],
                      ),
                      Icon(Icons.compare_arrows_rounded, color: Colors.grey.shade400, size: 24),
                      Column(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.green.shade400, width: 2),
                              color: Colors.black12,
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: enrolledBytes != null && enrolledBytes.isNotEmpty
                                ? Image.memory(enrolledBytes, fit: BoxFit.cover)
                                : const Icon(Icons.face_retouching_natural, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Enrolled Face'.tr,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              if (details is Map && details['similarity'] != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Biometric Match:'.tr, style: const TextStyle(fontSize: 11, color: Colors.black54)),
                          Text(
                            '${((details['similarity'] as num) * 100).toStringAsFixed(1)}% (Req: 80%)',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red),
                          ),
                        ],
                      ),
                      if (details['liveness'] != null) ...[
                        const SizedBox(height: 3),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Liveness Score:'.tr, style: const TextStyle(fontSize: 11, color: Colors.black54)),
                            Text(
                              '${((details['liveness'] as num) * 100).toStringAsFixed(1)}% (Req: 70%)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: (details['liveness'] as num) >= 0.70 ? Colors.green.shade700 : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),
              if (_failedAttempts >= 3) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _pickAndUploadPhoto();
                    },
                    icon: const Icon(Icons.upload_file_rounded, size: 18),
                    label: Text('Upload Photo Instead'.tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RequestColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showContactAdminDialog();
                    },
                    icon: const Icon(Icons.support_agent_rounded, size: 18),
                    label: Text('Contact Admin'.tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade800,
                      side: BorderSide(color: Colors.grey.shade400),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Try Again'.tr, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('Try Again'.tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
                const SizedBox(height: 6),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _pickAndUploadPhoto();
                  },
                  icon: const Icon(Icons.upload_file_rounded, size: 16, color: RequestColors.primary),
                  label: Text('Upload Photo Instead'.tr, style: const TextStyle(color: RequestColors.primary, fontSize: 13)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showContactAdminDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.admin_panel_settings_rounded, color: RequestColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Contact Administrator'.tr,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'If face recognition repeatedly fails, your biometric profile may need to be updated or re-enrolled.'.tr,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.email_outlined, size: 16, color: Colors.black54),
                      SizedBox(width: 8),
                      Text('admin@company.com', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.phone_outlined, size: 16, color: Colors.black54),
                      SizedBox(width: 8),
                      Text('+855 23 999 888', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close'.tr),
          ),
        ],
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
                title.tr,
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
                  message.tr,
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
                  child: Text(
                    'Understood'.tr,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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
    final sessionSuffix = _session != null ? ' (${'Section'.tr} $_session)' : '';
    switch (_action) {
      case 'register':
        return 'Register Face'.tr;
      case 'check_in':
        return '${'Check In'.tr}$sessionSuffix';
      case 'check_out':
        return '${'Check Out'.tr}$sessionSuffix';
      default:
        return 'Face Attendance'.tr;
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
          // 1. Live Camera Preview or Web Fallback
          if (isCameraReady)
            Builder(
              builder: (context) {
                final previewSize = _cameraController!.value.previewSize;
                final double width = previewSize?.height ?? 720.0;
                final double height = previewSize?.width ?? 1280.0;
                return SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: width,
                      height: height,
                      child: CameraPreview(_cameraController!),
                    ),
                  ),
                );
              },
            )
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt_outlined,
                        size: 40,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _statusText.isNotEmpty
                          ? _statusText.tr
                          : (_isPermissionDenied
                              ? 'Camera permission denied'.tr
                              : 'Camera loading or permission required'.tr),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _action == 'register'
                          ? 'You can capture using your camera or upload a clear photo of your face to enroll your biometric profile.'.tr
                          : 'You can capture using your camera or upload a clear photo of your face directly from your device.'.tr,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _pickAndUploadPhoto,
                      icon: const Icon(Icons.upload_file_rounded),
                      label: Text('${'Upload Photo for'.tr} ${_getActionTitle()}'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: RequestColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await openAppSettings();
                      },
                      icon: const Icon(Icons.settings_outlined, size: 18, color: Colors.white),
                      label: Text(
                        'Open Settings'.tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white38),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: _initCamera,
                      icon: const Icon(Icons.refresh_rounded, size: 16, color: Colors.white70),
                      label: Text(
                        'Retry Camera Connection'.tr,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
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
                                ? 'GPS Ready'.tr
                                : 'Locating...'.tr,
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

          // 5. Bottom Controls (Camera shutter + Upload photo option)
          if (isCameraReady)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 36),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Upload photo button option (only for check-in/out, not register)
                    if (_action != 'register') ...[
                      TextButton.icon(
                        onPressed: _pickAndUploadPhoto,
                        icon: const Icon(
                          Icons.upload_file_rounded,
                          color: Colors.white,
                          size: 17,
                        ),
                        label: Text(
                          'Upload Photo Instead'.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                          ),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.black54,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: const BorderSide(color: Colors.white30),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    // Shutter button
                    GestureDetector(
                      onTap: _captureAndProcess,
                      child: Container(
                        width: 76,
                        height: 76,
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
                            child: const Center(
                              child: Icon(
                                Icons.camera_alt_rounded,
                                color: RequestColors.primary,
                                size: 26,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
