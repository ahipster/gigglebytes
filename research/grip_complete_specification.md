# GRIP v2.0 - Complete Platform Specification & Implementation Plan

## Document Control
| Version | Date | Status | Classification |
|---------|------|--------|----------------|
| 2.1-COMPLETE | 2025-01-15 | Final Draft | Internal |

---

# SECTION A: DEEP CAPABILITY ANALYSIS

## A.1 Platform Intent Decomposition

### A.1.1 Primary Intents (What the platform MUST do)

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

### A.1.2 Intent-to-Capability Traceability Matrix

| Intent | Required Capabilities | Information Model | Processes | UI Features |
|--------|----------------------|-------------------|-----------|-------------|
| INT-001 | Registry Adapters, Scheduler, Queue, Error Handling | RegistrySource, RegistryRecord, IngestionJob | P1, P2, P5, P6 | Health Dashboard |
| INT-002 | Survivorship Engine, MER Computation | LegalEntity, MasterEntityRecord | P1, P2, P3 | Entity Detail View |
| INT-003 | Bi-temporal Storage, Temporal Query Engine | All entities with valid_from/valid_to + system_ts | P2 | History View, Point-in-Time |
| INT-004 | ER Engine, Matching Algorithms, Review Queue | MatchCandidate, MatchDecision, NegativeMatch | P3 | ER Review Screen |
| INT-005 | Survivorship Rules Engine, Lock Management | SurvivorshipRule, AttributeLock | P2, Config | Mapping Studio |
| INT-006 | DQ Rules Engine, Issue Tracking, Auto-remediation | DQIssue, DQRule, RemediationAction | P4 | DQ Dashboard |
| INT-007 | OCR Service, Document Storage, Verification Workflow | Document, OCRResult, VerificationTask | P2 (Manual) | OCR Upload, Verification UI |
| INT-008 | Immutable Audit Log, Snapshot Generator, Crypto Signing | AuditEvent, Snapshot | All | Lineage View, Export |
| INT-009 | Health Checker, Alerting, Metrics Collection | SourceHealthMetric, Alert | P6 | Health Dashboard |
| INT-010 | Mapping Studio, Rule Editor, Version Control | MappingConfig, ERRule, ConfigVersion | P5 | Config Studio |

---

## A.2 Complete Capability Inventory

### A.2.1 Data Management Capabilities

| CAP ID | Capability | Description | Status in PRD |
|--------|------------|-------------|---------------|
| CAP-DM-001 | Entity Lifecycle Management | Create, update, merge, deactivate entities | Partial - missing merge/deactivate |
| CAP-DM-002 | Record Ingestion Pipeline | Receive, validate, store registry records | Defined |
| CAP-DM-003 | Survivorship Computation Engine | Apply rules to compute MER | Defined |
| CAP-DM-004 | Bi-temporal Query Support | Query by valid-time and/or system-time | Missing - only mentioned |
| CAP-DM-005 | Data Quality Engine | Detect, classify, track DQ issues | Partial |
| CAP-DM-006 | Bulk Data Operations | Import/export large datasets | Missing |
| CAP-DM-007 | Data Retention Management | Archive/purge per policy | Missing |
| CAP-DM-008 | Cross-Registry Identifier Linking | Link same entity across different registries | Missing |
| CAP-DM-009 | Entity Relationship Management | Track parent/subsidiary/UBO relationships | Missing |
| CAP-DM-010 | Name Normalization Service | Standardize names across scripts/formats | Partial |

### A.2.2 Integration Capabilities

| CAP ID | Capability | Description | Status in PRD |
|--------|------------|-------------|---------------|
| CAP-INT-001 | REST Adapter Framework | Connect to REST APIs with auth | Implied |
| CAP-INT-002 | SOAP Adapter Framework | Connect to SOAP/WSDL services | Missing |
| CAP-INT-003 | SDMX Adapter Framework | Connect to statistical data APIs (ECB) | Missing |
| CAP-INT-004 | File Ingestion (FTP/SFTP) | Download bulk files | Mentioned |
| CAP-INT-005 | Delta/Change Feed Consumer | Process incremental updates | Mentioned |
| CAP-INT-006 | Web Scraping Agent Framework | Extract from web portals | Mentioned as "Agent" |
| CAP-INT-007 | OCR Document Processing | Extract text from images/PDFs | Mentioned |
| CAP-INT-008 | API Rate Limiting | Respect source rate limits | Missing |
| CAP-INT-009 | Credential/Secret Management | Secure API keys/certs | Missing |
| CAP-INT-010 | Adapter Health Probing | Test source connectivity | Partial |

### A.2.3 Workflow/Process Capabilities

| CAP ID | Capability | Description | Status in PRD |
|--------|------------|-------------|---------------|
| CAP-WF-001 | Task Queue Management | Create, assign, prioritize tasks | Mentioned |
| CAP-WF-002 | SLA Monitoring & Alerting | Track task aging, alert on breach | Mentioned |
| CAP-WF-003 | Escalation Automation | Auto-escalate overdue tasks | Partial |
| CAP-WF-004 | Batch Job Scheduling | Schedule recurring jobs | Implied |
| CAP-WF-005 | Manual Review Workflow | Maker-checker for sensitive ops | Mentioned |
| CAP-WF-006 | Conflict Resolution Workflow | Handle contradictory data | Partial |
| CAP-WF-007 | Approval Workflow | Approve config changes | Missing |
| CAP-WF-008 | Notification Service | Email/in-app notifications | Missing |

### A.2.4 Entity Resolution Capabilities

| CAP ID | Capability | Description | Status in PRD |
|--------|------------|-------------|---------------|
| CAP-ER-001 | Deterministic Matching | Exact match on identifiers | Defined |
| CAP-ER-002 | Probabilistic Matching | Fuzzy match with scoring | Defined |
| CAP-ER-003 | Name Similarity Algorithms | Jaro-Winkler, Levenshtein, etc. | Mentioned |
| CAP-ER-004 | Transliteration Service | Convert scripts to Latin | Mentioned |
| CAP-ER-005 | Legal Form Suffix Removal | Strip "Ltd", "GmbH", etc. | Mentioned |
| CAP-ER-006 | Negative Match Registry | "Never the same" blocking | Mentioned |
| CAP-ER-007 | Match Candidate Scoring | Compute confidence scores | Implied |
| CAP-ER-008 | Cluster Management | Group potential duplicates | Missing |
| CAP-ER-009 | Merge Execution | Combine two entities | Missing |
| CAP-ER-010 | Unmerge/Split Capability | Reverse incorrect merges | Missing |

### A.2.5 Configuration Capabilities

| CAP ID | Capability | Description | Status in PRD |
|--------|------------|-------------|---------------|
| CAP-CFG-001 | Source Schema Registration | Define source data structures | Implied |
| CAP-CFG-002 | Field Mapping Editor | Map source→CDM | Defined |
| CAP-CFG-003 | Transformation Functions | Lookup, concat, conditional | Mentioned |
| CAP-CFG-004 | Survivorship Rule Editor | Configure attribute priorities | Mentioned |
| CAP-CFG-005 | ER Rule Configuration | Set matching weights/thresholds | Defined |
| CAP-CFG-006 | DQ Rule Configuration | Define validation rules | Partial |
| CAP-CFG-007 | Configuration Versioning | Track config changes | Mentioned |
| CAP-CFG-008 | Configuration Promotion | Dev→Test→Prod | Missing |
| CAP-CFG-009 | Lookup Table Management | Manage code mappings | Implied |
| CAP-CFG-010 | Jurisdiction Configuration | Define jurisdiction attributes | Partial |

### A.2.6 Monitoring & Observability Capabilities

| CAP ID | Capability | Description | Status in PRD |
|--------|------------|-------------|---------------|
| CAP-MON-001 | Source Health Monitoring | API availability, response time | Defined |
| CAP-MON-002 | Ingestion Metrics | Records processed, error rates | Implied |
| CAP-MON-003 | DQ Metrics Dashboard | Issue counts by category | Mentioned |
| CAP-MON-004 | SLA Performance Dashboard | Task completion rates | Mentioned |
| CAP-MON-005 | Audit Event Logging | All user/system actions | Mentioned |
| CAP-MON-006 | Operational Alerting | PagerDuty/Slack integration | Missing |
| CAP-MON-007 | Usage Analytics | User activity tracking | Missing |
| CAP-MON-008 | Capacity Planning Metrics | Storage, throughput trends | Missing |

### A.2.7 Security & Access Control Capabilities

| CAP ID | Capability | Description | Status in PRD |
|--------|------------|-------------|---------------|
| CAP-SEC-001 | User Authentication | SSO/OIDC integration | Missing |
| CAP-SEC-002 | Role-Based Access Control | Steward, Ops, Admin roles | Implied |
| CAP-SEC-003 | Data-Level Authorization | Jurisdiction-based access | Missing |
| CAP-SEC-004 | API Authentication | OAuth2/API keys for consumers | Missing |
| CAP-SEC-005 | Audit Trail Immutability | Tamper-proof logging | Mentioned |
| CAP-SEC-006 | Data Encryption at Rest | Encrypt sensitive fields | Missing |
| CAP-SEC-007 | Data Encryption in Transit | TLS everywhere | Missing |
| CAP-SEC-008 | PII Masking | Mask sensitive data in logs/UI | Missing |

### A.2.8 API & Integration Output Capabilities

