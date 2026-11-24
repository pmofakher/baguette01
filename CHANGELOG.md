# تاریخچه تغییرات باگت (Baguette Changelog)

---

## [0.3.4] - 2026-11-24

### فارسی (Persian)
- **جملات رندوم در صفحه ورود (Splash):** نمایش تصادفی یکی از ۱۷ جمله مالی/طنز زیر لودینگ در هر بار ورود به برنامه.
- **خلوت‌تر شدن صفحه اصلی:** حذف کامل باکس نقل‌قول از صفحه خانه (`HomePage`).

### English
- **Random Splash Screen Quotes:** Displays one of 17 witty financial quotes randomly on the splash screen before entering the app.
- **Cleaner Home Screen:** Removed the quote card from `HomePage`.

---

## [0.3.3] - 2026-11-24

### فارسی (Persian)
- **بازطراحی کامل لیست دسته‌های خرج و درآمد:** جایگزینی دسته‌های پیش‌فرض با ۲۳ دسته خرج جدید و ۹ دسته درآمد جدید، مرتب‌شده از دسته‌های عمومی‌تر و پرکاربردتر در ابتدا و مهاجرت امن دیتابیس (نسخه ۳).
- **مرتب‌سازی هوشمند دسته‌ها بر اساس تکرار انتخاب:** افزایش خودکار اولویت دسته‌هایی که کاربر بیشتر در تراکنش‌ها انتخاب می‌کند در منوی تعیین دسته و فرم ثبت تراکنش.
- **برچسب‌های «واجب / انتخابی / لذت از زندگی»:** تغییر برچسب «غیرضروری» به «انتخابی»، نمایش برچسب روی ردیف خرج‌ها با امکان تغییر سریع یک‌لمسی، و افزودن فیلتر بر اساس برچسب در صفحه تراکنش‌ها و نمودار دسته‌های صفحه گزارش همراه با کارت تحلیل اهمیت خرج.

### English
- **Revamped Expense & Income Categories:** Replaced default categories with 23 expense and 9 income categories ordered from general/everyday items first, with safe DB v3 migration.
- **Frequency-Based Category Ordering:** Categories dynamically sort higher in pickers and transaction forms based on how often the user selects them.
- **Necessity Tags & Filters (واجب / انتخابی / لذت از زندگی):** Renamed "غیرضروری" to "انتخابی", added quick 1-tap tag badges on expense items and details, and added necessity breakdown & interactive filtering in Transactions and Reports.

---

## [0.3.1] - 2026-11-24

### فارسی (Persian)
- **آیکون رسمی باگت (Adaptive Icon):** طراحی و جایگزینی آیکون پیش‌فرض اپلیکیشن با آیکون تطبیقی مدرن اندروید شامل پس‌زمینه کرم گرم و لایه رویی شفاف در محدوده امن (Safe Zone) بدون بریدگی در ماسک‌های دایره و Squircle.
- **پشتیبانی از آیکون تک‌رنگ (Material You):** افزودن لایه Monochrome در `mipmap-anydpi-v26` برای هماهنگی آیکون با تم والپیپر در اندروید ۱۳ و بالاتر.
- **نسخه Legacy و منابع `assets/icons`:** تولید تمام سایزهای `mipmap` و `drawable` با `flutter_launcher_icons` و تنظیم نسخه `0.3.1+4`.

### English
- **Modern Adaptive Launcher Icon:** Replaced the default Flutter icon with a modern Android Adaptive Icon featuring a warm cream background and a clean foreground centered in the launcher safe zone to prevent clipping on circle/squircle masks.
- **Material You Monochrome Icon:** Added a monochrome layer (`ic_launcher_monochrome`) for Android 13+ themed icon support.
- **Legacy Icon & Assets:** Generated all `mipmap-*` and `drawable-*` resources via `flutter_launcher_icons` and bumped app version to `0.3.1+4`.

---

## [0.3.0] - 2026-11-22

