import 'package:flutter/material.dart';

import '../core/api_failure.dart';
import '../core/error_views.dart';
import '../l10n/app_localizations.dart';
import 'profile.dart';

/// The profile form, for onboarding and for "Edit my info" ([initial] set).
class ProfileFormScreen extends StatefulWidget {
  const ProfileFormScreen({super.key, this.initial, required this.onSubmit});

  final Profile? initial;
  final Future<void> Function(Profile profile) onSubmit;

  @override
  State<ProfileFormScreen> createState() => _ProfileFormScreenState();
}

class _ProfileFormScreenState extends State<ProfileFormScreen> {
  // The backend uses UTC dates for the age check.
  final _today = DateTime.now().toUtc();

  // Nothing is chosen by default, so we never guess someone's sex.
  late int? _month = widget.initial?.birthMonth;
  late int? _year = widget.initial?.birthYear;
  late Sex? _sex = widget.initial?.sex;
  late final _height = TextEditingController(
    text: _formatNumber(widget.initial?.heightCm),
  );
  late final _weight = TextEditingController(
    text: _formatNumber(widget.initial?.weightKg),
  );
  late ActivityLevel? _activity = widget.initial?.activityLevel;
  late Goal? _goal = widget.initial?.goal;

  var _errors = <ProfileField, String>{};
  var _busy = false;

  // The form's own snackbars, so they and their Retry go when it closes.
  final _messenger = GlobalKey<ScaffoldMessengerState>();

