class TranslationConstants {
  // Private constructor
  TranslationConstants._();

  static const Map<String, String> _translations = {
    // Current Levels
    'Complete Beginner': 'Mới bắt đầu hoàn toàn',
    'Beginner': 'Sơ cấp',
    'Elementary': 'Cơ bản',
    'Pre-Intermediate': 'Trung cấp sơ khởi',
    'Intermediate': 'Trung cấp',
    'Upper-Intermediate': 'Trung cấp cao',
    'Advanced': 'Nâng cao',
    'Near-Native': 'Gần như người bản xứ',

    // Learning Styles
    'Interactive Speaking': 'Giao tiếp tương tác',
    'Audio-Visual Learning': 'Học qua âm thanh và hình ảnh',
    'Conversation Practice': 'Luyện tập hội thoại',
    'Role-Playing': 'Đóng vai',
    'Pronunciation Drilling': 'Luyện phát âm',
    'Story Telling': 'Kể chuyện',
    'Debate & Discussion': 'Tranh luận và thảo luận',
    'Real-life Scenarios': 'Tình huống thực tế',
    'Self-Recording Practice': 'Luyện tập ghi âm tự học',

    // Priority Skills
    'Speaking': 'Kỹ năng nói',
    'Pronunciation': 'Phát âm',
    'Fluency': 'Lưu loát',
    'Vocabulary Building': 'Xây dựng từ vựng',
    'Grammar in Speaking': 'Ngữ pháp trong giao tiếp',
    'Accent Reduction': 'Giảm giọng địa phương',
    'Confidence Building': 'Xây dựng sự tự tin',
    'Natural Expression': 'Diễn đạt tự nhiên',
    'Listening Comprehension': 'Hiểu nghe',

    // Target Timelines
    '1 month - Quick Basics': '1 tháng - Cơ bản nhanh',
    '3 months - Conversation Ready': '3 tháng - Sẵn sàng giao tiếp',
    '6 months - Confident Speaker': '6 tháng - Nói tự tin',
    '1 year - Fluent Communication': '1 năm - Giao tiếp lưu loát',
    '2 years - Advanced Proficiency': '2 năm - Thành thạo nâng cao',
    'No rush - Steady Progress': 'Không vội - Tiến bộ đều đặn',

    // Speaking Challenges
    'Pronunciation Issues': 'Vấn đề phát âm',
    'Grammar Usage': 'Sử dụng ngữ pháp',
    'Limited Vocabulary': 'Từ vựng hạn chế',
    'Speaking Confidence': 'Tự tin khi nói',
    'Accent Problems': 'Vấn đề về giọng',
    'Speaking Too Fast/Slow': 'Nói quá nhanh/chậm',
    'Lack of Natural Flow': 'Thiếu tính tự nhiên',
    'Cultural Expression': 'Diễn đạt văn hóa',
    'Formal vs Informal Speech': 'Lời nói trang trọng vs thân mật',
    'Fear of Making Mistakes': 'Sợ mắc lỗi',

    // Preferred Accents
    'No Preference': 'Không ưu tiên',
    'American English': 'Tiếng Anh Mỹ',
    'British English': 'Tiếng Anh Anh',
    'Australian English': 'Tiếng Anh Úc',
    'Standard Mandarin': 'Tiếng Trung chuẩn',
    'Taiwan Mandarin': 'Tiếng Trung Đài Loan',
    'Standard Japanese': 'Tiếng Nhật chuẩn',
    'Kansai Japanese': 'Tiếng Nhật Kansai',
    'Native-like': 'Giống người bản xứ',
  };


  static String translate(String englishText) {
    return _translations[englishText] ?? englishText;
  }


  static List<String> translateList(List<String> englishList) {
    return englishList.map((item) => translate(item)).toList();
  }


  static String getEnglishValue(String vietnameseText) {
    for (var entry in _translations.entries) {
      if (entry.value == vietnameseText) {
        return entry.key;
      }
    }
    return vietnameseText;
  }
}