import 'dart:io';
import 'package:camera/camera.dart';  // Imports the camera package for camera functionalities.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Imports the Flutter Material package for UI components.
import 'package:gal/gal.dart';
import 'package:scheduler_app/FullScreenImage.dart'; // Imports the gal package, which appears to handle image gallery functions.

class TakePhoto extends StatefulWidget {
  const TakePhoto({super.key}); // A StatefulWidget for taking a photo.

  @override
  State<TakePhoto> createState() => _TakePhotoState(); // Creates the state for this widget.
}

class _TakePhotoState extends State<TakePhoto> with WidgetsBindingObserver, TickerProviderStateMixin {
  // Holds the list of available cameras and acameraController for managing the camera.
  List<CameraDescription> cameras = [];
  CameraController? cameraController;
  XFile? pic;
  double _minAvailableExposureOffset = 0.0;
  double _maxAvailableExposureOffset = 0.0;
  double _currentExposureOffset = 0.0;
  late AnimationController _flashModeControlRowAnimationController;
  late Animation<double> _flashModeControlRowAnimation;
  late AnimationController _exposureModeControlRowAnimationController;
  late Animation<double> _exposureModeControlRowAnimation;
  late AnimationController _focusModeControlRowAnimationController;
  late Animation<double> _focusModeControlRowAnimation;

  // Handles changes in the app's lifecycle state (e.g., background/foreground).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Checks if the cameracameraController is initialized.
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
    WidgetsBinding.instance.addObserver(this);

