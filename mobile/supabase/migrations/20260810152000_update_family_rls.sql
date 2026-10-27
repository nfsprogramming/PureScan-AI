-- Helper function to break RLS infinite recursion
CREATE OR REPLACE FUNCTION public.get_user_families(usr_id UUID)
RETURNS SETOF UUID 
LANGUAGE sql 
SECURITY DEFINER 
SET search_path = public 
AS $$
    SELECT id FROM family_groups WHERE owner_user_id = usr_id
    UNION
    SELECT family_id FROM family_members WHERE user_id = usr_id;
$$;

-- family_groups policies
DROP POLICY IF EXISTS "Users can view their own family groups" ON public.family_groups;
CREATE POLICY "Users can view their own family groups"
    ON public.family_groups FOR SELECT
    USING (auth.uid() = owner_user_id OR id IN (SELECT public.get_user_families(auth.uid())));

DROP POLICY IF EXISTS "Users can insert their own family groups" ON public.family_groups;
CREATE POLICY "Users can insert their own family groups"
    ON public.family_groups FOR INSERT
    WITH CHECK (auth.uid() = owner_user_id);

DROP POLICY IF EXISTS "Users can delete their own family groups" ON public.family_groups;
CREATE POLICY "Users can delete their own family groups"
    ON public.family_groups FOR DELETE
    USING (auth.uid() = owner_user_id);

-- family_members policies
DROP POLICY IF EXISTS "Users can view members of their family groups" ON public.family_members;
CREATE POLICY "Users can view members of their family groups"
    ON public.family_members FOR SELECT
    USING (auth.uid() = user_id OR family_id IN (SELECT public.get_user_families(auth.uid())));

DROP POLICY IF EXISTS "Owners can insert family members" ON public.family_members;
CREATE POLICY "Owners can insert family members"
    ON public.family_members FOR INSERT
    WITH CHECK (
        auth.uid() IN (SELECT owner_user_id FROM public.family_groups WHERE id = family_id) 
        OR auth.uid() = user_id
    );

DROP POLICY IF EXISTS "Owners can delete family members" ON public.family_members;
CREATE POLICY "Owners can delete family members"
    ON public.family_members FOR DELETE
    USING (
        auth.uid() IN (SELECT owner_user_id FROM public.family_groups WHERE id = family_id) 
        OR auth.uid() = user_id
    );

-- family_invitations policies
DROP POLICY IF EXISTS "Users can view invitations for their family groups" ON public.family_invitations;
CREATE POLICY "Users can view invitations for their family groups"
    ON public.family_invitations FOR SELECT
    USING (
        auth.uid() = inviter_user_id
        OR
        family_id IN (SELECT public.get_user_families(auth.uid()))
    );
    
DROP POLICY IF EXISTS "Anyone can view pending invitations by token" ON public.family_invitations;
CREATE POLICY "Anyone can view pending invitations by token"
    ON public.family_invitations FOR SELECT
    USING (status = 'pending' AND expires_at > NOW());

DROP POLICY IF EXISTS "Inviters can insert invitations" ON public.family_invitations;
CREATE POLICY "Inviters can insert invitations"
    ON public.family_invitations FOR INSERT
    WITH CHECK (auth.uid() = inviter_user_id);

DROP POLICY IF EXISTS "Users can update invitations they accept" ON public.family_invitations;
CREATE POLICY "Users can update invitations they accept"
    ON public.family_invitations FOR UPDATE
    USING (status = 'pending');
