-- Location: supabase/migrations/20250821020244_lawyer_connect_system.sql
-- Schema Analysis: Fresh project with no existing schema
-- Integration Type: Complete lawyer-client management system
-- Dependencies: Authentication + business tables for legal services

-- 1. Types and Enums
CREATE TYPE public.user_role AS ENUM ('admin', 'lawyer', 'client');
CREATE TYPE public.appointment_status AS ENUM ('pending', 'confirmed', 'completed', 'cancelled');
CREATE TYPE public.expertise_area AS ENUM ('civil_law', 'criminal_law', 'corporate_law', 'family_law', 'immigration_law', 'intellectual_property', 'labor_law', 'tax_law', 'real_estate', 'other');
CREATE TYPE public.availability_status AS ENUM ('available', 'busy', 'away');

-- 2. Core User Management Tables
CREATE TABLE public.user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL UNIQUE,
    full_name TEXT NOT NULL,
    role public.user_role DEFAULT 'client'::public.user_role,
    phone TEXT,
    profile_image_url TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. Lawyer-specific Tables
CREATE TABLE public.lawyer_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    license_number TEXT UNIQUE NOT NULL,
    bar_association TEXT NOT NULL,
    years_of_experience INTEGER DEFAULT 0,
    specializations public.expertise_area[] DEFAULT '{}',
    hourly_rate DECIMAL(10,2),
    bio TEXT,
    education TEXT,
    certifications TEXT[],
    languages TEXT[] DEFAULT '{"English"}',
    office_address TEXT,
    is_verified BOOLEAN DEFAULT false,
    average_rating DECIMAL(3,2) DEFAULT 0.00,
    total_reviews INTEGER DEFAULT 0,
    total_cases INTEGER DEFAULT 0,
    success_rate DECIMAL(5,2) DEFAULT 0.00,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 4. Lawyer Availability Management
