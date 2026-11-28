import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'entry.dart';
import 'meal.dart';

/// Opens Flutter's date picker on [day], from [firstDay] to [today], all
/// `YYYY-MM-DD`. Returns the day chosen, or null when the trainee cancels.
/// The picker marks [today], the diary's, which before 4:00 is the
/// calendar's yesterday.
Future<String?> showDiaryDayPicker(
  BuildContext context, {
  required String day,
  required String firstDay,
  required String today,
}) async {
  final picked = await showDatePicker(
    context: context,
    initialDate: DateTime.parse(day),
    firstDate: DateTime.parse(firstDay),
    lastDate: DateTime.parse(today),
    currentDate: DateTime.parse(today),
  );
  return picked == null ? null : dayOfDate(picked);
}

/// Asks which day to move an entry of [meal] to: today and the six days
/// before it, none before [firstDay], with [day], the entry's, marked; or
/// another date from the date picker. Returns the day chosen, or null when
/// the trainee cancels. All days are `YYYY-MM-DD`.
///
/// `isScrollControlled` lets the sheet be taller than half the screen,
/// which the seven days need.
Future<String?> showMoveDaySheet(
  BuildContext context, {
  required String day,
  required String firstDay,
  required String today,
  required String meal,
}) => showModalBottomSheet<String>(
  context: context,
  isScrollControlled: true,
  builder: (context) =>
      _MoveDaySheet(day: day, firstDay: firstDay, today: today, meal: meal),
);

class _MoveDaySheet extends StatelessWidget {
  const _MoveDaySheet({
    required this.day,
    required this.firstDay,
    required this.today,
    required this.meal,
  });

  final String day;
  final String firstDay;
  final String today;
  final String meal;

  /// Closes the sheet with the day chosen in the date picker, if any.
  Future<void> _pickOther(BuildContext context) async {
    final picked = await showDiaryDayPicker(
      context,
      day: day,
      firstDay: firstDay,
      today: today,
    );
    if (picked != null && context.mounted) Navigator.pop(context, picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final rowShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );
    const rowPadding = EdgeInsets.symmetric(horizontal: 12);
    final days = [for (var back = 0; back < 7; back++) addDays(today, -back)]
        .where((option) => option.compareTo(firstDay) >= 0);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: rowPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: [
                  Text(
                    l10n.moveToAnotherDay,
                    style: theme.appBarTheme.titleTextStyle,
                  ),
                  Text(
                    l10n.moveStaysInMeal(meal),
                    style: theme.textTheme.bodyMedium!.copyWith(color: muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            for (final option in days)
              _DayTile(
                day: option,
                today: today,
                chosen: option == day,
                shape: rowShape,
                padding: rowPadding,
                onTap: () => Navigator.pop(context, option),
              ),
            ListTile(
              shape: rowShape,
              contentPadding: rowPadding,
              leading: const Icon(Icons.calendar_today_outlined),
              title: Text(l10n.otherDate),
              trailing: Icon(Icons.chevron_right, color: muted),
              onTap: () => _pickOther(context),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
          ],
        ),
      ),
    );
  }
}

/// A day in the move sheet: "Today" or "Yesterday" over the date, or the
/// date alone. The [chosen] one, the entry's day, is filled and checked.
class _DayTile extends StatelessWidget {
  const _DayTile({
    required this.day,
    required this.today,
    required this.chosen,
    required this.shape,
    required this.padding,
    required this.onTap,
  });

  final String day;
  final String today;
  final bool chosen;
  final ShapeBorder shape;
  final EdgeInsetsGeometry padding;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final name = nearDayName(l10n, day, today);
    final date = diaryDateText(l10n, day);
    return ListTile(
      selected: chosen,
      shape: shape,
      contentPadding: padding,
      title: Text(
        name ?? date,
        style: chosen
            ? theme.textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w600)
            : null,
      ),
      subtitle: name == null
          ? null
          : Text(
              date,
              style: theme.textTheme.bodyMedium!.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
      trailing: chosen ? const Icon(Icons.check) : null,
      onTap: onTap,
    );
  }
}
