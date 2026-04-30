import 'app_locale.dart';

class AppStrings {
  AppStrings(this.locale);
  final AppLocale locale;

  String _of(Map<AppLocale, String> map) =>
      map[locale] ?? map[AppLocale.uzLatin] ?? '';

  // App
  String get appName => _of({
        AppLocale.uzLatin: 'Qarz Daftarchasi',
        AppLocale.uzCyrillic: 'Қарз Дафтарчаси',
        AppLocale.russian: 'Тетрадь долгов',
      });

  // Tabs
  String get tabCustomers => _of({
        AppLocale.uzLatin: 'Mijozlar',
        AppLocale.uzCyrillic: 'Мижозлар',
        AppLocale.russian: 'Клиенты',
      });
  String get tabTransactions => _of({
        AppLocale.uzLatin: 'Tranzaksiyalar',
        AppLocale.uzCyrillic: 'Транзаксиялар',
        AppLocale.russian: 'Операции',
      });
  String get tabReports => _of({
        AppLocale.uzLatin: 'Hisobot',
        AppLocale.uzCyrillic: 'Ҳисобот',
        AppLocale.russian: 'Отчёт',
      });
  String get tabSettings => _of({
        AppLocale.uzLatin: 'Sozlamalar',
        AppLocale.uzCyrillic: 'Созламалар',
        AppLocale.russian: 'Настройки',
      });

  // Common buttons
  String get save => _of({
        AppLocale.uzLatin: 'Saqlash',
        AppLocale.uzCyrillic: 'Сақлаш',
        AppLocale.russian: 'Сохранить',
      });
  String get cancel => _of({
        AppLocale.uzLatin: 'Bekor qilish',
        AppLocale.uzCyrillic: 'Бекор қилиш',
        AppLocale.russian: 'Отмена',
      });
  String get delete => _of({
        AppLocale.uzLatin: 'O\'chirish',
        AppLocale.uzCyrillic: 'Ўчириш',
        AppLocale.russian: 'Удалить',
      });
  String get edit => _of({
        AppLocale.uzLatin: 'Tahrirlash',
        AppLocale.uzCyrillic: 'Таҳрирлаш',
        AppLocale.russian: 'Изменить',
      });
  String get add => _of({
        AppLocale.uzLatin: 'Qo\'shish',
        AppLocale.uzCyrillic: 'Қўшиш',
        AppLocale.russian: 'Добавить',
      });
  String get send => _of({
        AppLocale.uzLatin: 'Yuborish',
        AppLocale.uzCyrillic: 'Юбориш',
        AppLocale.russian: 'Отправить',
      });
  String get yes => _of({
        AppLocale.uzLatin: 'Ha',
        AppLocale.uzCyrillic: 'Ҳа',
        AppLocale.russian: 'Да',
      });
  String get no => _of({
        AppLocale.uzLatin: 'Yo\'q',
        AppLocale.uzCyrillic: 'Йўқ',
        AppLocale.russian: 'Нет',
      });
  String get back => _of({
        AppLocale.uzLatin: 'Orqaga',
        AppLocale.uzCyrillic: 'Орқага',
        AppLocale.russian: 'Назад',
      });

  // Customer fields
  String get customerName => _of({
        AppLocale.uzLatin: 'Ism',
        AppLocale.uzCyrillic: 'Исм',
        AppLocale.russian: 'Имя',
      });
  String get phone => _of({
        AppLocale.uzLatin: 'Telefon',
        AppLocale.uzCyrillic: 'Телефон',
        AppLocale.russian: 'Телефон',
      });
  String get address => _of({
        AppLocale.uzLatin: 'Manzil',
        AppLocale.uzCyrillic: 'Манзил',
        AppLocale.russian: 'Адрес',
      });
  String get note => _of({
        AppLocale.uzLatin: 'Eslatma',
        AppLocale.uzCyrillic: 'Эслатма',
        AppLocale.russian: 'Заметка',
      });
  String get addCustomer => _of({
        AppLocale.uzLatin: 'Mijoz qo\'shish',
        AppLocale.uzCyrillic: 'Мижоз қўшиш',
        AppLocale.russian: 'Добавить клиента',
      });
  String get newCustomer => _of({
        AppLocale.uzLatin: 'Yangi mijoz',
        AppLocale.uzCyrillic: 'Янги мижоз',
        AppLocale.russian: 'Новый клиент',
      });
  String get editCustomer => _of({
        AppLocale.uzLatin: 'Mijozni tahrirlash',
        AppLocale.uzCyrillic: 'Мижозни таҳрирлаш',
        AppLocale.russian: 'Редактировать клиента',
      });

