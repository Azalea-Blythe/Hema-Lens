import 'dart:io';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import '../services/inference_service.dart';

// ─── Quality-only thresholds (no anatomy detection) ─────────────────────────
const double _kDarkThreshold   = 35.0;   // mean luminance below → too dark
const double _kBrightThreshold = 225.0;  // mean luminance above → overexposed
const double _kBlurThreshold   = 80.0;   // luminance variance below → blurry

// ─── UI colour palette ──────────────────────────────────────────────────────
const Color _kBgDark      = Color(0xFF0D1117);   // deep charcoal background
const Color _kSurface     = Color(0xFF161B22);   // slightly lighter surface
const Color _kTeal        = Color(0xFF2DD4BF);   // vibrant teal accent
const Color _kTealDim     = Color(0xFF134E4A);   // muted teal for backgrounds
const Color _kAmber       = Color(0xFFFBBF24);   // warm amber for warnings
const Color _kSuccess     = Color(0xFF34D399);   // minty green for success
const Color _kSuccessDim  = Color(0xFF065F46);   // dark green surface
const Color _kTextPrimary = Color(0xFFF0F6FC);   // bright white text
const Color _kTextMuted   = Color(0xFF8B949E);   // muted grey text

class CaptureScreen extends StatefulWidget {
  final String scanTarget; // 'conjunctiva' or 'fingernail'
  const CaptureScreen({super.key, required this.scanTarget});
  @override State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _controller;
  bool _initializing = true, _processing = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      _controller = CameraController(
          cameras.first, ResolutionPreset.high, enableAudio: false);
      await _controller!.initialize();
    } catch (_) {}
    if (mounted) setState(() => _initializing = false);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  QUALITY GATE — brightness & sharpness only (no anatomy detection)
  // ═══════════════════════════════════════════════════════════════════════════

  Future<String?> _validatePhoto(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return 'Could not decode the image. Please try again.';

    final cx = decoded.width  ~/ 2;
    final cy = decoded.height ~/ 2;
    const half = 80;
    final List<double> lumVals = [];

    for (int y = (cy - half).clamp(0, decoded.height - 1);
         y < (cy + half).clamp(0, decoded.height);
         y++) {
      for (int x = (cx - half).clamp(0, decoded.width - 1);
           x < (cx + half).clamp(0, decoded.width);
           x++) {
        final px = decoded.getPixelSafe(x, y);
        lumVals.add(0.299 * px.r.toDouble() +
                    0.587 * px.g.toDouble() +
                    0.114 * px.b.toDouble());
      }
    }

    if (lumVals.isEmpty) return 'Could not analyse image.';
    final n = lumVals.length.toDouble();
    final meanLum  = lumVals.reduce((a, b) => a + b) / n;
    final variance = lumVals.fold<double>(0, (acc, v) => acc + pow(v - meanLum, 2)) / n;

    if (meanLum < _kDarkThreshold) {
      return 'Image is too dark.\nMove to a well-lit area — natural daylight works best.';
    }
    if (meanLum > _kBrightThreshold) {
      return 'Image is overexposed.\nAvoid pointing the camera at a bright light source.';
    }
    if (variance < _kBlurThreshold) {
      return 'Image is too blurry.\nHold the camera still and bring it closer to the target.';
    }

    return null; // ✅ All quality checks passed
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  CAPTURE → VALIDATE → CONFIRM → INFER
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _captureAndCheck() async {
    if (_controller == null || !_controller!.value.isInitialized || _processing) return;
    setState(() => _processing = true);

    try {
      final xFile     = await _controller!.takePicture();
      final imageFile = File(xFile.path);

      final rejection = await _validatePhoto(imageFile);
      if (!mounted) return;

      if (rejection != null) {
        setState(() => _processing = false);
        _showRejection(rejection);
        return;
      }

      // Quality OK — show confirmation
      setState(() => _processing = false);
      final confirmed = await _showConfirmation(imageFile);
      if (!mounted) return;
      if (confirmed != true) return; // retake

      // User confirmed — run inference
      setState(() => _processing = true);
      final service = InferenceService();
      await service.loadModel(widget.scanTarget);
      final probs = await service.runInference(imageFile);
      service.dispose();
      if (mounted) Navigator.pop(context, probs);
    } catch (e) {
      if (mounted) {
        setState(() => _processing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red.shade700,
        ));
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  PICK FROM GALLERY → VALIDATE → CONFIRM → INFER
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _pickFromGallery() async {
    if (_processing) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return; // user cancelled

    final imageFile = File(picked.path);
    setState(() => _processing = true);

    try {
      final rejection = await _validatePhoto(imageFile);
      if (!mounted) return;

      if (rejection != null) {
        setState(() => _processing = false);
        _showRejection(rejection);
        return;
      }

      setState(() => _processing = false);
      final confirmed = await _showConfirmation(imageFile);
      if (!mounted) return;
      if (confirmed != true) return;

      setState(() => _processing = true);
      final service = InferenceService();
      await service.loadModel(widget.scanTarget);
      final probs = await service.runInference(imageFile);
      service.dispose();
      if (mounted) Navigator.pop(context, probs);
    } catch (e) {
      if (mounted) {
        setState(() => _processing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red.shade700,
        ));
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  PHOTO CONFIRMATION DIALOG
  // ═══════════════════════════════════════════════════════════════════════════

  Future<bool?> _showConfirmation(File imageFile) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        child: Container(
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: _kSuccess.withValues(alpha: 0.3), width: 1.5),
            boxShadow: [
              BoxShadow(color: _kSuccess.withValues(alpha: 0.08), blurRadius: 40, spreadRadius: 8),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ──────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_kSuccessDim, _kSuccessDim.withValues(alpha: 0.6)],
                  ),
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _kSuccess.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.check_circle_rounded, color: _kSuccess, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text('Photo looks good!',
                    style: TextStyle(color: _kTextPrimary, fontWeight: FontWeight.bold, fontSize: 17)),
                ]),
              ),

              // ── Image preview ───────────────────────────────────────
              Container(
                margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Image.file(imageFile, fit: BoxFit.cover, width: double.infinity),
                ),
              ),

              // ── Quality badges ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Row(children: [
                  _qualityBadge(Icons.wb_sunny_rounded, 'Lighting', _kSuccess),
                  const SizedBox(width: 8),
                  _qualityBadge(Icons.center_focus_strong_rounded, 'Sharpness', _kSuccess),
                  const SizedBox(width: 8),
                  _qualityBadge(Icons.verified_rounded, 'Ready', _kTeal),
                ]),
              ),

              // ── Buttons ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
                child: Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kTextMuted,
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.replay_rounded, size: 18),
                      label: const Text('Retake'),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kTeal,
                        foregroundColor: _kBgDark,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 6,
                        shadowColor: _kTeal.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.check_rounded, size: 20),
                      label: const Text('Use Photo',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      onPressed: () => Navigator.pop(context, true),
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _qualityBadge(IconData icon, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Text(label,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  REJECTION DIALOG
  // ═══════════════════════════════════════════════════════════════════════════

  void _showRejection(String message) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _kAmber.withValues(alpha: 0.3), width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _kAmber.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_amber_rounded, color: _kAmber, size: 36),
              ),
              const SizedBox(height: 16),
              const Text('Photo Rejected',
                style: TextStyle(color: _kTextPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 12),
              Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _kTextMuted, height: 1.6, fontSize: 14)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kAmber,
                    foregroundColor: _kBgDark,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.camera_alt_rounded),
                  label: const Text('Try Again',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final bool isConj = widget.scanTarget == 'conjunctiva';
    final String title = isConj ? 'Scan Conjunctiva' : 'Scan Nailbed';
    final String hint  = isConj
        ? 'Pull down your lower eyelid and align the pink inner surface in the frame.'
        : 'Hold your fingernail flat and align the nailbed in the frame.';
    final IconData hintIcon = isConj ? Icons.remove_red_eye_outlined : Icons.back_hand_outlined;

    return Scaffold(
      backgroundColor: _kBgDark,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
        backgroundColor: Colors.transparent,
        foregroundColor: _kTextPrimary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.close_rounded, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _initializing
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 48, height: 48,
                    child: CircularProgressIndicator(
                      strokeWidth: 3, color: _kTeal,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Starting camera…',
                    style: TextStyle(color: _kTextMuted, fontSize: 14)),
                ],
              ),
            )
          : Stack(
              alignment: Alignment.center,
              children: [
                // ── Camera preview ─────────────────────────────────
                if (_controller != null && _controller!.value.isInitialized)
                  SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _controller!.value.previewSize?.height ?? 1,
                        height: _controller!.value.previewSize?.width ?? 1,
                        child: CameraPreview(_controller!),
                      ),
                    ),
                  )
                else
                  Container(color: _kBgDark),

                // ── Overlay with animated focus frame ──────────────
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (_, child) => CustomPaint(
                      painter: _OverlayPainter(
                        pulseValue: _pulseController.value,
                        accentColor: _kTeal,
                      ),
                    ),
                  ),
                ),

                // ── Top target badge ──────────────────────────────
                Positioned(
                  top: MediaQuery.of(context).padding.top + 56,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _kTealDim.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _kTeal.withValues(alpha: 0.4)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(isConj
                          ? Icons.visibility_rounded
                          : Icons.fingerprint_rounded,
                          color: _kTeal, size: 16),
                      const SizedBox(width: 8),
                      Text(isConj ? 'Conjunctiva Mode' : 'Nailbed Mode',
                        style: const TextStyle(color: _kTeal, fontSize: 12,
                            fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                    ]),
                  ),
                ),

                // ── Hint card ─────────────────────────────────────
                Positioned(
                  bottom: 130,
                  left: 20, right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _kSurface.withValues(alpha: 0.92),
                          _kBgDark.withValues(alpha: 0.92),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _kTeal.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(hintIcon, color: _kTeal, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(hint,
                          style: const TextStyle(color: _kTextPrimary, fontSize: 13,
                              height: 1.45, fontWeight: FontWeight.w500)),
                      ),
                    ]),
                  ),
                ),

                // ── Processing overlay ────────────────────────────
                if (_processing)
                  Container(
                    color: _kBgDark.withValues(alpha: 0.85),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 52, height: 52,
                            child: CircularProgressIndicator(
                              strokeWidth: 3, color: _kTeal,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text('Checking quality…',
                            style: TextStyle(color: _kTextPrimary, fontSize: 16,
                                fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          const Text('Analysing brightness & sharpness',
                            style: TextStyle(color: _kTextMuted, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

      // ── Bottom controls: gallery + shutter ─────────────────────
      floatingActionButton: _initializing || _processing
          ? null
          : _buildBottomControls(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildBottomControls() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ── Gallery button ────────────────────────────────────────
        Tooltip(
          message: 'Pick from gallery',
          child: GestureDetector(
            onTap: _pickFromGallery,
            child: Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kSurface,
                border: Border.all(
                    color: _kTeal.withValues(alpha: 0.55), width: 2),
                boxShadow: [
                  BoxShadow(
                      color: _kTeal.withValues(alpha: 0.15),
                      blurRadius: 14,
                      spreadRadius: 1),
                ],
              ),
              child: const Icon(Icons.photo_library_rounded,
                  color: _kTeal, size: 24),
            ),
          ),
        ),

        const SizedBox(width: 28),

        // ── Shutter button ────────────────────────────────────────
        GestureDetector(
          onTap: _captureAndCheck,
          child: Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _kTeal, width: 3.5),
              boxShadow: [
                BoxShadow(
                    color: _kTeal.withValues(alpha: 0.25),
                    blurRadius: 20,
                    spreadRadius: 2),
              ],
            ),
            child: Center(
              child: Container(
                width: 62, height: 62,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_kTeal, Color(0xFF06B6D4)],
                  ),
                ),
                child: const Icon(Icons.camera_alt_rounded,
                    color: _kBgDark, size: 28),
              ),
            ),
          ),
        ),

        // ── Spacer to visually balance the row ────────────────────
        const SizedBox(width: 84), // mirrors gallery button width + gap
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  OVERLAY PAINTER — animated focus brackets
// ═══════════════════════════════════════════════════════════════════════════════