| CAP ID | Capability | Description | Status in PRD |
|--------|------------|-------------|---------------|
| CAP-API-001 | Entity Query API | Search/retrieve entities | Mentioned |
| CAP-API-002 | Entity Change Stream | Real-time change notifications | Mentioned |
| CAP-API-003 | Bulk Export API | Extract large datasets | Implied |
| CAP-API-004 | Point-in-Time Query API | Historical state retrieval | Implied |
| CAP-API-005 | Webhook Notifications | Push events to subscribers | Missing |
| CAP-API-006 | GraphQL API | Flexible querying | Missing |
| CAP-API-007 | API Versioning | Support multiple versions | Missing |
| CAP-API-008 | API Rate Limiting | Protect from abuse | Missing |

---

## A.3 Gap Analysis: Missing Requirements

### A.3.1 Critical Gaps (Must Have)

| Gap ID | Missing Element | Domain | Impact | Required For |
|--------|-----------------|--------|--------|--------------|
| GAP-C01 | Entity Merge Process | Process | Cannot consolidate duplicates | INT-004 |
| GAP-C02 | Entity Unmerge/Split | Process | Cannot fix merge errors | INT-004 |
| GAP-C03 | Bi-temporal Query API | Data | Cannot reconstruct history | INT-003, INT-008 |
| GAP-C04 | SOAP/SDMX Adapters | Integration | Cannot connect to 30% of sources | INT-001 |
| GAP-C05 | Credential Management | Security | Cannot securely store API keys | INT-001 |
| GAP-C06 | RBAC Implementation | Security | Cannot control access | All |
| GAP-C07 | Cross-Registry Linking | Data | Cannot link same entity across registries | INT-002 |
| GAP-C08 | Relationship Model | Data | Cannot capture corporate structures | INT-002 |
| GAP-C09 | Configuration Promotion | Config | Cannot safely deploy changes | INT-010 |
| GAP-C10 | Entity Event Model | Data | Cannot track mergers/dissolutions | INT-002 |

### A.3.2 Important Gaps (Should Have)

| Gap ID | Missing Element | Domain | Impact |
|--------|-----------------|--------|--------|
| GAP-I01 | Operational Alerting Integration | Monitoring | Manual detection of issues |
| GAP-I02 | Data Retention/Archival | Data | Unbounded storage growth |
| GAP-I03 | Bulk Import UI | UI | IT-dependent for large loads |
| GAP-I04 | Webhook Notifications | API | Polling-only for consumers |
| GAP-I05 | API Rate Limiting (outbound) | Integration | Risk of source blocking |
| GAP-I06 | Configuration Audit Log | Config | Cannot trace config changes |
| GAP-I07 | User Activity Analytics | Monitoring | Cannot optimize UX |
| GAP-I08 | Cluster/Duplicate Detection | ER | Reactive-only deduplication |

### A.3.3 Nice-to-Have Gaps

| Gap ID | Missing Element | Domain |
|--------|-----------------|--------|
| GAP-N01 | GraphQL API | API |
| GAP-N02 | Mobile-responsive UI | UI |
| GAP-N03 | Natural Language Search | UI |
| GAP-N04 | ML-based ER scoring | ER |
| GAP-N05 | Self-service Reporting | Analytics |

---

## A.4 Information Model Completeness Check

### A.4.1 Missing Entities

| Entity | Purpose | Attributes |
|--------|---------|------------|
| **IngestionJob** | Track batch ingestion runs | job_id, source_id, status, started_ts, completed_ts, records_processed, errors |
| **MatchCandidate** | Store potential matches for review | candidate_id, source_record_id, target_entity_id, score, status, reviewer_id |
| **MatchDecision** | Audit match decisions | decision_id, candidate_id, decision (LINK/REJECT/SPLIT), decided_by, decided_ts, reason |
| **NegativeMatch** | Block future matching | block_id, entity_a_id, entity_b_id, created_by, created_ts, reason |
| **DQIssue** | Track data quality issues | issue_id, entity_id, record_id, rule_id, severity, status, detected_ts, resolved_ts |
| **DQRule** | Define validation rules | rule_id, name, category, condition, severity, auto_remediate |
| **Document** | Store uploaded evidence | doc_id, entity_id, filename, mime_type, storage_uri, uploaded_by, uploaded_ts |
| **OCRResult** | Store OCR extraction results | ocr_id, doc_id, extracted_data (JSON), confidence_scores, reviewed_by |
| **Task** | Generic task queue | task_id, type, entity_id, priority, status, assigned_to, due_ts, created_ts, completed_ts |
| **EntityEvent** | Track corporate events | event_id, entity_id, event_type, event_date, details (JSON), source_id |
| **EntityRelationship** | Track entity relationships | rel_id, parent_entity_id, child_entity_id, relationship_type, valid_from, valid_to |
| **ConfigVersion** | Version control for configs | version_id, config_type, config_data, created_by, created_ts, promoted_ts |
| **AuditEvent** | Immutable audit log | event_id, event_type, actor_id, entity_id, before_state, after_state, timestamp |
| **Alert** | Operational alerts | alert_id, type, severity, source_id, message, acknowledged_by, acknowledged_ts |
| **UserSession** | Track user activity | session_id, user_id, started_ts, last_activity_ts, ip_address |
| **APIConsumer** | Track API consumers | consumer_id, name, api_key_hash, rate_limit, enabled |
| **Snapshot** | Point-in-time exports | snapshot_id, entity_id, as_of_ts, data (JSON), checksum, generated_ts |

### A.4.2 Missing Enumerations

| Enum | Values |
|------|--------|
| **EntityEventType** | INCORPORATION, NAME_CHANGE, ADDRESS_CHANGE, STATUS_CHANGE, MERGER, ACQUISITION, SPLIT, DISSOLUTION, LIQUIDATION, REDOMICILIATION |
| **RelationshipType** | PARENT, SUBSIDIARY, BRANCH, UBO, DIRECTOR, SHAREHOLDER, FUND_MANAGER |
| **TaskType** | MANUAL_REFRESH, ER_REVIEW, DQ_REMEDIATION, OCR_VERIFICATION, CONFLICT_RESOLUTION |
| **TaskStatus** | PENDING, IN_PROGRESS, ON_HOLD, COMPLETED, CANCELLED, ESCALATED |
| **MatchDecisionType** | AUTO_LINKED, MANUAL_LINKED, REJECTED, SPLIT, DEFERRED |
| **DQCategory** | COMPLETENESS, FORMAT, CONSISTENCY, CURRENCY, ACCURACY, UNIQUENESS |
| **AlertSeverity** | INFO, WARNING, ERROR, CRITICAL |
| **ConfigType** | MAPPING, SURVIVORSHIP, ER_RULE, DQ_RULE, SOURCE_CONFIG |

### A.4.3 Missing Attributes on Existing Entities

| Entity | Missing Attribute | Type | Purpose |
|--------|-------------------|------|---------|
| LegalEntity | merged_into_id | UUID FK | Track merged entities |
| LegalEntity | merge_ts | Timestamp | When merged |
| LegalEntity | risk_rating | Enum | Business criticality |
| LegalEntity | last_verified_ts | Timestamp | Last human verification |
| RegistryRecord | superseded_by_id | UUID FK | Link to newer record |
| RegistryRecord | verification_status | Enum | UNVERIFIED, VERIFIED, REJECTED |
| RegistrySource | rate_limit_requests | Integer | Max requests per period |
| RegistrySource | rate_limit_period_seconds | Integer | Rate limit window |
| RegistrySource | auth_type | Enum | NONE, API_KEY, OAUTH2, CERT, BASIC |
| RegistrySource | auth_config | JSON | Auth credentials (encrypted ref) |
| MasterEntityRecord | version | Integer | Computation version |
| MasterEntityRecord | dq_score | Decimal | Overall quality score |

---

## A.5 Process Completeness Check

### A.5.1 Missing Processes

| Process | Purpose | Trigger | Owner |
|---------|---------|---------|-------|
| **P7: Entity Merge** | Combine duplicate entities | ER decision | Data Ops |
| **P8: Entity Split/Unmerge** | Separate incorrectly merged entities | User request | Data Steward |
| **P9: Corporate Event Processing** | Handle mergers, acquisitions, dissolutions | Registry notification or manual | System/Data Ops |
| **P10: Configuration Deployment** | Promote config changes through environments | Steward approval | IT/Steward |
| **P11: Bulk Data Import** | Load large datasets | Admin request | IT |
| **P12: Data Archival** | Move old data to cold storage | Schedule | System |
| **P13: User Access Management** | Grant/revoke user permissions | Admin action | IT Admin |
| **P14: API Consumer Onboarding** | Register new API consumers | Request | IT |

### A.5.2 Missing Subprocesses

| Parent Process | Missing Subprocess | Purpose |
|----------------|-------------------|---------|
| P1: Entity Establishment | Duplicate Detection Pre-check | Prevent creating duplicates |
| P2: Entity Maintenance | Cascade Update to Relationships | Update related entities |
| P3: Entity Resolution | Cluster Processing | Handle multi-way matches |
| P4: DQ Management | Auto-remediation Execution | Fix correctable issues |
| P5: Source Onboarding | Source Deprecation | Phase out old sources |
| P6: Health Monitoring | Alert Escalation | Escalate persistent issues |

---

## A.6 Business Rules Completeness Check

### A.6.1 Missing Business Rules

