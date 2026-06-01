-- Migration 001: Initial schema setup
-- Apply: supabase migration up
-- NOTE: The app uses custom email/password auth stored in the database.
-- The `users` table below holds credentials and creates profiles via trigger.

BEGIN;

CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  username TEXT DEFAULT 'LockIn',
  email TEXT DEFAULT '',
  laziness INT DEFAULT 5,
  height INT DEFAULT 170,
  weight INT DEFAULT 70,
  age INT DEFAULT 25,
  gender TEXT DEFAULT '',
  goal TEXT DEFAULT 'build_muscle',
  experience TEXT DEFAULT 'beginner',
  time_per_session INT DEFAULT 20,
  health TEXT DEFAULT '',
  onboarding_completed BOOLEAN DEFAULT false,
  groq_key TEXT DEFAULT '',
  step_goal INT DEFAULT 10000,
  step_enabled BOOLEAN DEFAULT false,
  stride_length INT DEFAULT 70,
  daily_steps INT DEFAULT 0,
  water_goal INT DEFAULT 2000,
  daily_water INT DEFAULT 0,
  water_reminder BOOLEAN DEFAULT false,
  last_step_date TEXT DEFAULT '',
  last_water_date TEXT DEFAULT '',
  last_workout_date TEXT DEFAULT '',
  daily_reminders BOOLEAN DEFAULT false,
  difficulty_level TEXT DEFAULT 'Beast',
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE week_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  week_number INT NOT NULL,
  plan_start_date DATE,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE day_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  week_plan_id UUID NOT NULL REFERENCES week_plans(id) ON DELETE CASCADE,
  day_number INT NOT NULL,
  title TEXT NOT NULL,
  focus TEXT DEFAULT '',
  icon TEXT DEFAULT '🔥',
  scheduled_date DATE,
  is_rest BOOLEAN DEFAULT false
);

CREATE TABLE exercises (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  day_plan_id UUID NOT NULL REFERENCES day_plans(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  sets INT DEFAULT 3,
  reps TEXT DEFAULT '10',
  target TEXT DEFAULT '',
  log_key TEXT,
  log_val INT DEFAULT 0,
  is_timed BOOLEAN DEFAULT false,
  sort_order INT DEFAULT 0
);

CREATE TABLE face_exercises (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  day_plan_id UUID NOT NULL REFERENCES day_plans(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  sets INT DEFAULT 3,
  reps TEXT DEFAULT '10',
  target TEXT DEFAULT '',
  sort_order INT DEFAULT 0
);

CREATE TABLE lookmax_tips (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  day_plan_id UUID NOT NULL REFERENCES day_plans(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  sort_order INT DEFAULT 0
);

CREATE TABLE progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID NOT NULL UNIQUE REFERENCES profiles(id) ON DELETE CASCADE,
  workouts INT DEFAULT 0,
  streak INT DEFAULT 0,
  total_days INT DEFAULT 0,
  pushup_max INT DEFAULT 0,
  squat_max INT DEFAULT 0,
  plank_max INT DEFAULT 0,
  burpee_max INT DEFAULT 0,
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE completed_days (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  day_index INT NOT NULL,
  completed_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(profile_id, day_index)
);

CREATE TABLE skipped_days (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  skipped_date DATE NOT NULL,
  skipped_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(profile_id, skipped_date)
);

CREATE TABLE coach_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('user', 'assistant')),
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Indexes
CREATE INDEX idx_week_plans_profile ON week_plans(profile_id);
CREATE INDEX idx_day_plans_week ON day_plans(week_plan_id);
CREATE INDEX idx_exercises_day ON exercises(day_plan_id);
CREATE INDEX idx_face_exercises_day ON face_exercises(day_plan_id);
CREATE INDEX idx_lookmax_tips_day ON lookmax_tips(day_plan_id);
CREATE INDEX idx_progress_profile ON progress(profile_id);
CREATE INDEX idx_completed_days_profile ON completed_days(profile_id);
CREATE INDEX idx_skipped_days_profile ON skipped_days(profile_id);
CREATE INDEX idx_coach_messages_profile ON coach_messages(profile_id);

-- No RLS
ALTER TABLE users DISABLE ROW LEVEL SECURITY;
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE week_plans DISABLE ROW LEVEL SECURITY;
ALTER TABLE day_plans DISABLE ROW LEVEL SECURITY;
ALTER TABLE exercises DISABLE ROW LEVEL SECURITY;
ALTER TABLE face_exercises DISABLE ROW LEVEL SECURITY;
ALTER TABLE lookmax_tips DISABLE ROW LEVEL SECURITY;
ALTER TABLE progress DISABLE ROW LEVEL SECURITY;
ALTER TABLE completed_days DISABLE ROW LEVEL SECURITY;
ALTER TABLE coach_messages DISABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.profiles (id, username, email)
  VALUES (
    NEW.id,
    'LockIn',
    NEW.email
  );
  INSERT INTO public.progress (profile_id)
  VALUES (NEW.id);
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_new_user_created
  AFTER INSERT ON users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

COMMIT;
