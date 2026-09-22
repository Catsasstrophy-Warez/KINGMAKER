# Kingmaker / Dead Highway — Asset Working Spec

This project has no external art department: Claude is the artist of record for this project, and
this is Claude's own working spec to build against rather than reverse-engineer intent from the
codebase each time. Everything here is a real, load-bearing contract already used by running code
and tests — hitting these specs means an asset drops in with no simulation or engine changes.
Progress against each section should be tracked here as items close (see the checklist at the
bottom), the same way `Docs/ROADMAP_1_20.md` tracks the rest of the project.

## What this is

Dead Highway is an iOS RealityKit game built on a fully procedural blockout: every mesh, texture,
audio stem, animation clip, and particle effect currently in the repo is code-generated (Blender
scripts + numpy-synthesized textures + synthesized audio), deliberately temporary. The simulation,
save system, combat, economy, and UI are complete and tested (214 automated tests passing). What's
missing is **final art and audio to replace the placeholders without touching any code** — every
asset below already has a stable ID the engine resolves by name.

## Visual reference (ground truth for shape/finish)

`ResearchLibrary/ReferenceImages/`: three owner-provided sheets —
`XR13_OrthogonalsAndWasteland.png` (restored + wasteland configs, front/side/rear),
`XR13_DisassemblyAndComponentBreakdown.png` (exploded part view), and
`XR13_ParkDisassembly_DamagedRustedBrokenRepaired.png` (condition-state reference).
Where the images and this doc disagree, **the images win** for shape and finish.

Style: original fictional muscle car ("Blackridge XR-13 Kingmaker") — 1967–72 shoulders and hood
proportion, 2003–04 mechanical brutality, 2013–14 muscle stance, 2020–22 aero discipline. No real
automotive badges, logos, or a one-to-one copy of a production car.
Full canon: `ResearchLibrary/KINGMAKER_VISUAL_CANON.md`.

## Hero vehicle — the Kingmaker XR-13

**Real-world dimensions the physics/collision system expects** (`KingmakerCollisionBounds`):
length 4.8 m, width 1.95 m, height 1.45 m. Wheelbase/length ratio ≈ 0.57 (calibrated against
real GT500-class proportions, not the reference photo's pixel grid — see
`Docs/KINGMAKER_XR13_ASSET_PIPELINE.md` for why).

**Required sub-assembly separation** — nothing may be one monolithic mesh; each of these needs to
be an independently addressable node (full spec: `ResearchLibrary/KINGMAKER_PARTS_DISASSEMBLY_REFERENCE.md`):
- Front fascia (bumper, grille, push bar, headlights, hood)
- Side structure (doors, fenders, rockers, windows)
- Rear structure (hatch, taillights, diffuser, exhaust)
- Roof/cargo (roof panel, rack)
- Chassis shell, engine bay contents (block, supercharger, radiator), transmission, suspension, wheels/tires
- Cockpit (dashboard, wheel, pedal box, seats)

**Condition variants** — 4 total, same geometry, different material/wear treatment: `restored`
(clean), plus the three currently bundled as separate USDZs: `repaired`, `damaged`, `rusted`.

**Deformation** — the simulation tracks per-zone crumple damage (10 zones: front/rear
left/right/center, left/right side, roof, floor — `CollisionZone` enum) and expects blend-shape
targets named `deform_<zone>` (e.g. `deform_frontLeft`) on the chassis mesh. This is the one
requirement that's structurally necessary, not just nice-to-have: without named blend shapes,
crash damage can't visually render at all beyond the current crude scale-down placeholder.

**File**: USDZ, binding id `kingmaker.mesh` (+ `kingmaker.repaired`/`.damaged`/`.rusted`),
replaces `Sources/DHPresentation/Resources/Kingmaker_XR13.usdz` and siblings.

## Environments (each a separate USDZ, drop-in replacement)

| Asset | Binding id | What it is |
|---|---|---|
| Garage | `garage.mesh` | Player's home base — lift, workbench, tool wall |
| Road segment | `blackridge.road` | One repeatable highway segment |
| Terrain | `blackridge.terrain` | Open-world ground plane |
| Paradise interior | `paradise.interior` | Settlement trading hall |
| Truck-stop interior | `truckstop.interior` | Diner/fuel-counter interior |
| Town interior | `town.interior` | Ruined general store (intentionally collapsed/decayed) |
| Engine bay | `kingmaker.enginebay` | Under-hood detail mesh |
| Dashboard | `dashboard.warning` | Cockpit instrument panel |
| Hostile vehicle | `hostile.vehicle` | Raider encounter prefab |

## Characters

One mannequin rig currently exists (`player.walk` binding, walk-cycle only) — a humanoid skeleton
with hips/spine/head/arms/legs bones. A production character needs the same skeleton topology (or
better) plus at minimum idle and walk clips. 20 named NPCs exist as data (name/occupation/faction,
`Sources/DHGameplay/ProductionRoster.swift`) with no unique art yet — one shared rig with material
variation would cover all of them for v1.

## Audio

15 stems currently exist as synthesized placeholders (sine/noise waveforms, not real recordings).
Real audio should replace them 1:1 by filename — engine loops (exhaust, valvetrain, supercharger),
transient cues (DCT shift, crank, knock, repair, loot open/collect, hostile telegraph/attack,
Paradise negotiation), and radio (consequence broadcast, static). Format: `.wav` (loops) or `.m4a`
(one-shots), mono, 22.05kHz minimum. Full cue list: `Sources/DHPresentation/Rev10ProductionContracts.swift`'s `requiredAudio`.

## Lighting

No environment/IBL lighting exists yet — everything renders against a flat background color. This
is a real gap an artist or lighting pass needs to close (an earlier attempt at a lit studio-panel
environment blew out the paint's exposure and was reverted rather than shipped broken).

## Technical constraints (hard limits, checked by CI)

- Format: **USDZ** (zip-container USD), UV-unwrapped, PBR materials (Principled BSDF equivalent)
- Per-file size budget: **8 MB**; per-texture budget: **2 MB** (`Tools/validate_assets.py`)
- Every mesh must keep its **stable node/entity names** (the IDs in the tables above) — renaming
  breaks the resolver silently; see `Sources/DHPresentation/Rev10AssetManifest.swift`
- Drop-in path: replace the file at `Sources/DHPresentation/Resources/<sourceName>` — no simulation
  or Swift changes required as long as names match

## What NOT to worry about

Simulation, save/load, combat, economy, dialogue, and UI are done and tested — this work only
needs to be a visual/audio replacement, not a functional one.

## Progress checklist

- [x] Deformation blend-shape targets on the chassis mesh (`deform_<zone>` × 10) — real, nonzero
      per-vertex offsets, verified via USD stage introspection on every build. Runtime driving is
      still a scale-down proxy: RealityKit's public Swift API has no way to set an imported blend
      shape's weight as of this SDK (confirmed by inspecting `RealityKit.swiftinterface` directly,
      not by failing to find the right name) — the asset is ready for whenever that API exists.
- [ ] Condition-variant material pass beyond current procedural texturing
- [ ] Environment/IBL lighting pass
- [ ] Real audio to replace the 15 synthesized placeholder stems
- [ ] Second animation clip (idle) for the mannequin rig
- [ ] Unique per-NPC material variation across the 20-entry roster
