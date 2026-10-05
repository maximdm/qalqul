import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of L10n
/// returned by `L10n.of(context)`.
///
/// Applications need to include `L10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: L10n.localizationsDelegates,
///   supportedLocales: L10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the L10n.supportedLocales
/// property.
abstract class L10n {
  L10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static L10n of(BuildContext context) {
    return Localizations.of<L10n>(context, L10n)!;
  }

  static const LocalizationsDelegate<L10n> delegate = _L10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// Application name
  ///
  /// In en, this message translates to:
  /// **'Qalqul'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navCalculator.
  ///
  /// In en, this message translates to:
  /// **'Calc'**
  String get navCalculator;

  /// No description provided for @navNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get navNotes;

  /// No description provided for @navFinance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get navFinance;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @commonName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get commonName;

  /// No description provided for @commonCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get commonCategory;

  /// No description provided for @commonCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get commonCurrency;

  /// No description provided for @commonDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get commonDate;

  /// No description provided for @commonDeadline.
  ///
  /// In en, this message translates to:
  /// **'Deadline'**
  String get commonDeadline;

  /// No description provided for @commonAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get commonAmount;

  /// No description provided for @commonNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get commonNote;

  /// No description provided for @commonAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get commonAdd;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load your data'**
  String get commonLoadFailed;

  /// No description provided for @commonSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get commonSearch;

  /// No description provided for @homeNoWidgets.
  ///
  /// In en, this message translates to:
  /// **'No widgets yet'**
  String get homeNoWidgets;

  /// No description provided for @homeOpenStudio.
  ///
  /// In en, this message translates to:
  /// **'Open Widgets Studio'**
  String get homeOpenStudio;

  /// No description provided for @widgetsStudioTitle.
  ///
  /// In en, this message translates to:
  /// **'Widgets Studio'**
  String get widgetsStudioTitle;

  /// No description provided for @widgetsStudioEmpty.
  ///
  /// In en, this message translates to:
  /// **'No widgets yet — tap + to create one'**
  String get widgetsStudioEmpty;

  /// No description provided for @widgetsNew.
  ///
  /// In en, this message translates to:
  /// **'New widget'**
  String get widgetsNew;

  /// No description provided for @widgetsEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit widget'**
  String get widgetsEdit;

  /// No description provided for @widgetsType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get widgetsType;

  /// No description provided for @widgetsTitleField.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get widgetsTitleField;

  /// No description provided for @widgetsSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get widgetsSize;

  /// No description provided for @widgetsSizeSmall.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get widgetsSizeSmall;

  /// No description provided for @widgetsSizeMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get widgetsSizeMedium;

  /// No description provided for @widgetsSizeLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get widgetsSizeLarge;

  /// No description provided for @kindNoteSummary.
  ///
  /// In en, this message translates to:
  /// **'Recent notes'**
  String get kindNoteSummary;

  /// No description provided for @kindCalculator.
  ///
  /// In en, this message translates to:
  /// **'Quick calculator'**
  String get kindCalculator;

  /// No description provided for @kindFinanceOverview.
  ///
  /// In en, this message translates to:
  /// **'Finance overview'**
  String get kindFinanceOverview;

  /// No description provided for @kindSpendingChart.
  ///
  /// In en, this message translates to:
  /// **'Spending chart'**
  String get kindSpendingChart;

  /// No description provided for @kindNetWorth.
  ///
  /// In en, this message translates to:
  /// **'Net worth'**
  String get kindNetWorth;

  /// No description provided for @kindMonthSpend.
  ///
  /// In en, this message translates to:
  /// **'Month spend'**
  String get kindMonthSpend;

  /// No description provided for @kindPortfolioValue.
  ///
  /// In en, this message translates to:
  /// **'Portfolio value'**
  String get kindPortfolioValue;

  /// No description provided for @kindBillsDue.
  ///
  /// In en, this message translates to:
  /// **'Bills due'**
  String get kindBillsDue;

  /// No description provided for @widgetNoteEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notes yet'**
  String get widgetNoteEmpty;

