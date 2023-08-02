import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectionPage extends StatefulWidget {
  @override
  _FaceDetectionPageState createState() => _FaceDetectionPageState();
}

class _FaceDetectionPageState extends State<FaceDetectionPage> {
  CameraController? _cameraController;
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedImage;
  List<Face> _detectedFaces = [];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  void _initializeCamera() async {
    final cameras = await availableCameras();
    final camera = cameras.first;
    _cameraController = CameraController(camera, ResolutionPreset.high);
    await _cameraController!.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  void _pickImage() async {
    final pickedImage = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _selectedImage = File(pickedImage.path);
      });
    }
  }

  void _detectAndCropFace() async {
    if (_selectedImage == null) {
      print('No image selected');
      return;
    }

    final inputImage = InputImage.fromFilePath(_selectedImage!.path);

    // Create the face detector options if you want to customize the detection behavior.
    final faceDetectorOptions = FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
      enableContours: true, // Set to true if you want to detect facial contours as well
      enableLandmarks: true, // Set to true if you want to detect facial landmarks as well
    );

    final faceDetector = FaceDetector(options: faceDetectorOptions);

    try {
      final List<Face> faces = await faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        print('No faces detected');
        return;
      }

      // Assuming only one face is detected in this example
      final face = faces.first;
      final left = face.boundingBox.left.toInt();
      final top = face.boundingBox.top.toInt();
      final width = face.boundingBox.width.toInt();
      final height = face.boundingBox.height.toInt();

      // Get the face image and save it to a new file
      final croppedImage = await _cropFaceImage(left, top, width, height);
      // Now you have the cropped face image in the croppedImage variable.
    } catch (e) {
      print('Error during face detection: $e');
    } finally {
      faceDetector.close(); // Don't forget to close the detector to release resources
    }
  }

  Future<File> _cropFaceImage(int left, int top, int width, int height) async {
    final originalImage = img.decodeImage(await _selectedImage!.readAsBytes());
    final faceImage = img.copyCrop(originalImage!, x: left, y: top, width: width, height: height);
    final croppedPath = _selectedImage!.path.replaceFirst('.jpg', '_cropped.jpg');
    return File(croppedPath).writeAsBytes(img.encodeJpg(faceImage));
  }

  @override
  Widget build(BuildContext context) {
    if (!_cameraController!.value.isInitialized) {
      return Container();
    }
    final previewSize = _cameraController!.value.previewSize;

    return Scaffold(
      appBar: AppBar(title: Text('Face Detection')),
      body: Column(
        children: [
          Expanded(
            child: _selectedImage != null
                ? Stack(
              children: [
                Image.file(_selectedImage!),
                CustomPaint(
                  painter: FacePainter(_detectedFaces),
                ),
              ],
            )
                : Stack(
              children: [
                CameraPreview(_cameraController!),
                CustomPaint(
                  painter: FacePainter(_detectedFaces),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _pickImage,
            child: Text('Select Image'),
          ),
          ElevatedButton(
            onPressed: _detectAndCropFace,
            child: Text('Detect and Crop Face'),
          ),
        ],
      ),
    );
  }
}

class FacePainter extends CustomPainter {
  final List<Face> faces;

  FacePainter(this.faces);

  @override
  void paint(Canvas canvas, Size size) {
    final double scaleX = size.width;
    final double scaleY = size.height;

    final Paint paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    if (faces != null) {
      for (var face in faces) {
        final Rect boundingBox = _scaleRect(
          rect: face.boundingBox,
          imageSize: Size(scaleX, scaleY),
        );
        canvas.drawRect(boundingBox, paint);
      }
    }
  }

  @override
  bool shouldRepaint(FacePainter oldDelegate) {
    return faces != oldDelegate.faces;
  }

  Rect _scaleRect({required Rect rect, required Size imageSize}) {
    return Rect.fromLTRB(
      rect.left * imageSize.width,
      rect.top * imageSize.height,
      rect.right * imageSize.width,
      rect.bottom * imageSize.height,
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: FaceDetectionPage(),
  ));
}
