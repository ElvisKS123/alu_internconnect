import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/bloc/auth_cubit.dart';
import '../../opportunities/bloc/opportunity_cubit.dart';
import '../../opportunities/widgets/opportunity_card.dart';
import '../../opportunities/widgets/recommended_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      context.read<OpportunityCubit>().init(
            userId: authState.user.id,
            userSkills: authState.user.skills,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) {
            if (authState is! AuthAuthenticated) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            final user = authState.user;

            return CustomScrollView(
              slivers: [
                // ── Header ──────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello, ${user.firstName} 👋',
                                style: AppTextStyles.displayLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user.isStartup
                                    ? 'Manage your opportunities.'
                                    : 'Find meaningful ways to contribute.',
                                style: AppTextStyles.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        Stack(
                          children: [
                            GestureDetector(
                              onTap: () => context.go('/profile'),
                              child: CircleAvatar(
                                radius: 22,
                                backgroundColor: AppColors.primaryLight,
                                backgroundImage: user.photoUrl != null
                                    ? NetworkImage(user.photoUrl!)
                                    : null,
                                child: user.photoUrl == null
                                    ? Text(
                                        user.firstName[0].toUpperCase(),
                                        style: AppTextStyles.titleLarge
                                            .copyWith(color: AppColors.primary),
                                      )
                                    : null,
                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: AppColors.error,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.background,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Search bar ───────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: GestureDetector(
                      onTap: () => context.go('/explore'),
                      child: Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search, color: AppColors.textTertiary, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              'Search opportunities...',
                              style: AppTextStyles.bodyMedium,
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.tune_rounded,
                                color: AppColors.primary,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Startup: quick actions ───────────────────────────────────
                if (user.isStartup)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: _StartupQuickActions(),
                    ),
                  ),

                // ── Recommended ──────────────────────────────────────────────
                if (!user.isStartup)
                  BlocBuilder<OpportunityCubit, OpportunityState>(
                    builder: (context, state) {
                      if (state is! OpportunitiesLoaded) return const SliverToBoxAdapter(child: SizedBox());
                      if (state.recommended.isEmpty) return const SliverToBoxAdapter(child: SizedBox());

                      return SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Recommended', style: AppTextStyles.headlineMedium),
                                  GestureDetector(
                                    onTap: () => context.go('/explore'),
                                    child: Text(
                                      'See all',
                                      style: AppTextStyles.labelMedium
                                          .copyWith(color: AppColors.primary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 180,
                              child: ListView.separated(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                scrollDirection: Axis.horizontal,
                                itemCount: state.recommended.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 12),
                                itemBuilder: (context, i) => RecommendedCard(
                                  opportunity: state.recommended[i],
                                  isBookmarked: state.bookmarkedIds
                                      .contains(state.recommended[i].id),
                                  onTap: () => context
                                      .push('/opportunity/${state.recommended[i].id}'),
                                  onBookmark: () => context
                                      .read<OpportunityCubit>()
                                      .toggleBookmark(state.recommended[i].id),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                // ── Browse by category ───────────────────────────────────────
                if (!user.isStartup)
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
                          child: Text('Browse by category', style: AppTextStyles.headlineMedium),
                        ),
                        SizedBox(
                          height: 90,
                          child: ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            scrollDirection: Axis.horizontal,
                            children: [
                              _CategoryChip(
                                label: 'Design',
                                icon: Icons.palette_outlined,
                                onTap: () {
                                  context.read<OpportunityCubit>().filterOpportunities(category: 'Design');
                                  context.go('/explore');
                                },
                              ),
                              _CategoryChip(
                                label: 'Engineering',
                                icon: Icons.code_rounded,
                                onTap: () {
                                  context.read<OpportunityCubit>().filterOpportunities(category: 'Engineering');
                                  context.go('/explore');
                                },
                              ),
                              _CategoryChip(
                                label: 'Marketing',
                                icon: Icons.campaign_outlined,
                                onTap: () {
                                  context.read<OpportunityCubit>().filterOpportunities(category: 'Marketing');
                                  context.go('/explore');
                                },
                              ),
                              _CategoryChip(
                                label: 'Data',
                                icon: Icons.bar_chart_rounded,
                                onTap: () {
                                  context.read<OpportunityCubit>().filterOpportunities(category: 'Data');
                                  context.go('/explore');
                                },
                              ),
                              _CategoryChip(
                                label: 'Other',
                                icon: Icons.more_horiz_rounded,
                                onTap: () => context.go('/explore'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // ── Recent opportunities ─────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
                    child: Text(
                      user.isStartup ? 'Your Opportunities' : 'Recent opportunities',
                      style: AppTextStyles.headlineMedium,
                    ),
                  ),
                ),

                BlocBuilder<OpportunityCubit, OpportunityState>(
                  builder: (context, state) {
                    if (state is OpportunityLoading) {
                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, __) => const _SkeletonCard(),
                          childCount: 3,
                        ),
                      );
                    }
                    if (state is! OpportunitiesLoaded) {
                      return const SliverToBoxAdapter(child: SizedBox());
                    }

                    final opportunities = state.opportunities.take(5).toList();
                    if (opportunities.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            children: [
                              const Icon(Icons.inbox_outlined,
                                  size: 48, color: AppColors.textTertiary),
                              const SizedBox(height: 12),
                              Text('No opportunities yet',
                                  style: AppTextStyles.bodyMedium),
                            ],
                          ),
                        ),
                      );
                    }

                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: OpportunityCard(
                              opportunity: opportunities[i],
                              isBookmarked: state.bookmarkedIds
                                  .contains(opportunities[i].id),
                              onTap: () => context
                                  .push('/opportunity/${opportunities[i].id}'),
                              onBookmark: () => context
                                  .read<OpportunityCubit>()
                                  .toggleBookmark(opportunities[i].id),
                            ),
                          ),
                          childCount: opportunities.length,
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StartupQuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            icon: Icons.add_circle_outline_rounded,
            label: 'Post Opportunity',
            color: AppColors.primary,
            onTap: () => context.push('/opportunity/create'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionCard(
            icon: Icons.people_outline_rounded,
            label: 'View Applications',
            color: AppColors.success,
            onTap: () => context.push('/startup/dashboard'),
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.labelLarge.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 76,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(height: 6),
            Text(label, style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      height: 90,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
    );
  }
}
