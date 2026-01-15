Product Requirements Document (PRD): GRIP v2.0
Product Name: Global Registry Intelligence Platform (GRIP)

Role Focus: Data Stewardship, Data Operations, Senior Product Ownership

1. Product Vision & Scope
To provide a single, authoritative, and governed "Master Entity Record" of legal entities globally by automating the collection of data directly from national registries (Business, Trade, Tax, and FI).

1.1 MVP Scope Boundaries (Tier 1 - Weeks 1-42)
**In-Scope**: ~35 free, no-login registries (APIs + free search/open data) providing ~60% global business entity coverage

**Included Access Methods**:
- **Free REST/SOAP/XML APIs** (11): LEI, ABN, CRN, CIK, ICO, CVR, KRS, Japan Corporate Number, Korea TIN, Norway Org No, Ireland CRO
- **Free Open Data Portals** (12): Germany (Handelsregister, Public Sector ID), Belgium (CBE open data), Luxembourg (RCS), Malta (MBR), Greece (AMF), Serbia (Trade & PIB), Croatia (Trade Register), Bosnia (MBS), Cyprus (Business + CBC), Denmark (CVR, FT-nummer), Poland (REGON)
- **Free Web Search/Lookup** (12): Bulgaria (BULSTAT), Finland (Y-tunnus), Czech Republic (ICO), Germany (Handelsregister free search), Luxembourg, Malta, Serbia, Croatia, Greece, Cyprus, Bosnia, Denmark

**Access Model**: All free (no subscription, no login required, no institutional agreements). Includes automated APIs, open data downloads, and free web portals.

**Sourcing Methods**: REST/SOAP/XML APIs, free data portal downloads, web scraping free portals, free search lookups; manual ingestion as fallback

1.2 Tier 2 Scope (Post-MVP, Q2 2025 onward)
**Tier 2 - Free with Registration/Keys** (~15 registries): Free but require developer registration, API keys, or basic setup
- Examples: UAE ERN (marketplace account), Canada BN (developer registration), Finland Y-tunnus (API key), Argentina CUIT (portal registration), Brazil CNPJ (registration), France SIREN (account), Latvia NBR, Lithuania JAR, Netherlands KvK, Singapore UEN, Switzerland Zefix
- Target: Q2 2025 after MVP stabilization

**Future Releases - Paid/Restricted (70+ registries)**: Paid subscriptions, contracts, legal frameworks, or institutional access only
- Examples: BIC (Swift subscription), Sweden Organisationsnummer (monthly fee), Austria (via brokers), Italy, Russia, individual PINs (Personnummer, PESEL, SSN, etc.)
- Target: Q3 2025+, pending customer demand and licensing negotiations

**Out-of-Scope**:
1. **Individual Personal IDs** (~25 registries): Personnummer, PESEL, SSN, PIN, BSN, etc. (Legal entity scope only per this PRD)
2. **Paid third-party providers**: D&B, Moody's, Equifax (use official registries instead)
3. **Manual-only portals** requiring web scraping (deferred to Phase 6 OCR/Manual extension)

**Registry Coverage Verification**: ✅ All ~35 free registries (APIs + free search/open data) covered by MVP; no free registries deferred. Coverage: ~60% global.

1.3 Target Entities
Internal Party records (legal entities only) mastered against external registry evidence. Out-of-scope: individuals, personal tax IDs, consumer data.

2. Ontology & Information Model
The platform uses a Bi-Temporal Graph Model to ensure that data is never overwritten, only versioned.

2.1 Core Entities
Internal Party: The unique internal identifier (UUID) for a legal entity.

Registry Record: An immutable snapshot of data fetched from a specific source at a specific time.

Golden Record: The "Best Version" of a Party, computed by applying survivorship rules to all linked Registry Records.

2.2 Key Metadata Fields (Header & Attribute Level)
Every record must carry:

Sourcing Mode: AUTOMATED vs. MANUAL.

Sourcing Method: API, Agent, File, Human-OCR.

Stale Flag: Binary indicator if a manual record has not been refreshed in 3 years.

Quality Health Flag: CLEAN, WARNING, CRITICAL.

Timestamps: * Valid From (Source): When the registry says it happened.

Ingestion Date (System): When we learned it. (Used for "Latest Trumps Quality" logic).

3. BPMN Level 1: Macro Processes
Party Establishment: Initial search and creation of a party.

Party Maintenance: Ongoing monitoring and triggered refreshes.

Entity Resolution (ER): Automated matching of registry results to internal parties.

Data Quality Management: Exception handling for "Stale" or "Broken" data.