  /// No description provided for @widgetOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get widgetOpen;

  /// No description provided for @widgetInvested.
  ///
  /// In en, this message translates to:
  /// **'Invested {amount}'**
  String widgetInvested(String amount);

  /// No description provided for @widgetCredit.
  ///
  /// In en, this message translates to:
  /// **'Credit {amount}'**
  String widgetCredit(String amount);

  /// No description provided for @widgetSpent.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get widgetSpent;

  /// No description provided for @widgetAssetsCredit.
  ///
  /// In en, this message translates to:
  /// **'Assets {assets} · Credit {credit}'**
  String widgetAssetsCredit(String assets, String credit);

  /// No description provided for @widgetMonthSpend.
  ///
  /// In en, this message translates to:
  /// **'Spent this month'**
  String get widgetMonthSpend;

  /// No description provided for @widgetMonthSpendEmpty.
  ///
  /// In en, this message translates to:
  /// **'No spending this month'**
  String get widgetMonthSpendEmpty;

  /// No description provided for @widgetPortfolioEmpty.
  ///
  /// In en, this message translates to:
  /// **'No investments yet'**
  String get widgetPortfolioEmpty;

  /// No description provided for @widgetPortfolioValue.
  ///
  /// In en, this message translates to:
  /// **'Portfolio value'**
  String get widgetPortfolioValue;

  /// No description provided for @widgetPortfolioCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No holdings} =1{1 holding} other{{count} holdings}}'**
  String widgetPortfolioCount(int count);

  /// No description provided for @widgetBillsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing due soon'**
  String get widgetBillsEmpty;

  /// No description provided for @widgetBillsDueIn.
  ///
  /// In en, this message translates to:
  /// **'Due in {days, plural, =1{1 day} other{{days} days}}'**
  String widgetBillsDueIn(int days);

  /// No description provided for @widgetBillsOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get widgetBillsOverdue;

  /// No description provided for @widgetBillsWithin.
  ///
  /// In en, this message translates to:
  /// **'Within {days} days'**
  String widgetBillsWithin(int days);

  /// No description provided for @widgetLookaheadLabel.
  ///
  /// In en, this message translates to:
  /// **'Look ahead (days)'**
  String get widgetLookaheadLabel;

  /// No description provided for @widgetMonthOffsetLabel.
  ///
  /// In en, this message translates to:
  /// **'Month offset'**
  String get widgetMonthOffsetLabel;

  /// No description provided for @notesTitle.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesTitle;

  /// No description provided for @notesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search notes'**
  String get notesSearchHint;

  /// No description provided for @notesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notes yet'**
  String get notesEmpty;

  /// No description provided for @notesUntitled.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get notesUntitled;

  /// No description provided for @noteNew.
  ///
  /// In en, this message translates to:
  /// **'New note'**
  String get noteNew;

  /// No description provided for @noteEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit note'**
  String get noteEdit;

  /// No description provided for @noteTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get noteTitleHint;

  /// No description provided for @noteBodyHint.
  ///
  /// In en, this message translates to:
  /// **'Write your note…  (type an expression then \" = \" to compute)'**
  String get noteBodyHint;

  /// No description provided for @noteEvaluateTooltip.
  ///
  /// In en, this message translates to:
  /// **'Evaluate expression'**
  String get noteEvaluateTooltip;

  /// No description provided for @noteTabEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get noteTabEdit;

  /// No description provided for @noteTabPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get noteTabPreview;

  /// No description provided for @noteMarkdownTooltip.
  ///
  /// In en, this message translates to:
  /// **'Markdown'**
  String get noteMarkdownTooltip;

  /// No description provided for @notePreviewEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing to preview yet'**
  String get notePreviewEmpty;

  /// No description provided for @noteEvalNoTarget.
  ///
  /// In en, this message translates to:
  /// **'Place the cursor on an expression to evaluate'**
  String get noteEvalNoTarget;

  /// No description provided for @noteEvalFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t evaluate that expression'**
  String get noteEvalFailed;

  /// No description provided for @noteAppended.
  ///
  /// In en, this message translates to:
  /// **'Appended to {title}'**
  String noteAppended(String title);

