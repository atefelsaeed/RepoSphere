// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get inboxTitle => 'الوارد';

  @override
  String get tooltipWorkspaces => 'مساحات العمل';

  @override
  String get tooltipRepositories => 'المستودعات';

  @override
  String get tooltipSettings => 'الإعدادات';

  @override
  String get filterAll => 'الكل';

  @override
  String get filterUnassigned => 'بدون مساحة';

  @override
  String get filterEverything => 'كل شيء';

  @override
  String filterWithCount(String label, int count) {
    return '$label · $count';
  }

  @override
  String get emptyTitle => 'لا شيء يحتاج انتباهك';

  @override
  String get emptyBody => 'كل شيء على ما يرام الآن.';

  @override
  String bannerCouldntLoad(String account, String reason) {
    return 'تعذّر تحميل $account: $reason';
  }

  @override
  String bannerPartial(String account, String reason) {
    return 'قد تكون بعض نتائج $account ناقصة: $reason';
  }

  @override
  String get bannerSavedRefreshing => 'عرض النتائج المحفوظة — جارٍ التحديث…';

  @override
  String get errNetwork => 'خطأ في الشبكة أو استجابة غير متوقعة.';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get swipeDone => 'تم';

  @override
  String get swipeSnooze => 'تأجيل';

  @override
  String get snoozeLater => 'لاحقًا اليوم (4 ساعات)';

  @override
  String get snoozeTomorrow => 'غدًا';

  @override
  String get snoozeNextWeek => 'الأسبوع القادم';

  @override
  String get markedDone => 'تم الإنجاز';

  @override
  String get undo => 'تراجع';

  @override
  String get reasonCiFailed => 'فشل CI';

  @override
  String get reasonChangesRequested => 'مطلوب تعديلات';

  @override
  String get reasonConflicts => 'تعارضات دمج';

  @override
  String get reasonReviewRequested => 'مطلوب مراجعتك';

  @override
  String get reasonAssigned => 'مُسنَدة إليك';

  @override
  String get reasonMentioned => 'تمت الإشارة إليك';

  @override
  String get actionRerunCi => 'إعادة تشغيل CI الفاشل';

  @override
  String get actionApprove => 'موافقة';

  @override
  String get actionRequestChanges => 'طلب تعديلات';

  @override
  String get actionMerge => 'دمج';

  @override
  String get actionOpenInBrowser => 'فتح في المتصفح';

  @override
  String get doneApproved => 'تمت الموافقة';

  @override
  String get doneChangesRequested => 'تم طلب التعديلات';

  @override
  String get doneMerged => 'تم الدمج';

  @override
  String get doneCiRerun => 'بدأت إعادة تشغيل CI';

  @override
  String failedWith(String error) {
    return 'فشل: $error';
  }

  @override
  String get cancel => 'إلغاء';

  @override
  String get confirm => 'تأكيد';

  @override
  String get send => 'إرسال';

  @override
  String get approveTitle => 'الموافقة؟';

  @override
  String approveBody(String ref, String account) {
    return 'الموافقة على $ref باسم $account؟';
  }

  @override
  String get mergeTitle => 'الدمج؟';

  @override
  String mergeBody(String ref) {
    return 'دمج $ref؟ لا يمكن التراجع عن هذا من هنا.';
  }

  @override
  String get requestChangesHint => 'ما الذي يحتاج إلى تعديل؟';

  @override
  String get detailActions => 'الإجراءات';

  @override
  String get detailMore => 'المزيد';

  @override
  String get detailNoDescription => 'لا يوجد وصف.';

  @override
  String detailFilesChanged(int count) {
    return 'الملفات المتغيّرة · $count';
  }

  @override
  String detailDiscussion(int count) {
    return 'النقاش · $count';
  }

  @override
  String get detailNoComments => 'لا توجد تعليقات بعد.';

  @override
  String get detailNoDiff =>
      'لا يتوفر عرض للتغييرات (ملف ثنائي أو كبير جدًا). افتحه في المتصفح.';

  @override
  String detailMoreLines(int count) {
    return '… $count أسطر أخرى. افتح في المتصفح لعرض كل التغييرات.';
  }

  @override
  String get stateOpen => 'مفتوح';

  @override
  String get stateClosed => 'مغلق';

  @override
  String get stateMerged => 'مدموج';

  @override
  String get stateDraft => 'مسودة';

  @override
  String get workspacesTitle => 'مساحات العمل';

  @override
  String get workspaceNew => 'مساحة عمل جديدة';

  @override
  String get workspaceEmptyTitle => 'نظّم عملك حسب العميل';

  @override
  String get workspaceEmptyBody =>
      'تجمع مساحة العمل حسابات ومؤسسات من GitHub أو GitLab أو Azure DevOps تحت اسم عميل واحد، ليعرض الوارد عميلًا واحدًا في كل مرة.';

  @override
  String get workspaceNoAccounts => 'لا توجد حسابات بعد';

  @override
  String get workspaceRemovedAccount => 'حساب محذوف';

  @override
  String get workspaceNameLabel => 'اسم العميل / مساحة العمل';

  @override
  String get workspaceAccountsOrgs => 'الحسابات والمؤسسات';

  @override
  String get workspaceOrgHelp =>
      'اترك حقل المؤسسة فارغًا لتضمين الحساب كاملًا.';

  @override
  String get workspaceAccountLabel => 'الحساب';

  @override
  String get workspaceOrgLabel => 'المؤسسة / المجموعة (اختياري)';

  @override
  String get tooltipRemove => 'إزالة';

  @override
  String get workspaceAddRule => 'إضافة حساب أو مؤسسة';

  @override
  String get delete => 'حذف';

  @override
  String get save => 'حفظ';

  @override
  String get connectAzureUrlLabel =>
      'رابط المؤسسة (https://dev.azure.com/your-org)';

  @override
  String get connectGitlabUrlLabel => 'رابط GitLab المستضاف ذاتيًا (اختياري)';

  @override
  String get connectGitlabUrlHint => 'فارغ = gitlab.com';

  @override
  String get tokenLabel => 'رمز الوصول الشخصي';

  @override
  String get enterToken => 'أدخل الرمز.';

  @override
  String get azureNeedsOrg => 'يحتاج Azure DevOps إلى رابط المؤسسة.';

  @override
  String get invalidToken => 'الرمز غير صالح. تحقق من قيمته وصلاحياته.';

  @override
  String get couldNotConnectUrl => 'تعذّر الاتصال. تحقق من الرمز والرابط.';

  @override
  String get couldNotConnectNet =>
      'تعذّر الاتصال. تحقق من الرمز واتصالك بالإنترنت.';

  @override
  String get showToken => 'إظهار الرمز';

  @override
  String get hideToken => 'إخفاء الرمز';

  @override
  String get connecting => 'جارٍ الاتصال…';

  @override
  String get connect => 'اتصال';

  @override
  String createTokenOn(String provider) {
    return 'إنشاء رمز على $provider';
  }

  @override
  String needsScopes(String scopes) {
    return 'الصلاحيات المطلوبة: $scopes';
  }

  @override
  String get authTagline => 'وارد واحد لكل عملك على Git.';

  @override
  String get authSignInGithub => 'تسجيل الدخول عبر GitHub';

  @override
  String get authHideOther => 'إخفاء الخيارات الأخرى';

  @override
  String get authOtherOptions => 'GitLab أو Azure DevOps أو رمز وصول';

  @override
  String get deviceStep1 => '١. افتح هذا الرابط في المتصفح:';

  @override
  String get deviceStep2 => '٢. أدخل هذا الرمز:';

  @override
  String get codeCopied => 'تم نسخ الرمز!';

  @override
  String get deviceWaiting => 'بانتظار الموافقة…';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get connectedAccounts => 'الحسابات المتصلة';

  @override
  String get addAccount => 'إضافة حساب';

  @override
  String get connectAccountTitle => 'ربط حساب';

  @override
  String get noAccountsConnected =>
      'لا توجد حسابات متصلة. اضغط «إضافة حساب» للربط.';

  @override
  String removeProviderTitle(String provider) {
    return 'إزالة $provider';
  }

  @override
  String disconnectBody(String account) {
    return 'فصل $account؟ ستُزال مستودعاته من القائمة.';
  }

  @override
  String get remove => 'إزالة';

  @override
  String get appearance => 'المظهر';

  @override
  String get theme => 'السمة';

  @override
  String get themeSystem => 'افتراضي النظام';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get language => 'اللغة';

  @override
  String get languageSystem => 'افتراضي النظام';

  @override
  String get notificationsSection => 'الإشعارات';

  @override
  String get alertsTitle => 'تنبيهات الوارد العاجلة';

  @override
  String get alertsBody =>
      'فشل CI وطلبات التعديل والتعارضات وطلبات المراجعة. يُفحص في الخلفية كل 30 دقيقة تقريبًا، وقد يقلّل iOS من هذا التكرار.';

  @override
  String get alertsCheckNow => 'افحص الآن';

  @override
  String get alertsPermissionDenied =>
      'تم رفض إذن الإشعارات. فعّله من إعدادات النظام.';

  @override
  String alertsCouldNotChange(String error) {
    return 'تعذّر تغيير التنبيهات: $error';
  }

  @override
  String get checkedNothing => 'تم الفحص — لا جديد.';

  @override
  String checkedNew(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عنصر جديد',
      many: '$count عنصرًا جديدًا',
      few: '$count عناصر جديدة',
      two: 'عنصران جديدان',
      one: 'عنصر جديد',
      zero: 'لا جديد',
    );
    return 'تم الفحص — $_temp0.';
  }

  @override
  String checkFailed(String error) {
    return 'فشل الفحص: $error';
  }

  @override
  String get about => 'حول';

  @override
  String get aboutApp => 'التطبيق';

  @override
  String get aboutVersion => 'الإصدار';

  @override
  String get aboutProviders => 'المنصات';

  @override
  String alertTitleMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عنصر يحتاج انتباهك',
      many: '$count عنصرًا يحتاج انتباهك',
      few: '$count عناصر تحتاج انتباهك',
      two: 'عنصران يحتاجان انتباهك',
      one: 'عنصر واحد يحتاج انتباهك',
    );
    return '$_temp0';
  }

  @override
  String alertAndMore(int count) {
    return 'و$count آخرين';
  }

  @override
  String get alertChannelName => 'تنبيهات الوارد';

  @override
  String get alertChannelDescription =>
      'فشل CI وطلبات المراجعة وعناصر عاجلة أخرى';
}
