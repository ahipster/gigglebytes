# GRIP v2.0 - Complete Platform Specification

## Document Control
| Version | Date | Status |
|---------|------|--------|
| 2.1 | 2025-01-16 | Final |

---

# SECTION 1: PLATFORM OVERVIEW

## 1.1 Platform Intents

| Intent ID | Intent Statement | Success Criteria |
|-----------|------------------|------------------|
| INT-001 | Collect legal entity data from 135+ national registries | Data retrieved from all configured sources within SLA |
| INT-002 | Maintain a single Master Entity Record per legal entity | One canonical record exists with full lineage |
| INT-003 | Track all changes bi-temporally (valid time + system time) | Any historical state reconstructable |
| INT-004 | Automatically match incoming records to existing entities | STP rate > 85% for automated sources |
| INT-005 | Apply survivorship rules to compute best attribute values | Deterministic, reproducible attribute selection |
| INT-006 | Detect and remediate data quality issues | DQ issues surfaced within 24h, critical within 1h |
| INT-007 | Support manual data entry with AI-assisted OCR | OCR accuracy > 90% for structured documents |
| INT-008 | Provide audit-grade lineage for compliance | Point-in-time snapshots exportable with cryptographic proof |
| INT-009 | Monitor registry source health continuously | Degradation detected within 15 minutes |
| INT-010 | Enable steward self-service configuration | No IT involvement for mapping/rule changes |

## 1.2 Terminology

| Term | Definition |
|------|------------|
| CDM | Common Data Model - the canonical schema for entity attributes |
| ER | Entity Resolution - determining if two records refer to the same real-world entity |
| LEI | Legal Entity Identifier - ISO 17442 20-character alphanumeric code |
| MER | Master Entity Record - the computed attribute set for a Legal Entity |
| STP | Straight-Through Processing - automated resolution without human review |
| Survivorship | Rules determining which source value wins when multiple sources provide the same attribute |
| Data Steward | Role responsible for data model integrity and configuration |
| Data Operations Analyst | Role responsible for clearing work queues and manual data tasks |

---

# SECTION 2: INFORMATION MODEL

## 2.1 Ontology

```
+------------------+       1..*        +-------------------+
|   LegalEntity    |<----------------->|  RegistryRecord   |
+------------------+                   +-------------------+
| entity_id: UUID  |                   | record_id: UUID   |
| created_ts       |                   | source_id: FK     |
| status: enum     |                   | valid_from_source |
| merged_into_id   |                   | ingestion_ts      |
| risk_rating      |                   | sourcing_mode     |
+------------------+                   | sourcing_method   |
        |                              | raw_payload: JSON |
        |                              | superseded_by_id  |
        | computes                     +-------------------+
        v                                      |
+-------------------+                          |
| MasterEntityRec   |<-------------------------+
+-------------------+     survivorship
| mer_id: UUID      |
| entity_id: FK     |
| computed_ts       |
| version: Integer  |
| dq_score: Decimal |
| [attributes...]   |
+-------------------+

+-------------------+       provides        +------------------+
|  RegistrySource   |<--------------------->| RegistryRecord   |
+-------------------+                       +------------------+
| source_id: UUID   |
| jurisdiction: FK  |
| registry_type     |
| api_available     |
| api_type          |
| cost_model        |
| refresh_frequency |
| identifier_format |
| rate_limit_*      |
| auth_type         |
| health_status     |
+-------------------+

+-------------------+
|   Jurisdiction    |
+-------------------+
| jurisdiction_id   |
| iso_alpha2        |
| iso_alpha3        |
| level: enum       |  -- COUNTRY | TERRITORY | SUPRANATIONAL
| parent_id: FK     |  -- e.g., Guernsey -> UK
+-------------------+

+-------------------+       tracks          +------------------+
| EntityRelationship|<--------------------->| LegalEntity      |
+-------------------+                       +------------------+
| rel_id: UUID      |
| parent_entity_id  |
| child_entity_id   |
| relationship_type |
| valid_from        |
| valid_to          |
+-------------------+

+-------------------+
|   EntityEvent     |
+-------------------+
| event_id: UUID    |
| entity_id: FK     |
| event_type: enum  |
| event_date        |
| details: JSON     |
| source_id: FK     |
+-------------------+
```

## 2.2 Entity Definitions

| Entity | Definition | Primary Key |
|--------|------------|-------------|
| LegalEntity | An organization recognized by law as having rights and obligations | entity_id (UUID) |
| RegistryRecord | An immutable point-in-time snapshot of data from a single registry source | record_id (UUID) |
| MasterEntityRecord | The computed "best" attribute set for a LegalEntity via survivorship rules | mer_id (UUID) |
| RegistrySource | Metadata about an external registry: access method, cost, jurisdiction | source_id (UUID) |
| Jurisdiction | Geographic or regulatory scope with hierarchy support | jurisdiction_id |
| EntityRelationship | Tracks parent/subsidiary/UBO relationships between entities | rel_id (UUID) |
| EntityEvent | Tracks corporate events (merger, dissolution, name change) | event_id (UUID) |
| MatchCandidate | Stores potential matches for review | candidate_id (UUID) |
| MatchDecision | Audit trail for match decisions | decision_id (UUID) |
| NegativeMatch | Blocks future matching between two entities | block_id (UUID) |
| DQIssue | Tracks data quality issues | issue_id (UUID) |
| DQRule | Defines validation rules | rule_id (UUID) |
| Document | Stores uploaded evidence documents | doc_id (UUID) |
| OCRResult | Stores OCR extraction results | ocr_id (UUID) |
| Task | Generic task queue item | task_id (UUID) |
| ConfigVersion | Version control for configurations | version_id (UUID) |
| AuditEvent | Immutable audit log entry | event_id (UUID) |
| Snapshot | Point-in-time exports | snapshot_id (UUID) |

## 2.3 LegalEntity Attributes

| Attribute | Type | Cardinality | Source | Notes |
|-----------|------|-------------|--------|-------|
| entity_id | UUID | 1 | System | Immutable |
| internal_ref | String(50) | 0..1 | Internal | Optional business key |
| status | Enum | 1 | Computed | ACTIVE, INACTIVE, DISSOLVED, MERGED |
| created_ts | Timestamp | 1 | System | Entity creation |
| last_computed_ts | Timestamp | 1 | System | Last MER computation |
| merged_into_id | UUID FK | 0..1 | System | Redirect for merged entities |
| merge_ts | Timestamp | 0..1 | System | When merged |
| risk_rating | Enum | 0..1 | Computed | Business criticality |
| last_verified_ts | Timestamp | 0..1 | System | Last human verification |

## 2.4 RegistryRecord Attributes

| Attribute | Type | Cardinality | Source | Notes |
|-----------|------|-------------|--------|-------|
| record_id | UUID | 1 | System | Immutable |
| entity_id | UUID FK | 1 | ER Engine | Link to LegalEntity |
| source_id | UUID FK | 1 | System | Link to RegistrySource |
| valid_from_source | Date | 0..1 | Registry | When registry says change occurred |
| ingestion_ts | Timestamp | 1 | System | When system received data |
| sourcing_mode | Enum | 1 | System | AUTOMATED, SEMI_AUTOMATED, MANUAL |
| sourcing_method | Enum | 1 | System | API, FILE, AGENT, OCR, HUMAN |
| stale_flag | Boolean | 1 | Computed | True if exceeds refresh threshold |
| quality_flag | Enum | 1 | DQ Engine | CLEAN, WARNING, CRITICAL |
| raw_payload | JSON | 1 | System | Original response, immutable |
| superseded_by_id | UUID FK | 0..1 | System | Link to newer record |
| verification_status | Enum | 1 | System | UNVERIFIED, VERIFIED, REJECTED |

## 2.5 MasterEntityRecord Attributes (Computed)

