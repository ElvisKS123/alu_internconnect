import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/bloc/auth_cubit.dart';
import '../../applications/bloc/application_cubit.dart';
import '../../opportunities/repositories/opportunity_repository.dart';
import '../../opportunities/models/opportunity_model.dart';

class ApplyScreen extends StatefulWidget {
  final String opportunityId;

  const ApplyScreen({super.key, required this.opportunityId});

  @override
  State<ApplyScreen> createState() => _ApplyScreenState();
}

class _ApplyScreenState extends State<ApplyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _coverLetterController = TextEditingController();
  final _portfolioController = TextEditingController();
  final List<String> _selectedSkills = [];
  OpportunityModel? _opportunity;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOpportunity();
  }

  Future<void> _loadOpportunity() async {
    final opp = await context
        .read<OpportunityRepository>()
        .getOpportunityById(widget.opportunityId);
    setState(() {
      _opportunity = opp;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _coverLetterController.dispose();
    _portfolioController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_opportunity == null) return;

    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) return;
    final user = authState.user;

    await context.read<ApplicationCubit>().submitApplication(
          opportunityId: widget.opportunityId,
          opportunityTitle: _opportunity!.title,
          startupId: _opportunity!.startupId,
          startupName: _opportunity!.startupName,
          startupLogoUrl: _opportunity!.startupLogoUrl,
          applicantId: user.id,
          applicantName: user.fullName,
          applicantEmail: user.email,
          applicantPhotoUrl: user.photoUrl,
          coverLetter: _coverLetterController.text.trim(),
          portfolioUrl: _portfolioController.text.trim().isNotEmpty
              ? _portfolioController.text.trim()
              : null,
          relevantSkills: _selectedSkills,
        );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_opportunity == null) {
      return Scaffold(
          appBar: AppBar(), body: const Center(child: Text('Not found')));
    }

    final opp = _opportunity!;

    return BlocListener<ApplicationCubit, ApplicationState>(
      listener: (context, state) {
        if (state is ApplicationSubmitted) {
          _showSuccessSheet(context);
        }
        if (state is ApplicationError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded),
            onPressed: () => context.pop(),
          ),
          title: const Text('Apply'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Opportunity summary card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppColors.cardGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            opp.startupName.isNotEmpty
                                ? opp.startupName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(opp.title,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600)),
                            Text(opp.startupName,
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Cover letter
                Text('Cover Letter *', style: AppTextStyles.labelLarge),
                const SizedBox(height: 6),
                Text(
                  'Tell the startup why you\'re a great fit for this role.',
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _coverLetterController,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    hintText:
                        'I am excited about this opportunity because...\n\nMy relevant experience includes...\n\nI would love to contribute by...',
                    alignLabelWithHint: true,
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Cover letter is required';
                    if (v.trim().length < 100) {
                      return 'Please write at least 100 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Relevant skills
                Text('Relevant Skills', style: AppTextStyles.labelLarge),
                const SizedBox(height: 6),
                Text('Select skills that apply to this role.',
                    style: AppTextStyles.bodySmall),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: opp.skills.isEmpty
                      ? AppConstants.popularSkills.take(10).map(_buildSkillChip).toList()
                      : opp.skills.map(_buildSkillChip).toList(),
                ),

                const SizedBox(height: 24),

                // Portfolio
                Text('Portfolio / LinkedIn (Optional)',
                    style: AppTextStyles.labelLarge),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _portfolioController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    hintText: 'https://linkedin.com/in/yourname',
                    prefixIcon:
                        Icon(Icons.link_rounded, size: 20),
                  ),
                ),

                const SizedBox(height: 36),

                BlocBuilder<ApplicationCubit, ApplicationState>(
                  builder: (context, state) {
                    return ElevatedButton(
                      onPressed:
                          state is ApplicationSubmitting ? null : _submit,
                      child: state is ApplicationSubmitting
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Submit Application',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                    );
                  },
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkillChip(String skill) {
    final isSelected = _selectedSkills.contains(skill);
    return GestureDetector(
      onTap: () => setState(() {
        if (isSelected) {
          _selectedSkills.remove(skill);
        } else {
          _selectedSkills.add(skill);
        }
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          skill,
          style: AppTextStyles.labelLarge.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  void _showSuccessSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: AppColors.success, size: 40),
            ),
            const SizedBox(height: 20),
            Text('Application Submitted!',
                style: AppTextStyles.headlineLarge),
            const SizedBox(height: 10),
            Text(
              'Your application has been sent to ${_opportunity?.startupName}. You\'ll be notified when they review it.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.go('/applications');
              },
              child: const Text('View My Applications',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.go('/home');
              },
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
