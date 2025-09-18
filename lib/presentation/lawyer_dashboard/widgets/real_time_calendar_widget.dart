import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class RealTimeCalendarWidget extends StatelessWidget {
  final List<Map<String, dynamic>> appointments;
  final List<DateTime> holidays;

  const RealTimeCalendarWidget({
    Key? key,
    required this.appointments,
    required this.holidays,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Map<DateTime, List<String>> events = {};

    // Add appointments
    for (var appointment in appointments) {
      final date = DateTime.parse(appointment['date']);
      events.putIfAbsent(date, () => []).add('Appointment');
    }

    // Add holidays
    for (var holiday in holidays) {
      events.putIfAbsent(holiday, () => []).add('Ghana Holiday');
    }

    return TableCalendar(
      firstDay: DateTime.utc(DateTime.now().year, 1, 1),
      lastDay: DateTime.utc(DateTime.now().year, 12, 31),
      focusedDay: DateTime.now(),
      eventLoader: (day) => events[day] ?? [],
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, date, events) {
          if (events.contains('Ghana Holiday')) {
            return Icon(Icons.flag, color: Colors.red, size: 16);
          }
          if (events.isNotEmpty) {
            return Icon(Icons.event, color: Colors.blue, size: 16);
          }
          return null;
        },
      ),
    );
  }
}