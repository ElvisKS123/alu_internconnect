import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/bloc/auth_cubit.dart';
import '../../applications/bloc/application_cubit.dart';
import '../../applications/models/application_model.dart';
import '../../opportunities/repositories/opportunity_repository.dart';
import '../../opportunities/models/opportunity_model.dart';
import '../repositories/startup_repository.dart';
import '../models/startup_model.dart';

class StartupDashboardScreen extends StatefulWidget {
  const StartupDashboardScreen({super.key});

  @override
  State<StartupDashboardScreen> createState() => _StartupDashboardScreenState();
}

class _StartupDashboardScreenState extends State<StartupDashboardScreen> {
  StartupModel? _startup;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStartup();
  }

  Future<void> _loadStartup() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) return;

    final startupRepository = context.read<StartupRepository>();
    final applicationCubit = context.read<ApplicationCubit>();

    final startup = await startupRepository.getStartupById(authState.user.id);

    if (!mounted) return;

    setState(() {
      _startup = startup;
      _isLoading = false;
    });

    if (startup != null) {
      applicationCubit.loadStartupApplications(startup.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final username =
        authState is AuthAuthenticated ? authState.user.firstName : 'there';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Dashboard'),
        actions: [
          if (_startup != null)
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded),
              onPressed: () => context.push('/opportunity/create'),
              tooltip: 'Post new opportunity',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _startup == null
              ? _UnregisteredState(username: username)
              : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // Header: welcome + verification badge
                  _DashboardHeader(startup: _startup!),

                  const SizedBox(height: 20),

                  // Stats row
                  _StatsRow(startup: _startup!),

                  const SizedBox(height: 28),

                  // Applications section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Incoming Applications',
                          style: AppTextStyles.headlineMedium),
                    ],
                  ),
                  const SizedBox(height: 14),

                  BlocBuilder<ApplicationCubit, ApplicationState>(
                    builder: (context, state) {
                      if (state is ApplicationLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (state is! ApplicationsLoaded) {
                        return const SizedBox();
                      }

                      if (state.applications.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Center(
                            child: Column(
                              children: [
                                const Icon(Icons.inbox_outlined,
                                    size: 48, color: AppColors.textTertiary),
                                const SizedBox(height: 12),
                                Text('No applications yet',
                                    style: AppTextStyles.bodyMedium),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () => context.push('/opportunity/create'),
                                  style: ElevatedButton.styleFrom(
                                      minimumSize: const Size(160, 44)),
                                  child: const Text('Post an Opportunity',
                                      style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: state.applications
                            .map((app) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _ApplicantCard(application: app),
                                ))
                            .toList(),
                      );
                    },
                  ),

                  const SizedBox(height: 28),

                  // Active opportunities
                  Text('Your Opportunities',
                      style: AppTextStyles.headlineMedium),
                  const SizedBox(height: 14),

                  StreamBuilder<List<OpportunityModel>>(
                    stream: context
                        .read<OpportunityRepository>()
                        .watchStartupOpportunities(_startup!.id),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      final opps = snapshot.data!;
                      if (opps.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Center(
                            child: Text('No opportunities posted yet.',
                                style: AppTextStyles.bodyMedium),
                          ),
                        );
                      }
                      return Column(
                        children: opps
                            .map((opp) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _OpportunityManageCard(
                                    opportunity: opp,
                                    onClose: () async {
                                      await context
                                          .read<OpportunityRepository>()
                                          .closeOpportunity(
                                              opp.id, opp.startupId);
                                    },
                                  ),
                                ))
                            .toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}

class _UnregisteredState extends StatelessWidget {
  final String username;
  const _UnregisteredState({required this.username});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.rocket_launch_outlined,
                  color: AppColors.primary, size: 32),
            ),
            const SizedBox(height: 20),
            Text('Hi, $username', style: AppTextStyles.headlineLarge),
            const SizedBox(height: 10),
            Text(
              'Register your startup to start posting opportunities for ALU students.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: () => context.push('/startup/register'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(220, 50)),
              child: const Text('Register Startup',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final StartupModel startup;
  const _DashboardHeader({required this.startup});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Welcome, ${startup.name} 👋',
            style: AppTextStyles.headlineLarge),
        const SizedBox(height: 8),
        if (startup.isApproved)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_rounded,
                    color: AppColors.success, size: 14),
                const SizedBox(width: 4),
                Text('ALU Verified Startup',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.success, fontWeight: FontWeight.w600)),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.hourglass_top_rounded,
                    color: AppColors.warning, size: 14),
                const SizedBox(width: 4),
                Text('Verification pending',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.warning, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  final StartupModel startup;
  const _StatsRow({required this.startup});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(
          label: 'Active Roles',
          value: '${startup.activeOpportunities}',
          icon: Icons.work_outline_rounded,
          color: AppColors.primary,
        ),
        const SizedBox(width: 12),
        _StatCard(
          label: 'Total Posted',
          value: '${startup.totalOpportunities}',
          icon: Icons.list_alt_rounded,
          color: AppColors.success,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: AppTextStyles.displayMedium.copyWith(color: color)),
                Text(label, style: AppTextStyles.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ApplicantCard extends StatelessWidget {
  final ApplicationModel application;

  const _ApplicantCard({required this.application});

  void _openDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ApplicantDetailSheet(application: application),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: InkWell(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              onTap: () => _openDetail(context),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.primaryLight,
                          child: Text(
                            application.applicantName.isNotEmpty
                                ? application.applicantName[0].toUpperCase()
                                : '?',
                            style: AppTextStyles.titleMedium
                                .copyWith(color: AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(application.applicantName,
                                  style: AppTextStyles.titleMedium),
                              Text(application.opportunityTitle,
                                  style: AppTextStyles.bodySmall),
                            ],
                          ),
                        ),
                        _StatusBadge(status: application.status),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right_rounded,
                            color: AppColors.textTertiary, size: 20),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.email_outlined,
                            size: 15, color: AppColors.textTertiary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            application.applicantEmail,
                            style: AppTextStyles.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (application.relevantSkills.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: application.relevantSkills
                            .map((s) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    s,
                                    style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.primary, fontSize: 11),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                    if (application.coverLetter.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 10),
                      Text(
                        application.coverLetter.length > 120
                            ? '${application.coverLetter.substring(0, 120)}...'
                            : application.coverLetter,
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                    if (application.portfolioUrl != null &&
                            application.portfolioUrl!.isNotEmpty ||
                        application.resumeUrl != null &&
                            application.resumeUrl!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 16,
                        children: [
                          if (application.portfolioUrl != null &&
                              application.portfolioUrl!.isNotEmpty)
                            _LinkChip(
                              icon: Icons.link_rounded,
                              label: 'Portfolio',
                              url: application.portfolioUrl!,
                            ),
                          if (application.resumeUrl != null &&
                              application.resumeUrl!.isNotEmpty)
                            _LinkChip(
                              icon: Icons.description_outlined,
                              label: 'Resume',
                              url: application.resumeUrl!,
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      'Tap to view full application',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textTertiary, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _ApplicantActionButtons(application: application),
          ),
        ],
      ),
    );
  }
}

class _ApplicantActionButtons extends StatelessWidget {
  final ApplicationModel application;

  const _ApplicantActionButtons({required this.application});

  Future<void> _reject(BuildContext context) async {
    final reason = await _showRejectionReasonDialog(context);
    if (reason == null || reason.trim().isEmpty) return;
    if (!context.mounted) return;
    await context.read<ApplicationCubit>().updateStatus(
          applicationId: application.id,
          status: 'rejected',
          rejectionReason: reason.trim(),
          applicantId: application.applicantId,
          startupName: application.startupName,
          opportunityTitle: application.opportunityTitle,
        );
  }

  Future<void> _updateStatus(BuildContext context, String status) {
    return context.read<ApplicationCubit>().updateStatus(
          applicationId: application.id,
          status: status,
        );
  }

  void _scheduleMeeting(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ScheduleMeetingSheet(application: application),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = application.status;

    if (status == 'pending' || status == 'under_review') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _updateStatus(context, 'shortlisted'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 38),
                foregroundColor: AppColors.success,
                side: const BorderSide(color: AppColors.success),
              ),
              child: const Text('Shortlist'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: () => _updateStatus(context, 'under_review'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 38),
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
              ),
              child: const Text('Review'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: () => _reject(context),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 38),
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
              ),
              child: const Text('Reject'),
            ),
          ),
        ],
      );
    }
    if (status == 'shortlisted') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => _updateStatus(context, 'accepted'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                minimumSize: const Size(0, 38),
              ),
              child: const Text('Accept', style: TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: () => _reject(context),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 38),
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
              ),
              child: const Text('Reject'),
            ),
          ),
        ],
      );
    }
    if (status == 'accepted') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _scheduleMeeting(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            minimumSize: const Size(0, 38),
          ),
          icon: const Icon(Icons.event_available_rounded,
              color: Colors.white, size: 18),
          label: Text(
            application.hasMeeting ? 'Update Meeting' : 'Schedule Meeting',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }
    return const SizedBox();
  }
}

