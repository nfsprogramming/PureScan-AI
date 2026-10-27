-- Remove all Family Profiles data and schema
DROP TABLE IF EXISTS public.family_invitations CASCADE;
DROP TABLE IF EXISTS public.family_members CASCADE;
DROP TABLE IF EXISTS public.family_groups CASCADE;
DROP FUNCTION IF EXISTS public.get_user_families(UUID) CASCADE;
