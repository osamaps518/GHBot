import 'package:flutter/material.dart';

import '../core/database.dart';
import '../core/typed_number.dart';
import '../l10n/app_localizations.dart';
import 'food.dart';

/// The four values per 100 g the form asks for, named as
/// `targetsFieldLabel` names them, each with its most in tenths.
enum _Value {
  calories(maxCaloriesPer100g),
  protein(maxMacroPer100g),
  carbs(maxMacroPer100g),
  fat(maxMacroPer100g);

  const _Value(this.max);
  final int max;
}

/// The form for a new own food: names, an optional barcode and the values
/// per 100 g. Save checks them as the server does (decision 38), keeps the
/// food on the phone, which works offline, and closes with it, unless Back
/// closed the form while it saved.
class OwnFoodFormScreen extends StatefulWidget {
  const OwnFoodFormScreen({super.key, required this.database, this.name});

  final AppDatabase database;

  /// A name to start with: the text searched for. It goes in the Arabic
  /// field when it has an Arabic letter, otherwise in the English one.
  final String? name;

  @override
  State<OwnFoodFormScreen> createState() => _OwnFoodFormScreenState();
}

class _OwnFoodFormScreenState extends State<OwnFoodFormScreen> {
  late final _startsArabic = RegExp(
    r'\p{Script=Arabic}',
    unicode: true,
  ).hasMatch(widget.name ?? '');
  late final _nameAr = TextEditingController(
    text: _startsArabic ? widget.name : null,
  );
  late final _nameEn = TextEditingController(
    text: _startsArabic ? null : widget.name,
  );
  final _barcode = TextEditingController();
  final _values = {
    for (final value in _Value.values) value: TextEditingController(),
  };

  /// Set once Save was tapped with values the server would refuse: from
  /// then on, the form shows what to fix as it changes.
  var _showErrors = false;
  var _saving = false;

  @override
  void dispose() {
    for (final controller in [_nameAr, _nameEn, _barcode, ..._values.values]) {
      controller.dispose();
    }
    super.dispose();
  }

  _Draft get _draft => _Draft(
    nameAr: _nameAr.text,
    nameEn: _nameEn.text,
    barcode: _barcode.text,
    values: {
      for (final MapEntry(key: value, value: controller) in _values.entries)
        value: controller.text,
    },
  );

  Future<void> _save() async {
    final draft = _draft;
    final per100g = draft.per100g;
    if (!draft.valid || per100g == null) {
      setState(() => _showErrors = true);
      return;
    }
    setState(() => _saving = true);
    final food = await widget.database.addOwnFood(
      nameAr: draft.nameAr,
      nameEn: draft.nameEn,
      per100g: per100g,
      barcode: draft.barcode,
    );
    if (mounted && ModalRoute.of(context)!.isCurrent) {
      Navigator.pop(context, food);
    }
  }

  void _changed() => setState(() {});

