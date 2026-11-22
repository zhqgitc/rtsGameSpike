# rtsGameSpike: Plan

Spike for a classic-style RTS (C&C / StarCraft / Warcraft). Goal: see how far a human + Claude team can get. Story comes later.

## Decisions
- Engine: Godot 4.x, GDScript
- Perspective: 3D, fixed-angle RTS camera
- Art: free CC0 asset packs (Kenney etc.), placeholders where needed; factions distinguished by color and silhouette
- Scope: single-player vs. simple AI; no networking
- Setting: near-future, worldviews in conflict (Collectivists, Libertarians, religious extremists, reality-deniers)
- Spike factions: **Collectivists vs. Libertarians** (other two later, as data + assets)
- Orchestration: not used at the start (orchestrator MCP failed to connect); revisit later
- Owner is a professional developer: code is reviewed, architecture can be proper

## Spike features (all required)
- Selection (click, box, groups), move and attack orders, pathfinding, basic combat
- Resource gathering, base building, unit production
- Fog of war
- HUD: resource bar, selection panel, command card, minimap

## Architecture notes
- Game logic (units, orders, combat, economy) runs on a fixed tick, separate from rendering, so replays/lockstep stay possible later
- Pathfinding: `NavigationServer3D` (navmesh + avoidance); move to flow fields if group movement is poor
- Fog of war: grid visibility map updated per tick, texture overlay on terrain; enemy units hidden outside vision
- Minimap: top-down orthographic `SubViewport` with fog composited over it
- Data-driven content: units/buildings in resource files (`.tres`/JSON); a new unit is a data edit, not code

## Milestones (effort in focused work sessions)
| # | Milestone | Effort |
|---|---|---|
| 0 | Project setup, repo, folder structure, asset import pipeline | 1 |
| 1 | Terrain/map, RTS camera (pan, zoom, edge-scroll), placeholder units | 1-2 |
| 2 | Selection, move orders, navmesh pathing | 2-3 |
| 3 | Combat: attack orders, health, projectiles, death, auto-acquire | 2 |
| 4 | Economy: resource nodes, harvesters, base, building placement, production queue | 3-4 |
| 5 | HUD: resource bar, selection panel, command card, minimap | 2-3 |
| 6 | Fog of war | 2 |
| 7 | Simple enemy AI (build, expand, attack waves) | 2-3 |
| 8 | Polish, bugfixing, second faction's data | 2 |

Total: about 17-22 sessions. Biggest risks: group movement feel (2), fog in 3D (6), free assets not matching the description.

## Roles
- Claude: architecture, sim core, pathing, fog, AI design
- Cheaper models (later, via orchestration): data tables, boilerplate UI, tests, import scripts
- Review: separate `/code-review` pass
- Custom art: image/3D-generation model driven by the owner's descriptions
- Playtesting and feel: owner