| Attribute | Type | Survivorship Rule | Lock Allowed |
|-----------|------|-------------------|--------------|
| legal_name | String(500) | Latest Non-Null | Yes |
| legal_name_local | String(500) | Latest Non-Null | Yes |
| trading_name | String(500) | Latest Non-Null | No |
| legal_form | Enum FK | Latest Non-Null | Yes |
| incorporation_date | Date | Earliest Non-Null | Yes (default locked) |
| incorporation_jurisdiction | Jurisdiction FK | Earliest Non-Null | Yes (default locked) |
| registration_number | String(50) | By Source Priority | Yes |
| tax_id | String(50) | By Source Priority | No |
| lei | String(20) | GLEIF priority | Yes |
| status_code | Enum | Latest Non-Null | No |
| registered_address | Address | Latest Non-Null | No |
| business_address | Address | Latest Non-Null | No |
| version | Integer | System | No |
| dq_score | Decimal | Computed | No |

## 2.6 RegistrySource Attributes

| Attribute | Type | Source | Notes |
|-----------|------|--------|-------|
| source_id | UUID | System | |
| source_code | String(20) | Config | e.g., "SE_BOLAGSVERKET", "GLEIF" |
| source_name | String(100) | Config | Human-readable |
| jurisdiction_id | FK | Config | |
| registry_type | Enum | Config | BUSINESS, TAX, FI, INDIVIDUAL |
| api_available | Boolean | Config | |
| api_type | Enum | Config | REST, SOAP, SDMX, FILE, NONE |
| cost_model | Enum | Config | FREE, SUBSCRIPTION, PER_QUERY, CONTRACT |
| refresh_frequency | String | Config | e.g., "DAILY", "MONTHLY", "ON_DEMAND" |
| delta_available | Boolean | Config | Supports incremental updates |
| identifier_format | Regex | Config | Validation pattern |
| priority_rank | Integer | Config | For survivorship when sources conflict |
| rate_limit_requests | Integer | Config | Max requests per period |
| rate_limit_period_seconds | Integer | Config | Rate limit window |
| auth_type | Enum | Config | NONE, API_KEY, OAUTH2, CERT, BASIC |
| auth_config | JSON | Config | Auth credentials (encrypted ref) |
| last_health_check | Timestamp | System | |
| health_status | Enum | System | HEALTHY, DEGRADED, DOWN |

## 2.7 Address Composite Type

| Attribute | Type | Notes |
|-----------|------|-------|
| address_line_1 | String(200) | |
| address_line_2 | String(200) | |
| city | String(100) | |
| region | String(100) | State/Province |
| postal_code | String(20) | |
| country_code | String(2) | ISO 3166-1 alpha-2 |
| raw_address | String(500) | Original unstructured |
| geo_lat | Decimal | Optional |
| geo_lon | Decimal | Optional |

## 2.8 Enumerations

### EntityStatus
`ACTIVE`, `INACTIVE`, `DISSOLVED`, `MERGED`

### EntityEventType
`INCORPORATION`, `NAME_CHANGE`, `ADDRESS_CHANGE`, `STATUS_CHANGE`, `MERGER`, `ACQUISITION`, `SPLIT`, `DISSOLUTION`, `LIQUIDATION`, `REDOMICILIATION`

### RelationshipType
`PARENT`, `SUBSIDIARY`, `BRANCH`, `UBO`, `DIRECTOR`, `SHAREHOLDER`, `FUND_MANAGER`

### TaskType
`MANUAL_REFRESH`, `ER_REVIEW`, `DQ_REMEDIATION`, `OCR_VERIFICATION`, `CONFLICT_RESOLUTION`

### TaskStatus
`PENDING`, `IN_PROGRESS`, `ON_HOLD`, `COMPLETED`, `CANCELLED`, `ESCALATED`

### MatchDecisionType
`AUTO_LINKED`, `MANUAL_LINKED`, `REJECTED`, `SPLIT`, `DEFERRED`

### DQCategory
`COMPLETENESS`, `FORMAT`, `CONSISTENCY`, `CURRENCY`, `ACCURACY`, `UNIQUENESS`

### QualityFlag
`CLEAN` (0 DQ issues), `WARNING` (1-3 issues), `CRITICAL` (>3 or blocking issue)

### LegalForm (Partial)

| Code | Name | Jurisdiction |
|------|------|--------------|
| SE_AB | Aktiebolag | SE |
| SE_HB | Handelsbolag | SE |
| DE_GMBH | GmbH | DE |
| UK_LTD | Private Limited | GB |
| US_LLC | Limited Liability Company | US |
| GLOBAL_FUND | Investment Fund | SUPRANATIONAL |

---

# SECTION 3: BUSINESS RULES

## 3.1 Identifier Format Validation (BR-DM-001)

| Registry | Format | Regex | Example |
|----------|--------|-------|---------|
| SE Organisationsnummer | NNNNNN-NNNN | `^\d{6}-\d{4}$` | 556123-4567 |
| LEI | 20 alphanumeric | `^[A-Z0-9]{20}$` | 5493001KJTIIGC8Y1R12 |
| UK CRN | 8 digits or 2 letters + 6 digits | `^([0-9]{8}\|[A-Z]{2}[0-9]{6})$` | 12345678, SC123456 |
| NL KvK-nummer | 8 digits | `^\d{8}$` | 12345678 |
| US EIN | NN-NNNNNNN | `^\d{2}-\d{7}$` | 12-3456789 |
| GIIN | 6 chars.5 chars.LE.NNN | `^[A-Z0-9]{6}\.[A-Z0-9]{5}\.LE\.\d{3}$` | ABC123.12345.LE.001 |

## 3.2 Survivorship Rules (BR-DM-002)

```
FOR each attribute IN MasterEntityRecord:
  IF attribute.lock = TRUE AND current_value IS NOT NULL:
    RETAIN current_value  -- Locked attributes don't change
  ELSE:
    candidates = SELECT value, ingestion_ts, source_priority
                 FROM RegistryRecord
                 WHERE entity_id = ? AND attribute IS NOT NULL
                 ORDER BY ingestion_ts DESC, source_priority ASC

    IF candidates.first().value IS NOT NULL:
      SET attribute = candidates.first().value
    ELSE:
      RETAIN current_value  -- Don't overwrite with NULL
```

## 3.3 Stale Data Threshold (BR-DM-003)

| Jurisdiction | Regulatory Basis | Threshold |
|--------------|------------------|-----------|
| EU (AMLD6) | Art. 30 | 12 months |
| UK (MLR 2017) | Reg 28 | 12 months |
| US (CDD Rule) | 31 CFR 1010.230 | Risk-based (12-36 months) |
| Default | Internal Policy | 36 months |

**Rule:** `stale_flag = TRUE WHERE (NOW() - last_refresh_ts) > jurisdiction_threshold`

## 3.4 Source Priority (BR-DM-005)

| Priority | Source Type | Rationale |
|----------|-------------|-----------|
| 1 | Supranational (GLEIF, ECB RIAD) | Standardized, validated |
| 2 | Primary Business Register | Legal authority |
| 3 | Tax Authority Register | Authoritative for tax ID |
| 4 | Financial Supervisor | Authoritative for FI status |
| 5 | Semi-Automated (3rd-party aggregators) | Derived data |
| 6 | Manual (OCR, Human entry) | Lowest confidence |

## 3.5 Entity Rules

| Rule ID | Rule Statement |
|---------|----------------|
| BR-ENT-001 | An entity marked MERGED cannot be modified |
| BR-ENT-002 | Merged entities redirect all queries to survivor |
| BR-ENT-003 | Entity with active relationships cannot be dissolved |
| BR-REC-001 | A RegistryRecord cannot be deleted, only superseded |
| BR-REC-002 | Superseded records excluded from survivorship |
| BR-MER-001 | MER recomputed whenever new record linked |
| BR-MER-002 | MER recomputed whenever survivorship rules change |
| BR-MER-003 | Locked attributes skip survivorship unless force-unlocked |

## 3.6 Entity Resolution Rules

| Rule ID | Rule Statement |
|---------|----------------|
| BR-ER-001 | Negative matches block auto-link permanently |
| BR-ER-002 | Cross-border matches require manual review |
| BR-ER-003 | Match score < 70% auto-rejected |

