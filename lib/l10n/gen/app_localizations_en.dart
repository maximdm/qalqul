// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class L10nEn extends L10n {
  L10nEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Qalqul';

  @override
  String get navHome => 'Home';

  @override
  String get navCalculator => 'Calc';

  @override
  String get navNotes => 'Notes';

  @override
  String get navFinance => 'Finance';

  @override
  String get commonSave => 'Save';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonDone => 'Done';

  @override
  String get commonName => 'Name';

  @override
  String get commonCategory => 'Category';

  @override
  String get commonCurrency => 'Currency';

  @override
  String get commonDate => 'Date';

  @override
  String get commonDeadline => 'Deadline';

  @override
  String get commonAmount => 'Amount';

  @override
  String get commonNote => 'Note';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonSearch => 'Search';

  @override
  String get homeNoWidgets => 'No widgets yet';

  @override
  String get homeOpenStudio => 'Open Widgets Studio';

  @override
  String get widgetsStudioTitle => 'Widgets Studio';

  @override
  String get widgetsStudioEmpty => 'No widgets yet — tap + to create one';

  @override
  String get widgetsNew => 'New widget';

  @override
  String get widgetsEdit => 'Edit widget';

  @override
  String get widgetsType => 'Type';

  @override
  String get widgetsTitleField => 'Title';

  @override
  String get widgetsSize => 'Size';

  @override
  String get widgetsSizeSmall => 'Small';

  @override
  String get widgetsSizeMedium => 'Medium';

  @override
  String get widgetsSizeLarge => 'Large';

  @override
  String get kindNoteSummary => 'Recent notes';

  @override
  String get kindCalculator => 'Quick calculator';

  @override
  String get kindFinanceOverview => 'Finance overview';

  @override
  String get kindSpendingChart => 'Spending chart';

  @override
  String get kindNetWorth => 'Net worth';

  @override
  String get kindMonthSpend => 'Month spend';

  @override
  String get kindPortfolioValue => 'Portfolio value';

  @override
  String get kindBillsDue => 'Bills due';

  @override
  String get widgetNoteEmpty => 'No notes yet';

  @override
  String get widgetOpen => 'Open';

  @override
  String widgetInvested(String amount) {
    return 'Invested $amount';
  }

  @override
  String widgetCredit(String amount) {
    return 'Credit $amount';
  }

  @override
  String get widgetSpent => 'Spent';

  @override
  String widgetAssetsCredit(String assets, String credit) {
    return 'Assets $assets · Credit $credit';
  }

  @override
  String get widgetMonthSpend => 'Spent this month';

  @override
  String get widgetMonthSpendEmpty => 'No spending this month';

  @override
  String get widgetPortfolioEmpty => 'No investments yet';

  @override
  String get widgetPortfolioValue => 'Portfolio value';

  @override
  String widgetPortfolioCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count holdings',
      one: '1 holding',
      zero: 'No holdings',
    );
    return '$_temp0';
  }

  @override
  String get widgetBillsEmpty => 'Nothing due soon';

  @override
  String widgetBillsDueIn(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return 'Due in $_temp0';
  }

  @override
  String get widgetBillsOverdue => 'Overdue';

  @override
  String widgetBillsWithin(int days) {
    return 'Within $days days';
  }

  @override
  String get widgetLookaheadLabel => 'Look ahead (days)';

  @override
  String get widgetMonthOffsetLabel => 'Month offset';

  @override
  String get notesTitle => 'Notes';

  @override
  String get notesSearchHint => 'Search notes';

  @override
  String get notesEmpty => 'No notes yet';

  @override
  String get notesUntitled => 'Untitled';

  @override
  String get noteNew => 'New note';

  @override
  String get noteEdit => 'Edit note';

  @override
  String get noteTitleHint => 'Title';

  @override
  String get noteBodyHint =>
      'Write your note…  (type an expression then \" = \" to compute)';

  @override
  String get noteEvaluateTooltip => 'Evaluate expression';

  @override
  String get noteTabEdit => 'Edit';

  @override
  String get noteTabPreview => 'Preview';

  @override
  String get noteMarkdownTooltip => 'Markdown';

  @override
  String get notePreviewEmpty => 'Nothing to preview yet';

  @override
  String get noteEvalNoTarget =>
      'Place the cursor on an expression to evaluate';

  @override
  String get noteEvalFailed => 'Couldn\'t evaluate that expression';

  @override
  String noteAppended(String title) {
    return 'Appended to $title';
  }

  @override
  String get noteNoNotesToAppend => 'No notes yet — create one first';

  @override
  String get noteFromCalculation => 'New note from calculation';

  @override
  String get noteAppendToExisting => 'Append to note';

  @override
  String get noteCalculationTitle => 'Calculation';

  @override
  String get calculatorTitle => 'Calculator';

  @override
  String get calculatorSendToNote => 'Send to note';

  @override
  String get calculatorClearHistory => 'Clear history';

  @override
  String get calculatorHistory => 'History';

  @override
  String get calculatorCopyResult => 'Copy result';

  @override
  String get calculatorError => 'Error';

  @override
  String get calculatorDegreesMode => 'Degrees';

  @override
  String get calculatorScientificMode => 'Scientific';

  @override
  String get calculatorNothingYet => 'Calculate something first';

  @override
  String calculatorMemory(String value) {
    return 'M = $value';
  }

  @override
  String get financeTitle => 'Finance';

  @override
  String get financeTabInvestments => 'Investments';

  @override
  String get financeTabSpending => 'Spending';

  @override
  String get financeTabCredit => 'Credit';

  @override
  String get financeTabBudget => 'Budget';

  @override
  String get financeReorderTabs => 'Drag to reorder tabs';

  @override
  String get investmentsEmpty => 'No investments yet';

  @override
  String get investmentsAdd => 'Add investment';

  @override
  String get investmentsEdit => 'Edit investment';

  @override
  String get investmentsTotalValue => 'Total value';

  @override
  String investmentsPrincipal(String amount) {
    return 'Principal $amount';
  }

  @override
  String get investmentsAsOf => 'As of';

  @override
  String get investmentsName => 'Name';

  @override
  String get investmentsPrincipalField => 'Principal';

  @override
  String get investmentsCurrentValue => 'Current value';

  @override
  String get investmentsDefaultName => 'Investment';

  @override
  String get spendingEmpty => 'No spending logged';

  @override
  String get spendingSpent => 'Spent';

  @override
  String get spendingUncategorized => 'Uncategorized';

  @override
  String get creditEmpty => 'No credit tracked';

  @override
  String get creditOutstanding => 'Outstanding credit';

  @override
  String get creditLender => 'Lender';

  @override
  String get creditDueDate => 'Due date';

  @override
  String get budgetEmpty => 'No budgets yet';

  @override
  String get budgetAdd => 'Add budget';

  @override
  String get budgetEdit => 'Edit budget';

  @override
  String get budgetTargetField => 'Target amount';

  @override
  String get moneyPartialTotal => 'Partial total';

  @override
  String moneyPartialTotalBody(String amount) {
    return '$amount could not be converted and is not included. Add an exchange rate to include it.';
  }

  @override
  String moneyMissingRates(String currencies) {
    return 'No exchange rate for $currencies';
  }

  @override
  String get budgetSavedField => 'Saved so far';

  @override
  String get budgetDefaultName => 'Goal';

  @override
  String budgetSpent(String amount) {
    return 'Spent $amount';
  }

  @override
  String budgetDueIn(int days, String date) {
    return 'Due in $days days ($date)';
  }

  @override
  String budgetOverdueBy(int days, String date) {
    return 'Overdue by $days days ($date)';
  }

  @override
  String get txAddEntry => 'Add entry';

  @override
  String get txEditEntry => 'Edit entry';

  @override
  String get txRecurring => 'Recurring';

  @override
  String get txRepeat => 'Repeat';

  @override
  String get txRepeatDaily => 'Daily';

  @override
  String get txRepeatWeekly => 'Weekly';

  @override
  String get txRepeatMonthly => 'Monthly';

  @override
  String get txNextDue => 'Next due';

  @override
  String txRecurringDue(String date) {
    return 'due $date';
  }

  @override
  String reminderDue(String name) {
    return 'Due: $name';
  }

  @override
  String reminderBody(String recurrence, String amount) {
    return '$recurrence · $amount';
  }

  @override
  String get reminderChannelName => 'Reminders';

  @override
  String get reminderChannelDescription => 'Recurring payment reminders';

  @override
  String get searchNoMatches => 'No matches';

  @override
  String get shortcutNewCalculation => 'New calculation';

  @override
  String get shortcutNewNote => 'New note';

  @override
  String get searchStartTyping =>
      'Search notes, transactions, investments and budgets';

  @override
  String get searchFailed => 'Search is unavailable right now';

  @override
  String searchNoMatchesFor(String query) {
    return 'Nothing matches “$query”';
  }

  @override
  String searchMoreResults(int count) {
    return '+$count more — refine your search';
  }

  @override
  String get searchGroupNotes => 'Notes';

  @override
  String get searchGroupTransactions => 'Transactions';

  @override
  String get searchGroupInvestments => 'Investments';

  @override
  String get searchGroupBudgets => 'Budgets';

  @override
  String get searchGroupOther => 'Other';

  @override
  String get searchTitle => 'Search';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsCurrencySection => 'Currency';

  @override
  String get settingsBaseCurrency => 'Display currency';

  @override
  String get settingsBaseCurrencySubtitle =>
      'Finance amounts are converted to this currency';

  @override
  String get settingsRates => 'Exchange rates';

  @override
  String get settingsRatesSubtitle =>
      'Manual rates — 1 unit of the base currency';

  @override
  String get settingsAddRate => 'Add rate';

  @override
  String get settingsEditRate => 'Edit rate';

  @override
  String get settingsRateEmpty => 'No exchange rates yet';

  @override
  String get settingsRateFrom => 'From';

  @override
  String get settingsRateTo => 'To';

  @override
  String get settingsRateValue => 'Rate';

  @override
  String get settingsRateInvalid =>
      'Enter two different currencies and a rate above 0';

  @override
  String get settingsRateSame => 'Pick two different currencies';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'System default';

  @override
  String get settingsSecurity => 'Security';

  @override
  String get settingsAppLock => 'App lock';

  @override
  String get settingsAppLockSubtitle =>
      'Require biometrics when reopening Qalqul';

  @override
  String get settingsAppLockBiometricOnly => 'Biometrics only';

  @override
  String get settingsAppLockBiometricOnlySubtitle =>
      'Disallow the device passcode fallback';

  @override
  String get settingsAppLockGrace => 'Lock after backgrounding';

  @override
  String get settingsReplayTour => 'Replay intro tour';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingStart => 'Get started';

  @override
  String get onboardingStartEmpty => 'Start empty';

  @override
  String get onboardingWelcomeTitle => 'Welcome to Qalqul';

  @override
  String get onboardingWelcomeBody =>
      'A calculator, a notebook and your money in one place. Take a short tour — you can always replay it from Settings.';

  @override
  String get onboardingTrickTitle => 'End a line with =';

  @override
  String get onboardingTrickBody =>
      'Notes evaluate math while you type, and you can reuse earlier results as variables:';

  @override
  String get onboardingDashboardTitle => 'Build your dashboard';

  @override
  String get onboardingDashboardBody =>
      'Widgets, transactions and notes show up as cards on your home screen. We\'ll start with a few examples you can edit or delete.';

  @override
  String get settingsAppLockNow => 'Lock now';

  @override
  String get settingsAppLockUnavailable =>
      'No biometrics or screen lock is enrolled on this device';

  @override
  String get settingsBackup => 'Backup & restore';

  @override
  String get settingsExportJson => 'Export data (JSON)';

  @override
  String get settingsExportJsonSubtitle =>
      'Save all notes, finance & widgets to a file';

  @override
  String get settingsImportJson => 'Import data (JSON)';

  @override
  String get settingsImportJsonSubtitle =>
      'Replace all data from a backup file';

  @override
  String get settingsExportCsv => 'Export transactions (CSV)';

  @override
  String get settingsExportCsvSubtitle =>
      'Save transactions to a spreadsheet file';

  @override
  String get settingsImportConfirmTitle => 'Import backup?';

  @override
  String get settingsImportConfirmBody =>
      'This replaces all current notes, finance data and widgets with the contents of the selected file.';

  @override
  String get settingsImport => 'Import';

  @override
  String get settingsAbout => 'About';

  @override
  String settingsVersion(String version) {
    return 'Version $version';
  }

  @override
  String get settingsLegalese => 'Free to publish · MIT/BSD dependencies';

  @override
  String get actionOk => 'Done.';

  @override
  String get actionCancelled => 'Cancelled.';

  @override
  String get actionBadFile => 'Invalid backup file.';

  @override
  String get lockTitle => 'Qalqul is locked';

  @override
  String get lockUnlock => 'Unlock';

  @override
  String get lockFailed => 'Unlock failed — try again';

  @override
  String get lockUnavailableTitle => 'App lock unavailable';

  @override
  String get lockUnavailableBody =>
      'Set up a screen lock or biometrics on this device to use app lock.';

  @override
  String get lockContinue => 'Continue without lock';
}
