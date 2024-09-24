import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gallery_picker/gallery_picker.dart';

class Gallery extends StatefulWidget {
  const Gallery({super.key});

  @override
  State<Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<Gallery> {
  File? _selectedFile;

  @override
  void initState() {
    super.initState();
    _pickImageFromGallery();
  }

  Future<void> _pickImageFromGallery() async {
    try {
      // Pick media from the gallery
      List<MediaFile>? mediaFile = await GalleryPicker.pickMedia(
        context: context,
        singleMedia: true,
      );

      // Ensure mediaFile is not null and has elements
      if (mediaFile != null && mediaFile.isNotEmpty) {
        var data = await mediaFile.first.getFile();
        print('Selected file path: ${data.path}'); // Debugging the file path
        setState(() {
          _selectedFile = data;
        });
      } else {
        print('No file selected.');
      }
    } catch (e) {
      print('Error picking image: $e'); // Catch any errors
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
}