  /// Save sits below the scrolling part, so the keyboard doesn't cover it.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final draft = _draft;
    final errors = _showErrors ? draft : null;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.newFood)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  _Names(
                    nameAr: _nameAr,
                    nameEn: _nameEn,
                    errors: errors,
                    onChanged: _changed,
                  ),
                  const SizedBox(height: 16),
                  _BarcodeField(
                    controller: _barcode,
                    error: errors?.barcodeWrong ?? false,
                    onChanged: _changed,
                  ),
                  const SizedBox(height: 20),
                  const _ValuesHeading(),
                  const SizedBox(height: 12),
                  for (final value in _Value.values) ...[
                    _ValueField(
                      value: value,
                      controller: _values[value]!,
                      error: errors?.wrongValues.contains(value) ?? false,
                      onChanged: _changed,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (errors?.macrosOver100g ?? false) const _MacrosOver100g(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(l10n.save),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// What the form holds, read as the server takes it: names trimmed, an
/// empty name or barcode as none, digits as Western ones, values in tenths.
class _Draft {
  _Draft({
    required String nameAr,
    required String nameEn,
    required String barcode,
    required Map<_Value, String> values,
  }) : nameAr = _orNone(nameAr.trim()),
       nameEn = _orNone(nameEn.trim()),
       barcode = _orNone(westernNumberText(barcode)),
       tenths = {
         for (final MapEntry(key: value, value: typed) in values.entries)
           value: parsePer100g(typed, value.max),
       };

  final String? nameAr;
  final String? nameEn;
  final String? barcode;

  /// Each value in tenths, or null when it isn't one the server takes.
  final Map<_Value, int?> tenths;

  bool get noName => nameAr == null && nameEn == null;
  bool get nameArWrong => !ownFoodNameFits(nameAr);
  bool get nameEnWrong => !ownFoodNameFits(nameEn);
  bool get barcodeWrong => !ownFoodBarcodeFits(barcode);

  Set<_Value> get wrongValues => {
    for (final MapEntry(key: value, value: tenths) in tenths.entries)
      if (tenths == null) value,
  };

  /// The four values, once each is one the server takes.
  Nutrients? get per100g => wrongValues.isEmpty
      ? Nutrients(
          calories: tenths[_Value.calories]!,
          protein: tenths[_Value.protein]!,
          carbs: tenths[_Value.carbs]!,
          fat: tenths[_Value.fat]!,
        )
      : null;

  /// Whether protein, carbs and fat, once all typed right, add up to more
  /// than 100 g.
  bool get macrosOver100g => switch ((
    tenths[_Value.protein],
    tenths[_Value.carbs],
    tenths[_Value.fat],
  )) {
    (final int protein, final int carbs, final int fat) =>
      protein + carbs + fat > maxMacroPer100g,
    _ => false,
  };

  /// Whether the server would take the food.
  bool get valid => switch (per100g) {
    final per100g? => passesOwnFoodChecks(
      nameAr: nameAr,
      nameEn: nameEn,
      per100g: per100g,
      barcode: barcode,
    ),
    null => false,
  };

  static String? _orNone(String text) => text.isEmpty ? null : text;
}

/// The Arabic and English name fields, with the hint that one is enough
/// below them, in the error color when neither is given.
class _Names extends StatelessWidget {
  const _Names({
    required this.nameAr,
    required this.nameEn,
    required this.errors,
    required this.onChanged,
  });

  final TextEditingController nameAr;
  final TextEditingController nameEn;

  /// The draft to show errors for, or null while none show.
  final _Draft? errors;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final noName = errors?.noName ?? false;
    final nameArWrong = errors?.nameArWrong ?? false;
    final nameEnWrong = errors?.nameEnWrong ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LabeledField(
          fieldKey: 'nameAr',
          label: l10n.nameInArabic,
          controller: nameAr,
          error: noName || nameArWrong,
          errorText: nameArWrong ? l10n.errorFoodName : null,
          onChanged: onChanged,
        ),
        const SizedBox(height: 16),
        _LabeledField(
          fieldKey: 'nameEn',
          label: l10n.nameInEnglish,
          controller: nameEn,
          error: noName || nameEnWrong,
          errorText: nameEnWrong ? l10n.errorFoodName : null,
          onChanged: onChanged,
        ),
        const SizedBox(height: 6),
        Text(
          l10n.namesHint,
          style: theme.textTheme.bodySmall!.copyWith(
            color: noName ? colors.error : colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// A label above a text field, and an error below it when [errorText] is
/// set. [error] marks the label and the field in the error color.
class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.fieldKey,
    required this.label,
    required this.controller,
    required this.error,
    required this.errorText,
    required this.onChanged,
    this.keyboardType,
  });

  final String fieldKey;
  final String label;
  final TextEditingController controller;
  final bool error;
  final String? errorText;
  final VoidCallback onChanged;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 6,
      children: [
        Text(
          label,
          style: theme.textTheme.titleSmall!.copyWith(
            color: error ? colors.error : null,
          ),
        ),
        TextField(
          key: ValueKey(fieldKey),
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            error: error ? const SizedBox.shrink() : null,
          ),
          onChanged: (_) => onChanged(),
        ),
        if (errorText case final text?)
          Text(
            text,
            style: theme.textTheme.bodySmall!.copyWith(color: colors.error),
          ),
      ],
    );
  }
}

class _BarcodeField extends StatelessWidget {
  const _BarcodeField({
    required this.controller,
    required this.error,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool error;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _LabeledField(
      fieldKey: 'barcode',
      label: l10n.barcodeOptional,
      controller: controller,
      error: error,
      errorText: error ? l10n.errorBarcode : null,
      keyboardType: TextInputType.number,
      onChanged: onChanged,
    );
  }
}

class _ValuesHeading extends StatelessWidget {
  const _ValuesHeading();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 2,
      children: [
        Text(l10n.valuesPer100g, style: theme.textTheme.titleMedium),
        Text(
          l10n.valuesHint,
          style: theme.textTheme.bodySmall!.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// One value per 100 g: its name (or its error) at the start, the number
/// field with its unit at the end, as on the targets form.
class _ValueField extends StatelessWidget {
  const _ValueField({
    required this.value,
    required this.controller,
    required this.error,
    required this.onChanged,
  });

  final _Value value;
  final TextEditingController controller;
  final bool error;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final calories = value == _Value.calories;
    return Row(
      spacing: 16,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: [
              Text(
                l10n.targetsFieldLabel(value.name),
                style: theme.textTheme.titleMedium!.copyWith(
                  color: error ? colors.error : null,
                ),
              ),
              if (error)
                Text(
                  calories ? l10n.errorCaloriesPer100g : l10n.errorMacroPer100g,
                  style: theme.textTheme.bodySmall!.copyWith(
                    color: colors.error,
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          width: 132,
          child: TextField(
            key: ValueKey(value.name),
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
            decoration: InputDecoration(
              suffixText: calories ? l10n.caloriesUnit : l10n.gramsUnit,
              error: error ? const SizedBox.shrink() : null,
            ),
            onChanged: (_) => onChanged(),
          ),
        ),
      ],
    );
  }
}

/// Says protein, carbs and fat add up to more than 100 g.
class _MacrosOver100g extends StatelessWidget {
  const _MacrosOver100g();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      AppLocalizations.of(context)!.errorMacrosOver100g,
      style: theme.textTheme.bodyMedium!.copyWith(
        color: theme.colorScheme.error,
      ),
    );
  }
}
