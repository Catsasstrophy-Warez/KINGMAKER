# DEAD HIGHWAY Rev9 — Production Gameplay Integration

Rev9 moves the portable architecture toward rendered production gameplay rather than adding another isolated simulation subsystem.

## Added
- Chunk-based production world streamer with tile/environment records and interior portals.
- NPC schedule/activity brains with threat response and simulation LOD tiers.
- Playable combatant state supporting ammo, cover, suppression, ranged fire, melee and reload actions.
- Unified production gameplay mode runtime for on-foot, driving, interiors, combat, dialogue and garage states.
- Isometric camera rig that widens/looks ahead with vehicle speed.
- Production HUD/interaction prompt state and thermal-aware FX budget.
- Tests covering streaming/interiors, NPC schedules/LOD, combat state, camera and thermal throttling.

## Production boundary
These systems are executable/tested Swift foundations. Production meshes, textures, animations, navmeshes, authored terrain, audio, Metal shaders, device input bindings and signed iPhone execution still require Xcode/macOS and content production.