  /// No description provided for @noteNoNotesToAppend.
  ///
  /// In en, this message translates to:
  /// **'No notes yet — create one first'**
  String get noteNoNotesToAppend;

  /// No description provided for @noteFromCalculation.
  ///
  /// In en, this message translates to:
  /// **'New note from calculation'**
  String get noteFromCalculation;

  /// No description provided for @noteAppendToExisting.
  ///
  /// In en, this message translates to:
  /// **'Append to note'**
  String get noteAppendToExisting;

  /// No description provided for @noteCalculationTitle.
  ///
  /// In en, this message translates to:
  /// **'Calculation'**
  String get noteCalculationTitle;

  /// No description provided for @calculatorTitle.
  ///
  /// In en, this message translates to:
  /// **'Calculator'**
  String get calculatorTitle;

  /// No description provided for @calculatorSendToNote.
  ///
  /// In en, this message translates to:
  /// **'Send to note'**
  String get calculatorSendToNote;

  /// No description provided for @calculatorClearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear history'**
  String get calculatorClearHistory;

  /// No description provided for @calculatorHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get calculatorHistory;

  /// No description provided for @calculatorCopyResult.
  ///
  /// In en, this message translates to:
  /// **'Copy result'**
  String get calculatorCopyResult;

  /// No description provided for @calculatorError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get calculatorError;

  /// No description provided for @calculatorDegreesMode.
  ///
  /// In en, this message translates to:
  /// **'Degrees'**
  String get calculatorDegreesMode;

  /// No description provided for @calculatorScientificMode.
  ///
  /// In en, this message translates to:
  /// **'Scientific'**
  String get calculatorScientificMode;

  /// No description provided for @calculatorNothingYet.
  ///
  /// In en, this message translates to:
  /// **'Calculate something first'**
  String get calculatorNothingYet;

  /// No description provided for @calculatorMemory.
  ///
  /// In en, this message translates to:
  /// **'M = {value}'**
  String calculatorMemory(String value);

  /// No description provided for @financeTitle.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get financeTitle;

  /// No description provided for @financeTabInvestments.
  ///
  /// In en, this message translates to:
  /// **'Investments'**
  String get financeTabInvestments;

  /// No description provided for @financeTabSpending.
  ///
  /// In en, this message translates to:
  /// **'Spending'**
  String get financeTabSpending;

  /// No description provided for @financeTabCredit.
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get financeTabCredit;

  /// No description provided for @financeTabBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get financeTabBudget;

  /// No description provided for @financeReorderTabs.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder tabs'**
  String get financeReorderTabs;

  /// No description provided for @investmentsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No investments yet'**
  String get investmentsEmpty;

  /// No description provided for @investmentsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add investment'**
  String get investmentsAdd;

  /// No description provided for @investmentsEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit investment'**
  String get investmentsEdit;

  /// No description provided for @investmentsTotalValue.
  ///
  /// In en, this message translates to:
  /// **'Total value'**
  String get investmentsTotalValue;

  /// No description provided for @investmentsPrincipal.
  ///
  /// In en, this message translates to:
  /// **'Principal {amount}'**
  String investmentsPrincipal(String amount);

  /// No description provided for @investmentsAsOf.
  ///
  /// In en, this message translates to:
  /// **'As of'**
  String get investmentsAsOf;

  /// No description provided for @investmentsName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get investmentsName;

  /// No description provided for @investmentsPrincipalField.
  ///
  /// In en, this message translates to:
  /// **'Principal'**
  String get investmentsPrincipalField;

  /// No description provided for @investmentsCurrentValue.
  ///
  /// In en, this message translates to:
  /// **'Current value'**
  String get investmentsCurrentValue;

  /// No description provided for @investmentsDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Investment'**
  String get investmentsDefaultName;

  /// No description provided for @spendingEmpty.
  ///
  /// In en, this message translates to:
  /// **'No spending logged'**
  String get spendingEmpty;

  /// No description provided for @spendingSpent.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get spendingSpent;

