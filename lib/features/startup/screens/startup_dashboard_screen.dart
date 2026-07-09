import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
            ],
          ),
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
          const SizedBox(height: 12),
          // Action buttons
          if (application.status == 'pending' ||
              application.status == 'under_review')
            Row(
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
              ],
            ),
          if (application.status == 'shortlisted')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => onUpdateStatus('accepted'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  minimumSize: const Size(0, 38),
                ),
                child: const Text('Accept',
                    style: TextStyle(color: Colors.white)),
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
