// ignore_for_file: avoid_print

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'main.dart';

class RealTimeTextRecognition extends StatefulWidget {
  const RealTimeTextRecognition({super.key});

  @override
  State<RealTimeTextRecognition> createState() =>
      _RealTimeTextRecognitionState();
}

class _RealTimeTextRecognitionState extends State<RealTimeTextRecognition> {
  dynamic controller;
  bool isBusy = false;
  dynamic textRecognizer;
  late Size size;

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  //code to initialize the camera feed
  initializeCamera() async {
    //initialize detector
    textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    controller = CameraController(cameras[0], ResolutionPreset.high);
    await controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      controller.startImageStream((image) => {
            if (!isBusy)
              {isBusy = true, img = image, doTextRecognitionOnFrame()}
          });
    });
  }

  //close all resources
  @override
  void dispose() {
    controller?.dispose();
    textRecognizer.close();
    super.dispose();
  }

  //object detection on a frame
  dynamic _scanResults;
  CameraImage? img;
  doTextRecognitionOnFrame() async {
    var frameImg = getInputImage();
    RecognizedText recognizedText = await textRecognizer.processImage(frameImg);
    print(recognizedText.text);
    setState(() {
      _scanResults = recognizedText;
      isBusy = false;
    });
  }

  InputImage getInputImage() {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in img!.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();
    final Size imageSize = Size(img!.width.toDouble(), img!.height.toDouble());
    final camera = cameras[0];
    final imageRotation =
        InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    // if (imageRotation == null) return;

    final inputImageFormat =
        InputImageFormatValue.fromRawValue(img!.format.raw);
    // if (inputImageFormat == null) return null;

    final planeData = img!.planes.map(
      (Plane plane) {
        return InputImagePlaneMetadata(
          bytesPerRow: plane.bytesPerRow,
          height: plane.height,
          width: plane.width,
        );
      },
    ).toList();

    final inputImageData = InputImageData(
      size: imageSize,
      imageRotation: imageRotation!,
      inputImageFormat: inputImageFormat!,
      planeData: planeData,
    );

    final inputImage =
        InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);

    return inputImage;
  }

  //Show rectangles around detected objects
  Widget buildResult() {
    if (_scanResults == null ||
        controller == null ||
        !controller.value.isInitialized) {
      return const Text('');
    }

    final Size imageSize = Size(
      controller.value.previewSize!.height,
      controller.value.previewSize!.width,
    );
    CustomPainter painter = TextRecognitionPainter(imageSize, _scanResults);
    return CustomPaint(
      painter: painter,
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> stackChildren = [];
    size = MediaQuery.of(context).size;
    if (controller != null) {
      stackChildren.add(
        Positioned(
          top: 0.0,
          left: 0.0,
          width: size.width,
          height: size.height,
          child: Container(
            child: (controller.value.isInitialized)
                ? AspectRatio(
                    aspectRatio: controller.value.aspectRatio,
                    child: CameraPreview(controller),
                  )
                : Container(),
          ),
        ),
      );
      stackChildren.add(
        Positioned(
            top: 0.0,
            left: 0.0,
            width: size.width,
            height: size.height,
            child: buildResult()),
      );
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
          color: Colors.black,
          child: Stack(
            children: stackChildren,
          )),
    );
  }
}

class TextRecognitionPainter extends CustomPainter {
  TextRecognitionPainter(this.absoluteImageSize, this.recognizedText);

  final Size absoluteImageSize;
  final RecognizedText recognizedText;

  @override
  void paint(Canvas canvas, Size size) {
    final double scaleX = size.width / absoluteImageSize.width;
    final double scaleY = size.height / absoluteImageSize.height;

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.yellow;

    for (TextBlock block in recognizedText.blocks) {
      // final Rect rect = block.boundingBox;
      // final List<Point<int>> cornerPoints = block.cornerPoints;
      // final String text = block.text;
      // final List<String> languages = block.recognizedLanguages;

      for (TextLine line in block.lines) {
        canvas.drawRect(
          Rect.fromLTRB(
            block.boundingBox.left * scaleX,
            block.boundingBox.top * scaleY,
            block.boundingBox.right * scaleX,
            block.boundingBox.bottom * scaleY,
          ),
          paint,
        );
        TextSpan span = TextSpan(
            text: line.text,
            style: const TextStyle(fontSize: 15, color: Colors.yellow));
        TextPainter tp = TextPainter(
            text: span,
            textAlign: TextAlign.left,
            textDirection: TextDirection.ltr);
        tp.layout();
        tp.paint(
            canvas,
            Offset(
                line.boundingBox.left * scaleX, line.boundingBox.top * scaleY));

        //for (TextElement element in line.elements) {}
      }
    }
  }

  @override
  bool shouldRepaint(TextRecognitionPainter oldDelegate) {
    return oldDelegate.absoluteImageSize != absoluteImageSize ||
        oldDelegate.recognizedText != recognizedText;
  }
}
