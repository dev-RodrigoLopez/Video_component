import 'dart:async';
import 'package:camera/camera.dart';
import 'package:device_orientation/device_orientation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import 'video_preview_screen.dart';

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? cameras;
  Timer? timer;
  int maxDuration = 15; // 60 seconds
  int currentDuration = 0;
  bool isRecording = false;

  double _currentZoom = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 4.0;

  double _baseZoom = 1.0;

  late StreamSubscription<DeviceOrientation> _changeDeviceOrientation;
  bool _isOrientationListenerInitialized = false;
  DeviceOrientation currentOrientation = DeviceOrientation.portraitUp;

  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    _initializeCamera();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isOrientationListenerInitialized) {
      _isOrientationListenerInitialized = true;
      _changeDeviceOrientation = deviceOrientation$.listen((orientation) async {
        setState(() {
          print('---- $orientation');
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

  Future<void> _setZoom(double value) async {
    if (_controller == null) return;
    final clamped = value.clamp(_minZoom, _maxZoom);
    if ((clamped - _currentZoom).abs() < 0.01) return;
    setState(() => _currentZoom = clamped);
    await _controller!.setZoomLevel(_currentZoom);
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
      //await _controller!.setZoomLevel(minZoom);
      await _setZoom(minZoom);

      // Navigator.pop(context, file.path);
      
      setState(() {
        currentDuration = 0;
        isRecording = false;
        //_currentZoom = minZoom;
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
    timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    if (_controller == null || !_controller!.value.isInitialized) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onScaleStart: isRecording
                ? (_)=> _baseZoom = _currentZoom
                : null,
              onScaleUpdate: isRecording
                ? (details){
                  if(details.pointerCount <2) return;
                    _setZoom(_baseZoom*details.scale);
                }
                : null,
                child: CameraPreview(_controller!)
                ),
              ),

          if( isRecording ) ... [
            Align(
              alignment: (currentOrientation == DeviceOrientation.portraitUp) 
                ? Alignment.topCenter 
                : (currentOrientation == DeviceOrientation.landscapeLeft) 
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.only(
                  top : (currentOrientation == DeviceOrientation.portraitUp) ? size.height * 0.08 : 0,
                  left: (currentOrientation == DeviceOrientation.landscapeLeft) ? size.height * 0.01 : 0,
                  right: (currentOrientation == DeviceOrientation.landscapeRight) ? size.height * 0.01 : 0
                ),
                child: RotatedBox(
                  quarterTurns: (currentOrientation == DeviceOrientation.portraitUp) 
                    ? 0 
                    : (currentOrientation == DeviceOrientation.landscapeLeft) 
                      ? 3  
                      : 1,
                  child: Container(
                    width: size.width * 0.25,
                    height: size.height * 0.03,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Center(
                      child: Text(
                        '00:00:${currentDuration.toString().padLeft(2, '0')}',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],

          if( isRecording ) ... [
            Positioned(
              bottom: size.height * 0.08,
              left: size.width * 0.4,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.all(Radius.circular(50)),
                  onTap:  _stopRecording,
                  child: Ink(
                    width: size.height * 0.1,
                    height: size.height * 0.1,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.all(Radius.circular(50)),
                    ),
                    child: Padding(
                      padding:  EdgeInsets.all(
                        size.height * 0.025
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.all(Radius.circular(5)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],

          if( !isRecording ) ... [
            Positioned(
              bottom: size.height * 0.08,
              left: size.width * 0.4,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.all(Radius.circular(50)),
                  onTap:  _startRecording,
                  child: Ink(
                    width: size.height * 0.1,
                    height: size.height * 0.1,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.all(Radius.circular(50)),
                    ),
                    child: Padding(
                      padding:  EdgeInsets.all(
                        size.height * 0.008
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.all(Radius.circular(50)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],

          // if( isRecording )...[
          //   Positioned(
          //     bottom: size.height * 0.13,
          //     left: size.width * 0.1,
          //     child: Padding(
          //       padding: const EdgeInsets.only(bottom: 40),
          //       child: CenteredSlider(
          //         min: _minZoom,
          //         max: _maxZoom,
          //         value: _currentZoom,
          //         onChanged: _setZoom,
          //         // onChanged: (value) {
          //         //   setState(() { _currentZoom = value; });
          //         //   _controller?.setZoomLevel(_currentZoom);
          //         // },
          //       ),
          //     ),
          //   ),

          // ]

          
        ],
      ),
    );
  }
}

class CenteredSlider extends StatefulWidget {
  final double min;
  final double max;
  //final double initialValue;
  final double value;
  final ValueChanged<double> onChanged;

  const CenteredSlider({super.key, 
    this.min = 0,
    this.max = 10,
    //this.initialValue = 0,
    required this.value,
    required this.onChanged,
    //this.onChanged,
  });

  @override
  State<CenteredSlider> createState() => _CenteredSliderState();
}

class _CenteredSliderState extends State<CenteredSlider> {
  //late double _currentValue;


  // @override
  // void initState() {
  //   super.initState();
  //   _currentValue = widget.initialValue;

  // }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Valor actual
        Text(
          widget.value.toStringAsFixed(1),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        // Slider centrado
        SizedBox(
          width: size.width * 0.8,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Línea base (para resaltar el centro)
              Container(
                height: 2,
                color: Colors.white30,
              ),

              // Slider principal
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 2,
                  activeTrackColor: Colors.white,
                  inactiveTrackColor: Colors.white30,
                  thumbColor: Colors.white,
                  overlayColor: Colors.white24,
                  valueIndicatorColor: Colors.black,
                ),
                child: Slider(
                  value: widget.value,
                  min: widget.min,
                  max: widget.max,
                  onChanged: widget.onChanged,
                  // divisions: ((widget.max - widget.min) * 2).round(),
                //  onChanged: (value) {
                //     setState(() => _currentValue = value); 
                //     widget.onChanged?.call(value);
                //   },
                ),
              ),

            ],
          ),
        ),


      ],
    );
  }
}
