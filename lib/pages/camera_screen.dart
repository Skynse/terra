import 'dart:developer';
import 'dart:ffi';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraScreen extends StatefulWidget {
  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _imageBytes;
  bool _isProcessing = false;
  List<Map<String, dynamic>> classificationOutput = []; // Store prediction data

  Future<void> _pickImage(ImageSource source) async {
    final XFile? imageFile = await _picker.pickImage(source: source);
    if (imageFile != null) {
      if (source == ImageSource.camera) {
        final image = File(imageFile.path);

        // save to gallery
        final appDir = await getExternalStorageDirectory();
        final fileName = imageFile.path.split('/').last;
        final savedImage = await image.copy('${appDir!.path}/$fileName');
        log('Image saved to gallery: ${savedImage.path}');
      }
      setState(() {
        _isProcessing = true;
        _imageBytes = imageFile;
      });
      File image = File(imageFile.path);
      List<Map<String, dynamic>>? classification =
          await _sendImageToServer(image);
      setState(() {
        _isProcessing = false;
        classificationOutput = classification ?? [];
      });
    }
  }

  Future<List<Map<String, dynamic>>?> _sendImageToServer(File image) async {
    final uri = Uri.parse("https://skynse.pythonanywhere.com/predict");
    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('image', image.path));

    request.headers.addAll({
      'Content-Type': 'multipart/form-data',
    });

    final response = await request.send();
    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final Map<String, dynamic> jsonResponse = json.decode(responseBody);
      if (jsonResponse['success']) {
        return List<Map<String, dynamic>>.from(jsonResponse['predictions']);
      }
    } else {
      // Handle error
      log('Server error: ${response.statusCode}');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Padding(
          padding: EdgeInsets.only(top: 20),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: _isProcessing
                      ? CircularProgressIndicator()
                      : classificationOutput.isNotEmpty
                          ? Image.file(File(_imageBytes!.path))
                          : Text("Select an image to analyze"),
                ),
              ),
              SizedBox(
                height: 200,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            IconButton(
                              onPressed: () async {
                                if (await Permission.photos
                                    .request()
                                    .isGranted) {
                                  await _pickImage(ImageSource.gallery);
                                }
                              },
                              icon: Icon(Icons.photo),
                            ),
                            InkWell(
                              borderRadius: BorderRadius.circular(80),
                              onTap: () async {
                                // Request camera permission
                                if (await Permission.camera
                                    .request()
                                    .isGranted) {
                                  await _pickImage(ImageSource.camera);
                                }
                              },
                              child: const Stack(
                                alignment: Alignment.center,
                                children: [
                                  Icon(Icons.circle,
                                      size: 80, color: Colors.grey),
                                  Icon(Icons.circle,
                                      size: 70, color: Colors.white),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Expanded(
                          child: classificationOutput.isNotEmpty
                              ? ListView.builder(
                                  itemCount: classificationOutput.length,
                                  itemBuilder: (context, index) {
                                    Map<String, dynamic> prediction =
                                        classificationOutput[index];
                                    return ListTile(
                                      title: Text(prediction['label']),
                                      subtitle: Text(prediction['probability']
                                          .toStringAsFixed(2)),
                                    );
                                  },
                                )
                              : Center(
                                  child: Text("No predictions to show"),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
