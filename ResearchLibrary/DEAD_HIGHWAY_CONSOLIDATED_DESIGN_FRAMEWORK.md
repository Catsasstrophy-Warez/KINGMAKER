# DEAD HIGHWAY — Consolidated Design Framework

Status: design brief and research synthesis. This document describes the target experience; it does not imply that every item is implemented.

## Core identity

DEAD HIGHWAY is an open-world isometric action RPG, vehicle simulation, and dynamic economic sandbox. The visual target combines an isometric GTA 1/2 or Fallout 1/2 camera with modern 3D presentation: Metal atmosphere, volumetric dust, physical mud, headlights, weather, and combat particles. The Apple-native foundation is Swift 6 concurrency for background simulation, RealityKit ECS for entity and vehicle hierarchies, and Metal for rendering and fluid/atmospheric effects.

The core fantasy is that the vehicle is the player's lifeline, weapon, inventory, and second character. Physical actions on the road determine whether communities rebuild or collapse.

## Vehicles: the second character

The hero vehicle is the original fictional Blackridge XR-13 “Kingmaker,” not a reproduction of any Mustang, Shelby, or other real-world badge. Its proportions synthesize a coherent lineage: 1965 compact fastback purity; 1967–72 muscular shoulders and long-hood aggression; 2003–04 mechanical brutality; 2013–14 modern muscle balance; 2020–22 aero sophistication; and 2026-level cooling and active-aero thinking. Its performance DNA draws on road-course focus, supercharged violence, endurance/track balance, high-RPM handling, enormous engine-bay presence, and an extreme upper performance ceiling without reproducing any one source car.

Kingmaker begins as a battered shell discovered in an abandoned underground garage. The player restores it through physical work and can evolve it toward road racer, highway interceptor, wasteland endurance car, drag monster, armored pursuit vehicle, or an unreasonable hybrid. The clean/restored configuration and eventual wasteland configuration must remain visibly the same car: one believable machine transformed by use, repair, and choice.

Progress comes from physically installing machinery rather than unlocking abstract skill nodes. Component failures cascade: a punctured radiator loses coolant, temperature rises, the head gasket fails, oil burns, and the engine can seize. Health is communicated diegetically through engine sounds, torque, smoke, dashboard lights, and handling.

Wrecks are recovered through towing and maintenance, not instant unlocks. Vehicle categories include motorcycles, interceptors, heavy trucks, and faction-specific builds, each constrained by parts, tires, fuel, and mechanical compatibility.

## World and civilization simulation

Blackridge is one authored slice of a larger continent containing 12 distinct regions with different roads, hazards, weather, and economies. Civilization clusters around infrastructure: refineries, dams, rail yards, substations, pumps, and machine shops.

Supply chains move food, water, fuel, medicine, ammunition, and machinery through physical convoys. Destroying a rail coal train can black out a settlement, stop pump production, weaken defenses, and invite raids. Repairing infrastructure should visibly and mechanically improve towns.

## On-foot play and settlements

On foot, the game becomes a deliberate CRPG: real-time combat with tactical slowdown, cover, positioning, weapon condition, scarce ammunition, and meaningful melee alternatives. Settlements are dense hubs with mechanics, bounty hunters, refugees, traders, and persistent residents. Industrial interaction includes blast doors, 480V substations, pumps, and other machinery that can alter local economies.

## Factions and territory

The Highway Patrol, Refinery Houses, Rail Union, Motor Tribes, Restorationists, Combine, and Homesteads embody competing responses to collapse. Player actions alter faction reputation, borders, road control, and trade routes.

## Exploration, radio, and tone

Environmental stories favor quiet, specific discoveries over constant dungeonization: a dead diner refrigerator, an old photograph, and a few cans of food can carry the scene. Radio is the narrative glue, carrying music, propaganda, weather warnings, CB chatter, and consequences caused by the player. Restored towers unlock frequencies. The “White Whale” signal is an unmarked mystery driven by triangulation, static, and persistence rather than quest markers.

## Rev10 application

Rev10 concentrates this framework into the Blackridge County vertical slice. The implementation source of truth is the authored county manifest, the Kingmaker component-to-visual hierarchy, and the ordered save/reload acceptance path in `DHRev10VerticalSlice`.

## Action, mechanics, infrastructure, and hazards

The visual library should also cover high-speed pursuit and vehicular combat: side-swipes, overboost launches, night engagements, and first-person telemetry. Combat must expose the machine's mechanical consequences rather than become a detached action layer.

Wrecks and salvage are central verbs. Kingmaker can tow a dead vehicle from a collapsed tunnel, receive an engine transplant in the garage, accept diagnostic bypass equipment, and visibly strain its differential and suspension under load.

Industrial infrastructure provides scale and context: refinery settlements, gas pipeline valve stations, Rail Union yards, locomotives, machine shops, and improvised process instrumentation should dwarf and frame the car. The vehicle is a tool moving through a world of machines.

Weather and hazards should materially change presentation and handling: irradiated rain and thermal shock, Barrens dust whiteouts, freezing mountain passes with tire chains, and blackouts where the car shuts down to avoid detection.

Faction builds should remain one believable XR-13 identity while changing its engineering purpose: Heavy Hauler, Flame Spitter, High-Tech Scavenger, and Nomad. These are extreme physical configurations affecting mass, cooling, fuel, visibility, cargo, and faction recognition—not arbitrary cosmetic skins.

## Hazardous environments and industrial instrumentation

Kingmaker can be hardened for industrial hazards rather than merely armored for combat. Explosion-proof conduit, poured seals, intrinsically safe barriers, NEMA-rated cabin enclosures, hazardous-location filtration, protected lighting, and ambient gas monitoring become meaningful physical upgrades for refinery leaks, irradiated dust, and flooded industrial zones.

The world’s industrial leftovers can become vehicle instrumentation: Rosemount-style pressure transmitters, Fisher valve actuators, VFD control panels, gas monitors, scavenged fuel-composition sensors, and improvised power distribution modules. These additions should be visible, serviceable, and mechanically consequential.

## Racing heritage and telemetry

Kingmaker’s racing identity includes dirt-oval speed builds, ruined-interstate stock-car combat, E85 conversions, and car-show graveyards. Advanced tuning is diegetic: VCM-style calibration, SocketCAN overrides, adaptive DCT relearn, as-built memory edits, clutch pressure, boost, and tire-temperature overlays. Tuning is a physical and risky interaction with the machine, not a detached menu upgrade.
## Settlements, tactics, failure, and the Last Highway

Paradise is a lived-in safe haven rather than a menu: fortified truck-stop gates, broken neon, inspections, trade, repairs, recruitment, and visible infrastructure. Other havens can grow around dams, subway auto-docs, and faction checkpoints. Arrival should make the vehicle’s condition and cargo socially consequential.

Vehicle tactics include pneumatic harpoons, defensive side-pipe fire, caltrop deployment, and on-foot tire-iron negotiations. These tools must be constrained by parts, fuel, heat, ammunition, faction reputation, and physical mounting points.

Catastrophic failures are authored presentation states of the simulation: blown head gasket, dead battery in the Barrens, sheared driveshaft, and high-speed tire blowout. Each state must preserve mechanical causality and offer a repair, tow, salvage, or abandonment decision.

The endgame Last Highway is a tonal escalation: the Ghost Signal, Horizon of Wrecks, Edge of the Grid, and Final Ascent. It should feel like the simulation reaching the boundary of known infrastructure and then confronting an uncharted world, with the radio as the final narrative thread.
