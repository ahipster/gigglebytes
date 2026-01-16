# GRIP v2.0 - Comprehensive Implementation Plan (Solo Developer)

## Document Control
| Version | Date | Status |
|---------|------|--------|
| 3.0-SOLO | 2025-01-16 | Final |

## Implementation Context

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| Team Size | 1 Solo Developer | Cost-effective, full ownership |
| Local Dev | Docker Compose | All dependencies containerized, no external services |
| UI Prototyping | HTML/Tailwind Static | Fast iteration, stakeholder validation before code |
| OCR | Tesseract.js | Open-source, runs locally, no cloud dependency |
| Registry Adapters | Stubs First | Enable full E2E testing without external APIs |
| Testing | TDD from Day 1 | Higher quality, fewer regressions |
| Auth | JWT + Google OAuth (switchable) | Simple dev, easy prod migration |
| Deployment | GCP (Cloud Run + GKE) | Aligns with GCP Buckets |
| MVP Registries | 15 free, no-login sources | Per Section F scope |

---

# PHASE 0: PROJECT FOUNDATION (Weeks 1-2)

## Objective
Set up complete local development environment with zero external dependencies.

---

## Week 1: Repository & Docker Infrastructure

### Day 1-2: Repository Setup

**Task 0.1.1: Create Monorepo Structure**

```
grip/
├── .github/
│   └── workflows/
│       ├── ci.yml
│       └── deploy.yml
├── docker/
│   ├── docker-compose.yml
│   ├── docker-compose.dev.yml
│   ├── postgres/
│   │   └── init.sql
│   ├── redis/
│   │   └── redis.conf
│   └── kafka/
│       └── server.properties
├── packages/
│   ├── app/                    # Next.js full-stack (API + UI)
│   │   ├── src/
│   │   ├── tests/
│   │   ├── package.json
│   │   └── tsconfig.json
│   ├── shared/                 # Shared types/utils
│   │   ├── src/
│   │   └── package.json
│   └── adapters/               # Registry adapters
│       ├── src/
│       ├── stubs/
│       └── package.json
├── mockups/                    # HTML/Tailwind mockups
│   ├── index.html
│   ├── pages/
│   └── components/
├── docs/
│   ├── architecture/
│   ├── api/
│   └── decisions/
├── scripts/
│   ├── setup.sh
│   ├── seed.sh
│   └── reset.sh
├── .env.example
├── .gitignore
├── package.json               # Root workspace
├── pnpm-workspace.yaml
└── README.md
```

**Acceptance Criteria:**
- [ ] Repository created with above structure
- [ ] `.gitignore` covers node_modules, .env, docker volumes
- [ ] `pnpm-workspace.yaml` configured for monorepo
- [ ] Root `package.json` with workspace scripts
- [ ] README with setup instructions

**Deliverable:** Commit `feat: initial repository structure`

---

### Day 2-3: Docker Compose Configuration

**Task 0.1.2: Create docker-compose.yml**

```yaml
# docker/docker-compose.yml
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    container_name: grip-postgres
    environment:
      POSTGRES_USER: grip
      POSTGRES_PASSWORD: grip_dev_password
      POSTGRES_DB: grip
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./postgres/init.sql:/docker-entrypoint-initdb.d/init.sql
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U grip"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    container_name: grip-redis
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  kafka:
    image: confluentinc/cp-kafka:7.5.0
    container_name: grip-kafka
    depends_on:
      - zookeeper
    ports:
      - "9092:9092"
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://localhost:9092
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
    healthcheck:
      test: ["CMD", "kafka-topics", "--bootstrap-server", "localhost:9092", "--list"]
      interval: 30s
      timeout: 10s
      retries: 5

  zookeeper:
    image: confluentinc/cp-zookeeper:7.5.0
    container_name: grip-zookeeper
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
    ports:
      - "2181:2181"

  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.11.0
    container_name: grip-elasticsearch
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    ports:
      - "9200:9200"
    volumes:
      - es_data:/usr/share/elasticsearch/data
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:9200/_cluster/health || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 5

  neo4j:
    image: neo4j:5.15-community
    container_name: grip-neo4j
    environment:
      NEO4J_AUTH: neo4j/grip_dev_password
    ports:
      - "7474:7474"
      - "7687:7687"
    volumes:
      - neo4j_data:/data
    healthcheck:
      test: ["CMD", "neo4j", "status"]
      interval: 30s
      timeout: 10s
      retries: 5

  mailhog:
    image: mailhog/mailhog
    container_name: grip-mailhog
    ports:
      - "1025:1025"  # SMTP
      - "8025:8025"  # Web UI

volumes:
  postgres_data:
  redis_data:
  es_data:
  neo4j_data:
```

**Acceptance Criteria:**
- [ ] `docker-compose up -d` starts all services
- [ ] All healthchecks pass within 2 minutes
- [ ] Postgres accessible at localhost:5432
- [ ] Redis accessible at localhost:6379
- [ ] Kafka accessible at localhost:9092
- [ ] Elasticsearch accessible at localhost:9200
- [ ] Neo4j Browser at localhost:7474
- [ ] Mailhog UI at localhost:8025

**Test Command:**
```bash
docker-compose up -d
docker-compose ps  # All should be "healthy"
```

**Deliverable:** Commit `feat: docker-compose local dev environment`

---

### Day 3-4: Database Schema (Core Tables)

**Task 0.1.3: Create Initial PostgreSQL Schema**

File: `docker/postgres/init.sql`

```sql
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
    -- No updated_at: records are immutable
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
```

**Acceptance Criteria:**
- [ ] Schema creates without errors
- [ ] All tables exist with correct columns
- [ ] Enums created correctly
- [ ] Seed data inserted (15 jurisdictions, 15 sources, 5 DQ rules, 1 admin user)
- [ ] Indexes created
- [ ] Triggers working

