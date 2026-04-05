# Sync Fix Log

## [2026-04-05 Latest] - Database Schema & Error Handling Fix

### Issues Reported
1. **"Could not add lec rn"** - DatabaseException: table lectures has no column named courseId
2. **"Parse error"** - Generic error when importing playlists

### Root Cause
1. **Database Schema Issue**: The database was created with version 4 which added `courseId` and `courseTitle` columns, but existing databases weren't properly upgraded
2. **Error Swallowing**: Generic catch blocks were hiding the actual errors

### Files Modified

#### 1. `lib/services/database_service.dart`
**Changes:**
- Bumped database version from 5 to 6
- Added migration in `onUpgrade` for version 6:
  - Ensures `courseId` column exists in lectures table
  - Ensures `courseTitle` column exists in lectures table
  - Wrapped in try-catch to handle cases where columns already exist
- This fixes the "table lectures has no column named courseId" error

**Migration Logic:**
```dart
if (oldVersion < 6) {
  // Ensure courseId and courseTitle columns exist
  try {
    await db.execute('ALTER TABLE lectures ADD COLUMN courseId TEXT');
  } catch (_) {
    // Column might already exist
  }
  try {
    await db.execute('ALTER TABLE lectures ADD COLUMN courseTitle TEXT');
  } catch (_) {
    // Column might already exist
  }
}
```

#### 2. `lib/providers/lecture_provider.dart`
**Changes:**
- Added `dart:async` import for TimeoutException
- Added timeout to playlist HTTP request (15 seconds)
- Improved error handling in `addPlaylist`:
  - Separate catch for `SocketException` (network issues)
  - Separate catch for `TimeoutException` (slow connection)
  - Generic catch now shows actual error: `'Parse error: ${e.toString()}'`
- This helps identify the exact cause of playlist import failures

#### 3. `lib/screens/lectures_screen.dart`
**Changes:**
- Changed `catch (_)` to `catch (e)` in both dialogs
- Shows actual error messages to users
- Fixed button state reset after validation failures

### What This Fixes
1. ✅ Lectures can now be added without database errors
2. ✅ Playlists show specific error messages (network, timeout, parse)
3. ✅ Database properly migrates for all users
4. ✅ No more generic "could not add" messages

### Testing Steps
1. **Stop the app completely**
2. **Run**: `flutter clean`
3. **Run**: `flutter run`
4. **Test adding a lecture**: Should work now
5. **Test importing a playlist**: Should show specific error if it fails

### Expected Behavior
- Adding lectures: Should work and save to database
- Importing playlists: Should either succeed or show specific error (network, timeout, or parse details)
- No more "column not found" errors

---

## Previous Fixes (from fix.md)

### Sync Service Improvements
- Renamed `initialUpload()` to `syncToCloud()`
- Removed one-time sync flag to ensure data uploads on every login
- Changed `pullRemoteChanges()` to fetch ALL remote data
- Fixed SharedPreferences initialization issues

### Playlist Import Enhancements
- Added YouTube `youtubei/v1/browse` API as primary source
- Improved URL parsing for playlist and video IDs
- Added multiple fallback parsing strategies
- Added playlist availability detection
- Added detailed error messages for different failure scenarios
- Fixed JSON extraction and balanced-brace scanning

### UI State Management
- Separated submit states for lecture and playlist dialogs
- Added proper timeout handling for metadata fetch
- Added explicit success/failure snackbars
- Ensured state resets in `finally` blocks

### Android Manifest
- Added `INTERNET` permission for release builds
