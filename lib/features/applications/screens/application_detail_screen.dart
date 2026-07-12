import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../models/application_model.dart';
import '../repositories/application_repository.dart';

class ApplicationDetailScreen extends StatelessWidget {
  final String applicationId;

  const ApplicationDetailScreen({super.key, required this.applicationId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Application Details'),
      ),
      body: StreamBuilder<ApplicationModel?>(
        stream: context
            .read<ApplicationRepository>()
            .watchApplicationById(applicationId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final application = snapshot.data;
          if (application == null) {
            return const Center(child: Text('Application not found.'));
          }
          return _ApplicationDetailBody(application: application);
        },
      ),
    );
  }
}

class _ApplicationDetailBody extends StatelessWidget {
  final ApplicationModel application;
  const _ApplicationDetailBody({required this.application});

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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header card: company + role + status ────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.cardGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          application.startupName.isNotEmpty
                              ? application.startupName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(application.opportunityTitle,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          // Company name, front and center per the request.
                          Text(application.startupName,
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    application.statusDisplay,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Key details ───────────────────────────────────────────────
          _SectionCard(
            title: 'Application Details',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow(
                  icon: Icons.business_rounded,
                  label: 'Company',
                  value: application.startupName,
                ),
                _DetailRow(
                  icon: Icons.attach_money_rounded,
                  label: 'Paid Amount',
                  value: application.compensationDisplay,
                ),
                _DetailRow(
                  icon: Icons.schedule_rounded,
                  label: 'Applied',
                  value: application.timeAgo,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.flag_rounded,
                          size: 17, color: AppColors.textTertiary),
                      const SizedBox(width: 10),
                      Text('Status: ',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.textSecondary)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: _statusColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          application.statusDisplay,
                          style: AppTextStyles.bodySmall.copyWith(
                              color: _statusTextColor,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Rejection reason ─────────────────────────────────────────
          if (application.status == 'rejected') ...[
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Rejection Reason',
              titleColor: AppColors.error,
              child: Text(
                application.rejectionReason?.isNotEmpty == true
                    ? application.rejectionReason!
                    : 'No reason was provided by the startup.',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
              ),
            ),
          ],

          // ── Meeting details ───────────────────────────────────────────
          if (application.hasMeeting) ...[
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Scheduled Meeting',
              titleColor: AppColors.primary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailRow(
                    icon: Icons.business_rounded,
                    label: 'Company',
                    value: application.startupName,
                  ),
                  _DetailRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Date',
                    value: application.meetingDate != null
                        ? _formatDate(application.meetingDate!)
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
                    label: 'Meeting Status',
                    value: application.meetingStatusDisplay,
                  ),
                ],
              ),
            ),
          ],

          // ── Cover letter ──────────────────────────────────────────────
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Cover Letter',
            child: Text(application.coverLetter,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary)),
          ),

          if (application.relevantSkills.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Relevant Skills',
              child: Wrap(
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
                          child: Text(s,
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.primary)),
                        ))
                    .toList(),
              ),
            ),
          ],

          if ((application.portfolioUrl?.isNotEmpty ?? false) ||
              (application.resumeUrl?.isNotEmpty ?? false)) ...[
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Links',
              child: Wrap(
                spacing: 20,
                children: [
                  if (application.portfolioUrl?.isNotEmpty ?? false)
                    _LinkChip(label: 'Portfolio', url: application.portfolioUrl!),
                  if (application.resumeUrl?.isNotEmpty ?? false)
                    _LinkChip(label: 'Resume', url: application.resumeUrl!),
                ],
              ),
            ),
          ],

          if (application.startupNote?.isNotEmpty ?? false) ...[
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Note from Startup',
              child: Text(application.startupNote!,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary)),
            ),
          ],

          // ── Edit button ───────────────────────────────────────────────
          if (application.isEditable) ...[
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => context.push(
                '/opportunity/${application.opportunityId}/apply?applicationId=${application.id}',
              ),
              icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
              label: const Text('Edit Application',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        ],
      ),
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

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Color? titleColor;

  const _SectionCard({required this.title, required this.child, this.titleColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppTextStyles.labelLarge.copyWith(color: titleColor)),
          const SizedBox(height: 10),
          child,
        ],
      ),
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
      padding: const EdgeInsets.only(top: 6, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: AppColors.textTertiary),
          const SizedBox(width: 10),
          Text('$label: ',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
          Expanded(
            child: Text(value,
                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _LinkChip extends StatelessWidget {
  final String label;
  final String url;

  const _LinkChip({required this.label, required this.url});

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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.link_rounded, size: 15, color: AppColors.primary),
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
