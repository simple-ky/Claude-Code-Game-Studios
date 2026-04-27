---
title: Skills vs Agents vs Docs
tags: [concept, architecture]
---

# Skills vs Agents vs Docs

The three layers that compose this entire system. Once you see this, you can predict where any new feature fits.

---

## The three layers

```mermaid
flowchart TD
    User([You])
    Skill["Skill<br/>(slash command)"]
    Agent["Agent<br/>(AI persona)"]
    Doc["Document / Code<br/>(file on disk)"]

    User -->|invokes| Skill
    Skill -->|spawns| Agent
    Agent -->|writes| Doc
    Doc -->|read by next| Skill

    classDef u fill:#fef3c7,stroke:#d97706,stroke-width:2px;
    classDef s fill:#dbeafe,stroke:#2563eb,stroke-width:2px;
    classDef a fill:#e0e7ff,stroke:#4338ca,stroke-width:2px;
    classDef d fill:#dcfce7,stroke:#15803d,stroke-width:2px;
    class User u;
    class Skill s;
    class Agent a;
    class Doc d;
```

| Layer | What it is | Example | Where it lives |
|-------|-----------|---------|----------------|
| **Skill** | A slash command — the user-facing verb | `/design-system` | `.claude/skills/<name>/SKILL.md` |
| **Agent** | An AI persona — the noun that does the work | `game-designer` | `.claude/agents/<name>.md` |
| **Document** | A file on disk — the artifact produced | `design/gdd/movement.md` | Anywhere under `design/`, `docs/`, `production/`, `src/`, `assets/` |

---

## How they connect

**Skills are the API.** You only ever interact with the skill layer. Type `/brainstorm`, the skill knows everything else.

**Agents are the implementation.** A skill spawns whatever agents it needs in whatever order, sequentially or in parallel. You never spawn agents directly (well, you can via the `Task` tool, but that's a power-user move).

**Documents are the persistent state.** Every skill writes files to known locations. The next skill in the pipeline reads those files. This is why **the file is the memory, not the conversation** — see [[07-Project-Conventions/Context-Management]].

---

## Concrete example: `/design-system`

When you run `/design-system movement`, here's what happens:

```mermaid
sequenceDiagram
    participant U as You
    participant Sk as /design-system
    participant GD as game-designer
    participant SD as systems-designer
    participant FS as design/gdd/movement.md

    U->>Sk: /design-system movement
    Sk->>FS: Read systems-index.md, technical-preferences.md
    Sk->>U: "I'm about to author the GDD. Continue?"
    U-->>Sk: Yes
    Sk->>GD: Spawn for design intent
    GD-->>Sk: Returns: pillars, player fantasy
    Sk->>SD: Spawn for formula authoring
    SD-->>Sk: Returns: formulas, edge cases
    Sk->>FS: Write skeleton with section headers
    Sk->>U: "Section 1 (Overview) draft. Approve?"
    U-->>Sk: Approved
    Sk->>FS: Write section 1
    Note over Sk,FS: ...repeat per section...
    Sk->>U: "GDD complete. Run /design-review next."
```

The user sees a single `/design-system` command. The skill orchestrates `game-designer` and `systems-designer`, manages incremental file writes, and asks for approval at section boundaries.

---

## Why three layers and not one

You could imagine a flat system: just agents, no skills, no documents. Why this structure?

| Reason | Without 3 layers | With 3 layers |
|--------|------------------|---------------|
| **Discoverability** | "Which agent do I talk to?" | `/<tab>` — autocompletes |
| **Composition** | Manually orchestrate agents every time | Skills bundle the orchestration |
| **Persistence** | Lose context to compaction | Files survive sessions |
| **Cost control** | Always Opus | Skills assign right tier per agent |
| **Versionability** | Hard to track | Files in git, ADRs explain decisions |

Each layer earns its place by giving you something the others can't.

---

## The data flow shape

The pipeline is a chain of read → think → write → next-skill-reads:

```mermaid
flowchart LR
    A[/brainstorm/] --> B[game-concept.md]
    B --> C[/map-systems/]
    C --> D[systems-index.md]
    D --> E[/design-system/]
    E --> F[GDDs]
    F --> G[/create-architecture/]
    G --> H[architecture.md]
    H --> I[/architecture-decision/]
    I --> J[ADRs]
    J --> K[/create-control-manifest/]
    K --> L[control-manifest.md]
    L --> M[/create-stories/]
    M --> N[story files]
    N --> O[/dev-story/]
    O --> P[code]

    classDef skill fill:#dbeafe,stroke:#2563eb;
    classDef doc fill:#dcfce7,stroke:#15803d;
    class A,C,E,G,I,K,M,O skill;
    class B,D,F,H,J,L,N,P doc;
```

Each blue box reads the green boxes before it and writes the green box after it. **No state is held in conversation memory** — everything important goes to disk.

---

## How this affects you

When you're stuck on "what do I do?", ask:

1. *What document am I trying to produce?* → Check [[06-Documents-Produced/Document-Map]]
2. *Which skill produces that document?* → Check [[05-Skills/Skills-Index]]
3. *What does that skill need as input?* → Read its SKILL.md
4. *Do those inputs exist?* → If not, work backwards

The pipeline is just a topological sort over (input doc → skill → output doc) edges.

---

## See also

- [[02-Core-Concepts/The-7-Phase-Pipeline]] — the macro-shape of skill chains
- [[02-Core-Concepts/The-Studio-Metaphor]] — the agent layer, deeper
- [[06-Documents-Produced/Document-Map]] — the document layer, mapped
- [[05-Skills/Skills-Index]] — every skill, indexed