## 3.7 Data Quality Rules

| Rule ID | Rule Statement |
|---------|----------------|
| BR-DQ-001 | CRITICAL issues block MER publication |
| BR-DQ-002 | Stale entities auto-added to refresh queue |

## 3.8 Source Rules

| Rule ID | Rule Statement |
|---------|----------------|
| BR-SRC-001 | Sources in DOWN status excluded from broadcast |
| BR-SRC-002 | Manual sources never called automatically |
| BR-PM-001 | Retry failed API calls 3 times with exponential backoff |
| BR-PM-002 | If source fails >5 consecutive times, mark source DEGRADED |
| BR-PM-003 | Delta conflicts (>50% name change) route to Conflict Queue |

## 3.9 Configuration Rules

| Rule ID | Rule Statement |
|---------|----------------|
| BR-CFG-001 | Config changes require approval for production |
| BR-CFG-002 | Rollback available for 30 days post-deployment |

## 3.10 Security Rules

| Rule ID | Rule Statement |
|---------|----------------|
| BR-SEC-001 | Failed logins trigger lockout after 5 attempts |
| BR-SEC-002 | API keys expire after 1 year |

## 3.11 Audit Rules

| Rule ID | Rule Statement |
|---------|----------------|
| BR-AUD-001 | All entity modifications logged with before/after |
| BR-AUD-002 | Audit logs retained for 7 years minimum |

## 3.12 Data Quality Validation Rules

### Mandatory Field Completeness (DQ-001)

| Field | Mandatory For | Exception |
|-------|---------------|-----------|
| legal_name | All | None |
| registration_number | All | Sole traders in some jurisdictions |
| jurisdiction | All | None |
| legal_form | All | None |
| incorporation_date | Companies | Not required for partnerships |

### Cross-Field Validation (DQ-002)

| Rule ID | Condition | Severity |
|---------|-----------|----------|
| DQ-002-A | IF status = DISSOLVED THEN dissolution_date IS NOT NULL | WARNING |
| DQ-002-B | IF jurisdiction = 'SE' THEN registration_number MATCHES SE format | CRITICAL |
| DQ-002-C | incorporation_date <= NOW() | CRITICAL |
| DQ-002-D | IF lei IS NOT NULL THEN lei passes checksum | CRITICAL |

---

# SECTION 4: PROCESS SPECIFICATIONS

## 4.1 Process Landscape

```
+------------------------------------------------------------------+
|                    GRIP Process Landscape                         |
+------------------------------------------------------------------+
|                                                                   |
|  +------------------+    +---------------------+                   |
|  | P1: Entity       |    | P2: Entity          |                   |
|  | Establishment    |--->| Maintenance         |                   |
|  +------------------+    +---------------------+                   |
|         |                        |                                |
|         v                        v                                |
|  +------------------+    +---------------------+                   |
|  | P3: Entity       |    | P4: Data Quality    |                   |
|  | Resolution       |    | Management          |                   |
|  +------------------+    +---------------------+                   |
|                                  |                                |
|                                  v                                |
|  +------------------+    +---------------------+                   |
|  | P5: Source       |    | P6: Source          |                   |
|  | Onboarding       |    | Health Monitoring   |                   |
|  +------------------+    +---------------------+                   |
|         |                        |                                |
|         v                        v                                |
|  +------------------+    +---------------------+                   |
|  | P7: Entity       |    | P8: Entity          |                   |
|  | Merge            |    | Split/Unmerge       |                   |
|  +------------------+    +---------------------+                   |
|         |                                                         |
|         v                                                         |
|  +------------------+    +---------------------+                   |
|  | P9: Corporate    |    | P10: Configuration  |                   |
|  | Event Processing |    | Deployment          |                   |
|  +------------------+    +---------------------+                   |
|                                                                   |
+------------------------------------------------------------------+
```

| Process | Trigger | Owner | Primary Actor |
|---------|---------|-------|---------------|
| P1: Entity Establishment | New entity request | Process Owner | System / Data Ops |
| P2: Entity Maintenance | Schedule / Event | Process Owner | System |
| P3: Entity Resolution | New RegistryRecord | Process Owner | ER Engine / Steward |
| P4: Data Quality Management | DQ issue detected | Data Steward | Data Ops |
| P5: Source Onboarding | New registry identified | Data Steward | IT / Steward |
| P6: Source Health Monitoring | Continuous | IT Operations | System |
| P7: Entity Merge | ER decision | Data Ops | System / Steward |
| P8: Entity Split/Unmerge | User request | Data Steward | System |
| P9: Corporate Event Processing | Registry notification | System/Data Ops | System |
| P10: Configuration Deployment | Steward approval | IT/Steward | System |

## 4.2 P1: Entity Establishment

**Purpose:** Create a new LegalEntity and populate it with RegistryRecords from available sources.

**Trigger:** Internal system request containing search criteria (name, jurisdiction, registration number)

**Inputs:**
- Search criteria (name, jurisdiction, registration_number)
- Requestor context (business unit, purpose)

**Outputs:**
- New LegalEntity with entity_id
- 0..n linked RegistryRecords
- Computed MasterEntityRecord
- OR Manual Task if no automated sources

```
                    +-------------------+
                    |  Entity Request   |
                    |     Received      |
                    +--------+----------+
                             |
                             v
                    +--------+----------+
                    |  Identify         |
                    |  Available        |
                    |  Sources          |
                    +--------+----------+
                             |
              +--------------+--------------+
              |                             |
              v                             v
     +--------+--------+          +---------+---------+
     | Automated       |          | Manual-Only       |
     | Sources Exist   |          | Jurisdiction      |
     +--------+--------+          +---------+---------+
              |                             |
              v                             |
     +--------+--------+                    |
     | Broadcast       |                    |
     | Registry        |                    |
     | Queries         |                    |
     +--------+--------+                    |
              |                             |
              v                             |
     +--------+--------+                    |
     | Collect         |                    |
     | Responses       |                    |
     | (Timeout: 30s)  |                    |
     +--------+--------+                    |
              |                             |
              v                             |
     +--------+--------+                    |
     | Execute         |                    |
     | Entity          |                    |
     | Resolution      |<-------------------+
     +--------+--------+        (if no matches)
              |
     +--------+--------+--------+
     |        |                 |
     v        v                 v
  +--+--+  +--+--+         +----+----+
  | STP |  |Review|        |No Match |
  |Match|  |Match |        |         |
  +--+--+  +--+--+         +----+----+
     |        |                 |
     v        v                 v
  +--+--------+--+         +----+----+
  | Create/Link  |         | Create  |
  | LegalEntity  |         | Manual  |
  +--------------+         | Task    |
         |                 +---------+
         v
  +------+------+
  | Compute     |
  | Master      |
  | Entity Rec  |
  +------+------+
         |
         v
  +------+------+
  |   Entity    |
  | Established |
  +-------------+
```

**SLA Targets:**

| Step | Target | Escalation |
|------|--------|------------|
| Query Broadcast | 30 seconds | Timeout, proceed with available |
| STP Resolution | Immediate | N/A |
| Review Resolution | 4 hours | Escalate to Senior Ops |
| Manual Task | 24 hours | Escalate to Steward |

## 4.3 P2: Entity Maintenance

**Purpose:** Keep MasterEntityRecords current by refreshing from registry sources.

**Triggers:**
- Scheduled: Stale threshold exceeded
- Event: Downstream system request
- Event: Registry delta notification (where available)

