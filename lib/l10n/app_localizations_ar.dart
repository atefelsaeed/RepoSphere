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
  String get connectGiteaUrlLabel =>
      'رابط Forgejo / Gitea (مثل https://codeberg.org)';

  @override
  String get giteaNeedsUrl => 'يحتاج Forgejo / Gitea إلى رابط الخادم.';

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
  String get insecureInstanceUrl =>
      'رابط الخادم يستخدم http العادي، فالرمز سيُرسل بدون تشفير. استخدم https (يُسمح بـ http فقط لـ localhost وعناوين الشبكة الخاصة).';

  @override
  String get remoteImageBlocked => 'تم حظر الصورة';

  @override
  String loadRemoteImage(String host) {
    return 'تحميل الصورة من $host';
  }

  @override
  String get webTokenWarning =>
      'نسخة الويب: يُحفظ الرمز في التخزين المحلي للمتصفح وهو أقل حماية من تطبيقات سطح المكتب والجوال. استخدم تلك التطبيقات للرموز طويلة الأمد، ولا تستخدمها على جهاز مشترك.';

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

  @override
  String get tooltipActivity => 'النشاط';

  @override
  String get tooltipGists => 'الـ Gists';

  @override
  String get tooltipExplore => 'استكشاف GitHub';

  @override
  String get tooltipSort => 'ترتيب';

  @override
  String get sortUpdated => 'آخر تحديث';

  @override
  String get sortStars => 'النجوم';

  @override
  String get sortName => 'الاسم';

  @override
  String get sortCreated => 'تاريخ الإنشاء';

  @override
  String get tooltipToggleTheme => 'تبديل السمة';

  @override
  String get tooltipProfile => 'الملف الشخصي';

  @override
  String get tooltipLogout => 'تسجيل الخروج';

  @override
  String get disconnectAllTitle => 'فصل الكل';

  @override
  String get disconnectAllBody => 'إزالة كل الحسابات المتصلة من هذا الجهاز؟';

  @override
  String get disconnect => 'فصل';

  @override
  String get searchReposHint => 'ابحث في المستودعات…';

  @override
  String get pinned => 'المثبّتة';

  @override
  String get noReposFound => 'لم يتم العثور على مستودعات';

  @override
  String get filterOwned => 'المملوكة';

  @override
  String get filterForked => 'المنسوخة (Fork)';

  @override
  String get filterStarred => 'المميّزة بنجمة';

  @override
  String get filterPublic => 'العامة';

  @override
  String get filterPrivate => 'الخاصة';

  @override
  String get shortcutSearch => 'التركيز على شريط البحث';

  @override
  String get shortcutRefresh => 'تحديث المستودعات';

  @override
  String get shortcutHelp => 'عرض هذه النافذة';

  @override
  String get shortcutsTitle => 'اختصارات لوحة المفاتيح';

  @override
  String get close => 'إغلاق';

  @override
  String repoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مستودع',
      many: '$count مستودعًا',
      few: '$count مستودعات',
      two: 'مستودعان',
      one: 'مستودع واحد',
      zero: 'لا مستودعات',
    );
    return '$_temp0';
  }

  @override
  String get unpin => 'إلغاء التثبيت';

  @override
  String get pin => 'تثبيت';

  @override
  String get browseCode => 'تصفّح الكود';

  @override
  String get unstar => 'إزالة النجمة';

  @override
  String get star => 'نجمة';

  @override
  String get copied => 'تم النسخ!';

  @override
  String get copyLink => 'نسخ الرابط';

  @override
  String get pullRequests => 'طلبات الدمج (PRs)';

  @override
  String get issues => 'المشكلات (Issues)';

  @override
  String get commits => 'الـ Commits';

  @override
  String get releases => 'الإصدارات';

  @override
  String get forkLabel => 'Fork';

  @override
  String get topics => 'المواضيع';

  @override
  String get recentCommits => 'أحدث الـ Commits';

  @override
  String get viewAll => 'عرض الكل';

  @override
  String get noCommitsFound => 'لا توجد Commits';

  @override
  String get forks => 'عدد الـ Forks';

  @override
  String get watchers => 'المتابعون';

  @override
  String get languages => 'اللغات';

  @override
  String get contributors => 'المساهمون';

  @override
  String get clone => 'استنساخ';

  @override
  String get copy => 'نسخ';

  @override
  String openOnProvider(String provider) {
    return 'فتح على $provider';
  }

  @override
  String contributorTooltip(String login, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Commit',
      many: '$count Commit',
      few: '$count Commits',
      two: 'Commitان',
      one: 'Commit واحد',
    );
    return '$login · $_temp0';
  }

  @override
  String get noProfileData => 'لا توجد بيانات للملف الشخصي';

  @override
  String get reposLabel => 'المستودعات';

  @override
  String get followers => 'المتابعون';

  @override
  String get following => 'يتابع';

  @override
  String get searchAllHint => 'ابحث في كل مستودعات GitHub…';

  @override
  String get searchFailed => 'فشل البحث';

  @override
  String get searchAcrossTitle => 'ابحث في كل GitHub';

  @override
  String get searchAcrossBody =>
      'ابحث عن المستودعات بالاسم أو الموضوع أو الوصف';

  @override
  String get recentSearches => 'عمليات البحث الأخيرة';

  @override
  String get clearAll => 'مسح الكل';

  @override
  String get markAllRead => 'تعليم الكل كمقروء';

  @override
  String get refresh => 'تحديث';

  @override
  String get failedLoadNotifications => 'تعذّر تحميل الإشعارات';

  @override
  String get allCaughtUp => 'لا جديد!';

  @override
  String get noNotifications => 'لا توجد إشعارات';

  @override
  String get reasonSubscribed => 'مشترك';

  @override
  String get reasonAssignedShort => 'مُسنَد';

  @override
  String get reasonAuthor => 'المؤلف';

  @override
  String get reasonCommented => 'تم التعليق';

  @override
  String get reasonTeamMention => 'تمت الإشارة إلى الفريق';

  @override
  String get reasonStateChange => 'تغيّرت الحالة';

  @override
  String get failedLoadActivity => 'تعذّر تحميل النشاط';

  @override
  String get noRecentActivity => 'لا يوجد نشاط حديث';

  @override
  String get yourGists => 'الـ Gists الخاصة بك';

  @override
  String get failedLoadGists => 'تعذّر تحميل الـ Gists';

  @override
  String get noGistsYet => 'لا توجد Gists بعد';

  @override
  String get gistSecret => 'سرّي';

  @override
  String get newIssue => 'مشكلة جديدة';

  @override
  String get tabOpen => 'مفتوحة';

  @override
  String get tabClosed => 'مغلقة';

  @override
  String get loadMore => 'تحميل المزيد';

  @override
  String get tabMerged => 'مدموجة';

  @override
  String joinedAgo(String time) {
    return 'انضم $time';
  }

  @override
  String noResultsFor(String query) {
    return 'لا توجد نتائج لـ \"$query\"';
  }

  @override
  String reposForQuery(int count, String query) {
    return '$count+ مستودع لـ \"$query\"';
  }

  @override
  String updatedAgo(String time) {
    return 'آخر تحديث $time';
  }

  @override
  String get noOpenIssues => 'لا توجد مشكلات مفتوحة';

  @override
  String get noClosedIssues => 'لا توجد مشكلات مغلقة';

  @override
  String get noOpenPrs => 'لا توجد طلبات دمج مفتوحة';

  @override
  String get noClosedPrs => 'لا توجد طلبات دمج مغلقة';

  @override
  String get noMergedPrs => 'لا توجد طلبات دمج مدموجة';

  @override
  String openedAgo(String time) {
    return 'فُتحت $time';
  }

  @override
  String closedAgo(String time) {
    return 'أُغلقت $time';
  }

  @override
  String byAuthor(String author) {
    return 'بواسطة $author';
  }

  @override
  String get prOpen => 'مفتوح';

  @override
  String get prMerged => 'مدموج';

  @override
  String get prClosed => 'مغلق';

  @override
  String get prDraft => 'مسودة';

  @override
  String get noDescriptionProvided => 'لم يُقدَّم وصف.';

  @override
  String get noCommitsOnBranch => 'لا توجد Commits في هذا الفرع';

  @override
  String get defaultBadge => 'افتراضي';

  @override
  String get noReleasesYet => 'لا توجد إصدارات بعد';

  @override
  String get viewOnGithub => 'عرض على GitHub';

  @override
  String get copyContent => 'نسخ المحتوى';

  @override
  String get copiedToClipboard => 'تم النسخ إلى الحافظة';

  @override
  String get binaryFile => 'ملف ثنائي — لا يمكن عرضه';

  @override
  String get emptyDirectory => 'مجلد فارغ';

  @override
  String get noReadmeFound => 'لم يُعثر على README';

  @override
  String get titleLabel => 'العنوان';

  @override
  String get titleRequired => 'العنوان مطلوب';

  @override
  String get describeIssueHint => 'صف المشكلة… (اختياري)';

  @override
  String get descriptionLabel => 'الوصف';

  @override
  String get submitIssue => 'إرسال المشكلة';

  @override
  String get comments => 'التعليقات';

  @override
  String get emptyComment => '(تعليق فارغ)';

  @override
  String prTitle(int number) {
    return 'PR #$number';
  }

  @override
  String issueTitle(int number) {
    return 'مشكلة #$number';
  }

  @override
  String releasedAgo(String time) {
    return 'صدر $time';
  }

  @override
  String committedAgo(String time) {
    return 'تم الـ Commit $time';
  }

  @override
  String commentedAgo(String time) {
    return 'علّق $time';
  }

  @override
  String filesChangedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ملف متغيّر',
      many: '$count ملفًا متغيّرًا',
      few: '$count ملفات متغيّرة',
      two: 'ملفان متغيّران',
      one: 'ملف واحد متغيّر',
      zero: 'لا ملفات متغيّرة',
    );
    return '$_temp0';
  }

  @override
  String commentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تعليق',
      many: '$count تعليقًا',
      few: '$count تعليقات',
      two: 'تعليقان',
      one: 'تعليق واحد',
      zero: 'لا تعليقات',
    );
    return '$_temp0';
  }

  @override
  String get errInvalidToken => 'الرمز غير صالح أو منتهي. أعد الربط من فضلك.';

  @override
  String get errForbidden => 'الوصول مرفوض. تحقق من صلاحيات الرمز.';

  @override
  String get errNotFound => 'المورد غير موجود.';

  @override
  String get errTooMany => 'طلبات كثيرة جدًا. حاول بعد قليل.';

  @override
  String get errInvalidRequest =>
      'طلب غير صالح. تحقق من البيانات وحاول مجددًا.';

  @override
  String get errServer => 'الخادم يواجه مشكلة. حاول لاحقًا.';

  @override
  String errUnexpected(String code) {
    return 'خطأ غير متوقع ($code).';
  }

  @override
  String get errCommentRequired => 'التعليق مطلوب لطلب التعديلات.';

  @override
  String get errRateLimited => 'يحدّ GitHub من عدد الطلبات. حاول بعد دقيقة.';

  @override
  String errRateLimitedIn(String seconds) {
    return 'يحدّ GitHub من عدد الطلبات. حاول بعد $seconds ثانية.';
  }
}
