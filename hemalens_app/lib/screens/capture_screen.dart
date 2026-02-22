import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/scan_provider.dart';
import 'results_screen.dart';

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isBusy = false;
  String? _initError;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _initError = 'No camera found on this device.');
        return;
      }
      _controller = CameraController(
        cameras[0],
        ResolutionPreset.high,
        enableAudio: false,
      );
      await _controller!.initialize();
      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      setState(() => _initError = 'Camera error: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _takePhoto() async {
    if (_isBusy || _controller == null) return;
    setState(() => _isBusy = true);
    try {
      final xFile = await _controller!.takePicture();
      await _submit(File(xFile.path));
    } catch (e) {
      _showError('Capture failed: $e');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      final xFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (xFile != null) {
        await _submit(File(xFile.path));
      }
    } catch (e) {
      _showError('Gallery error: $e');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _submit(File imageFile) async {
    if (!mounted) return;
    final provider = context.read<ScanProvider>();
    await provider.processImage(imageFile);
    if (!mounted) return;

    if (provider.step == ScanStep.result) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ResultsScreen()),
      );
    } else if (provider.errorMessage != null) {
      _showError(provider.errorMessage!);
    }
    // else: advance to next scan step — screen rebuilds via Consumer
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: const Color(0xFFFF6B6B)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ScanProvider>(
      builder: (context, provider, _) {
        final modality = provider.currentModality;
        final stepNum = provider.currentScanNumber;
        final totalSteps = provider.totalScans;

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
            title: Text(
              _modalityTitle(modality),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
            ),
            centerTitle: true,
          ),
          body: Column(
            children: [
              // Progress
              LinearProgressIndicator(
                value: (stepNum + 1) / (totalSteps + 1),
                backgroundColor: const Color(0xFF1A1A1A),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF00D4AA)),
                minHeight: 3,
              ),
              // Step label
              Container(
                color: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Scan $stepNum of $totalSteps',
                      style: const TextStyle(
                        color: Color(0xFF00D4AA),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      _guideTarget(modality),
                      style: const TextStyle(
                        color: Color(0xFF8899AA),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Camera or error
              Expanded(
                child: _initError != null
                    ? _ErrorView(message: _initError!)
                    : !_isInitialized
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF00D4AA),
                        ),
                      )
                    : provider.step == ScanStep.processing
                    ? const _ProcessingView()
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          CameraPreview(_controller!),
                          CustomPaint(painter: _OvalPainter(modality)),
                          // Guide text
                          Positioned(
                            top: 16,
                            left: 24,
                            right: 24,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color.fromRGBO(0, 0, 0, 0.65),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _guideText(modality),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                          // Error overlay
                          if (provider.errorMessage != null)
                            Positioned(
                              top: 70,
                              left: 20,
                              right: 20,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color.fromRGBO(255, 60, 60, 0.9),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'Error: ${provider.errorMessage}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
              // Bottom controls
              if (provider.step != ScanStep.processing)
                Container(
                  color: Colors.black,
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Gallery button
                      _ControlButton(
                        icon: Icons.photo_library_rounded,
                        label: 'Gallery',
                        onTap: _isBusy ? null : _pickFromGallery,
                      ),
                      // Shutter
                      GestureDetector(
                        onTap: _isBusy ? null : _takePhoto,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(
                              color: const Color(0xFF00D4AA),
                              width: 4,
                            ),
                          ),
                          child: _isBusy
                              ? const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF00D4AA),
                                    strokeWidth: 3,
                                  ),
                                )
                              : const Icon(
                                  Icons.camera_alt_rounded,
                                  color: Color(0xFF00D4AA),
                                  size: 32,
                                ),
                        ),
                      ),
                      // Placeholder spacer
                      const SizedBox(width: 72),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _modalityTitle(String m) {
    switch (m) {
      case 'conjunctiva':
        return 'Step 1 — Conjunctiva';
      case 'fingernail':
        return 'Step 2 — Fingernails';
      case 'palm':
        return 'Step 3 — Palm';
      default:
        return 'Capture';
    }
  }

  String _guideTarget(String m) {
    switch (m) {
      case 'conjunctiva':
        return '👁 Inner lower eyelid';
      case 'fingernail':
        return '💅 Nail bed';
      case 'palm':
        return '✋ Inner palm';
      default:
        return '';
    }
  }

  String _guideText(String m) {
    switch (m) {
      case 'conjunctiva':
        return 'Gently pull your lower eyelid down. Centre the pink inner surface in the oval.';
      case 'fingernail':
        return 'Hold your fingernail flat in natural light. Centre the nailbed in the oval.';
      case 'palm':
        return 'Open your palm fully in bright light. Centre the inner palm in the oval.';
      default:
        return 'Centre the area in the oval and hold still.';
    }
  }
}

// ── Oval overlay painter ────────────────────────────────────────────────────
class _OvalPainter extends CustomPainter {
  final String modality;
  const _OvalPainter(this.modality);

  @override
  void paint(Canvas canvas, Size size) {
    final dark = Paint()..color = const Color.fromRGBO(0, 0, 0, 0.55);
    // Palm uses a wider oval; conjunctiva/fingernail a taller one
    final double ovalW = modality == 'palm'
        ? size.width * 0.80
        : size.width * 0.68;
    final double ovalH = modality == 'palm'
        ? size.height * 0.32
        : size.height * 0.40;

    final ovalRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2 - 20),
      width: ovalW,
      height: ovalH,
    );
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), dark);
    canvas.drawOval(ovalRect, Paint()..blendMode = BlendMode.clear);
    canvas.drawOval(
      ovalRect,
      Paint()
        ..color = const Color(0xFF00D4AA)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(covariant _OvalPainter old) => old.modality != modality;
}

// ── Helper widgets ──────────────────────────────────────────────────────────
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _ControlButton({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF1A2A3A),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF2A3A4A)),
            ),
            child: Icon(
              icon,
              color: onTap == null
                  ? const Color(0xFF334455)
                  : const Color(0xFF8899AA),
              size: 24,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF8899AA), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _ProcessingView extends StatelessWidget {
  const _ProcessingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF00D4AA), strokeWidth: 3),
          SizedBox(height: 20),
          Text(
            'Analysing image…',
            style: TextStyle(color: Color(0xFF8899AA), fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            'Running AI inference',
            style: TextStyle(color: Color(0xFF445566), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.camera_alt_outlined,
              color: Color(0xFF556677),
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: Color(0xFF8899AA), fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
