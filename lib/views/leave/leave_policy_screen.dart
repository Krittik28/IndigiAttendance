import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class LeavePolicyScreen extends StatelessWidget {
  const LeavePolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Leave Policy 2026'),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Leave Types for Confirmed Employees'),
            const SizedBox(height: 12),
            _buildPolicyCard(
              title: 'Casual Leave (CL)',
              subtitle: 'Short term planned leaves',
              icon: Icons.event_note_rounded,
              color: const Color(0xFF3D5AFE),
              content: [
                '7 days per calendar year.',
                'Normally, not more than 2 consecutive days.',
                'Cannot be carried forward or encashed.',
                'Requires Reporting Manager approval.',
              ],
            ),
            _buildPolicyCard(
              title: 'Sick Leave (SL)',
              subtitle: 'Medical emergencies & illness',
              icon: Icons.local_hospital_rounded,
              color: const Color(0xFFE53935),
              content: [
                '7 days per calendar year.',
                'Applicable for illness or medical emergencies.',
                'Medical certificate mandatory for 3 or more consecutive days.',
                'Cannot be encashed.',
              ],
            ),
            _buildPolicyCard(
              title: 'Earned Leave (EL)',
              subtitle: 'Planned vacations & long-term leaves',
              icon: Icons.verified_user_rounded,
              color: const Color(0xFF2E7D32),
              content: [
                'Entitlement: 18 days per calendar year (accrued at 1.5 days per month).',
                'Intended strictly for planned or long-duration leave.',
                'Must be applied at least 14 calendar days in advance through HRMS.',
                'Minimum EL availed at a time: 3 consecutive days.',
                'Requests for less than 3 days will not be permitted.',
                'Short-duration leave will be adjusted against CL or SL.',
                'Carry forward limited to 5 days to the next calendar year.',
                'EL is not encashable during the year unless approved by Management.',
                'EL cannot be merged or combined with CL or SL under any circumstances.',
                'EL must be applied separately and independently.',
                'Late arrival or early departure adjustment against EL is strictly prohibited.',
                'EL cannot be used for attendance regularization.',
                'Any attempt to merge EL with CL or SL shall be rejected or reclassified.',
              ],
            ),
            const SizedBox(height: 28),
            _buildSectionHeader('Probation Employees'),
            const SizedBox(height: 12),
            _buildPolicyCard(
              title: 'Probation Leave Rules',
              subtitle: 'Leaves during probation period',
              icon: Icons.timer_rounded,
              color: const Color(0xFFF57C00),
              content: [
                '1 day leave per completed month of service.',
                'Leave can be used as Casual Leave or Sick Leave.',
                'Earned Leave (EL) is not applicable during probation.',
                'Leave cannot be carried forward or encashed.',
              ],
            ),
            const SizedBox(height: 28),
            _buildSectionHeader('Other Policies'),
            const SizedBox(height: 12),
            _buildPolicyCard(
              title: 'Compensatory Off (Comp-Off)',
              subtitle: 'For weekend & holiday duties',
              icon: Icons.work_history_rounded,
              color: const Color(0xFF5E35B1),
              content: [
                'Applicable when working on a weekly off or declared holiday due to business needs.',
                'Requires Reporting Manager approval.',
                'Must be availed within 30 days, failing which it will lapse.',
                'Comp-Off is not encashable.',
              ],
            ),
            _buildPolicyCard(
              title: 'Holidays',
              subtitle: 'Base location list & schedule',
              icon: Icons.calendar_month_rounded,
              color: const Color(0xFF00897B),
              content: [
                'National & Festival Holiday List will be circulated separately.',
                'Employees must follow the holiday list applicable to their base location.',
              ],
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.textTertiary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildPolicyCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<String> content,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.radiusLG,
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: AppTheme.border, width: 1),
      ),
      child: Theme(
        data: ThemeData(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: AppTheme.radiusMD,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
              fontSize: 14,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(
              color: AppTheme.textTertiary,
              fontSize: 11,
            ),
          ),
          iconColor: AppTheme.textSecondary,
          collapsedIconColor: AppTheme.textTertiary,
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedAlignment: Alignment.topLeft,
          children: [
            const Divider(color: AppTheme.border, height: 1, thickness: 1),
            const SizedBox(height: 16),
            ...content.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
