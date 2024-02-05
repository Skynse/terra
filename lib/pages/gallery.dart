import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:camera/camera.dart';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';

class ImageCard extends ConsumerWidget {
  final String imagePath;
  final Function(String) onImageSelected;

  const ImageCard(
      {Key? key, required this.imagePath, required this.onImageSelected})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
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
    final directory =
        await getExternalStorageDirectories(type: StorageDirectory.pictures);
    final dir = Directory(directory![0].path);
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
        title: Text("Gallery"),
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
                  mainAxisSpacing: 4.0,
                ),
                itemCount: snapshot.data?.length,
                itemBuilder: (context, index) {
                  final imagePath = snapshot.data![index];
                  return FutureBuilder(
                    future: File(imagePath).readAsBytes(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
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
              return CircularProgressIndicator();
            }
          },
        ),
      ),
    );
  }
}
