import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class AppointmentDetailsCardWidget extends StatelessWidget {
  final Map<String, dynamic> appointmentData;

  const AppointmentDetailsCardWidget({
    Key? key,
    required this.appointmentData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(4.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(5.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Appointment Details',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.lightTheme.colorScheme.primary,
              ),
            ),
            SizedBox(height: 3.h),
            _buildLawyerInfo(),
            SizedBox(height: 3.h),
            _buildAppointmentInfo(),
            SizedBox(height: 3.h),
            _buildCostInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildLawyerInfo() {
    return Row(
      children: [
        Container(
          width: 15.w,
          height: 15.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.lightTheme.colorScheme.primary
                  .withValues(alpha: 0.2),
              width: 2,
            ),
          ),
          child: ClipOval(
            child: CustomImageWidget(
              imageUrl: appointmentData['lawyerPhoto'] as String? ??
                  'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face',
              width: 15.w,
              height: 15.w,
              fit: BoxFit.cover,
            ),
          ),
        ),
        SizedBox(width: 4.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                appointmentData['lawyerName'] as String? ?? 'Dr. Sarah Johnson',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 0.5.h),
              Text(
                appointmentData['lawyerSpecialty'] as String? ??
                    'Corporate Law Specialist',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 0.5.h),
              Row(
                children: [
                  CustomIconWidget(
                    iconName: 'star',
                    color: Colors.amber,
                    size: 4.w,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    '${appointmentData['lawyerRating'] ?? '4.8'} (${appointmentData['reviewCount'] ?? '127'} reviews)',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppointmentInfo() {
    return Column(
      children: [
        _buildInfoRow(
          'calendar_today',
          'Date & Time',
          '${appointmentData['appointmentDate'] ?? 'August 25, 2025'} at ${appointmentData['appointmentTime'] ?? '2:00 PM'}',
        ),
        SizedBox(height: 2.h),
        _buildInfoRow(
          'work',
          'Case Type',
          appointmentData['caseType'] as String? ?? 'Business Contract Review',
        ),
        SizedBox(height: 2.h),
        _buildInfoRow(
          'schedule',
          'Duration',
          '${appointmentData['duration'] ?? '60'} minutes',
        ),
        SizedBox(height: 2.h),
        _buildInfoRow(
          appointmentData['meetingType'] == 'video'
              ? 'videocam'
              : 'location_on',
          'Meeting Type',
          appointmentData['meetingType'] == 'video'
              ? 'Video Consultation'
              : 'In-Person at ${appointmentData['location'] ?? 'Law Office'}',
        ),
      ],
    );
  }

  Widget _buildCostInfo() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.primaryContainer
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(3.w),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total Cost',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            appointmentData['totalCost'] as String? ?? '\$150.00',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.lightTheme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String iconName, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 10.w,
          height: 10.w,
          decoration: BoxDecoration(
            color:
                AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(2.w),
          ),
          child: CustomIconWidget(
            iconName: iconName,
            color: AppTheme.lightTheme.colorScheme.primary,
            size: 5.w,
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                value,
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
