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
