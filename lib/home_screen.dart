import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_component/camera_screen.dart';
import 'package:video_player/video_player.dart';


class HomeScreen extends StatefulWidget {
  HomeScreen({
    super.key
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  bool showPreview = false;
  String path = '';

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Center(
        child: ButtonVideo(
          showPreview: showPreview,
          path: path,
          onTap: () async{
            final videoPath = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CameraScreen(),
              ),
            );
        
            if( videoPath != null ) {
              setState(() {
                showPreview = true;
                path = videoPath;
              });    
            }
        
          }
        )
      ),
    );
  }
}


class ButtonVideo extends StatelessWidget {
  const ButtonVideo({
    required this.path,
    required this.showPreview,
    required this.onTap,
    super.key
  });

  final bool showPreview;
  final String path;
  final Function() onTap;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return SizedBox(
      height: size.height * 0.5,
      width: size.width * 0.6,

      child: ( showPreview )  
        ? MiniPreviewVideo(videoPath: path) 
        : InkWell(
          onTap: onTap,
          child: Ink(             // height: size.height * 0.2,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(20)),
              border: Border.all( 
                color: Colors.black,
                width: 2
              )
            ),
            child: Center(
              child:Icon(
                showPreview ? Icons.play_arrow :  Icons.video_call,
                color: Colors.black,
                size: size.height * 0.2,
              ),
            ),
          ),
      ),
    );
  }
}

class MiniPreviewVideo extends StatefulWidget {
  MiniPreviewVideo({
    required this.videoPath,
    super.key
  });

  String videoPath;
  @override
  State<MiniPreviewVideo> createState() => _MiniPreviewVideoState();
}

class _MiniPreviewVideoState extends State<MiniPreviewVideo> {
  late VideoPlayerController _controller;

  @override
 void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.videoPath))
      ..initialize().then((_) {
        setState(() {});

      });
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: VideoPlayer(_controller),
    );
  }
}