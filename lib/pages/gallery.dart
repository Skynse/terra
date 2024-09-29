import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ImagePage extends StatelessWidget {
  final String filePath;
  const ImagePage({Key? key, required this.filePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(child: Image.file(File(filePath))),
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
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ImagePage(filePath: imagePath))),
      onLongPress: () => _showDeleteDialog(context),
      child: Image.file(File(imagePath), width: 200, fit: BoxFit.fitWidth),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Image"),
        content: const Text("Are you sure you want to delete this image?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              onImageSelected(imagePath);
              Navigator.pop(context);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}

class Gallery extends ConsumerStatefulWidget {
  const Gallery({Key? key}) : super(key: key);

  @override
  ConsumerState<Gallery> createState() => _GalleryState();
}

class _GalleryState extends ConsumerState<Gallery> {
  Future<List<String>> getImages() async {
    final directory = await getApplicationDocumentsDirectory();
    final files = Directory(directory.path).listSync();
    return files
        .where((e) =>
            e.path.endsWith(".jpg") ||
            e.path.endsWith(".jpeg") ||
            e.path.endsWith(".png"))
        .map((e) => e.path)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gallery", style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () async {
              final directory = await getApplicationDocumentsDirectory();
              Directory(directory.path).deleteSync(recursive: true);
              setState(() {});
            },
          )
        ],
      ),
      body: FutureBuilder<List<String>>(
        future: getImages(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, crossAxisSpacing: 4.0, mainAxisSpacing: 5.0),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) => ImageCard(
              imagePath: snapshot.data![index],
              onImageSelected: (imagePath) {
                File(imagePath).delete();
                setState(() {});
              },
            ),
          );
        },
      ),
    );
  }
}
