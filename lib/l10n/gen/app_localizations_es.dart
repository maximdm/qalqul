// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class L10nEs extends L10n {
  L10nEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Qalqul';

  @override
  String get navHome => 'Inicio';

  @override
  String get navCalculator => 'Calc';

  @override
  String get navNotes => 'Notas';

  @override
  String get navFinance => 'Finanzas';

  @override
  String get commonSave => 'Guardar';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonDelete => 'Eliminar';

  @override
  String get commonEdit => 'Editar';

  @override
  String get commonDone => 'Listo';

  @override
  String get commonName => 'Nombre';

  @override
  String get commonCategory => 'Categoría';

  @override
  String get commonCurrency => 'Moneda';

  @override
  String get commonDate => 'Fecha';

  @override
  String get commonDeadline => 'Fecha límite';

  @override
  String get commonAmount => 'Importe';

  @override
  String get commonNote => 'Nota';

  @override
  String get commonAdd => 'Añadir';

  @override
  String get commonRetry => 'Reintentar';

  @override
  String get commonSearch => 'Buscar';

  @override
  String get homeNoWidgets => 'Aún no hay widgets';

  @override
  String get homeOpenStudio => 'Abrir Widgets Studio';

  @override
  String get widgetsStudioTitle => 'Widgets Studio';

  @override
  String get widgetsStudioEmpty => 'Aún no hay widgets: pulsa + para crear uno';

  @override
  String get widgetsNew => 'Nuevo widget';

  @override
  String get widgetsEdit => 'Editar widget';

  @override
  String get widgetsType => 'Tipo';

  @override
  String get widgetsTitleField => 'Título';

  @override
  String get widgetsSize => 'Tamaño';

  @override
  String get widgetsSizeSmall => 'Pequeño';

  @override
  String get widgetsSizeMedium => 'Mediano';

  @override
  String get widgetsSizeLarge => 'Grande';

  @override
  String get kindNoteSummary => 'Notas recientes';

  @override
  String get kindCalculator => 'Calculadora rápida';

  @override
  String get kindFinanceOverview => 'Resumen financiero';

  @override
  String get kindSpendingChart => 'Gráfico de gasto';

  @override
  String get kindNetWorth => 'Patrimonio neto';

  @override
  String get kindMonthSpend => 'Gasto del mes';

  @override
  String get kindPortfolioValue => 'Valor de cartera';

  @override
  String get kindBillsDue => 'Facturas próximas';

  @override
  String get widgetNoteEmpty => 'Aún no hay notas';

  @override
  String get widgetOpen => 'Abrir';

  @override
  String widgetInvested(String amount) {
    return 'Invertido $amount';
  }

  @override
  String widgetCredit(String amount) {
    return 'Crédito $amount';
  }

  @override
  String get widgetSpent => 'Gastado';

  @override
  String widgetAssetsCredit(String assets, String credit) {
    return 'Activos $assets · Crédito $credit';
  }

  @override
  String get widgetMonthSpend => 'Gastado este mes';

  @override
  String get widgetMonthSpendEmpty => 'Sin gastos este mes';

  @override
  String get widgetPortfolioEmpty => 'Aún no hay inversiones';

  @override
  String get widgetPortfolioValue => 'Valor de cartera';

  @override
  String widgetPortfolioCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count posiciones',
      one: '1 posición',
      zero: 'Sin posiciones',
    );
    return '$_temp0';
  }

  @override
  String get widgetBillsEmpty => 'Nada vence pronto';

  @override
  String widgetBillsDueIn(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days días',
      one: '1 día',
    );
    return 'Vence en $_temp0';
  }

  @override
  String get widgetBillsOverdue => 'Vencida';

  @override
  String widgetBillsWithin(int days) {
    return 'En $days días';
  }

  @override
  String get widgetLookaheadLabel => 'Antelación (días)';

  @override
  String get widgetMonthOffsetLabel => 'Desfase de mes';

  @override
  String get notesTitle => 'Notas';

  @override
  String get notesSearchHint => 'Buscar notas';

  @override
  String get notesEmpty => 'Aún no hay notas';

  @override
  String get notesUntitled => 'Sin título';

  @override
  String get noteNew => 'Nueva nota';

  @override
  String get noteEdit => 'Editar nota';

  @override
  String get noteTitleHint => 'Título';

  @override
  String get noteBodyHint =>
      'Escribe tu nota…  (escribe una expresión y luego \" = \" para calcularla)';

  @override
  String get noteEvaluateTooltip => 'Evaluar expresión';

  @override
  String get noteTabEdit => 'Editar';

  @override
  String get noteTabPreview => 'Vista previa';

  @override
  String get noteMarkdownTooltip => 'Markdown';

  @override
  String get notePreviewEmpty => 'Todavía no hay nada que previsualizar';

  @override
  String get noteEvalNoTarget =>
      'Coloca el cursor sobre una expresión para evaluarla';

  @override
  String get noteEvalFailed => 'No se pudo evaluar esa expresión';

  @override
  String noteAppended(String title) {
    return 'Añadido a $title';
  }

  @override
  String get noteNoNotesToAppend => 'Aún no hay notas: crea una primero';

  @override
  String get noteFromCalculation => 'Nueva nota desde el cálculo';

  @override
  String get noteAppendToExisting => 'Añadir a una nota';

  @override
  String get noteCalculationTitle => 'Cálculo';

  @override
  String get calculatorTitle => 'Calculadora';

  @override
  String get calculatorSendToNote => 'Enviar a nota';

  @override
  String get calculatorClearHistory => 'Borrar historial';

  @override
  String get calculatorHistory => 'Historial';

  @override
  String get calculatorCopyResult => 'Copiar resultado';

  @override
  String get calculatorError => 'Error';

  @override
  String get calculatorDegreesMode => 'Grados';

  @override
  String get calculatorScientificMode => 'Científica';

  @override
  String get calculatorNothingYet => 'Calcula algo primero';

  @override
  String calculatorMemory(String value) {
    return 'M = $value';
  }

  @override
  String get financeTitle => 'Finanzas';

  @override
  String get financeTabInvestments => 'Inversiones';

  @override
  String get financeTabSpending => 'Gasto';

  @override
  String get financeTabCredit => 'Crédito';

  @override
  String get financeTabBudget => 'Presupuesto';

  @override
  String get financeReorderTabs => 'Arrastra para reordenar las pestañas';

  @override
  String get investmentsEmpty => 'Aún no hay inversiones';

  @override
  String get investmentsAdd => 'Añadir inversión';

  @override
  String get investmentsEdit => 'Editar inversión';

  @override
  String get investmentsTotalValue => 'Valor total';

  @override
  String investmentsPrincipal(String amount) {
    return 'Capital $amount';
  }

  @override
  String get investmentsAsOf => 'A fecha de';

  @override
  String get investmentsName => 'Nombre';

  @override
  String get investmentsPrincipalField => 'Capital';

  @override
  String get investmentsCurrentValue => 'Valor actual';

  @override
  String get investmentsDefaultName => 'Inversión';

  @override
  String get spendingEmpty => 'No hay gastos registrados';

  @override
  String get spendingSpent => 'Gastado';

  @override
  String get spendingUncategorized => 'Sin categoría';

  @override
  String get creditEmpty => 'No hay crédito registrado';

  @override
  String get creditOutstanding => 'Crédito pendiente';

  @override
  String get creditLender => 'Prestamista';

  @override
  String get creditDueDate => 'Fecha de vencimiento';

  @override
  String get budgetEmpty => 'Aún no hay presupuestos';

  @override
  String get budgetAdd => 'Añadir presupuesto';

  @override
  String get budgetEdit => 'Editar presupuesto';

  @override
  String get budgetTargetField => 'Importe objetivo';

  @override
  String get budgetSavedField => 'Ahorrado hasta ahora';

  @override
  String get budgetDefaultName => 'Objetivo';

  @override
  String budgetSpent(String amount) {
    return 'Gastado $amount';
  }

  @override
  String budgetDueIn(int days, String date) {
    return 'Vence en $days días ($date)';
  }

  @override
  String budgetOverdueBy(int days, String date) {
    return 'Vencido hace $days días ($date)';
  }

  @override
  String get txAddEntry => 'Añadir entrada';

  @override
  String get txEditEntry => 'Editar entrada';

  @override
  String get txRecurring => 'Recurrente';

  @override
  String get txRepeat => 'Repetir';

  @override
  String get txRepeatDaily => 'Diario';

  @override
  String get txRepeatWeekly => 'Semanal';

  @override
  String get txRepeatMonthly => 'Mensual';

  @override
  String get txNextDue => 'Próximo vencimiento';

  @override
  String txRecurringDue(String date) {
    return 'vence $date';
  }

  @override
  String reminderDue(String name) {
    return 'Vence: $name';
  }

  @override
  String reminderBody(String recurrence, String amount) {
    return '$recurrence · $amount';
  }

  @override
  String get reminderChannelName => 'Recordatorios';

  @override
  String get reminderChannelDescription => 'Recordatorios de pagos recurrentes';

  @override
  String get searchNoMatches => 'Sin resultados';

  @override
  String get shortcutNewCalculation => 'Nuevo cálculo';

  @override
  String get shortcutNewNote => 'Nueva nota';

  @override
  String get searchStartTyping =>
      'Busca en notas, movimientos, inversiones y presupuestos';

  @override
  String get searchFailed => 'La búsqueda no está disponible ahora mismo';

  @override
  String searchNoMatchesFor(String query) {
    return 'Nada coincide con «$query»';
  }

  @override
  String searchMoreResults(int count) {
    return '+$count más — afina la búsqueda';
  }

  @override
  String get searchGroupNotes => 'Notas';

  @override
  String get searchGroupTransactions => 'Movimientos';

  @override
  String get searchGroupInvestments => 'Inversiones';

  @override
  String get searchGroupBudgets => 'Presupuestos';

  @override
  String get searchGroupOther => 'Otros';

  @override
  String get searchTitle => 'Buscar';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsAppearance => 'Apariencia';

  @override
  String get settingsThemeSystem => 'Sistema';

  @override
  String get settingsThemeLight => 'Claro';

  @override
  String get settingsThemeDark => 'Oscuro';

  @override
  String get settingsCurrencySection => 'Moneda';

  @override
  String get settingsBaseCurrency => 'Moneda de visualización';

  @override
  String get settingsBaseCurrencySubtitle =>
      'Los importes se convierten a esta moneda';

  @override
  String get settingsRates => 'Tipos de cambio';

  @override
  String get settingsRatesSubtitle =>
      'Tipos manuales: 1 unidad de la moneda base';

  @override
  String get settingsAddRate => 'Añadir tipo';

  @override
  String get settingsEditRate => 'Editar tipo';

  @override
  String get settingsRateEmpty => 'Aún no hay tipos de cambio';

  @override
  String get settingsRateFrom => 'De';

  @override
  String get settingsRateTo => 'A';

  @override
  String get settingsRateValue => 'Tipo';

  @override
  String get settingsRateInvalid =>
      'Introduce dos monedas distintas y un tipo mayor que 0';

  @override
  String get settingsRateSame => 'Elige dos monedas distintas';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsLanguageSystem => 'Idioma del sistema';

  @override
  String get settingsSecurity => 'Seguridad';

  @override
  String get settingsAppLock => 'Bloqueo de la app';

  @override
  String get settingsAppLockSubtitle => 'Pedir biometría al reabrir Qalqul';

  @override
  String get settingsAppLockBiometricOnly => 'Solo biometría';

  @override
  String get settingsAppLockBiometricOnlySubtitle =>
      'No permitir el desbloqueo con el código del dispositivo';

  @override
  String get settingsAppLockGrace => 'Bloquear tras pasar a segundo plano';

  @override
  String get settingsReplayTour => 'Repetir la guía de inicio';

  @override
  String get onboardingSkip => 'Omitir';

  @override
  String get onboardingNext => 'Siguiente';

  @override
  String get onboardingStart => 'Empezar';

  @override
  String get onboardingStartEmpty => 'Empezar vacío';

  @override
  String get onboardingWelcomeTitle => 'Bienvenido a Qalqul';

  @override
  String get onboardingWelcomeBody =>
      'Una calculadora, un cuaderno y tus finanzas en un solo sitio. Haz un recorrido rápido; puedes repetirlo desde Ajustes.';

  @override
  String get onboardingTrickTitle => 'Termina una línea con =';

  @override
  String get onboardingTrickBody =>
      'Las notas evalúan matemáticas mientras escribes y puedes reutilizar resultados anteriores como variables:';

  @override
  String get onboardingDashboardTitle => 'Crea tu panel';

  @override
  String get onboardingDashboardBody =>
      'Los widgets, movimientos y notas aparecen como tarjetas en la pantalla de inicio. Empezaremos con algunos ejemplos que puedes editar o borrar.';

  @override
  String get settingsAppLockNow => 'Bloquear ahora';

  @override
  String get settingsAppLockUnavailable =>
      'Este dispositivo no tiene biometría ni bloqueo de pantalla configurado';

  @override
  String get settingsBackup => 'Copia de seguridad';

  @override
  String get settingsExportJson => 'Exportar datos (JSON)';

  @override
  String get settingsExportJsonSubtitle =>
      'Guarda notas, finanzas y widgets en un archivo';

  @override
  String get settingsImportJson => 'Importar datos (JSON)';

  @override
  String get settingsImportJsonSubtitle =>
      'Reemplaza todos los datos desde una copia';

  @override
  String get settingsExportCsv => 'Exportar transacciones (CSV)';

  @override
  String get settingsExportCsvSubtitle =>
      'Guarda las transacciones en un archivo de hoja de cálculo';

  @override
  String get settingsImportConfirmTitle => '¿Importar copia de seguridad?';

  @override
  String get settingsImportConfirmBody =>
      'Esto reemplaza todas las notas, finanzas y widgets actuales con el contenido del archivo seleccionado.';

  @override
  String get settingsImport => 'Importar';

  @override
  String get settingsAbout => 'Acerca de';

  @override
  String settingsVersion(String version) {
    return 'Versión $version';
  }

  @override
  String get settingsLegalese =>
      'Gratuito para publicar · dependencias MIT/BSD';

  @override
  String get actionOk => 'Listo.';

  @override
  String get actionCancelled => 'Cancelado.';

  @override
  String get actionBadFile => 'Archivo de copia no válido.';

  @override
  String get lockTitle => 'Qalqul está bloqueado';

  @override
  String get lockUnlock => 'Desbloquear';

  @override
  String get lockFailed => 'No se pudo desbloquear: inténtalo de nuevo';

  @override
  String get lockUnavailableTitle => 'Bloqueo no disponible';

  @override
  String get lockUnavailableBody =>
      'Configura un bloqueo de pantalla o biometría en este dispositivo para usar el bloqueo de la app.';

  @override
  String get lockContinue => 'Continuar sin bloqueo';
}