Source Onboarding: Configuration of new registry adapters and mappings.

4. Detailed Process Specifications (BPMN Level 2)
4.1 Party Establishment (Onboarding)
Trigger: Internal request for a new entity.

Process:

Registry Broadcast: System queries all automated adapters for the jurisdiction.

STP Selection: Registry records are matched to internal entities.

Logic: Match on Reg Number + ISO Country = 100% STP link.

Mastering: Survivorship rules applied to create the Golden Record.

Fallback: If no API/Agent response, trigger Manual Ingestion task.

4.2 Party Maintenance (Refresh)
Trigger: Scheduled (3-year threshold) or Event-driven.

Process:

Automated Fetch: System attempts refresh via API/Agent.

Delta Analysis: Compares "Latest" vs. "Current."

STP Update: If "Latest" is newer, it replaces the Golden Record value immediately (Latest Trumps Quality).

Issue Generation: If the "Latest" data is NULL or logically invalid, a Quality Issue is raised, but the update may still persist depending on the field-level lock.

4.3 Manual Data Ingestion
Step 1: Operator uploads document (e.g., Certificate of Incorporation).

Step 2: AI-Scanning (OCR) extracts attributes.

Step 3: Human-in-the-loop verification (Maker/Checker).

Step 4: Promotion to "Manual" Registry Record.

5. Entity Resolution (ER) & Survivorship Configuration
5.1 ER Rule Configuration
The ER engine supports Straight-Through Processing (STP) based on Steward-defined weights:

Default STP Rule: (Registration Number Match) AND (Country Match) = Auto-Merge.

Default Fuzzy Rule: (Legal Name Similarity > 92%) AND (City Match) = Review Task.

Negative Match: Ability to flag two entities as "Never the Same" to prevent future ER logic from merging them.

5.2 Survivorship: "Latest Trumps Quality"
The system defaults to a Temporal Priority model.

Rule: The attribute with the most recent Ingestion_Timestamp is selected for the Golden Record.

Exceptions: Stewards can set "Attribute Locks" on fields that should not change (e.g., Date of Incorporation) unless manually overridden.

6. Lineage Visualization & Configuration
6.1 Lineage Visualization (Steward View)
The UI must provide a "Source-to-Master" matrix to help Stewards maintain rules.

Attribute Matrix: A table showing the Golden Record value in the first column, followed by every contributing Registry Record in chronological order.

Visual Cues: Highlight the "Winning" source and provide a "Deep Link" to the raw evidence (JSON/PDF).

6.2 Mapping Configuration (Steward Owned)
Data Stewards (not IT) manage the semantic mapping:

Mapping Studio: A UI to map Source Schema (e.g., company_status_code) to CDM (e.g., Entity_Status).

Transformation Logic: Ability to apply logic like IF source.value == 'A' THEN 'Active'.

7. Data Quality (DQ) & Case Management
Stale Data Rule: Automatically flag records as "Out of Date" after 3 years if no automated refresh is possible.

DQ Dashboard:

Registry Health: Monitor API success rates and agent failures.

Manual Maintenance List: Entities requiring human intervention.

Conflict Queue: Where "Latest" data significantly deviates from "Previous" (e.g., 50% name change).

8. User Stories
Data Steward (The "Governor")
US-STW-01: As a Steward, I want to map fields from a new registry API to the Common Data Model so that data is standardized automatically.

US-STW-02: As a Steward, I want to see a visual lineage of all sources for a record to determine why the "Latest" information was selected.

US-STW-03: As a Steward, I want to configure the ER rules to prioritize Tax IDs over Legal Names to increase STP rates.

Data Operations (The "Remediator")
US-OPS-01: As an Operator, I want to see which entities are "Out of Date" (3-year rule) so I can manually source new documents.

US-OPS-02: As an Operator, I want to use AI-scanning to extract data from a PDF certificate to avoid manual typing errors.

US-OPS-03: As an Operator, I want to resolve "Suspected Matches" by comparing two entities side-by-side.

9. Major UI Features & Data Products
9.1 UI Feature Set
Registry Health Center: Dashboard showing status (API/Manual), last refresh date, and automated coverage per country.

Golden Record Workbench: 360-degree view of the entity, including lineage, metadata flags, and associated DQ issues.

Mapping & ER Studio: Self-service configuration area for Stewards.

9.2 Data Products (Outputs)
Party API: Real-time access to Golden Records + Metadata.

Change Stream: Kafka/Streaming updates whenever a "Latest Trumps Quality" update occurs.

Audit Extract: A point-in-time snapshot proving lineage for any date in the past.