import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flearn_app/core/constants/colors.dart';
import 'package:flearn_app/features/schedule/viewmodel/class_search_viewmodel.dart';
import 'package:flearn_app/features/schedule/model/schedule_model.dart';

class ClassSearchScreen extends StatefulWidget {
  const ClassSearchScreen({super.key});

  @override
  State<ClassSearchScreen> createState() => _ClassSearchScreenState();
}

class _ClassSearchScreenState extends State<ClassSearchScreen>
    with TickerProviderStateMixin {
  late ClassSearchViewModel _viewModel;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = Get.put(ClassSearchViewModel(service: Get.find()));
    _searchController.addListener(() {
      _viewModel.updateFilters(keyword: _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    final formatter =
    NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
    return formatter.format(amount);
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFAFF), // hồng phấn nhẹ như ảnh
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Tìm kiếm lớp học',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 19,
            color: Color(0xFF1A1A1A),
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Thanh search glassmorphism
              _buildModernSearchBar(),

              // Danh sách lớp
              Expanded(
                child: Obx(() {
                  if (_viewModel.isLoading.value) return _buildShimmer();
                  if (_viewModel.errorMessage.value.isNotEmpty) {
                    return _buildErrorState();
                  }
                  if (_viewModel.classes.isEmpty) return _buildEmptyState();

                  return RefreshIndicator(
                    onRefresh: () => _viewModel.searchClasses(resetPage: true),
                    color: AppColors.primary,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _viewModel.classes.length,
                      itemBuilder: (context, index) {
                        return _buildClassCard(_viewModel.classes[index]);
                      },
                    ),
                  );
                }),
              ),
            ],
          ),



        ],
      ),
    );
  }

  // ================= SEARCH BAR =================
  Widget _buildModernSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.78),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: AppColors.primary, size: 26),
                const SizedBox(width: 12),

                // Ô tìm kiếm
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Color(0xFF2D3436), fontSize: 16),
                    decoration: const InputDecoration(
                      hintText: 'Tìm kiếm khóa học...',
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // NÚT FILTER VUÔNG BO GÓC – ĐẸP NHƯ APP CHÍNH CHỦ
                GestureDetector(
                  onTap: _showFilterBottomSheet,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16), // Vuông bo góc 16px
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= CARD ĐẸP NHƯ ẢNH =================
  Widget _buildClassCard(ClassSearchResult cls) {
    final bool canEnroll = cls.status == 'Published' && !cls.isFull;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        color: const Color(0xFFFFF5FA), // hồng phấn đúng như ảnh
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: canEnroll ? () => _showDetailSheet(cls) : null,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.grey.shade200,
                      child: const Icon(Icons.person, color: Colors.grey),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cls.title,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          Text(
                            cls.teacherName ?? 'Chưa có giáo viên',
                            style: TextStyle(
                              fontSize: 13.5,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Tag "Mở đăng ký"
                    if (canEnroll)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Mở đăng ký',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // Nâng tầm kỹ năng + ngày giờ
                Row(
                  children: [
                    const Icon(Icons.trending_up_rounded,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Nâng tầm kỹ năng',
                      style: TextStyle(color: AppColors.primary, fontSize: 13),
                    ),
                    const Spacer(),
                    Text(
                      '${_formatDateTime(cls.startDateTime)} - ${DateFormat('HH:mm').format(cls.endDateTime)}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    Icon(Icons.people_outline, size: 18, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text(
                      '${cls.currentEnrollments}/${cls.capacity}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Giá + nút đăng ký
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatCurrency(cls.pricePerStudent),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    if (canEnroll)
                      ElevatedButton(
                        onPressed: () => _handleEnroll(cls),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 28, vertical: 12),
                        ),
                        child: const Text(
                          'Đăng ký',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= FILTER BOTTOM SHEET =================
  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Bộ lọc', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text('Xóa tất cả', style: TextStyle(color: AppColors.primary)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Obx(() {
                  if (_viewModel.isLoadingFilters.value) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return Column(
                    children: [
                      _buildDropdown(
                        label: 'Giáo viên',
                        value: _viewModel.selectedTeacherId.value.isEmpty
                            ? null
                            : _viewModel.selectedTeacherId.value,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Tất cả giáo viên')),
                          ..._viewModel.teachers.map((t) => DropdownMenuItem(
                            value: t.teacherId,
                            child: Text(t.fullName),
                          )),
                        ],
                        onChanged: (v) {
                          _viewModel.updateFilters(teacherId: v ?? '');
                          Get.back();
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildDropdown(
                        label: 'Chương trình',
                        value: _viewModel.selectedProgramId.value.isEmpty
                            ? null
                            : _viewModel.selectedProgramId.value,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Tất cả chương trình')),
                          ..._viewModel.programs.map((p) => DropdownMenuItem(
                            value: p.programId,
                            child: Text(p.name),
                          )),
                        ],
                        onChanged: (v) {
                          _viewModel.updateFilters(programId: v ?? '');
                          Get.back();
                        },
                      ),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    dynamic value,
    required List<DropdownMenuItem> items,
    required Function(dynamic) onChanged,
  }) {
    return DropdownButtonFormField(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      items: items,
      onChanged: onChanged,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 28),
    );
  }

  // ================= CÁC TRẠNG THÁI =================
  Widget _buildShimmer() => ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: 6,
    itemBuilder: (_, __) => Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: 180,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(24),
      ),
    ),
  );

  Widget _buildErrorState() => Center(
    child: Text(
      _viewModel.errorMessage.value,
      style: const TextStyle(color: Colors.red),
      textAlign: TextAlign.center,
    ),
  );

  Widget _buildEmptyState() => const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.search_off_rounded, size: 80, color: Colors.grey),
        SizedBox(height: 16),
        Text('Không tìm thấy lớp học nào', style: TextStyle(fontSize: 16)),
      ],
    ),
  );

  // ================= ĐĂNG KÝ =================
  void _handleEnroll(ClassSearchResult cls) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xác nhận đăng ký'),
        content: Text('Bạn muốn đăng ký lớp "${cls.title}"?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _viewModel.bookClass(cls.classID);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Đăng ký'),
          ),
        ],
      ),
    );
  }

  void _showDetailSheet(ClassSearchResult cls) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.6,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Thanh kéo
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cls.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (cls.teacherName != null)
                        Text('Giáo viên: ${cls.teacherName}', style: TextStyle(color: Colors.grey.shade600)),
                      const SizedBox(height: 16),
                      Text(cls.description, style: const TextStyle(fontSize: 15, height: 1.6)),
                      const SizedBox(height: 24),
                      _infoRow(Icons.calendar_today, 'Ngày học', DateFormat('dd/MM/yyyy').format(cls.startDateTime)),
                      _infoRow(Icons.access_time, 'Giờ học', '${DateFormat('HH:mm').format(cls.startDateTime)} - ${DateFormat('HH:mm').format(cls.endDateTime)}'),
                      _infoRow(Icons.people, 'Sĩ số', '${cls.currentEnrollments}/${cls.capacity}'),
                      _infoRow(Icons.monetization_on, 'Học phí', _formatCurrency(cls.pricePerStudent)),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _handleEnroll(cls);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Đăng ký lớp học', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }}