import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/bloc/auth_cubit.dart';
import '../../applications/bloc/application_cubit.dart';
import '../../startup/repositories/startup_repository.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) return const SizedBox();
        final user = authState.user;

        final appState = context.watch<ApplicationCubit>().state;
        final totalApps = appState is ApplicationsLoaded
            ? appState.applications.length
            : 0;
        final shortlisted = appState is ApplicationsLoaded
            ? appState.applications
                .where((a) => a.status == 'shortlisted')
                .length
            : 0;
        final accepted = appState is ApplicationsLoaded
            ? appState.applications
                .where((a) => a.status == 'accepted')
                .length
            : 0;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              child: Column(
                children: [
                  // ── Header ───
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Spacer(),
                      Text('Profile', style: AppTextStyles.headlineMedium),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined),
                        onPressed: () => context.push('/profile/edit'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Avatar ───
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: AppColors.primaryLight,
                    backgroundImage: user.photoUrl != null
                        ? NetworkImage(user.photoUrl!)
                        : null,
                    child: user.photoUrl == null
                        ? Text(
                            user.firstName[0].toUpperCase(),
                            style: AppTextStyles.displayLarge
                                .copyWith(color: AppColors.primary),
                          )
                        : null,
                  ),

                  const SizedBox(height: 14),
                  Text(user.fullName, style: AppTextStyles.headlineLarge),
                  const SizedBox(height: 4),
                  Text(
                    user.location ?? 'Kigali, Rwanda',
                    style: AppTextStyles.bodyMedium,
                  ),

                  const SizedBox(height: 20),

                  // ── Stats ───
                  if (user.isStudent)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          _Stat(count: totalApps, label: 'Applications'),
                          _Divider(),
                          _Stat(count: shortlisted, label: 'Shortlisted'),
                          _Divider(),
                          _Stat(count: accepted, label: 'Accepted'),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // ── Menu items ───
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        if (user.isStartup) ...[
                          _MenuItem(
                            icon: Icons.business_outlined,
                            label: 'Edit Startup Information',
                            onTap: () async {
                              final startup = await context
                                  .read<StartupRepository>()
                                  .getStartupById(user.id);
                              if (!context.mounted) return;
                              if (startup == null) {
                                context.push('/startup/register');
                              } else {
                                context.push('/startup/edit');
                              }
                            },
                          ),
                          _Separator(),
                          _MenuItem(
                            icon: Icons.person_outline_rounded,
                            label: 'Account Details',
                            onTap: () => context.push('/profile/edit'),
                          ),
                        ] else ...[
                          _MenuItem(
                            icon: Icons.person_outline_rounded,
                            label: 'My Profile',
                            onTap: () => context.push('/profile/edit'),
                          ),
                          _Separator(),
                          _MenuItem(
                            icon: Icons.star_outline_rounded,
                            label: 'Skills & Interests',
                            onTap: () => context.push('/profile/edit'),
                          ),
                          _Separator(),
                          _MenuItem(
                            icon: Icons.bookmark_outline_rounded,
                            label: 'Saved Opportunities',
                            onTap: () => context.push('/saved'),
                          ),
                        ],
                        _Separator(),
                        _MenuItem(
                          icon: Icons.notifications_none_rounded,
                          label: 'Notifications',
                          onTap: () => context.push('/notifications'),
                        ),
                        _Separator(),
                        _MenuItem(
                          icon: Icons.help_outline_rounded,
                          label: 'Help & Support',
                          onTap: () {},
                        ),
                        _Separator(),
                        _MenuItem(
                          icon: Icons.logout_rounded,
                          label: 'Logout',
                          labelColor: AppColors.error,
                          iconColor: AppColors.error,
                          onTap: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text('Log out?',
                                    style: AppTextStyles.headlineMedium),
                                content: Text(
                                    'You will be redirected to the login screen.',
                                    style: AppTextStyles.bodyMedium),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(ctx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(ctx, true),
                                    child: const Text('Log out',
                                        style: TextStyle(
                                            color: AppColors.error)),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true && context.mounted) {
                              context.read<AuthCubit>().signOut();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  final int count;
  final String label;
  const _Stat({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text('$count', style: AppTextStyles.displayMedium),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 36,
        color: AppColors.border,
      );
}

class _Separator extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Divider(
        height: 1,
        indent: 20,
        endIndent: 20,
      );
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? labelColor;
  final Color? iconColor;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.labelColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon,
          color: iconColor ?? AppColors.textSecondary, size: 22),
      title: Text(
        label,
        style: AppTextStyles.titleMedium.copyWith(color: labelColor),
      ),
      trailing: labelColor == null
          ? const Icon(Icons.chevron_right_rounded,
              color: AppColors.textTertiary)
          : null,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    );
  }
}