```
              +-------------------+
              |    Trigger        |
              | (Schedule/Event)  |
              +--------+----------+
                       |
                       v
              +--------+----------+
              | Select Entities   |
              | Due for Refresh   |
              +--------+----------+
                       |
                       v
              +--------+----------+
              | For Each Entity:  |
              | Get Active        |
              | Sources           |
              +--------+----------+
                       |
          +------------+------------+
          |                         |
          v                         v
   +------+------+          +-------+-------+
   | Automated   |          | Manual-Only   |
   | Source      |          | Source        |
   +------+------+          +-------+-------+
          |                         |
          v                         |
   +------+------+                  |
   | Call        |                  |
   | Registry    |                  |
   | API/Agent   |                  |
   +------+------+                  |
          |                         |
     +----+----+                    |
     |         |                    |
     v         v                    |
  +--+--+   +--+--+                  |
  | OK  |   |Fail |                  |
  +--+--+   +--+--+                  |
     |         |                    |
     |         v                    |
     |   +-----+-----+              |
     |   | Log       |              |
     |   | Failure   |              |
     |   | Check     |              |
     |   | Threshold |              |
     |   +-----+-----+              |
     |         |                    |
     |    +----+----+               |
     |    |         |               |
     |    v         v               |
     | +--+--+  +---+---+           |
     | |Retry|  |Create |           |
     | |Later|  |Manual |           |
     | +-----+  |Task   |           |
     |          +---+---+           |
     |              |               |
     |              +-------+-------+
     |                      |
     v                      v
   +-+----------------------+-+
   | Create New              |
   | RegistryRecord          |
   +----------+--------------+
              |
              v
   +----------+--------------+
   | Execute Delta           |
   | Analysis                |
   +----------+--------------+
              |
      +-------+-------+
      |               |
      v               v
   +--+---+      +----+----+
   |No    |      |Changes  |
   |Change|      |Detected |
   +--+---+      +----+----+
      |               |
      |               v
      |         +-----+-----+
      |         |Apply      |
      |         |Survivorship|
      |         |Rules      |
      |         +-----+-----+
      |               |
      |          +----+----+
      |          |         |
      |          v         v
      |      +---+---+ +---+---+
      |      |Update | |Conflict|
      |      |MER    | |Queue  |
      |      +---+---+ +---+---+
      |          |         |
      +----------+---------+
                 |
                 v
         +-------+-------+
         | Update        |
         | last_refresh_ts|
         +---------------+
```

## 4.4 P3: Entity Resolution

**Purpose:** Match incoming RegistryRecords to existing LegalEntities or create new ones.

**Decision Table:**

| Reg Number Match | Country Match | Name Similarity | Result |
|------------------|---------------|-----------------|--------|
| Exact | Exact | Any | STP Link |
| Exact | Different | Any | Review (cross-border?) |
| None | Exact | >= 95% | Review |
| None | Exact | 85-94% | Review |
| None | Exact | < 85% | No Match, Create New |
| Partial | Exact | >= 90% | Review |

**Name Similarity Algorithm:** Jaro-Winkler with preprocessing:
1. Uppercase
2. Remove legal form suffixes (Ltd, GmbH, AB, etc.)
3. Remove punctuation
4. Transliterate to Latin (for non-Latin scripts)
5. Calculate Jaro-Winkler score

## 4.5 P4: Data Quality Management

**Purpose:** Detect, track, and remediate data quality issues.

**Issue Taxonomy:**

| Category | Code | Description | Auto-Resolve |
|----------|------|-------------|--------------|
| Completeness | DQ-COMP-001 | Mandatory field missing | No |
| Format | DQ-FMT-001 | Identifier fails regex | Yes (if correctable) |
| Consistency | DQ-CON-001 | Cross-field validation fail | No |
| Currency | DQ-CUR-001 | Record stale | Trigger refresh |
| Accuracy | DQ-ACC-001 | Value contradicts trusted source | Review |

## 4.6 P5: Source Onboarding

**Purpose:** Configure a new registry source for automated or semi-automated ingestion.

**Stages:**
1. **Discovery:** Document source from registry catalog
2. **Technical Assessment:** API availability, authentication, rate limits
3. **Mapping Design:** Schema mapping to CDM (Steward-owned)
4. **Adapter Development:** IT builds connector
5. **UAT:** Test with sample entities
6. **Go-Live:** Enable for production

**Artifacts Required:**

| Artifact | Owner | Template |
|----------|-------|----------|
| Source Profile | Steward | source_profile_template.yaml |
| Field Mapping | Steward | mapping_studio export |
| API Spec | IT | OpenAPI 3.0 |
| Test Cases | QA | test_case_template.xlsx |

## 4.7 P6: Source Health Monitoring

**Purpose:** Continuously monitor registry source availability and performance.

**Metrics:**

| Metric | Target | Alert Threshold |
|--------|--------|-----------------|
| API Availability | 99.5% | < 95% over 1hr |
| Response Time (p95) | < 5s | > 10s |
| Error Rate | < 1% | > 5% |
| Data Freshness | Per source SLA | > 2x SLA |

**Health Status Transitions:**

```
HEALTHY --(>5% errors)--> DEGRADED --(>20% errors)--> DOWN
   ^                          |                         |
   |                          |                         |
   +----(< 1% errors)---------+----(recovered)----------+
```

## 4.8 RACI Matrix

| Activity | Data Steward | Data Ops | IT | Process Owner |
|----------|--------------|----------|----|----|
| Define survivorship rules | A/R | C | I | C |
| Configure field mappings | A/R | C | I | I |
| Execute manual refresh | I | A/R | I | C |
| Resolve ER conflicts | C | A/R | I | I |
| Build source adapters | C | I | A/R | I |
| Monitor source health | I | C | A/R | I |
| Escalate critical DQ | C | R | I | A |
| Approve source go-live | A | C | R | C |

---

# SECTION 5: USER PERSONAS & STORIES

## 5.1 User Personas

### Persona 1: Data Steward ("The Architect")
- **Goals:** Maintain data model integrity, optimize STP rates, ensure regulatory compliance
- **Pain Points:** Manual mapping is tedious, hard to trace why attributes were selected
- **Frequency:** Daily, 2-4 hours in system

### Persona 2: Data Operations Analyst ("The Operator")
- **Goals:** Clear work queue, minimize manual entry errors, meet SLA targets
- **Pain Points:** Too many clicks to resolve a match, OCR failures require re-work
- **Frequency:** Daily, 6-8 hours in system

### Persona 3: Compliance Officer ("The Auditor")
- **Goals:** Prove data lineage for any point in time, demonstrate refresh compliance
- **Pain Points:** Cannot easily generate audit reports, lineage visualization unclear
- **Frequency:** Weekly, 1-2 hours + audit periods

## 5.2 User Stories

### Epic: Entity Search & Establishment

**US-EST-001:** As a Data Ops Analyst, I want to search for an entity by name and jurisdiction so that I can establish it in the system.
- **Acceptance Criteria:**
  - Search supports partial name match
  - Results show match confidence %
  - Can filter by jurisdiction, legal form
  - Response < 3 seconds

**US-EST-002:** As a Data Ops Analyst, I want to see all automated registry results for my search so that I can select the correct entity.
- **Acceptance Criteria:**
  - Results grouped by source
  - Each result shows: legal name, reg number, status, source
  - Can expand to see full payload

**US-EST-003:** As a Data Ops Analyst, I want the system to auto-link high-confidence matches so that I don't review obvious cases.
- **Acceptance Criteria:**
  - STP threshold configurable by Steward
  - STP matches show as "Auto-Linked" with audit trail
  - Can undo auto-link within 24 hours

### Epic: Entity Maintenance

**US-MNT-001:** As a Data Ops Analyst, I want to see a prioritized list of entities requiring refresh so that I work on the most urgent first.
- **Acceptance Criteria:**
  - Sort by: days overdue, regulatory importance, business criticality
  - Filter by: jurisdiction, source type, assigned user
  - Bulk actions: assign, snooze, escalate

**US-MNT-002:** As a Data Ops Analyst, I want to upload a document and have OCR extract entity data so that I avoid manual typing.
- **Acceptance Criteria:**
  - Supports PDF, JPG, PNG
  - OCR confidence shown per field
  - Can correct OCR output before saving
  - Original document stored as evidence

**US-MNT-003:** As a Data Ops Analyst, I want to see what changed between the current and incoming record so that I can validate the update.
- **Acceptance Criteria:**
  - Side-by-side diff view
  - Changed fields highlighted
  - Can accept all / reject all / field-by-field

### Epic: Entity Resolution

