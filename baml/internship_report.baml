// internship_report.baml
//
// Typed-output schemas and functions for the UoN BA. Interior Design
// attachment report (Dynamism Icons Ltd, Tatu City — July 2026).
//
// All output is first-person, past-tense, evidence-quoted. Every claim
// references either a transcript segment, a user-supplied file, or a
// knowledge-graph entity so the report-with-context skill can validate.
//
// Pipeline:
//   knowledge-graph.json  ->  BuildCompany1Report  ->  Company1Report
//                          ->  BuildLogbookFourWeeks -> LogbookFourWeeks
//
// Use pi-baml's `baml_exec` / `baml_run` at runtime. No client block,
// no generator block, no env vars — per the baml skill rules.

// ---------------------------------------------------------------------------
// Shared primitives
// ---------------------------------------------------------------------------

class EvidenceQuote {
    source string @description("Audio file or user-supplied document the quote came from, e.g. 'company 1.m4a' or 'gemini chat 1.pdf p.6'")
    quote string @description("The verbatim line spoken or written — must appear in the source. Do not paraphrase.")
    segment string? @description("Timestamp in seconds (audio) or page number (PDF) where the quote appears")
}

class Citation {
    label string @description("Short bibliographic label, e.g. 'University of Nairobi, BA Interior Design logbook 2026'")
    url_or_path string? @description("Path on disk or stable URL when known")
}

class IllustrationSlot {
    subject string @description("What the illustration must depict, e.g. 'Site office partition plan with seven labelled rooms'")
    placement string @description("Where in the chapter or week the slot sits, e.g. 'after the partition-list paragraph'")
    medium "photo" | "sketch" | "diagram" | "table"
    width_hint "half_page" | "full_page" | "margin"
    caption string? @description("One-line caption for the figure list; null if none drafted")
}

// ---------------------------------------------------------------------------
// Company 1 report chapter
// ---------------------------------------------------------------------------

class BulletinAnswer {
    question string @description("The exact question as printed in 'bulletin questions - company 1', one per entry")
    answer_paragraphs string[] @description("One or more short paragraphs in the student's first-person past-tense voice; no filler, no summary from filename memory")
    evidence EvidenceQuote[] @description("At least one verbatim quote per question; the report-with-context validator refuses paragraphs without traceable evidence")
    illustration_slots IllustrationSlot[] @description("Zero or more slots where a sketch / photo should appear in the final layout pass")
}

class CompanyProfile {
    name string @description("Trading name as registered, e.g. 'Dynamism Icons Ltd'")
    sector string @description("What the firm does in one line, e.g. 'Design-build contractor at Tatu City'")
    location string @description("Site address or studio address — leave blank if [REDACTED — ASK user] applies")
    supervisor string @description("Head architect / supervising architect name as captured; mark [REDACTED] if not yet captured")
    attachment_period string @description("Inclusive dates of the attachment period, e.g. 'mid-July 2026 (exact day uncertain)'")
}

class ReflectionBlock {
    what_i_did string @description("Short first-person summary of the four-week arc at this company, past tense, no filler")
    what_i_learned string @description("Skills gained across the four weeks, framed as evidence-backed growth")
    what_still_unclear string @description("Topics that still need a follow-up ramble — these become gaps[] entries, never silently filled in")
}

class Company1Report {
    chapter_title string @description("e.g. 'Company 1 — Dynamism Icons Ltd (Tatu City)'")
    profile CompanyProfile
    first_day_experience BulletinAnswer @description("Q1 from bulletin: arrival, PPE induction, sent-home episode")
    daily_routine BulletinAnswer @description("Q2 from bulletin: clock-in, foreman briefing, materials-driven day")
    phase1_site_establishment BulletinAnswer @description("Q3: site clearance, fence erection, partitions, toilets")
    phase2_grid_layout BulletinAnswer @description("Q4: 5% gradient, backhoe clearance, profile timbers, horse-pipe method")
    phase3_excavation BulletinAnswer @description("Q5: backhoe cost and time, manual digging, architect + DCC approvals")
    phase4_concrete_pour BulletinAnswer @description("Q6: steel mesh baskets, 25 bays, circular columns, pouring and compaction")
    reflection ReflectionBlock
    illustration_slots IllustrationSlot[] @description("Chapter-level slots reserved for the design pass")
    citations Citation[] @description("Only sources actually cited; APA 7th labels, no fabricated references")
}

// ---------------------------------------------------------------------------
// Logbook entry for four weeks
// ---------------------------------------------------------------------------

class LogbookDayEntry {
    weekday string @description("Mon | Tue | Wed | Thu | Fri | Sat")
    date_iso string @description("ISO date e.g. '2026-07-13'; use 'approximate' in date_iso only if user is uncertain and reflect that in weekday_summary")
    weekday_summary string @description("One sentence naming the day's main activity, past tense, first person")
    tasks string[] @description("Concrete tasks performed that day, in chronological order")
    supervisor_initials string? @description("Site supervisor's initials — leave null unless captured")
}