**Test:**
```bash
docker-compose down -v  # Reset
docker-compose up -d postgres
docker exec grip-postgres psql -U grip -d grip -c "\dt"  # List tables
docker exec grip-postgres psql -U grip -d grip -c "SELECT count(*) FROM registry_sources;"  # Should be 15
```

**Deliverable:** Commit `feat: initial database schema with seed data`

---

### Day 4-5: Setup Scripts & Environment Config

**Task 0.1.4: Create Setup Scripts**

File: `scripts/setup.sh`
```bash
#!/bin/bash
set -e

echo "=== GRIP Development Environment Setup ==="

# Check prerequisites
command -v docker >/dev/null 2>&1 || { echo "Docker required but not installed. Aborting."; exit 1; }
command -v node >/dev/null 2>&1 || { echo "Node.js required but not installed. Aborting."; exit 1; }
command -v pnpm >/dev/null 2>&1 || { echo "Installing pnpm..."; npm install -g pnpm; }

# Create .env from example if not exists
if [ ! -f .env ]; then
    cp .env.example .env
    echo "Created .env from .env.example"
fi

# Start Docker services
echo "Starting Docker services..."
docker-compose -f docker/docker-compose.yml up -d

# Wait for services to be healthy
echo "Waiting for services to be ready..."
sleep 10

# Check service health
docker-compose -f docker/docker-compose.yml ps

# Install dependencies
echo "Installing Node.js dependencies..."
pnpm install

echo ""
echo "=== Setup Complete ==="
echo "Services running at:"
echo "  - PostgreSQL: localhost:5432"
echo "  - Redis: localhost:6379"
echo "  - Kafka: localhost:9092"
echo "  - Elasticsearch: localhost:9200"
echo "  - Neo4j: localhost:7474"
echo "  - Mailhog: localhost:8025"
echo ""
echo "Next: Run 'pnpm dev' to start the development servers"
```

File: `scripts/reset.sh`
```bash
#!/bin/bash
set -e

echo "=== Resetting GRIP Development Environment ==="

# Stop containers
docker-compose -f docker/docker-compose.yml down -v

# Remove node_modules
rm -rf node_modules packages/*/node_modules

# Start fresh
./scripts/setup.sh
```

File: `.env.example`
```env
# Application
NODE_ENV=development
PORT=3000
API_URL=http://localhost:3000

# Database
DATABASE_URL=postgresql://grip:grip_dev_password@localhost:5432/grip

# Redis
REDIS_URL=redis://localhost:6379

# Kafka
KAFKA_BROKERS=localhost:9092

# Elasticsearch
ELASTICSEARCH_URL=http://localhost:9200

# Neo4j
NEO4J_URL=bolt://localhost:7687
NEO4J_USER=neo4j
NEO4J_PASSWORD=grip_dev_password

# Auth
JWT_SECRET=your-super-secret-jwt-key-change-in-production
JWT_EXPIRES_IN=7d
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=

# OCR (Tesseract)
TESSERACT_LANG=eng

# Storage (local for dev, GCP for prod)
STORAGE_TYPE=local
STORAGE_LOCAL_PATH=./storage
GCP_BUCKET_NAME=
GCP_PROJECT_ID=

# Mail (Mailhog for dev)
SMTP_HOST=localhost
SMTP_PORT=1025
SMTP_FROM=noreply@grip.local
```

**Acceptance Criteria:**
- [ ] `./scripts/setup.sh` runs without errors
- [ ] `./scripts/reset.sh` cleans and restarts everything
- [ ] `.env` file created from example
- [ ] All Docker services start and become healthy

**Deliverable:** Commit `feat: setup scripts and environment configuration`

---

## Week 2: Next.js Full-Stack Scaffolding & CI/CD

### Day 6-7: Full-Stack Package Structure

**Task 0.2.1: Create Full-Stack Package with Next.js**

```bash
cd packages/app
pnpm create next-app@latest . --typescript --tailwind --eslint
pnpm add @prisma/client bcrypt jsonwebtoken uuid
pnpm add -D prisma @types/bcrypt @types/jsonwebtoken
```

Directory structure:
```
packages/app/
├── app/
│   ├── layout.tsx
│   ├── page.tsx
│   ├── api/
│   │   ├── auth/
│   │   │   ├── register/route.ts
│   │   │   ├── login/route.ts
│   │   │   └── logout/route.ts
│   │   ├── entities/
│   │   │   ├── route.ts
│   │   │   └── [id]/route.ts
│   │   ├── records/
│   │   ├── sources/
│   │   ├── tasks/
│   │   └── health/route.ts
│   └── (pages)/
│       ├── dashboard/
│       ├── entities/
│       └── settings/
├── components/
│   ├── ui/
│   └── features/
├── lib/
│   ├── auth.ts
│   ├── db.ts
│   └── api-client.ts
├── public/
├── prisma/
│   └── schema.prisma
├── tests/
│   ├── e2e/
│   └── unit/
├── tsconfig.json
├── next.config.js
├── jest.config.js
└── package.json
```

**Acceptance Criteria:**
- [ ] `pnpm build` compiles without errors
- [ ] `pnpm test` runs (even if no tests yet)
- [ ] `pnpm dev` starts server on port 3000
- [ ] Health endpoint at GET /api/health returns 200
- [ ] Home page renders at http://localhost:3000

**Deliverable:** Commit `feat: Next.js full-stack scaffolding`

---

### Day 8-9: CI/CD Pipeline

**Task 0.2.2: Create GitHub Actions Workflows**