**US-ER-001:** As a Data Ops Analyst, I want to resolve suspected matches by comparing entities side-by-side so that I can decide if they are the same.
- **Acceptance Criteria:**
  - Show both entities with all attributes
  - Highlight matching/differing fields
  - Actions: Merge, Keep Separate, Flag as "Never Same"

**US-ER-002:** As a Data Steward, I want to configure ER matching rules so that I can improve STP rates.
- **Acceptance Criteria:**
  - UI to set field weights (0-100)
  - UI to set STP threshold (default 95%)
  - Preview mode to test rules against sample data
  - Audit log of rule changes

### Epic: Lineage & Audit

**US-LIN-001:** As a Data Steward, I want to see the lineage of each attribute in the Master Entity Record so that I understand why a value was selected.
- **Acceptance Criteria:**
  - Attribute Lineage Table shows: attribute, current value, source, ingestion date
  - All contributing records shown chronologically
  - "Winner" highlighted
  - Click to view raw evidence (JSON/PDF)

**US-LIN-002:** As a Compliance Officer, I want to generate a point-in-time snapshot of an entity so that I can prove what we knew on a specific date.
- **Acceptance Criteria:**
  - Date picker for any historical date
  - Shows MER as it was computed on that date
  - Shows which RegistryRecords existed at that date
  - Exportable as PDF with digital signature

### Epic: Source Management

**US-SRC-001:** As a Data Steward, I want to map fields from a new registry to the CDM so that data is standardized automatically.
- **Acceptance Criteria:**
  - Mapping Studio UI with source schema on left, CDM on right
  - Drag-and-drop mapping
  - Transformation functions: lookup, concatenate, conditional
  - Validate mapping against sample payload
  - Version control for mappings

**US-SRC-002:** As a Data Steward, I want to see registry health status so that I know which sources are degraded.
- **Acceptance Criteria:**
  - Dashboard with all sources
  - Status indicators: green/yellow/red
  - Metrics: availability %, avg response time, last success
  - Click to see historical chart

---

# SECTION 6: FEATURE SPECIFICATIONS

## 6.1 Entity Search & Establish

```
+------------------+     +------------------+     +------------------+
|   Search Form    |     |   Results List   |     |   Establish      |
|                  |     |                  |     |   Confirmation   |
| [Name........]   |     | [ ] Result 1     |     |                  |
| [Jurisdiction v] | --> | [ ] Result 2     | --> | Entity Created   |
| [Reg Number...]  |     | [ ] Result 3     |     | ID: abc-123      |
| [Search]         |     | [Establish]      |     | [View Entity]    |
+------------------+     +------------------+     +------------------+
```

**Wireframe: Search Form**

```
+-------------------------------------------------------+
|  ESTABLISH NEW ENTITY                            [X]  |
+-------------------------------------------------------+
|                                                       |
|  Search Criteria                                      |
|  +-------------------------------------------------+ |
|  | Legal Name        [__________________________ ] | |
|  | Jurisdiction      [Sweden (SE)              v ] | |
|  | Registration No.  [__________________________ ] | |
|  | LEI (optional)    [__________________________ ] | |
|  +-------------------------------------------------+ |
|                                                       |
|  [ ] Include dissolved entities                       |
|  [ ] Search all subsidiaries                          |
|                                                       |
|                           [Clear]  [Search Sources]   |
+-------------------------------------------------------+
```

**Wireframe: Results List**

```
+-------------------------------------------------------+
|  SEARCH RESULTS (3 sources responded in 2.4s)         |
+-------------------------------------------------------+
|                                                       |
|  AUTOMATED MATCHES                                    |
|  +---------------------------------------------------+|
|  | [x] Bolagsverket (SE)                   98% match ||
|  |     Acme AB | 556123-4567 | Active               ||
|  |     Stockholm | Incorporated 2015-03-12          ||
|  |     [View Details]                               ||
|  +---------------------------------------------------+|
|  | [ ] GLEIF                               95% match ||
|  |     Acme AB | LEI: 549300ABC...        | Active  ||
|  |     [View Details]                               ||
|  +---------------------------------------------------+|
|                                                       |
|  NO AUTOMATED SOURCE                                  |
|  +---------------------------------------------------+|
|  | Finansinspektionen (FI.se)             [Manual]  ||
|  |     No API - Requires manual lookup              ||
|  +---------------------------------------------------+|
|                                                       |
|        [Cancel]  [Establish Selected as New Entity]   |
+-------------------------------------------------------+
```

## 6.2 Attribute Lineage Table

```
+-----------------------------------------------------------------------+
|  ENTITY: Acme AB (ID: abc-123-def)                                    |
|  Tab: [Overview] [Lineage] [Documents] [History] [Issues]             |
+-----------------------------------------------------------------------+
|                                                                       |
|  ATTRIBUTE LINEAGE                                   [Export] [Print] |
|                                                                       |
|  +---------------------------------------------------------------------+
|  | Attribute         | Current Value    | Source      | Ingested     ||
|  |-------------------+------------------+-------------+--------------||
|  | Legal Name        | Acme AB          | Bolagsverket| 2024-12-01   ||
|  |                   |                  | [WINNER]    |              ||
|  |                   +------------------+-------------+--------------||
|  |                   | ACME Aktiebolag  | GLEIF       | 2024-11-15   ||
|  |                   +------------------+-------------+--------------||
|  |                   | Acme AB          | Manual OCR  | 2023-06-01   ||
|  |-------------------+------------------+-------------+--------------||
|  | Reg. Number       | 556123-4567      | Bolagsverket| 2024-12-01   ||
|  |                   |                  | [LOCKED]    |              ||
|  |-------------------+------------------+-------------+--------------||
|  | Incorporation     | 2015-03-12       | Bolagsverket| 2024-12-01   ||
|  | Date              |                  | [LOCKED]    |              ||
|  |-------------------+------------------+-------------+--------------||
|  | Status            | Active           | Bolagsverket| 2024-12-01   ||
|  |                   |                  | [WINNER]    |              ||
|  +---------------------------------------------------------------------+
|                                                                       |
|  Legend: [WINNER] = Selected by survivorship | [LOCKED] = Steward lock|
|                                                                       |
+-----------------------------------------------------------------------+
```

## 6.3 Mapping Studio

```
+-----------------------------------------------------------------------+
|  MAPPING STUDIO: Bolagsverket (SE)                        [Save] [X] |
+-----------------------------------------------------------------------+
|                                                                       |
|  Source Schema (API Response)    -->    CDM (Target)                  |
|                                                                       |
|  +---------------------------+        +---------------------------+   |
|  | foretagsnamn             |   -->  | legal_name                |   |
|  | organisationsnummer      |   -->  | registration_number       |   |
|  | status_kod               |   -->  | status_code               |   |
|  |   [Transform: A=ACTIVE]  |        |   (via lookup table)      |   |
|  | registreringsdatum       |   -->  | incorporation_date        |   |
|  | postadress               |   -->  | registered_address        |   |
|  |   [Transform: parse]     |        |   (composite)             |   |
|  | verksamhetstyp           |   -->  | legal_form                |   |
|  |   [Transform: map AB]    |        |   (via lookup)            |   |
|  +---------------------------+        +---------------------------+   |
|                                                                       |
|  Unmapped Source Fields:              Unmapped Target Fields:         |
|  - telefonnummer                      - lei                           |
|  - epost                              - tax_id                        |
|                                                                       |
|  [Validate Mapping]   [Test with Sample]   [View Change History]      |
+-----------------------------------------------------------------------+
```

## 6.4 Registry Health Dashboard

