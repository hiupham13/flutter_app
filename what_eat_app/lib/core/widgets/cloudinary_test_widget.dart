import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:what_eat_app/core/services/cloudinary_service.dart';
import 'package:what_eat_app/core/widgets/cached_food_image.dart';
import 'package:what_eat_app/core/constants/app_colors.dart';

/// Widget để test kết nối Cloudinary và hiển thị hình ảnh
/// 
/// Sử dụng trong development để kiểm tra:
/// - Cloud name đã đúng chưa
/// - URL được tạo ra có đúng format không
/// - Hình ảnh có load được không
class CloudinaryTestWidget extends ConsumerStatefulWidget {
  final String? testFoodId;
  final String? testFoodName;
  final List<String>? testImages;

  const CloudinaryTestWidget({
    super.key,
    this.testFoodId,
    this.testFoodName,
    this.testImages,
  });

  @override
  ConsumerState<CloudinaryTestWidget> createState() => _CloudinaryTestWidgetState();
}

class _CloudinaryTestWidgetState extends ConsumerState<CloudinaryTestWidget> {
  String? _generatedUrl;
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _testConnection();
  }

  void _testConnection() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final cloudinaryService = ref.read(cloudinaryServiceProvider);
    
    // Test connection
    cloudinaryService.testConnection(
      testFoodId: widget.testFoodId,
      testFoodName: widget.testFoodName,
    );

    // Generate URL
    final url = cloudinaryService.getFoodImageUrl(
      widget.testFoodId,
      widget.testFoodName,
      widget.testImages,
      enableLogging: true,
    );

    setState(() {
      _generatedUrl = url;
      _isLoading = false;
      if (url == null) {
        _errorMessage = 'Không tìm thấy URL hình ảnh';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cloudinaryService = ref.read(cloudinaryServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloudinary Test'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _testConnection,
            tooltip: 'Test lại',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cloudinary Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thông tin Cloudinary',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow('Cloud Name', cloudinaryService.cloudName),
                    _buildInfoRow('Base URL', cloudinaryService.baseUrl),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Test Input
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Input',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    if (widget.testFoodId != null)
                      _buildInfoRow('Food ID', widget.testFoodId!),
                    if (widget.testFoodName != null)
                      _buildInfoRow('Food Name', widget.testFoodName!),
                    if (widget.testImages != null)
                      _buildInfoRow(
                        'Images List',
                        '${widget.testImages!.length} items',
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Generated URL
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Generated URL',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.error),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: AppColors.error),
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (_generatedUrl != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SelectableText(
                            _generatedUrl!,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              // Copy to clipboard
                              // Clipboard.setData(ClipboardData(text: _generatedUrl!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('URL đã được copy (cần import clipboard)'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy),
                            label: const Text('Copy URL'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Image Preview
            if (_generatedUrl != null && !_isLoading)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Image Preview',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 300,
                        width: double.infinity,
                        child: CachedFoodImage(
                          imageUrl: _generatedUrl!,
                          fit: BoxFit.cover,
                          borderRadius: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Instructions
            Card(
              color: AppColors.surfaceMuted,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Hướng dẫn',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.primary,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInstructionItem(
                      '1. Kiểm tra Cloud Name đã đúng chưa (phải là: dinrpqxne)',
                    ),
                    _buildInstructionItem(
                      '2. Kiểm tra URL format có đúng không',
                    ),
                    _buildInstructionItem(
                      '3. Kiểm tra hình ảnh có hiển thị không',
                    ),
                    _buildInstructionItem(
                      '4. Nếu không hiển thị, kiểm tra:',
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInstructionItem(
                            '- File đã upload lên Cloudinary chưa?',
                            isSubItem: true,
                          ),
                          _buildInstructionItem(
                            '- Tên file có khớp với food ID không?',
                            isSubItem: true,
                          ),
                          _buildInstructionItem(
                            '- File có trong folder "foods/" không? (phải là số nhiều)',
                            isSubItem: true,
                          ),
                        ],
                      ),
                    ),
                    _buildInstructionItem(
                      '5. Xem console log để debug chi tiết',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(String text, {bool isSubItem = false}) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: 4,
        left: isSubItem ? 8 : 0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isSubItem)
            const Text('• ', style: TextStyle(fontWeight: FontWeight.bold))
          else
            const Text('  - '),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: isSubItem ? 13 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