File: `.github/workflows/ci.yml`
```yaml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v2
        with:
          version: 8
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'pnpm'
      - run: pnpm install
      - run: pnpm lint

  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:15-alpine
        env:
          POSTGRES_USER: grip
          POSTGRES_PASSWORD: grip_test
          POSTGRES_DB: grip_test
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
      redis:
        image: redis:7-alpine
        ports:
          - 6379:6379
      kafka:
        image: confluentinc/cp-kafka:7.5.0
        ports:
          - 9092:9092
        options: >-
          --health-cmd "bash -lc 'kafka-topics --bootstrap-server localhost:9092 --list || exit 1'"
          --health-interval 30s
          --health-timeout 10s
          --health-retries 5
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v2
        with:
          version: 8
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'pnpm'
      - run: pnpm install
      - run: pnpm test:ci
        env:
          DATABASE_URL: postgresql://grip:grip_test@localhost:5432/grip_test
          REDIS_URL: redis://localhost:6379

  build:
    runs-on: ubuntu-latest
    needs: [lint, test]
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v2
        with:
          version: 8
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'pnpm'
      - run: pnpm install
      - run: pnpm build
      - name: Build Docker image
        run: |
          # Build a container image for deployment/packaging
          docker build -t ghcr.io/${{ github.repository }}/grip:latest .
```

**Acceptance Criteria:**
- [ ] CI workflow triggers on push/PR
- [ ] Lint job passes
- [ ] Test job passes with service containers
- [ ] Build job produces artifacts

**Deliverable:** Commit `ci: GitHub Actions workflow`

---

### Day 10: Documentation & README

**Task 0.2.3: Write Developer Documentation**

File: `README.md`
```markdown
# GRIP - Global Registry Intelligence Platform

## Quick Start

### Prerequisites
- Docker Desktop
- Node.js 20+
- pnpm 8+

### Setup
\`\`\`bash
git clone <repo>
cd grip
./scripts/setup.sh
\`\`\`

### Development
\`\`\`bash
pnpm dev          # Start all services
pnpm test         # Run tests
pnpm lint         # Lint code
pnpm build        # Build for production
\`\`\`

### Services
| Service | URL | Credentials |
|---------|-----|-------------|
| API | http://localhost:3000 | - |
| Swagger | http://localhost:3000/api | - |
| PostgreSQL | localhost:5432 | grip/grip_dev_password |
| Neo4j Browser | http://localhost:7474 | neo4j/grip_dev_password |
| Mailhog | http://localhost:8025 | - |
| Elasticsearch | http://localhost:9200 | - |

### Architecture
See [docs/architecture/](docs/architecture/)

### API Documentation
See [docs/api/](docs/api/) or Swagger UI at /api
```

**Deliverable:** Commit `docs: README and developer documentation`

---

## Phase 0 Exit Criteria

- [ ] Repository structure complete
- [ ] Docker Compose starts all services (Postgres, Redis, Kafka, ES, Neo4j, Mailhog)
- [ ] Database schema deployed with seed data
- [ ] API scaffolding compiles and runs
- [ ] Health endpoint responds
- [ ] CI pipeline passes
- [ ] README complete with setup instructions

---

# PHASE 1: UI MOCKUPS & VALIDATION (Weeks 3-5)

## Objective
Build complete HTML/Tailwind static mockups of ALL UI screens before writing any frontend code. This enables stakeholder validation and UX iteration without code changes.

---

## Week 3: Core Screen Mockups

### Task 1.1: Mockup Infrastructure

File: `mockups/index.html`
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>GRIP - UI Mockups</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script>
        tailwind.config = {
            theme: {
                extend: {
                    colors: {
                        primary: '#2563eb',
                        secondary: '#64748b',
                        success: '#22c55e',
                        warning: '#f59e0b',
                        danger: '#ef4444',
                    }
                }
            }
        }
    </script>
    <style>
        .sidebar { width: 250px; }
        .main-content { margin-left: 250px; }
    </style>
</head>
<body class="bg-gray-100">
    <!-- Navigation Index -->
    <div class="max-w-4xl mx-auto py-8">
        <h1 class="text-3xl font-bold mb-8">GRIP UI Mockups</h1>

        <div class="grid grid-cols-2 gap-6">
            <!-- Core Screens -->
            <div class="bg-white p-6 rounded-lg shadow">
                <h2 class="text-xl font-semibold mb-4">Core Screens</h2>
                <ul class="space-y-2">
                    <li><a href="pages/login.html" class="text-primary hover:underline">Login</a></li>
                    <li><a href="pages/dashboard.html" class="text-primary hover:underline">Dashboard</a></li>
                    <li><a href="pages/entity-search.html" class="text-primary hover:underline">Entity Search</a></li>
                    <li><a href="pages/entity-detail.html" class="text-primary hover:underline">Entity Detail</a></li>
                    <li><a href="pages/entity-establish.html" class="text-primary hover:underline">Entity Establish</a></li>
                </ul>
            </div>

            <!-- Operations -->
            <div class="bg-white p-6 rounded-lg shadow">
                <h2 class="text-xl font-semibold mb-4">Operations</h2>
                <ul class="space-y-2">
                    <li><a href="pages/task-queue.html" class="text-primary hover:underline">Task Queue</a></li>
                    <li><a href="pages/er-review.html" class="text-primary hover:underline">ER Review</a></li>
                    <li><a href="pages/manual-entry.html" class="text-primary hover:underline">Manual Entry / OCR</a></li>
                    <li><a href="pages/dq-dashboard.html" class="text-primary hover:underline">DQ Dashboard</a></li>
                </ul>
            </div>

            <!-- Configuration -->
            <div class="bg-white p-6 rounded-lg shadow">
                <h2 class="text-xl font-semibold mb-4">Configuration</h2>
                <ul class="space-y-2">
                    <li><a href="pages/source-health.html" class="text-primary hover:underline">Source Health</a></li>
                    <li><a href="pages/mapping-studio.html" class="text-primary hover:underline">Mapping Studio</a></li>
                    <li><a href="pages/survivorship-rules.html" class="text-primary hover:underline">Survivorship Rules</a></li>
                    <li><a href="pages/er-rules.html" class="text-primary hover:underline">ER Rules</a></li>
                    <li><a href="pages/dq-rules.html" class="text-primary hover:underline">DQ Rules</a></li>
                </ul>
            </div>

            <!-- Admin -->
            <div class="bg-white p-6 rounded-lg shadow">
                <h2 class="text-xl font-semibold mb-4">Admin & Audit</h2>
                <ul class="space-y-2">
                    <li><a href="pages/user-management.html" class="text-primary hover:underline">User Management</a></li>
                    <li><a href="pages/audit-log.html" class="text-primary hover:underline">Audit Log</a></li>
                    <li><a href="pages/lineage-view.html" class="text-primary hover:underline">Lineage View</a></li>
                    <li><a href="pages/snapshot-export.html" class="text-primary hover:underline">Snapshot Export</a></li>
                </ul>
            </div>
        </div>

        <!-- Component Library -->
        <div class="mt-8 bg-white p-6 rounded-lg shadow">
            <h2 class="text-xl font-semibold mb-4">Component Library</h2>
            <ul class="grid grid-cols-4 gap-4">
                <li><a href="components/buttons.html" class="text-primary hover:underline">Buttons</a></li>
                <li><a href="components/forms.html" class="text-primary hover:underline">Forms</a></li>
                <li><a href="components/tables.html" class="text-primary hover:underline">Tables</a></li>
                <li><a href="components/cards.html" class="text-primary hover:underline">Cards</a></li>
                <li><a href="components/modals.html" class="text-primary hover:underline">Modals</a></li>
                <li><a href="components/alerts.html" class="text-primary hover:underline">Alerts</a></li>
                <li><a href="components/badges.html" class="text-primary hover:underline">Badges</a></li>
                <li><a href="components/navigation.html" class="text-primary hover:underline">Navigation</a></li>
            </ul>
        </div>
    </div>