class WeeklyLogbookEntry {
    week_number int @description("1 to 4 for the four-week Co.1 attachment")
    date_range string @description("Human range, e.g. '13 Jul 2026 — 19 Jul 2026 (approx)'")
    company string @description("Always 'Dynamism Icons Ltd' for this logbook block")
    department string @description("e.g. 'Site / groundsman'")
    days LogbookDayEntry[] @description("Mon–Fri entries; skip weekends unless work happened")
    skills_gained string[] @description("Skill names from the knowledge graph that were exercised this week")
    supervisor_remarks string? @description("One-line remark block, e.g. 'PPE compliance verified; site safety standards met.'")
    supervisor_initials string? @description("Initials of the on-site supervisor; null if not yet captured")
    illustration_slots IllustrationSlot[] @description("Sketches / photos to embed for the week")
}

class LogbookFourWeeks {
    student_name string @description("Full legal name as printed on the logbook; mark [REDACTED — ASK user] if not yet captured")
    registration_no string @description("University of Nairobi registration number; mark [REDACTED — ASK user] if not yet captured")
    programme string @description("Always 'BA. Interior Design, University of Nairobi'")
    company_name string @description("Always 'Dynamism Icons Ltd'")
    attachment_period string @description("Inclusive dates e.g. 'mid-July 2026 — early August 2026'")
    site_address string @description("Tatu City, Kiambu County — plot R 348, Kijani Ridge")
    weeks WeeklyLogbookEntry[] @description("Four entries, weeks 1 to 4, in chronological order")
    overall_remarks string? @description("Closing remark across all four weeks — site supervisor signs here at the end of Co.1")
}

// ---------------------------------------------------------------------------
// Functions
// ---------------------------------------------------------------------------

function BuildCompany1Report(knowledge_graph_json: string, student_name: string, registration_no: string) -> Company1Report {
    client PiClient
    prompt #"
        You are writing Chapter 2 of a University of Nairobi BA. Interior Design
        attachment report for the company "Dynamism Icons Ltd" (Tatu City).

        Voice: first-person, past tense, no filler, no marketing language. Every
        paragraph must rest on a verbatim transcript quote or a user-stated fact
        from a named source. Never invent a number, date, supervisor name, course
        code, or reference.

        The knowledge graph below is the only source of truth. If a field is
        marked [REDACTED — ASK user], leave it redacted in the output. Do not
        guess the redacted values. If the graph has no evidence for a claim,
        place the claim in `reflection.what_still_unclear` instead of writing
        it as fact.

        Use the bulletin-question order:
          1. First-day experience (arrival, PPE, sent home)
          2. Daily routine (clock-in, foreman, materials-driven day)
          3. Phase 1 — Site Establishment and Preparation
          4. Phase 2 — Grid Layout and Accuracy Verification
          5. Phase 3 — Excavation and Structural Approvals
          6. Phase 4 — Concrete Pouring and Reinforcement

        Each answer_paragraphs entry must include at least one matching
        EvidenceQuote. The report-with-context validator will refuse any
        paragraph that cannot trace back to a transcript segment or a named
        user-supplied file.

        Student name for this report:
          {{ student_name }}

        Registration number for this report:
          {{ registration_no }}

        Knowledge graph (JSON):
        {{ knowledge_graph_json }}

        {{ ctx.output_format }}
    "#
}

function BuildLogbookFourWeeks(knowledge_graph_json: string, student_name: string, registration_no: string, supervisor_name: string) -> LogbookFourWeeks {
    client PiClient
    prompt #"
        You are filling in the four-week Co.1 block of the
        "4.0_ATTACHMENT LOGBOOK" for a UoN BA. Interior Design student.

        Voice: terse, logbook-style, past tense, third-person allowed for the
        student. Every task line must trace to an evidence quote in the
        knowledge graph. Do not fabricate dates — the user is uncertain about
        the exact day in mid-July, so use the dates already declared in the
        graph (week-001 starts 13 Jul 2026, etc.) and add "(approx.)" where
        the user said so.

        For each week, list Mon–Fri tasks, then skills_gained (use the skill
        names exactly as in the knowledge graph), then a one-line
        supervisor_remarks. The supervisor's name is supplied below; their
        initials are not, so leave supervisor_initials null.

        Never add a task that is not in the knowledge graph for that week.
        When a phase spans weeks (e.g. site office construction covered
        weeks 2 and 3), split the tasks honestly across the days instead
        of compressing them.

        Student:
          name: {{ student_name }}
          reg_no: {{ registration_no }}

        Site supervisor:
          {{ supervisor_name }}

        Knowledge graph (JSON):
        {{ knowledge_graph_json }}

        {{ ctx.output_format }}
    "#
}