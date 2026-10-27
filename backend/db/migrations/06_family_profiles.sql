-- Create the family_profiles table
CREATE TABLE IF NOT EXISTS public.family_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    relationship TEXT NOT NULL,
    allergies TEXT[] DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security (RLS)
ALTER TABLE public.family_profiles ENABLE ROW LEVEL SECURITY;

-- Allow users to select their own family profiles
CREATE POLICY "Users can view own family profiles" ON public.family_profiles
    FOR SELECT TO authenticated
    USING (auth.uid() = user_id);

-- Allow users to insert their own family profiles
CREATE POLICY "Users can insert own family profiles" ON public.family_profiles
    FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = user_id);

-- Allow users to update their own family profiles
CREATE POLICY "Users can update own family profiles" ON public.family_profiles
    FOR UPDATE TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Allow users to delete their own family profiles
CREATE POLICY "Users can delete own family profiles" ON public.family_profiles
    FOR DELETE TO authenticated
    USING (auth.uid() = user_id);
