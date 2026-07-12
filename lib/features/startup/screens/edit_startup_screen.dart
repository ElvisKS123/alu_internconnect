import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/bloc/auth_cubit.dart';
import '../models/startup_model.dart';
import '../repositories/startup_repository.dart';

class EditStartupScreen extends StatefulWidget {
  const EditStartupScreen({super.key});

  @override
  State<EditStartupScreen> createState() => _EditStartupScreenState();
}

class _EditStartupScreenState extends State<EditStartupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _taglineController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _category = AppConstants.categories.first;

  StartupModel? _startup;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) return;

    final startup =
        await context.read<StartupRepository>().getStartupById(authState.user.id);

    if (!mounted) return;
    setState(() {
      _startup = startup;
      if (startup != null) {
        _nameController.text = startup.name;
        _taglineController.text = startup.tagline;
        _descriptionController.text = startup.description;
        _category = startup.category;
      }
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _taglineController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final startup = _startup;
    if (startup == null) return;

    setState(() => _isSaving = true);
    try {
      final updated = StartupModel(
        id: startup.id,
        ownerId: startup.ownerId,
        name: _nameController.text.trim(),
        tagline: _taglineController.text.trim(),
        description: _descriptionController.text.trim(),
        logoUrl: startup.logoUrl,
        bannerUrl: startup.bannerUrl,
        category: _category,
        tags: startup.tags,
        verificationStatus: startup.verificationStatus,
        verificationNote: startup.verificationNote,
        aluRecognitionProof: startup.aluRecognitionProof,
        websiteUrl: startup.websiteUrl,
        linkedinUrl: startup.linkedinUrl,
        instagramUrl: startup.instagramUrl,
        email: startup.email,
        teamSize: startup.teamSize,
        totalOpportunities: startup.totalOpportunities,
        activeOpportunities: startup.activeOpportunities,
        createdAt: startup.createdAt,
        updatedAt: DateTime.now(),
      );

      await context.read<StartupRepository>().updateStartup(updated);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Startup information updated!'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_startup == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Startup Information')),
        body: const Center(child: Text('Startup profile not found.')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Edit Startup Information'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: Text(
              'Save',
              style: AppTextStyles.titleMedium.copyWith(
                color: _isSaving ? AppColors.textTertiary : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                  hintText: 'One-line description of what you do',
                  prefixIcon: Icon(Icons.short_text_rounded, size: 20),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Tagline required' : null,
              ),
              const SizedBox(height: 20),

              const _Label('Category'),
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

              const _Label('Description'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Describe your startup, its mission, and what kind of support you need...',
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
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save Changes',
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
