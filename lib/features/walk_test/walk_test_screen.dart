import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/providers.dart';

class WalkTestScreen extends ConsumerWidget {
  const WalkTestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walkTestStatus = ref.watch(walkTestProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Walk Test'),
        leading: walkTestStatus.state != WalkTestState.idle
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  ref.read(walkTestProvider.notifier).cancelTest();
                },
              )
            : null,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _buildContent(context, ref, walkTestStatus),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    WalkTestStatus status,
  ) {
    switch (status.state) {
      case WalkTestState.idle:
        return _buildIdleState(context, ref);
      case WalkTestState.preparing:
        return _buildPreparingState(context);
      case WalkTestState.collecting:
        return _buildCollectingState(context, ref, status);
      case WalkTestState.analyzing:
        return _buildAnalyzingState(context);
      case WalkTestState.completed:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final result = status.result;
          if (result != null) {
            ref.read(walkTestProvider.notifier).reset();
            context.pushReplacement('/result');
          }
        });
        return const SizedBox.shrink();
      case WalkTestState.error:
        return _buildErrorState(context, ref, status.errorMessage);
    }
  }

  Widget _buildIdleState(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.directions_walk_rounded,
            size: 100,
            color: AppColors.secondary,
          ),
        )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .scale(
              begin: const Offset(1.0, 1.0),
              end: const Offset(1.05, 1.05),
              duration: 1500.ms,
            ),
        const SizedBox(height: 40),
        Text(
          'Walk Test',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: AppColors.primary,
                size: 32,
              ),
              const SizedBox(height: 12),
              Text(
                AppConstants.walkTestInstruction,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              ref.read(walkTestProvider.notifier).startTest();
            },
            icon: const Icon(Icons.play_arrow_rounded, size: 28),
            label: const Text(
              'Start Test',
              style: TextStyle(fontSize: 18),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              padding: const EdgeInsets.symmetric(vertical: 18),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreparingState(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.hourglass_empty_rounded,
            size: 100,
            color: AppColors.warning,
          ),
        )
            .animate(onPlay: (controller) => controller.repeat())
            .rotate(duration: 2000.ms),
        const SizedBox(height: 40),
        Text(
          'Get Ready...',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 16),
        Text(
          'Place your phone in your pocket',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Starting in 3 seconds',
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildCollectingState(
    BuildContext context,
    WidgetRef ref,
    WalkTestStatus status,
  ) {
    final progress = (30 - status.remainingSeconds) / 30;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularPercentIndicator(
          radius: 120,
          lineWidth: 15,
          percent: progress,
          center: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${status.remainingSeconds}',
                style: const TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const Text(
                'seconds',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          progressColor: AppColors.primary,
          backgroundColor: AppColors.primary.withValues(alpha: 0.2),
          circularStrokeCap: CircularStrokeCap.round,
          animation: true,
          animateFromLastPercent: true,
          animationDuration: 500,
        ),
        const SizedBox(height: 48),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            5,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: index < (progress * 5).ceil()
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.directions_walk_rounded,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 8),
              Text(
                'Walking...',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        TextButton(
          onPressed: () {
            ref.read(walkTestProvider.notifier).cancelTest();
          },
          child: const Text('Cancel Test'),
        ),
      ],
    );
  }

  Widget _buildAnalyzingState(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.psychology_rounded,
            size: 100,
            color: AppColors.primary,
          ),
        )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .scale(
              begin: const Offset(1.0, 1.0),
              end: const Offset(1.1, 1.1),
              duration: 1000.ms,
            ),
        const SizedBox(height: 40),
        Text(
          'Analyzing...',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 16),
        Text(
          'Processing your gait data',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: 200,
          child: LinearProgressIndicator(
            backgroundColor: AppColors.primary.withValues(alpha: 0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    WidgetRef ref,
    String? errorMessage,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: AppColors.danger.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.error_outline_rounded,
            size: 100,
            color: AppColors.danger,
          ),
        ),
        const SizedBox(height: 40),
        Text(
          'Something went wrong',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            errorMessage ?? 'Please try again',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: () {
            ref.read(walkTestProvider.notifier).reset();
          },
          child: const Text('Try Again'),
        ),
      ],
    );
  }
}