CREATE TABLE public.lawyer_availability (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lawyer_id UUID REFERENCES public.lawyer_profiles(id) ON DELETE CASCADE,
    day_of_week INTEGER NOT NULL CHECK (day_of_week >= 0 AND day_of_week <= 6), -- 0 = Sunday
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    is_available BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 5. Appointments Management
CREATE TABLE public.appointments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    lawyer_id UUID REFERENCES public.lawyer_profiles(id) ON DELETE CASCADE,
    appointment_date DATE NOT NULL,
    appointment_time TIME NOT NULL,
    duration_minutes INTEGER DEFAULT 60,
    status public.appointment_status DEFAULT 'pending'::public.appointment_status,
    consultation_type TEXT DEFAULT 'general',
    description TEXT,
    meeting_link TEXT,
    notes TEXT,
    total_cost DECIMAL(10,2),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 6. Reviews and Ratings
CREATE TABLE public.reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    lawyer_id UUID REFERENCES public.lawyer_profiles(id) ON DELETE CASCADE,
    appointment_id UUID REFERENCES public.appointments(id) ON DELETE CASCADE,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    review_text TEXT,
    is_anonymous BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 7. Lawyer Gallery/Portfolio
CREATE TABLE public.lawyer_gallery (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lawyer_id UUID REFERENCES public.lawyer_profiles(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    caption TEXT,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 8. System Notifications
CREATE TABLE public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT DEFAULT 'general',
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 9. Essential Indexes
CREATE INDEX idx_user_profiles_role ON public.user_profiles(role);
CREATE INDEX idx_user_profiles_active ON public.user_profiles(is_active);
CREATE INDEX idx_lawyer_profiles_user_id ON public.lawyer_profiles(user_id);
CREATE INDEX idx_lawyer_profiles_verified ON public.lawyer_profiles(is_verified);
CREATE INDEX idx_lawyer_profiles_specializations ON public.lawyer_profiles USING GIN (specializations);
CREATE INDEX idx_lawyer_availability_lawyer_id ON public.lawyer_availability(lawyer_id);
CREATE INDEX idx_lawyer_availability_day ON public.lawyer_availability(day_of_week);
CREATE INDEX idx_appointments_client_id ON public.appointments(client_id);
CREATE INDEX idx_appointments_lawyer_id ON public.appointments(lawyer_id);
CREATE INDEX idx_appointments_date ON public.appointments(appointment_date);
CREATE INDEX idx_appointments_status ON public.appointments(status);
CREATE INDEX idx_reviews_lawyer_id ON public.reviews(lawyer_id);
CREATE INDEX idx_reviews_rating ON public.reviews(rating);
CREATE INDEX idx_lawyer_gallery_lawyer_id ON public.lawyer_gallery(lawyer_id);
CREATE INDEX idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX idx_notifications_unread ON public.notifications(is_read);

-- 10. Enable RLS
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lawyer_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lawyer_availability ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lawyer_gallery ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- 11. Helper Functions (MUST BE BEFORE RLS POLICIES)
CREATE OR REPLACE FUNCTION public.is_lawyer_owner(lawyer_profile_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM public.lawyer_profiles lp
    WHERE lp.id = lawyer_profile_id AND lp.user_id = auth.uid()
)
$$;

CREATE OR REPLACE FUNCTION public.is_appointment_participant(appointment_uuid UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM public.appointments a
    JOIN public.lawyer_profiles lp ON a.lawyer_id = lp.id
    WHERE a.id = appointment_uuid 
    AND (a.client_id = auth.uid() OR lp.user_id = auth.uid())
)
$$;

-- 12. RLS Policies
-- Pattern 1: Core user tables
CREATE POLICY "users_manage_own_user_profiles"
ON public.user_profiles
FOR ALL
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

CREATE POLICY "users_manage_own_user_profiles"
ON public.user_profiles
FOR INSERT
TO authenticated
WITH CHECK (id = auth.uid());

-- Pattern 2: Simple user ownership for lawyer profiles
CREATE POLICY "lawyers_manage_own_lawyer_profiles"
ON public.lawyer_profiles
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Pattern 4: Public read for lawyer profiles (clients can browse lawyers)
CREATE POLICY "public_can_read_verified_lawyers"
ON public.lawyer_profiles
FOR SELECT
TO public
USING (is_verified = true AND EXISTS (SELECT 1 FROM public.user_profiles WHERE id = user_id AND is_active = true));

-- Pattern 2: Simple ownership for availability
CREATE POLICY "lawyers_manage_own_availability"
ON public.lawyer_availability
FOR ALL
TO authenticated
USING (public.is_lawyer_owner(lawyer_id))
WITH CHECK (public.is_lawyer_owner(lawyer_id));

-- Pattern 4: Public read for lawyer availability
CREATE POLICY "public_can_read_lawyer_availability"
ON public.lawyer_availability
FOR SELECT
TO public
USING (is_available = true);

-- Pattern 7: Complex relationship for appointments
CREATE POLICY "participants_manage_appointments"
ON public.appointments
FOR ALL
TO authenticated
USING (public.is_appointment_participant(id))
WITH CHECK (client_id = auth.uid());

-- Pattern 2: Simple ownership for reviews
CREATE POLICY "users_manage_own_reviews"
ON public.reviews
FOR ALL
TO authenticated
USING (client_id = auth.uid())
WITH CHECK (client_id = auth.uid());

-- Pattern 4: Public read for reviews
CREATE POLICY "public_can_read_reviews"
ON public.reviews
FOR SELECT
TO public
USING (true);

-- Pattern 2: Simple ownership for gallery
CREATE POLICY "lawyers_manage_own_gallery"
ON public.lawyer_gallery
FOR ALL
TO authenticated
USING (public.is_lawyer_owner(lawyer_id))
WITH CHECK (public.is_lawyer_owner(lawyer_id));

-- Pattern 4: Public read for gallery
CREATE POLICY "public_can_read_lawyer_gallery"
ON public.lawyer_gallery
FOR SELECT
TO public
USING (true);

-- Pattern 2: Simple ownership for notifications
CREATE POLICY "users_manage_own_notifications"
ON public.notifications
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Pattern 4: Public read for active users
CREATE POLICY "public_can_read_active_users"
ON public.user_profiles
FOR SELECT
TO public
USING (is_active = true);

-- 13. Automatic User Profile Creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO public.user_profiles (id, email, full_name, role)
  VALUES (
    NEW.id, 
    NEW.email, 
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'role', 'client')::public.user_role
  );
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 14. Update Functions
CREATE OR REPLACE FUNCTION public.update_lawyer_rating()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE public.lawyer_profiles
  SET 
    average_rating = (
      SELECT COALESCE(AVG(rating::DECIMAL), 0.00)
      FROM public.reviews 
      WHERE lawyer_id = NEW.lawyer_id
    ),
    total_reviews = (
      SELECT COUNT(*)
      FROM public.reviews 
      WHERE lawyer_id = NEW.lawyer_id
    ),
    updated_at = CURRENT_TIMESTAMP
  WHERE id = NEW.lawyer_id;
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_review_created
  AFTER INSERT ON public.reviews
  FOR EACH ROW EXECUTE FUNCTION public.update_lawyer_rating();

-- 15. Mock Data for Development
DO $$
DECLARE
    admin_uuid UUID := gen_random_uuid();
    lawyer1_uuid UUID := gen_random_uuid();
    lawyer2_uuid UUID := gen_random_uuid();
    client1_uuid UUID := gen_random_uuid();
    client2_uuid UUID := gen_random_uuid();
    lawyer_profile1_id UUID := gen_random_uuid();
    lawyer_profile2_id UUID := gen_random_uuid();
    appointment1_id UUID := gen_random_uuid();
    appointment2_id UUID := gen_random_uuid();
BEGIN
    -- Create auth users with complete field structure
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        created_at, updated_at, raw_user_meta_data, raw_app_meta_data,
        is_sso_user, is_anonymous, confirmation_token, confirmation_sent_at,
        recovery_token, recovery_sent_at, email_change_token_new, email_change,
        email_change_sent_at, email_change_token_current, email_change_confirm_status,
        reauthentication_token, reauthentication_sent_at, phone, phone_change,
        phone_change_token, phone_change_sent_at
    ) VALUES
        (admin_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'admin@lawyerconnect.com', crypt('admin123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Admin User", "role": "admin"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (lawyer1_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'sarah.johnson@lawyerconnect.com', crypt('lawyer123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Sarah Johnson", "role": "lawyer"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (lawyer2_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'michael.chen@lawyerconnect.com', crypt('lawyer123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Michael Chen", "role": "lawyer"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (client1_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'john.doe@example.com', crypt('client123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "John Doe", "role": "client"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (client2_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'emily.wilson@example.com', crypt('client123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Emily Wilson", "role": "client"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null);

    -- Create lawyer profiles
    INSERT INTO public.lawyer_profiles (id, user_id, license_number, bar_association, years_of_experience, 
                                        specializations, hourly_rate, bio, education, is_verified, average_rating, total_reviews)
    VALUES
        (lawyer_profile1_id, lawyer1_uuid, 'LAW-2019-001', 'California State Bar', 8,
         '{"civil_law", "corporate_law"}'::public.expertise_area[], 350.00,
         'Experienced corporate lawyer with expertise in mergers and acquisitions. Dedicated to providing comprehensive legal solutions.',
         'Harvard Law School, JD; Stanford University, BA Business', true, 4.8, 24),
        (lawyer_profile2_id, lawyer2_uuid, 'LAW-2020-002', 'New York State Bar', 6,
         '{"family_law", "criminal_law"}'::public.expertise_area[], 280.00,
         'Compassionate family law attorney committed to protecting families and children. Strong background in criminal defense.',
         'Columbia Law School, JD; UCLA, BA Psychology', true, 4.6, 18);

    -- Create lawyer availability
    INSERT INTO public.lawyer_availability (lawyer_id, day_of_week, start_time, end_time)
    VALUES
        (lawyer_profile1_id, 1, '09:00', '17:00'), -- Monday
        (lawyer_profile1_id, 2, '09:00', '17:00'), -- Tuesday  
        (lawyer_profile1_id, 3, '09:00', '17:00'), -- Wednesday
        (lawyer_profile1_id, 4, '09:00', '17:00'), -- Thursday
        (lawyer_profile1_id, 5, '09:00', '15:00'), -- Friday
        (lawyer_profile2_id, 1, '10:00', '18:00'), -- Monday
        (lawyer_profile2_id, 2, '10:00', '18:00'), -- Tuesday
        (lawyer_profile2_id, 3, '10:00', '18:00'), -- Wednesday
        (lawyer_profile2_id, 4, '10:00', '18:00'), -- Thursday
        (lawyer_profile2_id, 5, '10:00', '16:00'); -- Friday

    -- Create appointments
    INSERT INTO public.appointments (id, client_id, lawyer_id, appointment_date, appointment_time, 
                                     status, consultation_type, description, total_cost)
    VALUES
        (appointment1_id, client1_uuid, lawyer_profile1_id, CURRENT_DATE + INTERVAL '3 days', '14:00',
         'confirmed'::public.appointment_status, 'Corporate Consultation', 
         'Business incorporation and legal structure consultation', 350.00),
        (appointment2_id, client2_uuid, lawyer_profile2_id, CURRENT_DATE + INTERVAL '1 week', '15:30',
         'pending'::public.appointment_status, 'Family Law Consultation',
         'Divorce proceedings and child custody consultation', 280.00);

    -- Create reviews
    INSERT INTO public.reviews (client_id, lawyer_id, appointment_id, rating, review_text)
    VALUES
        (client1_uuid, lawyer_profile1_id, appointment1_id, 5, 
         'Excellent service! Sarah was very professional and provided clear guidance for our business setup.'),
        (client2_uuid, lawyer_profile2_id, appointment2_id, 4,
         'Michael was very understanding and helped me navigate a difficult family situation with care.');

    -- Create gallery entries
    INSERT INTO public.lawyer_gallery (lawyer_id, image_url, caption, display_order)
    VALUES
        (lawyer_profile1_id, 'https://images.unsplash.com/photo-1556157382-97eda2d62296', 'Professional office environment', 1),
        (lawyer_profile1_id, 'https://images.unsplash.com/photo-1521791136064-7986c2920216', 'Client consultation room', 2),
        (lawyer_profile2_id, 'https://images.unsplash.com/photo-1590012314607-cda9d9b699ae', 'Family law library', 1),
        (lawyer_profile2_id, 'https://images.unsplash.com/photo-1589994965851-a8f479c573a9', 'Mediation conference room', 2);

    -- Create notifications
    INSERT INTO public.notifications (user_id, title, message, type)
    VALUES
        (client1_uuid, 'Appointment Confirmed', 'Your appointment with Sarah Johnson has been confirmed for next Friday.', 'appointment'),
        (lawyer1_uuid, 'New Review', 'You received a new 5-star review from John Doe.', 'review'),
        (client2_uuid, 'Appointment Pending', 'Your appointment request with Michael Chen is awaiting confirmation.', 'appointment');

EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'Foreign key error: %', SQLERRM;
    WHEN unique_violation THEN
        RAISE NOTICE 'Unique constraint error: %', SQLERRM;
    WHEN OTHERS THEN
        RAISE NOTICE 'Unexpected error: %', SQLERRM;
END $$;