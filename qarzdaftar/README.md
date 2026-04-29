# Qarz Daftarchasi

Qishloq va shahar magazinlarida mijozlarning qarz-to'lovlarini oson kuzatish uchun mobil ilova.

## Asosiy imkoniyatlar

- Telefon raqam orqali Firebase Auth (OTP) — har magazin egasi alohida hisob
- Mijozlar ro'yxati: ism, telefon, manzil, eslatma
- Har bir mijoz uchun qarz/to'lov yozuvlari (mahsulot nomi, summa, sana, qaytarish muddati)
- Mijoz qarzining real-time qoldig'ini avtomatik hisoblash
- Qarz muddati o'tib ketgan mijozlarni ajratib ko'rsatish
- SMS yuborish (mijozning telefon ilovasi orqali) va qo'ng'iroq qilish
- Qaytarish muddati o'tganda lokal bildirishnoma
- Offline ishlaydi (SQLite), keyinchalik Firestore sync qo'shiladi

## Tuzilma

```
lib/
├── main.dart                — Firebase + DB + Notifications init
├── app.dart                 — MaterialApp
├── theme/                   — Ranglar va shriftlar
├── models/                  — Customer, Txn, CustomerBalance
├── data/
│   ├── local/database.dart  — SQLite sxemasi
│   └── repositories/        — DB so'rovlari
├── providers/               — Riverpod state
├── services/                — auth, sms, local notifications
├── screens/
│   ├── splash/              — Auth holatiga qarab yo'naltiradi
│   ├── auth/                — Telefon + OTP
│   ├── home/                — Bosh ekran (balans + mijozlar)
│   ├── customers/           — Mijoz qo'shish, ko'rish
│   ├── transactions/        — Yangi qarz/to'lov
│   └── settings/            — Profil va chiqish
├── widgets/                 — BalanceCard, CustomerTile
└── utils/formatters.dart    — Pul, sana formatlari
```

## Ishga tushirish

### 1. Talablar

- Flutter SDK 3.2+
- Android Studio yoki Xcode
- Firebase CLI: `npm install -g firebase-tools`
- FlutterFire CLI: `dart pub global activate flutterfire_cli`

### 2. Paketlarni o'rnatish

```bash
cd qarzdaftar
flutter pub get
```

### 3. Firebase loyihasini sozlash

```bash
firebase login
flutterfire configure
```

Bu buyruq:
- `lib/firebase_options.dart` faylini avtomatik yaratadi
- Android uchun `android/app/google-services.json`
- iOS uchun `ios/Runner/GoogleService-Info.plist` qo'shadi

Firebase Console (https://console.firebase.google.com) da:
- **Authentication** → **Sign-in method** → **Phone** ni yoqish
- Test raqamlarini qo'shish (development uchun)

### 4. main.dart ni yangilash

`flutterfire configure` `firebase_options.dart` yaratgandan so'ng, `main.dart` ni quyidagicha o'zgartiring:

```dart
import 'firebase_options.dart';

await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

### 5. Android sozlamalari

`android/app/build.gradle` ichida `minSdkVersion 23` (yoki yuqori) bo'lishi kerak (Firebase Auth talabi).

### 6. Ishga tushirish

```bash
flutter run
```

## Keyingi rivojlanish bosqichlari

- [ ] Firestore sync (lokal ↔ bulut)
- [ ] PDF/Excel hisobotlar
- [ ] Diagrammalar (kunlik/oylik tushum)
- [ ] Mahsulotlar bo'limi (narx ro'yxati)
- [ ] Bir nechta xodim qo'shish
- [ ] Qora ro'yxat (qaytarmaydigan mijozlar)
- [ ] Backup va restore