  /// No description provided for @spendingUncategorized.
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get spendingUncategorized;

  /// No description provided for @creditEmpty.
  ///
  /// In en, this message translates to:
  /// **'No credit tracked'**
  String get creditEmpty;

  /// No description provided for @creditOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding credit'**
  String get creditOutstanding;

  /// No description provided for @creditLender.
  ///
  /// In en, this message translates to:
  /// **'Lender'**
  String get creditLender;

  /// No description provided for @creditDueDate.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get creditDueDate;

  /// No description provided for @budgetEmpty.
  ///
  /// In en, this message translates to:
  /// **'No budgets yet'**
  String get budgetEmpty;

  /// No description provided for @budgetAdd.
  ///
  /// In en, this message translates to:
  /// **'Add budget'**
  String get budgetAdd;

  /// No description provided for @budgetEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit budget'**
  String get budgetEdit;

  /// No description provided for @budgetTargetField.
  ///
  /// In en, this message translates to:
  /// **'Target amount'**
  String get budgetTargetField;

  /// Tooltip on a combined total that is missing some currencies
  ///
  /// In en, this message translates to:
  /// **'Partial total'**
  String get moneyPartialTotal;

  /// No description provided for @moneyPartialTotalBody.
  ///
  /// In en, this message translates to:
  /// **'{amount} could not be converted and is not included. Add an exchange rate to include it.'**
  String moneyPartialTotalBody(String amount);

  /// No description provided for @moneyMissingRates.
  ///
  /// In en, this message translates to:
  /// **'No exchange rate for {currencies}'**
  String moneyMissingRates(String currencies);

  /// No description provided for @budgetSavedField.
  ///
  /// In en, this message translates to:
  /// **'Saved so far'**
  String get budgetSavedField;

  /// No description provided for @budgetDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get budgetDefaultName;

  /// No description provided for @budgetSpent.
  ///
  /// In en, this message translates to:
  /// **'Spent {amount}'**
  String budgetSpent(String amount);

  /// No description provided for @budgetDueIn.
  ///
  /// In en, this message translates to:
  /// **'Due in {days} days ({date})'**
  String budgetDueIn(int days, String date);

  /// No description provided for @budgetOverdueBy.
  ///
  /// In en, this message translates to:
  /// **'Overdue by {days} days ({date})'**
  String budgetOverdueBy(int days, String date);

  /// No description provided for @txAddEntry.
  ///
  /// In en, this message translates to:
  /// **'Add entry'**
  String get txAddEntry;

  /// No description provided for @txEditEntry.
  ///
  /// In en, this message translates to:
  /// **'Edit entry'**
  String get txEditEntry;

  /// No description provided for @txRecurring.
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get txRecurring;

  /// No description provided for @txRepeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get txRepeat;

  /// No description provided for @txRepeatDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get txRepeatDaily;

  /// No description provided for @txRepeatWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get txRepeatWeekly;

  /// No description provided for @txRepeatMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get txRepeatMonthly;

  /// No description provided for @txNextDue.
  ///
  /// In en, this message translates to:
  /// **'Next due'**
  String get txNextDue;

  /// No description provided for @txRecurringDue.
  ///
  /// In en, this message translates to:
  /// **'due {date}'**
  String txRecurringDue(String date);

  /// No description provided for @reminderDue.
  ///
  /// In en, this message translates to:
  /// **'Due: {name}'**
  String reminderDue(String name);

  /// No description provided for @reminderBody.
  ///
  /// In en, this message translates to:
  /// **'{recurrence} · {amount}'**
  String reminderBody(String recurrence, String amount);

  /// No description provided for @reminderChannelName.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get reminderChannelName;

  /// No description provided for @reminderChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Recurring payment reminders'**
  String get reminderChannelDescription;

  /// No description provided for @searchNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get searchNoMatches;

  /// No description provided for @shortcutNewCalculation.
  ///
  /// In en, this message translates to:
  /// **'New calculation'**
  String get shortcutNewCalculation;

  /// No description provided for @shortcutNewNote.
  ///
  /// In en, this message translates to:
  /// **'New note'**
  String get shortcutNewNote;

