import 'package:face_recognition_attendance/config/localization/en_us.dart';
import 'package:face_recognition_attendance/config/localization/km_kh.dart';

void main() {
  print('=== STARTING LOCALIZATION & THEME KEYS TESTS ===');

  // 1. English & Khmer Dictionary Parity
  print('\n[Test 1] Testing English and Khmer dictionary key parity...');
  final enKeys = enUS.keys.toSet();
  final kmKeys = kmKH.keys.toSet();

  final missingInKm = enKeys.difference(kmKeys);
  final missingInEn = kmKeys.difference(enKeys);

  assert(missingInKm.isEmpty, 'Keys present in enUS but missing in kmKH: $missingInKm');
  assert(missingInEn.isEmpty, 'Keys present in kmKH but missing in enUS: $missingInEn');
  print('Dictionary key parity tests passed (${enKeys.length} matching keys).');

  // 2. Non-empty string checks
  print('\n[Test 2] Testing non-empty translation strings...');
  for (final entry in enUS.entries) {
    assert(entry.value.trim().isNotEmpty, 'enUS key ${entry.key} is empty');
  }
  for (final entry in kmKH.entries) {
    assert(entry.value.trim().isNotEmpty, 'kmKH key ${entry.key} is empty');
  }
  print('Non-empty translation string tests passed (${kmKeys.length} translations verified).');

  // 3. Dark mode and appearance translation keys check
  print('\n[Test 3] Testing dark mode and appearance translation keys...');
  const expectedThemeKeys = [
    'APPEARANCE / រូបរាង',
    'System Default',
    'Light Mode',
    'Dark Mode',
    'System',
    'Light',
    'Dark',
    'App theme and display appearance',
    'Settings & Appearance',
  ];
  for (final key in expectedThemeKeys) {
    assert(enKeys.contains(key), 'Missing theme key in enUS: $key');
    assert(kmKeys.contains(key), 'Missing theme key in kmKH: $key');
  }
  print('All dark mode & appearance keys verified in both locales.');

  print('\n=== ALL LOCALIZATION & THEME TESTS PASSED SUCCESSFULLY! ===\n');
}
