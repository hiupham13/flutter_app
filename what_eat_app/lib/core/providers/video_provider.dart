import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

class VideoControllerNotifier extends StateNotifier<VideoPlayerController?> {
  VideoControllerNotifier() : super(null);

  Future<void> initializeVideo(String videoPath) async {
    // Nếu đã có controller và đang chạy, không cần khởi tạo lại
    if (state != null && state!.value.isInitialized) {
      return;
    }

    try {
      final controller = VideoPlayerController.asset(videoPath);
      await controller.initialize();
      controller.setLooping(true);
      controller.setVolume(0.0);
      controller.play();
      state = controller;
    } catch (e) {
      debugPrint('Video initialization error: $e');
      state = null;
    }
  }

  @override
  void dispose() {
    state?.dispose();
    super.dispose();
  }
}

final videoControllerProvider =
    StateNotifierProvider<VideoControllerNotifier, VideoPlayerController?>((ref) {
  final notifier = VideoControllerNotifier();
  // Preload video khi provider được tạo
  notifier.initializeVideo('assets/videos/1214.mp4');
  return notifier;
});

