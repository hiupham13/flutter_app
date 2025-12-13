import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/error_widget.dart' as custom;
import '../../../models/user_model.dart';
import '../logic/user_profile_provider.dart';
import '../../../core/utils/date_formatter.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileStreamProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ Sơ'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to settings
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: userProfile.when(
        data: (user) => user == null 
            ? const Center(child: Text('Chưa đăng nhập'))
            : _buildProfile(context, user),
        loading: () => const LoadingIndicator(),
        error: (e, st) => custom.AppErrorWidget(
          title: 'Lỗi tải dữ liệu',
          message: e.toString(),
        ),
      ),
    );
  }
  
  Widget _buildProfile(BuildContext context, UserModel user) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header with avatar
          _buildHeader(context, user),
          
          const SizedBox(height: 24),
          
          // Stats cards
          _buildStatsSection(context, user),
          
          const SizedBox(height: 24),
          
          // Activity section
          _buildActivitySection(context, user),
          
          const SizedBox(height: 24),
          
          // Preferences section
          _buildPreferencesSection(context, user),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }
  
  Widget _buildHeader(BuildContext context, UserModel user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.secondaryContainer,
          ],
        ),
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.surface,
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 3,
              ),
            ),
            child: Center(
              child: Text(
                user.info.displayName.isNotEmpty 
                    ? user.info.displayName[0].toUpperCase()
                    : '?',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Name
          Text(
            user.info.displayName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 4),
          
          // Email
          Text(
            user.info.email,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Member since
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  'Tham gia ${DateFormatter.formatRelative(user.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatsSection(BuildContext context, UserModel user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thống Kê',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context: context,
                  icon: Icons.restaurant_menu,
                  label: 'Lượt chọn',
                  value: user.stats.totalPicked.toString(),
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context: context,
                  icon: Icons.local_fire_department,
                  label: 'Chuỗi ngày',
                  value: user.stats.streakDays.toString(),
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context: context,
                  icon: Icons.calendar_month,
                  label: 'Ngày tham gia',
                  value: _calculateActiveDays(user.createdAt).toString(),
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context: context,
                  icon: Icons.access_time,
                  label: 'Đăng nhập cuối',
                  value: _calculateActiveDays(user.createdAt).toString(),
                  color: Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActivitySection(BuildContext context, UserModel user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hoạt Động Gần Đây',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildActivityItem(
                  context: context,
                  icon: Icons.restaurant_menu,
                  label: 'Tổng lượt chọn món',
                  value: '${user.stats.totalPicked} lần',
                ),
                const Divider(height: 24),
                _buildActivityItem(
                  context: context,
                  icon: Icons.local_fire_department,
                  label: 'Chuỗi ngày sử dụng',
                  value: '${user.stats.streakDays} ngày',
                ),
                const Divider(height: 24),
                _buildActivityItem(
                  context: context,
                  icon: Icons.calendar_today,
                  label: 'Đã tham gia',
                  value: '${_calculateActiveDays(user.createdAt)} ngày',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActivityItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildPreferencesSection(BuildContext context, UserModel user) {
    final settings = user.settings;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sở Thích',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/settings');
                },
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Chỉnh sửa'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildPreferenceItem(
                  context: context,
                  icon: Icons.attach_money,
                  label: 'Ngân sách',
                  value: _getBudgetLabel(settings.defaultBudget),
                ),
                const Divider(height: 24),
                _buildPreferenceItem(
                  context: context,
                  icon: Icons.local_fire_department,
                  label: 'Độ cay',
                  value: 'Cấp ${settings.spiceTolerance}/5',
                ),
                const Divider(height: 24),
                _buildPreferenceItem(
                  context: context,
                  icon: Icons.eco,
                  label: 'Ăn chay',
                  value: settings.isVegetarian ? 'Có' : 'Không',
                ),
                if (settings.excludedAllergens.isNotEmpty) ...[
                  const Divider(height: 24),
                  _buildPreferenceItem(
                    context: context,
                    icon: Icons.warning_amber,
                    label: 'Dị ứng',
                    value: '${settings.excludedAllergens.length} loại',
                  ),
                ],
                if (settings.favoriteCuisines.isNotEmpty) ...[
                  const Divider(height: 24),
                  _buildPreferenceItem(
                    context: context,
                    icon: Icons.restaurant,
                    label: 'Ẩm thực yêu thích',
                    value: '${settings.favoriteCuisines.length} loại',
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPreferenceItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }
  
  String _getBudgetLabel(int budget) {
    switch (budget) {
      case 1:
        return 'Rẻ';
      case 2:
        return 'Vừa';
      case 3:
        return 'Sang';
      default:
        return 'Vừa';
    }
  }
  
  int _calculateActiveDays(DateTime createdAt) {
    return DateTime.now().difference(createdAt).inDays;
  }
}