# Poll & Feedback Feature

## Overview
Added support for sending images, polls, and feedback requests through the notification system. Admins can now create interactive notifications and collect user responses.

## Features Added

### 1. Image Support
- **Admin**: Add image URL when creating notifications
- **App**: Images display in notification cards with rounded corners
- **Use Case**: Announcements with visuals, feature previews, event posters

### 2. Polls
- **Admin**: Create polls with multiple options (minimum 2)
- **App**: Users can vote on poll options
- **Results**: View poll results in admin dashboard
- **Features**:
  - Single vote per user
  - Visual feedback when voted
  - Vote stored locally and synced to Firestore
  - Real-time vote counting

### 3. Feedback Requests
- **Admin**: Request feedback from users
- **App**: Users can submit text feedback
- **Results**: View all feedback responses in admin dashboard
- **Features**:
  - Multi-line text input
  - One-time submission
  - Feedback stored in Firestore
  - Visual confirmation after submission

## Database Changes

### Flutter (SQLite)
**Version 10** - Added columns to `notifications` table:
- `pollOptions` (TEXT) - JSON string of poll options
- `userVote` (TEXT) - User's selected option ID
- `userFeedback` (TEXT) - User's feedback text

### Firestore Structure

**Notification Document:**
```json
{
  "id": "uuid",
  "title": "What's your favorite feature?",
  "message": "Help us improve!",
  "type": "poll",
  "imageUrl": "https://example.com/image.jpg",
  "pollOptions": [
    {"id": "opt_1", "text": "Dark Mode", "votes": 0},
    {"id": "opt_2", "text": "Widgets", "votes": 0}
  ],
  "broadcast": true,
  "createdAt": "2024-01-01T00:00:00Z"
}
```

**Poll Votes Subcollection:**
```
notifications/{notificationId}/votes/{userId}
{
  "userId": "user123",
  "optionId": "opt_1",
  "votedAt": "2024-01-01T00:00:00Z"
}
```

**Feedback Subcollection:**
```
notifications/{notificationId}/feedback/{userId}
{
  "userId": "user123",
  "feedback": "Great app!",
  "submittedAt": "2024-01-01T00:00:00Z"
}
```

## API Endpoints

### Create Notification with Poll
```bash
POST /api/notifications/broadcast
{
  "title": "Poll Title",
  "message": "Poll question",
  "type": "poll",
  "imageUrl": "https://...",
  "pollOptions": [
    {"id": "opt_1", "text": "Option 1", "votes": 0},
    {"id": "opt_2", "text": "Option 2", "votes": 0}
  ]
}
```

### Get Poll Results
```bash
GET /api/notifications/{id}/poll-results
Response:
{
  "notificationId": "uuid",
  "totalVotes": 42,
  "results": {
    "opt_1": 25,
    "opt_2": 17
  },
  "votes": [...]
}
```

### Get Feedback
```bash
GET /api/notifications/{id}/feedback
Response:
{
  "notificationId": "uuid",
  "totalResponses": 15,
  "feedback": [
    {
      "userId": "user123",
      "feedback": "Great feature!",
      "submittedAt": "2024-01-01T00:00:00Z"
    }
  ]
}
```

## Admin Dashboard Usage

### Creating a Poll
1. Select **Type**: Poll
2. Enter title and message
3. Click **Add Option** to add poll choices (minimum 2)
4. Add optional image URL
5. Choose audience (All Users or Specific Users)
6. Click **Send**

### Creating Feedback Request
1. Select **Type**: Feedback Request
2. Enter title and message (e.g., "How can we improve?")
3. Add optional image URL
4. Choose audience
5. Click **Send**

### Viewing Results
- **Poll**: Click the chart icon next to poll notification
- **Feedback**: Click the inbox icon next to feedback notification
- Results show in a popup with counts and responses

## App UI

### Poll Display
- Shows all options as selectable cards
- Selected option highlighted in green
- Check icon appears when voted
- Options disabled after voting

### Feedback Display
- Multi-line text input field
- Submit button
- Confirmation message after submission
- Input disabled after submission

### Image Display
- Full-width image below notification text
- Rounded corners
- Responsive sizing
- Error handling for broken images

## Notification Types

| Type | Icon | Color | Use Case |
|------|------|-------|----------|
| announcement | 📢 | Slate | General announcements |
| update | 🔄 | Sage | App updates |
| feature | ⭐ | Terracotta | New features |
| maintenance | 🔧 | Slate | Maintenance notices |
| poll | 📊 | Sand | User polls |
| feedback | 💬 | Sage | Feedback requests |

## Code Changes

### Flutter Files Modified
1. `lib/models/notification_model.dart` - Added poll/feedback fields
2. `lib/services/notification_service.dart` - Added vote/feedback submission
3. `lib/services/database_service.dart` - Added DB methods for polls
4. `lib/screens/notifications_screen.dart` - Added poll/feedback UI
5. `lib/providers/notification_provider.dart` - Added provider methods

### Backend Files Modified
1. `admin_api/server.js` - Added poll/feedback endpoints
2. `admin_api/public/index.html` - Added poll/feedback UI

## Testing

### Test Poll
1. Create poll with 2+ options
2. Send to all users or specific users
3. Open app and vote
4. Check admin dashboard for results

### Test Feedback
1. Create feedback request
2. Send to users
3. Submit feedback in app
4. View responses in admin dashboard

### Test Images
1. Add image URL to any notification
2. Send notification
3. Verify image displays in app

## Future Enhancements
- [ ] Chart visualization for poll results
- [ ] Export feedback as CSV
- [ ] Multiple choice polls
- [ ] Anonymous feedback option
- [ ] Image upload (not just URL)
- [ ] Rich text formatting in feedback
- [ ] Sentiment analysis on feedback
- [ ] Poll expiration dates

## Notes
- Polls are single-vote only (users can't change vote)
- Feedback is one-time submission
- Images must be publicly accessible URLs
- Poll options are immutable after creation
- All data syncs to Firestore for persistence