| Rule ID | Domain | Rule Statement | Rationale |
|---------|--------|----------------|-----------|
| BR-ENT-001 | Entity | An entity marked MERGED cannot be modified | Data integrity |
| BR-ENT-002 | Entity | Merged entities redirect all queries to survivor | Transparency |
| BR-ENT-003 | Entity | Entity with active relationships cannot be dissolved | Referential integrity |
| BR-REC-001 | Record | A RegistryRecord cannot be deleted, only superseded | Immutability |
| BR-REC-002 | Record | Superseded records excluded from survivorship | Accuracy |
| BR-MER-001 | MER | MER recomputed whenever new record linked | Currency |
| BR-MER-002 | MER | MER recomputed whenever survivorship rules change | Consistency |
| BR-MER-003 | MER | Locked attributes skip survivorship unless force-unlocked | Control |
| BR-ER-001 | ER | Negative matches block auto-link permanently | Precision |
| BR-ER-002 | ER | Cross-border matches require manual review | Risk mitigation |
| BR-ER-003 | ER | Match score < 70% auto-rejected | Efficiency |
| BR-DQ-001 | DQ | CRITICAL issues block MER publication | Quality gate |
| BR-DQ-002 | DQ | Stale entities auto-added to refresh queue | Currency |
| BR-SRC-001 | Source | Sources in DOWN status excluded from broadcast | Reliability |
| BR-SRC-002 | Source | Manual sources never called automatically | Correctness |
| BR-CFG-001 | Config | Config changes require approval for production | Change control |
| BR-CFG-002 | Config | Rollback available for 30 days post-deployment | Recoverability |
| BR-SEC-001 | Security | Failed logins trigger lockout after 5 attempts | Security |
| BR-SEC-002 | Security | API keys expire after 1 year | Security |
| BR-AUD-001 | Audit | All entity modifications logged with before/after | Compliance |
| BR-AUD-002 | Audit | Audit logs retained for 7 years minimum | Regulatory |

---

# SECTION B: COMPLETE REQUIREMENTS SPECIFICATION

## B.1 Functional Requirements by Domain

### B.1.1 Entity Management (ENT)

| Req ID | Requirement | Priority | Acceptance Criteria |
|--------|-------------|----------|---------------------|
| ENT-001 | System shall create a new LegalEntity with a unique UUID | Must | UUID generated, entity persisted, audit logged |
| ENT-002 | System shall support entity status transitions (Active→Inactive→Dissolved) | Must | Valid transitions enforced, invalid rejected |
| ENT-003 | System shall merge two entities into one survivor | Must | Records consolidated, merged entity redirects, audit logged |
| ENT-004 | System shall split an entity into two (unmerge) | Must | Records separated, both entities independent, audit logged |
| ENT-005 | System shall track entity events (name change, merger, dissolution) | Must | Events persisted with date, type, source |
| ENT-006 | System shall manage entity relationships (parent/subsidiary) | Should | Relationships created with type, dates, validated |
| ENT-007 | System shall compute and store risk rating per entity | Should | Rating computed from rules, stored, queryable |
| ENT-008 | System shall track last verification timestamp | Should | Updated on manual verification, queryable |
| ENT-009 | System shall support soft-delete (deactivation) only | Must | No hard deletes, status set to INACTIVE |
| ENT-010 | System shall redirect queries for merged entities to survivor | Must | Transparent redirect, original ID still resolvable |

### B.1.2 Record Management (REC)

| Req ID | Requirement | Priority | Acceptance Criteria |
|--------|-------------|----------|---------------------|
| REC-001 | System shall create immutable RegistryRecords | Must | Records cannot be updated after creation |
| REC-002 | System shall store raw payload as-received | Must | JSON stored verbatim, no transformation |
| REC-003 | System shall track valid_from_source and ingestion_ts | Must | Both timestamps populated, queryable |
| REC-004 | System shall mark records as superseded (not deleted) | Must | superseded_by_id populated, excluded from survivorship |
| REC-005 | System shall compute stale_flag based on jurisdiction threshold | Must | Flag computed nightly, accurate per BR-DM-003 |
| REC-006 | System shall compute quality_flag based on DQ rules | Must | Flag updated on rule evaluation |
| REC-007 | System shall link records to source via source_id | Must | FK constraint enforced |
| REC-008 | System shall support verification workflow for manual records | Should | Status tracked (UNVERIFIED→VERIFIED/REJECTED) |
| REC-009 | System shall store OCR confidence per extracted field | Should | Confidence scores stored, UI displays |
| REC-010 | System shall retain records per retention policy | Should | Archival after policy period, restore capability |

### B.1.3 Master Entity Record (MER)

| Req ID | Requirement | Priority | Acceptance Criteria |
|--------|-------------|----------|---------------------|
| MER-001 | System shall compute MER on each new record ingestion | Must | MER recomputed within 1 minute of ingestion |
| MER-002 | System shall apply survivorship rules per BR-DM-002 | Must | Deterministic, reproducible results |
| MER-003 | System shall respect attribute locks | Must | Locked attributes unchanged unless force-unlocked |
| MER-004 | System shall skip NULL values in survivorship (Latest Non-Null) | Must | NULL never overwrites non-NULL |
| MER-005 | System shall track MER version number | Should | Version incremented on each computation |
| MER-006 | System shall compute DQ score for MER | Should | Score 0-100 based on completeness/quality |
| MER-007 | System shall store all historical MER versions | Must | Full history queryable for audit |
| MER-008 | System shall recompute MER when survivorship rules change | Should | Batch recompute triggered, progress tracked |
| MER-009 | System shall publish MER changes to event stream | Should | Kafka/webhook notification on change |
| MER-010 | System shall support forced attribute override by Steward | Should | Override logged, reason required |

### B.1.4 Entity Resolution (ER)

| Req ID | Requirement | Priority | Acceptance Criteria |
|--------|-------------|----------|---------------------|
| ER-001 | System shall perform deterministic matching on reg number + country | Must | Exact match = STP link |
| ER-002 | System shall perform probabilistic matching using Jaro-Winkler | Must | Score computed, threshold applied |
| ER-003 | System shall preprocess names (uppercase, remove suffixes, transliterate) | Must | Preprocessing applied before scoring |
| ER-004 | System shall create MatchCandidate records for review queue | Must | Candidates persisted with scores |
| ER-005 | System shall support Negative Match blocking | Must | Blocked pairs never auto-matched |
| ER-006 | System shall log all match decisions with reason | Must | MatchDecision created, auditable |
| ER-007 | System shall support configurable matching weights | Should | Weights editable by Steward |
| ER-008 | System shall support configurable STP threshold | Should | Threshold editable, preview available |
| ER-009 | System shall detect and cluster potential duplicates proactively | Should | Clusters surfaced for review |
| ER-010 | System shall support multi-way merge (3+ entities) | Should | Cluster merge supported |

### B.1.5 Data Quality (DQ)

| Req ID | Requirement | Priority | Acceptance Criteria |
|--------|-------------|----------|---------------------|
| DQ-001 | System shall evaluate DQ rules on record ingestion | Must | Rules evaluated, issues created |
| DQ-002 | System shall categorize issues (Completeness, Format, etc.) | Must | Category assigned per rule |
| DQ-003 | System shall assign severity (CLEAN, WARNING, CRITICAL) | Must | Severity assigned per BR-DM-004 |
| DQ-004 | System shall auto-remediate correctable issues | Should | Format corrections applied automatically |
| DQ-005 | System shall create tasks for non-auto issues | Must | Task created, assigned, SLA set |
| DQ-006 | System shall track issue lifecycle (detected→resolved) | Must | Status transitions logged |
| DQ-007 | System shall block MER publication on CRITICAL issues | Should | Gate enforced, notification sent |
| DQ-008 | System shall provide DQ dashboard with metrics | Should | Charts show issues by category/severity |
| DQ-009 | System shall support custom DQ rules by Steward | Should | Rule editor available |
| DQ-010 | System shall compute entity-level DQ score | Should | Score 0-100, displayed on entity view |

### B.1.6 Integration & Adapters (INT)

| Req ID | Requirement | Priority | Acceptance Criteria |
|--------|-------------|----------|---------------------|
| INT-001 | System shall support REST API adapters with OAuth2/API key auth | Must | Adapter framework available, auth configurable |
| INT-002 | System shall support SOAP/WSDL adapters | Must | WSDL parsing, SOAP calls functional |
| INT-003 | System shall support SDMX REST adapters (for ECB/statistical) | Should | SDMX queries functional |
| INT-004 | System shall support file ingestion (FTP/SFTP/S3) | Must | File download, parsing, ingestion |
| INT-005 | System shall support delta/change feeds | Should | Delta processing, incremental updates |
| INT-006 | System shall support web scraping agents | Should | Configurable scraping, rate limiting |
| INT-007 | System shall integrate OCR service (Tesseract/Cloud) | Must | OCR API called, results stored |
| INT-008 | System shall respect source rate limits | Must | Rate limiting enforced per source config |
| INT-009 | System shall securely store credentials (vault integration) | Must | No plaintext secrets, vault reference |
| INT-010 | System shall retry failed requests with exponential backoff | Must | Retry logic per BR-PM-001 |
| INT-011 | System shall timeout requests after configured duration | Must | Timeout enforced, failure logged |
| INT-012 | System shall log all external API calls | Must | Request/response logged (redacted) |

### B.1.7 Workflow & Task Management (WF)

