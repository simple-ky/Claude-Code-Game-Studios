---
title: Pipeline Map
tags: [map, pipeline, phases]
---

# Pipeline Map

The full game-development lifecycle in one diagram. Every phase has a `/gate-check` before the next.

> **Authoritative source:** `.claude/docs/workflow-catalog.yaml`. If this diagram and that file disagree, the YAML wins — please update this diagram.

---

## The full pipeline

```mermaid
flowchart TD
    Start(["/start"]) --> P1

    subgraph P1 [Phase 1 — Concept]
        B["/brainstorm"] --> SE["/setup-engine"]
        SE --> GC["game-concept.md"]
        GC --> AB["/art-bible"]
        AB --> MS["/map-systems"]
    end

    P1 --> G1{{"/gate-check<br/>Concept → Systems"}}
    G1 --> P2

    subgraph P2 [Phase 2 — Systems Design]
        DS["/design-system (×N)"] --> DR["/design-review (×N)"]
        DR --> RAG["/review-all-gdds"]
        RAG --> CC["/consistency-check (optional)"]
    end

    P2 --> G2{{"/gate-check<br/>Systems → Technical"}}
    G2 --> P3

    subgraph P3 [Phase 3 — Technical Setup]
        CA["/create-architecture"] --> AD["/architecture-decision (×N)"]
        AD --> AR["/architecture-review"]
        AR --> CM["/create-control-manifest"]
        CM --> AC["accessibility-requirements.md"]
    end

    P3 --> G3{{"/gate-check<br/>Technical → Pre-Prod"}}
    G3 --> P4

    subgraph P4 [Phase 4 — Pre-Production]
        AS["/asset-spec"] --> UD["/ux-design"]
        UD --> UR["/ux-review"]
        UR --> Pr["/prototype"]
        Pr --> CE["/create-epics"]
        CE --> CS["/create-stories"]
        CS --> TS["/test-setup"]
        TS --> SP1["/sprint-plan"]
        SP1 --> VS["/playtest-report (vertical slice)"]
    end

    P4 --> G4{{"/gate-check<br/>Pre-Prod → Production"}}
    G4 --> P5

    subgraph P5 [Phase 5 — Production]
        SP["/sprint-plan"] --> SR["/story-readiness"]
        SR --> Imp["/dev-story (loop)"]
        Imp --> CR["/code-review"]
        CR --> SDn["/story-done"]
        SDn --> Retro["/retrospective"]
    end

    P5 --> G5{{"/gate-check<br/>Production → Polish"}}
    G5 --> P6

    subgraph P6 [Phase 6 — Polish]
        PP["/perf-profile"] --> BC["/balance-check"]
        BC --> AA["/asset-audit"]
        AA --> PT3["/playtest-report (×3)"]
        PT3 --> TPo["/team-polish"]
    end

    P6 --> G6{{"/gate-check<br/>Polish → Release"}}
    G6 --> P7

    subgraph P7 [Phase 7 — Release]
        RC["/release-checklist"] --> PN["/patch-notes"]
        PN --> CL["/changelog"]
        CL --> LC["/launch-checklist"]
    end

    P7 --> Ship([Ship!])

    classDef phase fill:#e8f4fd,stroke:#2563eb,stroke-width:2px;
    classDef gate fill:#fef3c7,stroke:#d97706,stroke-width:2px;
    classDef start fill:#dcfce7,stroke:#16a34a,stroke-width:2px;
    class P1,P2,P3,P4,P5,P6,P7 phase;
    class G1,G2,G3,G4,G5,G6 gate;
    class Start,Ship start;
```

---

## Reading the diagram

- **Blue boxes** are phases (groups of skills).
- **Yellow diamonds** are gate-checks — advisory verdicts (PASS / CONCERNS / FAIL) that recommend whether to advance.
- **Green pills** are the start and end points.
- Each `/skill` is a slash command in Claude Code. Click into the matching note for details.

---

## Phase shortcuts

| Phase | Note | What you produce |
|-------|------|------------------|
| 1 | [[03-Phases/Phase-1-Concept]] | game-concept.md, art-bible.md, systems-index.md |
| 2 | [[03-Phases/Phase-2-Systems-Design]] | One GDD per system |
| 3 | [[03-Phases/Phase-3-Technical-Setup]] | architecture.md, ADRs, control-manifest.md |
| 4 | [[03-Phases/Phase-4-Pre-Production]] | UX specs, prototype, epics, stories, sprint plan |
| 5 | [[03-Phases/Phase-5-Production]] | Implemented code, playtest reports |
| 6 | [[03-Phases/Phase-6-Polish]] | Optimized + balanced build |
| 7 | [[03-Phases/Phase-7-Release]] | Release artifacts, patch notes |

---

## Gate behavior

Gates are **advisory, not hard-blocking**. Every `/gate-check` returns a verdict:

- ✅ **PASS** — all required artifacts present, can advance
- ⚠️ **CONCERNS** — gaps exist, listed with suggestions
- ❌ **FAIL** — missing required artifacts; advancing is risky

The user always decides whether to proceed. See [[02-Core-Concepts/Gates-and-Reviews]] for details.

---

## See also

- [[_Maps/Studio-Map]] — full vault map
- [[_Maps/Agent-Org-Chart]] — who works in each phase
- [[08-Reference/Workflow-Catalog-Explained]] — the YAML behind this diagram
