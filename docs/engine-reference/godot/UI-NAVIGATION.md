# Godot 4.6.2 Editor UI — Navigation Reference

| Field | Value |
|-------|-------|
| **Engine Version** | Godot 4.6.2 |
| **Last Verified** | 2026-05-23 |
| **Source** | Official Godot 4.6 docs + 4.5/4.6 release announcements |
| **LLM Knowledge Cutoff** | May 2025 (~Godot 4.3) |

## Why This File Exists

Claude's training data covers Godot up to roughly 4.3. Versions 4.4, 4.5, and
4.6 introduced significant **editor UI reorganization** that the model does not
know about. This file documents the actual 4.6.2 editor layout so that
step-by-step click instructions and `mcp__godot__*` tool calls target the
correct paths.

**Hard rule for agents**: If the UI element you need is not documented here,
fetch the relevant page from `https://docs.godotengine.org/en/4.6/` (pin the
version — do not use `/en/stable/`), and add the verified information here
before guiding the user.

## Sourcing Rule

Godot's **migration docs** (`/tutorials/migrating/upgrading_to_godot_4.X.html`)
document API breaks ONLY — they are silent on UI changes. The authoritative
sources for UI changes are:

- Release announcements: `https://godotengine.org/releases/4.6/` and `/4.5/`
- The "Editor manual" tree: `https://docs.godotengine.org/en/4.6/tutorials/editor/`

## Main Editor Layout (4.6.2)

```
+---------------------------------------------------------------+
| Menu bar:   Scene  Project  Debug  Editor  Help               |
+---------------------------------------------------------------+
| Workspace tabs (top center):  2D  |  3D  |  Script  |  AssetLib |
+--------+--------------------------------------------+---------+
|        |                                            |         |
| Left   |                                            | Right   |
| dock   |              Viewport                      | dock    |
| stack  |       (or Script editor / AssetLib)        | stack   |
|        |                                            |         |
+--------+--------------------------------------------+---------+
| Bottom dock stack: Output | Debugger | Audio | Animation | Shader | Search results | etc. |
+---------------------------------------------------------------+
```

### Default Dock Assignments

| Dock | Default Location | Purpose |
|------|-----------------|---------|
| **Scene** tree | Top-left | Node hierarchy of the current scene |
| **FileSystem** | Bottom-left | Project file browser |
| **Import** | Bottom-left (tab next to FileSystem) | Re-import settings for selected asset (reintroduced in 4.5 for batch editing) |
| **Inspector** | Right (top) | Properties of selected node/resource |
| **Node** | Right (tab next to Inspector) | Signals and groups for selected node |
| **History** | Right (tab next to Inspector) | Undo/redo history |
| **Output** | Bottom | `print()` output and warnings |
| **Debugger** | Bottom | Stack, profiler, monitors, video memory, misc |
| **Audio** | Bottom | Audio buses |
| **Animation** | Bottom | Animation editor (visible when AnimationPlayer selected) |
| **Shader** | Bottom | Shader code editor (visible when shader selected) |

### 4.6 Unified Docking System (Important — new behavior)

In Godot 4.6, **bottom panels became regular docks**. This means:

- Any dock (Output, Debugger, Inspector, FileSystem, …) can be dragged to any
  side (left / right / bottom) or floated into its own window.
- Floating: click the **3-vertical-dots** icon at the top of a dock → **Make Floating**.
- Reordering: drag a dock's tab header to a new position.
- The user's actual layout may not match the defaults above. **When guiding the
  user, ask "where do you currently see the X dock?" rather than asserting a
  fixed location.**

## Main Menu Reference (4.6.2)

### Scene Menu

| Item | Action |
|------|--------|
| New Scene | Create empty scene |
| New Inherited Scene… | Create scene inheriting from another |
| Open Scene… | Open `.tscn` / `.scn` |
| Reopen Closed Scene | Reopen last-closed |
| Open Recent | Recent scenes submenu |
| Save Scene | Save current |
| Save Scene As… | Save with new path |
| Save All Scenes | Save every open scene |
| Quick Open… | Resource picker (now with **live preview** in 4.6) |
| Quick Open Scene… | Scene-only picker |
| Quick Open Script… | Script-only picker |
| Close Scene | Close current tab |
| Quit | Exit editor |

