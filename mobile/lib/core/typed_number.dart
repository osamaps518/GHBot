/// [text] trimmed, with Arabic-Indic digits (٠–٩) as Western digits and `٫`
/// or `,` as `.`. Some Arabic keyboards send those, and Dart's number
/// parsing rejects them.
String westernNumberText(String text) => text
    .trim()
    .replaceAllMapped(
      RegExp('[٠-٩]'),
      (digit) => '${digit[0]!.codeUnitAt(0) - 0x0660}',
    )
    .replaceAll(RegExp('[٫,]'), '.');
