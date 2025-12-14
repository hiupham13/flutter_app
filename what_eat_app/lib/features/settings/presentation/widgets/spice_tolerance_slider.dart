import 'package:flutter/material.dart';

class SpiceToleranceDialog extends StatefulWidget {
  final int currentLevel;

  const SpiceToleranceDialog({
    super.key,
    required this.currentLevel,
  });

  @override
  State<SpiceToleranceDialog> createState() => _SpiceToleranceDialogState();
}

class _SpiceToleranceDialogState extends State<SpiceToleranceDialog> {
  late double _selectedLevel;

  @override
  void initState() {
    super.initState();
    _selectedLevel = widget.currentLevel.toDouble();
  }

  String _getLevelLabel(double level) {
    switch (level.round()) {
      case 1:
        return 'Không cay';
      case 2:
        return 'Cay nhẹ';
      case 3:
        return 'Cay vừa';
      case 4:
        return 'Cay nhiều';
      case 5:
        return 'Siêu cay';
      default:
        return 'Không cay';
    }
  }

  Color _getLevelColor(double level) {
    final value = level.round();
    if (value <= 1) {
      return Colors.green;
    } else if (value == 2) {
      return Colors.lightGreen;
    } else if (value == 3) {
      return Colors.orange;
    } else if (value == 4) {
      return Colors.deepOrange;
    } else {
      return Colors.red;
    }
  }

  IconData _getLevelIcon(double level) {
    final value = level.round();
    if (value <= 2) {
      return Icons.local_fire_department_outlined;
    } else if (value <= 4) {
      return Icons.local_fire_department;
    } else {
      return Icons.whatshot;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Chọn độ cay'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Visual indicator
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _getLevelColor(_selectedLevel).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _getLevelColor(_selectedLevel).withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  _getLevelIcon(_selectedLevel),
                  size: 48,
                  color: _getLevelColor(_selectedLevel),
                ),
                const SizedBox(height: 12),
                Text(
                  _getLevelLabel(_selectedLevel),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: _getLevelColor(_selectedLevel),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _getLevelColor(_selectedLevel),
              thumbColor: _getLevelColor(_selectedLevel),
              overlayColor: _getLevelColor(_selectedLevel).withOpacity(0.2),
              inactiveTrackColor: Colors.grey.shade300,
            ),
            child: Slider(
              value: _selectedLevel,
              min: 1,
              max: 5,
              divisions: 4,
              label: _getLevelLabel(_selectedLevel),
              onChanged: (value) {
                setState(() => _selectedLevel = value);
              },
            ),
          ),
          
          // Level indicators
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildLevelDot(1),
                _buildLevelDot(2),
                _buildLevelDot(3),
                _buildLevelDot(4),
                _buildLevelDot(5),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Description
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'App sẽ ưu tiên gợi ý món ăn phù hợp với độ cay bạn chọn',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _selectedLevel.round()),
          child: const Text('Xác nhận'),
        ),
      ],
    );
  }

  Widget _buildLevelDot(int level) {
    final isActive = _selectedLevel.round() == level;
    
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive
            ? _getLevelColor(level.toDouble())
            : Colors.grey.shade300,
        border: Border.all(
          color: isActive
              ? _getLevelColor(level.toDouble())
              : Colors.grey.shade400,
          width: isActive ? 2 : 1,
        ),
      ),
    );
  }
}