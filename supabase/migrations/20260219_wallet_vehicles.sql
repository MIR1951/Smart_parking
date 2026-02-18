-- Wallet va Vehicle jadvallari — foydalanuvchiga bog'langan
-- Haqiqiy moliyaviy operatsiyalar uchun Supabase RPC

-- ============================================================
-- 1) USER WALLETS — har bir foydalanuvchining balansi
-- ============================================================
CREATE TABLE IF NOT EXISTS public.user_wallets (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    balance BIGINT NOT NULL DEFAULT 0,  -- so'mda, integer
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.user_wallets ENABLE ROW LEVEL SECURITY;

CREATE POLICY user_wallets_select ON public.user_wallets
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY user_wallets_insert ON public.user_wallets
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY user_wallets_update ON public.user_wallets
    FOR UPDATE USING (auth.uid() = user_id);

-- ============================================================
-- 2) WALLET TRANSACTIONS — tranzaksiya tarixi
-- ============================================================
CREATE TABLE IF NOT EXISTS public.wallet_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    amount BIGINT NOT NULL,  -- musbat=top_up, manfiy=payment
    type TEXT NOT NULL CHECK (type IN ('top_up', 'payment')),
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_wallet_transactions_user
    ON public.wallet_transactions (user_id, created_at DESC);

ALTER TABLE public.wallet_transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY wallet_transactions_select ON public.wallet_transactions
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY wallet_transactions_insert ON public.wallet_transactions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- ============================================================
-- 3) USER VEHICLES — foydalanuvchi mashinalari
-- ============================================================
CREATE TABLE IF NOT EXISTS public.user_vehicles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('Sedan', 'SUV', 'MPV', 'Hatchback', 'Pickup')),
    plate_number TEXT NOT NULL,
    color TEXT NOT NULL DEFAULT 'gray',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_user_vehicles_user
    ON public.user_vehicles (user_id);

ALTER TABLE public.user_vehicles ENABLE ROW LEVEL SECURITY;

CREATE POLICY user_vehicles_select ON public.user_vehicles
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY user_vehicles_insert ON public.user_vehicles
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY user_vehicles_update ON public.user_vehicles
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY user_vehicles_delete ON public.user_vehicles
    FOR DELETE USING (auth.uid() = user_id);

-- ============================================================
-- 4) WALLET TOP-UP RPC — atomik to'ldirish
-- ============================================================
CREATE OR REPLACE FUNCTION public.wallet_top_up(
    p_amount BIGINT,
    p_description TEXT DEFAULT 'Hamyon to''ldirildi'
)
RETURNS BIGINT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_balance BIGINT;
BEGIN
    IF p_amount <= 0 THEN
        RAISE EXCEPTION 'Amount must be positive';
    END IF;

    -- Upsert: agar wallet mavjud bo'lmasa yaratish
    INSERT INTO public.user_wallets (user_id, balance, updated_at)
    VALUES (v_user_id, p_amount, now())
    ON CONFLICT (user_id)
    DO UPDATE SET balance = user_wallets.balance + p_amount, updated_at = now();

    -- Tranzaksiya yozish
    INSERT INTO public.wallet_transactions (user_id, amount, type, description)
    VALUES (v_user_id, p_amount, 'top_up', p_description);

    -- Yangi balansni qaytarish
    SELECT balance INTO v_balance FROM public.user_wallets WHERE user_id = v_user_id;
    RETURN v_balance;
END;
$$;

-- ============================================================
-- 5) WALLET DEDUCT RPC — atomik to'lov (yechish)
-- ============================================================
CREATE OR REPLACE FUNCTION public.wallet_deduct(
    p_amount BIGINT,
    p_description TEXT DEFAULT 'Parking to''lovi'
)
RETURNS BIGINT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_balance BIGINT;
BEGIN
    IF p_amount <= 0 THEN
        RAISE EXCEPTION 'Amount must be positive';
    END IF;

    -- Balansni tekshirish (FOR UPDATE — race condition'dan himoya)
    SELECT balance INTO v_balance
    FROM public.user_wallets
    WHERE user_id = v_user_id
    FOR UPDATE;

    IF v_balance IS NULL THEN
        RAISE EXCEPTION 'Wallet not found';
    END IF;

    IF v_balance < p_amount THEN
        RAISE EXCEPTION 'Insufficient balance';
    END IF;

    -- Balansni kamaytirish
    UPDATE public.user_wallets
    SET balance = balance - p_amount, updated_at = now()
    WHERE user_id = v_user_id;

    -- Tranzaksiya yozish (manfiy summa)
    INSERT INTO public.wallet_transactions (user_id, amount, type, description)
    VALUES (v_user_id, -p_amount, 'payment', p_description);

    RETURN v_balance - p_amount;
END;
$$;