class _OverlayPainter extends CustomPainter {
  final double pulseValue; // 0.0 – 1.0
  final Color accentColor;

  _OverlayPainter({required this.pulseValue, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    // Semi-transparent overlay outside focus area
    final bgPaint = Paint()..color = const Color(0xFF0D1117).withValues(alpha: 0.65);
    final bgPath  = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final center  = Offset(size.width / 2, size.height / 2 - 40);
    final focusRect = Rect.fromCenter(
        center: center, width: size.width * 0.78, height: size.height * 0.42);
    final focusPath = Path()
      ..addRRect(RRect.fromRectAndRadius(focusRect, const Radius.circular(20)));
    canvas.drawPath(
        Path.combine(PathOperation.difference, bgPath, focusPath), bgPaint);

    // Animated bracket opacity
    final alpha = 0.55 + 0.45 * pulseValue;

    final bracketPaint = Paint()
      ..color = accentColor.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    const double len = 32;
    final r = focusRect;

    // Top-left
    canvas.drawLine(Offset(r.left, r.top + len), Offset(r.left, r.top), bracketPaint);
    canvas.drawLine(Offset(r.left, r.top), Offset(r.left + len, r.top), bracketPaint);
    // Top-right
    canvas.drawLine(Offset(r.right - len, r.top), Offset(r.right, r.top), bracketPaint);
    canvas.drawLine(Offset(r.right, r.top), Offset(r.right, r.top + len), bracketPaint);
    // Bottom-left
    canvas.drawLine(Offset(r.left, r.bottom - len), Offset(r.left, r.bottom), bracketPaint);
    canvas.drawLine(Offset(r.left, r.bottom), Offset(r.left + len, r.bottom), bracketPaint);
    // Bottom-right
    canvas.drawLine(Offset(r.right - len, r.bottom), Offset(r.right, r.bottom), bracketPaint);
    canvas.drawLine(Offset(r.right, r.bottom), Offset(r.right, r.bottom - len), bracketPaint);
  }

  @override
  bool shouldRepaint(_OverlayPainter old) => old.pulseValue != pulseValue;
}