</body>
</html>
```

---

### Task 1.2: Dashboard Mockup

File: `mockups/pages/dashboard.html`
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard - GRIP</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100">
    <!-- Sidebar -->
    <aside class="fixed left-0 top-0 h-full w-64 bg-gray-900 text-white">
        <div class="p-4 border-b border-gray-700">
            <h1 class="text-xl font-bold">GRIP</h1>
            <p class="text-sm text-gray-400">Registry Intelligence</p>
        </div>
        <nav class="p-4">
            <ul class="space-y-2">
                <li>
                    <a href="dashboard.html" class="flex items-center p-2 bg-gray-800 rounded">
                        <span class="mr-3">📊</span> Dashboard
                    </a>
                </li>
                <li>
                    <a href="entity-search.html" class="flex items-center p-2 hover:bg-gray-800 rounded">
                        <span class="mr-3">🔍</span> Entity Search
                    </a>
                </li>
                <li>
                    <a href="task-queue.html" class="flex items-center p-2 hover:bg-gray-800 rounded">
                        <span class="mr-3">📋</span> Task Queue
                        <span class="ml-auto bg-red-500 text-xs px-2 py-1 rounded-full">12</span>
                    </a>
                </li>
                <li>
                    <a href="source-health.html" class="flex items-center p-2 hover:bg-gray-800 rounded">
                        <span class="mr-3">💚</span> Source Health
                    </a>
                </li>
                <li class="pt-4 border-t border-gray-700 mt-4">
                    <span class="text-xs text-gray-500 uppercase">Configuration</span>
                </li>
                <li>
                    <a href="mapping-studio.html" class="flex items-center p-2 hover:bg-gray-800 rounded">
                        <span class="mr-3">🗺️</span> Mapping Studio
                    </a>
                </li>
                <li>
                    <a href="survivorship-rules.html" class="flex items-center p-2 hover:bg-gray-800 rounded">
                        <span class="mr-3">⚖️</span> Survivorship Rules
                    </a>
                </li>
                <li>
                    <a href="er-rules.html" class="flex items-center p-2 hover:bg-gray-800 rounded">
                        <span class="mr-3">🔗</span> ER Rules
                    </a>
                </li>
                <li>
                    <a href="dq-rules.html" class="flex items-center p-2 hover:bg-gray-800 rounded">
                        <span class="mr-3">✅</span> DQ Rules
                    </a>
                </li>
            </ul>
        </nav>
        <div class="absolute bottom-0 left-0 right-0 p-4 border-t border-gray-700">
            <div class="flex items-center">
                <div class="w-8 h-8 bg-gray-600 rounded-full mr-3"></div>
                <div>
                    <p class="text-sm">Admin User</p>
                    <p class="text-xs text-gray-400">admin@grip.local</p>
                </div>
            </div>
        </div>
    </aside>

    <!-- Main Content -->
    <main class="ml-64 p-8">
        <!-- Header -->
        <div class="flex justify-between items-center mb-8">
            <div>
                <h1 class="text-2xl font-bold text-gray-900">Dashboard</h1>
                <p class="text-gray-600">Overview of your registry data</p>
            </div>
            <div class="flex items-center space-x-4">
                <span class="text-sm text-gray-500">Last updated: 5 min ago</span>
                <button class="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700">
                    Refresh
                </button>
            </div>
        </div>

        <!-- Stats Cards -->
        <div class="grid grid-cols-4 gap-6 mb-8">
            <div class="bg-white p-6 rounded-lg shadow">
                <div class="flex items-center justify-between">
                    <div>
                        <p class="text-sm text-gray-500">Total Entities</p>
                        <p class="text-3xl font-bold">12,456</p>
                    </div>
                    <div class="text-4xl">🏢</div>
                </div>
                <p class="text-sm text-green-600 mt-2">+123 this week</p>
            </div>
            <div class="bg-white p-6 rounded-lg shadow">
                <div class="flex items-center justify-between">
                    <div>
                        <p class="text-sm text-gray-500">Registry Records</p>
                        <p class="text-3xl font-bold">45,678</p>
                    </div>
                    <div class="text-4xl">📄</div>
                </div>
                <p class="text-sm text-green-600 mt-2">+456 this week</p>
            </div>
            <div class="bg-white p-6 rounded-lg shadow">
                <div class="flex items-center justify-between">
                    <div>
                        <p class="text-sm text-gray-500">Pending Tasks</p>
                        <p class="text-3xl font-bold text-orange-600">12</p>
                    </div>
                    <div class="text-4xl">📋</div>
                </div>
                <p class="text-sm text-orange-600 mt-2">3 overdue</p>
            </div>
            <div class="bg-white p-6 rounded-lg shadow">
                <div class="flex items-center justify-between">
                    <div>
                        <p class="text-sm text-gray-500">DQ Issues</p>
                        <p class="text-3xl font-bold text-red-600">8</p>
                    </div>
                    <div class="text-4xl">⚠️</div>
                </div>
                <p class="text-sm text-red-600 mt-2">2 critical</p>
            </div>
        </div>

        <!-- Two Column Layout -->
        <div class="grid grid-cols-2 gap-6 mb-8">
            <!-- Source Health -->
            <div class="bg-white p-6 rounded-lg shadow">
                <div class="flex justify-between items-center mb-4">
                    <h2 class="text-lg font-semibold">Source Health</h2>
                    <a href="source-health.html" class="text-blue-600 text-sm hover:underline">View All</a>
                </div>
                <div class="space-y-3">
                    <div class="flex items-center justify-between p-3 bg-green-50 rounded">
                        <div class="flex items-center">
                            <span class="w-3 h-3 bg-green-500 rounded-full mr-3"></span>
                            <span>GLEIF (LEI)</span>
                        </div>
                        <span class="text-sm text-gray-500">99.9%</span>
                    </div>
                    <div class="flex items-center justify-between p-3 bg-green-50 rounded">
                        <div class="flex items-center">
                            <span class="w-3 h-3 bg-green-500 rounded-full mr-3"></span>
                            <span>UK Companies House</span>
                        </div>
                        <span class="text-sm text-gray-500">99.5%</span>
                    </div>
                    <div class="flex items-center justify-between p-3 bg-yellow-50 rounded">
                        <div class="flex items-center">
                            <span class="w-3 h-3 bg-yellow-500 rounded-full mr-3"></span>
                            <span>Norway Brreg</span>
                        </div>
                        <span class="text-sm text-gray-500">94.2%</span>
                    </div>
                    <div class="flex items-center justify-between p-3 bg-gray-50 rounded">
                        <div class="flex items-center">
                            <span class="w-3 h-3 bg-gray-400 rounded-full mr-3"></span>
                            <span>Germany Handelsregister</span>
                        </div>
                        <span class="text-sm text-gray-500">Manual</span>
                    </div>
                </div>
            </div>

            <!-- Recent Tasks -->
            <div class="bg-white p-6 rounded-lg shadow">
                <div class="flex justify-between items-center mb-4">
                    <h2 class="text-lg font-semibold">Recent Tasks</h2>
                    <a href="task-queue.html" class="text-blue-600 text-sm hover:underline">View All</a>
                </div>
                <div class="space-y-3">
                    <div class="flex items-center justify-between p-3 border rounded">
                        <div>
                            <p class="font-medium">ER Review: Acme AB</p>
                            <p class="text-sm text-gray-500">Match score: 92%</p>
                        </div>
                        <span class="px-2 py-1 bg-orange-100 text-orange-800 text-xs rounded">Pending</span>
                    </div>
                    <div class="flex items-center justify-between p-3 border rounded">
                        <div>
                            <p class="font-medium">Manual Refresh: TechCorp Ltd</p>
                            <p class="text-sm text-gray-500">Stale > 365 days</p>
                        </div>
                        <span class="px-2 py-1 bg-red-100 text-red-800 text-xs rounded">Overdue</span>
                    </div>
                    <div class="flex items-center justify-between p-3 border rounded">
                        <div>
                            <p class="font-medium">DQ Fix: GlobalTech Inc</p>
                            <p class="text-sm text-gray-500">Missing registration number</p>
                        </div>
                        <span class="px-2 py-1 bg-orange-100 text-orange-800 text-xs rounded">Pending</span>
                    </div>
                </div>
            </div>
        </div>

        <!-- Ingestion Activity -->
        <div class="bg-white p-6 rounded-lg shadow">
            <div class="flex justify-between items-center mb-4">
                <h2 class="text-lg font-semibold">Ingestion Activity (Last 7 Days)</h2>
                <select class="border rounded px-3 py-1 text-sm">
                    <option>Last 7 days</option>
                    <option>Last 30 days</option>
                    <option>Last 90 days</option>
                </select>
            </div>
            <!-- Placeholder for chart -->
            <div class="h-64 bg-gray-50 rounded flex items-center justify-center text-gray-400">
                [Chart: Records ingested per day by source]
            </div>
        </div>
    </main>
</body>
</html>
```