| Req ID | Requirement | Priority | Acceptance Criteria |
|--------|-------------|----------|---------------------|
| WF-001 | System shall create tasks with type, priority, due date | Must | Tasks persisted, queryable |
| WF-002 | System shall assign tasks to users or queues | Must | Assignment tracked |
| WF-003 | System shall track task status transitions | Must | Valid transitions enforced |
| WF-004 | System shall calculate task aging and SLA breach | Must | Aging computed, breach flagged |
| WF-005 | System shall auto-escalate tasks breaching SLA | Should | Escalation to supervisor triggered |
| WF-006 | System shall support bulk task actions (assign, snooze) | Should | Bulk operations functional |
| WF-007 | System shall send notifications on task events | Should | Email/in-app notification sent |
| WF-008 | System shall support maker-checker workflow | Should | Second approval required for sensitive ops |
| WF-009 | System shall provide task dashboard with filters | Must | Dashboard functional, filters work |
| WF-010 | System shall track task completion metrics | Should | Metrics computed, displayed |

### B.1.8 Configuration Management (CFG)

| Req ID | Requirement | Priority | Acceptance Criteria |
|--------|-------------|----------|---------------------|
| CFG-001 | System shall provide Mapping Studio for field mappings | Must | UI available, mappings saveable |
| CFG-002 | System shall support transformation functions in mappings | Must | Lookup, concat, conditional functional |
| CFG-003 | System shall validate mappings against sample data | Should | Validation runs, errors displayed |
| CFG-004 | System shall version all configuration changes | Must | Version history available |
| CFG-005 | System shall support config promotion (Dev→Test→Prod) | Should | Promotion workflow functional |
| CFG-006 | System shall require approval for production config changes | Should | Approval workflow enforced |
| CFG-007 | System shall support config rollback | Should | Rollback to previous version functional |
| CFG-008 | System shall provide Survivorship Rule editor | Must | Rules editable, saveable |
| CFG-009 | System shall provide ER Rule editor | Must | Weights/thresholds editable |
| CFG-010 | System shall provide Lookup Table editor | Should | Lookup tables manageable |

### B.1.9 Source Management (SRC)

| Req ID | Requirement | Priority | Acceptance Criteria |
|--------|-------------|----------|---------------------|
| SRC-001 | System shall maintain registry source catalog | Must | All 135 sources cataloged |
| SRC-002 | System shall track source health metrics | Must | Availability, response time tracked |
| SRC-003 | System shall detect source degradation automatically | Must | Status transitions per health checks |
| SRC-004 | System shall alert on source issues | Should | Alerts sent on DEGRADED/DOWN |
| SRC-005 | System shall support source onboarding workflow | Must | Staged onboarding functional |
| SRC-006 | System shall support source deprecation workflow | Should | Graceful phase-out supported |
| SRC-007 | System shall schedule source health probes | Must | Probes run on schedule |
| SRC-008 | System shall provide source health dashboard | Must | Dashboard shows all sources |
| SRC-009 | System shall track source SLAs | Should | SLAs configurable, tracked |
| SRC-010 | System shall support source-specific identifier formats | Must | Regex validation per source |

### B.1.10 API & Output (API)

| Req ID | Requirement | Priority | Acceptance Criteria |
|--------|-------------|----------|---------------------|
| API-001 | System shall expose Entity Query REST API | Must | CRUD operations available |
| API-002 | System shall support search by name, reg number, LEI | Must | Search functional, performant |
| API-003 | System shall expose Change Stream (Kafka) | Should | Events published on changes |
| API-004 | System shall support point-in-time queries | Must | Historical state retrievable |
| API-005 | System shall support bulk export (JSON, CSV) | Should | Export functional, < 30s for 10k |
| API-006 | System shall authenticate API consumers | Must | OAuth2/API key enforced |
| API-007 | System shall rate-limit API consumers | Should | Rate limits enforced |
| API-008 | System shall version APIs | Should | v1, v2 supported concurrently |
| API-009 | System shall provide OpenAPI documentation | Must | Swagger/OpenAPI spec published |
| API-010 | System shall support webhook subscriptions | Should | Webhooks configurable, events pushed |

### B.1.11 Security & Access (SEC)

| Req ID | Requirement | Priority | Acceptance Criteria |
|--------|-------------|----------|---------------------|
| SEC-001 | System shall integrate with SSO (OIDC/SAML) | Must | SSO login functional |
| SEC-002 | System shall enforce role-based access control | Must | Roles assigned, permissions enforced |
| SEC-003 | System shall support jurisdiction-based data access | Should | Access limited by user's jurisdictions |
| SEC-004 | System shall encrypt sensitive data at rest | Must | Encryption enabled, keys managed |
| SEC-005 | System shall encrypt all data in transit (TLS 1.3) | Must | TLS enforced |
| SEC-006 | System shall mask PII in logs | Must | No PII in logs |
| SEC-007 | System shall lock accounts after failed logins | Should | Lockout after 5 attempts |
| SEC-008 | System shall expire API keys annually | Should | Expiration enforced, notification sent |
| SEC-009 | System shall log all access events | Must | Access logged, queryable |
| SEC-010 | System shall support MFA for admin users | Should | MFA required for admin roles |

### B.1.12 Audit & Compliance (AUD)

| Req ID | Requirement | Priority | Acceptance Criteria |
|--------|-------------|----------|---------------------|
| AUD-001 | System shall log all entity modifications | Must | Before/after state captured |
| AUD-002 | System shall log all user actions | Must | Action, user, timestamp captured |
| AUD-003 | System shall make audit logs immutable | Must | Append-only, no deletions |
| AUD-004 | System shall retain audit logs per policy (7 years) | Must | Retention enforced |
| AUD-005 | System shall generate point-in-time snapshots | Must | Snapshot exportable with checksum |
| AUD-006 | System shall digitally sign exported snapshots | Should | Signature verifiable |
| AUD-007 | System shall provide audit search interface | Must | Search by entity, user, date |
| AUD-008 | System shall export audit reports (PDF, CSV) | Should | Export functional |
| AUD-009 | System shall track data lineage end-to-end | Must | Source→Record→MER traced |
| AUD-010 | System shall support compliance reporting templates | Should | Pre-built reports available |

---

## B.2 Non-Functional Requirements

### B.2.1 Performance Requirements

| Req ID | Requirement | Target | Measurement |
|--------|-------------|--------|-------------|
| NFR-PERF-001 | Entity search response time | < 3s (p95) | APM |
| NFR-PERF-002 | Entity detail page load | < 2s | Lighthouse |
| NFR-PERF-003 | Record ingestion throughput | > 100 records/sec | Load test |
| NFR-PERF-004 | MER computation time | < 500ms per entity | Instrumentation |
| NFR-PERF-005 | Bulk export 10k entities | < 30s | Timed test |
| NFR-PERF-006 | API response time | < 500ms (p95) | APM |
| NFR-PERF-007 | ER matching batch | 1000 candidates/min | Load test |
| NFR-PERF-008 | Dashboard load time | < 3s | Lighthouse |

### B.2.2 Scalability Requirements

| Req ID | Requirement | Target |
|--------|-------------|--------|
| NFR-SCALE-001 | Total entities supported | 10 million |
| NFR-SCALE-002 | Registry records supported | 100 million |
| NFR-SCALE-003 | Concurrent UI users | 50 |
| NFR-SCALE-004 | Concurrent API requests | 500/sec |
| NFR-SCALE-005 | Registry sources supported | 200 |
| NFR-SCALE-006 | Daily ingestion volume | 1 million records |

### B.2.3 Availability Requirements

| Req ID | Requirement | Target |
|--------|-------------|--------|
| NFR-AVAIL-001 | Platform availability | 99.9% (8.76h downtime/year) |
| NFR-AVAIL-002 | Planned maintenance window | < 4h/month |
| NFR-AVAIL-003 | Recovery Time Objective (RTO) | < 1 hour |
| NFR-AVAIL-004 | Recovery Point Objective (RPO) | < 15 minutes |

### B.2.4 Security Requirements

| Req ID | Requirement | Standard |
|--------|-------------|----------|
| NFR-SEC-001 | Authentication | OIDC/SAML 2.0 |
| NFR-SEC-002 | Authorization | RBAC |
| NFR-SEC-003 | Encryption at rest | AES-256 |
| NFR-SEC-004 | Encryption in transit | TLS 1.3 |
| NFR-SEC-005 | Audit logging | Immutable, 7-year retention |
| NFR-SEC-006 | Vulnerability scanning | Weekly automated scans |

### B.2.5 Usability Requirements

| Req ID | Requirement | Target |
|--------|-------------|--------|
| NFR-USE-001 | Accessibility | WCAG 2.1 AA |
| NFR-USE-002 | Browser support | Chrome, Edge, Firefox (latest 2) |
| NFR-USE-003 | Localization | English (default), extensible |
| NFR-USE-004 | Training time for new user | < 4 hours |
| NFR-USE-005 | Task completion efficiency | < 5 clicks for common tasks |

---

# SECTION C: COMPREHENSIVE IMPLEMENTATION PLAN

## C.1 Architecture Overview

### C.1.1 System Context Diagram

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
|                  | (Node.js/Go)  |                               |
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
| |Postgres|  | Neo4j  |  |Redis |  |S3/Blob|  |Kafka |             |
| |(Entity)|  |(Graph) |  |(Cache)|  |(Docs) |  |(Events)|          |
| +--------+  +--------+  +------+  +-------+  +-------+            |
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

### C.1.2 Technology Stack

