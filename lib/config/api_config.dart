class ApiConfig {
  static const String baseUrl = "https://f-learn.app/api";
  static const String loginUrl = "/Auth/login";
  static const String registerUrl = "/Auth/register";
  static const String confirmEmailUrl = "/Auth/verify-otp";
  static const String profileUrl = "/Auth/me";
  static const String loginGoogle = "/Auth/google";
  static const String resendOtpUrl = "/Auth/resend-otp";
  static const String forgotPassword = "/Auth/forgot-password";
  static const String resetPassword = "/Auth/reset-password";

  static const String checkRequired = "/VoiceAssessment/check-required";

  static const String getLanguages = "/languages";
  static const String getTopic = "/conversation/topics";


  static const String getGoal = "/goals";

  static String voiceAssessmentStart(String languageId, int goalId) =>
      "/VoiceAssessment/start/$languageId?goalId=$goalId";

  static const String acceptVoiceAssessment = "/VoiceAssessment/accept-voice-assessment";
  static const String rejectVoiceAssessment = "/VoiceAssessment/reject-voice-assessment";


  static const String getCourse = "/courses";



}