## Open items
- [x] Godot 4.7.2 at `D:\Godot_v4.7.2` (no install needed; console exe verified)
- [x] Git repo initialized
- [x] Factions described: see `docs/FACTIONS.md` (mechanics drafted, to confirm)
- [ ] Choose asset packs matching the near-future setting
- [ ] Revisit orchestrator setup when cheap-model tasks become worthwhile
- [x] Milestone 0 skeleton: project.godot, folders, .gitignore, main scene (headless boot verified)
- [x] Milestone 1 (branch feature/m1-map-camera-units): flat map, RTS camera (WASD/arrows/edge scroll, wheel zoom), placeholder units from data/units/*.tres
- [x] Milestone 2 (branch feature/m2-selection-orders-pathing): click/box selection, right-click move orders, navmesh pathing with avoidance, formation spacing per unit type

## Backlog
- Ctrl+left-click selects all units of the same type (owner request, after M2)
- [x] Milestone 3 (branch feature/m3-combat): right-click attack + auto-acquire, melee-ish Conscripts vs ranged Freeholders with projectiles, health bars, Collectivists never retreat, Freeholders retreat below 30% health

- Balance pass later: owner feels Libertarians are a bit too strong; they should need specific strategies against Collectivists, who attack in higher numbers (revisit once full mechanics, graphics and story are in)
- [x] Milestone 4a (branch feature/m4-economy): deposits, harvesters, HQ drop-off, temporary resource readout. M4b: worker-built buildings + faction-specific second resource. M4c: production queues.
- [x] Milestone 4b (branch feature/m4b-buildings-second-resource): worker-built buildings with scaffolds, placement ghost (keys 1/2, left click place), Collectivist planned zone, Manpower cap, Libertarian Market producing Capital. Next: M4c production queues.
- [x] Milestone 4c (branch feature/m4c-production): selectable buildings, production queues (5 slots), Collectivist Plan batches, Libertarian education (Volunteer vs. Freeholder needing the Apprentice Workshop), Manpower reservation. Economy slice (M4) complete. Next: M5 HUD and minimap.
- [x] Milestone 5a (branch feature/m5a-hud-faction-choice): faction choice start screen (game paused until chosen), own-units-only selection, faction-styled resource bar and selection panel, camera starts on own HQ. Next: M5b command card with procedural icons, M5c minimap.
- [x] Milestone 5b (branch feature/m5b-command-card): command card with procedural icons (train, Plan, build), tooltips and dimmed unavailable buttons, queue strip in the selection panel, number-key shortcuts shown on buttons. Replaces the temporary production panel. Next: M5c minimap.
- [x] Milestone 5c (branch feature/m5c-minimap): minimap (terrain, obstacles, deposits, buildings, units, camera view outline), left click/drag moves the camera, right click orders selected units; idle units now yield to moving ones. HUD (M5) complete. Next: M6 fog of war (the minimap will hide enemy marks then).
- [x] Milestone 6 (branch feature/m6-fog-of-war): fog of war (unexplored / explored / visible grid, per-type sight ranges in data), soft terrain overlay, enemy units hidden outside sight, enemy buildings/deposits/walls hidden until explored and remembered dimmed, minimap follows the fog, buildings only placeable on explored ground. Next: M7 simple enemy AI.
- [x] Milestone 7a (branch feature/m7a-building-combat-victory): units and buildings share a Damageable base, buildings have health and can be destroyed, attack-move (Ctrl+right click), enemy building attack orders, health bars on buildings, win/lose when an HQ falls with a Victory/Defeat overlay and Restart. docs/CONTROLS.md added. Next: M7b AI economy and build order, M7c waves, personalities, difficulty (hard cheats lightly).
- [x] Milestone 7b (branch feature/m7b-ai-economy): AIController plays the opposing faction through the same rules (workers harvest, build order from data/ai/*.tres, housing when Manpower is short, army production with Plan batches for Collectivists and education prerequisites for Libertarians), abandons unreachable sites. Fixes a freed-deposit error in HarvestJob and widens building gaps to 2.5 m. Next: M7c attack waves, personalities, difficulty (Hard cheats lightly).

## Graphics
- [x] G1 (branch feature/g1-world-look): gritty desaturated world look. Atmosphere (overcast sky, haze, low sun, SSAO, grading, vignette), procedural terrain shader, scattered rocks and concrete slabs, black map border dissolving into haze. Next: G2 buildings (brutalist Collectivists, varied Libertarians), G3 units, G4 effects.
- [x] G1b: weather. Each game gets its own kind of day (overcast, dark, foggy, sunny) from data/weather/*.tres (WeatherPreset), chosen at random by default; the Atmosphere `day` property can fix one. Day name shown in the top bar.
- [x] G2 (branch feature/g2-buildings): procedural building models. Collectivists: stepped brutalist Central Committee Block (tiers, portal, star banner, flags), Dormitory Block (window grid), Conscription Office (gate, banner, watch tower). Libertarians: brick-and-timber Trading Post, Market stall, timber Militia Hall with flag and sandbags, Apprentice Workshop. Map walls are ruined concrete shells. Scaffold while building, model when finished. Next: G3 units, G4 effects.