---

### Complete Mockup List (Weeks 3-5)

| Week | Mockup | File | Status |
|------|--------|------|--------|
| 3 | Index/Navigation | `mockups/index.html` | |
| 3 | Dashboard | `mockups/pages/dashboard.html` | |
| 3 | Login | `mockups/pages/login.html` | |
| 3 | Entity Search | `mockups/pages/entity-search.html` | |
| 3 | Entity Detail (Overview) | `mockups/pages/entity-detail.html` | |
| 3 | Entity Detail (Lineage) | `mockups/pages/entity-lineage.html` | |
| 4 | Entity Establish | `mockups/pages/entity-establish.html` | |
| 4 | Task Queue | `mockups/pages/task-queue.html` | |
| 4 | ER Review | `mockups/pages/er-review.html` | |
| 4 | Manual Entry / OCR | `mockups/pages/manual-entry.html` | |
| 4 | DQ Dashboard | `mockups/pages/dq-dashboard.html` | |
| 5 | Source Health | `mockups/pages/source-health.html` | |
| 5 | Mapping Studio | `mockups/pages/mapping-studio.html` | |
| 5 | Survivorship Rules | `mockups/pages/survivorship-rules.html` | |
| 5 | ER Rules | `mockups/pages/er-rules.html` | |
| 5 | DQ Rules | `mockups/pages/dq-rules.html` | |
| 5 | Audit Log | `mockups/pages/audit-log.html` | |
| 5 | User Management | `mockups/pages/user-management.html` | |

