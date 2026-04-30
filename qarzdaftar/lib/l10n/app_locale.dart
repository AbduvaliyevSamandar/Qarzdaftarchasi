enum AppLocale {
  uzLatin('uz_Latn', 'O\'zbekcha'),
  uzCyrillic('uz_Cyrl', 'Ўзбекча'),
  russian('ru', 'Русский');

  const AppLocale(this.code, this.label);

  final String code;
  final String label;

  static AppLocale fromCode(String? code) {
    return AppLocale.values.firstWhere(
      (l) => l.code == code,
      orElse: () => AppLocale.uzLatin,
    );
  }
}