| Layer | Technology | Rationale |
|-------|------------|-----------|
| Frontend | React 18 + TypeScript | Modern, typed, ecosystem |
| UI Framework | Ant Design / Material UI | Enterprise-grade components |
| API Gateway | Kong / AWS API Gateway | Rate limiting, auth |
| Backend Services | Node.js | Performance, ecosystem |
| Entity Storage | PostgreSQL 15 | ACID, bi-temporal support |
| Graph Storage | Neo4j | Relationships, traversal |
| Cache | Redis | Session, query cache |
| Document Storage | GCP Bucket Objects | Scalable, cheap |
| Event Streaming | Kafka | Change stream, decoupling |
| Search | Elasticsearch | Full-text, fuzzy matching |
| OCR | AWS Textract / Google Vision | High accuracy |
| Secret Management | HashiCorp Vault | Secure credentials |
| Monitoring | Datadog / Prometheus+Grafana | Observability |
| CI/CD | GitHub Actions / GitLab CI | Automation |
| Infrastructure | Kubernetes (EKS/GKE) | Container orchestration |

---

## C.2 Implementation Phases

### Phase 0: Foundation (Weeks 1-4)

**Objective:** Establish project infrastructure and core architecture

| Week | Deliverables | Owner |
|------|--------------|-------|
| 1 | Project setup: repo, CI/CD, environments (dev/test/prod) | Platform Team |
| 1 | Architecture decision records finalized | Architect |
| 2 | Database schema v1 (core entities) deployed | Backend Team |
| 2 | API Gateway configured with auth | Platform Team |
| 3 | Core service scaffolding (Entity, Record, Source) | Backend Team |
| 3 | React app scaffolding with routing | Frontend Team |
| 4 | Logging, monitoring, alerting infrastructure | Platform Team |
| 4 | Secret management (Vault) configured | Platform Team |

**Exit Criteria:**
- [ ] All environments accessible
- [ ] CI/CD pipeline runs green
- [ ] Core services deploy and respond to health checks
- [ ] Monitoring dashboards visible

---

### Phase 1: Entity Core (Weeks 5-10)

**Objective:** Implement entity lifecycle and record management

#### Sprint 1.1 (Weeks 5-6): Entity & Record CRUD

| Req IDs | Feature | Tasks |
|---------|---------|-------|
| ENT-001, ENT-002, ENT-009 | Entity CRUD | API endpoints, validation, audit logging |
| REC-001, REC-002, REC-003 | Record creation | Immutable storage, timestamp handling |
| REC-007 | Source linking | FK constraint, validation |

**Deliverables:**
- Entity Service with create/read/update/deactivate
- Record Service with create/read
- Database migrations
- Unit tests (>80% coverage)
- API documentation

#### Sprint 1.2 (Weeks 7-8): MER & Survivorship

| Req IDs | Feature | Tasks |
|---------|---------|-------|
| MER-001, MER-002, MER-004 | MER computation engine | Algorithm implementation |
| MER-003 | Attribute locks | Lock storage, enforcement |
| MER-007 | MER versioning | Version tracking, history |
| CFG-008 | Survivorship rule storage | Config schema, API |

**Deliverables:**
- Survivorship Engine service
- MER computation triggered on record ingestion
- Lock management API
- MER history queryable
- Performance benchmarks (<500ms per entity)

#### Sprint 1.3 (Weeks 9-10): Bi-temporal Queries

| Req IDs | Feature | Tasks |
|---------|---------|-------|
| API-004 | Point-in-time query | Temporal query engine |
| AUD-005 | Snapshot generation | Snapshot service, export |
| AUD-009 | Lineage tracking | End-to-end trace |

**Deliverables:**
- Bi-temporal query API (as-of valid time, as-of system time)
- Snapshot generation and export
- Lineage API returning source→record→MER chain
- Integration tests

**Phase 1 Exit Criteria:**
- [ ] Entity CRUD operational via API
- [ ] MER computed correctly for test entities
- [ ] Point-in-time queries return correct historical state
- [ ] Performance targets met

---

### Phase 2: Integration Layer (Weeks 11-18)

**Objective:** Build registry adapter framework and connect initial sources

#### Sprint 2.1 (Weeks 11-12): Adapter Framework

| Req IDs | Feature | Tasks |
|---------|---------|-------|
| INT-001 | REST adapter framework | Generic REST client, auth handling |
| INT-008 | Rate limiting | Token bucket implementation |
| INT-010, INT-011 | Retry & timeout | Exponential backoff, circuit breaker |
| INT-012 | Call logging | Request/response logging |
| INT-009 | Credential management | Vault integration |

**Deliverables:**
- Adapter base class with REST support
- Rate limiter per source
- Retry logic with circuit breaker
- Vault integration for API keys
- Adapter test harness

#### Sprint 2.2 (Weeks 13-14): Initial Source Adapters

| Source | Type | Priority |
|--------|------|----------|
| GLEIF | REST | 1 - Supranational |
| UK Companies House | REST | 2 - High volume |
| Sweden Bolagsverket | REST/OAuth2 | 2 - Reference impl |
| Norway Brreg | REST | 2 - Open API |

**Deliverables:**
- 4 production-ready adapters
- Mapping configurations
- Integration tests against sandbox/test APIs
- Source health probes

#### Sprint 2.3 (Weeks 15-16): Additional Adapters

| Source | Type | Priority |
|--------|------|----------|
| Netherlands KVK | REST | 2 |
| Denmark CVR | Elasticsearch | 2 |
| Finland PRH | REST | 2 |
| France INPI RNE | REST/FTP | 2 |
| ECB RIAD | SDMX | 1 |

**Deliverables:**
- INT-002: SOAP adapter framework (for Austria, etc.)
- INT-003: SDMX adapter framework
- INT-004: File ingestion (FTP/SFTP)
- 5 additional adapters
- Total: 9 sources operational

#### Sprint 2.4 (Weeks 17-18): Source Management

| Req IDs | Feature | Tasks |
|---------|---------|-------|
| SRC-001, SRC-002 | Source catalog & health | Source registry, metrics collection |
| SRC-003, SRC-004 | Health monitoring & alerting | Health checker service, alert integration |
| SRC-007, SRC-008 | Health dashboard | UI for source status |
| SRC-010 | Identifier validation | Regex validation per source |

**Deliverables:**
- Source Health Service
- Metrics collection (availability, response time)
- Health status transitions (HEALTHY→DEGRADED→DOWN)
- Alert integration (Slack/PagerDuty)
- Health Dashboard UI

**Phase 2 Exit Criteria:**
- [ ] 9+ sources operational and ingesting data
- [ ] Health monitoring detects degradation within 15 minutes
- [ ] Alerts firing correctly
- [ ] Adapter framework documented for new sources

---

### Phase 3: Entity Resolution (Weeks 19-24)

**Objective:** Implement matching engine and review workflows

#### Sprint 3.1 (Weeks 19-20): Deterministic Matching

| Req IDs | Feature | Tasks |
|---------|---------|-------|
| ER-001 | Deterministic matching | Exact match on reg number + country |
| ER-003 | Name preprocessing | Uppercase, suffix removal, transliteration |
| ER-006 | Match decision logging | MatchDecision entity, audit |

**Deliverables:**
- ER Engine service
- Deterministic match rules
- Name normalization service (with 50+ legal form suffixes)
- Transliteration service (Cyrillic, CJK, Arabic→Latin)
- Auto-link for STP matches

#### Sprint 3.2 (Weeks 21-22): Probabilistic Matching

| Req IDs | Feature | Tasks |
|---------|---------|-------|
| ER-002 | Jaro-Winkler scoring | Algorithm implementation |
| ER-004 | Match candidates | Candidate generation, storage |
| ER-007, ER-008 | Configurable rules | Weight/threshold editor |

**Deliverables:**
- Jaro-Winkler implementation (optimized)
- Levenshtein as fallback
- Configurable field weights
- STP threshold configuration
- Candidate queue for review

#### Sprint 3.3 (Weeks 23-24): Review Workflows

| Req IDs | Feature | Tasks |
|---------|---------|-------|
| ER-005 | Negative matching | NegativeMatch entity, blocking logic |
| ENT-003 | Entity merge | Merge execution, record consolidation |
| ENT-004 | Entity split | Unmerge capability |
| WF-001-004 | Task management | Task queue for ER review |

**Deliverables:**
- ER Review UI (side-by-side comparison)
- Merge execution with redirect
- Split/unmerge execution
- Negative match UI and enforcement
- Task queue integration
- SLA tracking for review tasks

**Phase 3 Exit Criteria:**
- [ ] STP rate >85% for deterministic matches
- [ ] Probabilistic matches scored and queued
- [ ] Review UI operational
- [ ] Merge/split functional with audit trail

---

### Phase 4: Data Quality (Weeks 25-28)

**Objective:** Implement DQ detection and remediation

#### Sprint 4.1 (Weeks 25-26): DQ Rules Engine

| Req IDs | Feature | Tasks |
|---------|---------|-------|
| DQ-001, DQ-002, DQ-003 | DQ rule evaluation | Rule engine, categorization, severity |
| DQ-006 | Issue lifecycle | DQIssue entity, status tracking |
| DQ-009 | Custom rules | Rule editor UI |

**Deliverables:**
- DQ Engine service
- Pre-built rules (completeness, format, cross-field)
- DQIssue tracking
- Rule editor UI for Stewards

#### Sprint 4.2 (Weeks 27-28): Remediation & Dashboard