// Shows a dialog asking for a required rejection reason. Returns the
// entered reason, or null if the startup cancelled.
Future<String?> _showRejectionReasonDialog(BuildContext context) {
  final controller = TextEditingController();
  final formKey = GlobalKey<FormState>();
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Reject application'),
      content: Form(
        key: formKey,
        child: TextFormField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Let the student know why (required)...',
            alignLabelWithHint: true,
          ),
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'A rejection reason is required' : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: () {
            if (formKey.currentState!.validate()) {
              Navigator.pop(context, controller.text);
            }
          },
          child: const Text('Reject', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

class _ScheduleMeetingSheet extends StatefulWidget {
  final ApplicationModel application;
  const _ScheduleMeetingSheet({required this.application});

  @override
  State<_ScheduleMeetingSheet> createState() => _ScheduleMeetingSheetState();
}

class _ScheduleMeetingSheetState extends State<_ScheduleMeetingSheet> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  DateTime? _date;
  TimeOfDay? _time;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final app = widget.application;
    _date = app.meetingDate;
    _locationController.text = app.meetingLocation ?? '';
    if (app.meetingTime != null) {
      _time = _parseTime(app.meetingTime!);
    }
  }

  TimeOfDay? _parseTime(String formatted) {
    // Best-effort parse of a previously formatted "h:mm AM/PM" string.
    try {
      final isPm = formatted.toUpperCase().contains('PM');
      final clean = formatted.toUpperCase().replaceAll(RegExp(r'[AP]M'), '').trim();
      final parts = clean.split(':');
      var hour = int.parse(parts[0].trim());
      final minute = int.parse(parts[1].trim());
      if (isPm && hour != 12) hour += 12;
      if (!isPm && hour == 12) hour = 0;
      return TimeOfDay(hour: hour, minute: minute);
    } catch (_) {
      return null;
    }
  }

  String _formatTime(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 10, minute: 0),
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_date == null || _time == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both a date and a time')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await context.read<ApplicationCubit>().scheduleMeeting(
            applicationId: widget.application.id,
            applicantId: widget.application.applicantId,
            meetingDate: _date!,
            meetingTime: _formatTime(_time!),
            meetingLocation: _locationController.text.trim(),
            startupName: widget.application.startupName,
            opportunityTitle: widget.application.opportunityTitle,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Meeting scheduled'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('Schedule Meeting', style: AppTextStyles.headlineLarge),
              const SizedBox(height: 4),
              Text('with ${widget.application.applicantName}',
                  style: AppTextStyles.bodyMedium),
              const SizedBox(height: 20),

              Text('Date', style: AppTextStyles.labelLarge),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
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
                        _date != null
                            ? '${_date!.day}/${_date!.month}/${_date!.year}'
                            : 'Select a date',
                        style: _date != null
                            ? AppTextStyles.bodyLarge
                            : AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text('Time', style: AppTextStyles.labelLarge),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickTime,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          color: AppColors.textSecondary, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        _time != null ? _formatTime(_time!) : 'Select a time',
                        style: _time != null
                            ? AppTextStyles.bodyLarge
                            : AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text('Location', style: AppTextStyles.labelLarge),
              const SizedBox(height: 8),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  hintText: 'e.g. ALU Campus, Room 204 or Google Meet link',
                  prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Location is required' : null,
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save Meeting',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ApplicantDetailSheet extends StatelessWidget {
  final ApplicationModel application;

  const _ApplicantDetailSheet({required this.application});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: AppColors.primaryLight,
                          child: Text(
                            application.applicantName.isNotEmpty
                                ? application.applicantName[0].toUpperCase()
                                : '?',
                            style: AppTextStyles.titleLarge
                                .copyWith(color: AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(application.applicantName,
                                  style: AppTextStyles.displayMedium),
                              const SizedBox(height: 2),
                              Text(application.applicantEmail,
                                  style: AppTextStyles.bodyMedium),
                            ],
                          ),
                        ),
                        _StatusBadge(status: application.status),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _DetailRow(
                      icon: Icons.work_outline_rounded,
                      label: 'Applied for',
                      value: application.opportunityTitle,
                    ),
                    _DetailRow(
                      icon: Icons.schedule_rounded,
                      label: 'Applied',
                      value: application.timeAgo,
                    ),
                    if (application.relevantSkills.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text('Skills', style: AppTextStyles.labelLarge),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: application.relevantSkills
                            .map((s) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    s,
                                    style: AppTextStyles.bodySmall
                                        .copyWith(color: AppColors.primary),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                    if (application.portfolioUrl != null &&
                            application.portfolioUrl!.isNotEmpty ||
                        application.resumeUrl != null &&
                            application.resumeUrl!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text('Links', style: AppTextStyles.labelLarge),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 20,
                        children: [
                          if (application.portfolioUrl != null &&
                              application.portfolioUrl!.isNotEmpty)
                            _LinkChip(
                              icon: Icons.link_rounded,
                              label: 'Portfolio',
                              url: application.portfolioUrl!,
                            ),
                          if (application.resumeUrl != null &&
                              application.resumeUrl!.isNotEmpty)
                            _LinkChip(
                              icon: Icons.description_outlined,
                              label: 'Resume',
                              url: application.resumeUrl!,
                            ),
                        ],
                      ),
                    ],
                    if (application.coverLetter.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text('Cover Letter', style: AppTextStyles.labelLarge),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          application.coverLetter,
                          style: AppTextStyles.bodyMedium,
                        ),
                      ),
                    ],
                    if (application.startupNote != null &&
                        application.startupNote!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text('Your Note', style: AppTextStyles.labelLarge),
                      const SizedBox(height: 8),
                      Text(application.startupNote!,
                          style: AppTextStyles.bodyMedium),
                    ],
                    if (application.hasMeeting) ...[
                      const SizedBox(height: 16),
                      Text('Scheduled Meeting', style: AppTextStyles.labelLarge),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _DetailRow(
                              icon: Icons.calendar_today_rounded,
                              label: 'Date',
                              value: application.meetingDate != null
                                  ? '${application.meetingDate!.day}/${application.meetingDate!.month}/${application.meetingDate!.year}'
                                  : '-',
                            ),
                            _DetailRow(
                              icon: Icons.access_time_rounded,
                              label: 'Time',
                              value: application.meetingTime ?? '-',
                            ),
                            _DetailRow(
                              icon: Icons.location_on_rounded,
                              label: 'Location',
                              value: application.meetingLocation ?? '-',
                            ),
                            _DetailRow(
                              icon: Icons.flag_rounded,
                              label: 'Status',
                              value: application.meetingStatusDisplay,
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    _ApplicantActionButtons(application: application),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: AppColors.textTertiary),
          const SizedBox(width: 10),
          Text('$label: ', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
          Expanded(
            child: Text(value, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _LinkChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String url;

  const _LinkChip({required this.icon, required this.label, required this.url});

  Future<void> _open() async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _open,
      borderRadius: BorderRadius.circular(20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  Color get _color {
    switch (status) {
      case 'under_review': return AppColors.warning;
      case 'shortlisted': return AppColors.success;
      case 'accepted': return AppColors.primary;
      case 'rejected': return AppColors.error;
      default: return AppColors.textTertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: AppTextStyles.bodySmall.copyWith(
          color: _color,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _OpportunityManageCard extends StatelessWidget {
  final OpportunityModel opportunity;
  final VoidCallback onClose;

  const _OpportunityManageCard({
    required this.opportunity,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(opportunity.title, style: AppTextStyles.titleMedium),
                const SizedBox(height: 4),
                Text(
                  '${opportunity.applicationCount} applicant${opportunity.applicationCount != 1 ? 's' : ''} · ${opportunity.type}',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          if (opportunity.isOpen)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () =>
                      context.push('/opportunity/${opportunity.id}/edit'),
                  child: const Text('Edit',
                      style: TextStyle(color: AppColors.primary, fontSize: 13)),
                ),
                TextButton(
                  onPressed: onClose,
                  child: const Text('Close',
                      style: TextStyle(color: AppColors.error, fontSize: 13)),
                ),
              ],
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () =>
                      context.push('/opportunity/${opportunity.id}/edit'),
                  child: const Text('Edit',
                      style: TextStyle(color: AppColors.primary, fontSize: 13)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.closed,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Closed',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.closedText)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}