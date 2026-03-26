-- ============================================================================
-- Dharma CMS — PostgreSQL Schema
-- Generated from ERD design document.
-- All tables use UUID primary keys and UTC timestamps.
-- ============================================================================

-- ── Extension ──
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ══════════════════════════════════════════════════════════════════════════════
--  ACCOUNTS
-- ══════════════════════════════════════════════════════════════════════════════

CREATE TABLE accounts (
    id                        UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    firebase_uid              VARCHAR(128) NOT NULL UNIQUE,
    role                      VARCHAR(20)  NOT NULL DEFAULT 'citizen',  -- citizen | police | admin
    display_name              VARCHAR(255),
    email                     VARCHAR(255),
    phone_number              VARCHAR(20),
    photo_url                 TEXT,
    legacy_firestore_id       VARCHAR(128),
    legacy_source_collection  VARCHAR(50),
    created_at                TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at                TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE citizen_profiles (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    account_id    UUID NOT NULL UNIQUE REFERENCES accounts(id) ON DELETE CASCADE,
    dob           VARCHAR(20),
    gender        VARCHAR(20),
    aadhaar_number VARCHAR(20),
    house_no      VARCHAR(50),
    address_line1 TEXT,
    district      VARCHAR(100),
    state         VARCHAR(100) DEFAULT 'Tamil Nadu',
    country       VARCHAR(100) DEFAULT 'India',
    pincode       VARCHAR(10),
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE police_profiles (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    account_id    UUID NOT NULL UNIQUE REFERENCES accounts(id) ON DELETE CASCADE,
    rank          VARCHAR(100),
    district      VARCHAR(100),
    station_name  VARCHAR(255),
    range_name    VARCHAR(255),
    circle_name   VARCHAR(255),
    sdpo_name     VARCHAR(255),
    is_approved   BOOLEAN NOT NULL DEFAULT FALSE,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE device_tokens (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    account_id  UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    token       TEXT NOT NULL,
    platform    VARCHAR(20),    -- android | ios | web
    device_info VARCHAR(255),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ══════════════════════════════════════════════════════════════════════════════
--  PETITIONS
-- ══════════════════════════════════════════════════════════════════════════════

CREATE TABLE petitions (
    id                       UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    created_by_account_id    UUID REFERENCES accounts(id) ON DELETE SET NULL,
    submitted_by_account_id  UUID REFERENCES accounts(id) ON DELETE SET NULL,
    submission_channel       VARCHAR(20)  NOT NULL DEFAULT 'online',  -- online | offline
    petition_type            VARCHAR(100),
    title                    VARCHAR(500),
    petitioner_name          VARCHAR(255),
    grounds                  TEXT,
    description              TEXT,
    incident_address         TEXT,
    incident_at              TIMESTAMPTZ,
    district                 VARCHAR(100),
    station_name             VARCHAR(255),
    lifecycle_status         VARCHAR(50)  NOT NULL DEFAULT 'submitted',
    police_status            VARCHAR(50),
    police_sub_status        VARCHAR(100),
    is_anonymous             BOOLEAN NOT NULL DEFAULT FALSE,
    latitude                 DOUBLE PRECISION,
    longitude                DOUBLE PRECISION,
    legacy_firestore_id      VARCHAR(128),
    legacy_case_ref          VARCHAR(128),
    created_at               TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at               TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE petition_assignments (
    id                     UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    petition_id            UUID NOT NULL REFERENCES petitions(id) ON DELETE CASCADE,
    assigned_by_account_id UUID REFERENCES accounts(id) ON DELETE SET NULL,
    assigned_to_account_id UUID REFERENCES accounts(id) ON DELETE SET NULL,
    scope_type             VARCHAR(50),
    status                 VARCHAR(50) DEFAULT 'assigned',
    scope_district         VARCHAR(100),
    scope_station_name     VARCHAR(255),
    notes                  TEXT,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE petition_attachments (
    id                     UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    petition_id            UUID NOT NULL REFERENCES petitions(id) ON DELETE CASCADE,
    uploaded_by_account_id UUID REFERENCES accounts(id) ON DELETE SET NULL,
    file_url               TEXT NOT NULL,
    file_name              VARCHAR(255),
    file_type              VARCHAR(100),
    file_size              INTEGER,
    description            TEXT,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE petition_updates (
    id                   UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    petition_id          UUID NOT NULL REFERENCES petitions(id) ON DELETE CASCADE,
    added_by_account_id  UUID REFERENCES accounts(id) ON DELETE SET NULL,
    update_text          TEXT,
    ai_status            VARCHAR(50),
    ai_score             DOUBLE PRECISION,
    upload_errors        TEXT,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE petition_update_attachments (
    id                 UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    petition_update_id UUID NOT NULL REFERENCES petition_updates(id) ON DELETE CASCADE,
    file_url           TEXT NOT NULL,
    file_name          VARCHAR(255),
    file_type          VARCHAR(100),
    file_size          INTEGER,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE petition_saves (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    account_id    UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    petition_id   UUID NOT NULL REFERENCES petitions(id) ON DELETE CASCADE,
    snapshot_json JSONB,
    note          TEXT,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ══════════════════════════════════════════════════════════════════════════════
--  CASES
-- ══════════════════════════════════════════════════════════════════════════════

CREATE TABLE cases (
    id                    UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    petition_id           UUID REFERENCES petitions(id) ON DELETE SET NULL,
    case_reference        VARCHAR(100) UNIQUE,
    fir_number            VARCHAR(100),
    title                 VARCHAR(500),
    district              VARCHAR(100),
    police_station        VARCHAR(255),
    status                VARCHAR(50)  NOT NULL DEFAULT 'open',
    date_filed            DATE,
    fir_filed_at          TIMESTAMPTZ,
    complaint_statement   TEXT,
    incident_details      TEXT,
    acts_and_sections_text TEXT,
    legacy_firestore_id   VARCHAR(128),
    created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE case_people (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    case_id     UUID NOT NULL REFERENCES cases(id) ON DELETE CASCADE,
    role        VARCHAR(50) NOT NULL,  -- complainant | victim | accused | witness | reporting_person | petitioner
    name        VARCHAR(255) NOT NULL,
    father_name VARCHAR(255),
    age         INTEGER,
    gender      VARCHAR(20),
    address     TEXT,
    phone       VARCHAR(20),
    id_type     VARCHAR(50),
    id_number   VARCHAR(50),
    description TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE case_officers (
    id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    case_id           UUID NOT NULL REFERENCES cases(id) ON DELETE CASCADE,
    officer_account_id UUID REFERENCES accounts(id) ON DELETE SET NULL,
    officer_name      VARCHAR(255),
    officer_rank      VARCHAR(100),
    role              VARCHAR(50),  -- reporting_officer | dispatch_officer | investigating_officer | supervising_officer
    assigned_date     DATE,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE case_crime_details (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    case_id         UUID NOT NULL UNIQUE REFERENCES cases(id) ON DELETE CASCADE,
    crime_type      VARCHAR(100),
    ipc_sections    TEXT,
    description     TEXT,
    modus_operandi  TEXT,
    weapon_used     VARCHAR(255),
    property_stolen TEXT,
    property_value  DOUBLE PRECISION,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE case_journal_entries (
    id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    case_id           UUID NOT NULL REFERENCES cases(id) ON DELETE CASCADE,
    officer_account_id UUID REFERENCES accounts(id) ON DELETE SET NULL,
    officer_name      VARCHAR(255),
    officer_rank      VARCHAR(100),
    activity_type     VARCHAR(100),
    entry_text        TEXT,
    entry_at          TIMESTAMPTZ,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE case_journal_attachments (
    id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    journal_entry_id UUID NOT NULL REFERENCES case_journal_entries(id) ON DELETE CASCADE,
    file_url         TEXT NOT NULL,
    file_name        VARCHAR(255),
    file_type        VARCHAR(100),
    file_size        INTEGER,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE case_documents (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    case_id       UUID NOT NULL REFERENCES cases(id) ON DELETE CASCADE,
    document_type VARCHAR(50),   -- fir | investigation_report | chargesheet | evidence | other
    title         VARCHAR(500),
    file_url      TEXT NOT NULL,
    file_name     VARCHAR(255),
    file_type     VARCHAR(100),
    file_size     INTEGER,
    generated_by  VARCHAR(20),   -- ai | manual
    description   TEXT,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ══════════════════════════════════════════════════════════════════════════════
--  COMPLAINT DRAFTS
-- ══════════════════════════════════════════════════════════════════════════════

CREATE TABLE complaint_drafts (
    id                     UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    created_by_account_id  UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    title                  VARCHAR(500),
    complaint_type         VARCHAR(100),
    status                 VARCHAR(50) NOT NULL DEFAULT 'in_progress',
    is_anonymous           BOOLEAN NOT NULL DEFAULT FALSE,
    summary                TEXT,
    generated_complaint    TEXT,
    answers_json           JSONB,
    state_json             JSONB,
    submitted_petition_id  UUID REFERENCES petitions(id) ON DELETE SET NULL,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE complaint_draft_messages (
    id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    draft_id     UUID NOT NULL REFERENCES complaint_drafts(id) ON DELETE CASCADE,
    role         VARCHAR(20) NOT NULL,  -- user | assistant
    content      TEXT NOT NULL,
    message_type VARCHAR(20) DEFAULT 'text',
    sequence     INTEGER,
    extra        JSONB,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ══════════════════════════════════════════════════════════════════════════════
--  LEGAL QUERIES
-- ══════════════════════════════════════════════════════════════════════════════

CREATE TABLE legal_query_threads (
    id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    title      VARCHAR(500),
    category   VARCHAR(100),
    status     VARCHAR(50) NOT NULL DEFAULT 'active',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE legal_query_messages (
    id        UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    thread_id UUID NOT NULL REFERENCES legal_query_threads(id) ON DELETE CASCADE,
    role      VARCHAR(20) NOT NULL,  -- user | assistant
    content   TEXT NOT NULL,
    sequence  INTEGER,
    extra     JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ══════════════════════════════════════════════════════════════════════════════
--  PROMPT TEMPLATES
-- ══════════════════════════════════════════════════════════════════════════════

CREATE TABLE prompt_templates (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name        VARCHAR(255) NOT NULL UNIQUE,
    category    VARCHAR(100),
    template    TEXT NOT NULL,
    variables   TEXT[],
    description TEXT,
    is_active   BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ══════════════════════════════════════════════════════════════════════════════
--  INDEXES
-- ══════════════════════════════════════════════════════════════════════════════

CREATE INDEX idx_accounts_firebase_uid   ON accounts(firebase_uid);
CREATE INDEX idx_petitions_created_by    ON petitions(created_by_account_id);
CREATE INDEX idx_petitions_status        ON petitions(lifecycle_status);
CREATE INDEX idx_petition_assignments_pid ON petition_assignments(petition_id);
CREATE INDEX idx_petition_attachments_pid ON petition_attachments(petition_id);
CREATE INDEX idx_petition_updates_pid    ON petition_updates(petition_id);
CREATE INDEX idx_petition_saves_aid      ON petition_saves(account_id);
CREATE INDEX idx_cases_petition          ON cases(petition_id);
CREATE INDEX idx_case_people_cid         ON case_people(case_id);
CREATE INDEX idx_case_officers_cid       ON case_officers(case_id);
CREATE INDEX idx_journal_entries_cid     ON case_journal_entries(case_id);
CREATE INDEX idx_journal_attach_eid      ON case_journal_attachments(journal_entry_id);
CREATE INDEX idx_case_documents_cid      ON case_documents(case_id);
CREATE INDEX idx_complaint_drafts_aid    ON complaint_drafts(created_by_account_id);
CREATE INDEX idx_draft_messages_did      ON complaint_draft_messages(draft_id);
CREATE INDEX idx_legal_threads_aid       ON legal_query_threads(account_id);
CREATE INDEX idx_legal_messages_tid      ON legal_query_messages(thread_id);
CREATE INDEX idx_device_tokens_aid       ON device_tokens(account_id);

-- ══════════════════════════════════════════════════════════════════════════════
--  GEOGRAPHY — Police Hierarchy + Pincodes
--  Auto-seeded from JSON on first startup.
-- ══════════════════════════════════════════════════════════════════════════════

CREATE TABLE districts (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    state         VARCHAR(100) NOT NULL DEFAULT 'Andhra Pradesh',
    name          VARCHAR(200) NOT NULL,
    code          VARCHAR(50),
    range_name    VARCHAR(200),
    is_active     BOOLEAN      NOT NULL DEFAULT TRUE,
    sort_order    INTEGER      NOT NULL DEFAULT 0,
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_district_state_name UNIQUE (state, name)
);

CREATE TABLE sdpos (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    district_id   UUID         NOT NULL REFERENCES districts(id) ON DELETE CASCADE,
    name          VARCHAR(200) NOT NULL,
    is_active     BOOLEAN      NOT NULL DEFAULT TRUE,
    sort_order    INTEGER      NOT NULL DEFAULT 0,
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_sdpo_district_name UNIQUE (district_id, name)
);

CREATE TABLE circles (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sdpo_id       UUID         NOT NULL REFERENCES sdpos(id) ON DELETE CASCADE,
    name          VARCHAR(200) NOT NULL,
    is_active     BOOLEAN      NOT NULL DEFAULT TRUE,
    sort_order    INTEGER      NOT NULL DEFAULT 0,
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_circle_sdpo_name UNIQUE (sdpo_id, name)
);

CREATE TABLE police_stations (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    circle_id     UUID         NOT NULL REFERENCES circles(id) ON DELETE CASCADE,
    name          VARCHAR(300) NOT NULL,
    station_code  VARCHAR(50),
    phone         VARCHAR(20),
    address       TEXT,
    is_active     BOOLEAN      NOT NULL DEFAULT TRUE,
    sort_order    INTEGER      NOT NULL DEFAULT 0,
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_station_circle_name UNIQUE (circle_id, name)
);

CREATE TABLE pincodes (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    district_id   UUID         NOT NULL REFERENCES districts(id) ON DELETE CASCADE,
    pincode       VARCHAR(10)  NOT NULL,
    area_name     VARCHAR(200),
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_pincode_district UNIQUE (district_id, pincode)
);

-- Geography indexes
CREATE INDEX idx_sdpos_district          ON sdpos(district_id);
CREATE INDEX idx_circles_sdpo            ON circles(sdpo_id);
CREATE INDEX idx_stations_circle         ON police_stations(circle_id);
CREATE INDEX idx_pincodes_district       ON pincodes(district_id);
