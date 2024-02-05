import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:terra/core/ml_service.dart';
import 'package:terra/main.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:terra/pages/gallery.dart';

class CameraScreen extends StatefulWidget {
  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? controller;
  bool cameraReady = false;

  bool isImageGood = false;
  bool _isProcessing = false;
  late ImageClassificationHelper imageClassificationHelper;
  Map<String, double>? classification;

  @override
  void dispose() {
    // TODO: implement dispose
    controller?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    controller = CameraController(cameras[0], ResolutionPreset.high);

    controller?.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        cameraReady = true;
      });

      controller?.startImageStream(analyseImage);
    });

    imageClassificationHelper = ImageClassificationHelper();
    imageClassificationHelper.initHelper();
    super.initState();
  }

  Future<void> analyseImage(CameraImage cameraImage) async {
    // if image is still analyzing, skip this frame
    if (_isProcessing) {
      return;
    }
    _isProcessing = true;
    classification =
        await imageClassificationHelper.inferenceCameraFrame(cameraImage);
    _isProcessing = false;

    if (classification != null) {
      //print("CLASSIFICATION OUTPUT:" + classification.toString());
      if (classification!.keys.contains('positive')) {
        if (classification!['positive']! > 0.8) {
          isImageGood = true;
        } else {
          isImageGood = false;
        }
      } else {
        isImageGood = false;
      }
    }
    if (mounted) {
      setState(() {});
    }
  }

  //A future is an object that holds a potential value.

  Future<XFile?> takePicture() async {
    if (controller != null || controller!.value.isInitialized) {
      // picture logio
      XFile? data =
          await controller!.takePicture(); // take picture using controller

      var file = File(data.path); //get the temporary location of the saved file
      var documentsDir = await getExternalStorageDirectories(
          type: StorageDirectory
              .pictures); // get the documents folder of the current device

      var currentTime = DateTime.now()
          .millisecondsSinceEpoch; // get the current date and time

      var format = file.path
          .split('.')
          .last; // file.png -> only get png part "png" // get the file format of the captured image

      await file.copy(
          "${documentsDir?[0].path}/$currentTime.$format"); // Documents/0904203.png //copy the image from the temporary location to the permanent one
      // in our documents folder

      // copy to documents
      print("Image saved to ${documentsDir?[0].path}/$currentTime.$format");
      return data;
    }

    print("Camera is not initialized");
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
          appBar: AppBar(
            title: Text("Camera"),
            actions: [
              IconButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const Gallery()));
                  },
                  icon: Icon(Icons.browse_gallery_outlined))
            ],
          ),
          backgroundColor: Colors.black,
          body: Padding(
            padding: EdgeInsets.only(
                bottom: 20), // add padding (space) to bottom of screen
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              width: 5,
                            ),
                          ),
                          child: (controller != null &&
                                  this
                                      .controller!
                                      .value
                                      .isInitialized) // condition to make sure the camera is initialized
                              ? CameraPreview(this.controller!)
                              : Center(child: CircularProgressIndicator())),
                      Opacity(
                        opacity: 0.7,
                        child: Container(
                          width: double.infinity,
                          height: MediaQuery.of(context).size.height - 150,
                          decoration: BoxDecoration(
                            border: Border.all(
                              width: 5,
                              color: (isImageGood) ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 100,
                  child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(80),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            InkWell(
                              // The button itself
                              borderRadius: BorderRadius.circular(80),
                              onTap: () async {
                                // ensure camera is initialized

                                try {
                                  await Permission.camera
                                      .onGrantedCallback(() async {
                                    if (controller!.value.isTakingPicture) {
                                      return;
                                    }
                                    await controller?.takePicture().then(
                                      (path) async {
                                        // save path to gallery

                                        // get the temporary location of the saved file

                                        var file = File(path.path);

                                        var documentsDir =
                                            await getExternalStorageDirectories(
                                                type: StorageDirectory
                                                    .pictures); // get the documents folder of the current device

                                        var currentTime = DateTime.now()
                                            .millisecondsSinceEpoch; // get the current date and time

                                        var format = file.path
                                            .split('.')
                                            .last; // file.png -> only get png part "png" // get the file format of the captured image

                                        await file.copy(
                                            "${documentsDir?[0].path}/$currentTime.$format"); // Documents/0904203.png //copy the image from the temporary location to the permanent one
                                        print(
                                            "Image saved to ${documentsDir?[0].path}/$currentTime.$format");
                                        // preview
                                        // print out image path
                                        if (!mounted) return;
                                      },
                                    );
                                  }).request();
                                } on CameraException catch (e) {
                                  print("Unable to initialize camera: $e");
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
                            IconButton(
                              icon: Icon(Icons.flip_camera_android_outlined),
                              onPressed: () async {
                                var currentDescription =
                                    controller!.description;
                                // ensure camera is initialized
                                try {
                                  await Permission.camera
                                      .onGrantedCallback(() async {
                                    if (currentDescription.lensDirection ==
                                        CameraLensDirection.front) {
                                      await controller?.setDescription(
                                          cameras.where((element) {
                                        return element.lensDirection ==
                                            CameraLensDirection.back;
                                      }).first);
                                    } else {
                                      await controller?.setDescription(
                                          cameras.where((element) {
                                        return element.lensDirection ==
                                            CameraLensDirection.front;
                                      }).first);
                                    }
                                  }).request();
                                } on CameraException catch (e) {
                                  print("Unable to initialize camera: $e");
                                }
                              },
                            ),
                          ],
                        ),
                      )),
                ),
              ],
            ),
          )),
    );
  }
}

Widget circle(int radius, Color color) {
  return Container(
    width: radius.toDouble(),
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
