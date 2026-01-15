# GRIP v2.0 - Specification Suite

## Document Control
| Version | Date | Status |
|---------|------|--------|
| 2.0-DRAFT | 2025-01-15 | Under Review |

---

# PART 0: REVIEW FINDINGS

## 0.1 Identified Gaps

### Information Model Gaps
| ID | Gap | Impact | Resolution |
|----|-----|--------|------------|
| IM-G01 | No `RegistrySource` entity capturing registry metadata (API availability, cost model, refresh frequency) | Cannot operationalize registry selection or health monitoring | Add RegistrySource entity with attributes from registries_table.md |
| IM-G02 | Missing identifier format specifications per jurisdiction | Cannot validate incoming identifiers | Add BR: Identifier Format Rules per registry |
| IM-G03 | No Legal Form taxonomy/enumeration | Inconsistent entity type classification | Define LegalForm enum aligned with registry coverage |
| IM-G04 | Missing Address model (structured vs. unstructured) | Address matching and normalization undefined | Add Address composite type |
| IM-G05 | No Jurisdiction model distinguishing country/territory/supranational | GLEIF, ECB RIAD, BIC are supranational but treated as country-level | Add Jurisdiction entity with hierarchy |
| IM-G06 | Missing relationship types (parent/subsidiary, UBO, branch) | Cannot capture corporate structures | Add Relationship entity and type enum |
| IM-G07 | No specification for non-Latin character handling | Cannot process CJK, Cyrillic, Arabic names | Add transliteration/original-script attributes |

### Process Gaps
| ID | Gap | Impact | Resolution |
|----|-----|--------|------------|
| PR-G01 | No API failure/degradation handling | System fails silently on registry outages | Add exception subprocess in Party Maintenance |
| PR-G02 | Missing registry source decommissioning process | No way to phase out deprecated sources | Add Source Lifecycle process |
| PR-G03 | No process for cross-source data contradictions | Conflicts resolved arbitrarily | Add Conflict Resolution subprocess |
| PR-G04 | Missing escalation matrix | No ownership when STP fails | Add RACI and escalation paths |
| PR-G05 | No SLA definitions for processing times | Cannot measure operational performance | Add SLA targets per process step |
| PR-G06 | Missing entity lifecycle events (merger, split, dissolution) | Cannot track corporate actions | Add Entity Event taxonomy |

### Business Rule Gaps
| ID | Gap | Impact | Resolution |
|----|-----|--------|------------|
| BR-G01 | "3-year stale threshold" not justified by regulation | May not meet jurisdiction-specific refresh requirements | Map refresh requirements by jurisdiction (e.g., AMLD6 requires annual) |
| BR-G02 | "92% similarity" algorithm unspecified | Non-reproducible matching | Specify algorithm: Jaro-Winkler, with normalization rules |
| BR-G03 | No handling for same-entity-different-IDs across registries | Cannot link Company X in KVK to same in FI Institutnummer | Add Cross-Registry Linking rules |

---

## 0.2 Identified Conflicts

| ID | Conflict | Resolution |
|----|----------|------------|
| CF-01 | "Latest Trumps Quality" contradicts quality-first goals. A newer record with NULL values would overwrite valid data. | Revise to "Latest Non-Null Trumps" with explicit NULL-handling rules |
| CF-02 | PRD lists "FI Identifier" registries separately but processes treat them identically to business registers | Add FI-specific subprocess with additional regulatory attributes (MiFID status, CASP authorization) |
| CF-03 | Manual Ingestion AI-OCR step has no failure path | Add explicit "OCR Failed" branch with full-manual fallback |
| CF-04 | "Sourcing Mode: AUTOMATED vs. MANUAL" oversimplifies. 3rd-party API (e.g., Verifik for LATAM) is neither. | Add "SEMI-AUTOMATED" for broker/aggregator sources |

---

## 0.3 Identified Unclarities