| Req IDs | Feature | Tasks |
|---------|---------|-------|
| DQ-004 | Auto-remediation | Correctable issue fixing |
| DQ-005 | Task creation | Auto-create tasks for manual issues |
| DQ-007 | MER gating | Block publication on CRITICAL |
| DQ-008, DQ-010 | Dashboard & scoring | Charts, entity DQ score |

**Deliverables:**
- Auto-remediation for format issues
- Task creation for manual issues
- CRITICAL issue gating
- DQ Dashboard with charts
- Entity-level DQ score computation

**Phase 4 Exit Criteria:**
- [ ] DQ rules evaluating on ingestion
- [ ] Issues categorized and tracked
- [ ] Auto-remediation functional
- [ ] Dashboard showing issue metrics

---

### Phase 5: Configuration & Self-Service (Weeks 29-34)

**Objective:** Enable steward self-service configuration

#### Sprint 5.1 (Weeks 29-30): Mapping Studio

| Req IDs | Feature | Tasks |
|---------|---------|-------|
| CFG-001 | Mapping Studio UI | Drag-drop mapping interface |
| CFG-002 | Transformation functions | Lookup, concat, conditional |
| CFG-003 | Mapping validation | Test against sample data |
| CFG-004 | Versioning | Version history, diff view |

**Deliverables:**
- Mapping Studio UI
- Transformation function library
- Sample data testing
- Version control for mappings

#### Sprint 5.2 (Weeks 31-32): Rule Configuration

| Req IDs | Feature | Tasks |
|---------|---------|-------|
| CFG-008 | Survivorship editor | Rule priority configuration |
| CFG-009 | ER rule editor | Weight/threshold configuration |
| CFG-006 | DQ rule editor | Custom validation rules |
| CFG-010 | Lookup tables | Code mapping management |

**Deliverables:**
- Survivorship Rule editor
- ER Rule editor with preview
- DQ Rule editor
- Lookup Table management UI

#### Sprint 5.3 (Weeks 33-34): Config Promotion

| Req IDs | Feature | Tasks |
|---------|---------|-------|
| CFG-005 | Config promotion workflow | Dev→Test→Prod |
| CFG-006 | Approval workflow | Approval for prod changes |
| CFG-007 | Rollback | Revert to previous version |

**Deliverables:**
- Environment-aware configuration
- Promotion workflow with approval
- Rollback capability
- Config audit log

**Phase 5 Exit Criteria:**
- [ ] Stewards can create/edit mappings without IT
- [ ] Rules configurable via UI
- [ ] Config changes audited
- [ ] Promotion workflow operational

---

### Phase 6: Manual Ingestion & OCR (Weeks 35-38)

**Objective:** Support manual data entry with AI assistance

#### Sprint 6.1 (Weeks 35-36): Document Management

| Req IDs | Feature | Tasks |
|---------|---------|-------|
| INT-007 | OCR integration | AWS Textract / Google Vision |
| REC-008, REC-009 | OCR results | Confidence scoring, storage |
| Document entity | Document upload | S3 storage, metadata |

**Deliverables:**
- Document upload API and UI
- OCR service integration
- OCR result storage with confidence scores
- Document viewer

#### Sprint 6.2 (Weeks 37-38): Verification Workflow

| Req IDs | Feature | Tasks |
|---------|---------|-------|
| WF-005 | Maker-checker workflow | Verification tasks |
| Manual ingestion UI | Data entry forms | Pre-filled from OCR |
| REC-008 | Verification status | UNVERIFIED→VERIFIED flow |

**Deliverables:**
- Manual entry forms with OCR pre-fill
- Confidence highlighting in UI
- Verification workflow
- Task queue integration
- Evidence linking to records

**Phase 6 Exit Criteria:**
- [ ] Documents uploadable and OCR extracted
- [ ] OCR accuracy >90% for structured docs
- [ ] Verification workflow operational
- [ ] Manual records created with evidence

---

### Phase 7: API & Output (Weeks 39-42)

**Objective:** Expose platform capabilities via APIs

#### Sprint 7.1 (Weeks 39-40): REST API

| Req IDs | Feature | Tasks |
|---------|---------|-------|
| API-001 | Entity query API | CRUD endpoints |
| API-002 | Search API | Name, reg number, LEI search |
| API-004 | Point-in-time API | Historical queries |
| API-006 | API authentication | OAuth2 / API key |
| API-009 | Documentation | OpenAPI spec |

**Deliverables:**
- Complete Entity REST API
- Search endpoint with pagination
- Point-in-time query support
- OAuth2 authentication
- OpenAPI documentation

#### Sprint 7.2 (Weeks 41-42): Event Streaming & Bulk

| Req IDs | Feature | Tasks |
|---------|---------|-------|
| API-003 | Change stream | Kafka producer |
| API-005 | Bulk export | CSV, JSON export |
| API-007 | Rate limiting | Consumer rate limits |
| API-010 | Webhooks | Subscription management |

**Deliverables:**
- Kafka change stream publishing
- Bulk export API (async, download link)
- Consumer rate limiting
- Webhook subscription management
- Consumer onboarding process

**Phase 7 Exit Criteria:**
- [ ] REST API fully functional
- [ ] Change stream publishing
- [ ] Bulk export operational
- [ ] API consumers can integrate

---

### Phase 8: Security & Compliance (Weeks 43-46)

**Objective:** Harden security and ensure compliance

#### Sprint 8.1 (Weeks 43-44): Access Control

| Req IDs | Feature | Tasks |
|---------|---------|-------|
| SEC-001 | SSO integration | OIDC/SAML |
| SEC-002 | RBAC implementation | Role definitions, enforcement |
| SEC-003 | Data-level authorization | Jurisdiction filtering |
| SEC-007 | Account lockout | Failed login handling |
| SEC-010 | MFA | Admin MFA |

**Deliverables:**
- SSO login functional
- RBAC with roles: Admin, Steward, Ops, Viewer
- Jurisdiction-based data filtering
- Account lockout after 5 failures
- MFA for admin users

#### Sprint 8.2 (Weeks 45-46): Audit & Encryption

| Req IDs | Feature | Tasks |
|---------|---------|-------|
| SEC-004, SEC-005 | Encryption | At rest, in transit |
| SEC-006 | PII masking | Log sanitization |
| AUD-001-004 | Audit logging | Comprehensive logging |
| AUD-006 | Signed exports | Cryptographic signatures |
| AUD-007, AUD-008 | Audit UI | Search, export |

**Deliverables:**
- Database encryption enabled
- TLS 1.3 enforced everywhere
- PII masking in logs
- Immutable audit log
- Audit search UI
- Signed export capability

**Phase 8 Exit Criteria:**
- [ ] SSO login operational
- [ ] RBAC enforced
- [ ] Encryption verified
- [ ] Audit log complete and searchable

---

### Phase 9: UI Completion (Weeks 47-52)

**Objective:** Complete all user-facing features

#### Sprint 9.1 (Weeks 47-48): Entity Workbench

| Features | Tasks |
|----------|-------|
| Entity search | Search form, results list |
| Entity detail | Overview, attributes, tabs |
| Lineage view | Attribute lineage table |
| History view | Timeline, diff view |

**Deliverables:**
- Entity Search UI
- Entity Detail with all tabs
- Lineage visualization
- History timeline

#### Sprint 9.2 (Weeks 49-50): Operational UIs

| Features | Tasks |
|----------|-------|
| Task queue | Prioritized list, bulk actions |
| ER review | Side-by-side comparison |
| DQ dashboard | Issue charts, drilldown |
| Manual entry | Upload, OCR, verify |

**Deliverables:**
- Task Queue dashboard
- ER Review screen
- DQ Dashboard
- Manual Entry workflow

#### Sprint 9.3 (Weeks 51-52): Admin UIs

| Features | Tasks |
|----------|-------|
| Source health | Dashboard, metrics |
| Config studio | Mapping, rules |
| User management | Roles, permissions |
| Audit viewer | Search, export |

**Deliverables:**
- Source Health Dashboard
- Complete Config Studio
- User Management UI
- Audit Viewer

**Phase 9 Exit Criteria:**
- [ ] All UIs functional per wireframes
- [ ] Accessibility audit passed (WCAG 2.1 AA)
- [ ] Performance targets met
- [ ] User acceptance testing passed

---

### Phase 10: Scale & Production (Weeks 53-56)

**Objective:** Production hardening and scale testing

#### Sprint 10.1 (Weeks 53-54): Load Testing

| Activity | Target |
|----------|--------|
| Load test entity search | <3s at 100 concurrent |
| Load test ingestion | 100 records/sec sustained |
| Load test API | 500 requests/sec |
| Stress test | Find breaking point |

**Deliverables:**
- Load test scripts (k6/Locust)
- Performance baseline report
- Optimization recommendations
- Implemented optimizations

#### Sprint 10.2 (Weeks 55-56): Production Deployment

| Activity | Tasks |
|----------|-------|
| Production environment | Kubernetes cluster, databases |
| Data migration | Seed production data |
| Monitoring | Dashboards, alerts |
| Runbooks | Incident response procedures |
| Go-live | Staged rollout |

**Deliverables:**
- Production infrastructure
- Monitoring dashboards
- Alerting configured
- Runbooks documented
- Production go-live

**Phase 10 Exit Criteria:**
- [ ] Performance targets met under load
- [ ] Production environment stable
- [ ] Monitoring and alerting operational
- [ ] Team trained on operations

---

## C.3 Detailed Sprint Backlog Template

### Sprint Backlog: Phase 1, Sprint 1.1

