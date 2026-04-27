-- Enable Realtime on log table
-- Run this in Supabase SQL Editor

-- 1. Enable Realtime for the log table
ALTER PUBLICATION supabase_realtime ADD TABLE log;

-- 2. Verify Realtime is enabled
SELECT schemaname, tablename, pubname 
FROM pg_publication_tables 
WHERE tablename = 'log';

-- 3. Grant necessary permissions
GRANT SELECT ON log TO anon;
GRANT SELECT ON log TO authenticated;

-- 4. Enable Row Level Security (if not already enabled)
ALTER TABLE log ENABLE ROW LEVEL SECURITY;

-- 5. Create policy to allow reading logs (if not exists)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'log' 
        AND policyname = 'Allow read access to logs'
    ) THEN
        CREATE POLICY "Allow read access to logs"
            ON log
            FOR SELECT
            TO authenticated, anon
            USING (true);
    END IF;
END $$;

-- Done! Realtime should now work on the log table
