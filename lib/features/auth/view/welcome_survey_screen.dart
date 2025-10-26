import 'package:flutter/material.dart';
import 'package:flearn_app/features/survey/view/language_screen.dart';
import '../../../core/constants/colors.dart';

class WelcomeSurveyScreen extends StatelessWidget {
  const WelcomeSurveyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              Image.asset(
                'assets/images/logoa3.gif', // Using the GIF
                height: size.width * 0.65,
                fit: BoxFit.contain,
              ),
              const Spacer(flex: 1),
              Text(
                "Chào mừng bạn đến với F-Learn!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: (size.width * 0.065).clamp(26.0, 32.0),
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Montserrat', // A modern font
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Để có trải nghiệm học tốt nhất, hãy cùng làm một bài khảo sát ngắn để cá nhân hóa lộ trình cho bạn nhé.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: (size.width * 0.04).clamp(15.0, 17.0),
                  height: 1.5,
                ),
              ),
              const Spacer(flex: 2),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LanguageScreen(),
                    ),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, // Blue button
                  foregroundColor: Colors.white, // White text
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  'Bắt đầu khảo sát',
                  style: TextStyle(
                    fontSize: (size.width * 0.045).clamp(16.0, 18.0),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