| Story ID | Story | Points | Tasks | Owner |
|----------|-------|--------|-------|-------|
| ENT-001 | Create LegalEntity | 5 | 1. Define DB schema<br>2. Implement service<br>3. API endpoint<br>4. Audit logging<br>5. Unit tests | Backend |
| ENT-002 | Entity status transitions | 3 | 1. Define valid transitions<br>2. Implement state machine<br>3. Validation<br>4. Tests | Backend |
| REC-001 | Create RegistryRecord | 5 | 1. Define DB schema<br>2. Implement immutable insert<br>3. API endpoint<br>4. Tests | Backend |
| REC-002 | Store raw payload | 2 | 1. JSON column<br>2. No transformation<br>3. Tests | Backend |
| REC-003 | Timestamp handling | 3 | 1. valid_from_source parsing<br>2. ingestion_ts auto-set<br>3. Tests | Backend |
| API-DOC | API documentation | 2 | 1. OpenAPI spec<br>2. Swagger UI | Backend |

**Sprint Capacity:** 20 points
**Sprint Goal:** Entity and Record CRUD operational via API

---

## C.4 Risk Register

| Risk ID | Risk | Probability | Impact | Mitigation |
|---------|------|-------------|--------|------------|
| R01 | Registry API changes break adapters | High | High | Version adapters, monitor changelogs, automated regression tests |
| R02 | OCR accuracy below target | Medium | Medium | Fallback to manual entry, train custom models |
| R03 | ER false positive rate high | Medium | High | Conservative thresholds initially, iterative tuning |
| R04 | Performance targets not met | Medium | High | Early load testing, architecture review |
| R05 | RBAC complexity delays delivery | Medium | Medium | Start with simple roles, iterate |
| R06 | Bi-temporal queries slow | Medium | Medium | Indexed temporal columns, query optimization |
| R07 | Source rate limiting blocks ingestion | High | Medium | Distributed rate limiters, queue overflow |
| R08 | Data migration issues | Medium | High | Dry run migrations, rollback scripts |
| R09 | Team unfamiliar with graph DB | Low | Medium | Training, proof of concept first |
| R10 | Regulatory requirements change | Low | High | Modular compliance rules, regular review |

---

## C.5 Definition of Done

### Feature Level
- [ ] Code complete and peer-reviewed
- [ ] Unit tests passing (>80% coverage)
- [ ] Integration tests passing
- [ ] API documented (OpenAPI)
- [ ] UI accessible (WCAG 2.1 AA)
- [ ] Performance within targets
- [ ] Security review passed
- [ ] Audit logging implemented
- [ ] Deployed to test environment
- [ ] Product Owner accepted

### Sprint Level
- [ ] All committed stories meet feature DoD
- [ ] No critical bugs open
- [ ] Test environment stable
- [ ] Documentation updated
- [ ] Demo completed

### Release Level
- [ ] All sprint DoDs met
- [ ] End-to-end testing passed
- [ ] Load testing passed
- [ ] Security penetration testing passed
- [ ] Runbooks documented
- [ ] Training completed
- [ ] Production deployment successful

---

## C.6 Team Structure

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

**Total:** 13 people

---

## C.7 Milestone Summary

| Milestone | Target Week | Key Deliverables |
|-----------|-------------|------------------|
| M0: Foundation Complete | Week 4 | Infrastructure, CI/CD, core scaffolding |
| M1: Entity Core Complete | Week 10 | Entity/Record CRUD, MER computation, bi-temporal |
| M2: Integration Layer Complete | Week 18 | 9 sources operational, health monitoring |
| M3: ER Complete | Week 24 | Matching engine, review workflows, merge/split |
| M4: DQ Complete | Week 28 | DQ rules, remediation, dashboard |
| M5: Config Complete | Week 34 | Mapping Studio, rule editors, promotion |
| M6: Manual Ingestion Complete | Week 38 | OCR, document management, verification |
| M7: API Complete | Week 42 | REST API, change stream, bulk export |
| M8: Security Complete | Week 46 | SSO, RBAC, encryption, audit |
| M9: UI Complete | Week 52 | All user interfaces |
| M10: Production Go-Live | Week 56 | Production deployment |

---

## C.8 Appendix: Registry Adapter Priority List

### Tier 1: Supranational (Weeks 13-14)
| Source | API Type | Notes |
|--------|----------|-------|
| GLEIF | REST | Free, high quality, 3x daily updates |
| ECB RIAD | SDMX | Free, statistical data |

### Tier 2: High-Volume Jurisdictions (Weeks 13-18)
| Source | API Type | Notes |
|--------|----------|-------|
| UK Companies House | REST | Free, real-time streaming |
| Sweden Bolagsverket | REST/OAuth2 | Subscription, daily |
| Norway Brreg | REST | Free, open data leader |
| Netherlands KVK | REST | Subscription |
| Denmark CVR | Elasticsearch | Free, bulk |
| Finland PRH | REST | Free, open data |
| France INPI RNE | REST/FTP | Account required |

### Tier 3: Additional European (Weeks 19-24)
| Source | API Type | Notes |
|--------|----------|-------|
| Ireland CRO | REST | Free, open data |
| Belgium KBO | REST/SOAP | Free, monthly |
| Austria Firmenbuch | SOAP | Partner required |
| Switzerland Zefix | REST | Free |
| Estonia e-Business | XML | Contract required |

### Tier 4: Americas & Asia-Pacific (Weeks 25-34)
| Source | API Type | Notes |
|--------|----------|-------|
| USA SEC EDGAR | REST | Free |
| Canada Federal Corps | REST | Free |
| Australia ABR | SOAP | Free |
| Japan Corporate Number | REST | Free |
| Singapore ACRA | REST/OAuth2 | Subscription |

### Tier 5: Manual-Priority (Weeks 35+)
| Source | Notes |
|--------|-------|
| Germany Handelsregister | Portal only, manual |
| Luxembourg RCS | Portal only, manual |
| Italy Registro Imprese | Commercial API only |
| Hong Kong CR | Portal only, subscription |

---

# SECTION F: FUTURE RELEASES ROADMAP

## F.1 MVP Scope Boundaries (What is NOT in MVP)

### F.1.1 Registry Classification

Based on `registries_table.md` analysis (135 registries), GRIP MVP focuses exclusively on:

**TIER 1 - MVP (~35 registries)**: All free access methods, no subscription required
- **11 with REST APIs** (free, no login): LEI, OpenCorporates core datasets, and established public registries
- **12 with Free Open Data Portals**: Public company registries with downloadable datasets (various EU countries, Australia, New Zealand, etc.)
- **12 with Free Web Search**: Portal-based search without API (manual lookup capability for all major jurisdictions)
- Coverage: ~60% of global business entities

**TIER 2 - Post-MVP (~15 registries)**: Free with registration/API keys
- Target: Q2 2025, after MVP stabilization
- Examples: UAE ERN, Canada BN, Finland Y-tunnus, Argentina CUIT (free portal), Belgium CBE (free data), Brazil CNPJ (free but registration required), France SIREN, Latvia, Lithuania, Netherlands, Poland, Singapore, Switzerland

**FUTURE RELEASES (~70 registries)**: Paid, restricted, or login-required
- Deferred pending: MVP success metrics, customer demand, licensing negotiations
- Categories: Individual PINs (~25), Subscription-based (~25), Restricted (~35), Manual-only (~10)
- Examples: All personal identification numbers (PINs), commercial database subscriptions, restricted tax IDs, third-party premium APIs

### F.1.2 Out-of-Scope Registry Categories (Deferred to Future)

#### Category 1: Individual Personal IDs (Explicitly Out-of-Scope per PRD)
GRIP focuses on **legal entities only**. Individual identification numbers are out of scope:

| Country | Registry | Type | Reason |
|---------|----------|------|--------|
| Sweden | Personnummer | Individual PIN | Not legal entity |
| Sweden | Samordningsnummer | Individual temporary ID | Not legal entity |
| Denmark | CPR-nummer | Individual PIN | Not legal entity |
| Finland | N/A | Individual PIN | Out of scope |
| Netherlands | BSN (Persoonsnummer) | Individual PIN | Not legal entity |
| Norway | PIN (D/F-nummer) | Individual PIN | Not legal entity |
| Poland | PESEL | Individual PIN | Not legal entity |
| Austria | Tax ID (individuals) | Individual TIN | Not legal entity |
| Belgium | National Register TIN | Individual | Not legal entity |
| Bulgaria | EGN | Individual PIN | Not legal entity |
| Czech Republic | Rodné číslo | Individual PIN | Not legal entity |
| Hungary | Adóazonosító jel | Individual TIN | Not legal entity |
| Iceland | Kennitala PIN | Individual PIN | Not legal entity |
| Latvia | Personas kods | Individual PIN | Not legal entity |
| Lithuania | Asmens kodas | Individual PIN | Not legal entity |
| Luxembourg | Matricule (individual) | Individual PIN | Not legal entity |
| Slovenia | EMSO | Individual PIN | Not legal entity |
| Slovakia | Rodné číslo | Individual PIN | Not legal entity |
| USA | Social Security Number | Individual PIN | Not legal entity |
| Romania | CNP | Individual PIN | Not legal entity |
| Jersey | Tax reference | Individual | Not legal entity |
| Isle of Man | Tax reference | Individual | Not legal entity |
| UK | National Insurance number | Individual PIN | Not legal entity |
| Spain | DNI | Individual ID | Not legal entity |
| Italy | Codice Fiscale (individual) | Individual | Not legal entity |
| Portugal | NIF (individual) | Individual | Not legal entity |

