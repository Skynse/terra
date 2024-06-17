import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:developer';
import 'dart:io';
import 'dart:isolate';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart';
import 'package:tflite_flutter/tflite_flutter_platform_interface.dart';

import 'isolate_inference.dart';

class ImageClassificationHelper {
  static const modelPath = 'assets/model_quant.tflite';
  static const labelsPath = 'assets/labels.txt';

  late final Interpreter interpreter;
  late final List<String> labels;
  late final IsolateInference isolateInference;
  late Tensor inputTensor;
  late Tensor outputTensor;

  // Load model
  Future<void> _loadModel() async {
    final options = InterpreterOptions();

    // Use XNNPACK Delegate
    if (Platform.isAndroid) {
      options.addDelegate(XNNPackDelegate());
    }

    // Use Metal Delegate
    if (Platform.isIOS) {
      options.addDelegate(XNNPackDelegate());
    }
    // Load model from assets
    interpreter =
        await Interpreter.fromAsset(modelPath, options: options..threads = 4);
    inputTensor = interpreter.getInputTensors().first;
    outputTensor = interpreter.getOutputTensors().first;

    log('Interpreter loaded successfully');
  }

  // Load labels from assets
  Future<void> _loadLabels() async {
    final labelTxt = await rootBundle.loadString(labelsPath);
    // input data looks like 0 positive. only use the label

    labels = labelTxt.split('\n').map((label) {
      return label.substring(label.indexOf(' ') + 1);
    }).toList();
  }

  Future<void> initHelper() async {
    _loadLabels();
    _loadModel();
    isolateInference = IsolateInference();
    await isolateInference.start();
  }

  Future<Map<String, double>> _inference(InferenceModel inferenceModel) async {
    ReceivePort responsePort = ReceivePort();
    isolateInference.sendPort
        .send(inferenceModel..responsePort = responsePort.sendPort);
    // get inference result.
    var results = await responsePort.first;
    return results;
  }

  // inference camera frame
  Future<Map<String, double>> inferenceCameraFrame(
      CameraImage cameraImage) async {
    var isolateModel = InferenceModel(cameraImage, null, interpreter.address,
        labels, inputTensor.shape, outputTensor.shape);

    return _inference(isolateModel);
  }

  // inference still image
  Future<Map<String, double>> inferenceImage(Image image) async {
    var isolateModel = InferenceModel(null, image, interpreter.address, labels,
        inputTensor.shape, outputTensor.shape);
    return _inference(isolateModel);
  }

  Future<void> close() async {
    isolateInference.close();
  }
}
