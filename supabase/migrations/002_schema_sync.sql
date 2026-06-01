-- Migration 002: Schema sync and hardening
-- Apply after 001_initial.sql.
-- This keeps the live database aligned with the app code without wiping data.

BEGIN;

--------------------------------------------------
-- Core tables: make sure expected columns exist
--------------------------------------------------

ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT now();

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS username TEXT DEFAULT 'LockIn',
  ADD COLUMN IF NOT EXISTS email TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS laziness INT DEFAULT 5,
  ADD COLUMN IF NOT EXISTS height INT DEFAULT 170,
  ADD COLUMN IF NOT EXISTS weight INT DEFAULT 70,
  ADD COLUMN IF NOT EXISTS age INT DEFAULT 25,
  ADD COLUMN IF NOT EXISTS gender TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS goal TEXT DEFAULT 'build_muscle',
  ADD COLUMN IF NOT EXISTS experience TEXT DEFAULT 'beginner',
  ADD COLUMN IF NOT EXISTS time_per_session INT DEFAULT 20,
  ADD COLUMN IF NOT EXISTS health TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS onboarding_completed BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS groq_key TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS step_goal INT DEFAULT 10000,
  ADD COLUMN IF NOT EXISTS step_enabled BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS stride_length INT DEFAULT 70,
  ADD COLUMN IF NOT EXISTS daily_steps INT DEFAULT 0,
  ADD COLUMN IF NOT EXISTS water_goal INT DEFAULT 2000,
  ADD COLUMN IF NOT EXISTS daily_water INT DEFAULT 0,
  ADD COLUMN IF NOT EXISTS water_reminder BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS last_step_date TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS last_water_date TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS last_workout_date TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS daily_reminders BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS difficulty_level TEXT DEFAULT 'Beast',
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT now(),
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT now();

ALTER TABLE public.week_plans
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT now();

ALTER TABLE public.day_plans
  ADD COLUMN IF NOT EXISTS focus TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS icon TEXT DEFAULT '🔥',
  ADD COLUMN IF NOT EXISTS is_rest BOOLEAN DEFAULT false;

ALTER TABLE public.exercises
  ADD COLUMN IF NOT EXISTS target TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS log_key TEXT,
  ADD COLUMN IF NOT EXISTS log_val INT DEFAULT 0,
  ADD COLUMN IF NOT EXISTS is_timed BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS sort_order INT DEFAULT 0;

ALTER TABLE public.face_exercises
  ADD COLUMN IF NOT EXISTS target TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS sort_order INT DEFAULT 0;

ALTER TABLE public.lookmax_tips
  ADD COLUMN IF NOT EXISTS content TEXT NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS sort_order INT DEFAULT 0;

ALTER TABLE public.progress
  ADD COLUMN IF NOT EXISTS workouts INT DEFAULT 0,
  ADD COLUMN IF NOT EXISTS streak INT DEFAULT 0,
  ADD COLUMN IF NOT EXISTS total_days INT DEFAULT 0,
  ADD COLUMN IF NOT EXISTS pushup_max INT DEFAULT 0,
  ADD COLUMN IF NOT EXISTS squat_max INT DEFAULT 0,
  ADD COLUMN IF NOT EXISTS plank_max INT DEFAULT 0,
  ADD COLUMN IF NOT EXISTS burpee_max INT DEFAULT 0,
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT now();

CREATE TABLE IF NOT EXISTS public.skipped_days (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  skipped_date DATE NOT NULL,
  skipped_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(profile_id, skipped_date)
);

ALTER TABLE public.completed_days
  ADD COLUMN IF NOT EXISTS completed_at TIMESTAMPTZ DEFAULT now();

ALTER TABLE public.skipped_days
  ADD COLUMN IF NOT EXISTS skipped_at TIMESTAMPTZ DEFAULT now();

ALTER TABLE public.coach_messages
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT now();

--------------------------------------------------
-- Indexes and constraints
--------------------------------------------------

CREATE INDEX IF NOT EXISTS idx_week_plans_profile ON public.week_plans(profile_id);
CREATE INDEX IF NOT EXISTS idx_day_plans_week ON public.day_plans(week_plan_id);
CREATE INDEX IF NOT EXISTS idx_exercises_day ON public.exercises(day_plan_id);
CREATE INDEX IF NOT EXISTS idx_face_exercises_day ON public.face_exercises(day_plan_id);
CREATE INDEX IF NOT EXISTS idx_lookmax_tips_day ON public.lookmax_tips(day_plan_id);
CREATE INDEX IF NOT EXISTS idx_progress_profile ON public.progress(profile_id);
CREATE INDEX IF NOT EXISTS idx_completed_days_profile ON public.completed_days(profile_id);
CREATE INDEX IF NOT EXISTS idx_skipped_days_profile ON public.skipped_days(profile_id);
CREATE INDEX IF NOT EXISTS idx_coach_messages_profile ON public.coach_messages(profile_id);

--------------------------------------------------
-- RLS stays disabled for this app's current auth model
--------------------------------------------------

ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.week_plans DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.day_plans DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.exercises DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.face_exercises DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.lookmax_tips DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.progress DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.completed_days DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.skipped_days DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.coach_messages DISABLE ROW LEVEL SECURITY;

--------------------------------------------------
-- New user bootstrap
--------------------------------------------------

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.profiles (id, username, email, onboarding_completed, daily_reminders)
  VALUES (NEW.id, 'LockIn', NEW.email, false, false)
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.progress (profile_id)
  VALUES (NEW.id)
  ON CONFLICT (profile_id) DO NOTHING;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_new_user_created ON public.users;

CREATE TRIGGER on_new_user_created
AFTER INSERT ON public.users
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_user();

COMMIT;
