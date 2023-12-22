// ignore_for_file: prefer_const_constructors

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class StaticTextRecognition extends StatefulWidget {
  const StaticTextRecognition({super.key});
  @override
  State<StaticTextRecognition> createState() => _StaticTextRecognitionState();
}

class _StaticTextRecognitionState extends State<StaticTextRecognition> {
  File? _image;
  String result = '';
  late ImagePicker imagePicker;
  dynamic textRecognizer;

  @override
  void initState() {
    super.initState();
    imagePicker = ImagePicker();
    //initialize detector
    textRecognizer = TextRecognizer(
      script: TextRecognitionScript.latin,
    );
  }

  imgFromCamera() async {
    XFile? pickedFile = await imagePicker.pickImage(source: ImageSource.camera);
    File image = File(pickedFile!.path);
    setState(() {
      _image = image;
      if (_image != null) {
        doTextRecognition();
      }
    });
  }

  imgFromGallery() async {
    XFile? pickedFile =
        await imagePicker.pickImage(source: ImageSource.gallery);
    File image = File(pickedFile!.path);
    setState(() {
      _image = image;
      if (_image != null) {
        doTextRecognition();
      }
    });
  }

  //perform text recognition
  doTextRecognition() async {
    InputImage inputImage = InputImage.fromFile(_image!);
    final RecognizedText recognizedText =
        await textRecognizer.processImage(inputImage);
    // String text = recognizedText.text;
    // setState(() {
    //   result = text;
    // });
    result = '';
    for (TextBlock block in recognizedText.blocks) {
      // final Rect rect = block.boundingBox;
      // final List<Point<int>> cornerPoints = block.cornerPoints;
      // final String text = block.text;
      // final List<String> languages = block.recognizedLanguages;
      for (TextLine line in block.lines) {
        for (TextElement element in line.elements) {
          result += '${element.text} ';
        }
        result += '\n';
      }
      result += '\n';
    }
    setState(() {
      result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Column(
          children: [
            Container(
              color: Colors.white,
              height: MediaQuery.of(context).size.height / 2,
              width: MediaQuery.of(context).size.width,
              //margin: const EdgeInsets.only(top: 70),
              padding: const EdgeInsets.only(left: 28, bottom: 5, right: 18),
              child: SingleChildScrollView(
                  child: Text(
                result,
                textAlign: TextAlign.justify,
                style: const TextStyle(fontSize: 20, color: Colors.black),
              )),
            ),
            Stack(children: <Widget>[
              Center(
                child: ElevatedButton(
                  onPressed: imgFromGallery,
                  onLongPress: imgFromCamera,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent),
                  child: Container(
                    margin: const EdgeInsets.only(top: 100),
                    child: _image != null
                        ? Image.file(
                            _image!,
                            width: MediaQuery.of(context).size.width,
                            height: 300,
                            fit: BoxFit.fill,
                          )
                        : SizedBox(
                            width: 140,
                            height: 150,
                            child: Icon(
                              Icons.find_in_page,
                              size: 100,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
