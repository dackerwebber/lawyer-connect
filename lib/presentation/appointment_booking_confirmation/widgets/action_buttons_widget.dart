import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ActionButtonsWidget extends StatelessWidget {
  final VoidCallback? onAddToCalendar;
  final VoidCallback? onShareDetails;
  final VoidCallback? onMessageLawyer;

  const ActionButtonsWidget({
    Key? key,
    this.onAddToCalendar,
    this.onShareDetails,
    this.onMessageLawyer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  context,
                  'calendar_today',
                  'Add to Calendar',
                  AppTheme.lightTheme.colorScheme.primary,
                  Colors.white,
                  onAddToCalendar ?? () => _addToCalendar(context),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildActionButton(
                  context,
                  'share',
                  'Share Details',
                  AppTheme.lightTheme.colorScheme.surface,
                  AppTheme.lightTheme.colorScheme.primary,
                  onShareDetails ?? () => _shareDetails(context),
                  hasBorder: true,
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          SizedBox(
            width: double.infinity,
            child: _buildActionButton(
              context,
              'message',
              'Message Lawyer',
              AppTheme.lightTheme.colorScheme.secondary,
              Colors.white,
              onMessageLawyer ?? () => _messageLawyer(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String iconName,
    String label,
    Color backgroundColor,
    Color textColor,
    VoidCallback onPressed, {
    bool hasBorder = false,
  }) {
    return Container(
      height: 12.h,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: hasBorder ? 0 : 2,
          shadowColor: Colors.black.withValues(alpha: 0.1),
          side: hasBorder
              ? BorderSide(
                  color: AppTheme.lightTheme.colorScheme.primary,
                  width: 1.5,
                )
              : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(3.w),
          ),
          padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: iconName,
              color: textColor,
              size: 6.w,
            ),
            SizedBox(height: 1.h),
            Text(
              label,
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _addToCalendar(BuildContext context) {
    // Real calendar integration would be implemented here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Opening calendar app...'),
        backgroundColor: AppTheme.lightTheme.colorScheme.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(2.w),
        ),
      ),
    );
  }

  void _shareDetails(BuildContext context) {
    // Real system share sheet would be implemented here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Opening share options...'),
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(2.w),
        ),
      ),
    );
  }

  void _messageLawyer(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Opening message thread...'),
        backgroundColor: AppTheme.lightTheme.colorScheme.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(2.w),
        ),
      ),
    );
  }
}
