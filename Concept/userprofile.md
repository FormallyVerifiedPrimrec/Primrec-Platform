# User Profiles & Community Solutions - Concept Iteration 5

This document outlines the technical plan for implementing user profiles, leaderboard integration, and the community solutions feature.

---

## 🛠️ Backend Changes (Supabase & .NET)

### 1. Database Schema (`profiles`)
- **Column:** `avatar_data` (text) - Stored as a Base64 string.
- **Optimization:** Frontend will downscale images before upload to keep strings under ~50-100KB.

### 2. Immutable Submissions (API Layer)
- **Logic:** Handled in `ChallengesService.cs`. If `best_submission_source` is already populated for a user/challenge, the API ignores new source updates.

### 3. Community Solutions API (Paginated)
- **Endpoint:** `GET /api/challenges/{id}/solutions?limit=20&offset=0`
- **Controller Logic:**
  1. Verify the requester has solved the challenge.
  2. **Creator's Solution First:** The query must prioritize the creator's solution (from the `challenges` table) if it exists, followed by other users' submissions (from `user_interactions`) sorted by `solved_at` or `rank_points`.
  3. Returns a paginated list of `{ username, avatar_data, best_submission_source, is_creator }`.

---

## 📜 SQL Migrations

```sql
-- 1. Add avatar column to profiles
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS avatar_data TEXT;

-- 2. Add best_submission_source to user_interactions if not exists
ALTER TABLE public.user_interactions 
ADD COLUMN IF NOT EXISTS best_submission_source TEXT;

-- 3. Add solved_at timestamp to track solution age
ALTER TABLE public.user_interactions 
ADD COLUMN IF NOT EXISTS solved_at TIMESTAMPTZ DEFAULT now();
```

---

## 💻 Frontend Changes (React)

### 1. Profile Management (with Downscaling)
- **`ProfileModal.tsx`:** 
  - Image picker uses a hidden `<canvas>` to downscale uploaded images to a max resolution (e.g., 200x200px).
  - Converts the canvas result to a JPEG data URI with 0.7 quality to ensure the string is small.

### 2. Community Solutions in Challenge Overview
- **Location:** Integrated into the **Challenge Details / Overview** (the view that shows the full description).
- **Visibility:** Only accessible once the challenge is solved.
- **Page-by-Page Navigation:** 
  - Instead of a long scroll, solutions are presented one-at-a-time or in small groups (e.g., 1 solution per page).
  - Use "Previous" and "Next" buttons (or a horizontal slider) to navigate through the solutions.
  - This allows the user to focus on one implementation at a time without getting overwhelmed.
- **Pinned Start:** Page 1 is always the **Creator's Suggested Solution** with a special badge.
- **Viewer:** Solutions are displayed in a simple, syntax-highlighted `<pre>` code block.

---

## 📝 Decisions Made
1. **Avatar Storage:** Base64 string, downscaled on the **frontend** before upload.
2. **Persistence:** First solve is final (enforced in API).
3. **Challenge Start:** The creator's solution is the first one visible to solvers.
4. **API Scalability:** Added `limit` and `offset` to the solutions endpoint.
