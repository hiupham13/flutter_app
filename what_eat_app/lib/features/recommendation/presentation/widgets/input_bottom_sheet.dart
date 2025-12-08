import 'package:flutter/material.dart';

/// Input data cho recommendation
class RecommendationInput {
  final int budget; // 1: Cuối tháng, 2: Bình dân, 3: Sang chảnh
  final String companion; // "alone", "date", "group"
  final String? mood; // "normal", "stress", "sick", "happy"

  RecommendationInput({
    required this.budget,
    required this.companion,
    this.mood,
  });
}

/// Bottom Sheet để thu thập input từ user
class InputBottomSheet extends StatefulWidget {
  final Function(RecommendationInput) onConfirm;

  const InputBottomSheet({
    super.key,
    required this.onConfirm,
  });

  @override
  State<InputBottomSheet> createState() => _InputBottomSheetState();

  static Future<RecommendationInput?> show(BuildContext context) async {
    RecommendationInput? result;
    
    await showModalBottomSheet<RecommendationInput>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => InputBottomSheet(
        onConfirm: (input) {
          result = input;
          Navigator.of(context).pop(input);
        },
      ),
    );

    return result;
  }
}

class _InputBottomSheetState extends State<InputBottomSheet> {
  int? _selectedBudget;
  String? _selectedCompanion;
  String? _selectedMood;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hôm nay ăn gì?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Chọn thông tin để gợi ý món ăn phù hợp',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 32),

                // Budget Selection
                _buildSectionTitle('💰 Túi tiền'),
                const SizedBox(height: 12),
                _buildBudgetSelection(),
                const SizedBox(height: 24),

                // Companion Selection
                _buildSectionTitle('👥 Đi cùng ai?'),
                const SizedBox(height: 12),
                _buildCompanionSelection(),
                const SizedBox(height: 24),

                // Mood Selection (Optional)
                _buildSectionTitle('😐 Tâm trạng (Tùy chọn)'),
                const SizedBox(height: 12),
                _buildMoodSelection(),
                const SizedBox(height: 32),

                // Confirm Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _canConfirm() ? _handleConfirm : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'CHỐT ĐƠN',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildBudgetSelection() {
    return Row(
      children: [
        Expanded(
          child: _buildOptionCard(
            icon: '💰',
            label: 'Cuối tháng',
            subtitle: 'Rẻ',
            isSelected: _selectedBudget == 1,
            onTap: () => setState(() => _selectedBudget = 1),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildOptionCard(
            icon: '💵',
            label: 'Bình dân',
            subtitle: 'Vừa phải',
            isSelected: _selectedBudget == 2,
            onTap: () => setState(() => _selectedBudget = 2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildOptionCard(
            icon: '💎',
            label: 'Sang chảnh',
            subtitle: 'Cao cấp',
            isSelected: _selectedBudget == 3,
            onTap: () => setState(() => _selectedBudget = 3),
          ),
        ),
      ],
    );
  }

  Widget _buildCompanionSelection() {
    return Row(
      children: [
        Expanded(
          child: _buildOptionCard(
            icon: '🚶',
            label: 'Một mình',
            isSelected: _selectedCompanion == 'alone',
            onTap: () => setState(() => _selectedCompanion = 'alone'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildOptionCard(
            icon: '💑',
            label: 'Hẹn hò',
            isSelected: _selectedCompanion == 'date',
            onTap: () => setState(() => _selectedCompanion = 'date'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildOptionCard(
            icon: '👥',
            label: 'Nhóm bạn',
            isSelected: _selectedCompanion == 'group',
            onTap: () => setState(() => _selectedCompanion = 'group'),
          ),
        ),
      ],
    );
  }

  Widget _buildMoodSelection() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildMoodChip('😊', 'Vui', 'happy'),
        _buildMoodChip('😐', 'Bình thường', 'normal'),
        _buildMoodChip('😰', 'Stress', 'stress'),
        _buildMoodChip('🤒', 'Ốm', 'sick'),
      ],
    );
  }

  Widget _buildMoodChip(String emoji, String label, String value) {
    final isSelected = _selectedMood == value;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedMood = selected ? value : null;
        });
      },
      selectedColor: Colors.orange[100],
      checkmarkColor: Colors.orange,
    );
  }

  Widget _buildOptionCard({
    required String icon,
    required String label,
    String? subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange[50] : Colors.grey[100],
          border: Border.all(
            color: isSelected ? Colors.orange : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              icon,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.orange[900] : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _canConfirm() {
    return _selectedBudget != null && _selectedCompanion != null;
  }

  void _handleConfirm() {
    if (!_canConfirm()) return;

    final input = RecommendationInput(
      budget: _selectedBudget!,
      companion: _selectedCompanion!,
      mood: _selectedMood,
    );

    widget.onConfirm(input);
  }
}