### فارسی (Persian)
- **تشخیص هوشمند بلوبانک:** شناسایی دقیق پیامک‌های بلوبانک با واژه «بلو» جهت ورود خودکار تراکنش‌ها بدون خطا.
- **پشتیبانی سراسری از بانک‌های کشور:** افزودن ده‌ها بانک و نئوبانک ایرانی (ویپاد، آبانک، توبانک، باجت، ملی، ملت، سامان و...) برای استخراج خودکار مبالغ و کارت‌ها.
- **انتقال بین حساب‌ها (این جیب به اون جیب):** ثبت انتقال پول میان حساب‌های خود شخص بدون تاثیر در مخارج و درآمدهای ماهانه و حفظ کامل لاگ و بالانس هر حساب.
- **تشخیص خودکار جفت‌پیامک‌های انتقال:** تجمیع هوشمند دو پیامک واریز و برداشت هم‌مبلغ در یک تراکنش انتقال داخلی.
- **دکمه تبدیل دستی به انتقال:** امکان تبدیل هر تراکنش به «این جیب به اون جیب» با یک لمس در صفحه جزئیات تراکنش.
- **دکمه «+ دسته جدید» در منوی سریع:** ساخت فوری دسته جدید با نام و ایموجی دلخواه از درون شیت انتخاب دسته و اختصاص آنی به تراکنش.
- **دکمه متنی «وارد کردن تراکنش از sms ها»:** اضافه شدن دکمه اختصاصی در بالای صفحه تراکنش‌ها برای استعلام و ثبت سریع پیامک‌ها.
- **اصلاح جهت فلش‌های تقویم:** تنظیم حرکت ماه بعد (فلش راست) و ماه قبل (فلش چپ) متناسب با چیدمان زبان فارسی و راست‌چین.

### English
- **Smart BluBank Detection:** Accurately recognizes BluBank SMS using the "بلو" (Blu) keyword for seamless auto-import.
- **All Iranian Banks Support:** Added parsing support for all major Iranian banks & neo-banks (Wepod, Abank, Tobank, Bajet, Mellat, Melli, Saman, etc.).
- **Internal Transfers (Pocket-to-Pocket):** Transfers between own accounts update account balances without affecting monthly expense/income totals.
- **Automatic Transfer Pair Matching:** Automatically merges matching withdrawal and deposit SMS into a single internal transfer transaction.
- **Manual Convert to Transfer:** One-tap button in transaction details to convert any transaction into an internal transfer.
- **New Category (+) Button:** Create and immediately assign a new category with custom emoji and name directly from the quick category picker.
- **Dedicated SMS Import Button:** Prominent "وارد کردن تراکنش از sms ها" button in transactions top bar for 1-tap SMS reading.
- **RTL Month Pager Fix:** Fixed month navigation arrow directions for right-to-left layout (Right = Next month, Left = Previous month).

---

## [0.2.0] - 2026-11-21

### فارسی (Persian)
- **ورود خودکار پیامک‌های بانکی:** خواندن خودکار پیامک‌های بانکی و استخراج مبلغ، نوع تراکنش، تاریخ شمسی و شماره کارت.
- **دسته‌بندی اختیاری (Blank):** خالی ماندن فیلد دسته‌بندی برای انتخاب دلخواه توسط کاربر همراه با برچسب تعیین دسته در لیست.
- **جلوگیری از ثبت تکراری:** ذخیره شناسه پیامک‌ها در جدول دیتابیس `imported_sms` جهت جلوگیری از ثبت مجدد.
- **تاریخ دقیق در ماه مالی:** قرارگیری هر تراکنش در ماه مالی متناظر با تاریخ وقوع پیامک.

### English
- **Automatic Bank SMS Import:** Automatically reads incoming banking SMS and parses amount, transaction type, Shamsi date, and card number.
- **Blank Category by Default:** Keeps category blank upon import, allowing users to categorize easily with a visible tag.
- **Duplicate Prevention:** Stores processed SMS IDs in `imported_sms` database table to prevent re-importing.
- **Exact Financial Month Placement:** Places imported transactions in their respective financial month based on SMS timestamp.

---

## [0.1.0] - 2026-11-09

### فارسی (Persian)
- **راه‌اندازی اولیه اپلیکیشن:** انتشار نسخه اولیه MVP با دیتابیس امن رمزنگاری‌شده (SQLCipher)، تقویم شمسی و شناسایی باگ‌های ولخرجی.

### English
- **Initial MVP Release:** First release with encrypted local database (SQLCipher), Persian solar calendar, and spending leak detection.
