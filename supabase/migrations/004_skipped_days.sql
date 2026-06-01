-- Migration 004: Track skipped workout days so calendar and streaks reflect missed sessions.

BEGIN;

CREATE TABLE IF NOT EXISTS public.skipped_days (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  skipped_date DATE NOT NULL,
  skipped_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(profile_id, skipped_date)
);

CREATE INDEX IF NOT EXISTS idx_skipped_days_profile ON public.skipped_days(profile_id);

ALTER TABLE public.skipped_days DISABLE ROW LEVEL SECURITY;

COMMIT;
