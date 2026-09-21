# Rev10 execution board

This is the implementation board for the requested 50-step pass. “Implemented” means the portable contract or app wiring exists; “Xcode content” means it still requires authored assets, RealityKit scene work, or device validation.

1. **Implemented** — non-signing XcodeGen setup for local simulator/Mac builds.
2. **Implemented** — app now instantiates the Rev10 RealityKit scene bridge.
3. **Implemented** — Blackridge location/chunk manifest.
4. **Implemented** — Blackridge road graph.
5. **Implemented** — interior portal identifiers.
6. **Implemented** — encounter spawn identifiers.
7. **Implemented** — Kingmaker 254-component visual mapping contract.
8. **Implemented** — garage-to-reload acceptance runtime.
9. **Implemented** — save/reload equality validation.
10. **Implemented** — on-foot animation state machine.
11. **Implemented** — loot interaction state.
12. **Implemented** — hostile vehicle encounter state.
13. **Implemented** — radio consequence identifier flow.
14. **Implemented** — diagnostic RealityKit location anchors.
15. **Implemented** — diagnostic road anchors.
16. **Implemented** — diagnostic interior anchors.
17. **Implemented** — Kingmaker hierarchy anchors.
18. **Implemented** — stable entity lookup/attachment API.
19. **Implemented** — interior visibility toggling API.
20. **Implemented** — consolidated design framework in research library.
21. **Xcode content** — replace garage marker geometry with authored meshes.
22. **Xcode content** — author garage collision and navigation volumes.
23. **Xcode content** — author Kingmaker exterior and engine-bay assets.
24. **Xcode content** — bind component anchors to production mesh nodes.
25. **Xcode content** — add inspection camera and hotspot presentation.
26. **Xcode content** — add diagnosis audio, smoke, warning-light, and HUD feedback.
27. **Xcode content** — add repair animation and inventory presentation.
28. **Xcode content** — author Blackridge terrain chunks.
29. **Xcode content** — replace road markers with splines/navmesh.
30. **Xcode content** — author scrapyard, ruined town, mine, rail yard, depot, substation, farms, and truck stop.
31. **Xcode content** — author Paradise exterior and interiors.
32. **Xcode content** — add streaming handoff and chunk unloading.
33. **Xcode content** — add player locomotion clips and root-motion policy.
34. **Xcode content** — bind NPC schedules to visual agents.
35. **Xcode content** — add loot search animation and item pickup effects.
36. **Xcode content** — add weapon aim/fire/reload/cover clips.
37. **Xcode content** — add hit reactions and combat FX.
38. **Xcode content** — author hostile vehicle prefabs.
39. **Xcode content** — bind vehicle damage to visual deformation and smoke.
40. **Xcode content** — add pursuit camera and encounter staging.
41. **Xcode content** — add radio voice, static, music, and consequence mix.
42. **Xcode content** — author Paradise NPC visual roster.
43. **Xcode content** — add negotiation and trade UI.
44. **Xcode content** — add recruitment presentation and companion follow behavior.
45. **Implemented** — simulator app exposes beat progression and save/reload controls.
46. **Xcode validation** — validate streamed driving performance and thermal budget.
47. **Xcode validation** — validate controller/touch bindings.
48. **Device validation** — sign with the chosen Apple development team only when device testing begins.
49. **Device validation** — run the complete acceptance path on hardware.
50. **Release gate** — record screenshots/video, performance metrics, persistence results, and remaining defects.

## Asset handoff

`DHRev10AssetManifest` is the replacement list for steps 21–44. It gives each future USDZ, animation, navmesh, audio, prefab, and particle asset a stable runtime entity ID. The current scene bridge remains usable with diagnostic geometry until those assets are supplied.

The no-team setup applies to local simulator/Mac builds. A development team is still required for installing on a physical iPhone; that is intentionally deferred to step 48.
