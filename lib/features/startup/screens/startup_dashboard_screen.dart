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

    setState(() => _startup = startup);

    if (startup != null) {
      applicationCubit.loadStartupApplications(startup.id);
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
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: () => context.push('/opportunity/create'),
            tooltip: 'Post new opportunity',
          ),
        ],
      ),
      body: _startup == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [


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
                                  child: _ApplicantCard(
                                    application: app,
                                    onUpdateStatus: (status) async {
                                      await context
                                          .read<ApplicationCubit>()
                                          .updateStatus(
                                            applicationId: app.id,
                                            status: status,
                                          );
                                    },
                                  ),
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
  final ValueChanged<String> onUpdateStatus;

  const _ApplicantCard({
    required this.application,
    required this.onUpdateStatus,
  });

  void _openDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ApplicantDetailSheet(
        application: application,
        onUpdateStatus: onUpdateStatus,
      ),
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
            child: _ApplicantActionButtons(
              status: application.status,
              onUpdateStatus: onUpdateStatus,
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplicantActionButtons extends StatelessWidget {
  final String status;
  final ValueChanged<String> onUpdateStatus;

  const _ApplicantActionButtons({
    required this.status,
    required this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    if (status == 'pending' || status == 'under_review') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => onUpdateStatus('shortlisted'),
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
              onPressed: () => onUpdateStatus('under_review'),
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
              onPressed: () => onUpdateStatus('rejected'),
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
              onPressed: () => onUpdateStatus('accepted'),
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
              onPressed: () => onUpdateStatus('rejected'),
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
    return const SizedBox();
  }
}

class _ApplicantDetailSheet extends StatelessWidget {
  final ApplicationModel application;
  final ValueChanged<String> onUpdateStatus;

  const _ApplicantDetailSheet({
    required this.application,
    required this.onUpdateStatus,
  });

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
                    const SizedBox(height: 24),
                    _ApplicantActionButtons(
                      status: application.status,
                      onUpdateStatus: (status) {
                        onUpdateStatus(status);
                        Navigator.of(context).pop();
                      },
                    ),
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
            TextButton(
              onPressed: onClose,
              child: const Text('Close',
                  style: TextStyle(color: AppColors.error, fontSize: 13)),
            )
          else
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
    );
  }
}