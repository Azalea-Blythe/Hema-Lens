import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../services/inference_service.dart';

class CaptureScreen extends StatefulWidget {
  final String scanTarget; // 'conjunctiva' or 'fingernail'
  const CaptureScreen({super.key, required this.scanTarget});
  @override State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  CameraController? _controller;
  bool _initializing = true, _processing = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    _controller = CameraController(cameras.first, ResolutionPreset.high);
    await _controller!.initialize();
    if (mounted) setState(() => _initializing = false);
  }

  Future<void> _capture() async {
    if (_controller == null || _processing) return;
    setState(() => _processing = true);

    try {
      final xFile = await _controller!.takePicture();
      final imageFile = File(xFile.path);

      final service = InferenceService();
      await service.loadModel(widget.scanTarget);
      final probs = await service.runInference(imageFile);
      service.dispose();

      if (mounted) {
        // Pop back to HomeScreen, passing the probabilities
        Navigator.pop(context, probs);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _processing = false);
      }
    }
  }

  @override
  void dispose() { 
    _controller?.dispose(); 
    super.dispose(); 
  }

  @override
  Widget build(BuildContext context) {
    final bool isConjunctiva = widget.scanTarget == 'conjunctiva';
    final String title = isConjunctiva ? 'Scan Conjunctiva' : 'Scan Nailbed';
    final String hint = isConjunctiva 
      ? 'Pull down your lower eyelid and align the inner pink area within the frame.'
      : 'Hold your fingernail flat facing the camera and align it within the frame.';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _initializing
        ? const Center(child: CircularProgressIndicator(color: Colors.white))
        : Stack(
            alignment: Alignment.center,
            children: [
              // Camera fill
              SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller!.value.previewSize?.height ?? 1,
                    height: _controller!.value.previewSize?.width ?? 1,
                    child: CameraPreview(_controller!),
                  ),
                ),
              ),
              
              // Dark overlay with oval cutout
              Positioned.fill(
                child: CustomPaint(painter: _OverlayPainter()),
              ),
              
              // Hint text at the bottom
              Positioned(
                bottom: 120,
                left: 24, right: 24,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(isConjunctiva ? Icons.remove_red_eye : Icons.back_hand, color: Colors.white, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          hint,
                          style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Processing indicator
              if (_processing)
                Container(
                  color: Colors.black54,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 16),
                        Text('Analyzing...', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
      floatingActionButton: _initializing || _processing ? null : SizedBox(
        width: 72, height: 72,
        child: FloatingActionButton(
          backgroundColor: Colors.white,
          elevation: 8,
          shape: const CircleBorder(),
          onPressed: _capture,
          child: Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 2),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class _OverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = Colors.black.withOpacity(0.6);
    
    final bgPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    
    final center = Offset(size.width / 2, size.height / 2 - 40);
    final focusRect = Rect.fromCenter(center: center, width: size.width * 0.75, height: size.height * 0.45);
    final focusRRect = RRect.fromRectAndRadius(focusRect, const Radius.circular(24));
    final focusPath = Path()..addRRect(focusRRect);
    
    // Use PathOperation.difference to punch the hole without BlendMode.clear (fixes black hole bug on some devices)
    final maskPath = Path.combine(PathOperation.difference, bgPath, focusPath);
    canvas.drawPath(maskPath, bgPaint);
    
    // Draw corner brackets around the focus area (no solid white line)
    final bracketPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
      
    const double len = 30;
    
    // Top Left
    canvas.drawLine(Offset(focusRect.left, focusRect.top + len), Offset(focusRect.left, focusRect.top), bracketPaint);
    canvas.drawLine(Offset(focusRect.left, focusRect.top), Offset(focusRect.left + len, focusRect.top), bracketPaint);
    
    // Top Right
    canvas.drawLine(Offset(focusRect.right - len, focusRect.top), Offset(focusRect.right, focusRect.top), bracketPaint);
    canvas.drawLine(Offset(focusRect.right, focusRect.top), Offset(focusRect.right, focusRect.top + len), bracketPaint);
    
    // Bottom Left
    canvas.drawLine(Offset(focusRect.left, focusRect.bottom - len), Offset(focusRect.left, focusRect.bottom), bracketPaint);
    canvas.drawLine(Offset(focusRect.left, focusRect.bottom), Offset(focusRect.left + len, focusRect.bottom), bracketPaint);
    
    // Bottom Right
    canvas.drawLine(Offset(focusRect.right - len, focusRect.bottom), Offset(focusRect.right, focusRect.bottom), bracketPaint);
    canvas.drawLine(Offset(focusRect.right, focusRect.bottom), Offset(focusRect.right, focusRect.bottom - len), bracketPaint);
  }

  @override bool shouldRepaint(_) => false;
}