## Phase 1 Exit Criteria

- [ ] All 18 page mockups complete
- [ ] Component library documented
- [ ] Navigation between all pages works
- [ ] Stakeholder review completed
- [ ] Feedback incorporated
- [ ] Mockups approved for implementation

### Additional mockup requirements (additions)
- Mapping Studio mock should include a static depiction of drag-and-drop field mapping between source schema (left) and canonical CDM (right), with example transformation rules shown.
- Mockups must indicate multi-entity handling flows (bulk-merge, multi-select compare) and critical navigation states.
- Verify and annotate designs for WCAG 2.1 AA accessibility (contrast, focus states, keyboard flows) in the mockups.

---

# PHASE 2: STUB ADAPTERS & MOCK DATA (Weeks 6-8)

## Objective
Build mock/stub adapters for all 15 MVP registries that return realistic fake data. This enables full E2E testing without external API dependencies.

---

## Week 6: Adapter Framework & GLEIF Stub

### Task 2.1: Create Adapter Framework

File: `packages/adapters/src/base/adapter.interface.ts`
```typescript
export interface RegistryAdapter {
  sourceCode: string;
  search(query: SearchQuery): Promise<SearchResult[]>;
  fetch(identifier: string): Promise<RegistryRecord | null>;
  healthCheck(): Promise<HealthStatus>;
}

export interface SearchQuery {
  name?: string;
  registrationNumber?: string;
  jurisdiction?: string;
  limit?: number;
}

export interface SearchResult {
  sourceCode: string;
  identifier: string;
  name: string;
  score: number;
  preview: Record<string, any>;
}

export interface RegistryRecord {
  sourceCode: string;
  identifier: string;
  fetchedAt: Date;
  rawPayload: Record<string, any>;
  parsed: ParsedEntity;
}

export interface ParsedEntity {
  legalName: string;
  legalNameLocal?: string;
  registrationNumber: string;
  status: string;
  incorporationDate?: string;
  jurisdiction: string;
  legalForm?: string;
  address?: Address;
  lei?: string;
}

export interface Address {
  line1?: string;
  line2?: string;
  city?: string;
  region?: string;
  postalCode?: string;
  country: string;
}

export interface HealthStatus {
  status: 'HEALTHY' | 'DEGRADED' | 'DOWN';
  latencyMs?: number;
  lastCheck: Date;
  message?: string;
}
```

### Task 2.2: Create GLEIF Stub Adapter

File: `packages/adapters/src/stubs/gleif.stub.ts`
```typescript
import { RegistryAdapter, SearchQuery, SearchResult, RegistryRecord, HealthStatus } from '../base/adapter.interface';
import { faker } from '@faker-js/faker';

const MOCK_ENTITIES = [
  {
    lei: '5493001KJTIIGC8Y1R12',
    legalName: 'Acme Corporation',
    jurisdiction: 'US',
    status: 'ACTIVE',
    incorporationDate: '2010-03-15',
    address: { city: 'New York', country: 'US' }
  },
  {
    lei: '549300ABC123DEF456GH',
    legalName: 'TechCorp AB',
    jurisdiction: 'SE',
    status: 'ACTIVE',
    incorporationDate: '2015-07-22',
    address: { city: 'Stockholm', country: 'SE' }
  },
  // ... more mock entities
];

export class GleifStubAdapter implements RegistryAdapter {
  sourceCode = 'GLEIF';

  async search(query: SearchQuery): Promise<SearchResult[]> {
    // Simulate network delay
    await this.delay(100 + Math.random() * 200);

    let results = MOCK_ENTITIES;

    if (query.name) {
      results = results.filter(e =>
        e.legalName.toLowerCase().includes(query.name!.toLowerCase())
      );
    }

    if (query.registrationNumber) {
      results = results.filter(e => e.lei === query.registrationNumber);
    }

    return results.slice(0, query.limit || 10).map(e => ({
      sourceCode: this.sourceCode,
      identifier: e.lei,
      name: e.legalName,
      score: 100,
      preview: { lei: e.lei, status: e.status, jurisdiction: e.jurisdiction }
    }));
  }

  async fetch(identifier: string): Promise<RegistryRecord | null> {
    await this.delay(50 + Math.random() * 100);

    const entity = MOCK_ENTITIES.find(e => e.lei === identifier);
    if (!entity) return null;

    return {
      sourceCode: this.sourceCode,
      identifier: entity.lei,
      fetchedAt: new Date(),
      rawPayload: this.generateRawPayload(entity),
      parsed: {
        legalName: entity.legalName,
        registrationNumber: entity.lei,
        status: entity.status,
        incorporationDate: entity.incorporationDate,
        jurisdiction: entity.jurisdiction,
        lei: entity.lei,
        address: entity.address as any
      }
    };
  }

  async healthCheck(): Promise<HealthStatus> {
    const latency = 50 + Math.random() * 100;
    await this.delay(latency);

    return {
      status: 'HEALTHY',
      latencyMs: Math.round(latency),
      lastCheck: new Date()
    };
  }

  private delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  private generateRawPayload(entity: any): Record<string, any> {
    // Mimics actual GLEIF API response structure
    return {
      data: [{
        type: 'lei-records',
        id: entity.lei,
        attributes: {
          lei: entity.lei,
          entity: {
            legalName: { name: entity.legalName },
            status: entity.status,
            jurisdiction: entity.jurisdiction,
            legalAddress: entity.address
          },
          registration: {
            initialRegistrationDate: entity.incorporationDate,
            status: 'ISSUED'
          }
        }
      }]
    };
  }
}
```