  /// No description provided for @searchStartTyping.
  ///
  /// In en, this message translates to:
  /// **'Search notes, transactions, investments and budgets'**
  String get searchStartTyping;

  /// No description provided for @searchFailed.
  ///
  /// In en, this message translates to:
  /// **'Search is unavailable right now'**
  String get searchFailed;

  /// No description provided for @searchNoMatchesFor.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches “{query}”'**
  String searchNoMatchesFor(String query);

  /// No description provided for @searchMoreResults.
  ///
  /// In en, this message translates to:
  /// **'+{count} more — refine your search'**
  String searchMoreResults(int count);

  /// No description provided for @searchGroupNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get searchGroupNotes;

  /// No description provided for @searchGroupTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get searchGroupTransactions;

  /// No description provided for @searchGroupInvestments.
  ///
  /// In en, this message translates to:
  /// **'Investments'**
  String get searchGroupInvestments;

  /// No description provided for @searchGroupBudgets.
  ///
  /// In en, this message translates to:
  /// **'Budgets'**
  String get searchGroupBudgets;

  /// No description provided for @searchGroupOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get searchGroupOther;

  /// No description provided for @searchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsCurrencySection.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get settingsCurrencySection;

  /// No description provided for @settingsBaseCurrency.
  ///
  /// In en, this message translates to:
  /// **'Display currency'**
  String get settingsBaseCurrency;

  /// No description provided for @settingsBaseCurrencySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Finance amounts are converted to this currency'**
  String get settingsBaseCurrencySubtitle;

  /// No description provided for @settingsRates.
  ///
  /// In en, this message translates to:
  /// **'Exchange rates'**
  String get settingsRates;

  /// No description provided for @settingsRatesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manual rates — 1 unit of the base currency'**
  String get settingsRatesSubtitle;

  /// No description provided for @settingsAddRate.
  ///
  /// In en, this message translates to:
  /// **'Add rate'**
  String get settingsAddRate;

  /// No description provided for @settingsEditRate.
  ///
  /// In en, this message translates to:
  /// **'Edit rate'**
  String get settingsEditRate;

  /// No description provided for @settingsRateEmpty.
  ///
  /// In en, this message translates to:
  /// **'No exchange rates yet'**
  String get settingsRateEmpty;

  /// No description provided for @settingsRateFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get settingsRateFrom;

  /// No description provided for @settingsRateTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get settingsRateTo;

  /// No description provided for @settingsRateValue.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get settingsRateValue;

  /// No description provided for @settingsRateInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter two different currencies and a rate above 0'**
  String get settingsRateInvalid;

  /// No description provided for @settingsRateSame.
  ///
  /// In en, this message translates to:
  /// **'Pick two different currencies'**
  String get settingsRateSame;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get settingsSecurity;

  /// No description provided for @settingsAppLock.
  ///
  /// In en, this message translates to:
  /// **'App lock'**
  String get settingsAppLock;

  /// No description provided for @settingsAppLockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Require biometrics when reopening Qalqul'**
  String get settingsAppLockSubtitle;

  /// No description provided for @settingsAppLockBiometricOnly.
  ///
  /// In en, this message translates to:
  /// **'Biometrics only'**
  String get settingsAppLockBiometricOnly;

  /// No description provided for @settingsAppLockBiometricOnlySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Disallow the device passcode fallback'**
  String get settingsAppLockBiometricOnlySubtitle;

  /// No description provided for @settingsAppLockGrace.
  ///
  /// In en, this message translates to:
  /// **'Lock after backgrounding'**
  String get settingsAppLockGrace;

  /// No description provided for @settingsReplayTour.
  ///
  /// In en, this message translates to:
  /// **'Replay intro tour'**
  String get settingsReplayTour;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingStart.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardingStart;

  /// No description provided for @onboardingStartEmpty.
  ///
  /// In en, this message translates to:
  /// **'Start empty'**
  String get onboardingStartEmpty;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Qalqul'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'A calculator, a notebook and your money in one place. Take a short tour — you can always replay it from Settings.'**
  String get onboardingWelcomeBody;

