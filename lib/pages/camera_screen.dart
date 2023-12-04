import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:terra/main.dart';
import 'package:path_provider/path_provider.dart';

class CameraScreen extends StatefulWidget {
  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? controller;
  bool cameraReady = false;

  @override
  void initState() {
    super.initState(); // initialize the state
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    updateCamera();
  }

  void updateCamera() {
    // initialize and update camera
    controller = CameraController(cameras[0], ResolutionPreset.max);
    // camera[0] is the camera description for the back camera
    try {
      controller?.initialize();
    } on CameraException catch (e) {
      print("Unable to initialize camera: $e");
    }
  }

  //A future is an object that holds a potential value.

  Future<XFile?> takePicture() async {
    if (controller != null && controller!.value.isInitialized) {
      // picture logio
      XFile? data =
          await controller!.takePicture(); // take picture using controller
      var file =
          File(data!.path); //get the temporary location of the saved file
      var documentsDir =
          await getApplicationDocumentsDirectory(); // get the documents folder of the current device
      var currentTime = DateTime.now()
          .millisecondsSinceEpoch; // get the current date and time

      var format = file.path
          .split('.')
          .last; // file.png -> only get png part "png" // get the file format of the captured image

      await file.copy(
          "${documentsDir}/$currentTime.$format"); // Documents/0904203.png //copy the image from the temporary location to the permanent one
      // in our documents folder
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        body: Padding(
          padding: EdgeInsets.only(
              bottom: 20), // add padding (space) to bottom of screen
          child: Stack(
            children: [
              Container(
                  child: (this.controller != null &&
                          this
                              .controller!
                              .value
                              .isInitialized) // condition to make sure the camera is initialized
                      ? CameraPreview(this.controller!)
                      : Center(child: CircularProgressIndicator())),
              Align(
                  alignment: Alignment.bottomCenter,
                  child: InkWell(
                    // The button itself
                    borderRadius: BorderRadius.circular(80),
                    onTap: () async {
                      await takePicture();
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(Icons.circle, size: 80, color: Colors.grey),
                        Icon(Icons.circle, size: 70, color: Colors.white),
                      ],
                    ),
                  )),
            ],
          ),
        ));
  }
}

Widget circle(int radius, Color color) {
  return Container(
    width: radius.toDouble(),
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
