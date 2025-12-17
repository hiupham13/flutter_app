import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import '../../../models/food_model.dart';
import '../../../core/utils/logger.dart';
import '../data/repositories/history_repository.dart';
import '../data/repositories/food_repository.dart';

/// Grouped history by date
class GroupedHistoryItem {
  final DateTime date;
  final List<HistoryFoodItem> items;

  GroupedHistoryItem({
    required this.date,
    required this.items,
  });
}

/// History item với food data
class HistoryFoodItem {
  final String historyId;
  final FoodModel food;
  final DateTime timestamp;

  HistoryFoodItem({
    required this.historyId,
    required this.food,
    required this.timestamp,
  });
}

/// History state
class HistoryState {
  final List<GroupedHistoryItem> groupedHistory;
  final bool isLoading;
  final String? error;

  HistoryState({
    this.groupedHistory = const [],
    this.isLoading = false,
    this.error,
  });

  HistoryState copyWith({
    List<GroupedHistoryItem>? groupedHistory,
    bool? isLoading,
    String? error,
  }) {
    return HistoryState(
      groupedHistory: groupedHistory ?? this.groupedHistory,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  int get totalCount {
    return groupedHistory.fold(0, (sum, group) => sum + group.items.length);
  }
}

/// History controller
class HistoryController extends StateNotifier<HistoryState> {
  final HistoryRepository _historyRepo;
  final FoodRepository _foodRepo;

  HistoryController(this._historyRepo, this._foodRepo) : super(HistoryState());

  /// Load history and group by date
  Future<void> loadHistory({int limit = 50}) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      state = state.copyWith(
        isLoading: false,
        error: 'User not logged in',
      );
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Fetch history items
      final historyItems = await _historyRepo.fetchFullHistory(
        userId: userId,
        limit: limit,
      );

      if (historyItems.isEmpty) {
        state = state.copyWith(
          groupedHistory: [],
          isLoading: false,
        );
        return;
      }

      // Fetch food data for each history item
      final historyFoodItems = <HistoryFoodItem>[];
      for (final item in historyItems) {
        final food = await _foodRepo.getFoodById(item.foodId);
        if (food != null) {
          historyFoodItems.add(
            HistoryFoodItem(
              historyId: item.id,
              food: food,
              timestamp: item.timestamp,
            ),
          );
        }
      }

      // Group by date
      final grouped = _groupByDate(historyFoodItems);

      state = state.copyWith(
        groupedHistory: grouped,
        isLoading: false,
      );

      AppLogger.info('History loaded: ${historyFoodItems.length} items');
    } catch (e, st) {
      // Standardized error handling: Log + Crashlytics
      AppLogger.error('Load history failed: $e', e, st);
      FirebaseCrashlytics.instance.recordError(
        e,
        st,
        reason: 'Load history failed',
        fatal: false,
      );
      state = state.copyWith(
        isLoading: false,
        error: 'Không thể tải lịch sử: $e',
      );
    }
  }

  /// Delete a single history item
  Future<void> deleteHistoryItem(String historyId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      await _historyRepo.deleteHistoryItem(
        userId: userId,
        historyId: historyId,
      );

      // Remove from state
      final updatedGroups = <GroupedHistoryItem>[];
      for (final group in state.groupedHistory) {
        final filteredItems = group.items
            .where((item) => item.historyId != historyId)
            .toList();
        
        if (filteredItems.isNotEmpty) {
          updatedGroups.add(
            GroupedHistoryItem(
              date: group.date,
              items: filteredItems,
            ),
          );
        }
      }

      state = state.copyWith(groupedHistory: updatedGroups);
      AppLogger.info('History item deleted: $historyId');
    } catch (e, st) {
      // Standardized error handling: Log + Crashlytics
      AppLogger.error('Delete history item failed: $e', e, st);
      FirebaseCrashlytics.instance.recordError(
        e,
        st,
        reason: 'Delete history item failed',
        fatal: false,
      );
      state = state.copyWith(error: 'Không thể xóa: $e');
    }
  }

  /// Clear all history
  Future<void> clearAllHistory() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      await _historyRepo.clearAllHistory(userId: userId);
      state = state.copyWith(groupedHistory: []);
      AppLogger.info('All history cleared');
    } catch (e, st) {
      // Standardized error handling: Log + Crashlytics
      AppLogger.error('Clear all history failed: $e', e, st);
      FirebaseCrashlytics.instance.recordError(
        e,
        st,
        reason: 'Clear all history failed',
        fatal: false,
      );
      state = state.copyWith(error: 'Không thể xóa tất cả: $e');
    }
  }

  /// Group history items by date
  List<GroupedHistoryItem> _groupByDate(List<HistoryFoodItem> items) {
    final Map<String, List<HistoryFoodItem>> grouped = {};

    for (final item in items) {
      final dateKey = _getDateKey(item.timestamp);
      grouped.putIfAbsent(dateKey, () => []).add(item);
    }

    // Convert to list and sort by date descending
    final result = grouped.entries.map((entry) {
      return GroupedHistoryItem(
        date: _parseDateKey(entry.key),
        items: entry.value,
      );
    }).toList();

    result.sort((a, b) => b.date.compareTo(a.date));

    return result;
  }

  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  DateTime _parseDateKey(String key) {
    final parts = key.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }
}

/// History provider
final historyControllerProvider =
    StateNotifierProvider<HistoryController, HistoryState>((ref) {
  final historyRepo = ref.watch(historyRepositoryProvider);
  final foodRepo = ref.watch(foodRepositoryProvider);
  return HistoryController(historyRepo, foodRepo);
});

/// Provider imports
final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepository();
});

final foodRepositoryProvider = Provider<FoodRepository>((ref) {
  return FoodRepository();
});