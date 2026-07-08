import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:runshaw/utils/config.dart';
import 'package:runshaw/utils/theme/appbar.dart';
import 'package:video_player/video_player.dart';

class VideoTutorial extends StatefulWidget {
  const VideoTutorial({super.key});

  @override
  State<VideoTutorial> createState() => _VideoTutorialState();
}

class _VideoTutorialState extends State<VideoTutorial> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(MyRunshawConfig.tutorialVideoUrl),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    )..initialize().then((_) {
        setState(() => _controller.play());
      });

    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isInitialized = _controller.value.isInitialized;

    return Scaffold(
      appBar: const RunshawAppBar(title: "Video Tutorial"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio:
                    isInitialized ? _controller.value.aspectRatio : 16 / 9,
                child: isInitialized
                    ? VideoPlayer(_controller)
                    : const ColoredBox(
                        color: Colors.black,
                        child: Center(
                            child:
                                CircularProgressIndicator(color: Colors.white)),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            VideoProgressIndicator(
              _controller,
              allowScrubbing: true,
              padding: const EdgeInsets.symmetric(vertical: 4),
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(isInitialized && _controller.value.isPlaying
                      ? Icons.pause
                      : Icons.play_arrow),
                  onPressed: isInitialized
                      ? () => setState(() {
                            _controller.value.isPlaying
                                ? _controller.pause()
                                : _controller.play();
                          })
                      : null,
                ),
                if (isInitialized) ...[
                  Text(
                    _formatDuration(_controller.value.position),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    ' / ${_formatDuration(_controller.value.duration)}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Text(
                "Once you have copied this link, click the back button above and paste it into the text input.",
                style: GoogleFonts.rubik(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
