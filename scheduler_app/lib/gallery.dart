// Import necessary packages
import 'dart:io'; // Dart core library to handle files.
import 'package:flutter/material.dart'; // Flutter framework for UI building.
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart'; // ML Kit for text recognition.
import 'package:image_picker/image_picker.dart'; // Image Picker library for picking images from the gallery or camera.

/// This class represents a stateful widget that displays an interface for 
/// picking an image from the gallery and extracting text from it using 
/// Google's ML Kit text recognition.
class Gallery extends StatefulWidget {
  const Gallery({super.key});

  @override
  State<Gallery> createState() => _GalleryState();
}

/// This state class manages the state of the `Gallery` widget.
class _GalleryState extends State<Gallery> {
  File? _selectedFile; // Holds the selected image file.
  final ImagePicker _picker = ImagePicker(); // Instance of ImagePicker for picking images.

  /// Called when the state is initialized. Picks an image from the gallery 
  /// when the widget is first created.
  @override
  void initState() {
    super.initState();
    _pickImageFromGallery();
  }

  /// Picks an image from the gallery using the `image_picker` package.
  /// If an image is selected, it updates the state with the selected file.
  Future<void> _pickImageFromGallery() async {
    try {
      // Pick an image from the gallery.
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

      // If an image is selected, update the state with the file.
      if (image != null) {
        setState(() {
          _selectedFile = File(image.path);
        });
        print('Selected file path: ${image.path}'); // Log the selected file path.
      } else {
        print('No image selected.');
      }
    } catch (e) {
      print('Error picking image: $e'); // Log any errors that occur during image picking.
    }
  }

  /// Builds the UI of the Gallery screen, including the selected image view
  /// and the extracted text view.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gallery Picker"), // Title of the app bar.
      ),
      body: _buildUI(), // Build the main UI of the screen.
    );
  }

  /// Builds the main user interface, including the image view and the text 
  /// extraction view.
  Widget _buildUI() {
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _imageView(), // Display the selected image.
        _extractTextView(), // Display the extracted text.
      ],
    );
  }

  /// Builds a widget to display the selected image. If no image is selected,
  /// it prompts the user to pick an image.
  Widget _imageView() {
    if (_selectedFile == null) {
      return const Center(
        child: Text("Pick an image please."), // Prompt to pick an image.
      );
    }
    return Center(
      child: Image.file(
        _selectedFile!, // Display the selected image.
        width: 200,
        height: 200,
        fit: BoxFit.cover,
      ),
    );
  }

  /// Builds a widget to display the extracted text from the selected image.
  /// If no image is selected, it shows "No result".
  Widget _extractTextView() {
    if (_selectedFile == null) {
      return const Center(
        child: Text("No result"), // Displayed if no image is selected.
      );
    }
    return FutureBuilder(
      future: _extractText(_selectedFile!), // Future for extracting text from the image.
      builder: (context, snapshot) {
        return Text(
          snapshot.data ?? "", // Display the extracted text or an empty string if none.
          style: const TextStyle(
            fontSize: 15,
          ),
        );
      },
    );
  }

  /// Extracts text from the provided image file using Google's ML Kit text 
  /// recognition API.
  /// 
  /// [file]: The image file from which to extract text.
  /// 
  /// Returns a string containing the recognized text or null if an error occurs.
  Future<String?> _extractText(File file) async {
    // Create a text recognizer with Latin script.
    final textRecognizer = TextRecognizer(
      script: TextRecognitionScript.latin,
    );
    // Convert the file to an InputImage object.
    final InputImage inputImage = InputImage.fromFile(file);
    // Process the image and extract text.
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
    String text = recognizedText.text; // Extracted text.
    textRecognizer.close(); // Close the text recognizer to release resources.
    return text;
  }
}
