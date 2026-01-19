import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../controllers/leave_controller.dart';
import '../../models/leave_model.dart';

class ApplyLeaveScreen extends StatefulWidget {
  const ApplyLeaveScreen({super.key});

  @override
  State<ApplyLeaveScreen> createState() => _ApplyLeaveScreenState();
}

class _ApplyLeaveScreenState extends State<ApplyLeaveScreen> {
  final _formKey = GlobalKey<FormState>();
  
  LeaveType? _selectedType;
  DateTimeRange? _selectedDateRange;
  final TextEditingController _reasonController = TextEditingController();
  
  // Validation message from local checks
  String? _validationMessage;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<LeaveController>(context);
    final isProbation = controller.balance?.isProbation ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Apply for Leave',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionLabel('Leave Type'),
                const SizedBox(height: 8),
                _buildLeaveTypeDropdown(isProbation),
                
                const SizedBox(height: 24),
                
                _buildSectionLabel('Duration'),
                const SizedBox(height: 8),
                _buildDateRangePicker(),
                if (_validationMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _validationMessage!,
                            style: const TextStyle(color: Colors.orange, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),
                
                _buildSectionLabel('Reason'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _reasonController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Enter reason for leave...',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please provide a reason';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),
                
                if (_selectedType == LeaveType.sickLeave && (_selectedDateRange?.duration.inDays ?? 0) + 1 >= 3) ...[
                   _buildSectionLabel('Prescription'),
                   const SizedBox(height: 8),
                   _buildAttachmentUpload(),
                   const SizedBox(height: 8),
                   Text(
                     'Medical certificate is mandatory for 3 or more consecutive days.',
                     style: TextStyle(fontSize: 12, color: Colors.red[400], fontWeight: FontWeight.w500),
                   ),
                   const SizedBox(height: 32),
                ],

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: controller.isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: controller.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'Submit Application',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                
                if (controller.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Center(
                      child: Text(
                        controller.errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildLeaveTypeDropdown(bool isProbation) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<LeaveType>(
          value: _selectedType,
          isExpanded: true,
          hint: const Text('Select Leave Type'),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.indigo),
          items: LeaveType.values.where((type) {
             if (isProbation) {
               // Probation employees cannot apply for Earned Leave
               return type != LeaveType.earnedLeave;
             }
             return true;
          }).map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(_getLeaveTypeDisplay(type)),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedType = value;
              _validateSelection();
            });
          },
        ),
      ),
    );
  }

  Widget _buildDateRangePicker() {
    return GestureDetector(
      onTap: () async {
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime.now().subtract(const Duration(days: 0)), // Can't apply for past in general
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Colors.indigo,
                  onPrimary: Colors.white,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          setState(() {
            _selectedDateRange = picked;
            _validateSelection();
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month_outlined, color: Colors.indigo),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedDateRange == null
                    ? 'Select Dates'
                    : '${DateFormat('MMM d').format(_selectedDateRange!.start)} - ${DateFormat('MMM d').format(_selectedDateRange!.end)}',
                style: TextStyle(
                  color: _selectedDateRange == null ? Colors.grey[400] : Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (_selectedDateRange != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.indigo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_selectedDateRange!.duration.inDays + 1} Days',
                  style: const TextStyle(
                    color: Colors.indigo,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentUpload() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_upload_outlined, color: Colors.indigo),
          const SizedBox(width: 12),
          const Text(
            'Upload Medical Certificate',
            style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  String _getLeaveTypeDisplay(LeaveType type) {
    switch (type) {
      case LeaveType.sickLeave: return 'Sick Leave';
      case LeaveType.casualLeave: return 'Casual Leave';
      case LeaveType.happinessLeave: return 'Happiness Leave';
      case LeaveType.maternityLeave: return 'Maternity Leave';
      case LeaveType.paternityLeave: return 'Paternity Leave';
      case LeaveType.marriageLeave: return 'Marriage Leave';
      case LeaveType.bereavementLeave: return 'Bereavement Leave';
      case LeaveType.earnedLeave: return 'Earned Leave';
      case LeaveType.carryForwardLeave: return 'Carry Forward Leave';
      case LeaveType.workFromHome: return 'Work From Home';
      case LeaveType.compOff: return 'Comp-Off';
      case LeaveType.lwp: return 'LWP (Leave Without Pay)';
    }
  }

  void _validateSelection() {
    if (_selectedType != null && _selectedDateRange != null) {
      final controller = Provider.of<LeaveController>(context, listen: false);
      setState(() {
        _validationMessage = controller.validateRequest(
          _selectedType!, 
          _selectedDateRange!.start, 
          _selectedDateRange!.end,
        );
      });
    } else {
      setState(() {
        _validationMessage = null;
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a leave type')),
        );
        return;
      }
      if (_selectedDateRange == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select leave dates')),
        );
        return;
      }

      final controller = Provider.of<LeaveController>(context, listen: false);
      
      final success = await controller.submitLeaveRequest(
        type: _selectedType!,
        start: _selectedDateRange!.start,
        end: _selectedDateRange!.end,
        reason: _reasonController.text,
        attachmentPath: null, // Placeholder
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Leave request submitted successfully!')),
        );
        Navigator.pop(context); // Go back to dashboard
      }
    }
  }
}
