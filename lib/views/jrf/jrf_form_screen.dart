import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';

class JrfFormScreen extends StatefulWidget {
  const JrfFormScreen({super.key});

  @override
  State<JrfFormScreen> createState() => _JrfFormScreenState();
}

class _JrfFormScreenState extends State<JrfFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Section A Data
  final String _requisitionNo = "REQ-${DateTime.now().year}-${(1000 + DateTime.now().millisecond).toString().substring(1)}";
  DateTime _dateOfRequest = DateTime.now();
  final TextEditingController _requestedByController = TextEditingController();
  String _teamFunction = "SAP";
  final TextEditingController _otherTeamController = TextEditingController();
  final TextEditingController _positionTitleController = TextEditingController();
  final TextEditingController _noOfPositionsController = TextEditingController();
  String _employmentType = "Full-time";

  // Section B Data
  String _jobLevel = "Mid-Level";
  final TextEditingController _reportingToController = TextEditingController();
  String _workLocation = "Guwahati";
  final TextEditingController _otherLocationController = TextEditingController();
  DateTime? _proposedJoiningDate;
  String _requirementNature = "New Role";

  // Section C Data
  final List<String> _reasonsForRequisition = [];
  final TextEditingController _otherReasonController = TextEditingController();
  final TextEditingController _justificationController = TextEditingController();

  // Section D Data
  final TextEditingController _responsibilitiesController = TextEditingController();
  final TextEditingController _skillsController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();

  // Section E Data
  final TextEditingController _salaryRangeController = TextEditingController();
  String _budgetApprovedIn = "Project Budget";
  final TextEditingController _benefitsController = TextEditingController();

  @override
  void dispose() {
    _requestedByController.dispose();
    _otherTeamController.dispose();
    _positionTitleController.dispose();
    _noOfPositionsController.dispose();
    _reportingToController.dispose();
    _otherLocationController.dispose();
    _otherReasonController.dispose();
    _justificationController.dispose();
    _responsibilitiesController.dispose();
    _skillsController.dispose();
    _experienceController.dispose();
    _salaryRangeController.dispose();
    _benefitsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isRequestDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isRequestDate ? _dateOfRequest : (_proposedJoiningDate ?? DateTime.now().add(const Duration(days: 30))),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.accent,
              onPrimary: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isRequestDate) {
          _dateOfRequest = picked;
        } else {
          _proposedJoiningDate = picked;
        }
      });
    }
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      // Custom validation for checkboxes in Section C
      if (_reasonsForRequisition.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one Reason for Requisition in Section C.'),
            backgroundColor: AppTheme.error,
          ),
        );
        return;
      }

      // Successful simulated submission
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return Dialog(
            shape: const RoundedRectangleBorder(borderRadius: AppTheme.radiusXL),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: _buildSuccessModal(context),
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please correct the errors in the form before submitting.'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Job Requisition Form (JRF)'),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildFormHeaderCard(),
                  const SizedBox(height: 16),
                  _buildSectionA(),
                  const SizedBox(height: 16),
                  _buildSectionB(),
                  const SizedBox(height: 16),
                  _buildSectionC(),
                  const SizedBox(height: 16),
                  _buildSectionD(),
                  const SizedBox(height: 16),
                  _buildSectionE(),
                  const SizedBox(height: 16),
                  _buildSectionF(),
                  const SizedBox(height: 32),
                  _buildSubmitButton(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Form Components ────────────────────────────────────────────────────────

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.radiusXL,
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: AppTheme.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              border: Border(bottom: BorderSide(color: AppTheme.border, width: 1)),
            ),
            child: Row(
              children: [
                AppTheme.iconContainer(icon: icon, color: color, size: 20, padding: 8),
                const SizedBox(height: 12, width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: AppTheme.headingSM.copyWith(color: AppTheme.textPrimary),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppTheme.radiusXL,
        boxShadow: AppTheme.accentShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.description_rounded, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                'Manpower Requisition',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Complete all sections below to request new roles or vacancy replacements. Once submitted, it will be automatically routed to HR for review.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionA() {
    return _buildCard(
      title: 'Section A: Basic Information',
      icon: Icons.info_outline_rounded,
      color: AppTheme.accent,
      children: [
        // Requisition No (Read Only)
        _buildReadOnlyField(
          label: 'Requisition No',
          value: _requisitionNo,
          icon: Icons.tag_rounded,
        ),
        const SizedBox(height: 16),

        // Date of Request
        InkWell(
          onTap: () => _selectDate(context, true),
          borderRadius: AppTheme.radiusMD,
          child: _buildReadOnlyField(
            label: 'Date of Request *',
            value: DateFormat('dd MMM yyyy').format(_dateOfRequest),
            icon: Icons.calendar_month_rounded,
            trailing: const Icon(Icons.arrow_drop_down_rounded, color: AppTheme.textSecondary),
          ),
        ),
        const SizedBox(height: 16),

        // Requested By
        TextFormField(
          controller: _requestedByController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Requested By (PM / Sales Lead / Team Lead) *',
            hintText: 'e.g. Jane Doe',
            prefixIcon: Icon(Icons.person_outline_rounded, color: AppTheme.textSecondary),
          ),
          validator: (value) => value == null || value.trim().isEmpty ? 'Please enter who is requesting' : null,
        ),
        const SizedBox(height: 16),

        // Team / Function Selection
        const Text('Team / Function *', style: AppTheme.caption),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['SAP', 'PHP', 'Sales', 'Other'].map((team) {
            return _buildChoiceChip(
              label: team,
              isSelected: _teamFunction == team,
              onSelected: (selected) {
                if (selected) setState(() => _teamFunction = team);
              },
            );
          }).toList(),
        ),
        if (_teamFunction == 'Other') ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: _otherTeamController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Specify Team *',
              hintText: 'Enter team name',
            ),
            validator: (value) {
              if (_teamFunction == 'Other' && (value == null || value.trim().isEmpty)) {
                return 'Please specify the team';
              }
              return null;
            },
          ),
        ],
        const SizedBox(height: 16),

        // Position Title
        TextFormField(
          controller: _positionTitleController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Position Title *',
            hintText: 'e.g. Senior SAP Consultant',
            prefixIcon: Icon(Icons.title_rounded, color: AppTheme.textSecondary),
          ),
          validator: (value) => value == null || value.trim().isEmpty ? 'Please enter the position title' : null,
        ),
        const SizedBox(height: 16),

        // No of Positions Required
        TextFormField(
          controller: _noOfPositionsController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'No. of Positions Required *',
            hintText: 'e.g. 2',
            prefixIcon: Icon(Icons.people_outline_rounded, color: AppTheme.textSecondary),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter the number of positions';
            }
            final num = int.tryParse(value);
            if (num == null || num <= 0) {
              return 'Must be a positive integer';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Employment Type
        const Text('Employment Type *', style: AppTheme.caption),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['Full-time', 'Contract', 'Internship'].map((type) {
            return _buildChoiceChip(
              label: type,
              isSelected: _employmentType == type,
              onSelected: (selected) {
                if (selected) setState(() => _employmentType = type);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSectionB() {
    return _buildCard(
      title: 'Section B: Job Details',
      icon: Icons.work_outline_rounded,
      color: Colors.indigo,
      children: [
        // Job Level
        const Text('Job Level *', style: AppTheme.caption),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['Junior', 'Mid-Level', 'Senior', 'Managerial'].map((level) {
            return _buildChoiceChip(
              label: level,
              isSelected: _jobLevel == level,
              onSelected: (selected) {
                if (selected) setState(() => _jobLevel = level);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Reporting To
        TextFormField(
          controller: _reportingToController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Reporting To *',
            hintText: 'e.g. Tech Lead / Director',
            prefixIcon: Icon(Icons.account_tree_outlined, color: AppTheme.textSecondary),
          ),
          validator: (value) => value == null || value.trim().isEmpty ? 'Please enter reporting authority' : null,
        ),
        const SizedBox(height: 16),

        // Work Location / Base
        const Text('Work Location / Base *', style: AppTheme.caption),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['Guwahati', 'Client Site', 'Remote', 'Other'].map((loc) {
            return _buildChoiceChip(
              label: loc,
              isSelected: _workLocation == loc,
              onSelected: (selected) {
                if (selected) setState(() => _workLocation = loc);
              },
            );
          }).toList(),
        ),
        if (_workLocation == 'Other') ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: _otherLocationController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Specify Location *',
              hintText: 'Enter work location',
            ),
            validator: (value) {
              if (_workLocation == 'Other' && (value == null || value.trim().isEmpty)) {
                return 'Please specify the work location';
              }
              return null;
            },
          ),
        ],
        const SizedBox(height: 16),

        // Proposed Date of Joining
        InkWell(
          onTap: () => _selectDate(context, false),
          borderRadius: AppTheme.radiusMD,
          child: _buildReadOnlyField(
            label: 'Proposed Date of Joining *',
            value: _proposedJoiningDate != null
                ? DateFormat('dd MMM yyyy').format(_proposedJoiningDate!)
                : 'Select joining date',
            icon: Icons.calendar_today_rounded,
            trailing: const Icon(Icons.arrow_drop_down_rounded, color: AppTheme.textSecondary),
          ),
        ),
        const SizedBox(height: 16),

        // Nature of Requirement
        const Text('Nature of Requirement *', style: AppTheme.caption),
        const SizedBox(height: 8),
        Row(
          children: ['Replacement', 'New Role'].map((nature) {
            final isSel = _requirementNature == nature;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _buildChoiceChip(
                  label: nature,
                  isSelected: isSel,
                  onSelected: (selected) {
                    if (selected) setState(() => _requirementNature = nature);
                  },
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSectionC() {
    return _buildCard(
      title: 'Section C: Justification',
      icon: Icons.help_outline_rounded,
      color: Colors.amber.shade800,
      children: [
        // Reason for Requisition (Multi-select)
        const Text('Reason for Requisition (Select all that apply) *', style: AppTheme.caption),
        const SizedBox(height: 8),
        _buildCheckboxRow('New Project / Business Requirement'),
        _buildCheckboxRow('Replacement due to Resignation'),
        _buildCheckboxRow('Expansion of Team / Increased Workload'),
        _buildCheckboxRow('Critical Skill Requirement'),
        _buildCheckboxRow('Other'),
        if (_reasonsForRequisition.contains('Other')) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: _otherReasonController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Specify Other Reason *',
              hintText: 'Enter details',
            ),
            validator: (value) {
              if (_reasonsForRequisition.contains('Other') && (value == null || value.trim().isEmpty)) {
                return 'Please specify the reason';
              }
              return null;
            },
          ),
        ],
        const SizedBox(height: 16),

        // Brief Justification
        TextFormField(
          controller: _justificationController,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Brief Justification *',
            hintText: 'Explain why this manpower is critical to the team...',
            alignLabelWithHint: true,
          ),
          validator: (value) => value == null || value.trim().isEmpty ? 'Please provide justification details' : null,
        ),
      ],
    );
  }

  Widget _buildSectionD() {
    return _buildCard(
      title: 'Section D: Job Specifications',
      icon: Icons.checklist_rounded,
      color: AppTheme.success,
      children: [
        // Key Responsibilities
        TextFormField(
          controller: _responsibilitiesController,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Key Responsibilities *',
            hintText: 'Describe key tasks, projects, and deliverables...',
            alignLabelWithHint: true,
          ),
          validator: (value) => value == null || value.trim().isEmpty ? 'Please outline responsibilities' : null,
        ),
        const SizedBox(height: 16),

        // Required Skills / Qualifications
        TextFormField(
          controller: _skillsController,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Required Skills / Qualifications *',
            hintText: 'e.g. Flutter, Dart, REST APIs, Git, 3+ years experience',
            alignLabelWithHint: true,
          ),
          validator: (value) => value == null || value.trim().isEmpty ? 'Please list required skills' : null,
        ),
        const SizedBox(height: 16),

        // Experience Required
        TextFormField(
          controller: _experienceController,
          decoration: const InputDecoration(
            labelText: 'Experience Required (in years) *',
            hintText: 'e.g. 3-5 Years',
            prefixIcon: Icon(Icons.hourglass_empty_rounded, color: AppTheme.textSecondary),
          ),
          validator: (value) => value == null || value.trim().isEmpty ? 'Please specify required experience' : null,
        ),
      ],
    );
  }

  Widget _buildSectionE() {
    return _buildCard(
      title: 'Section E: Compensation & Budget',
      icon: Icons.monetization_on_outlined,
      color: Colors.purple,
      children: [
        // Proposed Salary Range
        TextFormField(
          controller: _salaryRangeController,
          decoration: const InputDecoration(
            labelText: 'Proposed Salary Range *',
            hintText: 'e.g. ₹6,00,000 - ₹9,00,000 LPA',
            prefixIcon: Icon(Icons.payments_outlined, color: AppTheme.textSecondary),
          ),
          validator: (value) => value == null || value.trim().isEmpty ? 'Please enter proposed salary range' : null,
        ),
        const SizedBox(height: 16),

        // Budget Approved In
        const Text('Budget Approved In *', style: AppTheme.caption),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['Project Budget', 'Department Budget', 'HR Annual Budget'].map((budget) {
            return _buildChoiceChip(
              label: budget,
              isSelected: _budgetApprovedIn == budget,
              onSelected: (selected) {
                if (selected) setState(() => _budgetApprovedIn = budget);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Additional Benefits
        TextFormField(
          controller: _benefitsController,
          decoration: const InputDecoration(
            labelText: 'Additional Benefits (if any)',
            hintText: 'e.g. Health Insurance, Performance Bonus',
            prefixIcon: Icon(Icons.card_giftcard_rounded, color: AppTheme.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionF() {
    return _buildCard(
      title: 'Section F: Approvals Workflow',
      icon: Icons.family_restroom_rounded, // fallback or generic icon representing routing/hierarchy
      color: Colors.blueGrey,
      children: [
        const Text(
          'Visual workflow tracking. Upon submitting this requisition, the approval process routes automatically in the following hierarchy:',
          style: AppTheme.bodySM,
        ),
        const SizedBox(height: 20),
        _buildWorkflowStep(
          stepNo: '1',
          role: 'Request Initiator (PM / Lead)',
          status: 'Active',
          color: AppTheme.accent,
          isCompleted: true,
          isLast: false,
        ),
        _buildWorkflowStep(
          stepNo: '2',
          role: 'HR Review',
          status: 'Pending Submission',
          color: AppTheme.textTertiary,
          isCompleted: false,
          isLast: false,
        ),
        _buildWorkflowStep(
          stepNo: '3',
          role: 'Finance (Budget Check)',
          status: 'Pending HR Clearance',
          color: AppTheme.textTertiary,
          isCompleted: false,
          isLast: false,
        ),
        _buildWorkflowStep(
          stepNo: '4',
          role: 'CEO Approval',
          status: 'Final Sign-off',
          color: AppTheme.textTertiary,
          isCompleted: false,
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildWorkflowStep({
    required String stepNo,
    required String role,
    required String status,
    required Color color,
    required bool isCompleted,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isCompleted ? color : Colors.transparent,
                  border: Border.all(color: color, width: 2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : Text(
                          stepNo,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isCompleted ? color : AppTheme.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role,
                    style: AppTheme.bodyLG.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isCompleted ? AppTheme.textPrimary : AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    status,
                    style: AppTheme.caption.copyWith(
                      fontSize: 12,
                      color: isCompleted ? AppTheme.success : AppTheme.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: AppTheme.accentShadow,
        borderRadius: AppTheme.radiusMD,
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const RoundedRectangleBorder(borderRadius: AppTheme.radiusMD),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: _handleSubmit,
        child: const Text('SUBMIT REQUISITION'),
      ),
    );
  }

  Widget _buildSuccessModal(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.radiusXL,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AppTheme.success,
              size: 54,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Requisition Submitted!',
            style: AppTheme.headingMD,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Job Requisition Form $_requisitionNo has been successfully generated as a draft and marked for routing.',
            style: AppTheme.bodyMD,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: AppTheme.radiusSM,
              border: Border.all(color: AppTheme.border),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: AppTheme.textSecondary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Note: Backend API integration will be implemented in the next phase.',
                    style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.success,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to modules hub
              },
              child: const Text('DONE'),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helper Widgets ─────────────────────────────────────────────────────────

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: AppTheme.radiusMD,
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textSecondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTheme.bodyLG.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool isSelected,
    required ValueChanged<bool> onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: AppTheme.accent.withValues(alpha: 0.12),
      backgroundColor: AppTheme.surfaceVariant,
      checkmarkColor: AppTheme.accent,
      side: BorderSide(
        color: isSelected ? AppTheme.accent : Colors.transparent,
        width: 1.5,
      ),
      shape: const RoundedRectangleBorder(borderRadius: AppTheme.radiusSM),
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? AppTheme.accent : AppTheme.textSecondary,
      ),
    );
  }

  Widget _buildCheckboxRow(String label) {
    final bool isChecked = _reasonsForRequisition.contains(label);
    return InkWell(
      onTap: () {
        setState(() {
          if (isChecked) {
            _reasonsForRequisition.remove(label);
          } else {
            _reasonsForRequisition.add(label);
          }
        });
      },
      borderRadius: AppTheme.radiusSM,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Checkbox(
              value: isChecked,
              onChanged: (bool? checked) {
                setState(() {
                  if (checked == true) {
                    _reasonsForRequisition.add(label);
                  } else {
                    _reasonsForRequisition.remove(label);
                  }
                });
              },
              activeColor: AppTheme.accent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            Expanded(
              child: Text(
                label,
                style: AppTheme.bodyMD.copyWith(
                  color: isChecked ? AppTheme.textPrimary : AppTheme.textSecondary,
                  fontWeight: isChecked ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
