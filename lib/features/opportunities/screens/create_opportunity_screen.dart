import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/bloc/auth_cubit.dart';
import '../../startup/repositories/startup_repository.dart';
import '../models/opportunity_model.dart';
import '../repositories/opportunity_repository.dart';

class CreateOpportunityScreen extends StatefulWidget {
  // When set, the screen opens in "edit an existing opportunity" mode.
  final String? opportunityId;

  const CreateOpportunityScreen({super.key, this.opportunityId});

  bool get isEditMode => opportunityId != null;

  @override
  State<CreateOpportunityScreen> createState() => _CreateOpportunityScreenState();
}

class _CreateOpportunityScreenState extends State<CreateOpportunityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _hoursController = TextEditingController();
  final _durationController = TextEditingController();
  final _compensationController = TextEditingController();
  String _category = 'Engineering';
  String _type = 'Part-time';
  String _location = 'On-campus';
  bool _isPaid = false;
  DateTime? _deadline;
  final List<String> _selectedSkills = [];
  final List<String> _selectedTags = [];
  bool _isSubmitting = false;
  OpportunityModel? _existingOpportunity;
  bool _isLoadingExisting = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditMode) {
      _isLoadingExisting = true;
      _loadExisting();
    }
  }

  Future<void> _loadExisting() async {
    final opp = await context
        .read<OpportunityRepository>()
        .getOpportunityById(widget.opportunityId!);
    if (!mounted) return;
    if (opp != null) {
      _titleController.text = opp.title;
      _descriptionController.text = opp.description;
      _hoursController.text = opp.hoursPerWeek ?? '';
      _durationController.text = opp.duration ?? '';
      _compensationController.text = opp.compensation ?? '';
      setState(() {
        _existingOpportunity = opp;
        _category = opp.category;
        _type = opp.type;
        _location = opp.location;
        _isPaid = opp.isPaid;
        _deadline = opp.deadline;
        _selectedSkills
          ..clear()
          ..addAll(opp.skills);
        _selectedTags
          ..clear()
          ..addAll(opp.tags);
        _isLoadingExisting = false;
      });
    } else {
      setState(() => _isLoadingExisting = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _hoursController.dispose();
    _durationController.dispose();
    _compensationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSkills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one skill required')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final authState = context.read<AuthCubit>().state;
      if (authState is! AuthAuthenticated) return;

      final opportunityRepository = context.read<OpportunityRepository>();

      if (widget.isEditMode) {
        if (_existingOpportunity == null) {
          setState(() => _isSubmitting = false);
          return;
        }

        final updated = OpportunityModel(
          id: _existingOpportunity!.id,
          startupId: _existingOpportunity!.startupId,
          startupName: _existingOpportunity!.startupName,
          startupLogoUrl: _existingOpportunity!.startupLogoUrl,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _category,
          skills: _selectedSkills,
          tags: _selectedTags,
          type: _type,
          location: _location,
          hoursPerWeek: _hoursController.text.trim().isNotEmpty
              ? _hoursController.text.trim()
              : null,
          duration: _durationController.text.trim().isNotEmpty
              ? _durationController.text.trim()
              : null,
          isPaid: _isPaid,
          compensation: _isPaid && _compensationController.text.trim().isNotEmpty
              ? _compensationController.text.trim()
              : null,
          applicationCount: _existingOpportunity!.applicationCount,
          status: _existingOpportunity!.status,
          deadline: _deadline,
          createdAt: _existingOpportunity!.createdAt,
          updatedAt: DateTime.now(),
        );

        await opportunityRepository.updateOpportunity(updated);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Opportunity updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        if (mounted) context.pop();
        return;
      }

      debugPrint('[CreateOpportunity] posting by startupId=${authState.user.id}');

      final startupRepository = context.read<StartupRepository>();

      final startup = await startupRepository.getStartupById(authState.user.id);

      if (!mounted) return;

      if (startup == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Startup profile not found.'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _isSubmitting = false);
        return;
      }


      final opportunity = OpportunityModel(
        id: '',
        startupId: startup.id,
        startupName: startup.name,
        startupLogoUrl: startup.logoUrl,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _category,
        skills: _selectedSkills,
        tags: _selectedTags,
        type: _type,
        location: _location,
        hoursPerWeek: _hoursController.text.trim().isNotEmpty
            ? _hoursController.text.trim()
            : null,
        duration: _durationController.text.trim().isNotEmpty
            ? _durationController.text.trim()
            : null,
        isPaid: _isPaid,
        compensation: _isPaid && _compensationController.text.trim().isNotEmpty
            ? _compensationController.text.trim()
            : null,
        deadline: _deadline,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await opportunityRepository.createOpportunity(opportunity);

      if (!mounted) return;

      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('✅ Opportunity posted successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      if (mounted) {
        context.pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingExisting) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(widget.isEditMode ? 'Edit Opportunity' : 'Post Opportunity'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              const _Label('Role Title *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Flutter Developer, Marketing Intern',
                  prefixIcon: Icon(Icons.work_outline_rounded, size: 20),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Title required' : null,
              ),
              const SizedBox(height: 20),

              // Category
              const _Label('Category *'),
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

              // Type & Location row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _Label('Type'),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _type,
                          items: ['Part-time', 'Full-time', 'Volunteer', 'Project-based']
                              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                              .toList(),
                          onChanged: (v) => setState(() => _type = v ?? _type),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _Label('Location'),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _location,
                          items: ['On-campus', 'Remote', 'Hybrid']
                              .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _location = v ?? _location),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Hours / Duration row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _Label('Hours/week'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _hoursController,
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(hintText: 'e.g. 8–10'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _Label('Duration'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _durationController,
                          decoration:
                              const InputDecoration(hintText: 'e.g. 3 months'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Description
              const _Label('Description *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText:
                      'Describe the role, responsibilities, and what the intern will work on...',
                  alignLabelWithHint: true,
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Description required';
                  if (v.length < 80) return 'Please write at least 80 characters';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Skills required
              const _Label('Skills Required *'),
              const SizedBox(height: 6),
              Text('Select all skills needed for this role.',
                  style: AppTextStyles.bodySmall),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.popularSkills.map((skill) {
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      child: Text(
                        skill,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Compensation toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.attach_money_rounded,
                        color: AppColors.success, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Paid opportunity', style: AppTextStyles.titleMedium),
                          Text('Does this role include compensation?',
                              style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isPaid,
                      activeThumbColor: AppColors.primary,
                      onChanged: (v) => setState(() => _isPaid = v),
                    ),
                  ],
                ),
              ),

              if (_isPaid) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _compensationController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. 50 USD/month, stipend based on performance',
                    prefixIcon: Icon(Icons.monetization_on_outlined, size: 20),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Deadline
              const _Label('Application Deadline (Optional)'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 14)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => _deadline = picked);
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          color: AppColors.textSecondary, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        _deadline != null
                            ? '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}'
                            : 'Select a deadline',
                        style: _deadline != null
                            ? AppTextStyles.bodyLarge
                            : AppTextStyles.bodyMedium,
                      ),
                      const Spacer(),
                      if (_deadline != null)
                        GestureDetector(
                          onTap: () => setState(() => _deadline = null),
                          child: const Icon(Icons.clear,
                              color: AppColors.textTertiary, size: 18),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 36),

              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(widget.isEditMode ? 'Save Changes' : 'Post Opportunity',
                        style: const TextStyle(
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
