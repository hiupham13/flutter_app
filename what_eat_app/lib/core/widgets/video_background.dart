import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../providers/video_provider.dart';

class VideoBackground extends ConsumerWidget {
  final String videoPath;
  final Widget child;

  const VideoBackground({
    super.key,
    required this.videoPath,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(videoControllerProvider);

    // Nếu controller chưa sẵn sàng, hiển thị fallback với màu tối
    if (controller == null || !controller.value.isInitialized) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black.withOpacity(0.8),
              Colors.black.withOpacity(0.6),
            ],
          ),
        ),
        child: child,
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Video background - KHÔNG blur, video rõ như gốc
        Positioned.fill(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: controller.value.size.width,
              height: controller.value.size.height,
              child: VideoPlayer(controller),
            ),
          ),
        ),
        // Dark overlay nhẹ để text dễ đọc hơn (như hình mẫu)
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
            ),
          ),
        ),
        // Content
        child,
      ],
    );
  }
}