| ID | Issue | Clarification Needed |
|----|-------|---------------------|
| UC-01 | "Golden Record" - definition is circular ("Best Version") | Define explicitly: "The composite record where each attribute is selected by applying field-level survivorship rules to all linked Registry Records" |
| UC-02 | "STP Selection" - criteria incomplete | Specify full decision table: what combinations yield STP vs. Review |
| UC-03 | "Quality Health Flag" values (CLEAN/WARNING/CRITICAL) have no threshold definitions | Define thresholds: CLEAN = 0 DQ issues, WARNING = 1-3 issues, CRITICAL = >3 or blocking issue |
| UC-04 | "Attribute Locks" - who can set/unset? | Specify: Data Steward role only, via Mapping Studio UI |
| UC-05 | "Deep Link to raw evidence" - retention period? | Specify: Evidence retained for regulatory minimum (typically 5-7 years post-relationship) |

---

## 0.4 Corporate/AI Slop Removed

| Original Term | Replacement |
|---------------|-------------|
| "Golden Record" | "Master Entity Record" (MER) |
| "Best Version" | "Computed attribute set per survivorship rules" |
| "360-degree view" | "Entity Detail View" |
| "Governor" role name | "Data Steward" |
| "Remediator" role name | "Data Operations Analyst" |
| "Source-to-Master matrix" | "Attribute Lineage Table" |
| "Deep Link" | "Evidence URI" |
| "Party" (ambiguous) | "Legal Entity" |

---

## 0.5 Registry Table Analysis Summary

From `registries_table.md` (135 registries across 60+ jurisdictions):

| Registry Type | Count | API Available | Notes |
|---------------|-------|---------------|-------|
| Business Register | 68 | 45 (66%) | Primary KYB source |
| Tax Identification | 32 | 12 (38%) | Often restricted access |
| FI Identifier | 18 | 14 (78%) | Includes BIC, LEI, GIIN, FT-nummer |
| Individual ID (PIN) | 17 | 3 (18%) | Highly restricted, out of scope for automation |

**Key Observations:**
- 23 registries have NO programmatic access (manual-only)
- 15 registries require paid subscriptions/contracts
- 8 registries provide change/delta feeds (critical for maintenance)
- Supranational sources (GLEIF, ECB RIAD, BIC) provide highest automation potential

### MVP Scope - Free & No-Login Registries (TIER 1)

**~35 registries qualify for MVP** (free access, no login required, no subscription):
- **11 with REST/SOAP/XML APIs**: LEI, ABN, CRN, CIK, ICO, CVR, KRS, Japan Corporate Number, Korea TIN, Norway Org No, Ireland CRO
- **12 with Free Open Data/Portals**: Germany (Handelsregister, Public Sector ID), Belgium (CBE), Luxembourg (RCS), Malta (MBR), Greece (AMF), Serbia (Trade & PIB), Croatia (Trade Register), Bosnia (MBS), Cyprus (Business + CBC), Denmark (CVR, FT-nummer), Poland (REGON)
- **12 with Free Web Search**: Bulgaria (BULSTAT), Finland (Y-tunnus), Czech Republic (ICO), Austria (Handelsregister free search), Luxembourg, Malta, Serbia, Croatia, Greece, Cyprus, Bosnia, Denmark

**MVP Coverage**: ~60% of global business entity coverage, includes LEI (global), G7/G20 economies, EU core, and free web search options for scaled coverage.

**Access Model**: All free (no subscription, no login, no institutional agreements). Includes automated APIs, open data downloads, and free web portals.

### Tier 2 Scope - Free with Registration (DEFERRED POST-MVP)

~15 registries remain free but require developer registration, API keys, or basic setup:
- UAE ERN (free marketplace account)
- Canada BN (free developer registration)
- Finland Y-tunnus (API key registration)
- Argentina CUIT (portal registration, free)
- Brazil CNPJ (registration for enhanced features)
- France SIREN (account required for daily API)
- Latvia NBR (API manager login)
- Lithuania JAR (RC service contracts, core free)
- Netherlands KvK (negotiate free tier)
- Poland REGON (free GUS API, keys via portal)
- Singapore UEN (free search tier)
- Switzerland Zefix (registration for API)

