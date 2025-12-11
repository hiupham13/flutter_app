# Work Flow Checklist (2025-12-11)

Tóm tắt nhanh các hạng mục trong `docs/work_flow.md` và trạng thái hiện tại.

## Phase 2 – Authentication & User Management
- [x] Google / Email-Pass sign-in, register, forgot password (UI + repo + provider).
- [x] Auth guard & auto-redirect (GoRouter refresh + onboarding check).
- [x] Onboarding multi-step UI & save prefs.
- [x] Onboarding analytics: `onboarding_completed` (skipped/filled + prefs counts).
- [x] Onboarding update profile methods (trong `user_profile_provider`).
- [ ] Phone / Anonymous auth (optional).

## Phase 3 – Data Layer & Firebase Integration
- [x] Firestore services & repositories (foods, master data, user prefs).
- [x] Activity logging service (Firestore) + provider.
- [x] Activity events wired:
  - `recommendation_requested` (dashboard trigger).
  - `map_opened` (result screen button).
  - `food_selected` (selectFood on map open).
- [x] Analytics service (FirebaseAnalytics) + events:
  - `recommendation_requested`, `food_selected`, `map_opened`, `onboarding_completed`.
- [x] Activity log batch write optimization.
- [~] Cache layer: in-memory TTL cache wired in `CacheService` + FoodRepository; Hive adapters still pending.
- [~] Offline mode: fallback to cached foods when Firestore lỗi/không có mạng; full queue writes pending.
- [ ] Firestore rules finalization & seeding tasks per checklist.

## Phase 5 – UI/UX Implementation
- [x] Dashboard header (weather, greeting, refresh).
- [x] Main CTA “Gợi ý ngay” -> input bottom sheet -> recommendations.
- [x] Quick actions (favorites stub, refresh context).
- [x] Recent recommendations list (top 3, tap to open result).
- [x] Result screen actions: map deeplink, re-roll, share, copywriting reason/joke.
- [ ] Dashboard profile/settings entry.
- [ ] Favorites widget + history surfaces beyond top 3.
- [ ] Slot machine animation alternative for CTA.

## Ghi chú tiếp theo
- Ưu tiên tiếp: Phase 3 cache/offline + batch activity logging; Phase 5 favorites/history screens; Phase 2 bổ sung update profile & optional auth methods.