  // Transactions
  String get amount => _of({
        AppLocale.uzLatin: 'Summa (so\'m)',
        AppLocale.uzCyrillic: 'Сумма (сўм)',
        AppLocale.russian: 'Сумма (сум)',
      });
  String get product => _of({
        AppLocale.uzLatin: 'Mahsulot',
        AppLocale.uzCyrillic: 'Маҳсулот',
        AppLocale.russian: 'Товар',
      });
  String get quantity => _of({
        AppLocale.uzLatin: 'Soni',
        AppLocale.uzCyrillic: 'Сони',
        AppLocale.russian: 'Кол-во',
      });
  String get gaveDebt => _of({
        AppLocale.uzLatin: 'Qarz berdim',
        AppLocale.uzCyrillic: 'Қарз бердим',
        AppLocale.russian: 'Дал в долг',
      });
  String get receivedPayment => _of({
        AppLocale.uzLatin: 'To\'lov oldim',
        AppLocale.uzCyrillic: 'Тўлов олдим',
        AppLocale.russian: 'Получил оплату',
      });
  String get dueDate => _of({
        AppLocale.uzLatin: 'Qaytarish muddati',
        AppLocale.uzCyrillic: 'Қайтариш муддати',
        AppLocale.russian: 'Срок возврата',
      });
  String get newRecord => _of({
        AppLocale.uzLatin: 'Yangi yozuv',
        AppLocale.uzCyrillic: 'Янги ёзув',
        AppLocale.russian: 'Новая запись',
      });
  String get addRecord => _of({
        AppLocale.uzLatin: 'Yozuv qo\'shish',
        AppLocale.uzCyrillic: 'Ёзув қўшиш',
        AppLocale.russian: 'Добавить запись',
      });

  // Status
  String get hasDebt => _of({
        AppLocale.uzLatin: 'Qarzdor',
        AppLocale.uzCyrillic: 'Қарздор',
        AppLocale.russian: 'Должник',
      });
  String get overdue => _of({
        AppLocale.uzLatin: 'Muddati o\'tdi',
        AppLocale.uzCyrillic: 'Муддати ўтди',
        AppLocale.russian: 'Просрочено',
      });
  String get paidOff => _of({
        AppLocale.uzLatin: 'Qarzi yo\'q',
        AppLocale.uzCyrillic: 'Қарзи йўқ',
        AppLocale.russian: 'Без долга',
      });
  String get all => _of({
        AppLocale.uzLatin: 'Hammasi',
        AppLocale.uzCyrillic: 'Ҳаммаси',
        AppLocale.russian: 'Все',
      });

  // Empty states
  String get noCustomersYet => _of({
        AppLocale.uzLatin: 'Hozircha mijoz yo\'q',
        AppLocale.uzCyrillic: 'Ҳозирча мижоз йўқ',
        AppLocale.russian: 'Пока нет клиентов',
      });
  String get addCustomerHint => _of({
        AppLocale.uzLatin: 'Pastdagi tugma orqali yangi mijoz qo\'shing',
        AppLocale.uzCyrillic: 'Пастдаги тугма орқали янги мижоз қўшинг',
        AppLocale.russian: 'Нажмите кнопку ниже, чтобы добавить клиента',
      });
  String get nothingFound => _of({
        AppLocale.uzLatin: 'Hech narsa topilmadi',
        AppLocale.uzCyrillic: 'Ҳеч нарса топилмади',
        AppLocale.russian: 'Ничего не найдено',
      });

  // Search
  String get searchCustomer => _of({
        AppLocale.uzLatin: 'Mijoz qidirish',
        AppLocale.uzCyrillic: 'Мижоз қидириш',
        AppLocale.russian: 'Поиск клиента',
      });

  // Balance card
  String get totalDebtTitle => _of({
        AppLocale.uzLatin: 'Olinishi kerak (jami qarz)',
        AppLocale.uzCyrillic: 'Олиниши керак (жами қарз)',
        AppLocale.russian: 'К получению (всего долгов)',
      });
  String get totalGiven => _of({
        AppLocale.uzLatin: 'Jami berilgan',
        AppLocale.uzCyrillic: 'Жами берилган',
        AppLocale.russian: 'Всего выдано',
      });
  String get totalReturned => _of({
        AppLocale.uzLatin: 'Qaytarilgan',
        AppLocale.uzCyrillic: 'Қайтарилган',
        AppLocale.russian: 'Возвращено',
      });

