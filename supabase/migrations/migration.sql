-- Migration 006: Final consolidated schema
-- Run this in Supabase SQL Editor. Safe to run multiple times (idempotent).
-- Covers: all 11 tables, indexes, RLS disable, user auto-bootstrap trigger.

BEGIN;

--------------------------------------------------
-- 1. Tables
--------------------------------------------------

CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL DEFAULT 'auth',
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
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
  sound_muted BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.week_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  week_number INT NOT NULL,
  plan_start_date DATE,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.day_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  week_plan_id UUID NOT NULL REFERENCES public.week_plans(id) ON DELETE CASCADE,
  day_number INT NOT NULL,
  title TEXT NOT NULL,
  focus TEXT DEFAULT '',
  icon TEXT DEFAULT '🔥',
  scheduled_date DATE,
  is_rest BOOLEAN DEFAULT false
);

CREATE TABLE IF NOT EXISTS public.exercises (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  day_plan_id UUID NOT NULL REFERENCES public.day_plans(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  sets INT DEFAULT 3,
  reps TEXT DEFAULT '10',
  target TEXT DEFAULT '',
  log_key TEXT,
  log_val INT DEFAULT 0,
  is_timed BOOLEAN DEFAULT false,
  sort_order INT DEFAULT 0
);

CREATE TABLE IF NOT EXISTS public.face_exercises (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  day_plan_id UUID NOT NULL REFERENCES public.day_plans(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  sets INT DEFAULT 3,
  reps TEXT DEFAULT '10',
  target TEXT DEFAULT '',
  sort_order INT DEFAULT 0
);

CREATE TABLE IF NOT EXISTS public.lookmax_tips (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  day_plan_id UUID NOT NULL REFERENCES public.day_plans(id) ON DELETE CASCADE,
  content TEXT NOT NULL DEFAULT '',
  sort_order INT DEFAULT 0
);

CREATE TABLE IF NOT EXISTS public.progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID NOT NULL UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
  workouts INT DEFAULT 0,
  streak INT DEFAULT 0,
  total_days INT DEFAULT 0,
  pushup_max INT DEFAULT 0,
  squat_max INT DEFAULT 0,
  plank_max INT DEFAULT 0,
  burpee_max INT DEFAULT 0,
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.completed_days (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  day_index INT NOT NULL,
  completed_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(profile_id, day_index)
);

CREATE TABLE IF NOT EXISTS public.skipped_days (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  skipped_date DATE NOT NULL,
  skipped_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(profile_id, skipped_date)
);

CREATE TABLE IF NOT EXISTS public.coach_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('user', 'assistant')),
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

--------------------------------------------------
-- 2. Indexes
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
CREATE INDEX IF NOT EXISTS idx_week_plans_start_date ON public.week_plans(plan_start_date);
CREATE INDEX IF NOT EXISTS idx_day_plans_scheduled_date ON public.day_plans(scheduled_date);

--------------------------------------------------
-- 3. Disable RLS (app uses service-role key via backend)
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
-- 4. Trigger: auto-bootstrap profile + progress on signup
--------------------------------------------------

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, username, email, onboarding_completed)
  VALUES (NEW.id, 'LockIn', NEW.email, false)
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
