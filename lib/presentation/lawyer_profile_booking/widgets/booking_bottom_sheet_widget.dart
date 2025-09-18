import 'dart:io' if (dart.library.io) 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class BookingBottomSheetWidget extends StatefulWidget {
  final DateTime selectedDate;
  final String selectedTime;
  final Map<String, dynamic> lawyerData;
  final Function(Map<String, dynamic>) onBookingConfirmed;

  const BookingBottomSheetWidget({
    Key? key,
    required this.selectedDate,
    required this.selectedTime,
    required this.lawyerData,
    required this.onBookingConfirmed,
  }) : super(key: key);

  @override
  State<BookingBottomSheetWidget> createState() =>
      _BookingBottomSheetWidgetState();
}

class _BookingBottomSheetWidgetState extends State<BookingBottomSheetWidget> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  String? _selectedCaseType;
  String? _selectedUrgency;
  List<XFile> _uploadedDocuments = [];
  bool _isLoading = false;

  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;

  final List<String> _caseTypes = [
    'Criminal Law',
    'Civil Law',
    'Family Law',
    'Corporate Law',
    'Real Estate Law',
    'Immigration Law',
    'Personal Injury',
    'Employment Law',
    'Tax Law',
    'Other'
  ];

  final List<String> _urgencyLevels = [
    'Low - Within 2 weeks',
    'Medium - Within 1 week',
    'High - Within 3 days',
    'Urgent - Within 24 hours'
  ];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      if (await _requestCameraPermission()) {
        _cameras = await availableCameras();
        if (_cameras.isNotEmpty) {
          final camera = kIsWeb
              ? _cameras.firstWhere(
                  (c) => c.lensDirection == CameraLensDirection.front,
                  orElse: () => _cameras.first)
              : _cameras.firstWhere(
                  (c) => c.lensDirection == CameraLensDirection.back,
                  orElse: () => _cameras.first);

          _cameraController = CameraController(
              camera, kIsWeb ? ResolutionPreset.medium : ResolutionPreset.high);

          await _cameraController!.initialize();
          await _applySettings();

          if (mounted) {
            setState(() {
              _isCameraInitialized = true;
            });
          }
        }
      }
    } catch (e) {
      // Camera initialization failed, continue without camera
    }
  }

  Future<bool> _requestCameraPermission() async {
    if (kIsWeb) return true;
    return (await Permission.camera.request()).isGranted;
  }

  Future<void> _applySettings() async {
    if (_cameraController == null) return;

    try {
      await _cameraController!.setFocusMode(FocusMode.auto);
    } catch (e) {}

    if (!kIsWeb) {
      try {
        await _cameraController!.setFlashMode(FlashMode.auto);
      } catch (e) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90.h,
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(6.w),
          topRight: Radius.circular(6.w),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 12.w,
            height: 1.h,
            margin: EdgeInsets.only(top: 2.h),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.dividerColor,
              borderRadius: BorderRadius.circular(0.5.h),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    SizedBox(height: 3.h),
                    _buildCaseTypeDropdown(),
                    SizedBox(height: 2.h),
                    _buildUrgencyDropdown(),
                    SizedBox(height: 2.h),
                    _buildDescriptionField(),
                    SizedBox(height: 2.h),
                    _buildDocumentUpload(),
                    SizedBox(height: 3.h),
                    _buildBookingSummary(),
                    SizedBox(height: 3.h),
                    _buildBookingButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Book Appointment',
              style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: CustomIconWidget(
                iconName: 'close',
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                size: 6.w,
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color:
                AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(2.w),
          ),
          child: Row(
            children: [
              CustomIconWidget(
                iconName: 'schedule',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 5.w,
              ),
              SizedBox(width: 2.w),
              Text(
                '${_formatDate(widget.selectedDate)} at ${widget.selectedTime}',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCaseTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Case Type *',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        DropdownButtonFormField<String>(
          value: _selectedCaseType,
          decoration: InputDecoration(
            hintText: 'Select case type',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(2.w),
            ),
          ),
          items: _caseTypes.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(type),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCaseType = value;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a case type';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildUrgencyDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Urgency Level *',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        DropdownButtonFormField<String>(
          value: _selectedUrgency,
          decoration: InputDecoration(
            hintText: 'Select urgency level',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(2.w),
            ),
          ),
          items: _urgencyLevels.map((urgency) {
            return DropdownMenuItem(
              value: urgency,
              child: Text(urgency),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedUrgency = value;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select urgency level';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Case Description *',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        TextFormField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Briefly describe your legal matter...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(2.w),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please provide a case description';
            }
            if (value.trim().length < 20) {
              return 'Please provide more details (minimum 20 characters)';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDocumentUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Supporting Documents (Optional)',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _pickFromGallery,
                icon: CustomIconWidget(
                  iconName: 'photo_library',
                  color: Colors.white,
                  size: 5.w,
                ),
                label: Text('Gallery'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                ),
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isCameraInitialized ? _capturePhoto : null,
                icon: CustomIconWidget(
                  iconName: 'camera_alt',
                  color: Colors.white,
                  size: 5.w,
                ),
                label: Text('Camera'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.lightTheme.colorScheme.secondary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                ),
              ),
            ),
          ],
        ),
        if (_uploadedDocuments.isNotEmpty) ...[
          SizedBox(height: 2.h),
          Container(
            height: 20.w,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _uploadedDocuments.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 20.w,
                  height: 20.w,
                  margin: EdgeInsets.only(right: 2.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2.w),
                    border: Border.all(
                      color: AppTheme.lightTheme.dividerColor,
                    ),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2.w),
                        child: kIsWeb
                            ? Image.network(
                                _uploadedDocuments[index].path,
                                width: 20.w,
                                height: 20.w,
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                File(_uploadedDocuments[index].path),
                                width: 20.w,
                                height: 20.w,
                                fit: BoxFit.cover,
                              ),
                      ),
                      Positioned(
                        top: 1.w,
                        right: 1.w,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _uploadedDocuments.removeAt(index);
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.all(1.w),
                            decoration: BoxDecoration(
                              color: AppTheme.lightTheme.colorScheme.error,
                              shape: BoxShape.circle,
                            ),
                            child: CustomIconWidget(
                              iconName: 'close',
                              color: Colors.white,
                              size: 3.w,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBookingSummary() {
    final hourlyRate = widget.lawyerData['hourlyRate'] as double? ?? 0.0;
    final consultationFee = hourlyRate;
    final platformFee = consultationFee * 0.1;
    final totalCost = consultationFee + platformFee;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(2.w),
        border: Border.all(
          color: AppTheme.lightTheme.dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Booking Summary',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2.h),
          _buildSummaryRow('Consultation (1 hour)',
              '\$${consultationFee.toStringAsFixed(2)}'),
          _buildSummaryRow(
              'Platform Fee', '\$${platformFee.toStringAsFixed(2)}'),
          Divider(),
          _buildSummaryRow(
            'Total Amount',
            '\$${totalCost.toStringAsFixed(2)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String amount, {bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            amount,
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? AppTheme.lightTheme.colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _confirmBooking,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.lightTheme.colorScheme.primary,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 2.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(2.w),
          ),
        ),
        child: _isLoading
            ? SizedBox(
                width: 5.w,
                height: 5.w,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'Confirm Booking',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Future<void> _pickFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _uploadedDocuments.add(image);
      });
    }
  }

  Future<void> _capturePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final XFile photo = await _cameraController!.takePicture();
      setState(() {
        _uploadedDocuments.add(photo);
      });
    } catch (e) {
      // Handle capture error silently
    }
  }

  Future<void> _confirmBooking() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate booking process
    await Future.delayed(Duration(seconds: 2));

    final bookingData = {
      'lawyerId': widget.lawyerData['id'],
      'lawyerName': widget.lawyerData['name'],
      'date': widget.selectedDate,
      'time': widget.selectedTime,
      'caseType': _selectedCaseType,
      'urgency': _selectedUrgency,
      'description': _descriptionController.text.trim(),
      'documents': _uploadedDocuments.map((doc) => doc.path).toList(),
      'totalAmount': (widget.lawyerData['hourlyRate'] as double? ?? 0.0) * 1.1,
      'status': 'pending',
      'bookingId': 'BK${DateTime.now().millisecondsSinceEpoch}',
    };

    setState(() {
      _isLoading = false;
    });

    widget.onBookingConfirmed(bookingData);
    Navigator.pop(context);
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
