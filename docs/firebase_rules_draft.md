# Firebase Security Rules (Draft)

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function isSignedIn() {
      return request.auth != null;
    }
    function isOwner(uid) {
      return isSignedIn() && request.auth.uid == uid;
    }

    // Users: each user can read/write their own doc
    match /users/{userId} {
      allow read, write: if isOwner(userId);
      match /recommendation_history/{docId} {
        allow read, write: if isOwner(userId);
      }
      match /activity_logs/{docId} {
        allow create: if isOwner(userId);
        allow read: if isOwner(userId);
      }
    }

    // Foods: read-only for all signed-in users
    match /foods/{foodId} {
      allow read: if isSignedIn();
      allow write: if false; // only via console/admin
    }

    // Master data: read-only
    match /master_data/{docId} {
      allow read: if true;
      allow write: if false;
    }

    // App configs: read-only
    match /app_configs/{docId} {
      allow read: if true;
      allow write: if false;
    }
  }
}
```

Notes:
- Tighten further if anonymous access is not allowed (change master_data/app_configs to require auth).
- Activity logs are user-scoped; batch writes should respect per-user match.

