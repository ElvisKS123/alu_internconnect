import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../models/startup_model.dart';
import '../repositories/startup_repository.dart';
import '../../opportunities/repositories/opportunity_repository.dart';
import '../../opportunities/models/opportunity_model.dart';
import '../../opportunities/widgets/opportunity_card.dart';

class StartupProfileScreen extends StatefulWidget {
  final String startupId;
  const StartupProfileScreen({super.key, required this.startupId});

  @override
  State<StartupProfileScreen> createState() => _StartupProfileScreenState();
}

class _StartupProfileScreenState extends State<StartupProfileScreen> {
  StartupModel? _startup;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final startup = await context.read<StartupRepository>().getStartupById(widget.startupId);

    if (!mounted) return;

    setState(() {
      _startup = startup;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_startup == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Startup not found.')),
      );
    }

    final s = _startup!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Banner + header
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AppColors.background,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: AppColors.cardGradient),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            s.name.isNotEmpty ? s.name[0].toUpperCase() : '?',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + verification badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(s.name, style: AppTextStyles.displayMedium),
                      ),
                      if (s.isApproved)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
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
                              Text('Verified ALU',
                                  style: AppTextStyles.bodySmall
                                      .copyWith(color: AppColors.success)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(s.tagline, style: AppTextStyles.bodyMedium),

                  const SizedBox(height: 16),

                  // Stats row
                  Row(
                    children: [
                      _StatChip(
                          icon: Icons.people_outline_rounded,
                          label: '${s.teamSize} team members'),
                      const SizedBox(width: 12),
                      _StatChip(
                          icon: Icons.work_outline_rounded,
                          label: '${s.activeOpportunities} open roles'),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Category tag
                  Chip(
                    label: Text(s.category),
                    backgroundColor: AppColors.primaryLight,
                    labelStyle: AppTextStyles.labelMedium
                        .copyWith(color: AppColors.primary),
                  ),

                  const SizedBox(height: 20),

                  // About
                  Text('About', style: AppTextStyles.headlineMedium),
                  const SizedBox(height: 10),
                  Text(s.description,
                      style: AppTextStyles.bodyLarge.copyWith(height: 1.6)),

                  // Links
                  if (s.websiteUrl != null || s.linkedinUrl != null) ...[
                    const SizedBox(height: 20),
                    Text('Links', style: AppTextStyles.headlineMedium),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      children: [
                        if (s.websiteUrl != null)
                          const _LinkChip(
                              icon: Icons.language_rounded,
                              label: 'Website'),
                        if (s.linkedinUrl != null)
                          const _LinkChip(
                              icon: Icons.link_rounded,
                              label: 'LinkedIn'),
                      ],
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Open opportunities
                  Text('Open Opportunities',
                      style: AppTextStyles.headlineMedium),
                  const SizedBox(height: 14),

                  StreamBuilder<List<OpportunityModel>>(
                    stream: context
                        .read<OpportunityRepository>()
                        .watchStartupOpportunities(widget.startupId),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      final opps = snapshot.data!
                          .where((o) => o.isOpen)
                          .toList();
                      if (opps.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Center(
                            child: Text(
                              'No open opportunities right now.',
                              style: AppTextStyles.bodyMedium,
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: opps
                            .map((opp) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: OpportunityCard(
                                    opportunity: opp,
                                    isBookmarked: false,
                                    onTap: () => context
                                        .push('/opportunity/${opp.id}'),
                                  ),
                                ))
                            .toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(label, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

class _LinkChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _LinkChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(label,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary)),
        ],
      ),
    );
  }
}
