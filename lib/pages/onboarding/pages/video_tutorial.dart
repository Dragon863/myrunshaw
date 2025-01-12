import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:runshaw/utils/config.dart';
import 'package:runshaw/utils/theme/appbar.dart';
import 'package:video_player/video_player.dart';

class VideoTutorial extends StatefulWidget {
  const VideoTutorial({super.key});

  @override
  _VideoTutorialState createState() => _VideoTutorialState();
}

class _VideoTutorialState extends State<VideoTutorial> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(
        Uri.parse(
          MyRunshawConfig.tutorialVideoUrl,
        ),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true,
        ))
      ..initialize().then((_) {
        // Play the video once it's loaded
        setState(() {
          _controller.play();
        });
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const RunshawAppBar(title: "Video Tutorial"),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              constraints: const BoxConstraints(maxHeight: 700),
              child: Center(
                child: _controller.value.isInitialized
                    ? AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: VideoPlayer(_controller),
                      )
                    : Container(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Center(
                  child: Text(
                    "Once you have copied this link, click the back button above and paste it into the text input.",
                    style: GoogleFonts.rubik(
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _controller.value.isPlaying
                ? _controller.pause()
                : _controller.play();
          });
        },
        child: Icon(
          _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
