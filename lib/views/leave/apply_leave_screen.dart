import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:indigi_attendance/controllers/leave_controller.dart';
import 'package:indigi_attendance/controllers/auth_controller.dart';
import '../../models/leave_model.dart';

class ApplyLeaveScreen extends StatefulWidget {
  final LeaveRequest? existingRequest;
  const ApplyLeaveScreen({super.key, this.existingRequest});

  @override
  State<ApplyLeaveScreen> createState() => _ApplyLeaveScreenState();
}

class _ApplyLeaveScreenState extends State<ApplyLeaveScreen> {
  final _formKey = GlobalKey<FormState>();
  
  LeaveType? _selectedType;
  DateTimeRange? _selectedDateRange;
  final TextEditingController _reasonController = TextEditingController();
  String? _attachmentPath;
  String? _attachmentName;
  
  // Validation message from local checks
  String? _validationMessage;

  @override
  void initState() {
    super.initState();
    if (widget.existingRequest != null) {
      _selectedType = widget.existingRequest!.type;
      _selectedDateRange = DateTimeRange(
        start: widget.existingRequest!.startDate,
        end: widget.existingRequest!.endDate,
      );
      _reasonController.text = widget.existingRequest!.reason;
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.indigo),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.attach_file, color: Colors.indigo),
                title: const Text('Choose File'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFile();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);

      if (image != null) {
        setState(() {
          _attachmentPath = image.path;
          _attachmentName = image.name;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'pdf', 'png', 'jpeg'],
      );

      if (result != null) {
        setState(() {
          _attachmentPath = result.files.single.path;
          _attachmentName = result.files.single.name;
        });
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<LeaveController>(context);
    final isProbation = controller.balance?.employeeType?.toLowerCase() == 'probation';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          widget.existingRequest != null ? 'Edit Leave' : 'Apply for Leave',
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
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
                   _buildSectionLabel('Prescription (Optional)'),
                   const SizedBox(height: 8),
                   _buildAttachmentUpload(),
                   const SizedBox(height: 8),
                   Text(
                     'You can upload a medical certificate if available.',
                     style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
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
                        : Text(
                            widget.existingRequest != null ? 'Update Application' : 'Submit Application',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
          initialDateRange: _selectedDateRange,
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
    return GestureDetector(
      onTap: _showAttachmentOptions,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _attachmentPath != null ? Colors.indigo : Colors.grey.shade300, 
            style: BorderStyle.solid,
            width: _attachmentPath != null ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _attachmentPath != null ? Icons.check_circle : Icons.cloud_upload_outlined, 
              color: _attachmentPath != null ? Colors.indigo : Colors.indigo,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _attachmentName ?? 'Upload Medical Certificate',
                style: const TextStyle(
                  color: Colors.indigo, 
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_attachmentPath != null)
              IconButton(
                icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                onPressed: () {
                  setState(() {
                    _attachmentPath = null;
                    _attachmentName = null;
                  });
                },
              )
          ],
        ),
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

      final authController = Provider.of<AuthController>(context, listen: false);
      final empCode = authController.currentUser?.employeeCode;

      if (empCode == null) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User session invalid. Please login again.')),
        );
        return;
      }

      final controller = Provider.of<LeaveController>(context, listen: false);
      
      bool success;
      if (widget.existingRequest != null) {
        success = await controller.updateLeaveRequest(
          leaveId: widget.existingRequest!.id,
          empCode: empCode,
          type: _selectedType!,
          start: _selectedDateRange!.start,
          end: _selectedDateRange!.end,
          reason: _reasonController.text,
        );
      } else {
        success = await controller.submitLeaveRequest(
          empCode: empCode,
          type: _selectedType!,
          start: _selectedDateRange!.start,
          end: _selectedDateRange!.end,
          reason: _reasonController.text,
          attachmentPath: _attachmentPath,
        );
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.existingRequest != null ? 'Leave request updated successfully!' : 'Leave request submitted successfully!')),
        );
        Navigator.pop(context); // Go back to dashboard
      }
    }
  }
}
