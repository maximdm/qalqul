export 'package:qalqul/l10n/gen/app_localizations.dart';

import 'package:flutter/widgets.dart';

import 'package:qalqul/core/models/user_widget.dart';
import 'package:qalqul/l10n/gen/app_localizations.dart';

/// Shorthand for `L10n.of(context)`.
extension L10nContext on BuildContext {
  L10n get l10n => L10n.of(this);
}

/// Maps widget kinds to their localized studio labels. Keeping the mapping here
/// means adding a `UserWidgetKind` only needs a matching ARB message.
extension L10nWidgetKinds on L10n {
  String kindLabel(UserWidgetKind kind) => switch (kind) {
        UserWidgetKind.noteSummary => kindNoteSummary,
        UserWidgetKind.calculator => kindCalculator,
        UserWidgetKind.financeOverview => kindFinanceOverview,
        UserWidgetKind.spendingChart => kindSpendingChart,
        UserWidgetKind.netWorth => kindNetWorth,
        UserWidgetKind.monthSpend => kindMonthSpend,
        UserWidgetKind.portfolioValue => kindPortfolioValue,
        UserWidgetKind.billsDue => kindBillsDue,
      };
}