import 'package:flutter/material.dart';

class LeavePolicyScreen extends StatelessWidget {
  const LeavePolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Leave Policy 2026',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             _buildSectionTitle('Leave Types for Confirmed Employees'),
             const SizedBox(height: 16),
             
             _buildPolicyCard(
               title: 'Casual Leave (CL)',
               content: [
                 '7 days per calendar year',
                 'Normally, not more than 2 consecutive days',
                 'Cannot be carried forward or encashed',
                 'Requires Reporting Manager approval',
               ],
               color: Colors.blue,
             ),
             
             _buildPolicyCard(
               title: 'Sick Leave (SL)',
               content: [
                 '7 days per calendar year',
                 'Applicable for illness or medical emergencies',
                 'Medical certificate mandatory for 3 or more consecutive days',
                 'Cannot be encashed',
               ],
               color: Colors.red,
             ),

             _buildPolicyCard(
               title: 'Earned Leave (EL)',
               content: [
                 'Entitlement: 18 days per calendar year (accrued at 1.5 days per month)',
                 'Intended strictly for planned or long-duration leave',
                 'Must be applied at least 14 calendar days in advance through HRMS',
                 'Minimum EL availed at a time: 3 consecutive days',
                 'Requests for less than 3 days will not be permitted',
                 'Short-duration leave will be adjusted against CL or SL',
                 'Carry forward limited to 5 days to the next calendar year',
                 'EL is not encashable during the year unless approved by Management',
                 'EL cannot be merged or combined with CL or SL under any circumstances',
                 'EL must be applied separately and independently',
                 'Late arrival or early departure adjustment against EL is strictly prohibited',
                 'EL cannot be used for attendance regularization',
                 'Any attempt to merge EL with CL or SL shall be rejected or reclassified',
               ],
               color: Colors.green,
             ),
             
             const SizedBox(height: 24),
             _buildSectionTitle('Probation Employees'),
             const SizedBox(height: 16),

             _buildPolicyCard(
               title: 'Probation Leave Rules',
               content: [
                 '1 day leave per completed month of service',
                 'Leave can be used as Casual Leave or Sick Leave',
                 'Earned Leave (EL) is not applicable during probation',
                 'Leave cannot be carried forward or encashed',
               ],
               color: Colors.orange,
             ),

             const SizedBox(height: 24),
             _buildSectionTitle('Other Policies'),
             const SizedBox(height: 16),

             _buildPolicyCard(
               title: 'Compensatory Off (Comp-Off)',
               content: [
                 'Applicable when working on a weekly off or declared holiday due to business needs',
                 'Requires Reporting Manager approval',
                 'Must be availed within 30 days, failing which it will lapse',
                 'Comp-Off is not encashable',
               ],
               color: Colors.purple,
             ),

             _buildPolicyCard(
               title: 'Holidays',
               content: [
                 'National & Festival Holiday List will be circulated separately',
                 'Employees must follow the holiday list applicable to their base location',
               ],
               color: Colors.teal,
             ),
             
             const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildPolicyCard({
    required String title,
    required List<String> content,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 16,
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: content.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Icon(Icons.circle, size: 6, color: color.withOpacity(0.6)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
