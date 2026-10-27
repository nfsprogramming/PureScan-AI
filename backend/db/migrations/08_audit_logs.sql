CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    action TEXT NOT NULL,
    entity_id TEXT,
    performed_by UUID REFERENCES users(id),
    performed_by_role TEXT,
    timestamp TIMESTAMPTZ DEFAULT NOW()
);
