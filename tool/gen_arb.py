#!/usr/bin/env python3
"""Single source for the app strings: writes lib/l10n/app_en.arb and app_ar.arb.

Edit the table below, run `python3 tool/gen_arb.py`, then `flutter gen-l10n`
(flutter pub get / flutter run do that automatically).
Placeholders are listed by name; all are Strings unless suffixed with :int.
"""
import json
from pathlib import Path

OUT = Path(__file__).resolve().parent.parent / "lib" / "l10n"

# key: (english, arabic, [placeholders])
S = {
  # ── Inbox ──
  "inboxTitle": ("Inbox", "الوارد", []),
  "tooltipWorkspaces": ("Workspaces", "مساحات العمل", []),
  "tooltipRepositories": ("Repositories", "المستودعات", []),
  "tooltipSettings": ("Settings", "الإعدادات", []),
  "filterAll": ("All", "الكل", []),
  "filterUnassigned": ("Unassigned", "بدون مساحة", []),
  "filterEverything": ("Everything", "كل شيء", []),
  "filterWithCount": ("{label} · {count}", "{label} · {count}", ["label", "count:int"]),
  "emptyTitle": ("You're all caught up", "لا شيء يحتاج انتباهك", []),
  "emptyBody": ("Nothing needs your attention right now.", "كل شيء على ما يرام الآن.", []),
  "bannerCouldntLoad": ("Couldn't load {account}: {reason}", "تعذّر تحميل {account}: {reason}", ["account", "reason"]),
  "bannerPartial": ("Some results from {account} may be missing: {reason}", "قد تكون بعض نتائج {account} ناقصة: {reason}", ["account", "reason"]),
  "bannerSavedRefreshing": ("Showing saved results — refreshing…", "عرض النتائج المحفوظة — جارٍ التحديث…", []),
  "errNetwork": ("Network error or unexpected response.", "خطأ في الشبكة أو استجابة غير متوقعة.", []),
  "retry": ("Retry", "إعادة المحاولة", []),
  "swipeDone": ("Done", "تم", []),
  "swipeSnooze": ("Snooze", "تأجيل", []),
  "snoozeLater": ("Later today (4 hours)", "لاحقًا اليوم (4 ساعات)", []),
  "snoozeTomorrow": ("Tomorrow", "غدًا", []),
  "snoozeNextWeek": ("Next week", "الأسبوع القادم", []),
  "markedDone": ("Marked done", "تم الإنجاز", []),
  "undo": ("Undo", "تراجع", []),
  # ── Reasons ──
  "reasonCiFailed": ("CI failed", "فشل CI", []),
  "reasonChangesRequested": ("Changes requested", "مطلوب تعديلات", []),
  "reasonConflicts": ("Merge conflicts", "تعارضات دمج", []),
  "reasonReviewRequested": ("Review requested", "مطلوب مراجعتك", []),
  "reasonAssigned": ("Assigned to you", "مُسنَدة إليك", []),
  "reasonMentioned": ("Mentioned", "تمت الإشارة إليك", []),
  # ── Actions ──
  "actionRerunCi": ("Re-run failed CI", "إعادة تشغيل CI الفاشل", []),
  "actionApprove": ("Approve", "موافقة", []),
  "actionRequestChanges": ("Request changes", "طلب تعديلات", []),
  "actionMerge": ("Merge", "دمج", []),
  "actionOpenInBrowser": ("Open in browser", "فتح في المتصفح", []),
  "doneApproved": ("Approved", "تمت الموافقة", []),
  "doneChangesRequested": ("Changes requested", "تم طلب التعديلات", []),
  "doneMerged": ("Merged", "تم الدمج", []),
  "doneCiRerun": ("CI re-run started", "بدأت إعادة تشغيل CI", []),
  "failedWith": ("Failed: {error}", "فشل: {error}", ["error"]),
  "cancel": ("Cancel", "إلغاء", []),
  "confirm": ("Confirm", "تأكيد", []),
  "send": ("Send", "إرسال", []),
  "approveTitle": ("Approve?", "الموافقة؟", []),
  "approveBody": ("Approve {ref} as {account}?", "الموافقة على {ref} باسم {account}؟", ["ref", "account"]),
  "mergeTitle": ("Merge?", "الدمج؟", []),
  "mergeBody": ("Merge {ref}? This can't be undone from here.", "دمج {ref}؟ لا يمكن التراجع عن هذا من هنا.", ["ref"]),
  "requestChangesHint": ("What needs to change?", "ما الذي يحتاج إلى تعديل؟", []),
  # ── Detail ──
  "detailActions": ("Actions", "الإجراءات", []),
  "detailMore": ("More", "المزيد", []),
  "detailNoDescription": ("No description.", "لا يوجد وصف.", []),
  "detailFilesChanged": ("Files changed · {count}", "الملفات المتغيّرة · {count}", ["count:int"]),
  "detailDiscussion": ("Discussion · {count}", "النقاش · {count}", ["count:int"]),
  "detailNoComments": ("No comments yet.", "لا توجد تعليقات بعد.", []),
  "detailNoDiff": ("No diff available (binary or too large). Open it in the browser.", "لا يتوفر عرض للتغييرات (ملف ثنائي أو كبير جدًا). افتحه في المتصفح.", []),
  "detailMoreLines": ("… {count} more lines. Open in the browser for the full diff.", "… {count} أسطر أخرى. افتح في المتصفح لعرض كل التغييرات.", ["count:int"]),
  "stateOpen": ("open", "مفتوح", []),
  "stateClosed": ("closed", "مغلق", []),
  "stateMerged": ("merged", "مدموج", []),
  "stateDraft": ("draft", "مسودة", []),
  # ── Workspaces ──
  "workspacesTitle": ("Workspaces", "مساحات العمل", []),
  "workspaceNew": ("New workspace", "مساحة عمل جديدة", []),
  "workspaceEmptyTitle": ("Group your work by client", "نظّم عملك حسب العميل", []),
  "workspaceEmptyBody": ("A workspace combines accounts and orgs from GitHub, GitLab or Azure DevOps under one client name, so your Inbox can show one client at a time.", "تجمع مساحة العمل حسابات ومؤسسات من GitHub أو GitLab أو Azure DevOps تحت اسم عميل واحد، ليعرض الوارد عميلًا واحدًا في كل مرة.", []),
  "workspaceNoAccounts": ("No accounts yet", "لا توجد حسابات بعد", []),
  "workspaceRemovedAccount": ("Removed account", "حساب محذوف", []),
  "workspaceNameLabel": ("Client / workspace name", "اسم العميل / مساحة العمل", []),
  "workspaceAccountsOrgs": ("Accounts & orgs", "الحسابات والمؤسسات", []),
  "workspaceOrgHelp": ("Leave the org field empty to include the whole account.", "اترك حقل المؤسسة فارغًا لتضمين الحساب كاملًا.", []),
  "workspaceAccountLabel": ("Account", "الحساب", []),
  "workspaceOrgLabel": ("Org / group (optional)", "المؤسسة / المجموعة (اختياري)", []),
  "tooltipRemove": ("Remove", "إزالة", []),
  "workspaceAddRule": ("Add account or org", "إضافة حساب أو مؤسسة", []),
  "delete": ("Delete", "حذف", []),
  "save": ("Save", "حفظ", []),
  # ── Connect form / login ──
  "connectAzureUrlLabel": ("Organisation URL (https://dev.azure.com/your-org)", "رابط المؤسسة (https://dev.azure.com/your-org)", []),
  "connectGitlabUrlLabel": ("Self-hosted GitLab URL (optional)", "رابط GitLab المستضاف ذاتيًا (اختياري)", []),
  "connectGiteaUrlLabel": ("Forgejo / Gitea URL (e.g. https://codeberg.org)", "رابط Forgejo / Gitea (مثل https://codeberg.org)", []),
  "giteaNeedsUrl": ("Forgejo / Gitea needs the server URL.", "يحتاج Forgejo / Gitea إلى رابط الخادم.", []),
  "connectGitlabUrlHint": ("Empty = gitlab.com", "فارغ = gitlab.com", []),
  "tokenLabel": ("Personal Access Token", "رمز الوصول الشخصي", []),
  "enterToken": ("Enter a token.", "أدخل الرمز.", []),
  "azureNeedsOrg": ("Azure DevOps needs an organisation URL.", "يحتاج Azure DevOps إلى رابط المؤسسة.", []),
  "invalidToken": ("Invalid token. Check the value and its scopes.", "الرمز غير صالح. تحقق من قيمته وصلاحياته.", []),
  "couldNotConnectUrl": ("Could not connect. Check the token and the URL.", "تعذّر الاتصال. تحقق من الرمز والرابط.", []),
  "couldNotConnectNet": ("Could not connect. Check the token and your internet connection.", "تعذّر الاتصال. تحقق من الرمز واتصالك بالإنترنت.", []),
  "showToken": ("Show token", "إظهار الرمز", []),
  "hideToken": ("Hide token", "إخفاء الرمز", []),
  "connecting": ("Connecting…", "جارٍ الاتصال…", []),
  "connect": ("Connect", "اتصال", []),
  "createTokenOn": ("Create a token on {provider}", "إنشاء رمز على {provider}", ["provider"]),
  "needsScopes": ("Needs: {scopes}", "الصلاحيات المطلوبة: {scopes}", ["scopes"]),
  "authTagline": ("One inbox for all your Git work.", "وارد واحد لكل عملك على Git.", []),
  "authSignInGithub": ("Sign in with GitHub", "تسجيل الدخول عبر GitHub", []),
  "authHideOther": ("Hide other options", "إخفاء الخيارات الأخرى", []),
  "authOtherOptions": ("GitLab, Azure DevOps or a token", "GitLab أو Azure DevOps أو رمز وصول", []),
  "deviceStep1": ("1. Open this URL in your browser:", "١. افتح هذا الرابط في المتصفح:", []),
  "deviceStep2": ("2. Enter this code:", "٢. أدخل هذا الرمز:", []),
  "codeCopied": ("Code copied!", "تم نسخ الرمز!", []),
  "deviceWaiting": ("Waiting for authorisation…", "بانتظار الموافقة…", []),
  # ── Settings ──
  "settingsTitle": ("Settings", "الإعدادات", []),
  "connectedAccounts": ("Connected Accounts", "الحسابات المتصلة", []),
  "addAccount": ("Add account", "إضافة حساب", []),
  "connectAccountTitle": ("Connect an account", "ربط حساب", []),
  "noAccountsConnected": ("No accounts connected. Tap \"Add account\" to connect.", "لا توجد حسابات متصلة. اضغط «إضافة حساب» للربط.", []),
  "removeProviderTitle": ("Remove {provider}", "إزالة {provider}", ["provider"]),
  "disconnectBody": ("Disconnect {account}? Its repos will be removed from the list.", "فصل {account}؟ ستُزال مستودعاته من القائمة.", ["account"]),
  "remove": ("Remove", "إزالة", []),
  "appearance": ("Appearance", "المظهر", []),
  "theme": ("Theme", "السمة", []),
  "themeSystem": ("System default", "افتراضي النظام", []),
  "themeLight": ("Light", "فاتح", []),
  "themeDark": ("Dark", "داكن", []),
  "language": ("Language", "اللغة", []),
  "languageSystem": ("System default", "افتراضي النظام", []),
  "notificationsSection": ("Notifications", "الإشعارات", []),
  "alertsTitle": ("Urgent inbox alerts", "تنبيهات الوارد العاجلة", []),
  "alertsBody": ("Failing CI, requested changes, conflicts and review requests. Checked in the background about every 30 minutes; iOS may run it less often.", "فشل CI وطلبات التعديل والتعارضات وطلبات المراجعة. يُفحص في الخلفية كل 30 دقيقة تقريبًا، وقد يقلّل iOS من هذا التكرار.", []),
  "alertsCheckNow": ("Check now", "افحص الآن", []),
  "alertsPermissionDenied": ("Notification permission was denied. Enable it in system settings.", "تم رفض إذن الإشعارات. فعّله من إعدادات النظام.", []),
  "alertsCouldNotChange": ("Could not change alerts: {error}", "تعذّر تغيير التنبيهات: {error}", ["error"]),
  "checkedNothing": ("Checked — nothing new.", "تم الفحص — لا جديد.", []),
  "checkedNew": ("Checked — {count, plural, one{1 new item} other{{count} new items}}.", "تم الفحص — {count, plural, =0{لا جديد} one{عنصر جديد} two{عنصران جديدان} few{{count} عناصر جديدة} many{{count} عنصرًا جديدًا} other{{count} عنصر جديد}}.", ["count:int"]),
  "checkFailed": ("Check failed: {error}", "فشل الفحص: {error}", ["error"]),
  "about": ("About", "حول", []),
  "aboutApp": ("App", "التطبيق", []),
  "aboutVersion": ("Version", "الإصدار", []),
  "aboutProviders": ("Providers", "المنصات", []),
  # ── Local notification ──
  "alertTitleMany": ("{count, plural, one{1 item needs your attention} other{{count} items need your attention}}", "{count, plural, one{عنصر واحد يحتاج انتباهك} two{عنصران يحتاجان انتباهك} few{{count} عناصر تحتاج انتباهك} many{{count} عنصرًا يحتاج انتباهك} other{{count} عنصر يحتاج انتباهك}}", ["count:int"]),
  "alertAndMore": ("and {count} more", "و{count} آخرين", ["count:int"]),
  "alertChannelName": ("Inbox alerts", "تنبيهات الوارد", []),
  "alertChannelDescription": ("Failing CI, review requests and other urgent items", "فشل CI وطلبات المراجعة وعناصر عاجلة أخرى", []),
}

# Strings of the repository-browser screens live in their own table.
from strings_legacy import LEGACY  # noqa: E402
S.update(LEGACY)


def arb(idx):
    d = {"@@locale": ["en", "ar"][idx]}
    for k, v in S.items():
        d[k] = v[idx]
        if idx == 0 and v[2]:
            d["@" + k] = {"placeholders": {
                p.split(":")[0]: ({"type": "int"} if p.endswith(":int") else {"type": "String"})
                for p in v[2]}}
    return d

for i, code in enumerate(["en", "ar"]):
    (OUT / f"app_{code}.arb").write_text(
        json.dumps(arb(i), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(len(S), "keys")
