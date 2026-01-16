-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Enumerations
CREATE TYPE entity_status AS ENUM ('ACTIVE', 'INACTIVE', 'DISSOLVED', 'MERGED');
CREATE TYPE sourcing_mode AS ENUM ('AUTOMATED', 'SEMI_AUTOMATED', 'MANUAL');
CREATE TYPE sourcing_method AS ENUM ('API', 'FILE', 'AGENT', 'OCR', 'HUMAN');
CREATE TYPE quality_flag AS ENUM ('CLEAN', 'WARNING', 'CRITICAL');
CREATE TYPE registry_type AS ENUM ('BUSINESS', 'TAX', 'FI', 'INDIVIDUAL');
CREATE TYPE api_type AS ENUM ('REST', 'SOAP', 'SDMX', 'FILE', 'NONE');
CREATE TYPE cost_model AS ENUM ('FREE', 'SUBSCRIPTION', 'PER_QUERY', 'CONTRACT');
CREATE TYPE health_status AS ENUM ('HEALTHY', 'DEGRADED', 'DOWN', 'UNKNOWN');
CREATE TYPE auth_type AS ENUM ('NONE', 'API_KEY', 'OAUTH2', 'CERT', 'BASIC');
CREATE TYPE task_type AS ENUM ('MANUAL_REFRESH', 'ER_REVIEW', 'DQ_REMEDIATION', 'OCR_VERIFICATION', 'CONFLICT_RESOLUTION');
CREATE TYPE task_status AS ENUM ('PENDING', 'IN_PROGRESS', 'ON_HOLD', 'COMPLETED', 'CANCELLED', 'ESCALATED');
CREATE TYPE match_decision_type AS ENUM ('AUTO_LINKED', 'MANUAL_LINKED', 'REJECTED', 'SPLIT', 'DEFERRED');
CREATE TYPE dq_category AS ENUM ('COMPLETENESS', 'FORMAT', 'CONSISTENCY', 'CURRENCY', 'ACCURACY', 'UNIQUENESS');
CREATE TYPE alert_severity AS ENUM ('INFO', 'WARNING', 'ERROR', 'CRITICAL');
CREATE TYPE verification_status AS ENUM ('UNVERIFIED', 'VERIFIED', 'REJECTED');
CREATE TYPE relationship_type AS ENUM ('PARENT', 'SUBSIDIARY', 'BRANCH', 'UBO', 'DIRECTOR', 'SHAREHOLDER', 'FUND_MANAGER');
CREATE TYPE entity_event_type AS ENUM ('INCORPORATION', 'NAME_CHANGE', 'ADDRESS_CHANGE', 'STATUS_CHANGE', 'MERGER', 'ACQUISITION', 'SPLIT', 'DISSOLUTION', 'LIQUIDATION', 'REDOMICILIATION');

