import 'package:flutter/material.dart';

class BudgetSelectorDialog extends StatefulWidget {
  final int currentBudget;

  const BudgetSelectorDialog({
    super.key,
    required this.currentBudget,
  });

  @override
  State<BudgetSelectorDialog> createState() => _BudgetSelectorDialogState();
}

class _BudgetSelectorDialogState extends State<BudgetSelectorDialog> {
  late int _selectedBudget;

  @override
  void initState() {
    super.initState();
    _selectedBudget = widget.currentBudget;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Chọn ngân sách mặc định'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildBudgetOption(
            value: 1,
            icon: Icons.money_off,
            label: 'Rẻ',
            subtitle: 'Dưới 35,000đ',
          ),
          const SizedBox(height: 8),
          _buildBudgetOption(
            value: 2,
            icon: Icons.attach_money,
            label: 'Vừa',
            subtitle: '35,000đ - 80,000đ',
          ),
          const SizedBox(height: 8),
          _buildBudgetOption(
            value: 3,
            icon: Icons.diamond,
            label: 'Sang',
            subtitle: 'Trên 80,000đ',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _selectedBudget),
          child: const Text('Xác nhận'),
        ),
      ],
    );
  }

  Widget _buildBudgetOption({
    required int value,
    required IconData icon,
    required String label,
    required String subtitle,
  }) {
    final isSelected = _selectedBudget == value;
    
    return InkWell(
      onTap: () => setState(() => _selectedBudget = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }
}