    _flashModeControlRowAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _flashModeControlRowAnimation = CurvedAnimation(
      parent: _flashModeControlRowAnimationController,
      curve: Curves.easeInCubic,
    );
    _exposureModeControlRowAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _exposureModeControlRowAnimation = CurvedAnimation(
      parent: _exposureModeControlRowAnimationController,
      curve: Curves.easeInCubic,
    );
    _focusModeControlRowAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _focusModeControlRowAnimation = CurvedAnimation(
      parent: _focusModeControlRowAnimationController,
      curve: Curves.easeInCubic,
    );
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
              height: MediaQuery.sizeOf(context).height * 0.55, // Camera preview takes up 30% of screen height.
              width: MediaQuery.sizeOf(context).width,  // 80% of screen width.
              child: CameraPreview(
                cameraController!, // Displays the live camera preview.
              ),
            ),
            _modeControlRowWidget(),
            IconButton(
              onPressed: () async {
                // Captures a picture when the camera button is pressed.
                pic = await cameraController!.takePicture();
                
                // Stores the picture in the gallery using the Gal package.
                Gal.putImage(
                  pic!.path,
                );

                setState(() {
                });
              },
              iconSize: 100, // Large camera icon size.
              icon: const Icon(
                Icons.camera, // Red camera icon.
                color: Colors.red,
              )
            ),
            _thumbnailWidget(),
          ],
        )
      ),
    );
  }

  // Sets up the cameracameraController asynchronously.
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

  // Displays the thumbnail of the captured image or video
  Widget _thumbnailWidget(){
    return Expanded(
      child: Align(
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (pic == null)
              Container()
            else
              GestureDetector(
                onTap: (){
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FullscreenImage(imageFile: File(pic!.path)),
                    ),
                  );
                },
                child: SizedBox(
                  width: 64.0,
                  height: 64.0,
                  child: Image.file(
                    File(pic!.path),
                    fit: BoxFit.cover,
                    ),
                  ),
              ),
          ],
        ),
      ),
    );
  }

  //Displays a bar with buttons to change the flash and exposure modes
  Widget _modeControlRowWidget(){
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.flash_on),
              color: Colors.blue,
              onPressed: cameraController != null ? onFlashModeButtonPressed : null,  
            ),
            ...!kIsWeb
              ? <Widget>[
                  IconButton(
                    icon: const Icon(Icons.exposure),
                    color: Colors.blue,
                    onPressed: cameraController != null
                      ? onExposureModeButtonPressed
                      : null, 
                  ),
                  IconButton( 
                    icon: const Icon(Icons.filter_center_focus),
                    color: Colors.blue,
                    onPressed: cameraController != null ? onFocusModeButtonPressed : null, 
                  )
              ]
              : <Widget>[],
            IconButton(
              onPressed: cameraController != null 
                ? onCaptureOrientationLockButtonPressed
                : null, 
              icon: Icon(cameraController?.value.isCaptureOrientationLocked ?? false
                  ? Icons.screen_lock_rotation
                  : Icons.screen_rotation),
              color: Colors.blue,
            ),
          ],
        ),
        _flashModeControlRowWidget(),
        _exposureModeControlRowWidget(),
        _focusModeControlRowWidget(),
      ],
    );
  }
  
  Widget _flashModeControlRowWidget() {
    return SizeTransition(
      sizeFactor: _flashModeControlRowAnimation,
      child: ClipRect(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            IconButton(
              onPressed: cameraController != null
                  ? () => onSetFlashModeButtonPressed(FlashMode.off)
                  : null, 
              icon: const Icon(Icons.flash_off),
              color: cameraController?.value.flashMode == FlashMode.off
                  ? Colors.orange
                  : Colors.blue,
            ),
            IconButton(
              onPressed: cameraController != null 
                  ? () => onSetFlashModeButtonPressed(FlashMode.auto)
                  : null, 
              icon: const Icon(Icons.flash_auto),
              color: cameraController?.value.flashMode == FlashMode.auto 
                  ? Colors.orange
                  : Colors.blue,
            ),
            IconButton(
              onPressed: cameraController != null 
                  ? () => onSetFlashModeButtonPressed(FlashMode.always)
                  : null, 
              icon: const Icon(Icons.flash_on),
              color: cameraController?.value.flashMode == FlashMode.always 
                  ? Colors.orange
                  : Colors.blue,
            ),
            IconButton(
              onPressed: cameraController != null 
                  ? () => onSetFlashModeButtonPressed(FlashMode.torch)
                  : null, 
              icon: const Icon(Icons.highlight),
              color: cameraController?.value.flashMode == FlashMode.torch 
                  ? Colors.orange
                  : Colors.blue,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _exposureModeControlRowWidget() {
    final ButtonStyle styleAuto = TextButton.styleFrom(
      foregroundColor: cameraController?.value.exposureMode == ExposureMode.auto
          ? Colors.orange
          : Colors.blue,
    );
    final ButtonStyle styleLocked = TextButton.styleFrom(
      foregroundColor: cameraController?.value.exposureMode == ExposureMode.locked
          ? Colors.orange
          : Colors.blue,
    );

    return SizeTransition(
      sizeFactor: _exposureModeControlRowAnimation,
      child: ClipRect(
        child: ColoredBox(
          color: Colors.grey.shade50,
          child: Column(
            children: <Widget>[
              const Center(
                child: Text('Exposure Mode'),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  TextButton(
                    style: styleAuto,
                    onPressed: cameraController != null
                        ? () =>
                            onSetExposureModeButtonPressed(ExposureMode.auto)
                        : null,
                    onLongPress: () {
                      if (cameraController != null) {
                      cameraController!.setExposurePoint(null);
                        showInSnackBar('Resetting exposure point');
                      }
                    },
                    child: const Text('AUTO'),
                  ),
                  TextButton(
                    style: styleLocked,
                    onPressed:cameraController != null
                        ? () =>
                            onSetExposureModeButtonPressed(ExposureMode.locked)
                        : null,
                    child: const Text('LOCKED'),
                  ),
                  TextButton(
                    style: styleLocked,
                    onPressed:cameraController != null
                        ? () =>cameraController!.setExposureOffset(0.0)
                        : null,
                    child: const Text('RESET OFFSET'),
                  ),
                ],
              ),
              const Center(
                child: Text('Exposure Offset'),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Text(_minAvailableExposureOffset.toString()),
                  Slider(
                    value: _currentExposureOffset,
                    min: _minAvailableExposureOffset,
                    max: _maxAvailableExposureOffset,
                    label: _currentExposureOffset.toString(),
                    onChanged: _minAvailableExposureOffset ==
                            _maxAvailableExposureOffset
                        ? null
                        : setExposureOffset,
                  ),
                  Text(_maxAvailableExposureOffset.toString()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _focusModeControlRowWidget() {
    final ButtonStyle styleAuto = TextButton.styleFrom(
      foregroundColor: cameraController?.value.focusMode == FocusMode.auto
          ? Colors.orange
          : Colors.blue,
    );
    final ButtonStyle styleLocked = TextButton.styleFrom(
      foregroundColor: cameraController?.value.focusMode == FocusMode.locked
          ? Colors.orange
          : Colors.blue,
    );

    return SizeTransition(
      sizeFactor: _focusModeControlRowAnimation,
      child: ClipRect(
        child: ColoredBox(
          color: Colors.grey.shade50,
          child: Column(
            children: <Widget>[
              const Center(
                child: Text('Focus Mode'),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  TextButton(
                    style: styleAuto,
                    onPressed: cameraController != null
                        ? () => onSetFocusModeButtonPressed(FocusMode.auto)
                        : null,
                    onLongPress: () {
                      if (cameraController != null) {
                        cameraController!.setFocusPoint(null);
                      }
                      showInSnackBar('Resetting focus point');
                    },
                    child: const Text('AUTO'),
                  ),
                  TextButton(
                    style: styleLocked,
                    onPressed: cameraController != null
                        ? () => onSetFocusModeButtonPressed(FocusMode.locked)
                        : null,
                    child: const Text('LOCKED'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showInSnackBar(String message){
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void onFlashModeButtonPressed(){
    if (_flashModeControlRowAnimationController.value == 1) {
      _flashModeControlRowAnimationController.reverse();
    } else {
      _flashModeControlRowAnimationController.forward();
      _exposureModeControlRowAnimationController.reverse();
      _focusModeControlRowAnimationController.reverse();
    }
  }

  void onExposureModeButtonPressed(){
    if (_exposureModeControlRowAnimationController.value == 1) {
      _exposureModeControlRowAnimationController.reverse();
    } else {
      _exposureModeControlRowAnimationController.forward();
      _flashModeControlRowAnimationController.reverse();
      _focusModeControlRowAnimationController.reverse();
    }
  }

  void onFocusModeButtonPressed(){
    if (_focusModeControlRowAnimationController.value == 1) {
      _focusModeControlRowAnimationController.reverse();
    } else {
      _focusModeControlRowAnimationController.forward();
      _flashModeControlRowAnimationController.reverse();
      _exposureModeControlRowAnimationController.reverse();
    }
  }

  void onSetFlashModeButtonPressed(FlashMode mode){
    setFlashMode(mode).then((_) {
      if (mounted) {
        setState(() {});
      }
      showInSnackBar('Flash mode set to ${mode.toString().split('.').last}');
    });
  }

  void onSetExposureModeButtonPressed(ExposureMode mode){
    setExposureMode(mode).then((_) {
      if (mounted) {
        setState(() {});
      }
      showInSnackBar('Exposure mode set to ${mode.toString().split('.').last}');
    });
  }

  void onSetFocusModeButtonPressed(FocusMode mode){
    setFocusMode(mode).then((_) {
      if (mounted) {
        setState(() {});
      }
      showInSnackBar('Focus mode set to ${mode.toString().split('.').last}');
    });
  }

  Future<void> onCaptureOrientationLockButtonPressed() async {
    try {
      if (cameraController != null) {
        final CameraController controller = cameraController!;
        if (controller.value.isCaptureOrientationLocked) {
          await controller.unlockCaptureOrientation();
          showInSnackBar('Capture orientation unlocked');
        } else {
          await controller.lockCaptureOrientation();
          showInSnackBar(
              'Capture orientation locked to ${controller.value.lockedCaptureOrientation.toString().split('.').last}');
        }
      }
    } on CameraException catch (e) {
      _showCameraException(e);
    }
  }

  Future<void> setFlashMode(FlashMode mode) async {
    if (cameraController == null) {
      return;
    }

    try {
      await cameraController!.setFlashMode(mode);
    } on CameraException catch (e) {
      _showCameraException(e);
      rethrow;
    }
  }

  Future<void> setExposureMode(ExposureMode mode) async {
    if (cameraController == null) {
      return;
    }

    try {
      await cameraController!.setExposureMode(mode);
    } on CameraException catch (e) {
      _showCameraException(e);
      rethrow;
    }
  }

  Future<void> setExposureOffset(double offset) async {
    if (cameraController == null) {
      return;
    }

    setState(() {
      _currentExposureOffset = offset;
    });
    try {
      offset = await cameraController!.setExposureOffset(offset);
    } on CameraException catch (e) {
      _showCameraException(e);
      rethrow;
    }
  }

  Future<void> setFocusMode(FocusMode mode) async {
    if (cameraController == null) {
      return;
    }

    try {
      await cameraController!.setFocusMode(mode);
    } on CameraException catch (e) {
      _showCameraException(e);
      rethrow;
    }
  }

  void _showCameraException(CameraException e){
    _logError(e.code, e.description);
    showInSnackBar('Error: ${e.code}\n${e.description}');
  }

  void _logError(String code, String? message){
    print('Error: $code${message == null ? '' : '\nError Message: $message'}');
  }





  
}