**Strategy**: Handle after MVP foundation stabilizes; requires adapter-specific registration/setup but remains cost-free.

### Future Releases Scope - Paid/Restricted (OUT OF MVP)

**~70 registries deferred to future roadmap**:

**Subscription-based** (~25): BIC (Swift), Sweden Organisationsnummer, Austria OeNB, Bosnia JIB, Belarus USR, Brazil SERPRO API, Estonia contract required, Taiwan NT$10/query, Hong Kong HK$500/year, etc.

**Restricted/Login-Required** (~35): Individual PINs (Personnummer, PIN, BSN, PESEL, CPR-nummer, SSN, etc.), restricted tax IDs (Austria, Belgium, Germany Steuernummer, Luxembourg Matricule, etc.), Central Bank systems, government-only databases.

**Manual-Only/No API** (~10): Bermuda ROC, Bahamas, Isle of Man, Guernsey, Marshall Islands, Liechtenstein, Malta (manual-only), Thailand, Turkey, Monaco (manual-only)

**Rationale for Deferral**:
1. **Individual PINs are out of scope per PRD** - GRIP focuses on legal entities, not individuals
2. **Subscription complexity** - Contracts, payment processing, per-entity fees don't scale for MVP
3. **Restricted access** - Requires legal frameworks, institutional agreements, or compliance certifications
4. **Manual-only** - Would require web scraping or manual portal access at scale
4. **Third-party dependency** - Broker reliance (Verifik, Apitude for LATAM) requires licensing negotiations

---

## 0.6 MVP/Tier Coverage Verification

✅ **Confirmed**: All ~35 free registries (APIs + free search/open data) ARE in MVP scope
✅ **Confirmed**: No free registries are deferred to Future
✅ **Confirmed**: All Tier 2 (free with registration) identified for post-MVP
✅ **Confirmed**: ~70 non-free/restricted registries explicitly deferred to Future

**Coverage Gap Analysis**:
- TIER 1 (MVP): 35 registries = ~60% business entity coverage globally
- TIER 2 (Q2 2025): +15 registries = ~80% coverage
- Future (enterprise tier): +70 registries = remaining 20% + specialized needs

---

# PART 1: DATA OWNER-STEWARD SPECIFICATION
**Owner:** Data Steward / Information Architect

## 1.1 Ontology

### 1.1.1 Core Concepts

```
+------------------+       1..*        +-------------------+
|   LegalEntity    |<----------------->|  RegistryRecord   |
+------------------+                   +-------------------+
| entity_id: UUID  |                   | record_id: UUID   |
| created_ts       |                   | source_id: FK     |
| status: enum     |                   | valid_from_source |
+------------------+                   | ingestion_ts      |
        |                              | sourcing_mode     |
        |                              | sourcing_method   |
        | computes                     | raw_payload: JSON |
        v                              +-------------------+
+-------------------+                          |
| MasterEntityRec   |<-------------------------+
+-------------------+     survivorship
| mer_id: UUID      |
| entity_id: FK     |
| computed_ts       |
| [attributes...]   |
+-------------------+

+-------------------+       provides        +------------------+
|  RegistrySource   |<--------------------->| RegistryRecord   |
+-------------------+                       +------------------+
| source_id: UUID   |
| jurisdiction: FK  |
| registry_type     |
| api_available     |
| cost_model        |
| refresh_frequency |
| identifier_format |
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
```

### 1.1.2 Entity Definitions

