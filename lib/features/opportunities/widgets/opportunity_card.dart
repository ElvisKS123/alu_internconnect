import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/opportunity_model.dart';

class OpportunityCard extends StatelessWidget {
  final OpportunityModel opportunity;
  final bool isBookmarked;
  final VoidCallback onTap;
  final VoidCallback? onBookmark;

  const OpportunityCard({
    super.key,
    required this.opportunity,
    required this.isBookmarked,
    required this.onTap,
    this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
              child: opportunity.startupLogoUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        opportunity.startupLogoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _LogoPlaceholder(
                          name: opportunity.startupName,
                        ),
                      ),
                    )
                  : _LogoPlaceholder(name: opportunity.startupName),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    opportunity.title,
                    style: AppTextStyles.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    opportunity.startupName,
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _MetaChip(label: opportunity.type),
                      const SizedBox(width: 6),
                      const Icon(Icons.circle, size: 3, color: AppColors.textTertiary),
                      const SizedBox(width: 6),
                      Text(opportunity.location, style: AppTextStyles.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
            // Bookmark
            if (onBookmark != null)
              GestureDetector(
                onTap: onBookmark,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    isBookmarked
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_outline_rounded,
                    color: isBookmarked ? AppColors.primary : AppColors.textTertiary,
                    size: 22,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LogoPlaceholder extends StatelessWidget {
  final String name;
  const _LogoPlaceholder({required this.name});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: AppTextStyles.titleLarge.copyWith(color: AppColors.primary),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  const _MetaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary),
      ),
    );
  }
}
