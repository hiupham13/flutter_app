import 'package:flutter/material.dart';

class AllergenPickerDialog extends StatefulWidget {
  final List<String> currentAllergens;
  final List<String> availableAllergens;

  const AllergenPickerDialog({
    super.key,
    required this.currentAllergens,
    required this.availableAllergens,
  });

  @override
  State<AllergenPickerDialog> createState() => _AllergenPickerDialogState();
}

class _AllergenPickerDialogState extends State<AllergenPickerDialog> {
  late Set<String> _selectedAllergens;

  @override
  void initState() {
    super.initState();
    _selectedAllergens = Set<String>.from(widget.currentAllergens);
  }

  IconData _getAllergenIcon(String allergen) {
    switch (allergen.toLowerCase()) {
      case 'hải sản':
      case 'seafood':
        return Icons.set_meal;
      case 'sữa':
      case 'dairy':
        return Icons.water_drop;
      case 'trứng':
      case 'egg':
        return Icons.egg;
      case 'đậu':
      case 'nuts':
        return Icons.nature;
      case 'gluten':
        return Icons.bakery_dining;
      case 'đậu nành':
      case 'soy':
        return Icons.spa;
      default:
        return Icons.block;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Chọn dị ứng thực phẩm'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: Colors.blue.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'App sẽ lọc bỏ món ăn có thành phần gây dị ứng',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Allergen list
            Flexible(
              child: widget.availableAllergens.isEmpty
                  ? Center(
                      child: Text(
                        'Không có dữ liệu dị ứng',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: widget.availableAllergens.length,
                      itemBuilder: (context, index) {
                        final allergen = widget.availableAllergens[index];
                        final isSelected = _selectedAllergens.contains(allergen);
                        
                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedAllergens.add(allergen);
                              } else {
                                _selectedAllergens.remove(allergen);
                              }
                            });
                          },
                          title: Row(
                            children: [
                              Icon(
                                _getAllergenIcon(allergen),
                                size: 20,
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 12),
                              Text(allergen),
                            ],
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                          controlAffinity: ListTileControlAffinity.leading,
                          dense: true,
                        );
                      },
                    ),
            ),
            
            // Selected count
            if (_selectedAllergens.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Đã chọn: ${_selectedAllergens.length} loại',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (_selectedAllergens.isNotEmpty)
          TextButton(
            onPressed: () {
              setState(() => _selectedAllergens.clear());
            },
            child: const Text('Xóa hết'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _selectedAllergens.toList()),
          child: const Text('Xác nhận'),
        ),
      ],
    );
  }
}