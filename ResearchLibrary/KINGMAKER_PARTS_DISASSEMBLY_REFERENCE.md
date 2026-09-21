# Kingmaker XR-13 parts and disassembly reference

This reference defines the visual separation required for the RealityKit assembly. Each group must remain independently addressable for inspection, repair, swapping, deformation, and configuration changes.

## Exterior assemblies

- Front fascia: bumper, grille mesh, push bar, headlights, fog/auxiliary lamps, hood, hood extraction, and front aero.
- Side structure: doors, fenders, rocker panels, side skirts, window framing, regulators, hinges, and weather seals.
- Rear structure: hatch, taillights, diffuser, rear aero, exhaust, tow hardware, winch, and fuel-cell access.
- Roof/cargo: roof panel, rack, solar panels, spare tire, jerry cans, camera feeds, and modular storage.

## Chassis and powertrain

- Chassis shell, subframes, crash structures, armor plates, and roll cage.
- Engine block, heads, supercharger, pulleys, belts, intake, throttle/actuator, radiator, cooling hoses, oil system, fuel delivery, battery, alternator, starter, and wiring.
- Transmission housing, clutch packs, actuators, driveshaft, differential, axles, suspension arms, pushrod/MagneRide units, hubs, brakes, rotors, calipers, wheels, and tires.

## Cockpit and telemetry

- Steering column, wheel, pedal box, seats, dashboard shell, analog gauges, diagnostic display, industrial toggle panel, CAN interface, gas monitor, wiring harness, and cabin enclosures.

## Wasteland modules

- Reinforced armor, protected optics, mismatched lamps, recovery winch, tow hooks, cargo rack, external fuel, tools, improvised instrumentation, and survival storage.

## Runtime rule

The asset hierarchy should map each sub-assembly to stable simulation and presentation IDs. No single monolithic mesh may hide a component that the player can diagnose, repair, replace, damage, animate, or visually inspect.
