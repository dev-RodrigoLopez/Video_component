import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

class FullscreenVideoScreen extends StatefulWidget {
  final String videoPath;

  const FullscreenVideoScreen({
    required this.videoPath,
    super.key,
  });

  @override
  State<FullscreenVideoScreen> createState() => _FullscreenVideoScreenState();
}

class _FullscreenVideoScreenState extends State<FullscreenVideoScreen> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isJumping = false;

  @override
  void initState() {
    super.initState();
    
    // Mantener en vertical
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    _controller = VideoPlayerController.file(File(widget.videoPath))
      ..initialize().then((_) {
        setState(() {
          _totalDuration = _controller.value.duration;
        });
        // Iniciar reproducción automáticamente
        _controller.play();
        _isPlaying = true;
      });
    
    _controller.addListener(_videoListener);
  }

  void _videoListener() {
    if (mounted) {
      setState(() {
        _currentPosition = _controller.value.position;
        if (!_isJumping) {
          _isPlaying = _controller.value.isPlaying;
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }

  void _closeScreen() {
    Navigator.pop(context);
  }

  void _buttonPlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _isPlaying = false;
      } else {
        _controller.play();
        _isPlaying = true;
      }
    });
  }

  void _seekBackward() {
    final currentPosition = _controller.value.position;
    final newPosition = currentPosition - const Duration(seconds: 5);
    
    setState(() {
      _isJumping = true;
    });
    
    if (newPosition < Duration.zero) {
      _controller.seekTo(Duration.zero).then((_) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            setState(() {
              _isJumping = false;
            });
          }
        });
      });
    } else {
      _controller.seekTo(newPosition).then((_) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            setState(() {
              _isJumping = false;
            });
          }
        });
      });
    }
  }

  void _seekForward() {
    final currentPosition = _controller.value.position;
    final newPosition = currentPosition + const Duration(seconds: 5);
    final duration = _controller.value.duration;
    
    setState(() {
      _isJumping = true;
    });
    
    if (newPosition > duration) {
      _controller.seekTo(duration).then((_) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            setState(() {
              _isJumping = false;
            });
          }
        });
      });
    } else {
      _controller.seekTo(newPosition).then((_) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            setState(() {
              _isJumping = false;
            });
          }
        });
      });
    }
  }

  void _onProgressBarTap(double value) {
    final duration = _controller.value.duration;
    final newPosition = Duration(
      milliseconds: (duration.inMilliseconds * value).round(),
    );
    
    setState(() {
      _isJumping = true;
    });
    
    _controller.seekTo(newPosition).then((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          setState(() {
            _isJumping = false;
          });
        }
      });
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: _controller.value.isInitialized
                ? AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  )
                : const CircularProgressIndicator(
                    color: Colors.white,
                  ),
          ),
          // Boton cerrar
          Positioned(
            top: MediaQuery.of(context).padding.top + (size.height * 0.07),
            right: size.width * 0.05,
            child: GestureDetector(
              onTap: _closeScreen,
              child: Container(
                width: size.width * 0.12,
                height: size.width * 0.12,
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  color: Colors.white,
                  size: size.width * 0.07,
                ),
              ),
            ),
          ),

          // Botones de control
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + (size.height * 0.06),
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.05,
                vertical: size.height * 0.02,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Barra de progreso
                  Row(
                    children: [
                      Text(
                        _formatDuration(_currentPosition),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: size.width * 0.035,
                        ),
                      ),
                      SizedBox(width: size.width * 0.02),
                      Expanded(
                        child: GestureDetector(
                          onTapDown: (details) {
                            final RenderBox box = context.findRenderObject() as RenderBox;
                            final Offset localOffset = box.globalToLocal(details.globalPosition);
                            
                            // Calcular el ancho disponible para la barra de progreso
                            final double leftPadding = size.width * 0.05 + size.width * 0.12 + size.width * 0.02;
                            final double rightPadding = size.width * 0.02 + size.width * 0.12;
                            final double progressBarWidth = size.width - leftPadding - rightPadding;
                            
                            // Calcular la posición relativa en la barra
                            final double tapX = localOffset.dx - leftPadding;
                            final double progress = (tapX / progressBarWidth).clamp(0.0, 1.0);
                            
                            _onProgressBarTap(progress);
                          },
                          child: Container(
                            height: size.height * 0.013,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(size.height * 0.004),
                              color: Colors.white.withOpacity(0.3),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: _totalDuration.inMilliseconds > 0
                                  ? _currentPosition.inMilliseconds / _totalDuration.inMilliseconds
                                  : 0.0,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(size.height * 0.004),
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: size.width * 0.02),
                      Text(
                        _formatDuration(_totalDuration),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: size.width * 0.035,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: size.height * 0.015),
                  
                  // Botones de control
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      
                      GestureDetector(
                        onTap: _seekBackward,
                        child: Container(
                          width: size.width * 0.12,
                          height: size.width * 0.12,
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.replay_5,
                            color: Colors.white,
                            size: size.width * 0.06,
                          ),
                        ),
                      ),
                      
                      GestureDetector(
                        onTap: _buttonPlayPause,
                        child: Container(
                          width: size.width * 0.15,
                          height: size.width * 0.15,
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: size.width * 0.1,
                          ),
                        ),
                      ),
                      
                      GestureDetector(
                        onTap: _seekForward,
                        child: Container(
                          width: size.width * 0.12,
                          height: size.width * 0.12,
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.forward_5,
                            color: Colors.white,
                            size: size.width * 0.06,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}