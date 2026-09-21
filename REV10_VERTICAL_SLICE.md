# Rev10 — Blackridge County Vertical Slice

Rev10 is now scoped around one rendered, persistent acceptance path rather than another standalone architecture pass.

The portable contract is `DHRev10VerticalSlice`. It owns the authored Blackridge location/road/chunk manifest, Kingmaker's visual hierarchy mapping, and the ordered gameplay beats from garage inspection through save/reload. Xcode/RealityKit work should consume this manifest directly: each location becomes an authored scene/chunk, each road edge becomes a navigable spline/graph edge, and each Kingmaker visual node becomes a render hierarchy anchor.

`DHRev10RealityKitScene` is the first integration bridge. It preserves those stable IDs while creating diagnostic RealityKit anchors for locations, interiors, roads, and Kingmaker visual nodes. Production meshes, navmesh resources, animation clips, and encounter prefabs can replace the marker entities in place.

Acceptance: start DEAD HIGHWAY, walk the garage, inspect and diagnose Kingmaker, scavenge, repair, start, drive streamed Blackridge, resolve a hostile vehicle encounter, hear its radio consequence, reach Paradise, enter, negotiate/trade/recruit, save, quit, reload, and verify the persisted state is identical.
