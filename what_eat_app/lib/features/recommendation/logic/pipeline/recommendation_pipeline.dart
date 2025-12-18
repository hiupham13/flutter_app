import 'dart:async';
import '../../../../core/utils/logger.dart';
import 'recommendation_step.dart';

/// Recommendation Pipeline - Orchestrates all steps
/// Follows Single Responsibility Principle (SRP) - only orchestrates, doesn't do business logic
class RecommendationPipeline {
  final List<RecommendationStep> _steps;
  
  RecommendationPipeline(this._steps);
  
  /// Execute all steps in sequence
  /// Returns null if pipeline should stop (error or empty result)
  Future<PipelineContext?> execute(PipelineContext initialContext) async {
    AppLogger.info('🚀 [Pipeline] Starting recommendation pipeline with ${_steps.length} steps');
    
    PipelineContext? context = initialContext;
    
    for (final step in _steps) {
      if (context == null) {
        AppLogger.warning('🚫 [Pipeline] Pipeline stopped by step');
        return null;
      }
      
      try {
        AppLogger.debug('▶️ [Pipeline] Executing step: ${step.stepName}');
        context = await step.process(context);
        
        if (context == null) {
          AppLogger.warning('🚫 [Pipeline] Step ${step.stepName} returned null, stopping pipeline');
          return null;
        }
        
        AppLogger.debug('✅ [Pipeline] Step ${step.stepName} completed');
      } catch (e, st) {
        AppLogger.error('❌ [Pipeline] Step ${step.stepName} failed: $e', e, st);
        // Continue with previous context on error (graceful degradation)
      }
    }
    
    AppLogger.info('✅ [Pipeline] Pipeline completed successfully');
    return context;
  }
  
  /// Add a step to the pipeline (for dynamic pipeline building)
  void addStep(RecommendationStep step) {
    _steps.add(step);
  }
  
  /// Remove a step from the pipeline
  void removeStep(RecommendationStep step) {
    _steps.remove(step);
  }
}

