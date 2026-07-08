import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../bloc/opportunity_cubit.dart';
import '../widgets/opportunity_card.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _searchController = TextEditingController();
  String? _selectedCategory;
  String? _selectedType;
  String? _selectedLocation;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    context.read<OpportunityCubit>().filterOpportunities(
          category: _selectedCategory,
          type: _selectedType,
          location: _selectedLocation,
          searchQuery: _searchController.text.trim(),
        );
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedType = null;
      _selectedLocation = null;
      _searchController.clear();
    });
    context.read<OpportunityCubit>().clearFilters();
  }

  bool get _hasFilters =>
      _selectedCategory != null ||
      _selectedType != null ||
      _selectedLocation != null ||
      _searchController.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  Text('Explore', style: AppTextStyles.displayMedium),
                  const Spacer(),
                  if (_hasFilters)
                    TextButton(
                      onPressed: _clearFilters,
                      child: Text('Clear all',
                          style: AppTextStyles.labelMedium
                              .copyWith(color: AppColors.error)),
                    ),
                ],
              ),
            ),

            // ── Search bar ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: TextFormField(
                controller: _searchController,
                onChanged: (_) => _applyFilters(),
                decoration: InputDecoration(
                  hintText: 'Search by role, skill, or startup...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _applyFilters();
                          },
                        )
                      : null,
                ),
              ),
            ),

            // ── Filter chips row ───────────────────────────────────────
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // Category
                  _FilterDropdown(
                    label: _selectedCategory ?? 'Category',
                    isActive: _selectedCategory != null,
                    items: AppConstants.categories,
                    onSelected: (v) {
                      setState(() => _selectedCategory = v);
                      _applyFilters();
                    },
                    onClear: () {
                      setState(() => _selectedCategory = null);
                      _applyFilters();
                    },
                  ),
                  const SizedBox(width: 8),
                  // Type
                  _FilterDropdown(
                    label: _selectedType ?? 'Type',
                    isActive: _selectedType != null,
                    items: const ['Part-time', 'Full-time', 'Volunteer', 'Project-based'],
                    onSelected: (v) {
                      setState(() => _selectedType = v);
                      _applyFilters();
                    },
                    onClear: () {
                      setState(() => _selectedType = null);
                      _applyFilters();
                    },
                  ),
                  const SizedBox(width: 8),
                  // Location
                  _FilterDropdown(
                    label: _selectedLocation ?? 'Location',
                    isActive: _selectedLocation != null,
                    items: const ['On-campus', 'Remote', 'Hybrid'],
                    onSelected: (v) {
                      setState(() => _selectedLocation = v);
                      _applyFilters();
                    },
                    onClear: () {
                      setState(() => _selectedLocation = null);
                      _applyFilters();
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Results ────────────────────────────────────────────────
            Expanded(
              child: BlocBuilder<OpportunityCubit, OpportunityState>(
                builder: (context, state) {
                  if (state is OpportunityLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is OpportunityError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.wifi_off_rounded,
                              size: 48, color: AppColors.textTertiary),
                          const SizedBox(height: 12),
                          Text(state.message, style: AppTextStyles.bodyMedium),
                        ],
                      ),
                    );
                  }
                  if (state is! OpportunitiesLoaded) {
                    return const SizedBox();
                  }

                  final opps = state.opportunities;

                  if (opps.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off_rounded,
                              size: 56, color: AppColors.textTertiary),
                          const SizedBox(height: 16),
                          Text('No opportunities found',
                              style: AppTextStyles.headlineMedium
                                  .copyWith(color: AppColors.textSecondary)),
                          const SizedBox(height: 8),
                          Text('Try adjusting your filters',
                              style: AppTextStyles.bodyMedium),
                        ],
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          '${opps.length} opportunit${opps.length == 1 ? 'y' : 'ies'} found',
                          style: AppTextStyles.bodySmall,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                          itemCount: opps.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, i) => OpportunityCard(
                            opportunity: opps[i],
                            isBookmarked:
                                state.bookmarkedIds.contains(opps[i].id),
                            onTap: () => context.push('/opportunity/${opps[i].id}'),
                            onBookmark: () => context
                                .read<OpportunityCubit>()
                                .toggleBookmark(opps[i].id),
                          ),
                        ),
                      ),
                    ],
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

class _FilterDropdown extends StatelessWidget {
  final String label;
  final bool isActive;
  final List<String> items;
  final ValueChanged<String> onSelected;
  final VoidCallback onClear;

  const _FilterDropdown({
    required this.label,
    required this.isActive,
    required this.items,
    required this.onSelected,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final result = await showModalBottomSheet<String>(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (ctx) => ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ...items.map(
                (item) => ListTile(
                  title: Text(item, style: AppTextStyles.titleMedium),
                  trailing: isActive && label == item
                      ? const Icon(Icons.check_rounded, color: AppColors.primary)
                      : null,
                  onTap: () => Navigator.pop(ctx, item),
                ),
              ),
            ],
          ),
        );
        if (result != null) onSelected(result);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTextStyles.labelLarge.copyWith(
                color: isActive ? Colors.white : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            if (isActive)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 15),
              )
            else
              const Icon(Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textSecondary, size: 18),
          ],
        ),
      ),
    );
  }
}
