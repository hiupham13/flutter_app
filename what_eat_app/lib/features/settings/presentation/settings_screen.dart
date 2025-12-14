import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/error_widget.dart' as custom;
import '../../../core/services/cache_service.dart';
import '../../../features/user/logic/user_profile_provider.dart';
import '../../../features/auth/logic/auth_provider.dart';
import '../../../models/user_model.dart';
import '../../../core/utils/logger.dart';
import 'widgets/budget_selector_dialog.dart';
import 'widgets/spice_tolerance_slider.dart';
import 'widgets/allergen_picker_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileStreamProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài Đặt'),
        elevation: 0,
      ),
      body: userProfile.when(
        data: (user) => user == null 
            ? const Center(child: Text('Chưa đăng nhập'))
            : _buildSettings(context, ref, user),
        loading: () => const LoadingIndicator(),
        error: (e, st) => custom.AppErrorWidget(
          title: 'Lỗi tải dữ liệu',
          message: e.toString(),
        ),
      ),
    );
  }
  
  Widget _buildSettings(BuildContext context, WidgetRef ref, UserModel user) {
    return ListView(
      children: [
        // Account Section
        _buildSection(
          context: context,
          title: 'Tài Khoản',
          children: [
            _buildAccountTile(context, user),
          ],
        ),
        
        const Divider(height: 32),
        
        // Food Preferences Section
        _buildSection(
          context: context,
          title: 'Sở Thích Ăn Uống',
          children: [
            _buildBudgetTile(context, ref, user),
            _buildSpiceTile(context, ref, user),
            _buildVegetarianTile(context, ref, user),
            _buildAllergiesTile(context, ref, user),
            _buildCuisinesTile(context, ref, user),
          ],
        ),
        
        const Divider(height: 32),
        
        // Data Section
        _buildSection(
          context: context,
          title: 'Dữ Liệu',
          children: [
            _buildClearCacheTile(context, ref),
          ],
        ),
        
        const Divider(height: 32),
        
        // Legal & About Section
        _buildSection(
          context: context,
          title: 'Pháp Lý & Hỗ Trợ',
          children: [
            _buildPrivacyPolicyTile(context),
            _buildDeleteAccountTile(context),
            _buildSupportTile(context),
            _buildAboutTile(context),
          ],
        ),
        
        const SizedBox(height: 32),
        
        // Logout Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildLogoutButton(context, ref),
        ),
        
        const SizedBox(height: 32),
      ],
    );
  }
  
  Widget _buildSection({
    required BuildContext context,
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
  
  Widget _buildAccountTile(BuildContext context, UserModel user) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Text(
          user.info.displayName.isNotEmpty 
              ? user.info.displayName[0].toUpperCase()
              : '?',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(user.info.displayName),
      subtitle: Text(user.info.email),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // Navigate to edit profile
        AppLogger.info('Edit profile tapped');
      },
    );
  }
  
  Widget _buildBudgetTile(BuildContext context, WidgetRef ref, UserModel user) {
    final budgetLabels = ['Rẻ (<35k)', 'Vừa (35-80k)', 'Sang (>80k)'];
    final budgetIcons = [Icons.money_off, Icons.attach_money, Icons.diamond];
    
    return ListTile(
      leading: Icon(budgetIcons[user.settings.defaultBudget - 1]),
      title: const Text('Ngân sách mặc định'),
      subtitle: Text(budgetLabels[user.settings.defaultBudget - 1]),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        final result = await showDialog<int>(
          context: context,
          builder: (context) => BudgetSelectorDialog(
            currentBudget: user.settings.defaultBudget,
          ),
        );
        
        if (result != null && result != user.settings.defaultBudget) {
          await ref.read(userProfileControllerProvider.notifier).updatePreferences(
            defaultBudget: result,
          );
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã cập nhật ngân sách mặc định')),
            );
          }
        }
      },
    );
  }
  
  Widget _buildSpiceTile(BuildContext context, WidgetRef ref, UserModel user) {
    return ListTile(
      leading: const Icon(Icons.local_fire_department),
      title: const Text('Độ cay chịu được'),
      subtitle: Text('Cấp độ: ${user.settings.spiceTolerance}/5'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        final result = await showDialog<int>(
          context: context,
          builder: (context) => SpiceToleranceDialog(
            currentLevel: user.settings.spiceTolerance,
          ),
        );
        
        if (result != null && result != user.settings.spiceTolerance) {
          await ref.read(userProfileControllerProvider.notifier).updatePreferences(
            spiceTolerance: result,
          );
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã cập nhật độ cay')),
            );
          }
        }
      },
    );
  }
  
  Widget _buildVegetarianTile(BuildContext context, WidgetRef ref, UserModel user) {
    return SwitchListTile(
      secondary: const Icon(Icons.eco),
      title: const Text('Ăn chay'),
      subtitle: const Text('Chỉ hiển thị món chay'),
      value: user.settings.isVegetarian,
      onChanged: (value) async {
        await ref.read(userProfileControllerProvider.notifier).updatePreferences(
          isVegetarian: value,
        );
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(value ? 'Đã bật chế độ ăn chay' : 'Đã tắt chế độ ăn chay'),
            ),
          );
        }
      },
    );
  }
  
  Widget _buildAllergiesTile(BuildContext context, WidgetRef ref, UserModel user) {
    final allergenCount = user.settings.excludedAllergens.length;
    
    return ListTile(
      leading: const Icon(Icons.warning_amber),
      title: const Text('Dị ứng thực phẩm'),
      subtitle: Text(
        allergenCount > 0 
            ? '$allergenCount loại đã chọn'
            : 'Chưa có',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        // Get available allergens from master data
        final availableAllergens = ['Hải sản', 'Sữa', 'Trứng', 'Đậu', 'Gluten', 'Đậu nành'];
        
        final result = await showDialog<List<String>>(
          context: context,
          builder: (context) => AllergenPickerDialog(
            currentAllergens: user.settings.excludedAllergens,
            availableAllergens: availableAllergens,
          ),
        );
        
        if (result != null) {
          await ref.read(userProfileControllerProvider.notifier).updatePreferences(
            excludedAllergens: result,
          );
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã cập nhật dị ứng')),
            );
          }
        }
      },
    );
  }
  
  Widget _buildCuisinesTile(BuildContext context, WidgetRef ref, UserModel user) {
    final cuisineCount = user.settings.favoriteCuisines.length;
    
    return ListTile(
      leading: const Icon(Icons.restaurant),
      title: const Text('Ẩm thực yêu thích'),
      subtitle: Text(
        cuisineCount > 0 
            ? '$cuisineCount loại đã chọn'
            : 'Chưa có',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // TODO: Show cuisine picker dialog
        AppLogger.info('Cuisine picker tapped');
      },
    );
  }
  
  Widget _buildClearCacheTile(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const Icon(Icons.delete_outline),
      title: const Text('Xóa cache'),
      subtitle: const Text('Xóa dữ liệu cache local'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Xóa cache?'),
            content: const Text(
              'Việc này sẽ xóa tất cả dữ liệu cache local. '
              'App sẽ tải lại dữ liệu từ server lần mở tiếp theo.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Xóa'),
              ),
            ],
          ),
        );
        
        if (confirmed == true) {
          try {
            // Clear cache through cache service
            final cacheService = CacheService();
            await cacheService.clearCache();
            
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã xóa cache thành công')),
              );
            }
          } catch (e) {
            AppLogger.error('Clear cache failed: $e');
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Lỗi: $e')),
              );
            }
          }
        }
      },
    );
  }
  
  Widget _buildPrivacyPolicyTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.privacy_tip_outlined),
      title: const Text('Chính sách bảo mật'),
      trailing: const Icon(Icons.open_in_new, size: 18),
      onTap: () async {
        final url = Uri.parse('https://whateatapp.vercel.app/privacy-policy.html');
        try {
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          } else {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Không thể mở liên kết')),
              );
            }
          }
        } catch (e) {
          AppLogger.error('Failed to launch privacy policy URL: $e');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Lỗi khi mở liên kết')),
            );
          }
        }
      },
    );
  }

  Widget _buildDeleteAccountTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.delete_forever_outlined),
      title: const Text('Xóa tài khoản'),
      subtitle: const Text('Yêu cầu xóa tài khoản và dữ liệu'),
      trailing: const Icon(Icons.open_in_new, size: 18),
      onTap: () async {
        final url = Uri.parse('https://whateatapp.vercel.app/delete-account.html');
        try {
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          } else {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Không thể mở liên kết')),
              );
            }
          }
        } catch (e) {
          AppLogger.error('Failed to launch delete account URL: $e');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Lỗi khi mở liên kết')),
            );
          }
        }
      },
    );
  }

  Widget _buildSupportTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.help_outline),
      title: const Text('Hỗ trợ'),
      subtitle: const Text('Câu hỏi thường gặp và liên hệ'),
      trailing: const Icon(Icons.open_in_new, size: 18),
      onTap: () async {
        final url = Uri.parse('https://whateatapp.vercel.app/support.html');
        try {
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          } else {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Không thể mở liên kết')),
              );
            }
          }
        } catch (e) {
          AppLogger.error('Failed to launch support URL: $e');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Lỗi khi mở liên kết')),
            );
          }
        }
      },
    );
  }

  Widget _buildAboutTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.info_outline),
      title: const Text('Về ứng dụng'),
      subtitle: const Text('Phiên bản 1.0.0'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        showAboutDialog(
          context: context,
          applicationName: 'What Eat - Hôm Nay Ăn Gì?',
          applicationVersion: '1.0.0',
          applicationIcon: const Icon(Icons.restaurant_menu, size: 48),
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text(
                'Ứng dụng đề xuất món ăn thông minh cho người Việt. '
                'Giúp bạn tìm ra món ăn hoàn hảo mỗi ngày dựa trên '
                'thời tiết, vị trí và sở thích của bạn.',
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      onPressed: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Đăng xuất?'),
            content: const Text('Bạn có chắc muốn đăng xuất?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Đăng xuất'),
              ),
            ],
          ),
        );
        
        if (confirmed == true) {
          await ref.read(authRepositoryProvider).signOut();
          
          if (context.mounted) {
            // Navigation will be handled by auth state listener
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã đăng xuất')),
            );
          }
        }
      },
      icon: const Icon(Icons.logout),
      label: const Text('Đăng xuất'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.error,
        side: BorderSide(color: Theme.of(context).colorScheme.error),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }
}