### Project Menu

| Item | Action |
|------|--------|
| **Project Settings…** | Per-project configuration (rendering, physics, input map, layer names, autoload, plugins, etc.) |
| Version Control | Git plugin actions (if installed) |
| Export… | Open Export window for platform builds |
| Pack Project as ZIP… | Bundle entire project |
| Install Android Build Template… | Required before Android export |
| Open User Data Folder | OS file browser to `user://` directory |
| Customize Engine Build Configuration… | Cross-compile / feature flags |
| Reload Current Project | Re-open project |
| Quit to Project List | Return to Project Manager |

### Debug Menu

| Item | Action |
|------|--------|
| Deploy with Remote Debug | Run with debugger attached on device |
| Small Deploy with Network Filesystem | Lightweight mobile deploy |
| Visible Collision Shapes | Toggle collision shape rendering when running |
| Visible Paths | Toggle path rendering |
| Visible Navigation | Toggle nav mesh rendering |
| Visible Avoidance | Toggle avoidance debug |
| Visible CanvasItem Redraws | Highlight redrawn CanvasItems |
| Synchronize Scene Changes | Live-reload scene tree on run |
| Synchronize Script Changes | Live-reload scripts on run |
| Customize Run Instances… | Multi-instance launch settings |

### Editor Menu

| Item | Action |
|------|--------|
| **Editor Settings…** | Editor-wide preferences (theme, font, shortcuts) |
| Command Palette… | Ctrl+Shift+P — fuzzy command search (includes named `EditorScript` files since 4.5) |
| Editor Docks | Show/hide individual docks |
| Editor Layout | Save/load custom dock layouts |
| Take Screenshot | Capture editor window |
| Toggle Fullscreen | Maximize editor |
| Open Editor Data/Settings Folder | OS browser to editor config |
| Manage Editor Features… | Enable/disable editor subsystems |
| Manage Export Templates… | Install/update platform export templates |
| Configure FBX Importer… | External FBX2glTF path |

### Help Menu

| Item | Action |
|------|--------|
| Search Help | Built-in API docs |
| Online Documentation | Opens browser to docs.godotengine.org |
| Forum | Opens browser to forum.godotengine.org |
| Community | Opens chat/community links |
| Report a Bug | Opens browser to GitHub issues |
| Suggest a Feature | Opens browser to godot-proposals |
| Send Docs Feedback | Opens browser to docs feedback form |
| About Godot | Version + author dialog |
| Support Godot Development | Donation page |

## Version-Drift Traps (Things That Moved or Were Renamed)

These are paths where pre-4.4 training data will mislead. Always use the
**RIGHT** column.

| Topic | OLD (≤ 4.3) | RIGHT (4.6.2) |
|-------|-------------|---------------|
| 2D/3D editor mode toggle | "Select Mode" / no separate select | **"Transform mode"** + separate **"Select-only mode"** (decoupled in 4.6) |
| Bottom-panel docks | Fixed at bottom | Regular docks — can be moved or floated (4.6 unified docking) |
| Import dock | Existed → removed in 4.4 → **reintroduced in 4.5** | Available as a tab in the left dock stack |
| Inspector array editing | Vertical-only layout | **Redesigned for horizontal space** in 4.6 |
| Editor theme | "Godot Minimal Theme" default | **"Modern" theme** default in 4.6 (Classic still available in Editor Settings) |
| Layer-flag editing | Click individual checkboxes | **Drag across flags** to set multiple (4.6) |
| Group assignment | One node at a time | **Multi-node group assignment** (4.6) |
| Open scenes/scripts list | Scene tabs only | **New menu button** showing all open scenes/scripts (4.6) |
| Game audio during debug | No toggle | **"Mute Game" toggle** in Game view (4.5) |
| Editor language switch | Required restart | **On-demand switching** (4.5) — no restart |
| Project Manager | No duplicate function | **"Duplicate" button** (4.5) + **Recovery Mode** dropdown (4.6) |
| Script editor color values | Plain text | **Color picker preview** next to `Color()` literals (4.5) |
| Inspector property groups | Group label only | **Checkbox toggle** via `PROPERTY_HINT_GROUP_ENABLE` (4.5) |
| HiDPI icons | Blurry on scaled displays | **DPI-aware sharp icons** (4.5) |
| Screen reader support | None | **AccessKit integration** (4.5, experimental) |

