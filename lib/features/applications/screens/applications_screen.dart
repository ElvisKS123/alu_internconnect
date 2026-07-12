import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/bloc/auth_cubit.dart';
import '../bloc/application_cubit.dart';
import '../models/application_model.dart';

class ApplicationsScreen extends StatefulWidget {
  const ApplicationsScreen({super.key});

  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> {
  final _filters = ['Applied', 'Interview', 'Accepted', 'All'];
  final _filterKeys = ['pending', 'shortlisted', 'accepted', 'all'];

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      context.read<ApplicationCubit>().loadStudentApplications(authState.user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Text('My Applications', style: AppTextStyles.displayMedium),
            ),

            // ── Filter tabs ───────────────────────────────────────────
            const SizedBox(height: 20),
            BlocBuilder<ApplicationCubit, ApplicationState>(
              builder: (context, state) {
                final currentFilter =
                    state is ApplicationsLoaded ? state.filter : 'all';
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: List.generate(_filters.length, (i) {
                      final isActive = currentFilter == _filterKeys[i];
                      return GestureDetector(
                        onTap: () => context
                            .read<ApplicationCubit>()
                            .setFilter(_filterKeys[i]),
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 8),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.primary
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isActive
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                          ),
                          child: Text(
                            _filters[i],
                            style: AppTextStyles.labelLarge.copyWith(
                              color: isActive
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // ── List ──────────────────────────────────────────────────
            Expanded(
              child: BlocBuilder<ApplicationCubit, ApplicationState>(
                builder: (context, state) {
                  if (state is ApplicationLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is ApplicationError) {
                    return Center(child: Text(state.message));
                  }
                  if (state is! ApplicationsLoaded) {
                    return const SizedBox();
                  }

                  final apps = state.filtered;

                  if (apps.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.folder_open_outlined,
                              size: 56, color: AppColors.textTertiary),
                          const SizedBox(height: 16),
                          Text(
                            'No applications here yet',
                            style: AppTextStyles.headlineMedium.copyWith(
                                color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Explore opportunities and apply!',
                            style: AppTextStyles.bodyMedium,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () => context.go('/explore'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(160, 48),
                            ),
                            child: const Text('Explore Now',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                    itemCount: apps.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) =>
                        _ApplicationCard(application: apps[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final ApplicationModel application;

  const _ApplicationCard({required this.application});

  Color get _statusColor {
    switch (application.status) {
      case 'under_review': return AppColors.underReview;
      case 'shortlisted': return AppColors.shortlisted;
      case 'accepted': return AppColors.success.withValues(alpha: 0.15);
      case 'rejected': return AppColors.closed;
      case 'closed': return AppColors.closed;
      default: return AppColors.surfaceVariant;
    }
  }

  Color get _statusTextColor {
    switch (application.status) {
      case 'under_review': return AppColors.underReviewText;
      case 'shortlisted': return AppColors.shortlistedText;
      case 'accepted': return AppColors.success;
      case 'rejected': return AppColors.closedText;
      case 'closed': return AppColors.closedText;
      default: return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => context.push('/application/${application.id}'),
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Logo
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                application.startupName.isNotEmpty
                    ? application.startupName[0].toUpperCase()
                    : '?',
                style: AppTextStyles.titleLarge.copyWith(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(application.opportunityTitle, style: AppTextStyles.titleMedium),
                const SizedBox(height: 2),
                Text(application.startupName, style: AppTextStyles.bodySmall),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Applied ${application.timeAgo}',
                      style: AppTextStyles.bodySmall,
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        application.statusDisplay,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: _statusTextColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded,
              size: 20, color: AppColors.textTertiary),
        ],
      ),
      ),
    );
  }
}
