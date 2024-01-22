import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:camera/camera.dart';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class ImageCard extends StatelessWidget {
  final String imagePath;
  final Function(String) onImageSelected;

  const ImageCard({required this.imagePath, required this.onImageSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          SizedBox(
            height: 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () {
                    onImageSelected(imagePath);
                  },
                  icon: Icon(Icons.delete),
                ),
              ],
            ),
          ),
          Image.file(
            File(imagePath),
            fit: BoxFit.cover,
          ),
        ],
      ),
    );
  }
}

class Gallery extends StatefulWidget {
  const Gallery({super.key});

  @override
  State<Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<Gallery> {
  Future<List<String>> getImages() async {
    // get image paths
    final directory =
        await getExternalStorageDirectories(type: StorageDirectory.pictures);
    final dir = Directory(directory![0].path);
    final files = dir.listSync();
    final imageFiles = files.where((element) {
      return element.path.endsWith(".jpg");
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
        title: Text("Gallery"),
      ),
      body: SafeArea(
        child: Container(
          child: FutureBuilder(
            future: getImages(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return ListView.builder(
                  itemCount: snapshot.data?.length,
                  itemBuilder: (context, index) {
                    isImageValid(File(snapshot.data![index]).readAsBytesSync())
                        .then((value) {
                      if (!value) {
                        File(snapshot.data![index]).delete();
                      }
                    });
                    return ImageCard(
                      imagePath: snapshot.data![index],
                      onImageSelected: (imagePath) {
                        setState(() {
                          File(imagePath).delete();
                        });
                      },
                    );
                  },
                );
              } else {
                return CircularProgressIndicator();
              }
            },
          ),
        ),
      ),
    );
  }
}
