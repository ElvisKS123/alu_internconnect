import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/bloc/auth_cubit.dart';
import '../../opportunities/bloc/opportunity_cubit.dart';
import '../models/opportunity_model.dart';
import '../repositories/opportunity_repository.dart';
import '../../applications/repositories/application_repository.dart';

class OpportunityDetailScreen extends StatefulWidget {
  final String opportunityId;

  const OpportunityDetailScreen({super.key, required this.opportunityId});

  @override
  State<OpportunityDetailScreen> createState() => _OpportunityDetailScreenState();
}

class _OpportunityDetailScreenState extends State<OpportunityDetailScreen> {
  OpportunityModel? _opportunity;
  bool _isLoading = true;
  bool _hasApplied = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final opportunityRepository = context.read<OpportunityRepository>();
    final applicationRepository = context.read<ApplicationRepository>();
    final authState = context.read<AuthCubit>().state;

    final opp = await opportunityRepository.getOpportunityById(widget.opportunityId);

    bool hasApplied = false;
    if (authState is AuthAuthenticated && authState.user.isStudent) {
      hasApplied = await applicationRepository.hasApplied(
        studentId: authState.user.id,
        opportunityId: widget.opportunityId,
      );
    }

    if (!mounted) return;

    setState(() {
      _opportunity = opp;
      _hasApplied = hasApplied;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_opportunity == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Opportunity not found.')),
      );
    }

    final opp = _opportunity!;
    final authState = context.watch<AuthCubit>().state;
    final isStudent =
        authState is AuthAuthenticated && authState.user.isStudent;

    final oppState = context.watch<OpportunityCubit>().state;
    final isBookmarked = oppState is OpportunitiesLoaded &&
        oppState.bookmarkedIds.contains(opp.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── App bar ───
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.background,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded),
              onPressed: () => context.pop(),
            ),
            title: Text('Opportunity Details', style: AppTextStyles.headlineMedium),
            actions: [
              IconButton(
                icon: const Icon(Icons.ios_share_rounded),
                onPressed: () {},
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header card ───
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                child: Text(
                                  opp.startupName.isNotEmpty
                                      ? opp.startupName[0].toUpperCase()
                                      : '?',
                                  style: AppTextStyles.headlineLarge
                                      .copyWith(color: AppColors.primary),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(opp.title, style: AppTextStyles.headlineMedium),
                                  const SizedBox(height: 2),
                                  GestureDetector(
                                    onTap: () =>
                                        context.push('/startup/${opp.startupId}'),
                                    child: Text(
                                      opp.startupName,
                                      style: AppTextStyles.bodyMedium.copyWith(
                                          color: AppColors.primary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        // Skill tags
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: opp.tags.map((t) => _Tag(label: t)).toList(),
                        ),
                        const SizedBox(height: 16),
                        // Meta info
                        _MetaRow(
                          icon: Icons.access_time_outlined,
                          text: opp.hoursPerWeek != null
                              ? '${opp.type} (${opp.hoursPerWeek} hrs/week)'
                              : opp.type,
                        ),
                        const SizedBox(height: 8),
                        _MetaRow(
                          icon: Icons.location_on_outlined,
                          text: opp.location,
                        ),
                        const SizedBox(height: 8),
                        _MetaRow(
                          icon: Icons.calendar_today_outlined,
                          text: 'Posted ${opp.timeAgo}',
                        ),
                        if (opp.deadline != null) ...[
                          const SizedBox(height: 8),
                          _MetaRow(
                            icon: Icons.timer_outlined,
                            text:
                                'Deadline: ${_formatDate(opp.deadline!)}',
                            color: AppColors.warning,
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── About ──
                  Text('About', style: AppTextStyles.headlineMedium),
                  const SizedBox(height: 10),
                  Text(opp.description, style: AppTextStyles.bodyLarge.copyWith(height: 1.6)),

                  const SizedBox(height: 24),

                  // ── Skills required ──
                  if (opp.skills.isNotEmpty) ...[
                    Text('Skills required', style: AppTextStyles.headlineMedium),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: opp.skills.map((s) => _SkillChip(label: s)).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ── Application count ──
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.people_outline_rounded,
                            color: AppColors.primary, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          '${opp.applicationCount} student${opp.applicationCount != 1 ? 's' : ''} applied',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.primary),
                        ),
                        const Spacer(),
                        if (opp.isPaid) ...[
                          const Icon(Icons.attach_money_rounded,
                              color: AppColors.success, size: 18),
                          Text('Paid', style: AppTextStyles.labelMedium
                              .copyWith(color: AppColors.success)),
                        ] else
                          Text('Volunteer', style: AppTextStyles.labelMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Bottom CTA ───
      bottomNavigationBar: isStudent
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Row(
                  children: [
                    // Bookmark
                    GestureDetector(
                      onTap: () => context
                          .read<OpportunityCubit>()
                          .toggleBookmark(opp.id),
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Icon(
                          isBookmarked
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_outline_rounded,
                          color: isBookmarked
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _hasApplied || !opp.isOpen
                            ? null
                            : () => context
                                .push('/opportunity/${opp.id}/apply'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _hasApplied
                              ? AppColors.success
                              : AppColors.primary,
                          disabledBackgroundColor: _hasApplied
                              ? AppColors.success
                              : AppColors.textTertiary,
                        ),
                        child: Text(
                          _hasApplied
                              ? '✓ Applied'
                              : opp.isOpen
                                  ? 'Apply Now'
                                  : 'Closed',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _Tag extends StatelessWidget {
  final String label;
  const _Tag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: AppTextStyles.labelMedium),
    );
  }
}

class _SkillChip extends StatelessWidget {
  final String label;
  const _SkillChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;

  const _MetaRow({required this.icon, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          text,
          style: AppTextStyles.bodyMedium.copyWith(color: color),
        ),
      ],
    );
  }
}
