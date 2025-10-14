import 'dart:async';

import 'package:flearn_app/features/survey/view/survey_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../../core/constants/colors.dart';
import '../viewmodel/otp_viewmodel.dart';
import 'home_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;

  const OtpVerificationScreen({super.key, required this.email});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = [];
  final List<FocusNode> _focusNodes = [];
  late final OtpViewModel otpViewModel;

  int _secondsLeft = 60;
  Timer? _timer;
  bool _canResend = false;



  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 6; i++) {
      _controllers.add(TextEditingController());
      _focusNodes.add(FocusNode());
    }
    otpViewModel = Get.put(OtpViewModel(Get.find()), permanent: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _focusNodes.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) _focusNodes[0].requestFocus();
        });
      }
    });
    _startTimer();
  }

  void _startTimer() {
    setState(() {
      _secondsLeft = 60;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() {
          _secondsLeft--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }


  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    Get.delete<OtpViewModel>();
    _timer?.cancel();
    super.dispose();
  }

  String get otpCode => _controllers.map((controller) => controller.text).join();

  void _onCodeChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    } else {
      _focusNodes[index].unfocus();
    }
  }

  void _onTap(int index) {
    if (mounted && index < _focusNodes.length) {
      _focusNodes[index].requestFocus();
      _controllers[index].selection = TextSelection.fromPosition(
        TextPosition(offset: _controllers[index].text.length),
      );
    }
  }

  Future<void> _verifyOtp() async {
    if (otpCode.length != 6) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Vui lòng nhập đầy đủ mã OTP"),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    FocusScope.of(context).unfocus();
    await otpViewModel.confirmEmail(otpCode);
    if (!mounted) return;

    final surveyStatus = await otpViewModel.checkSurveyRequired();
    if (surveyStatus != null) {
      final box = GetStorage();
      box.write('surveyStatus', surveyStatus);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Xác thực email thành công!"),
        backgroundColor: Colors.green,
      ),
    );




    if (!mounted) return;

    if (surveyStatus == null) {

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
      );
      return;
    }

    if (surveyStatus['assessmentRequired'] == true) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const SurveyScreen()),
            (route) => false,
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
      );
    }
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;
    try {
      final otpViewModel = Get.find<OtpViewModel>();
      await otpViewModel.resendOtp(widget.email);
      _startTimer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đã gửi lại mã OTP")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gửi lại mã thất bại: $e")),
        );
      }
    }
  }

  void _clearAll() {
    for (var controller in _controllers) {
      controller.clear();
    }
    if (mounted && _focusNodes.isNotEmpty) {
      _focusNodes[0].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTabletOrLarger = size.width >= 600;
    final fontScale = isTabletOrLarger ? 1.2 : 1.0;
    final padding = size.width * 0.06; // 6% of screen width
    final fieldSize = size.width * 0.12; // Scale OTP field size

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(fontScale),
        body: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  children: [
                    SizedBox(height: 40 * fontScale),
                    _buildIcon(size, fontScale),
                    SizedBox(height: 32 * fontScale),
                    _buildTitle(fontScale),
                    SizedBox(height: 8 * fontScale),
                    _buildSubtitle(fontScale),
                    SizedBox(height: 40 * fontScale),
                    _buildOtpInput(fieldSize, fontScale),
                    SizedBox(height: 40 * fontScale),
                    _buildVerifyButton(fontScale),
                    SizedBox(height: 20 * fontScale),
                    _buildActionButtons(fontScale),
                    SizedBox(height: 40 * fontScale),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(double fontScale) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(Icons.arrow_back, color: Colors.black, size: 24 * fontScale),
      ),
      title: Text(
        "Xác thực Email",
        style: TextStyle(color: Colors.black, fontSize: 20 * fontScale),
      ),
    );
  }

  Widget _buildIcon(Size size, double fontScale) {
    final iconSize = size.width * 0.2; // 20% of screen width
    return Container(
      width: iconSize.clamp(60, 100),
      height: iconSize.clamp(60, 100),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(iconSize / 2),
      ),
      child: Icon(
        Icons.email_outlined,
        size: iconSize * 0.5,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildTitle(double fontScale) {
    return Text(
      "Xác thực Email",
      style: TextStyle(
        fontSize: 24 * fontScale,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSubtitle(double fontScale) {
    return Text(
      "Nhập mã 6 số đã gửi đến\n${widget.email}",
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 16 * fontScale,
        color: Colors.grey[600],
      ),
    );
  }

  Widget _buildOtpInput(double fieldSize, double fontScale) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: fieldSize * 0.2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(6, (index) => _buildOtpField(index, fieldSize, fontScale)),
      ),
    );
  }

  Widget _buildOtpField(int index, double fieldSize, double fontScale) {
    return Container(
      width: fieldSize.clamp(40, 60), // Scale between 40 and 60
      height: fieldSize.clamp(48, 68), // Scale between 48 and 68
      margin: EdgeInsets.symmetric(horizontal: fieldSize * 0.05),
      decoration: BoxDecoration(
        border: Border.all(
          color: _focusNodes[index].hasFocus
              ? AppColors.primary
              : _controllers[index].text.isNotEmpty
              ? AppColors.primary.withOpacity(0.5)
              : Colors.grey[300]!,
          width: _focusNodes[index].hasFocus ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
        color: _focusNodes[index].hasFocus ? AppColors.primary.withOpacity(0.05) : Colors.white,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onTap(index),
          borderRadius: BorderRadius.circular(8),
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            style: TextStyle(fontSize: 18 * fontScale, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              border: InputBorder.none,
              counterText: '',
              contentPadding: EdgeInsets.zero,
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) => setState(() => _onCodeChanged(value, index)),
            onTap: () => _onTap(index),
          ),
        ),
      ),
    );
  }

  Widget _buildVerifyButton(double fontScale) {
    return GetX<OtpViewModel>(
      builder: (controller) => SizedBox(
        width: double.infinity,
        height: 50 * fontScale,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: controller.isLoading.value ? null : _verifyOtp,
          child: controller.isLoading.value
              ? SizedBox(
            width: 20 * fontScale,
            height: 20 * fontScale,
            child: const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          )
              : Text(
            "Xác thực",
            style: TextStyle(
              fontSize: 16 * fontScale,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(double fontScale) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        TextButton(
          onPressed: _clearAll,
          child: Text(
            "Xóa tất cả",
            style: TextStyle(color: Colors.grey[600], fontSize: 14 * fontScale),
          ),
        ),
        TextButton(
          onPressed: _resendOtp,
          child: Text(
            "Gửi lại mã (${_secondsLeft}s)",
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 14 * fontScale,
            ),
          ),
        ),
      ],
    );
  }
}