```
+-----------------------------------------------------------------------+
|  REGISTRY HEALTH CENTER                                               |
+-----------------------------------------------------------------------+
|                                                                       |
|  Overall Health: 94% (127/135 sources healthy)    [Last check: 5m]   |
|                                                                       |
|  +-------------------------------------------------------------------+|
|  | Filter: [All v] [Jurisdiction v] [Type v]        [Search...]     ||
|  +-------------------------------------------------------------------+|
|                                                                       |
|  +------------------------------------------------------------------+ |
|  | Source                | Type   | Status  | Avail | Resp  | Last | |
|  |-----------------------+--------+---------+-------+-------+------| |
|  | GLEIF                 | FI     |  [===]  | 99.9% | 0.8s  | 5m   | |
|  | Bolagsverket (SE)     | BIZ    |  [===]  | 99.2% | 1.2s  | 10m  | |
|  | Companies House (UK)  | BIZ    |  [===]  | 98.5% | 2.1s  | 15m  | |
|  | KVK (NL)              | BIZ    |  [==-]  | 94.1% | 4.5s  | 8m   | |
|  | Handelsregister (DE)  | BIZ    |  [---]  | N/A   | N/A   | MAN  | |
|  | FI.se (SE)            | FI     |  [==-]  | 89.2% | 3.2s  | 1h   | |
|  +------------------------------------------------------------------+ |
|                                                                       |
|  Legend: [===] Healthy  [==-] Degraded  [---] Manual Only             |
|                                                                       |
+-----------------------------------------------------------------------+
```

---

# SECTION 7: FUNCTIONAL REQUIREMENTS

## 7.1 Entity Management (ENT)

| Req ID | Requirement | Priority |
|--------|-------------|----------|
| ENT-001 | System shall create a new LegalEntity with a unique UUID | Must |
| ENT-002 | System shall support entity status transitions (Active→Inactive→Dissolved) | Must |
| ENT-003 | System shall merge two entities into one survivor | Must |
| ENT-004 | System shall split an entity into two (unmerge) | Must |
| ENT-005 | System shall track entity events (name change, merger, dissolution) | Must |
| ENT-006 | System shall manage entity relationships (parent/subsidiary) | Should |
| ENT-007 | System shall compute and store risk rating per entity | Should |
| ENT-008 | System shall track last verification timestamp | Should |
| ENT-009 | System shall support soft-delete (deactivation) only | Must |
| ENT-010 | System shall redirect queries for merged entities to survivor | Must |

## 7.2 Record Management (REC)

| Req ID | Requirement | Priority |
|--------|-------------|----------|
| REC-001 | System shall create immutable RegistryRecords | Must |
| REC-002 | System shall store raw payload as-received | Must |
| REC-003 | System shall track valid_from_source and ingestion_ts | Must |
| REC-004 | System shall mark records as superseded (not deleted) | Must |
| REC-005 | System shall compute stale_flag based on jurisdiction threshold | Must |
| REC-006 | System shall compute quality_flag based on DQ rules | Must |
| REC-007 | System shall link records to source via source_id | Must |
| REC-008 | System shall support verification workflow for manual records | Should |
| REC-009 | System shall store OCR confidence per extracted field | Should |
| REC-010 | System shall retain records per retention policy | Should |

## 7.3 Master Entity Record (MER)

| Req ID | Requirement | Priority |
|--------|-------------|----------|
| MER-001 | System shall compute MER on each new record ingestion | Must |
| MER-002 | System shall apply survivorship rules per BR-DM-002 | Must |
| MER-003 | System shall respect attribute locks | Must |
| MER-004 | System shall skip NULL values in survivorship | Must |
| MER-005 | System shall track MER version number | Should |
| MER-006 | System shall compute DQ score for MER | Should |
| MER-007 | System shall store all historical MER versions | Must |
| MER-008 | System shall recompute MER when survivorship rules change | Should |
| MER-009 | System shall publish MER changes to event stream | Should |
| MER-010 | System shall support forced attribute override by Steward | Should |

## 7.4 Entity Resolution (ER)

| Req ID | Requirement | Priority |
|--------|-------------|----------|
| ER-001 | System shall perform deterministic matching on reg number + country | Must |
| ER-002 | System shall perform probabilistic matching using Jaro-Winkler | Must |
| ER-003 | System shall preprocess names (uppercase, remove suffixes, transliterate) | Must |
| ER-004 | System shall create MatchCandidate records for review queue | Must |
| ER-005 | System shall support Negative Match blocking | Must |
| ER-006 | System shall log all match decisions with reason | Must |
| ER-007 | System shall support configurable matching weights | Should |
| ER-008 | System shall support configurable STP threshold | Should |
| ER-009 | System shall detect and cluster potential duplicates proactively | Should |
| ER-010 | System shall support multi-way merge (3+ entities) | Should |

## 7.5 Data Quality (DQ)

| Req ID | Requirement | Priority |
|--------|-------------|----------|
| DQ-001 | System shall evaluate DQ rules on record ingestion | Must |
| DQ-002 | System shall categorize issues (Completeness, Format, etc.) | Must |
| DQ-003 | System shall assign severity (CLEAN, WARNING, CRITICAL) | Must |
| DQ-004 | System shall auto-remediate correctable issues | Should |
| DQ-005 | System shall create tasks for non-auto issues | Must |
| DQ-006 | System shall track issue lifecycle (detected→resolved) | Must |
| DQ-007 | System shall block MER publication on CRITICAL issues | Should |
| DQ-008 | System shall provide DQ dashboard with metrics | Should |
| DQ-009 | System shall support custom DQ rules by Steward | Should |
| DQ-010 | System shall compute entity-level DQ score | Should |

## 7.6 Integration & Adapters (INT)

| Req ID | Requirement | Priority |
|--------|-------------|----------|
| INT-001 | System shall support REST API adapters with OAuth2/API key auth | Must |
| INT-002 | System shall support SOAP/WSDL adapters | Must |
| INT-003 | System shall support SDMX REST adapters | Should |
| INT-004 | System shall support file ingestion (FTP/SFTP/S3) | Must |
| INT-005 | System shall support delta/change feeds | Should |
| INT-006 | System shall support web scraping agents | Should |
| INT-007 | System shall integrate OCR service | Must |
| INT-008 | System shall respect source rate limits | Must |
| INT-009 | System shall securely store credentials (vault integration) | Must |
| INT-010 | System shall retry failed requests with exponential backoff | Must |
| INT-011 | System shall timeout requests after configured duration | Must |
| INT-012 | System shall log all external API calls | Must |

## 7.7 Workflow & Task Management (WF)

| Req ID | Requirement | Priority |
|--------|-------------|----------|
| WF-001 | System shall create tasks with type, priority, due date | Must |
| WF-002 | System shall assign tasks to users or queues | Must |
| WF-003 | System shall track task status transitions | Must |
| WF-004 | System shall calculate task aging and SLA breach | Must |
| WF-005 | System shall auto-escalate tasks breaching SLA | Should |
| WF-006 | System shall support bulk task actions | Should |
| WF-007 | System shall send notifications on task events | Should |
| WF-008 | System shall support maker-checker workflow | Should |
| WF-009 | System shall provide task dashboard with filters | Must |
| WF-010 | System shall track task completion metrics | Should |

## 7.8 Configuration Management (CFG)

| Req ID | Requirement | Priority |
|--------|-------------|----------|
| CFG-001 | System shall provide Mapping Studio for field mappings | Must |
| CFG-002 | System shall support transformation functions in mappings | Must |
| CFG-003 | System shall validate mappings against sample data | Should |
| CFG-004 | System shall version all configuration changes | Must |
| CFG-005 | System shall support config promotion (Dev→Test→Prod) | Should |
| CFG-006 | System shall require approval for production config changes | Should |
| CFG-007 | System shall support config rollback | Should |
| CFG-008 | System shall provide Survivorship Rule editor | Must |
| CFG-009 | System shall provide ER Rule editor | Must |
| CFG-010 | System shall provide Lookup Table editor | Should |

## 7.9 Source Management (SRC)

| Req ID | Requirement | Priority |
|--------|-------------|----------|
| SRC-001 | System shall maintain registry source catalog | Must |
| SRC-002 | System shall track source health metrics | Must |
| SRC-003 | System shall detect source degradation automatically | Must |
| SRC-004 | System shall alert on source issues | Should |
| SRC-005 | System shall support source onboarding workflow | Must |
| SRC-006 | System shall support source deprecation workflow | Should |
| SRC-007 | System shall schedule source health probes | Must |
| SRC-008 | System shall provide source health dashboard | Must |
| SRC-009 | System shall track source SLAs | Should |
| SRC-010 | System shall support source-specific identifier formats | Must |

