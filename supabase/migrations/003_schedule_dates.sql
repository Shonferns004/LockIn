-- Migration 003: Persist calendar dates for plans and days
-- This removes client-side date drift by storing the exact schedule in Supabase.

BEGIN;

ALTER TABLE public.week_plans
  ADD COLUMN IF NOT EXISTS plan_start_date DATE;

ALTER TABLE public.day_plans
  ADD COLUMN IF NOT EXISTS scheduled_date DATE;

UPDATE public.week_plans
SET plan_start_date = COALESCE(plan_start_date, created_at::date)
WHERE plan_start_date IS NULL;

UPDATE public.day_plans dp
SET scheduled_date = COALESCE(
  dp.scheduled_date,
  (wp.plan_start_date + (dp.day_number - 1))
)
FROM public.week_plans wp
WHERE dp.week_plan_id = wp.id
  AND dp.scheduled_date IS NULL
  AND wp.plan_start_date IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_week_plans_start_date ON public.week_plans(plan_start_date);
CREATE INDEX IF NOT EXISTS idx_day_plans_scheduled_date ON public.day_plans(scheduled_date);

COMMIT;