## Project Settings — Common Paths

**Open:** `Project → Project Settings…`

The Project Settings window has a left-side **category tree** and right-side
**property editor**. Top tabs: **General**, **Input Map**, **Localization**,
**Autoload**, **Shader Globals**, **Plugins**, **Import Defaults**.

Frequently asked paths (search box at top of Project Settings is faster than
navigating):

| Setting | Category path |
|---------|---------------|
| Window size | `Display → Window` |
| Stretch mode | `Display → Window → Stretch` |
| Default clear color | `Rendering → Environment → Default Clear Color` |
| Physics engine selection (Jolt vs Godot Physics) | `Physics → 3D → Physics Engine` |
| 2D physics engine | `Physics → 2D → Physics Engine` |
| Rendering method (Forward+, Mobile, Compatibility) | `Rendering → Renderer → Rendering Method` |
| Autoload (singletons) | `Autoload` tab (top of window) |
| Input actions | `Input Map` tab (top of window) |
| Custom C# project settings | `Dotnet → Project` |
| Layer name overrides (Physics 2D/3D, Render, Navigation) | `Layer Names → 2D Physics` / `3D Physics` / `2D Render` / `3D Render` / `2D Navigation` / `3D Navigation` |

## Editor Settings — Common Paths

**Open:** `Editor → Editor Settings…`

| Setting | Category path |
|---------|---------------|
| Editor theme | `Interface → Theme` |
| Editor language | `Interface → Editor → Editor Language` |
| Custom keybindings | `Shortcuts` |
| External script editor | `Text Editor → External` |
| FBX importer path | `FileSystem → Import → FBX → FBX2GLTF Path` |
| Network proxy / mirror | `Network → HTTP Proxy` |
| Run on save | `Run → Auto Save → Save Before Running` |

## Export Workflow

**Open:** `Project → Export…`

Add a preset → install export templates if not already installed
(`Editor → Manage Export Templates…`) → configure preset → click **Export
Project**.

**Platforms requiring extra setup**:

- **Android**: requires `Project → Install Android Build Template…` and JDK + Android SDK paths in `Editor Settings → Export → Android`.
- **iOS / macOS**: requires Xcode (macOS only).
- **Web**: requires `coi-serviceworker` or proper COOP/COEP headers on the host for SharedArrayBuffer.

## MCP Tool Notes (`mcp__godot__*`)

The Godot MCP tools accept project paths and node operations — they do **not**
emulate the editor UI itself. When using them:

- `mcp__godot__launch_editor` — opens the editor at a project path. **The
  editor that opens is the version installed on the user's machine.** Confirm
  that this version is 4.6.2 (the pinned project version) before issuing
  follow-up UI instructions.
- `mcp__godot__add_node`, `mcp__godot__create_scene`, `mcp__godot__save_scene`
  — operate on `.tscn`/`.tres` files directly. These do not depend on UI
  layout, so they are safe regardless of where the user has docked panels.
- `mcp__godot__get_godot_version` — call this first if you are unsure which
  version is installed. Refuse to give UI click-paths if the reported version
  does not match 4.6.x.

When in doubt, **ask the user to confirm what they see on screen** before
giving step-by-step instructions. A description of the visible toolbar/dock
arrangement is faster than guessing from version-pinned defaults.

## Verification Checklist for Agents

Before writing UI click instructions or invoking `mcp__godot__*`:

- [ ] The path I'm about to give appears in this file's "Main Menu Reference"
      or "Project Settings — Common Paths" table.
- [ ] If the user has a non-default dock layout, I asked them to confirm where
      the target dock is rather than asserting its location.
- [ ] I checked the "Version-Drift Traps" table — none of the names I'm using
      are the pre-4.4 names.
- [ ] If the operation is not covered here, I fetched the relevant 4.6 doc
      page and added the verified information to this file before continuing.
