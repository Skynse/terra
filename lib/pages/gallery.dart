import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:camera/camera.dart';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';

import 'package:terra/core/ml_service.dart';

class ImagePage extends StatefulWidget {
  //  Viewing the full image
  ImagePage({super.key, required this.filePath});
  String filePath;

  @override
  State<ImagePage> createState() => _ImagePageState();
}

class _ImagePageState extends State<ImagePage> {
  Map<String, double> classificationOutput = {};

  late ImageClassificationHelper imageClassificationHelper;

  @override
  void initState() {
    imageClassificationHelper = ImageClassificationHelper();
    imageClassificationHelper.initHelper();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              child: Text("Image Classification"),
            ),
            ListTile(
              title: Text("Classify Image"),
              onTap: () async {
                final image =
                    img.decodeImage(File(widget.filePath).readAsBytesSync());
                final resizedImage =
                    img.copyResize(image!, width: 224, height: 224);
                final inputImage = img.encodePng(resizedImage);
                img.Image im = img.Image.fromBytes(
                    width: resizedImage.width,
                    height: resizedImage.height,
                    bytes: inputImage.buffer);
                final output = await imageClassificationHelper
                    .inferenceImage(im as img.Image);
                classificationOutput = output;

                // show popup, ensuring scrollable
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text("Classification Result"),
                      content: SingleChildScrollView(
                        child: Column(
                          children: classificationOutput.keys
                              .map((key) => ListTile(
                                    title: Text(key),
                                    subtitle: Text(
                                        classificationOutput[key]!.toString()),
                                  ))
                              .toList(),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text("Close"),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            ListTile(
              title: Text("Close"),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(),
      body: Center(
        child: Image.file(
          File(widget.filePath),
        ),
      ),
    );
  }
}

class ImageCard extends ConsumerWidget {
  final String imagePath;
  final Function(String) onImageSelected;

  const ImageCard(
      {Key? key, required this.imagePath, required this.onImageSelected})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ImagePage(
                    filePath: imagePath,
                  )),
        );
      },
      onLongPress: () {
        showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text("Delete Image"),
                content: Text("Are you sure you want to delete this image?"),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text("Cancel"),
                  ),
                  TextButton(
                    onPressed: () {
                      onImageSelected(imagePath);
                      Navigator.pop(context);
                    },
                    child: Text("Delete"),
                  ),
                ],
              );
            });
      },
      child: SizedBox(
        height: 300,
        width: 300,
        child: Column(
          children: [
            Expanded(
              child: Image.file(
                filterQuality: FilterQuality.low,
                width: 200,
                scale: 1.0,
                File(imagePath),
                fit: BoxFit.fitWidth,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Gallery extends ConsumerStatefulWidget {
  const Gallery({super.key});

  @override
  ConsumerState<Gallery> createState() => _GalleryState();
}

class _GalleryState extends ConsumerState<Gallery> {
  Future<List<String>> getImages() async {
    // get image paths
    final directory = await getApplicationDocumentsDirectory();
    final dir = Directory(directory.path);
    final files = dir.listSync();
    final imageFiles = files.where((element) {
      return element.path.endsWith(".jpg") ||
          element.path.endsWith(".jpeg") ||
          element.path.endsWith(".png");
    }).toList();

    return imageFiles.map((e) => e.path).toList();
  }

  Future<bool> isImageValid(List<int> rawList) async {
    final uInt8List =
        rawList is Uint8List ? rawList : Uint8List.fromList(rawList);

    try {
      final codec = await instantiateImageCodec(uInt8List, targetWidth: 32);
      final frameInfo = await codec.getNextFrame();
      return frameInfo.image.width > 0;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.clear),
            onPressed: () async {
              final directory = await getApplicationDocumentsDirectory();
              final dir = Directory(directory.path);
              dir.deleteSync(recursive: true);

              setState(() {});
              // deleta all images
            },
          )
        ],
        iconTheme: IconThemeData(color: Colors.white),
        // ignore: prefer_const_constructors
        title: Text(
          "Gallery",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder(
          future: getImages(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 4.0,
                  mainAxisSpacing: 5.0,
                ),
                itemCount: snapshot.data?.length,
                itemBuilder: (context, index) {
                  final imagePath = snapshot.data![index];
                  return FutureBuilder(
                    future: File(imagePath).readAsBytes(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        if (snapshot.data!.length == 0) {
                          return Center(child: Text("No Images Found"));
                        }

                        final rawList = snapshot.data as List<int>;
                        return FutureBuilder(
                          future: isImageValid(rawList),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              final isValid = snapshot.data as bool;
                              if (isValid) {
                                return SizedBox(
                                  height: 200,
                                  width: 200,
                                  child: ImageCard(
                                    imagePath: imagePath,
                                    onImageSelected: (imagePath) {
                                      File(imagePath).delete();
                                      if (!mounted) return;
                                      setState(() {});
                                    },
                                  ),
                                );
                              } else {
                                return Container();
                              }
                            } else {
                              return CircularProgressIndicator();
                            }
                          },
                        );
                      } else {
                        return CircularProgressIndicator();
                      }
                    },
                  );
                },
              );
            } else {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    const SizedBox(height: 10),
                    const Text("Loading Images..."),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
