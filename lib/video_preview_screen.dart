import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

class VideoPreviewScreen extends StatefulWidget {
  final String videoPath;

  VideoPreviewScreen({required this.videoPath});

  @override
  _VideoPreviewScreenState createState() => _VideoPreviewScreenState();
}

class _VideoPreviewScreenState extends State<VideoPreviewScreen> {
  late VideoPlayerController _controller;
  bool isRecording = false;

  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    _controller = VideoPlayerController.file(File(widget.videoPath))
      ..initialize().then((_) {
        setState(() {});

      });
      _controller.addListener(_videoListener);
  }

  @override
  void dispose() {
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }

  void _acceptVideo() {
    Navigator.pop(context);
    Navigator.pop(context, widget.videoPath); 
  }

  void _retakeVideo() {
    Navigator.pop(context);
  }

  void _videoListener() {
    final bool isFinished = _controller.value.position >= _controller.value.duration;

    if (isFinished && isRecording ) {
      _controller.seekTo(Duration.zero);
      setState(() {
        isRecording = false;
      });
    } 
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.black,
      // appBar: AppBar(title: Text("Preview")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_controller.value.isInitialized)
            AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            )
          else
            Center(child: CircularProgressIndicator()),

          if( _controller.value.isInitialized ) ... [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: (){
                    _retakeVideo();
                  }, 
                  icon: Icon(
                    Icons.cancel_outlined,
                    size: size.width * 0.15,
                    color: Colors.red,
                  )
                ),

                IconButton(
                  onPressed: (){
                    if( isRecording ) {
                      setState(() {
                        isRecording = false;
                      });
                      _controller.pause();
                    } else {
                        setState(() {
                          isRecording = true;
                        });
                        _controller.play();
                    }

                  }, 
                  icon: Icon(
                    isRecording ? Icons.pause : Icons.play_circle_outline,
                    size: size.width * 0.15,
                    color: Colors.white,
                    weight: 1,
                  )
                ),

                IconButton(
                  onPressed: (){
                    _acceptVideo();
                  }, 
                  icon: Icon(
                    Icons.check_circle_outline_outlined,
                    size: size.width * 0.15,
                    color: Colors.green,
                    weight: 1,
                  )
                ),
                            
              ],
            )
          ]
        ],
      ),
    );
  }
}
