import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/camera_overlay.dart';
import '../widgets/capture_button.dart';
import '../widgets/focus_ring.dart';
import '../../review/screens/review_screen.dart';
import '../../../data/services/image_storage_service.dart';

/// Full-screen camera viewfinder for receipt capture.
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isCapturing = false;
  FlashMode _flashMode = FlashMode.off;
  Offset? _focusPoint;
  bool _showFocusRing = false;
  bool _permissionDenied = false;
  bool _permissionPermanentlyDenied = false;
  final _imageStorageService = ImageStorageService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (status.isDenied) {
      setState(() => _permissionDenied = true);
      return;
    }
    if (status.isPermanentlyDenied) {
      setState(() => _permissionPermanentlyDenied = true);
      return;
    }

    _cameras = await availableCameras();
    if (_cameras.isEmpty) return;

    _cameraController = CameraController(
      _cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await _cameraController!.initialize();
      await _cameraController!.setFlashMode(_flashMode);
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  Future<void> _captureImage() async {
    if (_isCapturing || _cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return;
    }

    setState(() => _isCapturing = true);

    try {
      final xFile = await _cameraController!.takePicture();
      final imageFile = File(xFile.path);

      // Get the crop rect from the overlay
      if (!mounted) return;
      final screenSize = MediaQuery.of(context).size;
      final cropRect = CameraOverlayHelper.getCropRect(screenSize);

      // Map overlay rect to image pixel coordinates
      final previewSize = _cameraController!.value.previewSize!;
      final imageWidth = previewSize.height; // rotated
      final imageHeight = previewSize.width;

      final scaleX = imageWidth / screenSize.width;
      final scaleY = imageHeight / screenSize.height;

      final croppedFile = await _imageStorageService.cropImage(
        imageFile,
        x: (cropRect.left * scaleX).round(),
        y: (cropRect.top * scaleY).round(),
        width: (cropRect.width * scaleX).round(),
        height: (cropRect.height * scaleY).round(),
      );

      if (!mounted) return;

      // Navigate to review screen
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReviewScreen(imageFile: croppedFile),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Capture failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewScreen(imageFile: File(picked.path)),
      ),
    );
  }

  void _toggleFlash() {
    setState(() {
      switch (_flashMode) {
        case FlashMode.off:
          _flashMode = FlashMode.auto;
          break;
        case FlashMode.auto:
          _flashMode = FlashMode.always;
          break;
        case FlashMode.always:
        case FlashMode.torch:
          _flashMode = FlashMode.off;
          break;
      }
    });
    _cameraController?.setFlashMode(_flashMode);
  }

  void _onTapToFocus(TapDownDetails details) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    final size = MediaQuery.of(context).size;
    final point = Offset(
      details.localPosition.dx / size.width,
      details.localPosition.dy / size.height,
    );

    _cameraController!.setFocusPoint(point);
    _cameraController!.setExposurePoint(point);

    setState(() {
      _focusPoint = details.localPosition;
      _showFocusRing = true;
    });
  }

  IconData get _flashIcon {
    switch (_flashMode) {
      case FlashMode.off:
        return Icons.flash_off;
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.always:
      case FlashMode.torch:
        return Icons.flash_on;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Permission denied states
    if (_permissionDenied || _permissionPermanentlyDenied) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.camera_alt_outlined,
                    size: 80, color: Colors.white54),
                const SizedBox(height: 16),
                Text(
                  'Camera Permission Required',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _permissionPermanentlyDenied
                      ? 'Camera permission was permanently denied. Please enable it in Settings.'
                      : 'We need camera access to scan receipts.',
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (_permissionPermanentlyDenied)
                  ElevatedButton.icon(
                    onPressed: () => openAppSettings(),
                    icon: const Icon(Icons.settings),
                    label: const Text('Open Settings'),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() => _permissionDenied = false);
                      _initCamera();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: _onTapToFocus,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Camera preview
            Center(child: CameraPreview(_cameraController!)),

            // Crop overlay
            const CameraOverlay(),

            // Focus ring
            if (_showFocusRing && _focusPoint != null)
              FocusRing(
                position: _focusPoint!,
                onComplete: () {
                  if (mounted) setState(() => _showFocusRing = false);
                },
              ),

            // Top controls
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 8,
              right: 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                    iconSize: 28,
                  ),
                  IconButton(
                    onPressed: _toggleFlash,
                    icon: Icon(_flashIcon, color: Colors.white),
                    iconSize: 28,
                  ),
                ],
              ),
            ),

            // Bottom controls
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 24,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Gallery pick
                  IconButton(
                    onPressed: _pickFromGallery,
                    icon: const Icon(Icons.photo_library_outlined,
                        color: Colors.white),
                    iconSize: 32,
                  ),
                  // Capture
                  CaptureButton(
                    onPressed: _captureImage,
                    enabled: !_isCapturing,
                  ),
                  // Spacer for symmetry
                  const SizedBox(width: 56),
                ],
              ),
            ),

            // Loading overlay
            if (_isCapturing)
              Container(
                color: Colors.black45,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text('Processing...',
                          style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
