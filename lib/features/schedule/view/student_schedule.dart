import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flearn_app/core/constants/colors.dart';
import 'package:flearn_app/features/schedule/model/enrollment_model.dart';
import 'package:flearn_app/features/schedule/viewmodel/schedule_viewmodel.dart';

class StudentScheduleScreen extends StatefulWidget {
  const StudentScheduleScreen({super.key});

  @override
  State<StudentScheduleScreen> createState() => _StudentScheduleScreenState();
}

class _StudentScheduleScreenState extends State<StudentScheduleScreen> {
  late final ScheduleViewModel _viewModel;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _viewModel = Get.put(ScheduleViewModel(service: Get.find()));
    _viewModel.fetchMyEnrollments();
  }

  void _onDaySelected(DateTime day) {
    setState(() {
      _selectedDate = day;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Lịch học của tôi'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: Obx(() {
        if (_viewModel.isLoading.value && _viewModel.myEnrollments.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (_viewModel.errorMessage.value.isNotEmpty) {
          return Center(child: Text(_viewModel.errorMessage.value));
        }

        return Column(
          children: [
            _buildWeekSelector(),
            const SizedBox(height: 16),
            _buildTimelineHeader(),
            Expanded(child: _buildTimeline()),
          ],
        );
      }),
    );
  }

  Widget _buildWeekSelector() {
    final weekStart = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
    final days = List.generate(7, (index) => weekStart.add(Duration(days: index)));

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: days.map((day) {
          final isSelected = day.year == _selectedDate.year &&
              day.month == _selectedDate.month &&
              day.day == _selectedDate.day;
          return GestureDetector(
            onTap: () => _onDaySelected(day),
            child: Column(
              children: [
                Text(
                  DateFormat('E').format(day).toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? AppColors.primary : Colors.grey.shade600,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTimelineHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            DateFormat('MMMM d, yyyy').format(_selectedDate),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.today, color: AppColors.primary),
            onPressed: () => _onDaySelected(DateTime.now()),
          )
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    final enrollmentsForDay = _viewModel.myEnrollments.where((e) {
      final startDate = e.startDateTime;
      return startDate.year == _selectedDate.year &&
          startDate.month == _selectedDate.month &&
          startDate.day == _selectedDate.day;
    }).toList();

    enrollmentsForDay.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));

    if (enrollmentsForDay.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_outlined, size: 60, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Không có lịch học',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    // Determine the current or next event to highlight
    Enrollment? highlightedEnrollment;
    final now = DateTime.now();
    
    // Find current running class
    final currentClasses = enrollmentsForDay.where((e) => now.isAfter(e.startDateTime) && now.isBefore(e.endDateTime));
    if (currentClasses.isNotEmpty) {
      highlightedEnrollment = currentClasses.first;
    } else {
      // Find next class to start
      final upcomingClasses = enrollmentsForDay.where((e) => now.isBefore(e.startDateTime));
      if (upcomingClasses.isNotEmpty) {
        highlightedEnrollment = upcomingClasses.first;
      }
    }


    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: enrollmentsForDay.length,
      itemBuilder: (context, index) {
        final enrollment = enrollmentsForDay[index];
        final isHighlighted = enrollment == highlightedEnrollment;

        return _buildTimelineItem(
          enrollment,
          isFirst: index == 0,
          isLast: index == enrollmentsForDay.length - 1,
          isHighlighted: isHighlighted,
        );
      },
    );
  }

  Widget _buildTimelineItem(Enrollment enrollment, {required bool isFirst, required bool isLast, required bool isHighlighted}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline graphic
          SizedBox(
            width: 40,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Container(
                  width: 2,
                  height: 20,
                  color: isFirst ? Colors.transparent : Colors.grey.shade300,
                ),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isHighlighted ? AppColors.primary : Colors.grey.shade300,
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast ? Colors.transparent : Colors.grey.shade300,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isHighlighted ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      enrollment.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isHighlighted ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'GV: ${enrollment.teacherName}',
                       style: TextStyle(
                        fontSize: 14,
                        color: isHighlighted ? Colors.white.withOpacity(0.8) : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${enrollment.totalEnrollments}/${enrollment.capacity} HV',
                           style: TextStyle(
                            fontSize: 14,
                            color: isHighlighted ? Colors.white.withOpacity(0.8) : Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          '${DateFormat('HH:mm').format(enrollment.startDateTime)} - ${DateFormat('HH:mm').format(enrollment.endDateTime)}',
                           style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isHighlighted ? Colors.white : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    if (enrollment.canJoinClass) ...[
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () { /* Handle join class */ },
                        icon: Icon(Icons.videocam, color: isHighlighted ? AppColors.primary : Colors.white),
                        label: Text(
                          'Vào lớp học',
                          style: TextStyle(color: isHighlighted ? AppColors.primary : Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isHighlighted ? Colors.white : AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      )
                    ]
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
