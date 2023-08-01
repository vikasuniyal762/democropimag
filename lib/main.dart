import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

final double left = 100;
final double top = 100;
final double width = 399;
const double height = 299;

// Define the original image file path here
const String imagePath = 'assets/child-children-girl-happy.jpg';

Future<Uint8List> processImage() async {
  // Load the image from assets
  final ByteData data = await rootBundle.load(imagePath);
  final Uint8List bytes = data.buffer.asUint8List();
  final rawImage = img.decodeImage(bytes);

  final pictureRecorder = ui.PictureRecorder();
  final canvas = Canvas(pictureRecorder);
  final paint = Paint();
  canvas.drawImage(
    rawImage! as ui.Image,
    Offset.zero,
    paint,
  );

  final croppedImage = img.copyCrop(
    rawImage!,
    x: left.toInt(),
    y: top.toInt(),
    width: width.toInt(),
    height: height.toInt(),
  );

  final croppedBytes = img.encodePng(croppedImage);

  return croppedBytes;
}

Future<File> saveImageToDisk(Uint8List bytes) async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/cropped_image.png');
  await file.writeAsBytes(bytes);
  return file;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final croppedImageBytes = await processImage();

  // Save the cropped image to disk
  final croppedImageFile = await saveImageToDisk(croppedImageBytes);

  runApp(MyApp(croppedImageFile: croppedImageFile));
}

class MyApp extends StatelessWidget {
  final File croppedImageFile;

  const MyApp({super.key, required this.croppedImageFile});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Cropped Image')),
        body: Center(
          child: Image.file(croppedImageFile),
        ),
      ),
    );
  }
}
