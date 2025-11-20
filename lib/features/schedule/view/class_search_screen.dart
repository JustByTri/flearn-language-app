import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flearn_app/core/constants/colors.dart';
import 'package:flearn_app/features/schedule/viewmodel/class_search_viewmodel.dart';
import 'package:flearn_app/features/schedule/model/schedule_model.dart';
import 'package:flearn_app/features/schedule/view/student_schedule_screen.dart' // <-- thêm import
    ;

class ClassSearchScreen extends StatefulWidget {
  const ClassSearchScreen({super.key});

  @override
  State<ClassSearchScreen> createState() => _ClassSearchScreenState();
}

class _ClassSearchScreenState extends State<ClassSearchScreen> with TickerProviderStateMixin {
  late ClassSearchViewModel _viewModel;
  final TextEditingController _searchController = TextEditingController();
  bool _showFilters = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _viewModel = Get.put(ClassSearchViewModel(service: Get.find()));
    _searchController.addListener(_onSearchChanged);
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _viewModel.updateFilters(keyword: _searchController.text);
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    return formatter.format(amount);
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Tìm lớp học',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: Color(0xFF2D3436)),
        ),
        centerTitle: true,
        actions: [
          _buildFilterButton(),
        ],
      ),
      body: Column(
        children: [
          // GLASSMORPHIC SEARCH
          _buildGlassSearchBar(),

          // FILTERS
          AnimatedSize(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOutCubic,
            child: _showFilters ? _buildNeumorphicFilters() : const SizedBox(height: 12),
          ),

          // CLASS LIST
          Expanded(child: _buildClassList()),
        ],
      ),
    );
  }

  Widget _buildFilterButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _showFilters ? AppColors.primary.withOpacity(0.15) : Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4)),
          BoxShadow(color: Colors.white.withOpacity(0.8), blurRadius: 12, offset: const Offset(0, -4)),
        ],
      ),
      child: Icon(
        _showFilters ? Icons.tune_rounded : Icons.filter_list_rounded,
        color: _showFilters ? AppColors.primary : const Color(0xFF636E72),
        size: 24,
      ),
    ).onTap(() => setState(() => _showFilters = !_showFilters));
  }

  Widget _buildGlassSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 8)),
              ],
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Color(0xFF2D3436), fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: 'Tìm tên lớp, giáo viên...',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 26),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear_rounded, color: Color(0xFF636E72)),
                  onPressed: () => setState(() => _searchController.clear()),
                )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 18),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNeumorphicFilters() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F8),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.white, blurRadius: 15, offset: const Offset(-8, -8)),
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(8, 8)),
        ],
      ),
      child: Obx(() {
        if (_viewModel.isLoadingFilters.value) {
          return const SizedBox(height: 80, child: Center(child: CircularProgressIndicator(color: AppColors.primary)));
        }

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Bộ lọc', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16), overflow: TextOverflow.ellipsis),
                ),
                TextButton(onPressed: _viewModel.clearFilters, child: const Text('Xóa tất cả', style: TextStyle(color: AppColors.primary))),
              ],
            ),
            const SizedBox(height: 12),
            _neumorphicDropdown<Teacher>(
              label: 'Giáo viên',
              value: _viewModel.selectedTeacherId.value,
              items: _viewModel.teachers,
              getValue: (item) => item.teacherId,
              getLabel: (item) => item.fullName,
              onChanged: (v) => _viewModel.updateFilters(teacherId: v ?? ''),
            ),
            const SizedBox(height: 12),
            _neumorphicDropdown<Program>(
              label: 'Chương trình',
              value: _viewModel.selectedProgramId.value,
              items: _viewModel.programs,
              getValue: (item) => item.programId,
              getLabel: (item) => item.name,
              onChanged: (v) => _viewModel.updateFilters(programId: v ?? ''),
            ),
          ],
        );
      }),
    );
  }

  Widget _neumorphicDropdown<T>({
    required String label,
    required String value,
    required List<T> items,
    required String Function(T) getValue,
    required String Function(T) getLabel,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F8),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.white, blurRadius: 8, offset: const Offset(-4, -4)),
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(4, 4)),
        ],
      ),
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        // Use initialValue for newer API compatibility; use empty string for "Tất cả"
        initialValue: value.isEmpty ? '' : value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade700, fontSize: 14),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
        items: [
          // Use empty string to represent "all" so the types remain String
          const DropdownMenuItem(value: '', child: Text('Tất cả')),
          // Build items defensively: skip entries where getValue/getLabel fails
          ...items.map((item) {
            try {
              final v = getValue(item);
              final text = getLabel(item);
              return DropdownMenuItem<String>(
                value: v,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 240),
                  child: Text(
                    text,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              );
            } catch (err) {
              // Log mismatch and skip
              debugPrint('[Dropdown] Skipping item due to error: $err, item runtimeType=${item.runtimeType}');
              return null;
            }
          }).whereType<DropdownMenuItem<String>>(),
        ],
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildClassList() {
    return Obx(() {
      if (_viewModel.isLoading.value) return _buildShimmer();
      if (_viewModel.errorMessage.value.isNotEmpty) return _buildError();
      final hasFilter = _viewModel.selectedTeacherId.value.isNotEmpty || _viewModel.selectedProgramId.value.isNotEmpty || _viewModel.searchKeyword.value.isNotEmpty;
      if (_viewModel.classes.isEmpty) return _buildEmpty(hasFilter);

      return RefreshIndicator(
        onRefresh: () => _viewModel.searchClasses(resetPage: true),
        color: AppColors.primary,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _viewModel.classes.length,
          itemBuilder: (context, i) => _buildNeumorphicCard(_viewModel.classes[i]),
        ),
      );
    });
  }

  Widget _buildNeumorphicCard(ClassSearchResult cls) {
    final canEnroll = cls.status == 'Published' && !cls.isFull;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F4F8),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(color: Colors.white, blurRadius: 20, offset: const Offset(-10, -10)),
            BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 20, offset: const Offset(10, 10)),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: canEnroll ? () => _showDetailSheet(cls) : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildAvatar(cls),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cls.title,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF2D3436)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if ((cls.teacherName ?? '').isNotEmpty)
                          Text(
                            cls.teacherName!,
                            style: TextStyle(fontSize: 13.5, color: Colors.grey.shade600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    fit: FlexFit.loose,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: _build3DStatus(cls),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if ((cls.programName ?? '').isNotEmpty)
                Text(
                  cls.programName!,
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 6),
              Text(cls.description, style: TextStyle(color: Colors.grey.shade700, fontSize: 13.5), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 12),
              _infoRow(Icons.access_time_rounded, '${_formatDateTime(cls.startDateTime)} - ${DateFormat('HH:mm').format(cls.endDateTime)}'),
              const SizedBox(height: 8),
              _infoRow(Icons.people_alt_rounded, '${cls.currentEnrollments}/${cls.capacity} học viên'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatCurrency(cls.pricePerStudent), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primary)),
                  // Hiển thị nút nếu có thể đăng ký HOẶC là lớp vừa thanh toán
                  Obx(() {
                    final showView = _viewModel.shouldShowViewScheduleFor(cls.classID);
                    final showButton = canEnroll || showView;
                    return showButton ? _gradientButton(cls, showView) : const SizedBox.shrink();
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(ClassSearchResult cls) {
    final canEnroll = cls.status == 'Published' && !cls.isFull;
    return Hero(
      tag: 'avatar_${cls.classID}',
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Transform.scale(
            scale: canEnroll ? 1.0 + 0.05 * _pulseController.value : 1.0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: canEnroll ? const LinearGradient(colors: [Color(0xFF00D2FF), Color(0xFF3A7BD5)]) : null,
                boxShadow: canEnroll ? [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 12)] : [],
              ),
              child: CircleAvatar(
                radius: 28,
                backgroundImage: cls.teacherAvatar?.isNotEmpty == true ? NetworkImage(cls.teacherAvatar!) : null,
                child: cls.teacherAvatar?.isEmpty != false ? const Icon(Icons.person, color: Colors.white) : null,
                backgroundColor: Colors.grey.shade300,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _build3DStatus(ClassSearchResult cls) {
    final (color, text, bg) = cls.isFull
        ? (Colors.red, 'Đã đầy', const Color(0xFFFFEBEE))
        : cls.status != 'Published'
        ? (Colors.grey, 'Chưa mở', const Color(0xFFF5F5F5))
        : (Colors.green, 'Mở đăng ký', const Color(0xFFE8F5E9));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: Colors.white, offset: const Offset(-2, -2), blurRadius: 4),
          BoxShadow(color: Colors.black.withOpacity(0.1), offset: const Offset(2, 2), blurRadius: 4),
        ],
      ),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 11)),
    );
  }

