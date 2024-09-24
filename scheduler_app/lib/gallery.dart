import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart'; // New import

class Gallery extends StatefulWidget {
  const Gallery({super.key});

  @override
  State<Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<Gallery> {
  File? _selectedFile;
  final ImagePicker _picker = ImagePicker(); // Create ImagePicker instance

  @override
  void initState() {
    super.initState();
    _pickImageFromGallery();
  }

  Future<void> _pickImageFromGallery() async {
    try {
      // Use ImagePicker to pick an image
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        setState(() {
          _selectedFile = File(image.path);
        });
        print('Selected file path: ${image.path}');
      } else {
        print('No image selected.');
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gallery Picker"),
      ),
      body: _buildUI(),
    );
  }

  Widget _buildUI() {
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _imageView(),
        _extractTextView(),
      ],
    );
  }

  Widget _imageView() {
    if (_selectedFile == null) {
      return const Center(
        child: Text("Pick an image please."),
      );
    }
    return Center(
      child: Image.file(
        _selectedFile!,
        width: 200,
        height: 200,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _extractTextView() {
    if (_selectedFile == null){
      return const Center(
        child: Text("No result"),
      );
    }
    return FutureBuilder(
      future: _extractText(_selectedFile!), 
      builder: (context, snapshot) {
        return Text(
          snapshot.data ?? "", 
          style: const TextStyle(
            fontSize: 15,
          ),
        );
      },
    );
  }

  Future<String?> _extractText(File file) async{
    final textRecognizer = TextRecognizer(
      script: TextRecognitionScript.latin,
    );
    final InputImage inputImage = InputImage.fromFile(file);
    final RecognizedText recognizedText = 
      await textRecognizer.processImage(inputImage);
    String text = recognizedText.text;
    textRecognizer.close();
    return text;
  }
}
