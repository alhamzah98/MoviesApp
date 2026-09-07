import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Centralized application localization layer for English and Arabic.
///
/// Implements typed getters for application-owned UI strings, genre translation,
/// and friendly error message mapping.
class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('ar'),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        const AppLocalizations(Locale('en'));
  }

  static bool isSupported(String? languageCode) {
    if (languageCode == null) return false;
    return languageCode == 'en' || languageCode == 'ar';
  }

  bool get isArabic => locale.languageCode == 'ar';
  TextDirection get textDirection =>
      isArabic ? TextDirection.rtl : TextDirection.ltr;

  // --- Common ---
  String get appTitle => isArabic ? 'تطبيق الأفلام' : 'Movies App';
  String get cancel => isArabic ? 'إلغاء' : 'Cancel';
  String get tryAgain => isArabic ? 'إعادة المحاولة' : 'Try Again';
  String get somethingWentWrong =>
      isArabic ? 'حدث خطأ ما' : 'Something went wrong';
  String get loading => isArabic ? 'جارٍ التحميل...' : 'Loading...';
  String get minutesShort => isArabic ? 'دقيقة' : 'min';
  String get unknown => isArabic ? 'غير معروف' : 'Unknown';
  String get close => isArabic ? 'إغلاق' : 'Close';

  // --- Bottom Navigation ---
  String get homeTab => isArabic ? 'الرئيسية' : 'Home';
  String get searchTab => isArabic ? 'بحث' : 'Search';
  String get browseTab => isArabic ? 'تصفح' : 'Browse';
  String get profileTab => isArabic ? 'الملف الشخصي' : 'Profile';

  // --- Onboarding ---
  String get onboardingTitle1 =>
      isArabic ? 'اعثر على فيلمك المفضل القادم هنا' : 'Find Your Next Favorite Movie Here';
  String get onboardingDesc1 => isArabic
      ? 'تمتع بالوصول إلى مكتبة ضخمة من الأفلام لتناسب جميع الأذواق. ستنال إعجابك بالتأكيد.'
      : 'Get access to a huge library of movies to suit all tastes. You will surely like it.';
  String get onboardingBtn1 => isArabic ? 'استكشف الآن' : 'Explore Now';

  String get onboardingTitle2 =>
      isArabic ? 'اكتشف الأفلام' : 'Discover Movies';
  String get onboardingDesc2 => isArabic
      ? 'استكشف مجموعة واسعة من الأفلام بجميع الجودات والتصنيفات. اعثر على فيلمك المفضل بسهولة.'
      : 'Explore a vast collection of movies in all qualities and genres. Find your next favorite film with ease.';
  String get onboardingBtn2 => isArabic ? 'التالي' : 'Next';

  String get onboardingTitle3 =>
      isArabic ? 'استكشف جميع التصنيفات' : 'Explore All Genres';
  String get onboardingDesc3 => isArabic
      ? 'اكتشف أفلاماً من كل تصنيف، بجميع الجودات المتوفرة. ابحث عن شيء جديد ومشوق لمشاهدته كل يوم.'
      : 'Discover movies from every genre, in all available qualities. Find something new and exciting to watch every day.';
  String get onboardingBtn3 => isArabic ? 'التالي' : 'Next';

  String get onboardingTitle4 =>
      isArabic ? 'أنشئ قوائم المشاهدة' : 'Create Watchlists';
  String get onboardingDesc4 => isArabic
      ? 'احفظ الأفلام في قائمة المشاهدة لتتبع ما ترغب بمشاهدته لاحقاً. استمتع بالأفلام بجودات وتصنيفات متنوعة.'
      : 'Save movies to your watchlist to keep track of what you want to watch next. Enjoy films in various qualities and genres.';
  String get onboardingBtn4 => isArabic ? 'التالي' : 'Next';

  String get onboardingTitle5 =>
      isArabic ? 'قيّم وراجع وتعرّف' : 'Rate, Review, and Learn';
  String get onboardingDesc5 => isArabic
      ? 'شارك آراءك حول الأفلام التي شاهدتها. تعمق في تفاصيل الفيلم وساعد الآخرين على اكتشاف أفلام رائعة بتقييماتك.'
      : "Share your thoughts on the movies you've watched. Dive deep into film details and help others discover great movies with your reviews.";
  String get onboardingBtn5 => isArabic ? 'التالي' : 'Next';

  String get onboardingTitle6 =>
      isArabic ? 'ابدأ المشاهدة الآن' : 'Start Watching Now';
  String get onboardingBtn6 => isArabic ? 'إنهاء' : 'Finish';
  String get onboardingBack => isArabic ? 'رجوع' : 'Back';
  String get onboardingSaveError => isArabic
      ? 'تعذر حفظ تقدم الإعداد. يرجى المحاولة مرة أخرى.'
      : 'Could not save onboarding progress. Please try again.';

  // --- Auth (Login, Register, Forgot Password) ---
  String get login => isArabic ? 'تسجيل الدخول' : 'Login';
  String get register => isArabic ? 'إنشاء حساب' : 'Register';
  String get createAccount => isArabic ? 'إنشاء حساب' : 'Create Account';
  String get email => isArabic ? 'البريد الإلكتروني' : 'Email';
  String get password => isArabic ? 'كلمة المرور' : 'Password';
  String get confirmPassword =>
      isArabic ? 'تأكيد كلمة المرور' : 'Confirm Password';
  String get name => isArabic ? 'الاسم' : 'Name';
  String get phoneNumber => isArabic ? 'رقم الهاتف' : 'Phone Number';
  String get forgotPasswordPrompt =>
      isArabic ? 'نسيت كلمة المرور؟' : 'Forgot Password ?';
  String get forgotPasswordTitle =>
      isArabic ? 'نسيت كلمة المرور' : 'Forgot Password';
  String get forgotPasswordInstruction => isArabic
      ? 'أدخل بريدك الإلكتروني لتلقي رابط إعادة تعيين كلمة المرور.'
      : 'Enter your email address to receive a password reset link.';
  String get sendCode => isArabic ? 'إرسال الرابط' : 'Send Code';
  String get verifyEmail => isArabic ? 'التحقق من البريد' : 'Verify Email';
  String get dontHaveAccount =>
      isArabic ? 'ليس لديك حساب؟' : "Don't Have Account ?";
  String get createOne => isArabic ? 'أنشئ حساباً' : 'Create One';
  String get alreadyHaveAccount =>
      isArabic ? 'لديك حساب بالفعل؟' : 'Already Have Account ?';
  String get orDivider => isArabic ? 'أو' : 'Or';
  String get loginWithGoogle =>
      isArabic ? 'الدخول بواسطة جوجل' : 'Login With Google';
  String get resetPasswordSuccess => isArabic
      ? 'تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني.'
      : 'Password reset link sent to your email.';
  String get resetPasswordFailure => isArabic
      ? 'تعذر إرسال رابط إعادة التعيين. يرجى المحاولة مرة أخرى.'
      : 'Failed to send reset link. Please try again.';
  String get authServiceUnavailable => isArabic
      ? 'خدمة المصادقة غير متوفرة حالياً.'
      : 'Authentication service is currently unavailable.';
  String get authFailed => isArabic
      ? 'فشلت المصادقة. يرجى المحاولة مرة أخرى.'
      : 'Authentication failed. Please try again.';
  String get registrationFailed => isArabic
      ? 'فشل إنشاء الحساب. يرجى المحاولة مرة أخرى.'
      : 'Registration failed. Please try again.';
  String get firebaseConfigMissing => isArabic
      ? 'إعدادات فايربيز غير موجودة. يرجى تهيئة google-services.json.'
      : 'Firebase configuration is absent. Please configure google-services.json.';

  // --- Validation ---
  String get valEmailRequired =>
      isArabic ? 'البريد الإلكتروني مطلوب.' : 'Email is required.';
  String get valEmailInvalid =>
      isArabic ? 'يرجى إدخال بريد إلكتروني صالح.' : 'Please enter a valid email address.';
  String get valPasswordRequired =>
      isArabic ? 'كلمة المرور مطلوبة.' : 'Password is required.';
  String get valPasswordMinLength => isArabic
      ? 'يجب ألا تقل كلمة المرور عن 6 أحرف.'
      : 'Password must be at least 6 characters long.';
  String get valPasswordLetterNumber => isArabic
      ? 'يجب أن تحتوي كلمة المرور على حرف واحد ورقم واحد على الأقل.'
      : 'Password must contain at least one letter and one number.';
  String get valNameRequired => isArabic ? 'الاسم مطلوب.' : 'Name is required.';
  String get valNameLength => isArabic
      ? 'يجب أن يتراوح الاسم بين 2 و50 حرفاً.'
      : 'Name must be between 2 and 50 characters.';
  String get valPhoneRequired =>
      isArabic ? 'رقم الهاتف مطلوب.' : 'Phone number is required.';
  String get valPhoneInvalid =>
      isArabic ? 'يرجى إدخال رقم هاتف صالح.' : 'Please enter a valid phone number.';
  String get valPasswordsDoNotMatch =>
      isArabic ? 'كلمتا المرور غير متطابقتين.' : 'Passwords do not match.';

  // --- Home ---
  String get availableNow => isArabic ? 'متوفر الآن' : 'Available Now';
  String get watchNow => isArabic ? 'شاهد الآن' : 'Watch Now';
  String get seeMore => isArabic ? 'المزيد' : 'See More';
  String get retry => isArabic ? 'إعادة المحاولة' : 'Retry';
  String get noMoviesAvailable => isArabic
      ? 'لا تتوفر أفلام جديدة حالياً.'
      : 'No new movies are available right now.';
  String get noActionMoviesFound =>
      isArabic ? 'لم يتم العثور على أفلام حركة.' : 'No action movies found.';
  String get failedToLoadFeatured =>
      isArabic ? 'تعذر تحميل الأفلام المميزة' : 'Failed to load featured movies';
  String get failedToLoadMovies =>
      isArabic ? 'تعذر تحميل الأفلام' : 'Failed to load movies';

  // --- Search ---
  String get searchHint =>
      isArabic ? 'ابحث عن أفلام...' : 'Search for movies...';
  String get searchMoviesTitle =>
      isArabic ? 'ابحث عن الأفلام' : 'Search for Movies';
  String get searchMoviesSubtitle => isArabic
      ? 'ابحث عن أفلامك المفضلة بالعنوان أو السنة أو الكلمات المفتاحية.'
      : 'Find movies by title, year, or keywords.';
  String get noMoviesFound =>
      isArabic ? 'لم يتم العثور على أفلام' : 'No Movies Found';
  String get noMoviesFoundSubtitle => isArabic
      ? 'لم نتمكن من العثور على أي نتائج تطابق بحثك.'
      : "We couldn't find anything matching your search.";
  String noMoviesFoundForQuery(String query) => isArabic
      ? 'لم يتم العثور على أفلام لـ "$query"'
      : 'No movies found for "$query"';
  String get searchCheckSpelling => isArabic
      ? 'تأكد من صحة الكلمات أو جرب كلمات مفتاحية أخرى.'
      : 'Check your spelling or try different keywords.';
  String get failedToSearch =>
      isArabic ? 'فشل في البحث عن الأفلام' : 'Failed to search movies';
  String get clearSearchTooltip =>
      isArabic ? 'مسح البحث' : 'Clear search';

  // --- Browse ---
  String get browseMovies => isArabic ? 'تصفح الأفلام' : 'Browse Movies';
  String get noMoviesInGenre => isArabic
      ? 'لا توجد أفلام في هذا التصنيف.'
      : 'No movies found in this genre.';
  String noMoviesFoundForGenre(String genre) => isArabic
      ? 'لا توجد أفلام في تصنيف ${translateGenre(genre)}'
      : 'No movies found for $genre';
  String get tryAnotherGenre => isArabic
      ? 'جرب اختيار تصنيف آخر من الشريط العلوي.'
      : 'Try selecting another genre from the top bar.';
  String get failedToLoadGenre => isArabic
      ? 'تعذر تحميل أفلام هذا التصنيف.'
      : 'Failed to load movies for this genre.';

  // --- Movie Details ---
  String get watchTrailer => isArabic ? 'مشاهدة الإعلان' : 'Watch Trailer';
  String get trailerUnavailable =>
      isArabic ? 'الإعلان غير متوفر' : 'Trailer Unavailable';
  String get trailerLaunchFailed =>
      isArabic ? 'تعذر فتح الإعلان.' : 'Failed to launch trailer.';
  String get invalidTrailerId =>
      isArabic ? 'رابط الإعلان غير صالح.' : 'Invalid trailer video ID.';
  String get summary => isArabic ? 'القصة' : 'Summary';
  String get cast => isArabic ? 'طاقم العمل' : 'Cast';
  String get genres => isArabic ? 'التصنيفات' : 'Genres';
  String get screenshots => isArabic ? 'لقطات من الفيلم' : 'Screenshots';
  String get similarMovies => isArabic ? 'أفلام مشابهة' : 'Similar Movies';
  String get rating => isArabic ? 'التقييم' : 'Rating';
  String get year => isArabic ? 'السنة' : 'Year';
  String get invalidMovieIdTitle =>
      isArabic ? 'معرّف الفيلم غير صالح' : 'Invalid movie ID';
  String get invalidMovieIdMessage => isArabic
      ? 'تعذر التعرف على الفيلم المحدد.'
      : 'The selected movie could not be identified.';
  String get failedToLoadDetails =>
      isArabic ? 'تعذر تحميل تفاصيل الفيلم.' : 'Failed to load movie details.';
  String get failedToLoadSuggestions => isArabic
      ? 'تعذر تحميل الأفلام المشابهة.'
      : 'Failed to load similar movies.';
  String get signInToBookmark => isArabic
      ? 'يرجى تسجيل الدخول لحفظ الأفلام في قائمة المشاهدة.'
      : 'Please sign in to save movies to your watch list.';
  String get saveToWatchList =>
      isArabic ? 'حفظ في قائمة المشاهدة' : 'Save to Watch List';
  String get removeFromWatchList =>
      isArabic ? 'إزالة من قائمة المشاهدة' : 'Remove from Watch List';
  String get checkingWatchListStatus => isArabic
      ? 'جارٍ التحقق من حالة قائمة المشاهدة...'
      : 'Checking Watch List status...';
  String get signInToSaveTooltip => isArabic
      ? 'سجّل الدخول للحفظ في قائمة المشاهدة'
      : 'Sign in to save to Watch List';
  String get backTooltip => isArabic ? 'رجوع' : 'Back';

  // --- Profile & Update Profile ---
  String get userDefault => isArabic ? 'مستخدم' : 'User';
  String get guestUser => isArabic ? 'زائر' : 'Guest User';
  String get notSignedIn => isArabic ? 'غير مسجل الدخول' : 'Not signed in';
  String get editProfile => isArabic ? 'تعديل الملف' : 'Edit Profile';
  String get logout => isArabic ? 'تسجيل الخروج' : 'Logout';
  String get logoutConfirmTitle => isArabic ? 'تسجيل الخروج' : 'Logout';
  String get logoutConfirmMessage => isArabic
      ? 'هل أنت متأكد من رغبتك في تسجيل الخروج من حسابك؟'
      : 'Are you sure you want to log out of your account?';
  String get watchList => isArabic ? 'قائمة المشاهدة' : 'Watch List';
  String get history => isArabic ? 'السجل' : 'History';
  String get emptyWatchListTitle =>
      isArabic ? 'قائمة المشاهدة فارغة' : 'Your Watch List is Empty';
  String get emptyWatchListSubtitle => isArabic
      ? 'الأفلام التي تضيفها إلى قائمة المشاهدة ستظهر هنا.'
      : 'Movies you add to your watch list will appear here.';
  String get emptyHistoryTitle =>
      isArabic ? 'لا يوجد سجل مشاهدة' : 'No History Recorded';
  String get emptyHistorySubtitle => isArabic
      ? 'الأفلام التي شاهدتها ستظهر هنا.'
      : 'Movies you have viewed will appear here.';
  String get watchListUnavailableTitle =>
      isArabic ? 'قائمة المشاهدة غير متوفرة' : 'Watch List Unavailable';
  String get historyUnavailableTitle =>
      isArabic ? 'سجل المشاهدة غير متوفر' : 'History Unavailable';
  String get watchListUnavailableSubtitleSignedIn => isArabic
      ? 'مزامنة قائمة المشاهدة غير متوفرة حالياً وسيتم ربطها في مرحلة قادمة.'
      : 'Watch list sync is currently unavailable and will be integrated in an upcoming phase.';
  String get watchListUnavailableSubtitleGuest => isArabic
      ? 'سجّل الدخول لمزامنة وعرض قائمة المشاهدة الخاصة بك.'
      : 'Sign in to sync and view your saved watch list.';
  String get historyUnavailableSubtitleSignedIn => isArabic
      ? 'تتبع سجل المشاهدة غير متوفر حالياً وسيتم ربطه في مرحلة قادمة.'
      : 'Watch history tracking is currently unavailable and will be integrated in an upcoming phase.';
  String get historyUnavailableSubtitleGuest => isArabic
      ? 'سجّل الدخول لتتبع وعرض سجل المشاهدة الخاص بك.'
      : 'Sign in to track and view your watch history.';
  String get unableToLoadWatchList => isArabic
      ? 'تعذر تحميل قائمة المشاهدة.'
      : 'Unable to load your watch list.';
  String get unableToLoadHistory => isArabic
      ? 'تعذر تحميل سجل المشاهدة.'
      : 'Unable to load your watch history.';
  String get updateProfile =>
      isArabic ? 'تعديل الملف الشخصي' : 'Update Profile';
  String get profileUnavailableTitle =>
      isArabic ? 'الملف الشخصي غير متوفر' : 'Profile Unavailable';
  String get profileUnavailableSubtitle => isArabic
      ? 'يرجى تسجيل الدخول لعرض وتحديث ملفك الشخصي.'
      : 'Please sign in to view and update your profile.';
  String get signIn => isArabic ? 'تسجيل الدخول' : 'Sign In';
  String get changeAvatar =>
      isArabic ? 'تغيير الصورة الرمزية' : 'Change Avatar';
  String get chooseAvatar =>
      isArabic ? 'اختر صورة رمزية' : 'Choose Avatar';
  String get resetPassword =>
      isArabic ? 'إعادة تعيين كلمة المرور' : 'Reset Password';
  String get updateData => isArabic ? 'تحديث البيانات' : 'Update Data';
  String get deleteAccount => isArabic ? 'حذف الحساب' : 'Delete Account';
  String get deleteAccountUnavailable =>
      isArabic ? 'حذف الحساب (غير متوفر)' : 'Delete Account (Unavailable)';
  String get deleteAccountConfirmTitle =>
      isArabic ? 'حذف الحساب' : 'Delete Account';
  String get deleteAccountConfirmMessage => isArabic
      ? 'سيؤدي هذا إلى حذف حسابك في تطبيق الأفلام، وملفك الشخصي، وقائمة المشاهدة، وسجل المشاهدة نهائياً. لا يمكن التراجع عن هذا الإجراء.'
      : 'This will permanently delete your MoviesApp account, profile, Watch List, and History. This action cannot be undone.';
  String get deleteAccountConfirmAction =>
      isArabic ? 'حذف الحساب نهائياً' : 'Delete Account Permanently';
  String get deleteAccountWarning => isArabic
      ? 'سيؤدي حذف الحساب إلى إزالة جميع بياناتك المحفوظة وقوائم المشاهدة بشكل نهائي.'
      : 'Deleting your account will permanently remove all your saved data and watch lists.';
  String get reauthenticateTitle =>
      isArabic ? 'تأكيد الهوية' : 'Confirm Identity';
  String get reauthenticatePasswordPrompt => isArabic
      ? 'يرجى إدخال كلمة المرور الحالية لتأكيد حذف الحساب.'
      : 'Please enter your current password to confirm account deletion.';
  String get reauthenticateWithGoogle =>
      isArabic ? 'إعادة المصادقة بواسطة جوجل' : 'Reauthenticate with Google';
  String get reauthenticateFailed => isArabic
      ? 'فشلت إعادة المصادقة. يرجى التحقق من بياناتك والمحاولة مرة أخرى.'
      : 'Reauthentication failed. Please verify your credentials and try again.';
  String get accountDeletedSuccess => isArabic
      ? 'تم حذف الحساب بنجاح.'
      : 'Account deleted successfully.';
  String get accountDeletionFailed => isArabic
      ? 'فشل حذف الحساب. يرجى المحاولة مرة أخرى.'
      : 'Failed to delete account. Please try again.';
  String get accountDeletionPartialFailureTitle => isArabic
      ? 'حذف غير مكتمل للحساب'
      : 'Incomplete Account Deletion';
  String get accountDeletionPartialFailure => isArabic
      ? 'قد تكون بعض بيانات الحساب قد حُذفت. عملية حذف الحساب غير مكتملة، يرجى إعادة المحاولة.'
      : 'Some account data may have been removed. Account deletion is incomplete. Please retry.';
  String get unsupportedReauthProvider => isArabic
      ? 'طريقة تسجيل الدخول لهذا الحساب غير مدعومة لحذف الحساب.'
      : 'The sign-in method for this account is not supported for account deletion.';
  String get userMismatchError => isArabic
      ? 'حساب المصادقة لا يطابق المستخدم الحالي.'
      : 'The authenticated account does not match the current user.';
  String get retryAccountDeletion =>
      isArabic ? 'إعادة محاولة حذف الحساب' : 'Retry Account Deletion';
  String get accountDeletionUncertain => isArabic
      ? 'قد تكون بعض البيانات قد حُذفت. يرجى إعادة المحاولة لإكمال العملية.'
      : 'Some data may have been removed. Please retry to complete the deletion.';
  String get deletingAccount =>
      isArabic ? 'جارٍ حذف الحساب...' : 'Deleting account...';
  String get profileUpdatedSuccess => isArabic
      ? 'تم تحديث الملف الشخصي بنجاح.'
      : 'Profile updated successfully.';
  String get profileUpdateFailed => isArabic
      ? 'فشل تحديث الملف الشخصي. يرجى المحاولة مرة أخرى.'
      : 'Failed to update profile. Please try again.';
  String get language => isArabic ? 'اللغة' : 'Language';
  String get english => isArabic ? 'الإنجليزية' : 'English';
  String get arabic => isArabic ? 'العربية' : 'Arabic';
  String get languageSaveFailed => isArabic
      ? 'تعذر حفظ تفضيل اللغة.'
      : 'Could not save language preference.';

  // --- Genre Translations (Preserving API values in queries) ---
  static const Map<String, String> _genreArabic = {
    'Action': 'أكشن',
    'Adventure': 'مغامرة',
    'Animation': 'رسوم متحركة',
    'Biography': 'سيرة ذاتية',
    'Comedy': 'كوميديا',
    'Crime': 'جريمة',
    'Documentary': 'وثائقي',
    'Drama': 'دراما',
    'Family': 'عائلي',
    'Fantasy': 'خيال',
    'Film-Noir': 'فيلم نوار',
    'History': 'تاريخ',
    'Horror': 'رعب',
    'Music': 'موسيقى',
    'Musical': 'موسيقي',
    'Mystery': 'غموض',
    'Romance': 'رومانسي',
    'Sci-Fi': 'خيال علمي',
    'Sport': 'رياضة',
    'Thriller': 'إثارة',
    'War': 'حرب',
    'Western': 'وسترن',
  };

  String translateGenre(String canonicalGenre) {
    if (!isArabic) return canonicalGenre;
    return _genreArabic[canonicalGenre] ?? canonicalGenre;
  }

  // --- Error Code Translations ---
  String translateError({String? errorCode, String? fallback}) {
    if (errorCode != null) {
      switch (errorCode) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return isArabic
              ? 'بيانات الاعتماد غير صالحة. يرجى التحقق من بريدك وكلمة المرور.'
              : 'Invalid credentials. Please verify your email and password.';
        case 'email-already-in-use':
          return isArabic
              ? 'البريد الإلكتروني مستخدم بالفعل بحساب آخر.'
              : 'The email address is already in use by another account.';
        case 'network-request-failed':
          return isArabic
              ? 'تعذر الاتصال بالشبكة. يرجى التحقق من اتصال الإنترنت.'
              : 'Network request failed. Please check your internet connection.';
        case 'too-many-requests':
          return isArabic
              ? 'محاولات كثيرة غير ناجحة. يرجى المحاولة لاحقاً.'
              : 'Too many unsuccessful attempts. Please try again later.';
        case 'requires-recent-login':
          return isArabic
              ? 'تتطلب هذه العملية إعادة تسجيل الدخول لتأكيد الهوية.'
              : 'This operation requires recent authentication. Please sign in again.';
        case 'user-mismatch':
          return userMismatchError;
        case 'provider-not-supported':
          return unsupportedReauthProvider;
        case 'cleanup-budget-exceeded':
          return isArabic
              ? 'تجاوزت عملية التنظيف الحد الأقصى المسموح به.'
              : 'Account cleanup exceeded the batch budget.';
        case 'operation-in-progress':
          return isArabic
              ? 'توجد عملية جارية على الحساب حالياً. يرجى الانتظار.'
              : 'An operation is currently in progress. Please wait.';
        case 'session-invalid':
          return isArabic
              ? 'تغيرت جلسة المستخدم أثناء العملية. يرجى إعادة المحاولة.'
              : 'The user session changed during the operation. Please try again.';
        case 'invalid-email':
          return valEmailInvalid;
        case 'weak-password':
          return valPasswordMinLength;
        case 'password-mismatch':
          return valPasswordsDoNotMatch;
        case 'invalid-name':
          return valNameRequired;
        case 'invalid-phone':
          return valPhoneRequired;
        case 'invalid-avatar':
          return isArabic ? 'يرجى اختيار صورة رمزية.' : 'Please select an avatar.';
      }
    }
    return fallback ??
        (isArabic
            ? 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.'
            : 'An unexpected error occurred. Please try again.');
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.isSupported(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(
      AppLocalizations(locale),
    );
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