| Entity | Definition | Primary Key |
|--------|------------|-------------|
| LegalEntity | An organization recognized by law as having rights and obligations. Internal master reference. | entity_id (UUID) |
| RegistryRecord | An immutable point-in-time snapshot of data retrieved from a single registry source. Never updated, only superseded. | record_id (UUID) |
| MasterEntityRecord | The computed "best" attribute set for a LegalEntity, derived by applying survivorship rules across all linked RegistryRecords. Recomputed on each ingestion. | mer_id (UUID) |
| RegistrySource | Metadata about an external registry: access method, cost, jurisdiction, data model. | source_id (UUID) |
| Jurisdiction | Geographic or regulatory scope. Supports hierarchy (e.g., supranational > country > territory). | jurisdiction_id |

---

## 1.2 Information Model

### 1.2.1 LegalEntity Attributes

| Attribute | Type | Cardinality | Source | Notes |
|-----------|------|-------------|--------|-------|
| entity_id | UUID | 1 | System | Immutable |
| internal_ref | String(50) | 0..1 | Internal | Optional business key |
| status | Enum | 1 | Computed | ACTIVE, INACTIVE, DISSOLVED, MERGED |
| created_ts | Timestamp | 1 | System | Entity creation |
| last_computed_ts | Timestamp | 1 | System | Last MER computation |

### 1.2.2 RegistryRecord Attributes

| Attribute | Type | Cardinality | Source | Notes |
|-----------|------|-------------|--------|-------|
| record_id | UUID | 1 | System | Immutable |
| entity_id | UUID FK | 1 | ER Engine | Link to LegalEntity |
| source_id | UUID FK | 1 | System | Link to RegistrySource |
| valid_from_source | Date | 0..1 | Registry | When registry says change occurred |
| ingestion_ts | Timestamp | 1 | System | When system received data |
| sourcing_mode | Enum | 1 | System | AUTOMATED, SEMI_AUTOMATED, MANUAL |
| sourcing_method | Enum | 1 | System | API, FILE, AGENT, OCR, HUMAN |
| stale_flag | Boolean | 1 | Computed | True if >3 years since ingestion with no refresh |
| quality_flag | Enum | 1 | DQ Engine | CLEAN, WARNING, CRITICAL |
| raw_payload | JSON | 1 | System | Original response, immutable |

### 1.2.3 MasterEntityRecord Attributes (Computed)

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

### 1.2.4 RegistrySource Attributes

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
| last_health_check | Timestamp | System | |
| health_status | Enum | System | HEALTHY, DEGRADED, DOWN |

### 1.2.5 Address Composite Type

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

### 1.2.6 LegalForm Enumeration (Partial)

| Code | Name | Jurisdiction | Notes |
|------|------|--------------|-------|
| SE_AB | Aktiebolag | SE | Swedish limited company |
| SE_HB | Handelsbolag | SE | Swedish general partnership |
| DE_GMBH | GmbH | DE | German limited liability |
| UK_LTD | Private Limited | GB | UK private limited |
| US_LLC | Limited Liability Company | US | US LLC |
| GLOBAL_FUND | Investment Fund | SUPRANATIONAL | UCITS/AIF |

---

## 1.3 Business Rules (Data Domain)

### BR-DM-001: Identifier Format Validation

| Registry | Format | Regex | Example |
|----------|--------|-------|---------|
| SE Organisationsnummer | NNNNNN-NNNN | `^\d{6}-\d{4}$` | 556123-4567 |
| LEI | 20 alphanumeric | `^[A-Z0-9]{20}$` | 5493001KJTIIGC8Y1R12 |
| UK CRN | 8 digits or 2 letters + 6 digits | `^([0-9]{8}\|[A-Z]{2}[0-9]{6})$` | 12345678, SC123456 |
| NL KvK-nummer | 8 digits | `^\d{8}$` | 12345678 |
| US EIN | NN-NNNNNNN | `^\d{2}-\d{7}$` | 12-3456789 |
| GIIN | 6 chars.5 chars.LE.NNN | `^[A-Z0-9]{6}\.[A-Z0-9]{5}\.LE\.\d{3}$` | ABC123.12345.LE.001 |

### BR-DM-002: Survivorship Rules

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

### BR-DM-003: Stale Data Threshold

