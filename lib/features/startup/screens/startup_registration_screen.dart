import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/bloc/auth_cubit.dart';
import '../repositories/startup_repository.dart';

class StartupRegistrationScreen extends StatefulWidget {
  const StartupRegistrationScreen({super.key});

  @override
  State<StartupRegistrationScreen> createState() =>
      _StartupRegistrationScreenState();
}

class _StartupRegistrationScreenState
    extends State<StartupRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _taglineController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _codeController = TextEditingController();
  String _category = AppConstants.categories.first;

  bool _isVerifying = false;
  bool _isSubmitting = false;
  bool? _codeValid; // null = not checked yet

  @override
  void dispose() {
    _nameController.dispose();
    _taglineController.dispose();
    _descriptionController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) return;
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the ALU issued startup code first.')),
      );
      return;
    }

    setState(() {
      _isVerifying = true;
      _codeValid = null;
    });

    final repository = context.read<StartupRepository>();
    final isValid = await repository.verifyStartupCode(
      code: code,
      startupId: authState.user.id,
    );

    if (!mounted) return;
    setState(() {
      _isVerifying = false;
      _codeValid = isValid;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) return;

    setState(() => _isSubmitting = true);

    try {
      final repository = context.read<StartupRepository>();
      await repository.createStartup(
        ownerId: authState.user.id,
        name: _nameController.text.trim(),
        tagline: _taglineController.text.trim(),
        category: _category,
        description: _descriptionController.text.trim(),
        email: authState.user.email,
        verificationStatus: _codeValid == true ? 'approved' : 'pending',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_codeValid == true
              ? '🎉 Startup registered and verified!'
              : 'Startup registered! Verification is still pending.'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/startup/dashboard');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Something went wrong: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Register Startup'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Startup Profile', style: AppTextStyles.displayMedium),
              const SizedBox(height: 8),
              Text('Tell us a bit about your startup.',
                  style: AppTextStyles.bodyMedium),
              const SizedBox(height: 28),

              const _Label('Startup Name'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Tech Rwanda Ltd',
                  prefixIcon: Icon(Icons.business_outlined, size: 20),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Startup name required' : null,
              ),
              const SizedBox(height: 20),

              const _Label('Tagline'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _taglineController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Building digital solutions for Africa',
                  prefixIcon: Icon(Icons.short_text_rounded, size: 20),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Tagline required' : null,
              ),
              const SizedBox(height: 20),

              const _Label('Startup Category'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.category_outlined, size: 20),
                ),
                items: AppConstants.categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v ?? _category),
              ),
              const SizedBox(height: 20),

              const _Label('Startup Description'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText:
                      'Describe your startup, its mission, and what kind of support you need...',
                  alignLabelWithHint: true,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Description required';
                  if (v.trim().length < 50) {
                    return 'Please provide at least 50 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified_outlined,
                            size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text('ALU Startup Verification',
                            style: AppTextStyles.titleMedium),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Enter the code issued by ALU for your startup. This verifies '
                      'that your startup is recognized within the ALU ecosystem.',
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _codeController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              hintText: 'Enter ALU issued startup code',
                              prefixIcon: Icon(Icons.key_outlined, size: 20),
                            ),
                            onChanged: (_) {
                              if (_codeValid != null) {
                                setState(() => _codeValid = null);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isVerifying ? null : _verifyCode,
                            style: ElevatedButton.styleFrom(
                                minimumSize: const Size(90, 56)),
                            child: _isVerifying
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Verify',
                                    style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                    if (_codeValid == true) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              color: AppColors.success, size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Valid code - Startup verified successfully.',
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.success),
                            ),
                          ),
                        ],
                      ),
                    ] else if (_codeValid == false) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.cancel_rounded,
                              color: AppColors.error, size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Invalid or already used code. You can still register '
                              'and verify later.',
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Register Startup',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) =>
      Text(text, style: AppTextStyles.labelLarge);
}
