import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'visits_tab.dart';
import 'jrf/jrf_form_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('All Modules'),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            // Text(
            //   'Manage HR Modules',
            //   style: AppTheme.headingMD.copyWith(color: AppTheme.primary),
            // ),
            // const SizedBox(height: 6),
            // Text(
            //   'Access client visits, job requisitions, and core human resource processes.',
            //   style: AppTheme.bodyMD,
            // ),
            // const SizedBox(height: 28),

            // Active Modules Section
            // AppTheme.sectionHeader('Active Modules'),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
              children: [
                _buildModuleCard(
                  context,
                  title: 'Client Visits',
                  description:
                      'Track and manage external client meetings and routes.',
                  icon: Icons.directions_run_rounded,
                  iconColor: AppTheme.accent,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const VisitsTab()),
                    );
                  },
                ),
                _buildModuleCard(
                  context,
                  title: 'Job Requisitions',
                  description: 'Create and submit Job Requisition Forms (JRF).',
                  icon: Icons.assignment_ind_rounded,
                  iconColor: AppTheme.success,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const JrfFormScreen()),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Future/Locked Modules Section
            // AppTheme.sectionHeader('Planned Modules'),
            // GridView.count(
            //   crossAxisCount: 2,
            //   shrinkWrap: true,
            //   physics: const NeverScrollableScrollPhysics(),
            //   crossAxisSpacing: 16,
            //   mainAxisSpacing: 16,
            //   childAspectRatio: 0.85,
            //   children: [
            //     _buildModuleCard(
            //       context,
            //       title: 'Reimbursements',
            //       description:
            //           'Claim travel, food, and miscellaneous work expenses.',
            //       icon: Icons.receipt_long_rounded,
            //       iconColor: AppTheme.textTertiary,
            //       isLocked: true,
            //     ),
            //     _buildModuleCard(
            //       context,
            //       title: 'Performance',
            //       description:
            //           'Track objectives, key results, and annual appraisals.',
            //       icon: Icons.analytics_rounded,
            //       iconColor: AppTheme.textTertiary,
            //       isLocked: true,
            //     ),
            //     _buildModuleCard(
            //       context,
            //       title: 'Training & Development',
            //       description:
            //           'Access learning courses and certification programs.',
            //       icon: Icons.school_rounded,
            //       iconColor: AppTheme.textTertiary,
            //       isLocked: true,
            //     ),
            //   ],
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    VoidCallback? onTap,
    bool isLocked = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.radiusXL,
        boxShadow: AppTheme.cardShadow,
        border: Border.all(
          color: isLocked
              ? AppTheme.border.withValues(alpha: 0.5)
              : AppTheme.border,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppTheme.radiusXL,
        child: InkWell(
          onTap: isLocked ? null : onTap,
          borderRadius: AppTheme.radiusXL,
          splashColor: iconColor.withValues(alpha: 0.05),
          highlightColor: iconColor.withValues(alpha: 0.02),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppTheme.iconContainer(
                      icon: icon,
                      color: isLocked ? AppTheme.textTertiary : iconColor,
                      padding: 12,
                      size: 24,
                    ),
                    if (isLocked)
                      Icon(
                        CupertinoIcons.lock_fill,
                        size: 16,
                        color: AppTheme.textTertiary.withValues(alpha: 0.7),
                      )
                    else
                      const Icon(
                        CupertinoIcons.arrow_right_circle_fill,
                        size: 20,
                        color: AppTheme.accent,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.headingSM.copyWith(
                        color: isLocked
                            ? AppTheme.textSecondary
                            : AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: AppTheme.bodySM.copyWith(
                        color: AppTheme.textSecondary.withValues(alpha: 0.8),
                        height: 1.3,
                        fontSize: 11.5,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
