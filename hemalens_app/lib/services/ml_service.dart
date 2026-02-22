import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../models/scan_result.dart';

class MlService {
  static const int _inputSize = 224;

  // Cache loaded interpreters to avoid reloading on each inference
  static final Map<String, Interpreter> _interpreters = {};

  static Future<Interpreter> _loadInterpreter(String modality) async {
    if (_interpreters.containsKey(modality)) {
      return _interpreters[modality]!;
    }
    final assetPath = 'assets/models/${modality}_model.tflite';
    final interpreter = await Interpreter.fromAsset(assetPath);
    _interpreters[modality] = interpreter;
    return interpreter;
  }

  /// Run inference on [imageFile] using the model for [modality].
  /// [modality] must be one of: 'conjunctiva', 'fingernail', 'palm'
  /// Returns ImageProbs with softmax probabilities.
  static Future<ImageProbs> runInference(
    File imageFile,
    String modality,
  ) async {
    final interpreter = await _loadInterpreter(modality);

    // Decode and preprocess image
    final rawBytes = await imageFile.readAsBytes();
    img.Image? decoded = img.decodeImage(rawBytes);
    if (decoded == null) throw Exception('Failed to decode image');

    // Resize to 224x224
    final resized = img.copyResize(
      decoded,
      width: _inputSize,
      height: _inputSize,
    );

    // Build input tensor [1, 224, 224, 3] normalized to [0, 1]
    final input = List.generate(
      1,
      (_) => List.generate(
        _inputSize,
        (y) => List.generate(_inputSize, (x) {
          final pixel = resized.getPixel(x, y);
          return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
        }),
      ),
    );

    // Output tensor [1, 3] — three class probabilities
    final output = List.generate(1, (_) => List.filled(3, 0.0));

    interpreter.run(input, output);

    final probs = output[0];
    return ImageProbs(
      low: probs[0],
      moderate: probs[1],
      high: probs[2],
      modality: modality,
    );
  }

  static void dispose() {
    for (final interp in _interpreters.values) {
      interp.close();
    }
    _interpreters.clear();
  }
}