### Task 2.3: Create Remaining 14 Stub Adapters

Repeat similar pattern for all 15 MVP sources:

| # | Source Code | Stub File | Mock Data Focus |
|---|-------------|-----------|-----------------|
| 1 | GLEIF | `gleif.stub.ts` | LEI, global entities |
| 2 | AU_ABR | `au-abr.stub.ts` | ABN, Australian businesses |
| 3 | BA_MBS | `ba-mbs.stub.ts` | Bosnia companies |
| 4 | CY_COMPANIES | `cy-companies.stub.ts` | Cyprus companies |
| 5 | CY_CBC | `cy-cbc.stub.ts` | Cyprus FIs |
| 6 | CZ_ICO | `cz-ico.stub.ts` | Czech companies |
| 7 | DE_DESTATIS | `de-destatis.stub.ts` | German public sector |
| 8 | DK_CVR | `dk-cvr.stub.ts` | Danish companies |
| 9 | GB_CH | `gb-ch.stub.ts` | UK companies |
| 10 | IE_CRO | `ie-cro.stub.ts` | Irish companies |
| 11 | JP_NTA | `jp-nta.stub.ts` | Japanese companies |
| 12 | KR_NTS | `kr-nts.stub.ts` | Korean companies |
| 13 | NO_BRREG | `no-brreg.stub.ts` | Norwegian companies |
| 14 | PL_KRS | `pl-krs.stub.ts` | Polish companies |
| 15 | US_SEC | `us-sec.stub.ts` | US SEC filers |

### Additions (stubs)
- Emit operational metrics from stubs (simulated latency, request/response counts, error rates) for dashboard aggregation.
- Simulate rate-limits and configurable delays/errors in stubs to validate retry/backoff and error handling flows.
- Ensure an adapter factory exists to dynamically load a stub by `registry_sources.source_code` and to register adapters for runtime selection.

### Task 2.4: Seed Data Generator

File: `packages/adapters/src/stubs/seed-generator.ts`
```typescript
import { faker } from '@faker-js/faker';

export function generateMockEntity(jurisdiction: string, sourceCode: string) {
  const companyTypes = {
    SE: ['AB', 'HB', 'KB'],
    GB: ['Ltd', 'PLC', 'LLP'],
    US: ['Inc', 'LLC', 'Corp'],
    // ... more
  };

  return {
    legalName: `${faker.company.name()} ${companyTypes[jurisdiction]?.[0] || 'Ltd'}`,
    registrationNumber: generateRegistrationNumber(sourceCode),
    jurisdiction,
    status: faker.helpers.arrayElement(['ACTIVE', 'ACTIVE', 'ACTIVE', 'INACTIVE']),
    incorporationDate: faker.date.past({ years: 20 }).toISOString().split('T')[0],
    address: {
      line1: faker.location.streetAddress(),
      city: faker.location.city(),
      postalCode: faker.location.zipCode(),
      country: jurisdiction
    }
  };
}

function generateRegistrationNumber(sourceCode: string): string {
  const formats: Record<string, () => string> = {
    GLEIF: () => faker.string.alphanumeric({ length: 20, casing: 'upper' }),
    GB_CH: () => faker.string.numeric(8),
    SE_BOLAG: () => `${faker.string.numeric(6)}-${faker.string.numeric(4)}`,
    // ... more
  };

  return formats[sourceCode]?.() || faker.string.alphanumeric(10);
}
```

## Phase 2 Exit Criteria

- [ ] All 15 stub adapters implemented
- [ ] Each adapter returns realistic mock data
- [ ] Adapters implement full interface (search, fetch, healthCheck)
- [ ] 50+ mock entities per jurisdiction
- [ ] Adapter factory/registry pattern implemented
- [ ] Unit tests for all adapters

---

# PHASE 3: CORE API IMPLEMENTATION (Weeks 9-16)

## Week 9-10: Entity & Record Services

### Tasks
- ENT-001 to ENT-010: Entity CRUD operations
- REC-001 to REC-010: Record management
- Full TDD approach with tests written first

## Week 11-12: MER & Survivorship Engine

### Tasks
- MER-001 to MER-010: Master Entity Record computation
- Survivorship algorithm implementation
- Bi-temporal history tracking

### Additions (from revised execution plan)
- Implement row-level triggers and stored procedures to support MER lineage and versioning (ensure `mer_history` is populated on MER updates).
- Add survivorship audit tracing: record attribute derivation (which `registry_record` contributed each winning attribute) and keep an immutable derivation trail for lineage reports.
- Implement attribute-level locks and source-priority enforcement in the survivorship computation (respect locked attributes, null-prevention rules, and source priority rankings).
- Expose API endpoints to fetch point-in-time MER snapshots and historical MER versions for compliance reporting (support `as_of` and system/valid-time queries).

## Week 13-14: Entity Resolution Engine

### Tasks
- ER-001 to ER-010: Matching algorithms
- Jaro-Winkler implementation
- Name normalization service
- Match candidate queue

### Additions (ER)
- Implement configurable thresholds and policies to control automated linkages (STP) vs. manual review; expose these settings in config.
- Add deterministic pre-checks (registration number + jurisdiction) to short-circuit probabilistic matching when exact identifiers match.
- Define metrics to record match decisions, false-positive/false-negative rates, and reviewer interactions for tuning.

## Week 15-16: Data Quality Engine

### Tasks
- DQ-001 to DQ-010: Rule evaluation
- Issue tracking
- Auto-remediation
- DQ scoring

### Additions (DQ)
- Implement cross-field validations (e.g., jurisdiction-specific registration number formats and date/currency consistency checks).
- Add SLA escalation metadata to `dq_issues` and automatic task creation for remediation; include escalation paths and SLA breach notifications.
- Support manual remediation workflows with audit trail and reviewer assignment; record remediation actions and outcomes.
- Surface DQ metrics on dashboards: counts by severity, auto-resolved vs manual, and filters by jurisdiction/entity type.

