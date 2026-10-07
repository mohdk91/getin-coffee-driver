import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class DriverVideoSplash extends StatefulWidget {
  const DriverVideoSplash({super.key});

  @override
  State<DriverVideoSplash> createState() => _DriverVideoSplashState();
}

class _DriverVideoSplashState extends State<DriverVideoSplash> {
  static const _backgroundColor = Color(0xFF152A23);
  static const _videoAsset = 'assets/video/driver_splash.mp4';
  static const _startPoster =
      'assets/images/splash/driver_splash_start.jpg';
  static const _endPoster = 'assets/images/splash/driver_splash_end.jpg';

  VideoPlayerController? _controller;
  bool _videoReady = false;
  bool _showEndPoster = false;

  @override
  void initState() {
    super.initState();
    unawaited(_initializeVideo());
  }

  Future<void> _initializeVideo() async {
    final controller = VideoPlayerController.asset(
      _videoAsset,
      videoPlayerOptions: VideoPlayerOptions(
        allowBackgroundPlayback: false,
        mixWithOthers: false,
      ),
    );
    _controller = controller;

    try {
      await controller.initialize();
      await controller.setLooping(false);
      await controller.setVolume(0);
      controller.addListener(_handlePlaybackState);

      if (!mounted) {
        controller.removeListener(_handlePlaybackState);
        await controller.dispose();
        return;
      }

      setState(() => _videoReady = true);
      await controller.play();
    } catch (_) {
      // The native launch background + poster remain a safe visual fallback.
      // Startup must continue even if the video decoder is unavailable.
      if (!mounted) return;
      setState(() => _showEndPoster = true);
    }
  }

  void _handlePlaybackState() {
    final controller = _controller;
    if (!mounted || controller == null || _showEndPoster) return;

    final value = controller.value;
    if (!value.isInitialized || value.duration <= Duration.zero) return;

    const endHoldThreshold = Duration(milliseconds: 90);
    if (value.position >= value.duration - endHoldThreshold) {
      setState(() => _showEndPoster = true);
    }
  }

  @override
  void dispose() {
    final controller = _controller;
    if (controller != null) {
      controller.removeListener(_handlePlaybackState);
      unawaited(controller.dispose());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _backgroundColor,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            _startPoster,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.medium,
          ),
          if (_videoReady && _controller != null)
            AnimatedOpacity(
              opacity: _showEndPoster ? 0 : 1,
              duration: const Duration(milliseconds: 90),
              child: _CoverVideo(controller: _controller!),
            ),
          IgnorePointer(
            child: AnimatedOpacity(
              opacity: _showEndPoster ? 1 : 0,
              duration: const Duration(milliseconds: 90),
              child: Image.asset(
                _endPoster,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverVideo extends StatelessWidget {
  final VideoPlayerController controller;

  const _CoverVideo({required this.controller});

  @override
  Widget build(BuildContext context) {
    final size = controller.value.size;
    if (size.width <= 0 || size.height <= 0) {
      return const SizedBox.expand();
    }

    return ClipRect(
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: VideoPlayer(controller),
          ),
        ),
      ),
    );
  }
}
