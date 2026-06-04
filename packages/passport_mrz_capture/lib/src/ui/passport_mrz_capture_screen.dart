import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:passport_mrz_capture/src/layout/passport_guide_layout.dart';
import 'package:passport_mrz_capture/src/processing/passport_capture_processor.dart';
import 'package:passport_mrz_capture/src/models/passport_mrz_capture_config.dart';
import 'package:passport_mrz_capture/src/models/passport_mrz_capture_error_code.dart';
import 'package:passport_mrz_capture/src/models/passport_mrz_capture_failure.dart';
import 'package:passport_mrz_capture/src/models/passport_mrz_parsed_data.dart';
import 'package:passport_mrz_capture/src/models/passport_mrz_capture_success.dart';
import 'package:passport_mrz_capture/src/parsing/mrz_parser.dart';
import 'package:passport_mrz_capture/src/processing/face_cropper.dart';
import 'package:passport_mrz_capture/src/processing/passport_frame_analyzer.dart';
import 'package:passport_mrz_capture/src/ui/passport_guide_overlay_painter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class PassportMrzCaptureScreen extends StatefulWidget {
  const PassportMrzCaptureScreen({
    super.key,
    required this.config,
    required this.onSuccess,
    required this.onFailure,
  });

  final PassportMrzCaptureConfig config;
  final void Function(PassportMrzCaptureSuccess success) onSuccess;
  final void Function(PassportMrzCaptureFailure failure) onFailure;

  @override
  State<PassportMrzCaptureScreen> createState() =>
      _PassportMrzCaptureScreenState();
}

