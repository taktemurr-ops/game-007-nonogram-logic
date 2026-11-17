class NonogramText {
  const NonogramText(this.language);
  final String language;
  static const supported = ['tr', 'en', 'ar'];
  static const _strings = <String, Map<String, String>>{
    'title': {'tr': 'Nonogram Mantık', 'en': 'Nonogram Logic', 'ar': 'لغز نونوغرام'},
    'play': {'tr': 'Oyna', 'en': 'Play', 'ar': 'العب'},
    'daily': {'tr': 'Günlük bulmaca', 'en': 'Daily puzzle', 'ar': 'اللغز اليومي'},
    'zen': {'tr': 'Rahat mod', 'en': 'Zen mode', 'ar': 'الوضع الهادئ'},
    'timed': {'tr': 'Zamana karşı', 'en': 'Time attack', 'ar': 'تحدي الوقت'},
    'levels': {'tr': 'Bölümler', 'en': 'Levels', 'ar': 'المستويات'},
    'settings': {'tr': 'Ayarlar', 'en': 'Settings', 'ar': 'الإعدادات'},
    'progress': {'tr': 'İlerleme', 'en': 'Progress', 'ar': 'التقدم'},
    'continue': {'tr': 'Devam et', 'en': 'Continue', 'ar': 'متابعة'},
    'reset': {'tr': 'Yeniden başlat', 'en': 'Restart', 'ar': 'إعادة'},
    'undo': {'tr': 'Geri al', 'en': 'Undo', 'ar': 'تراجع'},
    'redo': {'tr': 'Yinele', 'en': 'Redo', 'ar': 'إعادة الحركة'},
    'hint': {'tr': 'Ücretsiz ipucu', 'en': 'Free hint', 'ar': 'تلميح مجاني'},
    'filled': {'tr': 'Doldur', 'en': 'Fill', 'ar': 'املأ'},
    'empty': {'tr': 'Boş işaretle', 'en': 'Mark empty', 'ar': 'علّم فارغ'},
    'erase': {'tr': 'Sil', 'en': 'Erase', 'ar': 'امسح'},
    'solved': {'tr': 'Bulmaca çözüldü!', 'en': 'Puzzle solved!', 'ar': 'تم حل اللغز!'},
    'next': {'tr': 'Sonraki bölüm', 'en': 'Next level', 'ar': 'المستوى التالي'},
    'back': {'tr': 'Geri', 'en': 'Back', 'ar': 'رجوع'},
    'help': {'tr': 'Satır ve sütun ipuçlarını kullan.', 'en': 'Follow the row and column clues.', 'ar': 'اتبع أرقام الصفوف والأعمدة.'},
    'privacy': {'tr': 'Veriler yalnızca cihazda tutulur. Reklam veya hesap yoktur.', 'en': 'Data stays on this device. No ads or account.', 'ar': 'البيانات تبقى على الجهاز. لا إعلانات أو حساب.'},
    'delete': {'tr': 'Yerel verilerimi sil', 'en': 'Delete my local data', 'ar': 'حذف بياناتي'},
    'confirm': {'tr': 'Emin misiniz?', 'en': 'Are you sure?', 'ar': 'هل أنت متأكد؟'},
    'cancel': {'tr': 'İptal', 'en': 'Cancel', 'ar': 'إلغاء'},
    'yes': {'tr': 'Evet', 'en': 'Yes', 'ar': 'نعم'},
    'language': {'tr': 'Dil', 'en': 'Language', 'ar': 'اللغة'},
    'reduced': {'tr': 'Animasyonu azalt', 'en': 'Reduce motion', 'ar': 'تقليل الحركة'},
    'dark': {'tr': 'Koyu tema', 'en': 'Dark theme', 'ar': 'الوضع الداكن'},
    'locked': {'tr': 'Kilitli', 'en': 'Locked', 'ar': 'مغلق'},
    'pause': {'tr': 'Duraklat', 'en': 'Pause', 'ar': 'إيقاف مؤقت'},
    'resume': {'tr': 'Devam', 'en': 'Resume', 'ar': 'استئناف'},
    'moves': {'tr': 'Hamle', 'en': 'Moves', 'ar': 'حركات'},
  };
  String operator [](String key) =>
      _strings[key]?[language] ?? _strings[key]?['en'] ?? key;
}
