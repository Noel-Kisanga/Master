import 'package:camera/camera.dart';  // Imports the camera package for camera functionalities.
import 'package:flutter/material.dart'; // Imports the Flutter Material package for UI components.
import 'package:gal/gal.dart'; // Imports the gal package, which appears to handle image gallery functions.

class TakePhoto extends StatefulWidget {
  const TakePhoto({super.key}); // A StatefulWidget for taking a photo.

  @override
  State<TakePhoto> createState() => _TakePhotoState(); // Creates the state for this widget.
}

class _TakePhotoState extends State<TakePhoto> with WidgetsBindingObserver {
  // Holds the list of available cameras and a controller for managing the camera.
  List<CameraDescription> cameras = [];
  CameraController? cameraController;

  // Handles changes in the app's lifecycle state (e.g., background/foreground).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Checks if the camera controller is initialized.
    if (cameraController == null || cameraController?.value.isInitialized == false) {
      return;
    }

    // Disposes the camera when the app is inactive (e.g., backgrounded).
    if (state == AppLifecycleState.inactive) {
      cameraController?.dispose();
    } 
    // Reinitializes the camera when the app resumes.
    else if (state == AppLifecycleState.resumed) {
      _setupCameraController();
    }
  }

  @override
  void initState() {
    super.initState();
    _setupCameraController(); // Sets up the camera when the widget is first initialized.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildUI(), // Builds the UI.
    );
  }

  // Builds the UI for the camera preview and camera button.
  Widget _buildUI() {
    // If the camera is not initialized, show a loading spinner.
    if (cameraController?.value.isInitialized == false) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    // Displays the camera preview and a camera button once the camera is ready.
    return SafeArea(
      child: SizedBox.expand(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Even spacing for the column's children.
          crossAxisAlignment: CrossAxisAlignment.center, // Aligns items in the center horizontally.
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.70, // Camera preview takes up 30% of screen height.
              width: MediaQuery.sizeOf(context).width,  // 80% of screen width.
              child: CameraPreview(
                cameraController!, // Displays the live camera preview.
              ),
            ),
            IconButton(
              onPressed: () async {
                // Captures a picture when the camera button is pressed.
                XFile pic = await cameraController!.takePicture();
                
                // Stores the picture in the gallery using the Gal package.
                Gal.putImage(
                  pic.path,
                );
              },
              iconSize: 100, // Large camera icon size.
              icon: const Icon(
                Icons.camera, // Red camera icon.
                color: Colors.red,
              )
            )
          ],
        )
      ),
    );
  }

  // Sets up the camera controller asynchronously.
  Future<void> _setupCameraController() async {
    // Gets the list of available cameras.
    List<CameraDescription> cameras = await availableCameras();
    
    // If cameras are available, set up the first camera.
    if (cameras.isNotEmpty) {
      setState(() {
        cameras = cameras; // Updates the list of available cameras.
        
        // Initializes the CameraController with the first available camera and high resolution.
        cameraController = CameraController(
          cameras.first, 
          ResolutionPreset.high,
        );
      });
      
      // Initializes the camera and updates the UI once done.
      cameraController?.initialize().then((_) {
        if (!mounted) { // If the widget is no longer in the widget tree, do nothing.
          return;
        }
        setState(() {}); // Rebuilds the UI to display the camera preview.
      }).catchError(
        (Object e) {}, // Handles any errors that occur during initialization.
      );
    }
  }
}