class _PassportMrzCaptureScreenState extends State<PassportMrzCaptureScreen>
    with SingleTickerProviderStateMixin {
  static const _frameInterval = Duration(milliseconds: 2200);
  static const _hintStableFrames = 3;
  static const _frameSampleStep = 5;

  CameraController? _controller;
  bool _initializing = true;
  String? _initError;
  final ValueNotifier<PassportScanHint> _hintNotifier =
      ValueNotifier(PassportScanHint.placeInFrame);
  bool _frameAnalysisInFlight = false;
  bool _isCapturing = false;
  bool _tapFocusInFlight = false;
  Offset? _lastTapFocusPoint;
  DateTime? _lastFrameProcessedAt;
  PassportScanHint? _pendingHint;
  int _pendingHintFrames = 0;

  // --- NEW OCR IMPLEMENTATION ---
  File? _fullPassportImage;
  File? _mrzCroppedImage;
  final ValueNotifier<bool> _capturingUi = ValueNotifier(false);

  late final AnimationController _pulseController;

  void _endCaptureUi({bool resumePreview = true}) {
    _isCapturing = false;
    _capturingUi.value = false;
    if (resumePreview && mounted) {
      unawaited(_resumePreviewAfterCapture());
    }
  }

  void _pausePreviewDuringCapture() {
    _pulseController.stop();
    unawaited(_stopImageStream());
  }

  Future<void> _resumePreviewAfterCapture() async {
    final cam = _controller;
    if (!mounted || cam == null || !cam.value.isInitialized) return;
    try {
      if (!cam.value.isStreamingImages) {
        await cam.startImageStream(_onCameraImage);
      }
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _setup();
  }

  Future<CameraController> _openCameraController(CameraDescription camera) async {
    for (final preset in [
      ResolutionPreset.veryHigh,
      ResolutionPreset.high,
      ResolutionPreset.max,
    ]) {
      final controller = CameraController(
        camera,
        preset,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );
      try {
        await controller.initialize();
        return controller;
      } catch (_) {
        await controller.dispose();
      }
    }
    throw StateError('Could not open camera at any resolution preset');
  }

  Future<void> _setup() async {
    final granted = await _ensureCameraPermission();
    if (!granted) {
      if (mounted) {
        setState(() {
          _initializing = false;
          _initError = 'camera_permission';
        });
      }
      return;
    }

    try {
      final cams = await availableCameras();
      final back = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cams.first,
      );
      final cam = await _openCameraController(back);
      await cam.setFlashMode(FlashMode.off);
      try {
        await cam.setFocusMode(FocusMode.auto);
        await cam.setExposureMode(ExposureMode.auto);
      } catch (_) {
        // Some devices do not support manual focus/exposure modes.
      }
      try {
        final minZ = await cam.getMinZoomLevel();
        final maxZ = await cam.getMaxZoomLevel();
        final target = 1.0.clamp(minZ, maxZ);
        await cam.setZoomLevel(target);
      } catch (_) {}
      await cam.startImageStream(_onCameraImage);
      if (!mounted) return;
      setState(() {
        _controller = cam;
        _initializing = false;
        _initError = null;
      });
      _hintNotifier.value = PassportScanHint.placeInFrame;
    } catch (_) {
      if (mounted) {
        setState(() {
          _initializing = false;
          _initError = 'camera_init';
        });
      }
    }
  }

  Future<bool> _ensureCameraPermission() async {
    var status = await Permission.camera.status;
    if (status.isGranted) return true;
    status = await Permission.camera.request();
    if (status.isGranted) return true;
    if (!mounted) return false;
    if (status.isPermanentlyDenied) {
      await _showOpenSettingsDialog();
    } else {
      await _showOpenSettingsDialog();
    }
    return false;
  }

  Future<void> _showOpenSettingsDialog() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Camera access'),
        content: const Text(
          'Camera permission is required to scan your passport. You can enable it in system settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              openAppSettings();
            },
            child: const Text('Open settings'),
          ),
        ],
      ),
    );
  }

  PassportFrameSample? _buildFrameSample(CameraImage image) {
    if (image.planes.isEmpty) return null;

    final plane = image.planes.first;
    final bytes = plane.bytes;
    final bpr = plane.bytesPerRow;
    final w = image.width;
    final h = image.height;
    final isBgra = image.format.group == ImageFormatGroup.bgra8888;
    final step = _frameSampleStep;

    final sw = (w + step - 1) ~/ step;
    final sh = (h + step - 1) ~/ step;
    final out = Uint8List(sw * sh);
    var oi = 0;

    for (var y = 0; y < h; y += step) {
      for (var x = 0; x < w; x += step) {
        final row = y * bpr;
        double luma;
        if (isBgra) {
          final i = row + x * 4;
          if (i + 2 >= bytes.length) {
            luma = 0;
          } else {
            luma =
                0.114 * bytes[i] + 0.587 * bytes[i + 1] + 0.299 * bytes[i + 2];
          }
        } else {
          final i = row + x;
          luma = i < bytes.length ? bytes[i].toDouble() : 0;
        }
        out[oi++] = luma.round().clamp(0, 255);
      }
    }

    return PassportFrameSample(width: sw, height: sh, bytes: out);
  }

  PassportScanHint _hintFromMetrics(PassportFrameMetrics m) {
    if (m.meanLuma < 42 || m.meanLuma > 218) {
      return PassportScanHint.poorLighting;
    }
    if (m.sharpness < 90) {
      return PassportScanHint.outOfFocus;
    }
    if (m.fillRatio < 0.065) {
      return PassportScanHint.moveCloser;
    }
    if (m.bottomContrast < 11.5) {
      return PassportScanHint.alignMrz;
    }
    if (m.fillRatio < 0.10) {
      return PassportScanHint.moveCloser;
    }
    return PassportScanHint.holdSteady;
  }

  void _onCameraImage(CameraImage image) {
    if (_isCapturing || _frameAnalysisInFlight || !mounted) return;

    final now = DateTime.now();
    if (_lastFrameProcessedAt != null &&
        now.difference(_lastFrameProcessedAt!) < _frameInterval) {
      return;
    }
    _lastFrameProcessedAt = now;

    final sample = _buildFrameSample(image);
    if (sample == null) return;

    _frameAnalysisInFlight = true;
    unawaited(_analyzeFrameSample(sample));
  }

  Future<void> _analyzeFrameSample(PassportFrameSample sample) async {
    try {
      final metrics = await compute(analyzePassportFrame, sample);
      if (!mounted || _isCapturing) return;
      _applyHint(_hintFromMetrics(metrics));
    } catch (_) {
      // Keep previous hint on analysis failure.
    } finally {
      _frameAnalysisInFlight = false;
    }
  }

  void _applyHint(PassportScanHint hint, {bool immediate = false}) {
    if (_isCapturing && hint != PassportScanHint.scanning) return;
    if (hint == _hintNotifier.value) {
      _pendingHint = null;
      _pendingHintFrames = 0;
      return;
    }
    if (immediate) {
      _pendingHint = null;
      _pendingHintFrames = 0;
      _hintNotifier.value = hint;
      return;
    }
    if (_pendingHint != hint) {
      _pendingHint = hint;
      _pendingHintFrames = 1;
      return;
    }
    _pendingHintFrames++;
    if (_pendingHintFrames >= _hintStableFrames) {
      _hintNotifier.value = hint;
      _pendingHint = null;
      _pendingHintFrames = 0;
    }
  }

  Future<void> _stopImageStream() async {
    final cam = _controller;
    if (cam != null && cam.value.isStreamingImages) {
      await cam.stopImageStream();
    }
  }

  Future<void> _onCapturePressed() async {
    final cam = _controller;
    if (cam == null || !cam.value.isInitialized || _isCapturing) return;

    final screenSize = mounted ? MediaQuery.sizeOf(context) : null;
    final previewDisplaySize =
        screenSize != null ? _ocrPreviewDisplaySize(screenSize) : null;
    if (screenSize == null || previewDisplaySize == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera preview not ready. Try again.')),
        );
      }
      return;
    }

    _isCapturing = true;
    _capturingUi.value = true;
    _applyHint(PassportScanHint.scanning, immediate: true);

    try {
      if (!mounted) return;
      await _capturePlaceholderAndMrzThenNavigate(
        screenSize: screenSize,
        previewDisplaySize: previewDisplaySize,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not capture photo. Please try again.'),
        ),
      );
      _endCaptureUi();
    }
  }

  Future<void> _onPreviewTapDown(TapDownDetails details) async {
    final cam = _controller;
    if (cam == null ||
        !cam.value.isInitialized ||
        _isCapturing ||
        _tapFocusInFlight) {
      return;
    }

    final render = context.findRenderObject();
    if (render is! RenderBox) return;
    final size = render.size;
    if (size.width <= 0 || size.height <= 0) return;

    final local = details.localPosition;
    final dx = (local.dx / size.width).clamp(0.0, 1.0);
    final dy = (local.dy / size.height).clamp(0.0, 1.0);
    final tapPoint = Offset(dx, dy);

    _tapFocusInFlight = true;
    try {
      try {
        await cam.setFocusMode(FocusMode.auto);
        await cam.setFocusPoint(tapPoint);
        await cam.setExposurePoint(tapPoint);
        _lastTapFocusPoint = tapPoint;
      } catch (_) {
        // Device may not support tap focus/exposure points.
      }

      // Give autofocus a bit more time to settle at close distance.
      await Future<void>.delayed(const Duration(milliseconds: 380));
      if (!mounted || _isCapturing) return;
      await _onCapturePressed();
    } finally {
      _tapFocusInFlight = false;
    }
  }


  void _resetOcrCaptureState() {
    _fullPassportImage = null;
    _mrzCroppedImage = null;
  }

  // --- NEW OCR IMPLEMENTATION ---
  Size? _ocrPreviewDisplaySize(Size screenSize) {
    final cam = _controller;
    if (cam == null || !cam.value.isInitialized || !mounted) return null;
    return PassportGuideLayout.previewDisplaySize(
      screenSize: screenSize,
      cameraAspectRatio: cam.value.aspectRatio,
      isPortrait: MediaQuery.orientationOf(context) == Orientation.portrait,
    );
  }

  /// Placeholder + MRZ band crop, OCR parse, then confirmation (no verify dialog).
  Future<void> _capturePlaceholderAndMrzThenNavigate({
    required Size screenSize,
    required Size previewDisplaySize,
  }) async {
    final cam = _controller;
    if (cam == null || !cam.value.isInitialized) {
      _endCaptureUi();
      return;
    }

    _pausePreviewDuringCapture();
    await Future<void>.delayed(Duration.zero);

    late final XFile shot;
    try {
      try {
        await cam.setFocusMode(FocusMode.auto);
        final focusPoint = _lastTapFocusPoint ?? const Offset(0.5, 0.5);
        await cam.setFocusPoint(focusPoint);
        await cam.setExposurePoint(focusPoint);
        await Future<void>.delayed(
          Duration(milliseconds: _lastTapFocusPoint != null ? 320 : 150),
        );
      } catch (_) {}
      shot = await cam.takePicture();
      try {
        await cam.setFocusMode(FocusMode.auto);
        await cam.setExposureMode(ExposureMode.auto);
      } catch (_) {}
      _lastTapFocusPoint = null;
    } catch (_) {
      _endCaptureUi();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not capture photo. Try again.')),
        );
      }
      return;
    }

    final docs = await getApplicationDocumentsDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;

    final processResult = await processPassportCaptureOffMain(
      CaptureProcessRequest(
        sourceImagePath: shot.path,
        placeholderOutputPath: '${docs.path}/passport_placeholder_$ts.jpg',
        mrzOutputPath: '${docs.path}/passport_mrz_$ts.jpg',
        screenWidth: screenSize.width,
        screenHeight: screenSize.height,
        previewDisplayWidth: previewDisplaySize.width,
        previewDisplayHeight: previewDisplaySize.height,
      ),
    );

    try {
      await File(shot.path).delete();
    } catch (_) {}

    if (!processResult.ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not crop passport image. Align the page in the frame and try again.',
            ),
          ),
        );
      }
      _endCaptureUi();
      return;
    }

    if (!mounted) return;
    _fullPassportImage = File(processResult.placeholderPath!);
    _mrzCroppedImage = File(processResult.mrzPath!);
    await _extractMrzAndNavigateToConfirmation(docs);
  }

  // --- NEW OCR IMPLEMENTATION ---
  Future<void> _extractMrzAndNavigateToConfirmation(Directory docs) async {
    final mrzImage = _mrzCroppedImage;
    final passportImage = _fullPassportImage;
    if (mrzImage == null || passportImage == null) return;

    try {
      final parsed = await _parseMrzFromCroppedImage(mrzImage);
      if (parsed == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Could not read passport details. Align the MRZ lines and try again.',
              ),
            ),
          );
        }
        _resetOcrCaptureState();
        _endCaptureUi();
        return;
      }

      File? croppedFace;
      if (widget.config.includeFaceImage) {
        final faceOutput =
            '${docs.path}/face_${DateTime.now().millisecondsSinceEpoch}.jpg';
        croppedFace = await FaceCropper.cropFace(passportImage, faceOutput);
      }

      if (!mounted) return;
      _resetOcrCaptureState();
      _endCaptureUi(resumePreview: false);
      final success = PassportMrzCaptureSuccess(
        data: parsed,
        passportPageImage: passportImage,
        faceImage: croppedFace,
        mrzCroppedImage: widget.config.includeMrzCropInResult || kDebugMode
            ? mrzImage
            : null,
      );
      // Pop camera before onSuccess so GetX / Navigator stacks do not close the next route.
      Navigator.of(context).pop();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onSuccess(success);
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not process passport. Please try again.'),
          ),
        );
      }
      _resetOcrCaptureState();
      _endCaptureUi();
    }
  }

  Future<PassportMrzParsedData?> _parseMrzFromCroppedImage(
      File mrzImage) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final recognizedText = await recognizer.processImage(
        InputImage.fromFilePath(mrzImage.path),
      );
      final rawMRZText = recognizedText.text;
      debugPrint('[OCR MRZ] raw OCR text:\n$rawMRZText');

      var parsed = MRZParser.parse(rawMRZText);
      parsed ??= MRZParser.parseForOcr(rawMRZText);
      if (parsed == null) {
        debugPrint(
          '[OCR MRZ] parse failed (strict + OCR fallback), length=${rawMRZText.length}',
        );
      } else {
        debugPrint('[OCR MRZ] L1: ${parsed.mrzLine1}');
        debugPrint('[OCR MRZ] L2: ${parsed.mrzLine2}');
      }
      return parsed;
    } finally {
      await recognizer.close();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _hintNotifier.dispose();
    _capturingUi.dispose();
    unawaited(_stopImageStream());
    _controller?.dispose();
    super.dispose();
  }

  /// Sizes preview at native resolution to avoid upscaled/blurry letterboxing.
  Widget _buildCameraPreview(CameraController cam) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final previewSize = cam.value.previewSize;
        if (previewSize == null) {
          return Center(child: CameraPreview(cam));
        }

        final isPortrait =
            MediaQuery.orientationOf(context) == Orientation.portrait;
        final previewW =
            isPortrait ? previewSize.height : previewSize.width;
        final previewH =
            isPortrait ? previewSize.width : previewSize.height;

        return ClipRect(
          child: OverflowBox(
            alignment: Alignment.center,
            maxWidth: constraints.maxWidth,
            maxHeight: constraints.maxHeight,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: previewW,
                height: previewH,
                child: CameraPreview(cam),
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _iconForHint(PassportScanHint hint) {
    switch (hint) {
      case PassportScanHint.moveCloser:
        return Icons.zoom_in_rounded;
      case PassportScanHint.alignMrz:
        return Icons.swap_vert_rounded;
      case PassportScanHint.poorLighting:
        return Icons.wb_sunny_outlined;
      case PassportScanHint.outOfFocus:
        return Icons.blur_on_rounded;
      case PassportScanHint.holdSteady:
        return Icons.check_circle_outline_rounded;
      default:
        return Icons.credit_card_rounded;
    }
  }

  bool _showTopBanner(PassportScanHint hint) {
    return hint == PassportScanHint.moveCloser ||
        hint == PassportScanHint.alignMrz ||
        hint == PassportScanHint.poorLighting ||
        hint == PassportScanHint.outOfFocus;
  }

  Widget _instructionBanner(BuildContext context, PassportScanHint hint) {
    final isUrgent = _showTopBanner(hint);
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: hint.borderColor.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hint.borderColor.withValues(alpha: 0.85),
            width: isUrgent ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _iconForHint(hint),
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                hint.message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid) {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      );
    }

    final captureBg = widget.config.captureButtonColor ?? Colors.white;
    final captureIcon = widget.config.captureIconColor ?? Colors.black87;

    return PopScope(
      canPop: !_isCapturing,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        widget.onFailure(
          const PassportMrzCaptureFailure(
            code: PassportMrzCaptureErrorCode.cancelled,
            message: 'Capture cancelled',
          ),
        );
        Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _initializing
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : _initError != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _initError == 'camera_permission'
                            ? 'Camera permission is required for this step.'
                            : 'Could not start the camera.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_controller != null &&
                          _controller!.value.isInitialized)
                        RepaintBoundary(
                          child: _buildCameraPreview(_controller!),
                        ),
                      Positioned.fill(
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTapDown: _onPreviewTapDown,
                        ),
                      ),
                      ValueListenableBuilder<PassportScanHint>(
                        valueListenable: _hintNotifier,
                        builder: (context, hint, _) {
                          return AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, _) {
                              return RepaintBoundary(
                                child: CustomPaint(
                                  painter: PassportGuideOverlayPainter(
                                    hint: hint,
                                    pulse: hint == PassportScanHint.moveCloser
                                        ? _pulseController.value
                                        : 0,
                                    mrzPulse: _pulseController.value,
                                  ),
                                  child: const SizedBox.expand(),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      Positioned(
                        top: 84,
                        left: 20,
                        right: 20,
                        child: ValueListenableBuilder<PassportScanHint>(
                          valueListenable: _hintNotifier,
                          builder: (context, hint, _) {
                            if (_isCapturing || !_showTopBanner(hint)) {
                              return const SizedBox.shrink();
                            }
                            return _instructionBanner(context, hint);
                          },
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                          child: ValueListenableBuilder<bool>(
                            valueListenable: _capturingUi,
                            builder: (context, capturing, _) {
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (capturing)
                                    const Padding(
                                      padding: EdgeInsets.only(bottom: 12),
                                      child: SizedBox(
                                        width: 28,
                                        height: 28,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ),
                                  ValueListenableBuilder<PassportScanHint>(
                                    valueListenable: _hintNotifier,
                                    builder: (context, hint, _) {
                                      return Text(
                                        capturing
                                            ? PassportScanHint
                                                .scanning.message
                                            : hint.message,
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500,
                                              height: 1.35,
                                            ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  Material(
                                    color: capturing
                                        ? Colors.white38
                                        : captureBg,
                                    shape: const CircleBorder(),
                                    child: InkWell(
                                      customBorder: const CircleBorder(),
                                      onTap: capturing
                                          ? null
                                          : _onCapturePressed,
                                      child: Padding(
                                        padding: const EdgeInsets.all(18),
                                        child: Icon(
                                          Icons.camera_alt_rounded,
                                          size: 40,
                                          color: capturing
                                              ? Colors.white54
                                              : captureIcon,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
