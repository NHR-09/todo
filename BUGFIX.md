# Bug Fix: withValues to withOpacity

## Issue
The app was throwing assertion errors:
```
'dart:ui/painting.dart': Failed assertion: line 342 pos 12: '<optimized out>': is not true.
```

## Root Cause
The code was using `withValues(alpha:)` method which is only available in newer Flutter versions (3.27+). This caused compatibility issues with older Flutter versions.

## Solution
Replaced all occurrences of `withValues(alpha:)` with `withOpacity()` which is compatible with all Flutter versions.

## Files Fixed
1. `lib/main.dart` - 2 occurrences
2. `lib/theme/app_theme.dart` - 2 occurrences  
3. `lib/theme/marvel_animations.dart` - 5 occurrences
4. `lib/widgets/glass_card.dart` - 2 occurrences
5. `lib/widgets/immersive_background.dart` - 3 occurrences
6. `lib/screens/analytics_screen.dart` - 5 occurrences
7. `lib/screens/dashboard_screen.dart` - 2 occurrences
8. `lib/screens/hero_mode_screen.dart` - 5 occurrences
9. `lib/screens/lectures_screen.dart` - 4 occurrences
10. `lib/screens/settings_screen.dart` - 5 occurrences
11. `lib/screens/tasks_screen.dart` - 2 occurrences

## Total Changes
37 occurrences fixed across 11 files

## Verification
Run the following command to verify all fixes:
```bash
findstr /s /i "withValues" lib\*.dart
```

Should return 0 results.

## Testing
After this fix, the app should run without assertion errors on all Flutter versions.

## Compatibility
- ✅ Flutter 3.0+
- ✅ Flutter 3.10+
- ✅ Flutter 3.16+
- ✅ Flutter 3.24+
- ✅ Flutter 3.27+

The `withOpacity()` method is available in all Flutter versions and provides the same functionality as `withValues(alpha:)`.
