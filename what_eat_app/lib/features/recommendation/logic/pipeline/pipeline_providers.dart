import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../recommendation_provider.dart'; // Import providers
import '../anti_repetition_filter.dart';
import '../cold_start_handler.dart';
import 'recommendation_pipeline.dart';
import 'recommendation_orchestrator.dart';
import 'data_fetch_step.dart';
import 'validation_step.dart';
import 'preference_learning_step.dart';
import 'cold_start_step.dart';
import 'scoring_step.dart';
import 'anti_repetition_step.dart';
import 'diversity_step.dart';

/// Provider for Recommendation Pipeline
final recommendationPipelineProvider = Provider<RecommendationPipeline>((ref) {
  final repository = ref.watch(foodRepositoryProvider);
  final historyRepo = ref.watch(historyRepositoryProvider);
  final dataValidator = ref.watch(dataValidatorProvider);
  final diversityEnforcer = ref.watch(diversityEnforcerProvider);
  final preferenceLearner = ref.watch(userPreferenceLearnerProvider);
  final scoringEngine = ref.watch(scoringEngineProvider);
  final coldStartHandler = ColdStartHandler(repository, scoringEngine);
  final antiRepetitionFilter = AntiRepetitionFilter(historyRepo);
  
  // Build pipeline with all steps
  final steps = [
    DataFetchStep(repository),
    ValidationStep(dataValidator),
    PreferenceLearningStep(preferenceLearner),
    ColdStartStep(historyRepo, coldStartHandler),
    ScoringStep(),
    AntiRepetitionStep(antiRepetitionFilter),
    DiversityStep(diversityEnforcer),
  ];
  
  return RecommendationPipeline(steps);
});

/// Provider for Recommendation Orchestrator
final recommendationOrchestratorProvider = Provider<RecommendationOrchestrator>((ref) {
  final pipeline = ref.watch(recommendationPipelineProvider);
  final repository = ref.watch(foodRepositoryProvider);
  final historyRepo = ref.watch(historyRepositoryProvider);
  final feedbackLearner = ref.watch(userFeedbackLearnerProvider);
  
  return RecommendationOrchestrator(
    pipeline: pipeline,
    repository: repository,
    historyRepository: historyRepo,
    feedbackLearner: feedbackLearner,
  );
});