## 7.10 API & Output (API)

| Req ID | Requirement | Priority |
|--------|-------------|----------|
| API-001 | System shall expose Entity Query REST API | Must |
| API-002 | System shall support search by name, reg number, LEI | Must |
| API-003 | System shall expose Change Stream (Kafka) | Should |
| API-004 | System shall support point-in-time queries | Must |
| API-005 | System shall support bulk export (JSON, CSV) | Should |
| API-006 | System shall authenticate API consumers | Must |
| API-007 | System shall rate-limit API consumers | Should |
| API-008 | System shall version APIs | Should |
| API-009 | System shall provide OpenAPI documentation | Must |
| API-010 | System shall support webhook subscriptions | Should |

## 7.11 Security & Access (SEC)

| Req ID | Requirement | Priority |
|--------|-------------|----------|
| SEC-001 | System shall integrate with SSO (OIDC/SAML) | Must |
| SEC-002 | System shall enforce role-based access control | Must |
| SEC-003 | System shall support jurisdiction-based data access | Should |
| SEC-004 | System shall encrypt sensitive data at rest | Must |
| SEC-005 | System shall encrypt all data in transit (TLS 1.3) | Must |
| SEC-006 | System shall mask PII in logs | Must |
| SEC-007 | System shall lock accounts after failed logins | Should |
| SEC-008 | System shall expire API keys annually | Should |
| SEC-009 | System shall log all access events | Must |
| SEC-010 | System shall support MFA for admin users | Should |

## 7.12 Audit & Compliance (AUD)

| Req ID | Requirement | Priority |
|--------|-------------|----------|
| AUD-001 | System shall log all entity modifications | Must |
| AUD-002 | System shall log all user actions | Must |
| AUD-003 | System shall make audit logs immutable | Must |
| AUD-004 | System shall retain audit logs per policy (7 years) | Must |
| AUD-005 | System shall generate point-in-time snapshots | Must |
| AUD-006 | System shall digitally sign exported snapshots | Should |
| AUD-007 | System shall provide audit search interface | Must |
| AUD-008 | System shall export audit reports (PDF, CSV) | Should |
| AUD-009 | System shall track data lineage end-to-end | Must |
| AUD-010 | System shall support compliance reporting templates | Should |

---

# SECTION 8: NON-FUNCTIONAL REQUIREMENTS

## 8.1 Performance

| Req ID | Requirement | Target |
|--------|-------------|--------|
| NFR-PERF-001 | Entity search response time | < 3s (p95) |
| NFR-PERF-002 | Entity detail page load | < 2s |
| NFR-PERF-003 | Record ingestion throughput | > 100 records/sec |
| NFR-PERF-004 | MER computation time | < 500ms per entity |
| NFR-PERF-005 | Bulk export 10k entities | < 30s |
| NFR-PERF-006 | API response time | < 500ms (p95) |
| NFR-PERF-007 | ER matching batch | 1000 candidates/min |
| NFR-PERF-008 | Dashboard load time | < 3s |

## 8.2 Scalability

| Req ID | Requirement | Target |
|--------|-------------|--------|
| NFR-SCALE-001 | Total entities supported | 10 million |
| NFR-SCALE-002 | Registry records supported | 100 million |
| NFR-SCALE-003 | Concurrent UI users | 50 |
| NFR-SCALE-004 | Concurrent API requests | 500/sec |
| NFR-SCALE-005 | Registry sources supported | 200 |
| NFR-SCALE-006 | Daily ingestion volume | 1 million records |

## 8.3 Availability

| Req ID | Requirement | Target |
|--------|-------------|--------|
| NFR-AVAIL-001 | Platform availability | 99.9% |
| NFR-AVAIL-002 | Planned maintenance window | < 4h/month |
| NFR-AVAIL-003 | Recovery Time Objective (RTO) | < 1 hour |
| NFR-AVAIL-004 | Recovery Point Objective (RPO) | < 15 minutes |

## 8.4 Security

| Req ID | Requirement | Standard |
|--------|-------------|----------|
| NFR-SEC-001 | Authentication | OIDC/SAML 2.0 |
| NFR-SEC-002 | Authorization | RBAC |
| NFR-SEC-003 | Encryption at rest | AES-256 |
| NFR-SEC-004 | Encryption in transit | TLS 1.3 |
| NFR-SEC-005 | Audit logging | Immutable, 7-year retention |
| NFR-SEC-006 | Vulnerability scanning | Weekly automated scans |

## 8.5 Usability

| Req ID | Requirement | Target |
|--------|-------------|--------|
| NFR-USE-001 | Accessibility | WCAG 2.1 AA |
| NFR-USE-002 | Browser support | Chrome, Edge, Firefox (latest 2) |
| NFR-USE-003 | Localization | English (default), extensible |
| NFR-USE-004 | Training time for new user | < 4 hours |
| NFR-USE-005 | Task completion efficiency | < 5 clicks for common tasks |

---

# SECTION 9: ARCHITECTURE

## 9.1 System Context

```
+------------------------------------------------------------------+
|                         GRIP Platform                             |
+------------------------------------------------------------------+
|                                                                   |
|  +-------------+  +-------------+  +-------------+  +----------+ |
|  |   Web UI    |  |   REST API  |  | Change Stream|  |  Admin   | |
|  |  (React)    |  |  (Gateway)  |  |  (Kafka)    |  |  Console | |
|  +------+------+  +------+------+  +------+------+  +----+-----+ |
|         |                |                |              |       |
|         +----------------+----------------+--------------+       |
|                          |                                       |
|                  +-------+-------+                               |
|                  |   API Layer   |                               |
|                  | (Node.js)     |                               |
|                  +-------+-------+                               |
|                          |                                       |
|    +----------+----------+----------+----------+----------+      |
|    |          |          |          |          |          |      |
| +--+---+ +----+----+ +---+----+ +---+----+ +---+---+ +----+---+  |
| |Entity| |   ER    | |  DQ    | | Source | | Task  | | Audit  |  |
| |Service| | Engine | | Engine | | Manager| | Queue | | Logger |  |
| +--+---+ +----+----+ +---+----+ +---+----+ +---+---+ +----+---+  |
|    |          |          |          |          |          |      |
|    +----------+----------+----------+----------+----------+      |
|                          |                                       |
|                  +-------+-------+                               |
|                  |  Data Layer   |                               |
|                  +-------+-------+                               |
|                          |                                       |
|    +----------+----------+----------+----------+                 |
|    |          |          |          |          |                 |
| +--+---+  +---+----+  +--+---+  +---+---+  +---+---+             |
| |Postgres|  | Neo4j  |  |Redis |  |S3/Blob|  |Kafka |            |
| |(Entity)|  |(Graph) |  |(Cache)|  |(Docs) |  |(Events)|         |
| +--------+  +--------+  +------+  +-------+  +-------+           |
|                                                                   |
+------------------------------------------------------------------+
                          |
    +---------------------+---------------------+
    |                     |                     |
+---+---+           +-----+-----+         +-----+-----+
|Registry|          |Registry   |         |Registry   |
|APIs    |          |Files      |         |Portals    |
|(REST/  |          |(FTP/S3)   |         |(Scraping) |
| SOAP)  |          |           |         |           |
+--------+          +-----------+         +-----------+
```

## 9.2 Technology Stack

