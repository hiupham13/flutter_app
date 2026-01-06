import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../models/reward_model.dart';
import '../logic/rewards_provider.dart';

/// Màn hình hiển thị lịch sử giao dịch coin
/// 
/// Features:
/// - List all transactions
/// - Group by date (Hôm nay, Hôm qua, DD/MM/YYYY)
/// - Filter by type (earned, spent, bonus, refund)
/// - Pull-to-refresh
/// - Empty state
/// - Error handling
class TransactionHistoryScreen extends ConsumerStatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  ConsumerState<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState
    extends ConsumerState<TransactionHistoryScreen> {
  // Filter state
  Set<TransactionType> _selectedTypes = TransactionType.values.toSet();

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch Sử Giao Dịch'),
        actions: [
          // Filter button
          IconButton(
            icon: Icon(
              _selectedTypes.length == TransactionType.values.length
                  ? Icons.filter_list
                  : Icons.filter_list_alt,
              color: _selectedTypes.length == TransactionType.values.length
                  ? null
                  : Theme.of(context).colorScheme.primary,
            ),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: transactionsAsync.when(
        data: (transactions) {
          // Apply filter
          final filtered = transactions.where((txn) {
            return _selectedTypes.contains(txn.type);
          }).toList();

          if (filtered.isEmpty) {
            return _buildEmptyState();
          }

          return _buildTransactionList(filtered);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => _buildErrorState(error.toString()),
      ),
    );
  }

  Widget _buildTransactionList(List<CoinTransaction> transactions) {
    // Group transactions by date
    final grouped = _groupTransactionsByDate(transactions);

    return RefreshIndicator(
      onRefresh: () async {
        // Refresh transaction list
        ref.invalidate(transactionHistoryProvider);
        // Wait for new data
        await ref.read(transactionHistoryProvider.future);
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: grouped.length,
        itemBuilder: (context, index) {
          final entry = grouped.entries.elementAt(index);
          final dateLabel = entry.key;
          final dayTransactions = entry.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  dateLabel,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ),

              // Transactions for this date
              ...dayTransactions.map((txn) => TransactionTile(
                    transaction: txn,
                  )),

              // Divider after each day (except last)
              if (index < grouped.length - 1)
                const Divider(height: 1, thickness: 1),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasFilter = _selectedTypes.length < TransactionType.values.length;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasFilter ? Icons.filter_list_off : Icons.receipt_long_outlined,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              hasFilter
                  ? 'Không Có Giao Dịch'
                  : 'Chưa Có Giao Dịch Nào',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              hasFilter
                  ? 'Thử thay đổi bộ lọc để xem các giao dịch khác'
                  : 'Mở hộp quà để bắt đầu kiếm coins!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
              textAlign: TextAlign.center,
            ),
            if (hasFilter) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedTypes = TransactionType.values.toSet();
                  });
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('Xóa Bộ Lọc'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Có Lỗi Xảy Ra',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(transactionHistoryProvider);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Thử Lại'),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Lọc Giao Dịch'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: TransactionType.values.map((type) {
                return CheckboxListTile(
                  title: Text(_getTypeDisplayName(type)),
                  subtitle: Text(_getTypeDescription(type)),
                  value: _selectedTypes.contains(type),
                  onChanged: (checked) {
                    setDialogState(() {
                      if (checked == true) {
                        _selectedTypes.add(type);
                      } else {
                        _selectedTypes.remove(type);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setDialogState(() {
                    _selectedTypes = TransactionType.values.toSet();
                  });
                },
                child: const Text('Tất Cả'),
              ),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {}); // Update main screen
                  context.pop();
                },
                child: const Text('Áp Dụng'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ============================================================================
  // Helper Methods
  // ============================================================================

  Map<String, List<CoinTransaction>> _groupTransactionsByDate(
    List<CoinTransaction> transactions,
  ) {
    final grouped = <String, List<CoinTransaction>>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final txn in transactions) {
      final txnDate = DateTime(
        txn.timestamp.year,
        txn.timestamp.month,
        txn.timestamp.day,
      );

      String dateLabel;
      if (txnDate == today) {
        dateLabel = 'Hôm Nay';
      } else if (txnDate == yesterday) {
        dateLabel = 'Hôm Qua';
      } else {
        dateLabel = DateFormat('dd/MM/yyyy').format(txnDate);
      }

      grouped.putIfAbsent(dateLabel, () => []).add(txn);
    }

    return grouped;
  }

  String _getTypeDisplayName(TransactionType type) {
    switch (type) {
      case TransactionType.earned:
        return 'Kiếm Được';
      case TransactionType.spent:
        return 'Đã Tiêu';
      case TransactionType.bonus:
        return 'Thưởng';
      case TransactionType.refund:
        return 'Hoàn Tiền';
    }
  }

  String _getTypeDescription(TransactionType type) {
    switch (type) {
      case TransactionType.earned:
        return 'Từ mở hộp quà';
      case TransactionType.spent:
        return 'Đổi quà, mua vật phẩm';
      case TransactionType.bonus:
        return 'Thưởng streak, sự kiện';
      case TransactionType.refund:
        return 'Hoàn lại từ đơn hủy';
    }
  }
}

/// Widget hiển thị một transaction trong list
class TransactionTile extends StatelessWidget {
  final CoinTransaction transaction;

  const TransactionTile({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _buildIcon(context),
      title: Text(
        _getDisplayText(),
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(_formatTime(transaction.timestamp)),
      trailing: Text(
        '${transaction.isCredit ? '+' : '-'}${transaction.amount}',
        style: TextStyle(
          color: transaction.isCredit ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      onTap: () => _showDetails(context),
    );
  }

  Widget _buildIcon(BuildContext context) {
    IconData iconData;
    Color color;

    switch (transaction.type) {
      case TransactionType.earned:
        iconData = Icons.card_giftcard;
        color = Colors.green;
        break;
      case TransactionType.spent:
        iconData = Icons.shopping_bag;
        color = Colors.red;
        break;
      case TransactionType.bonus:
        iconData = Icons.star;
        color = Colors.amber;
        break;
      case TransactionType.refund:
        iconData = Icons.undo;
        color = Colors.blue;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(iconData, color: color),
    );
  }

  String _getDisplayText() {
    if (transaction.description != null &&
        transaction.description!.isNotEmpty) {
      return transaction.description!;
    }

    switch (transaction.type) {
      case TransactionType.earned:
        return 'Mở Hộp Quà';
      case TransactionType.spent:
        return 'Đổi Quà';
      case TransactionType.bonus:
        return 'Thưởng';
      case TransactionType.refund:
        return 'Hoàn Tiền';
    }
  }

  String _formatTime(DateTime timestamp) {
    return DateFormat('HH:mm').format(timestamp);
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildIcon(context),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getDisplayText(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(transaction.timestamp),
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDetailRow('Loại', _getTypeDisplayName(transaction.type)),
            _buildDetailRow(
              'Số Coins',
              '${transaction.isCredit ? '+' : '-'}${transaction.amount}',
              valueColor: transaction.isCredit ? Colors.green : Colors.red,
            ),
            if (transaction.relatedBoxId != null)
              _buildDetailRow('ID Hộp Quà', transaction.relatedBoxId!),
            if (transaction.description != null)
              _buildDetailRow('Mô Tả', transaction.description!),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  String _getTypeDisplayName(TransactionType type) {
    switch (type) {
      case TransactionType.earned:
        return 'Kiếm Được';
      case TransactionType.spent:
        return 'Đã Tiêu';
      case TransactionType.bonus:
        return 'Thưởng';
      case TransactionType.refund:
        return 'Hoàn Tiền';
    }
  }
}