| Jurisdiction | Regulatory Basis | Threshold |
|--------------|------------------|-----------|
| EU (AMLD6) | Art. 30 | 12 months |
| UK (MLR 2017) | Reg 28 | 12 months |
| US (CDD Rule) | 31 CFR 1010.230 | Risk-based (12-36 months) |
| Default | Internal Policy | 36 months |

**Rule:** `stale_flag = TRUE WHERE (NOW() - last_refresh_ts) > jurisdiction_threshold`

### BR-DM-004: Quality Flag Computation

| Condition | Flag |
|-----------|------|
| All mandatory fields present, no DQ issues | CLEAN |
| 1-3 minor DQ issues (e.g., format warnings) | WARNING |
| >3 issues OR missing mandatory field OR logical contradiction | CRITICAL |

### BR-DM-005: Source Priority (Default)

| Priority | Source Type | Rationale |
|----------|-------------|-----------|
| 1 | Supranational (GLEIF, ECB RIAD) | Standardized, validated |
| 2 | Primary Business Register (e.g., Companies House, Bolagsverket) | Legal authority |
| 3 | Tax Authority Register | Authoritative for tax ID |
| 4 | Financial Supervisor (FCA, FI.se) | Authoritative for FI status |
| 5 | Semi-Automated (3rd-party aggregators) | Derived data |
| 6 | Manual (OCR, Human entry) | Lowest confidence |

---

## 1.4 Data Quality Rules

### DQ-001: Mandatory Field Completeness

| Field | Mandatory For | Exception |
|-------|---------------|-----------|
| legal_name | All | None |
| registration_number | All | Sole traders in some jurisdictions |
| jurisdiction | All | None |
| legal_form | All | None |
| incorporation_date | Companies | Not required for partnerships |

### DQ-002: Cross-Field Validation

| Rule ID | Condition | Severity |
|---------|-----------|----------|
| DQ-002-A | IF status = DISSOLVED THEN dissolution_date IS NOT NULL | WARNING |
| DQ-002-B | IF jurisdiction = 'SE' THEN registration_number MATCHES SE format | CRITICAL |
| DQ-002-C | incorporation_date <= NOW() | CRITICAL |
| DQ-002-D | IF lei IS NOT NULL THEN lei passes checksum | CRITICAL |

---

# PART 2: PROCESS OWNER SPECIFICATION
**Owner:** Process Owner / Business Analyst

## 2.1 Process Landscape (BPMN Level 1)

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

---

## 2.2 Process Specifications (BPMN Level 2)

### P1: Entity Establishment

**Purpose:** Create a new LegalEntity and populate it with RegistryRecords from available sources.

**Trigger:** Internal system request containing: search criteria (name, jurisdiction, registration number)

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

---

### P2: Entity Maintenance

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

**Business Rules:**
- BR-PM-001: Retry failed API calls 3 times with exponential backoff
- BR-PM-002: If source fails >5 consecutive times, mark source DEGRADED
- BR-PM-003: Delta conflicts (>50% name change) route to Conflict Queue

---

### P3: Entity Resolution

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

---

### P4: Data Quality Management

**Purpose:** Detect, track, and remediate data quality issues.

**Issue Taxonomy:**

| Category | Code | Description | Auto-Resolve |
|----------|------|-------------|--------------|
| Completeness | DQ-COMP-001 | Mandatory field missing | No |
| Format | DQ-FMT-001 | Identifier fails regex | Yes (if correctable) |
| Consistency | DQ-CON-001 | Cross-field validation fail | No |
| Currency | DQ-CUR-001 | Record stale | Trigger refresh |
| Accuracy | DQ-ACC-001 | Value contradicts trusted source | Review |

---

### P5: Source Onboarding

**Purpose:** Configure a new registry source for automated or semi-automated ingestion.

**Stages:**
1. **Discovery:** Document source from registries_table.md
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

---

### P6: Source Health Monitoring

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

---

## 2.3 RACI Matrix

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

# PART 3: PRODUCT OWNER/UX SPECIFICATION
**Owner:** Product Owner / UX Designer