| Layer | Technology | Rationale |
|-------|------------|-----------|
| Frontend | React 18 + TypeScript | Modern, typed, ecosystem |
| UI Framework | Ant Design / Material UI | Enterprise-grade components |
| API Gateway | Kong / AWS API Gateway | Rate limiting, auth |
| Backend Services | Node.js | Performance, ecosystem |
| Entity Storage | PostgreSQL 15 | ACID, bi-temporal support |
| Graph Storage | Neo4j | Relationships, traversal |
| Cache | Redis | Session, query cache |
| Document Storage | GCP Bucket Objects | Scalable, cost-effective |
| Event Streaming | Kafka | Change stream, decoupling |
| Search | Elasticsearch | Full-text, fuzzy matching |
| OCR | AWS Textract / Google Vision | High accuracy |
| Secret Management | HashiCorp Vault | Secure credentials |
| Monitoring | Datadog / Prometheus+Grafana | Observability |
| CI/CD | GitHub Actions | Automation |
| Infrastructure | Kubernetes (GKE/EKS) | Container orchestration |

---

# SECTION 10: IMPLEMENTATION PLAN

## 10.1 Phase Overview

| Phase | Focus | Key Deliverables |
|-------|-------|------------------|
| 0: Foundation | Infrastructure | CI/CD, environments, core scaffolding |
| 1: Entity Core | Data Model | Entity/Record CRUD, MER computation, bi-temporal |
| 2: Integration | Adapters | 9+ sources operational, health monitoring |
| 3: Entity Resolution | Matching | ER engine, review workflows, merge/split |
| 4: Data Quality | DQ Engine | Rules, remediation, dashboard |
| 5: Configuration | Self-Service | Mapping Studio, rule editors, promotion |
| 6: Manual Ingestion | OCR | Document management, verification |
| 7: API | Output | REST API, change stream, bulk export |
| 8: Security | Hardening | SSO, RBAC, encryption, audit |
| 9: UI | Frontend | All user interfaces |
| 10: Production | Go-Live | Load testing, deployment |

## 10.2 Milestone Summary

| Milestone | Key Deliverables |
|-----------|------------------|
| M0: Foundation Complete | Infrastructure, CI/CD, core scaffolding |
| M1: Entity Core Complete | Entity/Record CRUD, MER computation, bi-temporal |
| M2: Integration Layer Complete | 9 sources operational, health monitoring |
| M3: ER Complete | Matching engine, review workflows, merge/split |
| M4: DQ Complete | DQ rules, remediation, dashboard |
| M5: Config Complete | Mapping Studio, rule editors, promotion |
| M6: Manual Ingestion Complete | OCR, document management, verification |
| M7: API Complete | REST API, change stream, bulk export |
| M8: Security Complete | SSO, RBAC, encryption, audit |
| M9: UI Complete | All user interfaces |
| M10: Production Go-Live | Production deployment |

## 10.3 Definition of Done

### Feature Level
- Code complete and peer-reviewed
- Unit tests passing (>80% coverage)
- Integration tests passing
- API documented (OpenAPI)
- UI accessible (WCAG 2.1 AA)
- Performance within targets
- Security review passed
- Audit logging implemented
- Deployed to test environment
- Product Owner accepted

### Release Level
- All sprint DoDs met
- End-to-end testing passed
- Load testing passed
- Security penetration testing passed
- Runbooks documented
- Training completed
- Production deployment successful

## 10.4 Risk Register

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Registry API changes break adapters | High | High | Version adapters, monitor changelogs |
| OCR accuracy below target | Medium | Medium | Fallback to manual entry |
| ER false positive rate high | Medium | High | Conservative thresholds initially |
| Performance targets not met | Medium | High | Early load testing |
| RBAC complexity delays delivery | Medium | Medium | Start with simple roles |
| Bi-temporal queries slow | Medium | Medium | Indexed temporal columns |
| Source rate limiting blocks ingestion | High | Medium | Distributed rate limiters |
| Data migration issues | Medium | High | Dry run migrations |

## 10.5 Team Structure

| Role | Count | Responsibilities |
|------|-------|------------------|
| Product Owner | 1 | Requirements, priorities, acceptance |
| Tech Lead/Architect | 1 | Architecture, technical decisions |
| Backend Engineers | 4 | Services, APIs, adapters |
| Frontend Engineers | 2 | React UI development |
| Data Engineer | 1 | Schema, bi-temporal, performance |
| QA Engineer | 2 | Test automation, manual testing |
| DevOps/Platform | 1 | Infrastructure, CI/CD, monitoring |
| Data Steward (Domain) | 1 | Domain expertise, UAT |

---

# SECTION 11: REGISTRY COVERAGE

## 11.1 Registry Classification (135 registries)

| Tier | Count | Access | Coverage |
|------|-------|--------|----------|
| MVP (Tier 1) | ~35 | Free, no login | ~60% global |
| Tier 2 | ~15 | Free with registration | +20% |
| Future | ~70 | Paid/restricted | +20% |

## 11.2 MVP Scope (Tier 1)

**~35 registries qualify for MVP** (free access, no login required):
- **11 with REST/SOAP/XML APIs**: LEI, ABN, CRN, CIK, ICO, CVR, KRS, Japan Corporate Number, Korea TIN, Norway Org No, Ireland CRO
- **12 with Free Open Data/Portals**: Germany (Public Sector ID), Belgium (CBE), Luxembourg (RCS), Malta (MBR), Greece (AMF), Serbia (Trade & PIB), Croatia (Trade Register), Bosnia (MBS), Cyprus (Business + CBC), Denmark (CVR, FT-nummer), Poland (REGON)
- **12 with Free Web Search**: Bulgaria (BULSTAT), Finland (Y-tunnus), Czech Republic (ICO), Austria (free search), and others

## 11.3 Tier 2 (Post-MVP)

~15 registries requiring developer registration/API keys:
- UAE ERN, Canada BN, Finland Y-tunnus, Argentina CUIT, Brazil CNPJ, France SIREN, Latvia NBR, Lithuania JAR, Netherlands KvK, Poland REGON, Singapore UEN, Switzerland Zefix

## 11.4 Future Releases

**Deferred (~70 registries):**

1. **Individual PINs (~25)**: Out of scope - GRIP focuses on legal entities only
2. **Subscription-based (~25)**: BIC, Sweden Organisationsnummer, paid APIs
3. **Restricted/Login-Required (~35)**: Government-only, institutional access
4. **Manual-Only (~10)**: No programmatic API available

## 11.5 Adapter Priority List

### Supranational (First Priority)
| Source | API Type | Notes |
|--------|----------|-------|
| GLEIF | REST | Free, high quality, 3x daily updates |
| ECB RIAD | SDMX | Free, statistical data |

### High-Volume Jurisdictions
| Source | API Type | Notes |
|--------|----------|-------|
| UK Companies House | REST | Free, real-time streaming |
| Sweden Bolagsverket | REST/OAuth2 | Subscription, daily |
| Norway Brreg | REST | Free, open data leader |
| Netherlands KVK | REST | Subscription |
| Denmark CVR | Elasticsearch | Free, bulk |
| Finland PRH | REST | Free, open data |
| France INPI RNE | REST/FTP | Account required |

### Reference Registry Summary

| Jurisdiction | Primary Source | API | Priority |
|--------------|----------------|-----|----------|
| SE | Bolagsverket | REST/OAuth2 | 2 |
| UK | Companies House | REST | 2 |
| DE | Handelsregister | Manual | 6 |
| NL | KVK | REST | 2 |
| NO | Brreg | REST | 2 |
| DK | CVR | Elasticsearch | 2 |
| FI | PRH | REST | 2 |
| FR | INPI RNE | REST/FTP | 2 |
| Global | GLEIF | REST | 1 |
| Global | ECB RIAD | SDMX | 1 |

---

# APPENDIX A: Open Questions

| # | Question | Options | Decision |
|---|----------|---------|----------|
| 1 | Should OCR failures auto-create manual task or prompt user immediately? | A) Auto-create task B) Prompt immediately | TBD |
| 2 | Max number of results to show from search? | A) 10 B) 25 C) 50 with pagination | TBD |
| 3 | Allow bulk establish from search results? | A) Yes B) No, one at a time | TBD |
| 4 | Evidence document retention period? | A) 5 years B) 7 years C) Configurable | TBD |

---

**Total Requirements:** 120+ functional, 25+ non-functional
**Total Entities:** 17 core entities
**Registry Coverage:** 135 registries (35 MVP, 15 Tier 2, ~70 future)
