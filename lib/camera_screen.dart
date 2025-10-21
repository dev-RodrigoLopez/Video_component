import 'dart:async';
import 'package:camera/camera.dart';
import 'package:device_orientation/device_orientation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import 'video_preview_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? cameras;
  Timer? timer;
  int maxDuration = 15; // 60 seconds
  int currentDuration = 0;
  bool isRecording = false;

  double _currentZoom = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 4.0;


  late StreamSubscription<DeviceOrientation> _changeDeviceOrientation;
  bool _isOrientationListenerInitialized = false;
  DeviceOrientation currentOrientation = DeviceOrientation.portraitUp;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isOrientationListenerInitialized) {
      _isOrientationListenerInitialized = true;
      _changeDeviceOrientation = deviceOrientation$.listen((orientation) async {
        setState(() {
          currentOrientation = orientation;
        });
        // Aquí puedes guardar la orientación si necesitas
      });
    }
  }

  Future<void> _initializeCamera() async {
    if (await Permission.camera.request().isGranted &&
        await Permission.microphone.request().isGranted) {
      cameras = await availableCameras();
      _controller = CameraController(
        cameras!.first,
        ResolutionPreset.high,
        enableAudio: true,
      );

      await _controller!.initialize();

      // Obtener los niveles de zoom soportados
      _minZoom = await _controller!.getMinZoomLevel();
      _maxZoom = await _controller!.getMaxZoomLevel();
      _currentZoom = _minZoom;

      await _controller!.setZoomLevel(_currentZoom);

      setState(() {});
    } else {
      // Permisos denegados
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Permisos de cámara o micrófono denegados")),
      );
    }
  }

  void _startRecording() async {
    if (!_controller!.value.isInitialized) return;

    await _controller!.startVideoRecording();
    isRecording = true;
    currentDuration = 0;

    timer = Timer.periodic(Duration(seconds: 1), (Timer t) async {
      currentDuration++;
      if (currentDuration >= maxDuration) {
        _stopRecording();
      }
      setState(() {});
    });

    setState(() {});
  }

  void _stopRecording() async {
    if (_controller!.value.isRecordingVideo) {
      timer?.cancel();
      final file = await _controller!.stopVideoRecording();

      final minZoom = await _controller!.getMinZoomLevel();
      await _controller!.setZoomLevel(minZoom);

      // Navigator.pop(context, file.path);

      setState(() {
        currentDuration = 0;
        isRecording = false;
        _currentZoom = minZoom;
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPreviewScreen(videoPath: file.path),
        ),
      );
    }
  }

  @override
  void dispose() {
    _currentZoom = 0;
    _changeDeviceOrientation.cancel();
    timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    if (_controller == null || !_controller!.value.isInitialized) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return OrientationBuilder(
      builder: (context, orientation) {

        final isPortrait = orientation == Orientation.portrait;
        final size = MediaQuery.of(context).size;

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [


              RotatedBox(
                quarterTurns: ( _controller!.value.isRecordingVideo ) 
                  ? isPortrait 
                    ? 0 
                    :  ( currentOrientation == DeviceOrientation.landscapeLeft ) ? 1 : 3
                  : isPortrait ? 0 : 4,
                child: Center(child: CameraPreview(_controller!))
              ),
             
              if (isRecording) ...[
                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: (isPortrait) ? size.height * 0.04 : size.height * 0.03
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        '00:00:${currentDuration.toString().padLeft(2, '0')}',
                        style: const TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  ),
                ),
              ],

              if (isRecording) ...[
                Align(
                  alignment: isPortrait ? Alignment.bottomCenter : Alignment.centerRight,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.all(Radius.circular(50)),
                      onTap: _stopRecording,
                      child: Ink(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.all(Radius.circular(50)),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(25) ,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(5)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              if (!isRecording) ...[
                Align(
                  alignment: isPortrait ? Alignment.bottomCenter : Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: (isPortrait) ? size.height * 0.04 : 0,
                      right:  (!isPortrait) ? size.width * 0.03 : 0
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.all(Radius.circular(50)),
                        onTap: _startRecording,
                        child: Ink(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.all(Radius.circular(50)),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(5),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(50)),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              // if (isRecording) ...[
              //   Align(
              //     alignment: isPortrait ? Alignment.bottomCenter : Alignment.centerRight,
              //     child: Padding(
              //       padding: EdgeInsets.only(
              //         bottom: (isPortrait) ? size.height * 0.1 : 0,
              //         right:  (!isPortrait) ? size.width * 0.03 : 0
              //       ),
              //       child: CenteredSlider(
              //         min: _minZoom,
              //         max: _maxZoom,
              //         initialValue: _currentZoom,
              //         isLandscape: !isPortrait,
              //         onChanged: (value) {
              //           setState(() {
              //             _currentZoom = value;
              //           });
              //           _controller?.setZoomLevel(_currentZoom);
              //         },
              //       ),
              //     ),
              //   ),
              // ],
            ],
          ),
        );
      },
    );
  }

}


class CenteredSlider extends StatefulWidget {
  final double min;
  final double max;
  final double initialValue;
  final ValueChanged<double>? onChanged;
  final bool isLandscape;

  const CenteredSlider({
    super.key,
    this.min = 0,
    this.max = 10,
    this.initialValue = 0,
    this.onChanged,
    this.isLandscape = false,
  });

  @override
  State<CenteredSlider> createState() => _CenteredSliderState();
}

class _CenteredSliderState extends State<CenteredSlider> {
  late double _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue;
  }

@override
Widget build(BuildContext context) {
  final size = MediaQuery.of(context).size;

  final slider = SliderTheme(
    data: SliderTheme.of(context).copyWith(
      trackHeight: 2,
      activeTrackColor: Colors.white,
      inactiveTrackColor: Colors.white30,
      thumbColor: Colors.white,
      overlayColor: Colors.white24,
      valueIndicatorColor: Colors.black,
    ),
    child: Slider(
      value: _currentValue,
      min: widget.min,
      max: widget.max,
      onChanged: (value) {
        setState(() => _currentValue = value);
        widget.onChanged?.call(value);
      },
    ),
  );

  return widget.isLandscape
    ? Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _currentValue.toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          RotatedBox(
            quarterTurns: 3,
            child: SizedBox(
              height: size.height * 0.4,
              child: slider,
            ),
          ),
        ],
      )
    : Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _currentValue.toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(
            width: size.width * 0.8,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 2,
                  color: Colors.white30,
                ),
                slider,
              ],
            ),
          ),
        ],
      );
  }
}
