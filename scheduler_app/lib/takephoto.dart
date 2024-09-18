import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';

class TakePhoto extends StatefulWidget {
  const TakePhoto({super.key});

  @override
  State<TakePhoto> createState() => _TakePhotoState();
}

class _TakePhotoState extends State<TakePhoto> with WidgetsBindingObserver {
  List<CameraDescription> cameras = [];
  CameraController? cameraController;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (cameraController == null || cameraController?.value.isInitialized == false){
      return;
    }

    if (state == AppLifecycleState.inactive){
      cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed){
      _setupCameraController();
    }
  }

  @override
  void initState() {
    super.initState();
    _setupCameraController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildUI(),
    );
  }

  Widget _buildUI(){
    if (cameraController?.value.isInitialized == false){
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    return SafeArea(
      child: SizedBox.expand(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.30,
              width: MediaQuery.sizeOf(context).width * 0.80,
              child: CameraPreview(
                cameraController!,
              ),
            ),
            IconButton(
              onPressed: () async {
                XFile pic = await cameraController!.takePicture();
                Gal.putImage(
                  pic.path,
                );
              },
              iconSize: 100, 
              icon: const Icon(
                Icons.camera,
                color: Colors.red,
              )
            )
          ],
        )
      ),
    );
  }

  Future<void> _setupCameraController() async{
    List<CameraDescription> cameras = await availableCameras();
    if (cameras.isNotEmpty){
      setState(() {
        cameras = cameras;
        cameraController = CameraController(
          cameras.first, 
          ResolutionPreset.high,
          );
      });
      cameraController?.initialize().then((_) {
        if(!mounted){
          return;
        }
        setState(() {});
      }).catchError(
        (Object e){},
      );
    }
  }
}