**Count**: ~25 registries eliminated; not product scope.

#### Category 2: Subscription-Based / Paid APIs (~25 registries)

These require commercial licensing, contracts, or per-entity fees. Defer pending customer demand:

| Country | Registry | Cost Model | Notes |
|---------|----------|-----------|-------|
| Global | Business Identifier Code (BIC) | Subscription + FileAct | Core banking infrastructure; not priority for MVP |
| Sweden | Organisationsnummer | One-time fee + monthly tier | Requires contract; prioritize free sources first |
| Austria | Commercial Register (FB-Nr.) | API via paid brokers (ADVOKAT) | Broker dependency increases complexity |
| Austria | Association Register (ZVR) | Paid API via brokers | Broker-dependent; enterprise tier |
| Austria | OeNB Identnummer | Monthly KM 100 fee | Financial institution-specific; lower priority |
| Bosnia | Trade register (JIB) | KM 100 monthly fee | Central Bank access requires payment |
| Belarus | USR | Electronic app fee ~32 BYN | Emerging market; lower priority |
| Brazil | CNPJ (SERPRO API) | Paid SERPRO Store | Use free Receita Federal lookup instead |
| Estonia | Business register | Contract required for enhanced API | Core data free; advanced features paid |
| Taiwan | Tax number | NT$10 per company queried | Per-entity pricing; doesn't scale well |
| Hong Kong | Corporate register | Sub HK$500/year (e-Search) | Low-cost but subscription model |
| Greece | International Maritime (IMO) | Subscription (Equasis/S&P) | Specialized maritime; lower priority |
| India | Corporate identity (CIN) | Credit-based; Technowire API | Portal available free; API requires credits |
| Iceland | Identification (KT) | Paid via brokers (Já.is) | No direct free API; broker-dependent |
| Italy | CCIAA+REA | Commercial contract required | Professional-grade; enterprise tier |
| Russia | INN/OGRN | Institutional contracts required | Complex legal framework; enterprise tier |
| Mexico | RFC | Paid CRiskCo/Verifik APIs | Use free portal; defer paid APIs |
| Colombia | NIT | Verifik/Apitude paid APIs | Use free RUES lookup; defer paid APIs |
| Panama | RUC | Paid Verifik API | Free lookup available; defer paid |
| Peru | RUC | Paid Apitude/Verifik | Free SUNAT lookup; defer paid APIs |
| China | USCN | Paid via 3rd party brokers | LATAM strategy; enterprise tier |
| Singapore | UEN/ROB | Chargeable packages (EIQ/FIQ) | Free search; paid extracts; post-MVP |
| Ukraine | EDRPOU | Free basic; paid API | Use free search; defer API tier |
| Netherlands | KvK APIs | Subscription + per-call fees | Some free data available; negotiate terms |
| Canada | BC Registries | Fees per regulation | Provincial; prioritize federal free tier |

**Strategy**: Negotiate volume discounts after MVP success; evaluate cost-benefit per market.

#### Category 3: Restricted Access / Legal Basis Required (~35 registries)

These require institutional status, government authorization, or legal agreements:

| Country | Registry | Restriction | Notes |
|---------|----------|------------|-------|
| Austria | Tax ID (legal entity) | Gated via FinanzOnline; authorized systems only | Requires integration agreement |
| Belgium | CBE (legal entity) | Some data restricted; free data available | Use free open data tier only |
| Germany | Tax ID (Steuernummer) | Restricted – official use only | Local tax ID; government-only access |
| Germany | Association register | Some free access; documents paid | Use free lookup; docs post-MVP |
| Switzerland | Tax code (UID number) | Restricted to admin offices; login required | UID business is free; personal is restricted |
| USA | EIN | Restricted A2A API | Institutional-only; defer to enterprise |
| USA | Unique Taxpayer Ref (UTR) | Commercial keys via HMRC | Tax-specific; restricted; post-MVP |
| UK | UTR | Commercial keys via HMRC | Tax-specific restricted; post-MVP |
| Croatia | OIB | Free for authorized e-Citizens | Authorized-only; restricted framework |
| Romania | EU VAT | Free for authorized systems | Authorized-only; restricted access |
| Romania | Trade register | Restricted via INFOCERT | Broker-dependent; paid access |
| Luxembourg | Matricule/PM | Restricted – ACD access | Government-only; out of scope |
| Luxembourg | Public sector/VAT | Restricted – CTIE | Government-only; out of scope |
| Luxembourg | Investment fund | Agreement with CSSF required | Regulatory agreement needed |
| Lithuania | JAR kodas | RC service contracts; fees apply | Contract framework required |
| Latvia | NBR | National API manager login | Login required for API access |
| Slovenia | Tax code | Gated via eDavki | Authorized-only system |
| Croatia | Trade register | Free subscription; login required | Subscription + login; Tier 2 after MVP |
| Israel | Tax ID | API keys for authorized orgs | Authorized organizational status |
| Indonesia | NPWP | Free for authorized tax agents | Professional/institutional framework |
| France | SIREN | Account required for daily API | Registration required; Tier 2 candidate |
| France | CIB (Financial) | Free but IBM Client ID required | Registration requirement |
| Estonia | e-Business | Contract required; core data free | Contract framework; Tier 2 |
| Serbia | Trade register | Manual only; free search web | No direct API; scraping candidate |
| Serbia | PIB | Manual only; no direct API | No direct API layer |
| Portugal | Tax ID (NIF) | Restricted – Finanças access | Government-only; out of scope |
| Portugal | Tax ID (individual) | Restricted – Finanças | Not legal entity; out of scope |
| Poland | Trade register (KRS) | Free data available; legal entity scope | Legal entity OK; individual PESEL out |
| Poland | Tax code (NIP) | Gated for authorized; legal entity OK | Use where available; authorize where needed |
| Bulgaria | BULSTAT | Entry fees apply; web free | Free web search; skip fees for MVP |
| Austria | Association (ZVR) | Some free, some paid | Use free tier; docs post-MVP |
| Germany | Handelsregister | Free search; docs paid | Use free search; docs post-MVP |
| Greece | Tax code (AMF) | No direct API; free search only | Free manual search only; consider scraping |
| Malta | Business register | No direct API; free search | Free manual search only |
| Monaco | Trade register | No direct API; free search | Free manual search; scraping candidate |

**Strategy**: Implement authorization frameworks in Tier 2 after MVP; start with free tiers only.

#### Category 4: Manual-Only / No Programmatic API (~10 registries)

These have no direct API and would require manual scraping or portal access:

| Country | Registry | Access Type | Notes |
|---------|----------|------------|-------|
| Bermuda | ROC | Portal only | No direct API; broker-dependent |
| Bahamas | Business register | Portal search only | Manual portal; low priority |
| Isle of Man | Company register | Portal only | Offshore; broker-dependent |
| Guernsey | Entity Reg Number | Portal only | Offshore; low priority |
| Marshall Islands | Business register | Portal only | Offshore; low priority |
| Liechtenstein | FL-Nummer | Portal only | Alpine jurisdiction; manual scraping needed |
| Luxembourg | RCS | Portal only | Manual portal; no API |
| Thailand | Business register | Portal only | No programmatic API as of 2026 |
| Turkey | Tax code (Vergi Kimlik) | Digital filing only | Lawyer-led filing; complex |
| Malta | MBR | Portal only | Free manual search; no API |

**Strategy**: Defer to web scraping tier (Phase 6 OCR/Manual extension) if customer demand justifies.

### F.1.3 Future Releases Roadmap

| Phase | Timeline | Target Count | Focus |
|-------|----------|--------------|-------|
| **MVP (CURRENT)** | Weeks 1-42 | 15 registries | Free, no-login, high-priority jurisdictions |
| **Tier 2** | Q2 2025 | +20 registries | Free with registration/keys; adapter setup |
| **Enterprise Tier** | Q3 2025+ | +50-60 registries | Subscriptions, enterprise licensing, negotiated access |
| **Compliance Tier** | Q4 2025+ | +20-25 registries | Restricted-access, regulatory frameworks, government integrations |
| **Specialized** | 2026+ | +10-15 registries | Manual-only, scraping, third-party brokers, offshore |

### F.1.4 Coverage Verification Matrix

**MVP TIER 1 (15 registries)** ✅ All free no-login covered:
1. ✅ LEI (Global) – Tier 1
2. ✅ ABN (Australia) – Tier 1
3. ✅ MBS (Bosnia) – Tier 1
4. ✅ Cyprus Business Register – Tier 1
5. ✅ Cyprus CBC – Tier 1
6. ✅ ICO (Czech) – Tier 1
7. ✅ Germany Public Sector ID – Tier 1
8. ✅ CVR (Denmark) – Tier 1
9. ✅ Corporate Number (Japan) – Tier 1
10. ✅ TIN (Korea) – Tier 1
11. ✅ Business Register (Norway) – Tier 1
12. ✅ KRS (Poland) – Tier 1
13. ✅ CRN (UK) – Tier 1
14. ✅ CIK (USA) – Tier 1
15. ✅ CRO (Ireland) – Tier 1

**VERIFICATION**: No free no-login registries are deferred. All are in MVP or Tier 2 (free with registration).

---

# Document End

**Total Requirements:** 120+ functional, 25+ non-functional
**Total Capabilities:** 80+
**Implementation Duration:** 56 weeks
**Team Size:** 13 people
