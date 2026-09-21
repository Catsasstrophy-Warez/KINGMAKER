# Kingmaker XR-13 production reference matrix

This matrix is the detailed reference specification for modeling, RealityKit assembly, animation, physics, UI, and concept generation. It is a production target, not a claim that the assets already exist.

## Exterior views

- Front elevation: 1968 muscular shoulders, push bar, asymmetrical LED headlights.
- Rear elevation: fastback chassis, exposed 24-gallon fuel cell, winch, dual exhaust.
- Side profile: broad 1971 body, modern track aero, off-road suspension, rear slicks.
- Top-down isometric: CRPG angle, rusted roof, hood cutout, visible Roots supercharger.
- Front/rear three-quarter: restored and armored configurations sharing the same silhouette.
- Underbody: steel/carbon chassis, rerouted exhaust, scraped armor.
- Roof detail: solar panels, modular cargo racks, external cameras.

## Interior and mechanical views

Driver POV, explosion-proof NEMA/Class I Div 1 dash enclosures, VCM Scanner tuning laptop, sealed wiring harnesses, 480V cargo, Gas Clip monitor, welded pedal box, roll cage, stripped door panels, supercharged V8, DCT clutch packs, E85 delivery, MagneRide pushrods, Rosemount pressure transmitter, Fisher/Bettis throttle bypass, SocketCAN diagnostics, brake assembly, patched cooling loop, battery harness, and industrial alternator.

## Animation and physics states

Cold start, DCT launch control, emergency braking, and independent suspension articulation must be authored as procedural/mechanical states driven by simulation values. Visual feedback includes engine shudder, soot, mount torque, suspension compression, tire deformation, brake heat, smoke, and wheel travel.

## Character and companion interactions

The passenger can become a recruited co-pilot. Roadside negotiation, sleeping quarters, refueling under fire, and companion scanning should occur around the physical car, using the same cabin, cargo, fuel, and armor entities as the simulation.

## Crash, deformation, and crafting

Blend shapes cover frontal impact, side swipe, rollover, and chassis warp. Crafting references include armor plates, dry-deck seals, shock-tower modification, and scavenged headlights. Each craft action changes mass, integrity, cooling, visibility, power, or hazard tolerance.

## Lighting and weather

Dust Country noon, industrial sulfur fog, nuclear aurora, and flash flood are reference scenarios for Metal atmosphere, volumetric lighting, material response, water, heat distortion, headlights, and handling changes.

## Asset mapping

The matrix maps to the existing pipeline contracts: `KingmakerMechanicalPresentation` for deformation/wheels/audio/dashboard, `KingmakerRealityKitSimulation` for thermodynamics and fault codes, `KingmakerVisualHierarchy` for entity identity, and `DHRev10AssetManifest` for external USDZ/WAV/particle replacement points.
