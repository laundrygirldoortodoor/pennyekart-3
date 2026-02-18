
-- Create seller wallets for existing selling partners who don't have one
INSERT INTO public.seller_wallets (seller_id, balance)
SELECT p.user_id, 0
FROM public.profiles p
WHERE p.user_type = 'selling_partner'
  AND NOT EXISTS (
    SELECT 1 FROM public.seller_wallets sw WHERE sw.seller_id = p.user_id
  );

-- Create delivery staff wallets for existing delivery staff who don't have one
INSERT INTO public.delivery_staff_wallets (staff_user_id, balance)
SELECT p.user_id, 0
FROM public.profiles p
WHERE p.user_type = 'delivery_staff'
  AND NOT EXISTS (
    SELECT 1 FROM public.delivery_staff_wallets dw WHERE dw.staff_user_id = p.user_id
  );

-- Create a function to auto-create wallet when a new selling partner or delivery staff is created
CREATE OR REPLACE FUNCTION public.auto_create_partner_wallet()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.user_type = 'selling_partner' THEN
    INSERT INTO public.seller_wallets (seller_id, balance)
    VALUES (NEW.user_id, 0)
    ON CONFLICT DO NOTHING;
  ELSIF NEW.user_type = 'delivery_staff' THEN
    INSERT INTO public.delivery_staff_wallets (staff_user_id, balance)
    VALUES (NEW.user_id, 0)
    ON CONFLICT DO NOTHING;
  END IF;
  RETURN NEW;
END;
$$;

-- Create trigger on profiles table to auto-create wallet
DROP TRIGGER IF EXISTS trg_auto_create_partner_wallet ON public.profiles;
CREATE TRIGGER trg_auto_create_partner_wallet
  AFTER INSERT OR UPDATE OF user_type ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.auto_create_partner_wallet();