-- Jurisdiction table
CREATE TABLE jurisdictions (
    jurisdiction_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    iso_alpha2 VARCHAR(2) NOT NULL UNIQUE,
    iso_alpha3 VARCHAR(3),
    name VARCHAR(100) NOT NULL,
    level VARCHAR(20) NOT NULL CHECK (level IN ('COUNTRY', 'TERRITORY', 'SUPRANATIONAL')),
    parent_id UUID REFERENCES jurisdictions(jurisdiction_id),
    stale_threshold_days INTEGER DEFAULT 365,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Registry Source table
CREATE TABLE registry_sources (
    source_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    source_code VARCHAR(50) NOT NULL UNIQUE,
    source_name VARCHAR(200) NOT NULL,
    jurisdiction_id UUID REFERENCES jurisdictions(jurisdiction_id),
    registry_type registry_type NOT NULL,
    api_available BOOLEAN DEFAULT FALSE,
    api_type api_type DEFAULT 'NONE',
    api_endpoint VARCHAR(500),
    cost_model cost_model DEFAULT 'FREE',
    refresh_frequency VARCHAR(50),
    delta_available BOOLEAN DEFAULT FALSE,
    identifier_format VARCHAR(200),
    identifier_regex VARCHAR(500),
    priority_rank INTEGER DEFAULT 5,
    rate_limit_requests INTEGER,
    rate_limit_period_seconds INTEGER,
    auth_type auth_type DEFAULT 'NONE',
    auth_config JSONB,
    health_status health_status DEFAULT 'UNKNOWN',
    last_health_check TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT TRUE,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Legal Entity table
CREATE TABLE legal_entities (
    entity_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    internal_ref VARCHAR(50),
    status entity_status DEFAULT 'ACTIVE',
    merged_into_id UUID REFERENCES legal_entities(entity_id),
    merge_ts TIMESTAMPTZ,
    risk_rating VARCHAR(20),
    last_verified_ts TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT entity_not_self_merged CHECK (merged_into_id != entity_id)
);

-- Registry Record table (immutable)
CREATE TABLE registry_records (
    record_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    source_id UUID NOT NULL REFERENCES registry_sources(source_id),
    valid_from_source DATE,
    ingestion_ts TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    sourcing_mode sourcing_mode NOT NULL,
    sourcing_method sourcing_method NOT NULL,
    stale_flag BOOLEAN DEFAULT FALSE,
    quality_flag quality_flag DEFAULT 'CLEAN',
    verification_status verification_status DEFAULT 'UNVERIFIED',
    superseded_by_id UUID REFERENCES registry_records(record_id),
    raw_payload JSONB NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Master Entity Record table
CREATE TABLE master_entity_records (
    mer_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    version INTEGER NOT NULL DEFAULT 1,
    computed_ts TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Core attributes
    legal_name VARCHAR(500),
    legal_name_local VARCHAR(500),
    trading_name VARCHAR(500),
    legal_form VARCHAR(100),
    incorporation_date DATE,
    incorporation_jurisdiction_id UUID REFERENCES jurisdictions(jurisdiction_id),
    registration_number VARCHAR(100),
    tax_id VARCHAR(100),
    lei VARCHAR(20),
    status_code VARCHAR(50),

    -- Address (composite stored as JSON for flexibility)
    registered_address JSONB,
    business_address JSONB,

    -- Metadata
    dq_score DECIMAL(5,2),

    -- Lineage tracking (which record contributed each attribute)
    attribute_sources JSONB,

    -- Locks
    locked_attributes JSONB DEFAULT '[]'::JSONB,

    created_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(entity_id, version)
);

-- MER History (for bi-temporal queries)
CREATE TABLE mer_history (
    history_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    mer_id UUID NOT NULL,
    entity_id UUID NOT NULL,
    version INTEGER NOT NULL,
    valid_from TIMESTAMPTZ NOT NULL,
    valid_to TIMESTAMPTZ,
    data JSONB NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tasks table
CREATE TABLE tasks (
    task_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_type task_type NOT NULL,
    entity_id UUID REFERENCES legal_entities(entity_id),
    record_id UUID REFERENCES registry_records(record_id),
    priority INTEGER DEFAULT 5,
    status task_status DEFAULT 'PENDING',
    assigned_to UUID,
    due_ts TIMESTAMPTZ,
    sla_breach_ts TIMESTAMPTZ,
    context JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

-- Match Candidates table
CREATE TABLE match_candidates (
    candidate_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    source_record_id UUID NOT NULL REFERENCES registry_records(record_id),
    target_entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    score DECIMAL(5,2) NOT NULL,
    match_details JSONB,
    status task_status DEFAULT 'PENDING',
    reviewer_id UUID,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Match Decisions table
CREATE TABLE match_decisions (
    decision_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    candidate_id UUID REFERENCES match_candidates(candidate_id),
    source_record_id UUID REFERENCES registry_records(record_id),
    target_entity_id UUID REFERENCES legal_entities(entity_id),
    decision match_decision_type NOT NULL,
    decided_by UUID,
    decided_ts TIMESTAMPTZ DEFAULT NOW(),
    reason TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Negative Matches table
CREATE TABLE negative_matches (
    block_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entity_a_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    entity_b_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    created_by UUID,
    reason TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT different_entities CHECK (entity_a_id != entity_b_id),
    UNIQUE(entity_a_id, entity_b_id)
);

-- DQ Rules table
CREATE TABLE dq_rules (
    rule_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(200) NOT NULL,
    description TEXT,
    category dq_category NOT NULL,
    condition JSONB NOT NULL,
    severity quality_flag NOT NULL,
    auto_remediate BOOLEAN DEFAULT FALSE,
    remediation_action JSONB,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- DQ Issues table
CREATE TABLE dq_issues (
    issue_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entity_id UUID REFERENCES legal_entities(entity_id),
    record_id UUID REFERENCES registry_records(record_id),
    rule_id UUID REFERENCES dq_rules(rule_id),
    category dq_category NOT NULL,
    severity quality_flag NOT NULL,
    status task_status DEFAULT 'PENDING',
    details JSONB,
    detected_ts TIMESTAMPTZ DEFAULT NOW(),
    resolved_ts TIMESTAMPTZ,
    resolved_by UUID,
    resolution_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Documents table
CREATE TABLE documents (
    doc_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entity_id UUID REFERENCES legal_entities(entity_id),
    record_id UUID REFERENCES registry_records(record_id),
    filename VARCHAR(500) NOT NULL,
    mime_type VARCHAR(100) NOT NULL,
    file_size_bytes BIGINT,
    storage_uri VARCHAR(1000) NOT NULL,
    checksum VARCHAR(64),
    uploaded_by UUID,
    uploaded_ts TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- OCR Results table
CREATE TABLE ocr_results (
    ocr_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    doc_id UUID NOT NULL REFERENCES documents(doc_id),
    extracted_data JSONB,
    confidence_scores JSONB,
    processing_time_ms INTEGER,
    ocr_engine VARCHAR(50),
    status VARCHAR(50) DEFAULT 'COMPLETED',
    error_message TEXT,
    reviewed_by UUID,
    reviewed_ts TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Entity Events table
CREATE TABLE entity_events (
    event_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    event_type entity_event_type NOT NULL,
    event_date DATE,
    details JSONB,
    source_id UUID REFERENCES registry_sources(source_id),
    source_record_id UUID REFERENCES registry_records(record_id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Entity Relationships table
CREATE TABLE entity_relationships (
    rel_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    parent_entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    child_entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    relationship_type relationship_type NOT NULL,
    ownership_percentage DECIMAL(5,2),
    valid_from DATE,
    valid_to DATE,
    source_id UUID REFERENCES registry_sources(source_id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT different_entities CHECK (parent_entity_id != child_entity_id)
);

-- Configuration Versions table
CREATE TABLE config_versions (
    version_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    config_type VARCHAR(50) NOT NULL,
    config_key VARCHAR(200) NOT NULL,
    config_data JSONB NOT NULL,
    is_active BOOLEAN DEFAULT FALSE,
    created_by UUID,
    approved_by UUID,
    approved_ts TIMESTAMPTZ,
    promoted_ts TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(config_type, config_key, version_id)
);

-- Audit Events table
CREATE TABLE audit_events (
    event_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_type VARCHAR(100) NOT NULL,
    actor_id UUID,
    actor_type VARCHAR(50), -- 'USER', 'SYSTEM', 'API'
    entity_type VARCHAR(100),
    entity_id UUID,
    before_state JSONB,
    after_state JSONB,
    ip_address VARCHAR(45),
    user_agent TEXT,
    event_ts TIMESTAMPTZ DEFAULT NOW()
);

-- Alerts table
CREATE TABLE alerts (
    alert_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    alert_type VARCHAR(100) NOT NULL,
    severity alert_severity NOT NULL,
    source_id UUID REFERENCES registry_sources(source_id),
    title VARCHAR(500) NOT NULL,
    message TEXT,
    context JSONB,
    acknowledged_by UUID,
    acknowledged_ts TIMESTAMPTZ,
    resolved_ts TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Ingestion Jobs table
CREATE TABLE ingestion_jobs (
    job_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    source_id UUID REFERENCES registry_sources(source_id),
    job_type VARCHAR(50) NOT NULL, -- 'FULL', 'DELTA', 'SINGLE'
    status VARCHAR(50) DEFAULT 'PENDING',
    started_ts TIMESTAMPTZ,
    completed_ts TIMESTAMPTZ,
    records_processed INTEGER DEFAULT 0,
    records_created INTEGER DEFAULT 0,
    records_updated INTEGER DEFAULT 0,
    errors INTEGER DEFAULT 0,
    error_details JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Users table (for auth)
CREATE TABLE users (
    user_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255),
    google_id VARCHAR(255),
    name VARCHAR(255),
    role VARCHAR(50) DEFAULT 'VIEWER',
    jurisdictions JSONB DEFAULT '[]'::JSONB,
    is_active BOOLEAN DEFAULT TRUE,
    last_login_ts TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Sessions table
CREATE TABLE sessions (
    session_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id),
    token_hash VARCHAR(255) NOT NULL,
    ip_address VARCHAR(45),
    user_agent TEXT,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- API Consumers table
CREATE TABLE api_consumers (
    consumer_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    api_key_hash VARCHAR(255) NOT NULL UNIQUE,
    rate_limit INTEGER DEFAULT 100,
    is_enabled BOOLEAN DEFAULT TRUE,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Snapshots table
CREATE TABLE snapshots (
    snapshot_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    as_of_ts TIMESTAMPTZ NOT NULL,
    data JSONB NOT NULL,
    checksum VARCHAR(64) NOT NULL,
    signature TEXT,
    generated_by UUID,
    generated_ts TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_legal_entities_status ON legal_entities(status);
CREATE INDEX idx_legal_entities_merged_into ON legal_entities(merged_into_id) WHERE merged_into_id IS NOT NULL;
CREATE INDEX idx_registry_records_entity ON registry_records(entity_id);
CREATE INDEX idx_registry_records_source ON registry_records(source_id);
CREATE INDEX idx_registry_records_ingestion ON registry_records(ingestion_ts);
CREATE INDEX idx_registry_records_stale ON registry_records(stale_flag) WHERE stale_flag = TRUE;
CREATE INDEX idx_mer_entity ON master_entity_records(entity_id);
CREATE INDEX idx_mer_version ON master_entity_records(entity_id, version);
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_assigned ON tasks(assigned_to) WHERE assigned_to IS NOT NULL;
CREATE INDEX idx_tasks_due ON tasks(due_ts) WHERE status IN ('PENDING', 'IN_PROGRESS');
CREATE INDEX idx_match_candidates_status ON match_candidates(status);
CREATE INDEX idx_dq_issues_status ON dq_issues(status);
CREATE INDEX idx_dq_issues_entity ON dq_issues(entity_id);
CREATE INDEX idx_audit_events_entity ON audit_events(entity_id);
CREATE INDEX idx_audit_events_ts ON audit_events(event_ts);
CREATE INDEX idx_alerts_severity ON alerts(severity) WHERE acknowledged_ts IS NULL;
CREATE INDEX idx_ingestion_jobs_source ON ingestion_jobs(source_id);
CREATE INDEX idx_users_email ON users(email);

-- Triggers for updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_legal_entities_updated
    BEFORE UPDATE ON legal_entities
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER tr_registry_sources_updated
    BEFORE UPDATE ON registry_sources
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER tr_tasks_updated
    BEFORE UPDATE ON tasks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER tr_match_candidates_updated
    BEFORE UPDATE ON match_candidates
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER tr_dq_rules_updated
    BEFORE UPDATE ON dq_rules
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER tr_users_updated
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Seed data: Jurisdictions
INSERT INTO jurisdictions (iso_alpha2, iso_alpha3, name, level) VALUES
('GL', 'GLB', 'Global', 'SUPRANATIONAL'),
('EU', 'EUR', 'European Union', 'SUPRANATIONAL'),
('AU', 'AUS', 'Australia', 'COUNTRY'),
('BA', 'BIH', 'Bosnia and Herzegovina', 'COUNTRY'),
('CY', 'CYP', 'Cyprus', 'COUNTRY'),
('CZ', 'CZE', 'Czech Republic', 'COUNTRY'),
('DE', 'DEU', 'Germany', 'COUNTRY'),
('DK', 'DNK', 'Denmark', 'COUNTRY'),
('GB', 'GBR', 'United Kingdom', 'COUNTRY'),
('IE', 'IRL', 'Ireland', 'COUNTRY'),
('JP', 'JPN', 'Japan', 'COUNTRY'),
('KR', 'KOR', 'South Korea', 'COUNTRY'),
('NO', 'NOR', 'Norway', 'COUNTRY'),
('PL', 'POL', 'Poland', 'COUNTRY'),
('US', 'USA', 'United States', 'COUNTRY');

-- Seed data: Registry Sources (MVP 15)
INSERT INTO registry_sources (source_code, source_name, jurisdiction_id, registry_type, api_available, api_type, priority_rank, identifier_regex, notes) VALUES
('GLEIF', 'Global Legal Entity Identifier Foundation', (SELECT jurisdiction_id FROM jurisdictions WHERE iso_alpha2 = 'GL'), 'FI', TRUE, 'REST', 1, '^[A-Z0-9]{20}$', 'LEI - Free REST API, 3x daily updates'),
('AU_ABR', 'Australian Business Register', (SELECT jurisdiction_id FROM jurisdictions WHERE iso_alpha2 = 'AU'), 'BUSINESS', TRUE, 'SOAP', 2, '^\d{11}$', 'ABN - Free SOAP web services'),
('BA_MBS', 'Bosnia Business Register', (SELECT jurisdiction_id FROM jurisdictions WHERE iso_alpha2 = 'BA'), 'BUSINESS', TRUE, 'REST', 2, NULL, 'MBS - Open Data portal'),
('CY_COMPANIES', 'Cyprus Companies Registry', (SELECT jurisdiction_id FROM jurisdictions WHERE iso_alpha2 = 'CY'), 'BUSINESS', TRUE, 'REST', 2, NULL, 'Open Data Portal'),
('CY_CBC', 'Central Bank of Cyprus FI List', (SELECT jurisdiction_id FROM jurisdictions WHERE iso_alpha2 = 'CY'), 'FI', TRUE, 'FILE', 3, NULL, 'Excel/CSV download'),
('CZ_ICO', 'Czech Business Register (ARES)', (SELECT jurisdiction_id FROM jurisdictions WHERE iso_alpha2 = 'CZ'), 'BUSINESS', TRUE, 'REST', 2, '^\d{8}$', 'ICO - PRIS REST API'),
('DE_DESTATIS', 'Germany Public Sector ID', (SELECT jurisdiction_id FROM jurisdictions WHERE iso_alpha2 = 'DE'), 'BUSINESS', TRUE, 'REST', 2, NULL, 'GENESIS-Online API'),
('DK_CVR', 'Denmark Central Business Register', (SELECT jurisdiction_id FROM jurisdictions WHERE iso_alpha2 = 'DK'), 'BUSINESS', TRUE, 'REST', 2, '^\d{8}$', 'CVR - Elasticsearch API'),
('GB_CH', 'UK Companies House', (SELECT jurisdiction_id FROM jurisdictions WHERE iso_alpha2 = 'GB'), 'BUSINESS', TRUE, 'REST', 2, '^([0-9]{8}|[A-Z]{2}[0-9]{6})$', 'CRN - Free REST API'),
('IE_CRO', 'Ireland Companies Registration Office', (SELECT jurisdiction_id FROM jurisdictions WHERE iso_alpha2 = 'IE'), 'BUSINESS', TRUE, 'REST', 2, NULL, 'Open Data API'),
('JP_NTA', 'Japan National Tax Agency', (SELECT jurisdiction_id FROM jurisdictions WHERE iso_alpha2 = 'JP'), 'BUSINESS', TRUE, 'REST', 2, '^\d{13}$', 'Corporate Number API'),
('KR_NTS', 'Korea National Tax Service', (SELECT jurisdiction_id FROM jurisdictions WHERE iso_alpha2 = 'KR'), 'BUSINESS', TRUE, 'REST', 2, '^\d{3}-\d{2}-\d{5}$', 'Business Registration TIN'),
('NO_BRREG', 'Norway Brønnøysund Register Centre', (SELECT jurisdiction_id FROM jurisdictions WHERE iso_alpha2 = 'NO'), 'BUSINESS', TRUE, 'REST', 2, '^\d{9}$', 'Org No - Extensive open APIs'),
('PL_KRS', 'Poland National Court Register', (SELECT jurisdiction_id FROM jurisdictions WHERE iso_alpha2 = 'PL'), 'BUSINESS', TRUE, 'REST', 2, '^\d{10}$', 'KRS - Open Data portal'),
('US_SEC', 'USA SEC EDGAR', (SELECT jurisdiction_id FROM jurisdictions WHERE iso_alpha2 = 'US'), 'BUSINESS', TRUE, 'REST', 2, '^\d{10}$', 'CIK - Free REST API');

-- Seed data: Default DQ Rules
INSERT INTO dq_rules (name, description, category, condition, severity, auto_remediate) VALUES
('Legal Name Required', 'Legal entity must have a legal name', 'COMPLETENESS', '{"field": "legal_name", "operator": "not_null"}', 'CRITICAL', FALSE),
('Registration Number Required', 'Legal entity must have a registration number', 'COMPLETENESS', '{"field": "registration_number", "operator": "not_null"}', 'CRITICAL', FALSE),
('Jurisdiction Required', 'Legal entity must have a jurisdiction', 'COMPLETENESS', '{"field": "incorporation_jurisdiction_id", "operator": "not_null"}', 'CRITICAL', FALSE),
('LEI Format Validation', 'LEI must be 20 alphanumeric characters', 'FORMAT', '{"field": "lei", "operator": "regex", "value": "^[A-Z0-9]{20}$"}', 'WARNING', FALSE),
('Incorporation Date Valid', 'Incorporation date must not be in the future', 'CONSISTENCY', '{"field": "incorporation_date", "operator": "lte", "value": "NOW()"}', 'CRITICAL', FALSE);

-- Seed data: Default admin user (password: admin123 - bcrypt hash)
INSERT INTO users (email, password_hash, name, role) VALUES
('admin@grip.local', '$2b$10$rQZ5OJr.wSj5qv5q5q5q5.5q5q5q5q5q5q5q5q5q5q5q5q5q5q5q5q', 'Admin User', 'ADMIN');

COMMIT;
