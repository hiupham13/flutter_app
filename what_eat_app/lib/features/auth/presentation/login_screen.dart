import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:what_eat_app/config/theme/style_tokens.dart';
import 'package:what_eat_app/core/constants/app_colors.dart';
import 'package:what_eat_app/core/widgets/custom_textfield.dart';
import 'package:what_eat_app/core/widgets/loading_indicator.dart';
import 'package:what_eat_app/core/widgets/primary_button.dart';

import '../logic/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = ref.read(authControllerProvider.notifier);
    await auth.signIn(_emailCtrl.text.trim(), _passwordCtrl.text.trim());
    final state = ref.read(authControllerProvider);
    state.whenOrNull(
      data: (user) {
        if (user != null && mounted) {
          context.goNamed('dashboard');
        }
      },
      error: (err, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err.toString())),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < AppBreakpoints.compact;
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Chào mừng trở lại',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Đăng nhập để tiếp tục khám phá món ngon phù hợp với bạn.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        boxShadow: const [AppShadows.card],
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            CustomTextField(
                              label: 'Email',
                              hint: 'name@example.com',
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) => (v == null || !v.contains('@')) ? 'Email không hợp lệ' : null,
                              autofillHints: const [AutofillHints.email],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            CustomTextField(
                              label: 'Mật khẩu',
                              hint: '••••••••',
                              controller: _passwordCtrl,
                              obscureText: _obscure,
                              validator: (v) => (v == null || v.length < 6) ? 'Tối thiểu 6 ký tự' : null,
                              suffixIcon: IconButton(
                                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
                              autofillHints: const [AutofillHints.password],
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            PrimaryButton(
                              label: 'Đăng nhập',
                              isLoading: isLoading,
                              onPressed: isLoading ? null : _submit,
                              size: AppButtonSize.large,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton(
                                  onPressed: () => context.goNamed('register'),
                                  child: const Text('Tạo tài khoản'),
                                ),
                                TextButton(
                                  onPressed: () => context.goNamed('forgot_password'),
                                  child: const Text('Quên mật khẩu?'),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              children: const [
                                Expanded(child: Divider()),
                                SizedBox(width: AppSpacing.sm),
                                Text('hoặc'),
                                SizedBox(width: AppSpacing.sm),
                                Expanded(child: Divider()),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _SocialButton(
                              icon: Icons.g_mobiledata,
                              label: 'Đăng nhập với Google',
                              onPressed: isLoading
                                  ? null
                                  : () async {
                                      final notifier = ref.read(authControllerProvider.notifier);
                                      await notifier.signInWithGoogle();
                                      final state = ref.read(authControllerProvider);
                                      state.whenOrNull(
                                        data: (user) {
                                          if (user != null && mounted) {
                                            context.goNamed('dashboard');
                                          }
                                        },
                                        error: (err, _) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text(err.toString())),
                                          );
                                        },
                                      );
                                    },
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _SocialButton(
                              icon: Icons.facebook,
                              label: 'Đăng nhập với Facebook',
                              onPressed: isLoading
                                  ? null
                                  : () async {
                                      final notifier = ref.read(authControllerProvider.notifier);
                                      await notifier.signInWithFacebook();
                                      final state = ref.read(authControllerProvider);
                                      state.whenOrNull(
                                        data: (user) {
                                          if (user != null && mounted) {
                                            context.goNamed('dashboard');
                                          }
                                        },
                                        error: (err, _) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text(err.toString())),
                                          );
                                        },
                                      );
                                    },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    if (isLoading) const LoadingIndicator(message: 'Đang đăng nhập...'),
                    if (!isCompact) const SizedBox(height: AppSpacing.xxxl),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _SocialButton({
    required this.icon,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      icon: Icon(icon, color: AppColors.textPrimary),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      onPressed: onPressed,
    );
  }
}

