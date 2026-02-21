import 'dart:io';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class InferenceService {
  Interpreter? _interpreter;

  // Call this once to load the model before running inference
  Future<void> loadModel(String scanType) async {
    final modelPath = 'assets/models/${scanType}_model.tflite';
    _interpreter = await Interpreter.fromAsset(modelPath);
  }

  // Takes an image file, preprocesses it, runs the model, returns [low, mod, high]
  Future<List<double>> runInference(File imageFile) async {
    if (_interpreter == null) throw Exception('Model not loaded.');

    // Step 1: Read and decode the image
    final rawBytes = await imageFile.readAsBytes();
    img.Image? image = img.decodeImage(rawBytes);
    if (image == null) throw Exception('Could not decode image.');

    // Step 2: Resize to 224x224 (required by MobileNetV2)
    image = img.copyResize(image, width: 224, height: 224);

    // Step 3: Convert pixels to a float32 tensor normalized [0,1]
    // Shape: [1, 224, 224, 3]  (batch=1, height, width, RGB channels)
    var input = List.generate(1, (_) =>
      List.generate(224, (y) =>
        List.generate(224, (x) {
          final pixel = image!.getPixel(x, y);
          return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
        })
      )
    );

    // Step 4: Prepare an output buffer — 3 probability values
    var output = List.filled(1 * 3, 0.0).reshape([1, 3]);

    // Step 5: Run the model!
    _interpreter!.run(input, output);

    // output[0] = [lowProb, modProb, highProb]
    return List<double>.from(output[0]);
  }

  void dispose() => _interpreter?.close();
}