// Đổi nút động: Đăng ký / Xem lịch
  Widget _gradientButton(ClassSearchResult cls, bool showViewSchedule) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (showViewSchedule) {
              Get.to(() => const StudentScheduleScreen(), transition: Transition.cupertino);
            } else {
              _handleEnroll(cls);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(colors: [Color(0xFF00D2FF), Color(0xFF3A7BD5)]),
              boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 12, offset: Offset(0, 6))],
            ),
            child: Text(
              showViewSchedule ? 'Xem lịch' : 'Đăng ký',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(children: [Icon(icon, size: 18, color: Colors.grey.shade600), const SizedBox(width: 8), Text(text, style: TextStyle(color: Colors.grey.shade700, fontSize: 13.5))]);
  }

  void _showDetailSheet(ClassSearchResult cls) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF0F4F8),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.all(24),
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              Text(
                cls.title,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF2D3436)),
              ),
              const SizedBox(height: 8),

              // Teacher & Program
              if ((cls.teacherName ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.person_outline, size: 18, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text(cls.teacherName!, style: TextStyle(fontSize: 15, color: Colors.grey.shade700)),
                    ],
                  ),
                ),
              if ((cls.programName ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      Icon(Icons.book_outlined, size: 18, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text(cls.programName!, style: const TextStyle(fontSize: 15, color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),

              const Divider(height: 32),

              // Description
              const Text('Mô tả', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF2D3436))),
              const SizedBox(height: 8),
              Text(cls.description, style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.5)),

              const SizedBox(height: 24),

              // Schedule
              const Text('Lịch học', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF2D3436))),
              const SizedBox(height: 12),
              _detailInfoRow(Icons.calendar_today, 'Ngày bắt đầu', DateFormat('dd/MM/yyyy').format(cls.startDateTime)),
              const SizedBox(height: 8),
              _detailInfoRow(Icons.access_time, 'Thời gian', '${DateFormat('HH:mm').format(cls.startDateTime)} - ${DateFormat('HH:mm').format(cls.endDateTime)}'),
              const SizedBox(height: 8),
              _detailInfoRow(Icons.timelapse, 'Thời lượng', '${cls.durationInMinutes} phút'),

              const SizedBox(height: 24),

              // Capacity & Price
              const Text('Thông tin lớp', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF2D3436))),
              const SizedBox(height: 12),
              _detailInfoRow(Icons.people, 'Sĩ số', '${cls.currentEnrollments}/${cls.capacity} học viên'),
              const SizedBox(height: 8),
              _detailInfoRow(Icons.attach_money, 'Học phí', _formatCurrency(cls.pricePerStudent)),
              const SizedBox(height: 8),
              _detailInfoRow(Icons.info_outline, 'Trạng thái', cls.isFull ? 'Đã đầy' : (cls.status == 'Published' ? 'Còn chỗ' : 'Chưa mở')),

              const SizedBox(height: 32),

              // Enroll button
              if (cls.status == 'Published' && !cls.isFull)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _handleEnroll(cls);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text('Đăng ký ngay', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2D3436))),
            ],
          ),
        ),
      ],
    );
  }

  void _handleEnroll(ClassSearchResult cls) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xác nhận đăng ký', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bạn có chắc muốn đăng ký lớp "${cls.title}"?'),
            const SizedBox(height: 12),
            Text('Học phí: ${_formatCurrency(cls.pricePerStudent)}', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Hủy', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _viewModel.bookClass(cls.classID);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Đăng ký', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() => ListView.builder(itemCount: 5, padding: const EdgeInsets.all(16), itemBuilder: (_, i) => _shimmerCard());
  Widget _buildEmpty(bool filtered) {
    final teacherName = _viewModel.activeTeacherName;
    final programName = _viewModel.activeProgramName;
    String title;
    String subtitle;
    if (filtered) {
      if (teacherName != null && programName != null) {
        title = 'Không có lớp phù hợp';
        subtitle = 'Không tìm thấy lớp của giáo viên "$teacherName" trong chương trình "$programName".';
      } else if (teacherName != null) {
        title = 'Chưa có lớp của giáo viên này';
        subtitle = 'Giáo viên "$teacherName" chưa có lớp hoặc chưa công khai.';
      } else if (programName != null) {
        title = 'Chưa có lớp của chương trình này';
        subtitle = 'Không tìm thấy lớp thuộc chương trình "$programName".';
      } else {
        title = 'Không tìm thấy lớp học';
        subtitle = 'Thử điều chỉnh từ khóa hoặc xóa bộ lọc.';
      }
    } else {
      title = 'Không tìm thấy lớp học';
      subtitle = 'Thử tìm với từ khóa khác.';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 84, color: Colors.grey.shade300),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF2D3436)), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.4), textAlign: TextAlign.center),
            if (filtered) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: _viewModel.clearFilters,
                icon: const Icon(Icons.filter_alt_off, size: 18),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                label: const Text('Xóa bộ lọc'),
              ),
            ],
          ],
        ),
      ),
    );
  }
  Widget _buildError() => const Center(child: Text('Lỗi kết nối', style: TextStyle(color: Colors.red)));
  Widget _shimmerCard() => Container(margin: const EdgeInsets.only(bottom: 20), height: 180, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(28)));
}

// Extension để thêm .onTap()
extension WidgetTap on Widget {
  Widget onTap(VoidCallback callback) => GestureDetector(onTap: callback, child: this);
}