  /// No description provided for @onboardingTrickTitle.
  ///
  /// In en, this message translates to:
  /// **'End a line with ='**
  String get onboardingTrickTitle;

  /// No description provided for @onboardingTrickBody.
  ///
  /// In en, this message translates to:
  /// **'Notes evaluate math while you type, and you can reuse earlier results as variables:'**
  String get onboardingTrickBody;

  /// No description provided for @onboardingDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Build your dashboard'**
  String get onboardingDashboardTitle;

  /// No description provided for @onboardingDashboardBody.
  ///
  /// In en, this message translates to:
  /// **'Widgets, transactions and notes show up as cards on your home screen. We\'ll start with a few examples you can edit or delete.'**
  String get onboardingDashboardBody;

  /// No description provided for @settingsAppLockNow.
  ///
  /// In en, this message translates to:
  /// **'Lock now'**
  String get settingsAppLockNow;

  /// No description provided for @settingsAppLockUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No biometrics or screen lock is enrolled on this device'**
  String get settingsAppLockUnavailable;

  /// No description provided for @settingsBackup.
  ///
  /// In en, this message translates to:
  /// **'Backup & restore'**
  String get settingsBackup;

  /// No description provided for @settingsExportJson.
  ///
  /// In en, this message translates to:
  /// **'Export data (JSON)'**
  String get settingsExportJson;

  /// No description provided for @settingsExportJsonSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save all notes, finance & widgets to a file'**
  String get settingsExportJsonSubtitle;

  /// No description provided for @settingsImportJson.
  ///
  /// In en, this message translates to:
  /// **'Import data (JSON)'**
  String get settingsImportJson;

  /// No description provided for @settingsImportJsonSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Replace all data from a backup file'**
  String get settingsImportJsonSubtitle;

  /// No description provided for @settingsExportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export transactions (CSV)'**
  String get settingsExportCsv;

  /// No description provided for @settingsExportCsvSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save transactions to a spreadsheet file'**
  String get settingsExportCsvSubtitle;

  /// No description provided for @settingsImportConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Import backup?'**
  String get settingsImportConfirmTitle;

  /// No description provided for @settingsImportConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This replaces all current notes, finance data and widgets with the contents of the selected file.'**
  String get settingsImportConfirmBody;

  /// No description provided for @settingsImport.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get settingsImport;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String settingsVersion(String version);

  /// No description provided for @settingsLegalese.
  ///
  /// In en, this message translates to:
  /// **'Free to publish · MIT/BSD dependencies'**
  String get settingsLegalese;

  /// No description provided for @actionOk.
  ///
  /// In en, this message translates to:
  /// **'Done.'**
  String get actionOk;

  /// No description provided for @actionCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled.'**
  String get actionCancelled;

  /// No description provided for @actionBadFile.
  ///
  /// In en, this message translates to:
  /// **'Invalid backup file.'**
  String get actionBadFile;

  /// No description provided for @lockTitle.
  ///
  /// In en, this message translates to:
  /// **'Qalqul is locked'**
  String get lockTitle;

  /// No description provided for @lockUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get lockUnlock;

  /// No description provided for @lockFailed.
  ///
  /// In en, this message translates to:
  /// **'Unlock failed — try again'**
  String get lockFailed;

  /// No description provided for @lockUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'App lock unavailable'**
  String get lockUnavailableTitle;

  /// No description provided for @lockUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'Set up a screen lock or biometrics on this device to use app lock.'**
  String get lockUnavailableBody;

  /// No description provided for @lockContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue without lock'**
  String get lockContinue;
}

class _L10nDelegate extends LocalizationsDelegate<L10n> {
  const _L10nDelegate();

  @override
  Future<L10n> load(Locale locale) {
    return SynchronousFuture<L10n>(lookupL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_L10nDelegate old) => false;
}

L10n lookupL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return L10nEn();
    case 'es':
      return L10nEs();
  }

  throw FlutterError(
    'L10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
