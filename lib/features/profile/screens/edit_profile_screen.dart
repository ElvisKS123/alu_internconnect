import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/bloc/auth_cubit.dart';
import '../../auth/repositories/auth_repository.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _locationController;
  late TextEditingController _linkedinController;
  late TextEditingController _portfolioController;
  final _customSkillController = TextEditingController();
  List<String> _selectedSkills = [];
  bool _isSaving = false;

  void _addCustomSkill() {
    final skill = _customSkillController.text.trim();
    if (skill.isEmpty) return;
    // Avoid case-sensitive duplicates (e.g. "flutter" vs "Flutter").
    final alreadyAdded = _selectedSkills
        .any((s) => s.toLowerCase() == skill.toLowerCase());
    if (alreadyAdded) {
      _customSkillController.clear();
      return;
    }
    setState(() {
      _selectedSkills.add(skill);
      _customSkillController.clear();
    });
  }

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthCubit>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;

    _nameController = TextEditingController(text: user?.fullName ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
    _locationController = TextEditingController(text: user?.location ?? '');
    _linkedinController = TextEditingController(text: user?.linkedinUrl ?? '');
    _portfolioController = TextEditingController(text: user?.portfolioUrl ?? '');
    _selectedSkills = List<String>.from(user?.skills ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _linkedinController.dispose();
    _portfolioController.dispose();
    _customSkillController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final authState = context.read<AuthCubit>().state;
      if (authState is! AuthAuthenticated) return;

      final updatedUser = authState.user.copyWith(
        fullName: _nameController.text.trim(),
        bio: _bioController.text.trim(),
        location: _locationController.text.trim(),
        linkedinUrl: _linkedinController.text.trim().isNotEmpty
            ? _linkedinController.text.trim()
            : null,
        portfolioUrl: _portfolioController.text.trim().isNotEmpty
            ? _portfolioController.text.trim()
            : null,
        skills: _selectedSkills,
      );

      await context.read<AuthRepository>().updateUserProfile(updatedUser);

      if (!mounted) return;

      // Keep AuthCubit's in-memory user in sync immediately (skills, bio,
      // etc.), otherwise the app keeps showing the pre-edit profile until
      // the next sign-in.
      context.read<AuthCubit>().updateLocalUser(updatedUser);

      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      if (mounted) {
        context.pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
        title: const Text('Edit Profile'),
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
              // Avatar section
              Center(
                child: Stack(
                  children: [
                    BlocBuilder<AuthCubit, AuthState>(
                      builder: (context, state) {
                        final user =
                            state is AuthAuthenticated ? state.user : null;
                        return CircleAvatar(
                          radius: 44,
                          backgroundColor: AppColors.primaryLight,
                          backgroundImage: user?.photoUrl != null
                              ? NetworkImage(user!.photoUrl!)
                              : null,
                          child: user?.photoUrl == null
                              ? Text(
                                  user?.firstName[0].toUpperCase() ?? '?',
                                  style: AppTextStyles.displayLarge
                                      .copyWith(color: AppColors.primary),
                                )
                              : null,
                        );
                      },
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt_rounded,
                            color: Colors.white, size: 14),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              const _Label('Full Name'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'Your full name',
                  prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Name required' : null,
              ),

              const SizedBox(height: 20),
              const _Label('Bio'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bioController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Tell startups about yourself...',
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 20),
              const _Label('Location'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Kigali, Rwanda',
                  prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                ),
              ),

              const SizedBox(height: 20),
              const _Label('LinkedIn URL'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _linkedinController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  hintText: 'https://linkedin.com/in/yourname',
                  prefixIcon: Icon(Icons.link_rounded, size: 20),
                ),
              ),

              const SizedBox(height: 20),
              const _Label('Portfolio URL'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _portfolioController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  hintText: 'https://yourportfolio.com',
                  prefixIcon: Icon(Icons.web_rounded, size: 20),
                ),
              ),

              const SizedBox(height: 28),
              const _Label('Skills & Interests'),
              const SizedBox(height: 6),
              Text('Add any skill or interest, or pick from popular ones below.',
                  style: AppTextStyles.bodySmall),
              const SizedBox(height: 12),

              // Free-text add field, for skills/interests not in the
              // predefined list below.
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _customSkillController,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _addCustomSkill(),
                      decoration: const InputDecoration(
                        hintText: 'e.g. Public Speaking, Photography...',
                        prefixIcon: Icon(Icons.add_rounded, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _addCustomSkill,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 54),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                    ),
                    child: const Text('Add',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),

              if (_selectedSkills.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Your skills (tap to remove)', style: AppTextStyles.labelLarge),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedSkills.map((skill) {
                    return GestureDetector(
                      onTap: () => setState(() => _selectedSkills.remove(skill)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(skill,
                                style: AppTextStyles.labelLarge
                                    .copyWith(color: Colors.white)),
                            const SizedBox(width: 6),
                            const Icon(Icons.close_rounded,
                                color: Colors.white, size: 15),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 16),
              Text('Popular skills', style: AppTextStyles.labelLarge),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                // Only offer skills that aren't already selected above --
                // once picked, a skill moves into the removable list.
                children: AppConstants.popularSkills
                    .where((skill) => !_selectedSkills
                        .any((s) => s.toLowerCase() == skill.toLowerCase()))
                    .map((skill) {
                  return GestureDetector(
                    onTap: () => setState(() => _selectedSkills.add(skill)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        skill,
                        style: AppTextStyles.labelLarge
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 36),

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
