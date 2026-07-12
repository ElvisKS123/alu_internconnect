import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../bloc/opportunity_cubit.dart';
import '../models/opportunity_model.dart';
import '../repositories/opportunity_repository.dart';
import '../widgets/opportunity_card.dart';

class SavedOpportunitiesScreen extends StatefulWidget {
  const SavedOpportunitiesScreen({super.key});

  @override
  State<SavedOpportunitiesScreen> createState() =>
      _SavedOpportunitiesScreenState();
}

class _SavedOpportunitiesScreenState extends State<SavedOpportunitiesScreen> {
  List<OpportunityModel>? _saved;
  List<String> _lastFetchedIds = const [];
  bool _isLoading = true;

  Future<void> _loadFor(List<String> bookmarkedIds) async {
    // Avoid redundant refetches if the ID set hasn't actually changed.
    if (_lastFetchedIds.length == bookmarkedIds.length &&
        _lastFetchedIds.toSet().containsAll(bookmarkedIds)) {
      return;
    }
    _lastFetchedIds = bookmarkedIds;
    setState(() => _isLoading = true);
    final opportunities = await context
        .read<OpportunityRepository>()
        .getOpportunitiesByIds(bookmarkedIds);
    if (!mounted) return;
    setState(() {
      _saved = opportunities;
      _isLoading = false;
    });
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
        title: const Text('Saved Opportunities'),
      ),
      body: BlocConsumer<OpportunityCubit, OpportunityState>(
        listener: (context, state) {
          if (state is OpportunitiesLoaded) {
            _loadFor(state.bookmarkedIds);
          }
        },
        builder: (context, state) {
          if (state is! OpportunitiesLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.bookmarkedIds.isEmpty) {
            return _EmptyState();
          }
          if (_isLoading || _saved == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final saved = _saved!;
          if (saved.isEmpty) {
            return _EmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            itemCount: saved.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final opp = saved[i];
              return OpportunityCard(
                opportunity: opp,
                isBookmarked: true,
                onTap: () => context.push('/opportunity/${opp.id}'),
                onBookmark: () {
                  context.read<OpportunityCubit>().toggleBookmark(opp.id);
                  // Optimistically drop it from the local list so it
                  // disappears immediately instead of waiting for the
                  // bookmarks stream round-trip.
                  setState(() {
                    _saved = saved.where((o) => o.id != opp.id).toList();
                  });
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bookmark_outline_rounded,
                size: 56, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text('No saved opportunities yet',
                style: AppTextStyles.headlineMedium
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text(
              'Tap the bookmark icon on any opportunity to save it for later.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.go('/explore'),
              child: const Text('Explore Opportunities',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
