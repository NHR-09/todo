# QUICK FIX GUIDE

## Issues Fixed
1. ✅ **Database Error**: "table lectures has no column named courseId"
2. ✅ **Generic Errors**: Now shows actual error messages

## What Was Done

### 1. Database Migration (database_service.dart)
- Bumped database version to 6
- Added migration to ensure `courseId` and `courseTitle` columns exist
- Handles cases where columns might already exist

### 2. Better Error Messages (lecture_provider.dart)
- Added timeout handling (15 seconds)
- Shows specific errors: network, timeout, or parse details
- No more generic "YouTube response format changed" messages

### 3. Error Display (lectures_screen.dart)
- Shows actual error messages to users
- Fixed button lockup issues

## How to Apply the Fix

### Step 1: Clean Build
```bash
flutter clean
```

### Step 2: Run the App
```bash
flutter run
```

### Step 3: Test
1. **Add a lecture**: Paste a YouTube video URL
   - Example: `https://www.youtube.com/watch?v=dQw4w9WgXcQ`
   - Should work now without database errors

2. **Import a playlist**: Paste a YouTube playlist URL
   - Example: `https://www.youtube.com/playlist?list=PLrAXtmErZgOeiKm4sgNOknGvNjby9efdf`
   - Should either succeed or show specific error

## Expected Results

### Adding Lecture
- ✅ Success: "Lecture added" message
- ❌ Failure: Shows specific error (e.g., "Invalid URL", "Network timeout", etc.)

### Importing Playlist
- ✅ Success: "Imported X lectures as a course"
- ❌ Failure: Shows specific error:
  - "Invalid playlist URL"
  - "Network error: could not reach YouTube"
  - "Timeout: YouTube took too long to respond"
  - "Playlist unavailable: [reason]"
  - "Parse error: [details]"

## Troubleshooting

### If you still get database errors:
1. Uninstall the app completely
2. Run `flutter clean`
3. Reinstall: `flutter run`
4. This will create a fresh database with correct schema

### If playlist import fails:
- Check the error message - it will tell you exactly what went wrong
- Network issues: Check your internet connection
- Timeout: Try again with better connection
- Parse error: The error message will show what failed
- Private playlist: Make sure the playlist is public

### If lecture add fails:
- Check the error message for details
- Make sure the URL is a valid YouTube video link
- Check your internet connection

## What Changed in Code

### database_service.dart
```dart
version: 6  // Was 5
// Added migration for version 6
if (oldVersion < 6) {
  try {
    await db.execute('ALTER TABLE lectures ADD COLUMN courseId TEXT');
  } catch (_) {}
  try {
    await db.execute('ALTER TABLE lectures ADD COLUMN courseTitle TEXT');
  } catch (_) {}
}
```

### lecture_provider.dart
```dart
// Added timeout
.timeout(const Duration(seconds: 15))

// Better error handling
} on TimeoutException {
  _setPlaylistImportError('Timeout: YouTube took too long to respond. Try again.');
} catch (e) {
  _setPlaylistImportError('Parse error: ${e.toString()}');
}
```

### lectures_screen.dart
```dart
// Shows actual errors
} catch (e) {
  messenger.showSnackBar(
    SnackBar(content: Text('Could not add lecture: ${e.toString()}')),
  );
}
```

## Need More Help?

If you still see errors after following these steps:
1. Copy the EXACT error message
2. Check if it's a network issue (no internet)
3. Try with a different YouTube URL
4. Make sure the playlist is public (not private)

The error messages now tell you exactly what's wrong, making it much easier to fix!