  // Settings items
  String get shopInfo => _of({
        AppLocale.uzLatin: 'Do\'kon ma\'lumotlari',
        AppLocale.uzCyrillic: 'Дўкон маълумотлари',
        AppLocale.russian: 'Информация о магазине',
      });
  String get productsAndPrices => _of({
        AppLocale.uzLatin: 'Mahsulotlar va narxlar',
        AppLocale.uzCyrillic: 'Маҳсулотлар ва нархлар',
        AppLocale.russian: 'Товары и цены',
      });
  String get autoReminderTitle => _of({
        AppLocale.uzLatin: 'Avtomatik eslatma bildirishnoma',
        AppLocale.uzCyrillic: 'Автоматик эслатма билдиришнома',
        AppLocale.russian: 'Автоматическое напоминание',
      });
  String get themeMenu => _of({
        AppLocale.uzLatin: 'Tema',
        AppLocale.uzCyrillic: 'Тема',
        AppLocale.russian: 'Тема',
      });
  String get languageMenu => _of({
        AppLocale.uzLatin: 'Til',
        AppLocale.uzCyrillic: 'Тил',
        AppLocale.russian: 'Язык',
      });
  String get exportExcel => _of({
        AppLocale.uzLatin: 'Excel\'ga eksport',
        AppLocale.uzCyrillic: 'Excelга экспорт',
        AppLocale.russian: 'Экспорт в Excel',
      });
  String get exportPdf => _of({
        AppLocale.uzLatin: 'PDF\'ga eksport',
        AppLocale.uzCyrillic: 'PDFга экспорт',
        AppLocale.russian: 'Экспорт в PDF',
      });
  String get backupRestore => _of({
        AppLocale.uzLatin: 'Zaxira va qaytarish',
        AppLocale.uzCyrillic: 'Захира ва қайтариш',
        AppLocale.russian: 'Резервная копия',
      });
  String get changePin => _of({
        AppLocale.uzLatin: 'PIN-kodni o\'zgartirish',
        AppLocale.uzCyrillic: 'PIN-кодни ўзгартириш',
        AppLocale.russian: 'Изменить PIN-код',
      });
  String get logout => _of({
        AppLocale.uzLatin: 'Chiqish (qulflash)',
        AppLocale.uzCyrillic: 'Чиқиш (қулфлаш)',
        AppLocale.russian: 'Выход (заблокировать)',
      });

  // Theme labels
  String get themeSystem => _of({
        AppLocale.uzLatin: 'Tizim sozlamasi',
        AppLocale.uzCyrillic: 'Тизим созламаси',
        AppLocale.russian: 'Системная',
      });
  String get themeLight => _of({
        AppLocale.uzLatin: 'Kunduzgi',
        AppLocale.uzCyrillic: 'Кундузги',
        AppLocale.russian: 'Светлая',
      });
  String get themeDark => _of({
        AppLocale.uzLatin: 'Tungi',
        AppLocale.uzCyrillic: 'Тунги',
        AppLocale.russian: 'Тёмная',
      });

  // Reports
  String get reportLast30Days => _of({
        AppLocale.uzLatin: 'Oxirgi 30 kun',
        AppLocale.uzCyrillic: 'Охирги 30 кун',
        AppLocale.russian: 'Последние 30 дней',
      });
  String get topDebtors => _of({
        AppLocale.uzLatin: 'Eng katta qarzdor 5 mijoz',
        AppLocale.uzCyrillic: 'Энг катта қарздор 5 мижоз',
        AppLocale.russian: 'Топ-5 должников',
      });

  // Backup
  String get exportBackup => _of({
        AppLocale.uzLatin: 'Zaxira faylini yaratish',
        AppLocale.uzCyrillic: 'Захира файлини яратиш',
        AppLocale.russian: 'Создать резервную копию',
      });
  String get importBackup => _of({
        AppLocale.uzLatin: 'Zaxiradan tiklash',
        AppLocale.uzCyrillic: 'Захирадан тиклаш',
        AppLocale.russian: 'Восстановить из копии',
      });
  String get backupHelp => _of({
        AppLocale.uzLatin: 'Telefon yo\'qolsa ham ma\'lumotni saqlash uchun fayl yaratiladi va Telegram\'ga yoki o\'zingizga jo\'natasiz',
        AppLocale.uzCyrillic: 'Телефон йўқолса ҳам маълумотни сақлаш учун файл яратилади ва Telegramга ёки ўзингизга жўнатасиз',
        AppLocale.russian: 'Создаёт файл для сохранения данных. Отправьте его в Telegram или себе на email.',
      });
}
