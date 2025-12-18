import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../models/food_model.dart';
import '../interfaces/repository_interfaces.dart';
import '../data/repositories/food_repository.dart';
import '../data/repositories/history_repository.dart';
import '../../../../core/utils/logger.dart';
import 'scoring_engine.dart';

/// Learns user preferences from history and actions
class UserPreferenceLearner {
  final IFoodRepository _foodRepository;
  final IHistoryRepository _historyRepository;
  final FirebaseFirestore _firestore;
  
  UserPreferenceLearner({
    IFoodRepository? foodRepository,
    IHistoryRepository? historyRepository,
    FirebaseFirestore? firestore,
  })  : _foodRepository = foodRepository ?? FoodRepository() as IFoodRepository,
        _historyRepository = historyRepository ?? HistoryRepository() as IHistoryRepository,
        _firestore = firestore ?? FirebaseFirestore.instance;
  
  /// Learn preferences from user history
  /// Returns learned preferences: favorite cuisines, preferred meal types, etc.
  Future<LearnedPreferences> learnFromHistory(String userId, {int days = 30}) async {
    try {
      AppLogger.info('📚 Learning preferences from history for user $userId');
      
      // Get recent history
      final historyIds = await _historyRepository.fetchHistoryFoodIdsWithDays(
        userId: userId,
        days: days,
      );
      
      if (historyIds.isEmpty) {
        AppLogger.debug('No history found, returning empty preferences');
        return LearnedPreferences.empty();
      }
      
      // Get food details
      final foods = <FoodModel>[];
      for (final foodId in historyIds) {
        final food = await _foodRepository.getFoodById(foodId);
        if (food != null) foods.add(food);
      }
      
      if (foods.isEmpty) {
        return LearnedPreferences.empty();
      }
      
      // Analyze preferences
      final cuisineCounts = <String, int>{};
      final mealTypeCounts = <String, int>{};
      final priceSegmentCounts = <int, int>{};
      
      for (final food in foods) {
        cuisineCounts[food.cuisineId] = (cuisineCounts[food.cuisineId] ?? 0) + 1;
        mealTypeCounts[food.mealTypeId] = (mealTypeCounts[food.mealTypeId] ?? 0) + 1;
        priceSegmentCounts[food.priceSegment] = (priceSegmentCounts[food.priceSegment] ?? 0) + 1;
      }
      
      // Get top preferences (appear in >20% of history)
      final threshold = (foods.length * 0.2).ceil();
      final favoriteCuisines = cuisineCounts.entries
          .where((e) => e.value >= threshold)
          .map((e) => e.key)
          .toList();
      
      final preferredMealTypes = mealTypeCounts.entries
          .where((e) => e.value >= threshold)
          .map((e) => e.key)
          .toList();
      
      // Most common price segment
      final preferredPriceSegment = priceSegmentCounts.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
      
      AppLogger.info('📊 Learned preferences:');
      AppLogger.info('   Favorite cuisines: $favoriteCuisines');
      AppLogger.info('   Preferred meal types: $preferredMealTypes');
      AppLogger.info('   Preferred price segment: $preferredPriceSegment');
      
      return LearnedPreferences(
        favoriteCuisines: favoriteCuisines,
        preferredMealTypes: preferredMealTypes,
        preferredPriceSegment: preferredPriceSegment,
        confidence: _calculateConfidence(foods.length),
      );
    } catch (e, st) {
      AppLogger.error('Error learning preferences: $e', e, st);
      return LearnedPreferences.empty();
    }
  }
  
