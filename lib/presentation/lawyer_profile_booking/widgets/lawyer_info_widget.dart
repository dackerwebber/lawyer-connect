import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class LawyerInfoWidget extends StatelessWidget {
  final Map<String, dynamic> lawyerData;

  const LawyerInfoWidget({
    Key? key,
    required this.lawyerData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(3.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  icon: 'schedule',
                  title: 'Experience',
                  value: '${lawyerData['experience'] ?? 0} years',
                ),
              ),
              Container(
                width: 1,
                height: 8.h,
                color: AppTheme.lightTheme.dividerColor,
              ),
              Expanded(
                child: _buildInfoItem(
                  icon: 'attach_money',
                  title: 'Hourly Rate',
                  value: '\$${lawyerData['hourlyRate'] ?? 0}/hr',
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  icon: 'verified',
                  title: 'Verified',
                  value: lawyerData['isVerified'] == true ? 'Yes' : 'No',
                  valueColor: lawyerData['isVerified'] == true
                      ? AppTheme.lightTheme.colorScheme.secondary
                      : AppTheme.lightTheme.colorScheme.error,
                ),
              ),
              Container(
                width: 1,
                height: 8.h,
                color: AppTheme.lightTheme.dividerColor,
              ),
              Expanded(
                child: _buildInfoItem(
                  icon: 'location_on',
                  title: 'Location',
                  value: lawyerData['location'] as String? ?? 'Not specified',
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: lawyerData['isAvailable'] == true
                  ? AppTheme.lightTheme.colorScheme.secondary
                      .withValues(alpha: 0.1)
                  : AppTheme.lightTheme.colorScheme.error
                      .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(2.w),
              border: Border.all(
                color: lawyerData['isAvailable'] == true
                    ? AppTheme.lightTheme.colorScheme.secondary
                    : AppTheme.lightTheme.colorScheme.error,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 3.w,
                  height: 3.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: lawyerData['isAvailable'] == true
                        ? AppTheme.lightTheme.colorScheme.secondary
                        : AppTheme.lightTheme.colorScheme.error,
                  ),
                ),
                SizedBox(width: 2.w),
                Text(
                  lawyerData['isAvailable'] == true
                      ? 'Available Today'
                      : 'Currently Unavailable',
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    color: lawyerData['isAvailable'] == true
                        ? AppTheme.lightTheme.colorScheme.secondary
                        : AppTheme.lightTheme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required String icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Column(
      children: [
        CustomIconWidget(
          iconName: icon,
          color: AppTheme.lightTheme.colorScheme.primary,
          size: 8.w,
        ),
        SizedBox(height: 1.h),
        Text(
          title,
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            color: valueColor ?? AppTheme.lightTheme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