## 3.1 User Personas

### Persona 1: Data Steward ("The Architect")
- **Goals:** Maintain data model integrity, optimize STP rates, ensure regulatory compliance
- **Pain Points:** Manual mapping is tedious, hard to trace why attributes were selected
- **Frequency:** Daily, 2-4 hours in system

### Persona 2: Data Operations Analyst ("The Remediator")
- **Goals:** Clear work queue, minimize manual entry errors, meet SLA targets
- **Pain Points:** Too many clicks to resolve a match, OCR failures require re-work
- **Frequency:** Daily, 6-8 hours in system

### Persona 3: Compliance Officer ("The Auditor")
- **Goals:** Prove data lineage for any point in time, demonstrate refresh compliance
- **Pain Points:** Cannot easily generate audit reports, lineage visualization unclear
- **Frequency:** Weekly, 1-2 hours + audit periods

---

## 3.2 User Stories

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

---

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

---

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

---

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

---

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

## 3.3 Feature Specifications (BPMN Level 3 Detail)

### F1: Entity Search & Establish

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

---

### F2: Attribute Lineage Table

**Wireframe:**

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

---

### F3: Mapping Studio

**Wireframe:**

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

---

### F4: Registry Health Dashboard

**Wireframe:**

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

## 3.4 Non-Functional Requirements

| Requirement | Target | Measurement |
|-------------|--------|-------------|
| Search Response Time | < 3 seconds (p95) | Application Performance Monitoring |
| Page Load Time | < 2 seconds | Lighthouse |
| Concurrent Users | 50 | Load testing |
| Data Export | < 30 seconds for 10k entities | Timed test |
| Accessibility | WCAG 2.1 AA | Automated audit + manual review |
| Browser Support | Chrome, Edge, Firefox (latest 2 versions) | E2E tests |

---

## 3.5 Open Questions for Product Owner

| # | Question | Options | Decision |
|---|----------|---------|----------|
| 1 | Should OCR failures auto-create manual task or prompt user immediately? | A) Auto-create task B) Prompt immediately | TBD |
| 2 | Max number of results to show from search? | A) 10 B) 25 C) 50 with pagination | TBD |
| 3 | Allow bulk establish from search results? | A) Yes B) No, one at a time | TBD |
| 4 | Evidence document retention period? | A) 5 years B) 7 years C) Configurable | TBD |

---

# APPENDIX A: Glossary

| Term | Definition |
|------|------------|
| CDM | Common Data Model - the canonical schema for entity attributes |
| ER | Entity Resolution - the process of determining if two records refer to the same real-world entity |
| LEI | Legal Entity Identifier - ISO 17442 20-character alphanumeric code |
| MER | Master Entity Record - the computed attribute set for a Legal Entity |
| STP | Straight-Through Processing - automated resolution without human review |
| Survivorship | The rules determining which source value wins when multiple sources provide the same attribute |

---

# APPENDIX B: Registry Source Reference (Summary)

| Jurisdiction | Primary Source | API | Refresh | Priority |
|--------------|----------------|-----|---------|----------|
| SE | Bolagsverket | REST/OAuth2 | Daily | 2 |
| UK | Companies House | REST | Real-time | 2 |
| DE | Handelsregister | Manual | On-demand | 6 |
| NL | KVK | REST | Continuous | 2 |
| NO | Brreg | REST | Delta API | 2 |
| DK | CVR | Elasticsearch | Daily | 2 |
| FI | PRH | REST | Daily | 2 |
| FR | INPI RNE | REST/FTP | Daily | 2 |
| Global | GLEIF | REST | 3x daily | 1 |
| Global | ECB RIAD | SDMX | Nightly | 1 |

*(Full list: 135 sources in registries_table.md)*

---

# APPENDIX C: Change Log

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 2.0-DRAFT | 2025-01-15 | [Review] | Initial restructure from PRD v1; addressed gaps CF-01 through CF-04; removed slop terminology |
