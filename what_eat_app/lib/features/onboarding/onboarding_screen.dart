import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'logic/onboarding_provider.dart';
import '../../core/services/analytics_service.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _cuisineOptions = const ['vn', 'kr', 'jp', 'us', 'cn', 'th'];
  final _allergyOptions = const ['seafood', 'peanut', 'dairy', 'egg', 'soy'];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    final ctrl = ref.read(onboardingControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thiết lập ban đầu'),
        leading: state.step > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: state.isSaving ? null : ctrl.prevStep,
              )
            : null,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildProgress(state.step),
              const SizedBox(height: 16),
              Expanded(child: _buildStep(state.step, ctrl)),
              const SizedBox(height: 12),
              _buildActions(state),
              if (state.error != null) ...[
                const SizedBox(height: 8),
                Text(
                  state.error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgress(int step) {
    const total = 4;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(value: (step + 1) / total),
        const SizedBox(height: 8),
        Text('Bước ${step + 1} / $total'),
      ],
    );
  }

  Widget _buildStep(int step, OnboardingController ctrl) {
    switch (step) {
      case 0:
        return _buildAllergyStep(ctrl);
      case 1:
        return _buildSpiceStep(ctrl);
      case 2:
        return _buildBudgetStep(ctrl);
      default:
        return _buildCuisineStep(ctrl);
    }
  }

  Widget _buildAllergyStep(OnboardingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bạn dị ứng gì?',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: _allergyOptions
              .map(
                (a) => FilterChip(
                  label: Text(a),
                  selected: ctrl.allergies.contains(a),
                  onSelected: (selected) {
                    setState(() {
                      selected
                          ? ctrl.allergies.add(a)
                          : ctrl.allergies.remove(a);
                    });
                  },
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildSpiceStep(OnboardingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Khả năng ăn cay?',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Slider(
          value: ctrl.spiceTolerance.toDouble(),
          min: 0,
          max: 5,
          divisions: 5,
          label: '${ctrl.spiceTolerance}',
          onChanged: (v) => setState(() => ctrl.spiceTolerance = v.toInt()),
        ),
      ],
    );
  }

  Widget _buildBudgetStep(OnboardingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mức chi tiêu mặc định?',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Column(
          children: List.generate(3, (index) {
            final value = index + 1;
            final labels = ['Cuối tháng', 'Bình dân', 'Sang chảnh'];
            return RadioListTile<int>(
              value: value,
              groupValue: ctrl.budget,
              onChanged: (v) => setState(() => ctrl.budget = v ?? 2),
              title: Text(labels[index]),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildCuisineStep(OnboardingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sở thích ẩm thực',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: _cuisineOptions
              .map(
                (c) => FilterChip(
                  label: Text(c.toUpperCase()),
                  selected: ctrl.cuisines.contains(c),
                  onSelected: (selected) {
                    setState(() {
                      selected ? ctrl.cuisines.add(c) : ctrl.cuisines.remove(c);
                    });
                  },
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildActions(OnboardingState state) {
    final ctrl = ref.read(onboardingControllerProvider.notifier);

    final isLastStep = state.step >= 3;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: state.isSaving
              ? null
              : () async {
                  if (isLastStep) {
                    final ok = await ctrl.save();
                    if (!mounted || !ok) return;

                    // Log onboarding completed with preferences
                    final analytics =
                        ref.read(analyticsServiceProvider);
                    await analytics.logOnboardingCompleted(
                      skipped: false,
                      defaultBudget: ctrl.budget,
                      spiceTolerance: ctrl.spiceTolerance,
                      favoriteCuisinesCount: ctrl.cuisines.length,
                      excludedAllergensCount: ctrl.allergies.length,
                    );

                    context.goNamed('dashboard');
                  } else {
                    ctrl.nextStep();
                  }
                },
          child: state.isSaving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isLastStep ? 'Hoàn tất' : 'Tiếp tục'),
        ),
        TextButton(
          onPressed: state.isSaving
              ? null
              : () async {
                  await ctrl.markCompletedOnly();
                  if (!mounted) return;

                  // Log onboarding skipped
                  final analytics =
                      ref.read(analyticsServiceProvider);
                  await analytics.logOnboardingCompleted(skipped: true);

                  context.goNamed('dashboard');
                },
          child: const Text('Bỏ qua (sẽ thiết lập sau)'),
        )
      ],
    );
  }
}
