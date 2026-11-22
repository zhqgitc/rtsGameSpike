# CLAUDE.md: rules for rtsGameSpike

RTS game spike (C&C / StarCraft / Warcraft style). See `PLAN.md` for scope and milestones, `docs/FACTIONS.md` for faction design.

## Stack
- Godot 4.7.2, GDScript, 3D with a fixed-angle RTS camera
- Godot executable: `D:\Godot_v4.7.2\Godot_v4.7.2-stable_win64_console.exe` (no install; use the console exe for headless runs)
- Headless smoke test: `Godot_v4.7.2-stable_win64_console.exe --headless --path . --quit`

## Git workflow
- Branches: `develop` (integration; `master` does not exist yet), `feature/<name>` or `session/<date>-<topic>` (all work)
- **Always create a feature or session branch before changing anything, and always branch from `develop`.**
- **Commit only to feature/session branches.** Never commit to `develop` unless the owner explicitly says so.
- **Never merge a feature branch into `develop` directly. Integration happens only through a pull request (base `develop`), which the owner reviews and merges.**
- Don't push or open PRs without the owner asking (or confirming); opening a PR for finished work is the expected path to `develop`.
- A `master` branch will be created later, on the owner's say-so.
- Commit messages: short imperative subject, body explains why. End with the attribution line configured for the session.
- One logical change per commit; don't commit `.godot/` or generated files.

## Architecture rules
- Game logic (units, orders, combat, economy, fog) runs on a fixed tick, separate from rendering and UI. This keeps replays and lockstep multiplayer possible later.
- Content is data-driven: units and buildings live in resource files under `data/`. Adding a unit should be a data edit, not a code change.
- Gameplay code lives in `scripts/sim/`, UI and camera in `scripts/ui/`, AI in `scripts/ai/`, world/map presentation in `scripts/world/`. Sim code must not depend on UI code.
- Art sits behind an asset interface (model/texture referenced from data), so placeholders can be swapped for real assets without code changes.

## Code style
- GDScript with static typing (`var x: int`, typed function signatures)
- Tabs for indentation (Godot default), snake_case for files, functions and variables, PascalCase for classes
- Small focused scripts; comments only where the why is not obvious

## Assets
- Only CC0 or otherwise freely licensed assets. Record source and license in `assets/CREDITS.md` for every pack added.
- Factions are told apart by color and silhouette. Collectivists: brutalist, massive, red. Libertarians: small, varied, many structures.

## Working agreements
- Owner is a professional developer who reviews code; owner decides game design and judges feel. Ask before changing design decisions in `docs/FACTIONS.md`.
- Verify changes by running the project headless (and by the owner playtesting) before calling a milestone done.
- Keep `PLAN.md` open items current as work completes.
- Orchestrator MCP is not used for now; revisit when cheap-model tasks are worthwhile.

## Visual direction
- Gritty and desaturated: overcast haze, low weak sun, dark scorched ground, muted colours. Faction colours stay strong accents against it.
- All art is procedural (built in code from descriptions, no downloaded assets). The world mood is tuned through the constants at the top of `scripts/world/atmosphere.gd`; the ground look lives in `assets/shaders/terrain.gdshader`.
- Decorative props are chunked (`scripts/world/props.gd`) so the fog of war can hide unexplored patches.
