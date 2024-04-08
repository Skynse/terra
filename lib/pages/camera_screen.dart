import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:terra/core/ml_service.dart';
import 'package:terra/main.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:terra/pages/gallery.dart';

// attribs
/*
0 balancing_elements
1 color_harmony
2 content
3 depth_of_field
4 light
5 motion_blur
6 object
7 repetition
8 rule_of_thirds
9 symmetry
10 vivid_color
11 score
*/
const attributes = {
  'balancing_elements': 0,
  'color_harmony': 1,
  'content': 2,
  'depth_of_field': 3,
  'light': 4,
  'motion_blur': 5,
  'object': 6,
  'repetition': 7,
  'rule_of_thirds': 8,
  'symmetry': 9,
  'vivid_color': 10,
  'score': 11
};

class CameraScreen extends StatefulWidget {
  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? controller;
  bool cameraReady = false;
  // classification
  Map<String, double> classificationOutput = {}; //attribute: score
  bool infoVisible = false;
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
      setState(() {
        classificationOutput = classification!;
      });
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
      var documentsDir = await getApplicationDocumentsDirectory();// get the documents folder of the current device
     

      var currentTime = DateTime.now()
          .millisecondsSinceEpoch; // get the current date and time

      var format = file.path
          .split('.')
          .last; // file.png -> only get png part "png" // get the file format of the captured image

      await file.copy(
          "${documentsDir.path}/$currentTime.$format"); // Documents/0904203.png //copy the image from the temporary location to the permanent one
      // in our documents folder

      // copy to documents
      print("Image saved to ${documentsDir.path}/$currentTime.$format");
      return data;
    }

    print("Camera is not initialized");
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
          // infopanel toggle
          floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              setState(() {
                infoVisible = !infoVisible;
              });
            },
            child: Icon(infoVisible ? Icons.close : Icons.info),
          ),
          body: Padding(
            padding: EdgeInsets.only(
                top: 20, bottom: 15), // add padding (space) to bottom of screen
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(18.0),
                          child: Container(
                              child: (controller != null &&
                                      this
                                          .controller!
                                          .value
                                          .isInitialized) // condition to make sure the camera is initialized
                                  ? CameraPreview(this.controller!)
                                  : Center(child: CircularProgressIndicator())),
                        ),
                      ),
                      /*
                      Opacity(
                        opacity: 0.7,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.only(
                                bottom: 18.0, top: 18, left: 43, right: 43),
                            child: Container(
                              height: MediaQuery.of(context).size.height,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  width: 5,
                                  color:
                                      (isImageGood) ? Colors.green : Colors.red,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ), */
                      // score at top right
                      AnimatedPositioned(
                        top: infoVisible
                            ? 10
                            : -300, // Adjust the top position based on visibility
                        right: 30,
                        duration: Duration(
                            milliseconds: 300), // Set the animation duration
                        curve: Curves.easeInOut, // Set the animation curve
                        child: Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              for (var attribute in attributes.keys)
                                Row(
                                  children: [
                                    Text(
                                      attribute,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      classificationOutput[attribute] != null
                                          ? classificationOutput[attribute]!
                                              .toStringAsFixed(2)
                                          : "0.0",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
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
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            IconButton(
                                onPressed: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const Gallery()));
                                },
                                icon: Icon(Icons.photo)),
                            InkWell(
                              // The button itself
                              borderRadius: BorderRadius.circular(80),
                              onTap: () async {
                                // ensure camera is initialized

                                if (Platform.isAndroid) {

                                try {
                                  await Permission.camera
                                      .onGrantedCallback(() async {
                                    if (controller!.value.isTakingPicture) {
                                      return;
                                    }
                                    await controller?.takePicture().then(
                                      (path) async {
                                        var file = File(path.path);

                                        var documentsDir =
                                            await getApplicationDocumentsDirectory(); // get the documents folder of the current device

                                        var currentTime = DateTime.now()
                                            .millisecondsSinceEpoch; // get the current date and time

                                        var format = file.path
                                            .split('.')
                                            .last; // file.png -> only get png part "png" // get the file format of the captured image

                                        await file.copy(
                                            "${documentsDir.path}/$currentTime.$format"); // Documents/0904203.png //copy the image from the temporary location to the permanent one
                                        print(
                                            "Image saved to ${documentsDir.path}/$currentTime.$format");
                                        // preview
                                        // print out image path
                                        if (!mounted) return;
                                      },
                                    );
                                  }).request();
                                } on CameraException catch (e) {
                                  print("Unable to initialize camera: $e");
                                }
                              } else {
                           
                                    if (controller!.value.isTakingPicture) {
                                      return;
                                    }
                                    await controller?.takePicture().then(
                                      (path) async {
                                        var file = File(path.path);

                                        var documentsDir =
                                            await getApplicationDocumentsDirectory(); // get the documents folder of the current device

                                        var currentTime = DateTime.now()
                                            .millisecondsSinceEpoch; // get the current date and time

                                        var format = file.path
                                            .split('.')
                                            .last; // file.png -> only get png part "png" // get the file format of the captured image

                                        await file.copy(
                                            "${documentsDir.path}/$currentTime.$format"); // Documents/0904203.png //copy the image from the temporary location to the permanent one
                                        print(
                                            "Image saved to ${documentsDir.path}/$currentTime.$format");
                                        // preview
                                        // print out image path
                                        if (!mounted) return;
                                      },
                                    );
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
                                if (Platform.isAndroid) {
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
                                }

                                  else {          

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