---

# PHASE 4: REAL ADAPTERS (Weeks 17-22)

## Week 17-18: GLEIF, UK CH, Norway Brreg

### Tasks
- Replace stubs with real API calls
- OAuth2/API key authentication
- Rate limiting
- Error handling

### Additions (Real adapters / security)
- Integrate secrets management for adapter credentials (vault-backed or environment secrets) and ensure credentials are not stored in source.
- Implement transport encryption and at-rest protections for sensitive fields retrieved from registries where applicable.
- Validate rate-limit compliance for each adapter and add retry/backoff strategies with circuit-breaker patterns.

## Week 19-20: Remaining EU Sources

### Tasks
- Denmark CVR (Elasticsearch)
- Ireland CRO
- Czech ICO
- Poland KRS
- Cyprus sources

## Week 21-22: Non-EU Sources

### Tasks
- Australia ABR (SOAP)
- Japan NTA
- Korea NTS
- USA SEC EDGAR

---

# PHASE 5: FRONTEND IMPLEMENTATION (Weeks 23-32)

## Week 23-26: React Scaffolding & Core Screens

### Tasks
- React 18 + TypeScript setup
- Component library based on mockups
- Dashboard, Search, Entity Detail

## Week 27-30: Operational UIs

### Tasks
- Task Queue
- ER Review
- Manual Entry / OCR
- DQ Dashboard

### Additions (Operational UIs)
- Implement side-by-side ER Review UI: candidate comparison, attribute diffs, provenance (source + timestamp), and reviewer actions (Link / Block / Create New).
- Provide an attribute-diff renderer that highlights WINNER, LOCKED, and source for each value; support keyboard-driven review flows for speed.

## Week 31-32: Configuration UIs

### Tasks
- Source Health
- Mapping Studio
- Rule Editors

### Additions (Config UIs)
- Add a Configurable Rule UI for survivorship and ER: field-weight tuning, preview mode, and dry-run results so operators can validate rule changes before promoting.

---

# PHASE 6: OCR & MANUAL INGESTION (Weeks 33-36)

## Tasks
- Tesseract.js integration
- Document upload to GCP Bucket
- OCR result parsing
- Verification workflow

---

# PHASE 7: API & SECURITY (Weeks 37-42)

## Week 37-38: REST API

### Tasks
- OpenAPI spec
- All endpoints
- Rate limiting

## Week 39-40: Authentication

### Tasks
- JWT implementation
- Google OAuth integration
- Session management

## Week 41-42: Audit & Compliance

### Tasks
- Immutable audit log
- Snapshot generation
- Point-in-time queries

---

# PHASE 8: DEPLOYMENT & PRODUCTION (Weeks 43-48)

## Week 43-44: GCP Setup

### Tasks
- Cloud Run configuration
- GKE cluster (if needed)
- Cloud SQL (Postgres)
- GCP Buckets
- Cloud Pub/Sub (Kafka alternative)

## Week 45-46: CI/CD for Production

### Tasks
- GitHub Actions deployment
- Environment variables
- Secrets management

### Additions (Production security)
- Integrate vault-backed secrets into CI/CD pipelines; ensure deployments fetch secrets at runtime rather than embedding them in build artifacts.
- Add encrypted secrets handling for GCP service accounts and DB credentials, and rotate credentials as part of deployment processes.

## Week 47-48: Monitoring & Go-Live

### Tasks
- Cloud Monitoring
- Alerting
- Runbooks
- Production launch

---

# MASTER TASK LIST

## Total Tasks by Phase

| Phase | Weeks | Task Count | Focus |
|-------|-------|------------|-------|
| 0 | 1-2 | 15 | Foundation |
| 1 | 3-5 | 20 | UI Mockups |
| 2 | 6-8 | 18 | Stub Adapters |
| 3 | 9-16 | 45 | Core API |
| 4 | 17-22 | 20 | Real Adapters |
| 5 | 23-32 | 35 | Frontend |
| 6 | 33-36 | 12 | OCR |
| 7 | 37-42 | 18 | API & Security |
| 8 | 43-48 | 15 | Deployment |
| **Total** | **48 weeks** | **198 tasks** | |

## Solo Developer Timeline

**Estimated Duration:** 48 weeks (12 months)

**Assumptions:**
- Full-time dedication (40 hrs/week)
- No major scope changes
- TDD adds ~30% time but reduces bugs
- Stubs-first approach enables parallel UI/API work

---

# APPENDIX: DAILY STANDUP TEMPLATE

```
## Date: YYYY-MM-DD

### Yesterday
- [x] Completed task X
- [x] Completed task Y

### Today
- [ ] Task A (Phase X, Week Y)
- [ ] Task B

### Blockers
- None / Description

### Notes
- Any learnings or decisions
```

---

# APPENDIX: TESTING STRATEGY

## Unit Tests (TDD)
- Write test first
- One test file per source file
- 80%+ coverage target

## Integration Tests
- API endpoint tests
- Database transaction tests
- Adapter integration tests (with stubs)

## E2E Tests
- Playwright for UI
- Full workflow tests
- Run against stubs initially, real adapters later

---

# APPENDIX: DECISION LOG

| Date | Decision | Rationale | Alternatives Considered |
|------|----------|-----------|------------------------|
| 2025-01-16 | Docker Compose for local dev | Zero external dependencies | SQLite, Cloud dev |
| 2025-01-16 | HTML/Tailwind mockups first | Fast stakeholder validation | Figma, Storybook |
| 2025-01-16 | Tesseract.js for OCR | Local, free, works offline | Cloud Vision, Textract |
| 2025-01-16 | Stubs before real adapters | Full E2E testing capability | Real adapters first |
| 2025-01-16 | TDD approach | Higher quality, fewer regressions | Tests after features |
