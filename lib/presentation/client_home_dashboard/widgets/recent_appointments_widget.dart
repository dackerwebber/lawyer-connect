import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import './appointment_card_widget.dart';

class RecentAppointmentsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> appointments;
  final Function(Map<String, dynamic>)? onReschedule;
  final Function(Map<String, dynamic>)? onCancel;
  final Function(Map<String, dynamic>)? onMessage;
  final Function(Map<String, dynamic>)? onAppointmentTap;

  const RecentAppointmentsWidget({
    Key? key,
    required this.appointments,
    this.onReschedule,
    this.onCancel,
    this.onMessage,
    this.onAppointmentTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Appointments',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to appointments screen
                },
                child: Text(
                  'View All',
                  style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 1.h),
        appointments.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: appointments.length > 3 ? 3 : appointments.length,
                itemBuilder: (context, index) {
                  final appointment = appointments[index];
                  return AppointmentCardWidget(
                    appointment: appointment,
                    onRescheduleTap: () => onReschedule?.call(appointment),
                    onCancelTap: () => onCancel?.call(appointment),
                    onMessageTap: () => onMessage?.call(appointment),
                    onCardTap: () => onAppointmentTap?.call(appointment),
                  );
                },
              ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(8.w),
          child: Column(
            children: [
              CustomIconWidget(
                iconName: 'event_note',
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                size: 64,
              ),
              SizedBox(height: 2.h),
              Text(
                'No appointments yet',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                'Book your first appointment with a lawyer to get started',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 3.h),
              ElevatedButton(
                onPressed: () {
                  // Navigate to lawyer booking
                },
                child: Text('Find Your Lawyer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