  /// Learn from user actions (pick, skip, favorite, reject)
  Future<LearnedPreferences> learnFromActions(String userId, {int days = 30}) async {
    try {
      AppLogger.info('📚 Learning preferences from actions for user $userId');
      
      // Get user actions from Firestore
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('user_actions')
          .where('timestamp', isGreaterThan: Timestamp.fromDate(cutoffDate))
          .get();
      
      if (snapshot.docs.isEmpty) {
        return LearnedPreferences.empty();
      }
      
      final positiveFoodIds = <String>[]; // Picked, favorited
      final negativeFoodIds = <String>[]; // Skipped, rejected
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final foodId = data['food_id'] as String? ?? '';
        final action = data['action'] as String? ?? '';
        
        if (foodId.isEmpty) continue;
        
        if (action == 'pick' || action == 'favorite') {
          positiveFoodIds.add(foodId);
        } else if (action == 'skip' || action == 'reject') {
          negativeFoodIds.add(foodId);
        }
      }
      
      // Learn from positive actions
      final positiveFoods = <FoodModel>[];
      for (final foodId in positiveFoodIds) {
        final food = await _foodRepository.getFoodById(foodId);
        if (food != null) positiveFoods.add(food);
      }
      
      // Learn from negative actions (what to avoid)
      final negativeFoods = <FoodModel>[];
      for (final foodId in negativeFoodIds) {
        final food = await _foodRepository.getFoodById(foodId);
        if (food != null) negativeFoods.add(food);
      }
      
      // Analyze positive preferences
      final cuisineCounts = <String, int>{};
      final mealTypeCounts = <String, int>{};
      
      for (final food in positiveFoods) {
        cuisineCounts[food.cuisineId] = (cuisineCounts[food.cuisineId] ?? 0) + 1;
        mealTypeCounts[food.mealTypeId] = (mealTypeCounts[food.mealTypeId] ?? 0) + 1;
      }
      
      // Get top preferences (appear in >30% of positive actions)
      final threshold = positiveFoods.isEmpty ? 0 : (positiveFoods.length * 0.3).ceil();
      final favoriteCuisines = cuisineCounts.entries
          .where((e) => e.value >= threshold)
          .map((e) => e.key)
          .toList();
      
      final preferredMealTypes = mealTypeCounts.entries
          .where((e) => e.value >= threshold)
          .map((e) => e.key)
          .toList();
      
      // Get avoided cuisines/meal types from negative actions
      final avoidedCuisines = negativeFoods.map((f) => f.cuisineId).toSet().toList();
      final avoidedMealTypes = negativeFoods.map((f) => f.mealTypeId).toSet().toList();
      
      AppLogger.info('📊 Learned from actions:');
      AppLogger.info('   Favorite cuisines: $favoriteCuisines');
      AppLogger.info('   Preferred meal types: $preferredMealTypes');
      AppLogger.info('   Avoided cuisines: $avoidedCuisines');
      AppLogger.info('   Avoided meal types: $avoidedMealTypes');
      
      return LearnedPreferences(
        favoriteCuisines: favoriteCuisines,
        preferredMealTypes: preferredMealTypes,
        avoidedCuisines: avoidedCuisines,
        avoidedMealTypes: avoidedMealTypes,
        confidence: _calculateConfidence(positiveFoods.length + negativeFoods.length),
      );
    } catch (e, st) {
      AppLogger.error('Error learning from actions: $e', e, st);
      return LearnedPreferences.empty();
    }
  }
  
  /// Combine learned preferences from history and actions
  Future<LearnedPreferences> learnPreferences(String userId) async {
    final historyPrefs = await learnFromHistory(userId);
    final actionPrefs = await learnFromActions(userId);
    
    // Merge preferences (actions have higher weight)
    return LearnedPreferences(
      favoriteCuisines: [
        ...actionPrefs.favoriteCuisines,
        ...historyPrefs.favoriteCuisines,
      ].toSet().toList(),
      preferredMealTypes: [
        ...actionPrefs.preferredMealTypes,
        ...historyPrefs.preferredMealTypes,
      ].toSet().toList(),
      preferredPriceSegment: actionPrefs.preferredPriceSegment ?? historyPrefs.preferredPriceSegment,
      avoidedCuisines: actionPrefs.avoidedCuisines,
      avoidedMealTypes: actionPrefs.avoidedMealTypes,
      confidence: (historyPrefs.confidence + actionPrefs.confidence) / 2.0,
    );
  }
  
  /// Apply learned preferences to context
  RecommendationContext applyLearnedPreferences(
    RecommendationContext baseContext,
    LearnedPreferences learned,
  ) {
    // Merge favorite cuisines
    final favoriteCuisines = [
      ...baseContext.favoriteCuisines,
      ...learned.favoriteCuisines,
    ].toSet().toList();
    
    // Add avoided cuisines to excluded (if not already)
    // Note: We don't have excludedCuisines field, so we'll skip this for now
    
    // Adjust budget if learned preference is strong
    int budget = baseContext.budget;
    if (learned.preferredPriceSegment != null && learned.confidence > 0.5) {
      budget = learned.preferredPriceSegment!;
    }
    
    return baseContext.copyWith(
      favoriteCuisines: favoriteCuisines,
      budget: budget,
    );
  }
  
  /// Calculate confidence score (0.0 - 1.0)
  double _calculateConfidence(int sampleSize) {
    // More samples = higher confidence
    // 0 samples = 0.0
    // 10+ samples = 1.0
    return (sampleSize / 10.0).clamp(0.0, 1.0);
  }
}

/// Learned user preferences
class LearnedPreferences {
  final List<String> favoriteCuisines;
  final List<String> preferredMealTypes;
  final int? preferredPriceSegment;
  final List<String> avoidedCuisines;
  final List<String> avoidedMealTypes;
  final double confidence; // 0.0 - 1.0
  
  LearnedPreferences({
    this.favoriteCuisines = const [],
    this.preferredMealTypes = const [],
    this.preferredPriceSegment,
    this.avoidedCuisines = const [],
    this.avoidedMealTypes = const [],
    this.confidence = 0.0,
  });
  
  factory LearnedPreferences.empty() {
    return LearnedPreferences();
  }
  
  bool get isEmpty => favoriteCuisines.isEmpty && preferredMealTypes.isEmpty;
}

