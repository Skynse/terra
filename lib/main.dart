import 'package:flutter/material.dart';
import 'package:terra/pages/camera_screen.dart';
import 'package:camera/camera.dart';
import 'package:terra/pages/gallery.dart';

List<CameraDescription> cameras =
    []; // USES the availableCameras() to store their descriptions (front, back, external)

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // explain more later
  cameras = await availableCameras(); // get the list of available cameras
  runApp(App());
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: CameraScreen(),
        ));
  }
}
