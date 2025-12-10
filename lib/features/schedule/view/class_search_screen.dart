import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:flearn_app/core/constants/colors.dart';
import 'package:flearn_app/features/schedule/viewmodel/class_search_viewmodel.dart';
import 'package:flearn_app/features/schedule/model/schedule_model.dart';
import 'package:flearn_app/features/schedule/view/student_schedule_screen.dart';
import '../../auth/viewmodel/user_viewmodel.dart';

class ClassSearchScreen extends StatefulWidget {
  const ClassSearchScreen({super.key});

  @override
  State<ClassSearchScreen> createState() => _ClassSearchScreenState();
}

class _ClassSearchScreenState extends State<ClassSearchScreen> {
  late ClassSearchViewModel _viewModel;
  final TextEditingController _searchController = TextEditingController();
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _viewModel = Get.put(ClassSearchViewModel(service: Get.find()));
    _searchController.addListener(_onSearchChanged);
    _viewModel.clearFilters();
    _viewModel.classes.clear();
    _viewModel.searchClasses(resetPage: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
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

  double _scale(double size) {
    final width = MediaQuery.of(context).size.width;
    if (width > 600) return size * 1.3;
    if (width > 400) return size * 1.1;
    return size;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth * 0.05;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Tìm lớp học',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: _scale(21),
            letterSpacing: -0.3,
          ),
        ),
        actions: const [], // nút filter được dời xuống cạnh ô search
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.grey.shade200,
                  Colors.grey.shade100,
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(horizontalPadding),
          AnimatedSize(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOutCubic,
            child: _showFilters ? _buildFilters(horizontalPadding) : const SizedBox.shrink(),
          ),
          Expanded(child: _buildClassList(horizontalPadding)),
        ],
      ),
    );
  }

  Widget _buildSearchBar(double horizontalPadding) {
    return Obx(() {
      final from = _viewModel.selectedFromDate.value;
      final to = _viewModel.selectedToDate.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  margin: EdgeInsets.fromLTRB(horizontalPadding, _scale(16), horizontalPadding, _scale(8)),
                  padding: EdgeInsets.symmetric(horizontal: _scale(12)),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(_scale(12)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: _scale(15),
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      icon: Icon(CupertinoIcons.search, color: Colors.grey, size: _scale(20)),
                      hintText: 'Tìm tên lớp, giáo viên...',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: _scale(15),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                        icon: Icon(
                          CupertinoIcons.clear_circled_solid,
                          color: Colors.grey.shade400,
                          size: _scale(20),
                        ),
                        onPressed: () => setState(() => _searchController.clear()),
                      )
                          : null, // bỏ icon lịch khỏi ô search
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: _scale(14)),
                    ),
                  ),
                ),
              ),
              SizedBox(width: _scale(10)),
              // Nút chọn ngày (lịch) đặt cạnh ô search, không nằm trong ô search
              Container(
                width: _scale(44),
                height: _scale(44),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(_scale(12)),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: _scale(6),
                      offset: Offset(0, _scale(2)),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(CupertinoIcons.calendar, color: AppColors.primary, size: _scale(22)),
                  tooltip: 'Chọn khoảng ngày',
                  onPressed: _pickDateRange,
                ),
              ),
              SizedBox(width: _scale(8)),
              Container(
                margin: EdgeInsets.only(right: horizontalPadding),
                width: _scale(44),
                height: _scale(44),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(_scale(12)),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: _scale(6),
                      offset: Offset(0, _scale(2)),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    _showFilters ? Icons.tune_rounded : Icons.filter_list_rounded,
                    color: AppColors.textPrimary,
                    size: _scale(22),
                  ),
                  tooltip: 'Bộ lọc',
                  onPressed: () => setState(() => _showFilters = !_showFilters),
                ),
              ),
            ],
          ),
          if (from != null || to != null)
            Padding(
              padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, _scale(8)),
              child: Wrap(
                spacing: _scale(8),
                runSpacing: _scale(4),
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: _scale(12), vertical: _scale(8)),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(_scale(12)),
                      border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(CupertinoIcons.calendar, color: AppColors.primary, size: 16),
                        SizedBox(width: _scale(6)),
                        Text(
                          '${from != null ? DateFormat('dd/MM').format(from) : 'Từ'} - ${to != null ? DateFormat('dd/MM').format(to) : 'Đến'}',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: _scale(13),
                          ),
                        ),
                        SizedBox(width: _scale(6)),
                        GestureDetector(
                          onTap: () => _viewModel.updateFilters(fromDate: null, toDate: null),
                          child: Icon(CupertinoIcons.clear_thick_circled, size: _scale(16), color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    });
  }

  Widget _buildFilters(double horizontalPadding) {
    return Container(
      margin: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, _scale(12)),
      padding: EdgeInsets.all(_scale(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_scale(16)),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: _scale(12),
            offset: Offset(0, _scale(2)),
          ),
        ],
      ),
      child: Obx(() {
        if (_viewModel.isLoadingFilters.value) {
          return SizedBox(
            height: _scale(80),
            child: const Center(
              child: CupertinoActivityIndicator(radius: 15),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bộ lọc',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: _scale(16),
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: _viewModel.clearFilters,
                  child: Text(
                    'Xóa tất cả',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: _scale(14),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: _scale(12)),
            _buildDropdown<Teacher>(
              label: 'Giáo viên',
              value: _viewModel.selectedTeacherId.value,
              items: _viewModel.teachers,
              getValue: (item) => item.teacherId,
              getLabel: (item) => item.fullName,
              onChanged: (v) => _viewModel.updateFilters(teacherId: v ?? ''),
            ),
            SizedBox(height: _scale(12)),
            _buildDropdown<Program>(
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

  Widget _buildDropdown<T>({
    required String label,
    required String value,
    required List<T> items,
    required String Function(T) getValue,
    required String Function(T) getLabel,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: _scale(12)),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(_scale(12)),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        value: value.isEmpty ? '' : value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey.shade600,
            fontSize: _scale(13),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        icon: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: AppColors.primary,
          size: _scale(24),
        ),
        items: [
          DropdownMenuItem(
            value: '',
            child: Text(
              'Tất cả',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: _scale(14),
              ),
            ),
          ),
          ...items.map((item) {
            try {
              final v = getValue(item);
              final text = getLabel(item);
              return DropdownMenuItem<String>(
                value: v,
                child: Text(
                  text,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: _scale(14),
                  ),
                ),
              );
            } catch (err) {
              debugPrint('[Dropdown] error: $err');
              return null;
            }
          }).whereType<DropdownMenuItem<String>>(),
        ],
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildClassList(double horizontalPadding) {
    return RefreshIndicator(
      onRefresh: () => _viewModel.searchClasses(resetPage: true),
      color: AppColors.primary,
      child: Obx(() {
        if (_viewModel.isLoading.value && _viewModel.classes.isEmpty) {
          return const Center(
            child: CupertinoActivityIndicator(radius: 15),
          );
        }

        if (_viewModel.errorMessage.value.isNotEmpty) {
          return _buildErrorState();
        }

        final hasFilter = _viewModel.selectedTeacherId.value.isNotEmpty ||
            _viewModel.selectedProgramId.value.isNotEmpty ||
            _viewModel.searchKeyword.value.isNotEmpty;

        if (_viewModel.classes.isEmpty) {
          return _buildEmptyState(hasFilter);
        }

        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            _scale(8),
            horizontalPadding,
            kBottomNavigationBarHeight + 20,
          ),
          itemCount: _viewModel.classes.length,
          itemBuilder: (context, index) {
            final cls = _viewModel.classes[index];
            return _buildClassCard(cls);
          },
        );
      }),
    );
  }

  Widget _buildClassCard(ClassSearchResult cls) {
    final canEnroll = cls.status == 'Published' && !cls.isFull;

    return GestureDetector(
      onTap: canEnroll ? () => _showDetailSheet(cls) : null,
      child: Container(
        margin: EdgeInsets.only(bottom: _scale(16)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_scale(24)),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: _scale(20),
              offset: Offset(0, _scale(4)),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: _scale(8),
              offset: Offset(0, _scale(2)),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(_scale(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cls.title,
                          style: TextStyle(
                            fontSize: _scale(16),
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if ((cls.teacherName ?? '').isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(top: _scale(6)),
                            child: Row(
                              children: [
                                Icon(
                                  CupertinoIcons.person,
                                  size: _scale(14),
                                  color: Colors.grey.shade600,
                                ),
                                SizedBox(width: _scale(4)),
                                Expanded(
                                  child: Text(
                                    cls.teacherName!,
                                    style: TextStyle(
                                      fontSize: _scale(13),
                                      color: Colors.grey.shade600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(width: _scale(12)),
                  _buildStatusBadge(cls),
                ],
              ),
              if ((cls.programName ?? '').isNotEmpty) ...[
                SizedBox(height: _scale(12)),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: _scale(10),
                    vertical: _scale(4),
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(_scale(8)),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    cls.programName!,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: _scale(12),
                    ),
                  ),
                ),
              ],
              SizedBox(height: _scale(12)),
              Text(
                cls.description,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: _scale(13),
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: _scale(16)),
              _buildInfoRow(
                CupertinoIcons.time,
                '${_formatDateTime(cls.startDateTime)} - ${DateFormat('HH:mm').format(cls.endDateTime)}',
              ),
              SizedBox(height: _scale(8)),
              _buildInfoRow(
                CupertinoIcons.person_2,
                '${cls.currentEnrollments}/${cls.capacity} học viên',
              ),
              SizedBox(height: _scale(16)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatCurrency(cls.pricePerStudent),
                    style: TextStyle(
                      fontSize: _scale(20),
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                  Obx(() {
                    final showView = _viewModel.shouldShowViewScheduleFor(cls.classID);
                    final showButton = canEnroll || showView;
                    if (!showButton) return const SizedBox.shrink();
                    return _buildActionButton(cls, showView);
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ClassSearchResult cls) {
    final (color, text, bgColor) = cls.isFull
        ? (Colors.red, 'Đã đầy', Colors.red.withOpacity(0.1))
        : cls.status != 'Published'
        ? (Colors.grey, 'Chưa mở', Colors.grey.withOpacity(0.1))
        : (Colors.green, 'Mở', Colors.green.withOpacity(0.1));

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _scale(10),
        vertical: _scale(6),
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(_scale(8)),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: _scale(11),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(_scale(6)),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(_scale(8)),
          ),
          child: Icon(
            icon,
            size: _scale(14),
            color: Colors.grey.shade600,
          ),
        ),
        SizedBox(width: _scale(8)),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: _scale(13),
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(ClassSearchResult cls, bool showView) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(_scale(18)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: _scale(8),
            offset: Offset(0, _scale(3)),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(_scale(18)),
          onTap: () {
            if (showView) {
              Get.to(() => const StudentScheduleScreen(), transition: Transition.cupertino);
            } else {
              _handleEnroll(cls);
            }
          },
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: _scale(20),
              vertical: _scale(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  showView ? 'Xem lịch' : 'Đăng ký',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: _scale(13),
                  ),
                ),
                SizedBox(width: _scale(6)),
                Icon(
                  CupertinoIcons.arrow_right,
                  color: Colors.white,
                  size: _scale(14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool hasFilter) {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Container(
          padding: EdgeInsets.all(_scale(24)),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: Icon(
            CupertinoIcons.book,
            size: _scale(64),
            color: Colors.grey.shade300,
          ),
        ),
        SizedBox(height: _scale(20)),
        Text(
          hasFilter ? 'Không tìm thấy lớp học phù hợp' : 'Chưa có lớp học nào',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: _scale(18),
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        SizedBox(height: _scale(8)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: _scale(40)),
          child: Text(
            hasFilter
                ? 'Thử điều chỉnh bộ lọc hoặc từ khóa tìm kiếm'
                : 'Kéo xuống để làm mới',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: _scale(14),
              color: Colors.grey.shade400,
            ),
          ),
        ),
        if (hasFilter) ...[
          SizedBox(height: _scale(24)),
          Center(
            child: OutlinedButton.icon(
              onPressed: _viewModel.clearFilters,
              icon: Icon(Icons.filter_alt_off, size: _scale(18)),
              label: Text('Xóa bộ lọc', style: TextStyle(fontSize: _scale(14))),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: EdgeInsets.symmetric(
                  horizontal: _scale(20),
                  vertical: _scale(12),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_scale(12)),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildErrorState() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
        Icon(
          CupertinoIcons.exclamationmark_triangle,
          size: _scale(64),
          color: Colors.red.shade300,
        ),
        SizedBox(height: _scale(20)),
        Text(
          'Lỗi kết nối',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: _scale(18),
            fontWeight: FontWeight.w600,
            color: Colors.red.shade400,
          ),
        ),
        SizedBox(height: _scale(8)),
        Text(
          'Kéo xuống để thử lại',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: _scale(14),
            color: Colors.grey.shade400,
          ),
        ),
      ],
    );
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
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(_scale(24)),
              ),
            ),
            child: ListView(
              controller: controller,
              padding: EdgeInsets.all(_scale(24)),
              children: [
                Center(
                  child: Container(
                    width: _scale(40),
                    height: _scale(4),
                    margin: EdgeInsets.only(bottom: _scale(20)),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(_scale(2)),
                    ),
                  ),
                ),
                Text(
                  cls.title,
                  style: TextStyle(
                    fontSize: _scale(24),
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: _scale(8)),
                if ((cls.teacherName ?? '').isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(bottom: _scale(4)),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.person,
                          size: _scale(18),
                          color: Colors.grey.shade600,
                        ),
                        SizedBox(width: _scale(8)),
                        Text(
                          cls.teacherName!,
                          style: TextStyle(
                            fontSize: _scale(15),
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                if ((cls.programName ?? '').isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(bottom: _scale(16)),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.book,
                          size: _scale(18),
                          color: Colors.grey.shade600,
                        ),
                        SizedBox(width: _scale(8)),
                        Text(
                          cls.programName!,
                          style: TextStyle(
                            fontSize: _scale(15),
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                Divider(height: _scale(32)),
                Text(
                  'Mô tả',
                  style: TextStyle(
                    fontSize: _scale(16),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: _scale(8)),
                Text(
                  cls.description,
                  style: TextStyle(
                    fontSize: _scale(14),
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: _scale(24)),
                Text(
                  'Lịch học',
                  style: TextStyle(
                    fontSize: _scale(16),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: _scale(12)),
                _detailInfoRow(
                  CupertinoIcons.calendar,
                  'Ngày bắt đầu',
                  DateFormat('dd/MM/yyyy').format(cls.startDateTime),
                ),
                SizedBox(height: _scale(8)),
                _detailInfoRow(
                  CupertinoIcons.time,
                  'Thời gian',
                  '${DateFormat('HH:mm').format(cls.startDateTime)} - ${DateFormat('HH:mm').format(cls.endDateTime)}',
                ),
                SizedBox(height: _scale(8)),
                _detailInfoRow(
                  CupertinoIcons.timer,
                  'Thời lượng',
                  '${cls.durationInMinutes} phút',
                ),
                SizedBox(height: _scale(24)),
                Text(
                  'Thông tin lớp',
                  style: TextStyle(
                    fontSize: _scale(16),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: _scale(12)),
                _detailInfoRow(
                  CupertinoIcons.person_2,
                  'Sĩ số',
                  '${cls.currentEnrollments}/${cls.capacity} học viên',
                ),
                SizedBox(height: _scale(8)),
                _detailInfoRow(
                  CupertinoIcons.money_dollar,
                  'Học phí',
                  _formatCurrency(cls.pricePerStudent),
                ),
                SizedBox(height: _scale(8)),
                _detailInfoRow(
                  CupertinoIcons.info_circle,
                  'Trạng thái',
                  cls.isFull ? 'Đã đầy' : (cls.status == 'Published' ? 'Còn chỗ' : 'Chưa mở'),
                ),
                SizedBox(height: _scale(32)),
                if (cls.status == 'Published' && !cls.isFull)
                  SizedBox(
                    width: double.infinity,
                    height: _scale(56),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _handleEnroll(cls);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(_scale(16)),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Đăng ký ngay',
                        style: TextStyle(
                          fontSize: _scale(16),
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        )
    );
  }

  Widget _detailInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: _scale(20), color: AppColors.primary),
        SizedBox(width: _scale(12)),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: _scale(14),
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: _scale(14),
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _handleEnroll(ClassSearchResult cls) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_scale(20)),
        ),
        title: Text(
          'Xác nhận đăng ký',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: _scale(18),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bạn có chắc muốn đăng ký lớp "${cls.title}"?',
              style: TextStyle(fontSize: _scale(14)),
            ),
            SizedBox(height: _scale(12)),
            Text(
              'Học phí: ${_formatCurrency(cls.pricePerStudent)}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
                fontSize: _scale(14),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Hủy',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: _scale(14),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              String studentId = '';
              try {
                if (Get.isRegistered<UserViewModel>()) {
                  final u = Get.find<UserViewModel>().user.value;
                  studentId = u?.id ?? '';
                }
                if (studentId.isEmpty) {
                  final userMap = GetStorage().read('user') as Map?;
                  studentId = userMap?['userId']?.toString() ?? '';
                }
              } catch (e) {
                debugPrint('[Enroll] read user failed: $e');
              }
              if (studentId.isEmpty) {
                Get.snackbar('Lỗi', 'Không tìm thấy mã học viên. Vui lòng đăng nhập lại.');
                return;
              }
              _viewModel.bookClass(cls.classID);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_scale(12)),
              ),
            ),
            child: Text(
              'Đăng ký',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: _scale(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final initialFrom = _viewModel.selectedFromDate.value ?? now;
    final initialTo = _viewModel.selectedToDate.value ?? now.add(const Duration(days: 7));

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      initialDateRange: DateTimeRange(start: initialFrom, end: initialTo),
      helpText: 'Chọn khoảng ngày',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
      // Thêm dòng này để ẩn icon bút
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );

    if (picked != null) {
      _viewModel.updateFilters(fromDate: picked.start, toDate: picked.end);
    }
  }
}