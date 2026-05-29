-- Refined Seed Script using UPSERT (INSERT ... ON CONFLICT DO UPDATE)
-- This avoids "Missing WHERE clause" warnings and handles the trigger-created profiles gracefully.

-- 1. Alice
INSERT INTO auth.users (id, email, created_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, role)
VALUES ('a11ce000-0000-0000-0000-000000000001', 'alice@dummy.com', now(), now(), '{"provider":"email","providers":["email"]}', '{"username":"Alice_Coder"}', false, 'authenticated')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.profiles (id, username, rank_points, avatar_data)
VALUES ('a11ce000-0000-0000-0000-000000000001', 'Alice_Coder', 1250, 'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAxMDAgMTAwIj48cmVjdCB3aWR0aD0iMTAwJSIgaGVpZ2h0PSIxMDAlIiBmaWxsPSIjRkY1NzMzIi8+PHRleHQgeD0iNTAiIHk9IjYwIiBmb250LXNpemU9IjUwIiB0ZXh0LWFuY2hvcj0ibWlkZGxlIiBmaWxsPSJ3aGl0ZSI+QTwvdGV4dD48L3N2Zz4=')
ON CONFLICT (id) DO UPDATE SET
  username = EXCLUDED.username,
  rank_points = EXCLUDED.rank_points,
  avatar_data = EXCLUDED.avatar_data;

-- 2. Bob
INSERT INTO auth.users (id, email, created_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, role)
VALUES ('b0b00000-0000-0000-0000-000000000002', 'bob@dummy.com', now(), now(), '{"provider":"email","providers":["email"]}', '{"username":"Bob_Recursive"}', false, 'authenticated')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.profiles (id, username, rank_points, avatar_data)
VALUES ('b0b00000-0000-0000-0000-000000000002', 'Bob_Recursive', 980, 'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAxMDAgMTAwIj48cmVjdCB3aWR0aD0iMTAwJSIgaGVpZ2h0PSIxMDAlIiBmaWxsPSIjMzNDRkZGIi8+PHRleHQgeD0iNTAiIHk9IjYwIiBmb250LXNpemU9IjUwIiB0ZXh0LWFuY2hvcj0ibWlkZGxlIiBmaWxsPSJ3aGl0ZSI+QjwvdGV4dD48L3N2Zz4=')
ON CONFLICT (id) DO UPDATE SET
  username = EXCLUDED.username,
  rank_points = EXCLUDED.rank_points,
  avatar_data = EXCLUDED.avatar_data;

-- 3. Challenges & Interactions
DO $$
DECLARE
    my_id uuid;
BEGIN
    -- Find your actual user ID to make you the owner
    SELECT id INTO my_id FROM auth.users 
    WHERE id NOT IN ('a11ce000-0000-0000-0000-000000000001', 'b0b00000-0000-0000-0000-000000000002') 
    LIMIT 1;

    -- Addition Challenge
    INSERT INTO public.challenges (id, creator_id, title, description, template_func, postcondition, suggested_solution, votes, created_at)
    VALUES 
      (
        '11111111-1111-1111-1111-111111111111', 
        COALESCE(my_id, 'a11ce000-0000-0000-0000-000000000001'), 
        'Addition Challenge', 
        'Implement a function `plus(x, y)` that returns the sum of $x$ and $y$.', 
        'plusBase(x) = x;\nplusStep(x, y, previous) = succ(previous);\nplus(x, y) = primrec(plusBase, plusStep);', 
        'plus(x, y) = x + y', 
        'plusBase(x) = x;\nplusStep(x, y, previous) = succ(previous);\nplus(x, y) = primrec(plusBase, plusStep);', 
        10, 
        now()
      )
    ON CONFLICT (id) DO UPDATE SET
        title = EXCLUDED.title,
        description = EXCLUDED.description;

    -- Add a solution from Bob to your challenge
    INSERT INTO public.user_interactions (user_id, challenge_id, has_solved, best_submission_source, solved_at, vote_type)
    VALUES 
      (
        'b0b00000-0000-0000-0000-000000000002', 
        '11111111-1111-1111-1111-111111111111', 
        true, 
        '// Bob''s alternative solution\nplus(x, y) = primrec(x, succ(3));', 
        now(),
        1
      )
    ON CONFLICT (user_id, challenge_id) DO NOTHING;
END $$;
