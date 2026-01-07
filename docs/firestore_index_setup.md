# 🔥 Firestore Index Setup - Mystery Boxes Query

**Date:** 06/01/2026  
**Component:** Mystery Box Rewards System  
**Priority:** HIGH - App functionality broken without this

---

## 🚨 Error

```
[cloud_firestore/failed-precondition] The query requires an index. 
You can create it here: https://console.firebase.google.com/...
```

### Query Details:
```dart
// lib/features/rewards/data/rewards_repository.dart:188
_firestore
  .collection('users')
  .doc(userId)
  .collection('mystery_boxes')
  .where('is_opened', isEqualTo: false)
  .orderBy('earned_at', descending: true)
  .get();
```

---

## ✅ Solution: Create Composite Index

### Method 1: Auto-create via Console Link (Recommended)

1. **Click the link from error log** (Firebase Console automatically generates correct URL)
2. Firestore will auto-populate the index configuration
3. Click "Create Index"
4. Wait 2-5 minutes for index to build

### Method 2: Manual Creation

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select project: `futter-app-a0120`
3. Navigate to: **Firestore Database** → **Indexes** tab
4. Click **"Create Index"**
5. Configure:

```yaml
Collection ID: mystery_boxes
Collection group: ✓ (Enable)

Fields to index:
  - Field: is_opened
    Type: Ascending
  
  - Field: earned_at
    Type: Descending

Query scope: Collection group
```

6. Click **Create**
7. Wait for index status: "Building" → "Enabled"

### Method 3: Firebase CLI (for CI/CD)

Add to `firestore.indexes.json`:

```json
{
  "indexes": [
    {
      "collectionGroup": "mystery_boxes",
      "queryScope": "COLLECTION_GROUP",
      "fields": [
        {
          "fieldPath": "is_opened",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "earned_at",
          "order": "DESCENDING"
        }
      ]
    }
  ],
  "fieldOverrides": []
}
```

Deploy:
```bash
firebase deploy --only firestore:indexes
```

---

## 📊 Index Details

### Why is this index needed?

Firestore requires composite indexes when you:
1. **Filter** on a field (`where()`)
2. **AND Order** by a different field (`orderBy()`)

Our query does exactly this:
- **Filter:** `where('is_opened', isEqualTo: false)`
- **Order:** `orderBy('earned_at', descending: true)`

### Index Configuration:

| Field | Type | Purpose |
|-------|------|---------|
| `is_opened` | Ascending | Filter unopened boxes only |
| `earned_at` | Descending | Show newest boxes first |

### Collection Structure:
```
users/{userId}/mystery_boxes/{boxId}
  ├─ is_opened: false
  ├─ earned_at: Timestamp
  ├─ coins_awarded: int
  ├─ rarity: string
  └─ ...
```

---

## 🧪 Verification

### Test the Query:

```dart
// After index is created, this should work:
final pendingBoxes = await FirebaseFirestore.instance
  .collection('users')
  .doc(userId)
  .collection('mystery_boxes')
  .where('is_opened', isEqualTo: false)
  .orderBy('earned_at', descending: true)
  .get();

print('Pending boxes: ${pendingBoxes.docs.length}');
```

### Check Index Status:

1. Go to Firebase Console → Firestore → Indexes
2. Find the `mystery_boxes` index
3. Status should be: ✅ **Enabled** (not "Building" or "Error")

---

## ⚠️ Common Issues

### Issue 1: Index still building
**Solution:** Wait 2-5 minutes. Large collections take longer.

### Issue 2: Error persists after index created
**Solution:** 
1. Check index status in Firebase Console
2. Ensure field names match exactly (case-sensitive)
3. Verify collection path is correct
4. Try hot restart app (not just hot reload)

### Issue 3: Multiple index warnings
**Solution:** 
- Firebase automatically suggests indexes for new queries
- Create them as needed following same process

---

## 📝 Related Queries

These queries also use the same index:

### 1. Get all pending boxes (dashboard):
```dart
_firestore
  .collection('users')
  .doc(userId)
  .collection('mystery_boxes')
  .where('is_opened', isEqualTo: false)
  .orderBy('earned_at', descending: true)
  .get();
```

### 2. Stream pending boxes (real-time):
```dart
_firestore
  .collection('users')
  .doc(userId)
  .collection('mystery_boxes')
  .where('is_opened', isEqualTo: false)
  .orderBy('earned_at', descending: true)
  .snapshots();
```

---

## 🎯 Best Practices

### 1. Plan indexes early
- Review queries during development
- Create indexes before deploying to production

### 2. Monitor index usage
- Firebase Console shows index usage stats
- Delete unused indexes to reduce costs

### 3. Test locally first
- Use Firestore Emulator for development
- Automatically creates indexes in emulator

### 4. Document all indexes
- Keep track of why each index exists
- Include in code documentation

---

## 🔗 Resources

- [Firestore Index Documentation](https://firebase.google.com/docs/firestore/query-data/indexing)
- [Index Best Practices](https://firebase.google.com/docs/firestore/query-data/index-overview)
- [Firebase Console](https://console.firebase.google.com/)

---

## ✅ Checklist

- [ ] Index created in Firebase Console
- [ ] Index status: "Enabled"
- [ ] App tested with query
- [ ] No more error logs
- [ ] Documented in project docs
- [ ] Added to firestore.indexes.json (if using CI/CD)

---

**Status:** 🔧 PENDING - Index needs to be created  
**Impact:** HIGH - Blocks Mystery Box functionality  
**ETA:** 2-5 minutes after index creation