  @override
  void dispose() {
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  void _changed(ProfileField field, VoidCallback change) => setState(() {
    change();
    _errors.remove(field);
    if (field == ProfileField.birthMonth || field == ProfileField.birthYear) {
      _errors
        ..remove(ProfileField.birthMonth)
        ..remove(ProfileField.birthYear);
    }
  });

  Map<ProfileField, String> _validate(AppLocalizations l10n) {
    final invalid = validateProfileDraft(
      ProfileDraft(
        birthYear: _year,
        birthMonth: _month,
        sex: _sex,
        heightCm: _parseNumber(_height.text),
        weightKg: _parseNumber(_weight.text),
        activityLevel: _activity,
        goal: _goal,
      ),
      _today,
    );
    return {
      for (final field in invalid)
        field: switch (field) {
          ProfileField.birthMonth => _month == null ? l10n.errorChooseOne : '',
          ProfileField.birthYear =>
            _year == null ? l10n.errorChooseOne : l10n.errorAge,
          ProfileField.sex ||
          ProfileField.activityLevel ||
          ProfileField.goal => l10n.errorChooseOne,
          ProfileField.height => l10n.errorHeight,
          ProfileField.weight => l10n.errorWeight,
        },
    };
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = _messenger.currentState!..hideCurrentSnackBar();
    final errors = _validate(l10n);
    setState(() => _errors = errors);
    if (errors.isNotEmpty) return;

    setState(() => _busy = true);
    try {
      await widget.onSubmit(
        Profile(
          birthYear: _year!,
          birthMonth: _month!,
          sex: _sex!,
          heightCm: _parseNumber(_height.text)!,
          weightKg: _parseNumber(_weight.text)!,
          activityLevel: _activity!,
          goal: _goal!,
        ),
      );
    } on ApiFailure catch (failure) {
      // Back may have closed this form while it saved.
      if (!mounted) return;
      switch (failure) {
        case ValidationFailure(:final types):
          if (types.contains('age_out_of_range')) {
            setState(
              () => _errors = {
                ProfileField.birthMonth: '',
                ProfileField.birthYear: l10n.errorAge,
              },
            );
          }
          if (types.any((type) => type != 'age_out_of_range')) {
            messenger.showSnackBar(
              SnackBar(content: Text(l10n.errorCheckDetails)),
            );
          }
        case ConnectionFailure():
          messenger.showSnackBar(connectionSnackBar(l10n, onRetry: _submit));
        case ServerFailure() || UnexpectedResponseFailure():
          messenger.showSnackBar(SnackBar(content: Text(l10n.errorGeneral)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ScaffoldMessenger(
      key: _messenger,
      child: Scaffold(
        appBar: widget.initial == null ? null : AppBar(),
        body: SafeArea(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              20,
              widget.initial == null ? 48 : 0,
              20,
              24,
            ),
            children: [
              const _Header(),
              const SizedBox(height: 16),
              _Pair(
                _MonthField(
                  value: _month,
                  error: _errors[ProfileField.birthMonth],
                  onChanged: (month) =>
                      _changed(ProfileField.birthMonth, () => _month = month),
                ),
                _YearField(
                  thisYear: _today.year,
                  value: _year,
                  error: _errors[ProfileField.birthYear],
                  onChanged: (year) =>
                      _changed(ProfileField.birthYear, () => _year = year),
                ),
              ),
              const SizedBox(height: 14),
              _ChoiceField(
                label: l10n.sex,
                hint: l10n.sexHint,
                options: {Sex.male: l10n.sexMale, Sex.female: l10n.sexFemale},
                value: _sex,
                error: _errors[ProfileField.sex],
                onChanged: (sex) =>
                    _changed(ProfileField.sex, () => _sex = sex),
              ),
              const SizedBox(height: 14),
              _Pair(
                _NumberField(
                  key: const ValueKey('height'),
                  label: l10n.height,
                  controller: _height,
                  error: _errors[ProfileField.height],
                  onChanged: () => _changed(ProfileField.height, () {}),
                ),
                _NumberField(
                  key: const ValueKey('weight'),
                  label: l10n.weight,
                  controller: _weight,
                  error: _errors[ProfileField.weight],
                  onChanged: () => _changed(ProfileField.weight, () {}),
                ),
              ),
              const SizedBox(height: 14),
              _ActivityField(
                value: _activity,
                error: _errors[ProfileField.activityLevel],
                onChanged: (level) => _changed(
                  ProfileField.activityLevel,
                  () => _activity = level,
                ),
              ),
              const SizedBox(height: 14),
              _ChoiceField(
                label: l10n.goal,
                options: {
                  for (final goal in Goal.values)
                    goal: l10n.goalName(goal.name),
                },
                value: _goal,
                error: _errors[ProfileField.goal],
                onChanged: (goal) =>
                    _changed(ProfileField.goal, () => _goal = goal),
              ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: FilledButton(
              onPressed: _busy ? null : _submit,
              child: Text(l10n.calculateButton),
            ),
          ),
        ),
      ),
    );
  }
}

/// The form's title and the line under it.
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 2,
      children: [
        Text(l10n.profileTitle, style: theme.textTheme.headlineSmall),
        Text(
          l10n.profileSubtitle,
          style: theme.textTheme.bodyLarge!.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _MonthField extends StatelessWidget {
  const _MonthField({
    required this.value,
    required this.error,
    required this.onChanged,
  });

  final int? value;
  final String? error;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _Labeled(
      label: l10n.birthMonth,
      error: error != null,
      child: DropdownMenu<int>(
        key: const ValueKey('birthMonth'),
        initialSelection: value,
        expandedInsets: EdgeInsets.zero,
        selectOnly: true,
        errorText: error,
        onSelected: onChanged,
        dropdownMenuEntries: [
          for (var month = 1; month <= 12; month++)
            DropdownMenuEntry(value: month, label: l10n.monthName('$month')),
        ],
      ),
    );
  }
}

class _YearField extends StatelessWidget {
  const _YearField({
    required this.thisYear,
    required this.value,
    required this.error,
    required this.onChanged,
  });

  final int thisYear;
  final int? value;
  final String? error;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return _Labeled(
      label: AppLocalizations.of(context)!.birthYear,
      error: error != null,
      child: DropdownMenu<int>(
        key: const ValueKey('birthYear'),
        initialSelection: value,
        expandedInsets: EdgeInsets.zero,
        selectOnly: true,
        errorText: error,
        onSelected: onChanged,
        dropdownMenuEntries: [
          // Ages 18 to 100. The oldest year only fits birth months later in
          // the year; the age check catches the others.
          for (var year = thisYear - 18; year >= thisYear - 101; year--)
            DropdownMenuEntry(value: year, label: '$year'),
        ],
      ),
    );
  }
}

/// One option out of a few, as a row of segments. Starts with none chosen.
class _ChoiceField<T> extends StatelessWidget {
  const _ChoiceField({
    required this.label,
    required this.options,
    required this.value,
    required this.error,
    required this.onChanged,
    this.hint,
  });

  final String label;

  /// Each option and its text, in the order shown.
  final Map<T, String> options;
  final T? value;
  final String? error;
  final ValueChanged<T> onChanged;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return _Labeled(
      label: label,
      error: error != null,
      errorText: error,
      hint: hint,
      child: SegmentedButton<T>(
        segments: [
          for (final option in options.entries)
            ButtonSegment(value: option.key, label: Text(option.value)),
        ],
        selected: {?value},
        emptySelectionAllowed: true,
        showSelectedIcon: false,
        expandedInsets: EdgeInsets.zero,
        onSelectionChanged: (selected) {
          // Tapping the chosen option keeps it chosen.
          if (selected.isEmpty) return;
          onChanged(selected.single);
        },
      ),
    );
  }
}

/// A dropdown whose options show a name and a description.
class _ActivityField extends StatelessWidget {
  const _ActivityField({
    required this.value,
    required this.error,
    required this.onChanged,
  });

  final ActivityLevel? value;
  final String? error;
  final ValueChanged<ActivityLevel?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _Labeled(
      label: l10n.activityLevel,
      error: error != null,
      hint: l10n.activityHint,
      child: InputDecorator(
        isEmpty: value == null,
        decoration: InputDecoration(
          errorText: error,
          contentPadding: const EdgeInsetsDirectional.fromSTEB(16, 6, 12, 6),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<ActivityLevel>(
            key: const ValueKey('activityLevel'),
            value: value,
            isExpanded: true,
            itemHeight: null,
            borderRadius: BorderRadius.circular(16),
            hint: Text(l10n.activityChoose),
            onChanged: onChanged,
            items: [
              for (final level in ActivityLevel.values)
                DropdownMenuItem(value: level, child: _ActivityOption(level)),
            ],
            selectedItemBuilder: (context) => [
              for (final level in ActivityLevel.values) _ActivityOption(level),
            ],
          ),
        ),
      ),
    );
  }
}

/// Two fields side by side.
class _Pair extends StatelessWidget {
  const _Pair(this.start, this.end);

  final Widget start;
  final Widget end;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 12,
    children: [
      Expanded(child: start),
      Expanded(child: end),
    ],
  );
}

/// A label above a field, with an optional error and hint below it. Fields
/// that show their own error leave [errorText] null.
class _Labeled extends StatelessWidget {
  const _Labeled({
    required this.label,
    required this.error,
    required this.child,
    this.errorText,
    this.hint,
  });

  final String label;
  final bool error;
  final Widget child;
  final String? errorText;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final small = theme.textTheme.bodySmall!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 6,
      children: [
        Text(
          label,
          style: theme.textTheme.titleSmall!.copyWith(
            color: error ? theme.colorScheme.error : null,
          ),
        ),
        child,
        if (errorText != null)
          Text(
            errorText!,
            style: small.copyWith(color: theme.colorScheme.error),
          ),
        if (hint != null)
          Text(
            hint!,
            style: small.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
      ],
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    super.key,
    required this.label,
    required this.controller,
    required this.error,
    required this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String? error;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => _Labeled(
    label: label,
    error: error != null,
    child: TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(errorText: error),
      onChanged: (_) => onChanged(),
    ),
  );
}

class _ActivityOption extends StatelessWidget {
  const _ActivityOption(this.level);

  final ActivityLevel level;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.activityName(level.code)),
        Text(
          l10n.activityDescription(level.code),
          style: theme.textTheme.bodySmall!.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Reads a number typed with Western or Arabic-Indic digits (٠–٩), and `.`,
/// `٫` or `,` as the decimal point. Some Arabic keyboards send those, and
/// `double.parse` rejects them.
double? _parseNumber(String text) {
  final western = text
      .trim()
      .replaceAllMapped(
        RegExp('[٠-٩]'),
        (digit) => '${digit[0]!.codeUnitAt(0) - 0x0660}',
      )
      .replaceAll(RegExp('[٫,]'), '.');
  return double.tryParse(western);
}

/// Shows a saved number with Western digits (decision 16), without a
/// trailing ".0".
String _formatNumber(double? value) {
  if (value == null) return '';
  return value == value.truncateToDouble()
      ? value.toInt().toString()
      : value.toString();
}
