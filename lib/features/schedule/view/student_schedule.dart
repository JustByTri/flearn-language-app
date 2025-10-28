import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import '../viewmodel/schedule_viewmodel.dart';

class StudentScheduleScreen extends StatefulWidget {
  const StudentScheduleScreen({super.key});

  @override
  State<StudentScheduleScreen> createState() => _StudentScheduleScreenState();
}

class _StudentScheduleScreenState extends State<StudentScheduleScreen> with WidgetsBindingObserver {
  late final ScheduleViewModel viewModel;
  DateTime _currentStart = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    viewModel = Get.put(ScheduleViewModel(service: Get.find()));
    _loadEnrollments();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadEnrollments();
    }
  }

  Future<void> _loadEnrollments() async {
    await viewModel.fetchMyEnrollments();

    if (viewModel.myEnrollments.isNotEmpty) {
      final firstEnrollment = viewModel.myEnrollments.first;
      setState(() {
        _currentStart = firstEnrollment.startDateTime;
      });
    }
  }

  void _nextWeek() {
    setState(() {
      _currentStart = _currentStart.add(const Duration(days: 7));
    });
    _loadEnrollments();
  }

  void _prevWeek() {
    setState(() {
      _currentStart = _currentStart.subtract(const Duration(days: 7));
    });
    _loadEnrollments();
  }

  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  Map<DateTime, List<dynamic>> _groupEnrollmentsByDay(List<dynamic> enrollments, DateTime weekStart) {
    final Map<DateTime, List<dynamic>> grouped = {};
    for (int i = 0; i < 7; i++) {
      final day = weekStart.add(Duration(days: i));
      grouped[day] = [];
    }
    for (final e in enrollments) {
      final startDate = DateTime(e.startDateTime.year, e.startDateTime.month, e.startDateTime.day);
      if (grouped.containsKey(startDate)) {
        grouped[startDate]!.add(e);
      }
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final weekStart = _getWeekStart(_currentStart);
    final weekEnd = weekStart.add(const Duration(days: 6));
    final weekRange = '${DateFormat('dd/MM/yyyy').format(weekStart)} - ${DateFormat('dd/MM/yyyy').format(weekEnd)}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch học của tôi'),
        actions: [
          IconButton(icon: const Icon(Icons.arrow_back), onPressed: _prevWeek),
          IconButton(icon: const Icon(Icons.arrow_forward), onPressed: _nextWeek),
        ],
      ),
      body: Obx(() {
        if (viewModel.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final allEnrollments = viewModel.myEnrollments;
        final groupedEnrollments = _groupEnrollmentsByDay(allEnrollments, weekStart);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Tuần: $weekRange',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: 7,
                itemBuilder: (context, index) {
                  final day = weekStart.add(Duration(days: index));
                  final dayEnrollments = groupedEnrollments[day] ?? [];
                  final dayName = DateFormat('E').format(day);
                  final dayNumber = DateFormat('dd').format(day);

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8.0),
                      color: dayEnrollments.isEmpty ? Colors.grey.shade50 : Colors.white,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$dayName $dayNumber',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        dayEnrollments.isEmpty
                            ? const Text('Không có lớp', style: TextStyle(fontSize: 14, color: Colors.grey))
                            : SizedBox(
                          height: 200,
                          child: ListView.builder(
                            itemCount: dayEnrollments.length,
                            itemBuilder: (context, idx) {
                              final e = dayEnrollments[idx];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8.0),
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      e.title,
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${DateFormat('HH:mm').format(e.startDateTime)} - ${DateFormat('HH:mm').format(e.endDateTime)}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }
}