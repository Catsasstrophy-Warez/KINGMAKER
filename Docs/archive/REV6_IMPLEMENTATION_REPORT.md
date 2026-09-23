# DEAD HIGHWAY Rev6 — First Playable Foundation

Rev6 turns the Rev5 systems architecture into a concrete first-playable presentation/runtime boundary.

Implemented:
- Blackridge garage blockout scene descriptors with Kingmaker, workbench and interactive garage door.
- Highway and Paradise blockout scene descriptors.
- RealityKit procedural blockout builder behind platform availability guards.
- Isometric camera rig for on-foot, vehicle chase and garage inspection modes.
- Interaction highlight and HUD state.
- Streaming-cell controller for garage -> highway -> Paradise transitions.
- FirstPlayableRuntime implementing the complete opening interaction chain.
- Additional Swift tests covering scene content, streaming and end-to-end first-playable progression.

The RealityKit builder deliberately uses procedural placeholder geometry. Production meshes, materials, animation, audio, input surfaces and Xcode app signing remain later integration work and are not represented as finished assets.
