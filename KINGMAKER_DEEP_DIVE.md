# Blackridge XR-13 “Kingmaker” — Deep-Dive Specification

## 1. Design thesis

Kingmaker is one fictional vehicle with one recognizable fastback identity and many physically earned futures. It is not a real-world replica, not a generic Mad Max prop, and not fourteen unrelated eras stapled together. The silhouette stays coherent while the player changes the machine’s mass, cooling, traction, protection, cargo, telemetry, and purpose.

The player does not “equip a build.” They discover a battered XR-13 shell, diagnose it, source compatible parts, physically install them, test the result, and live with the consequences.

## 2. Silhouette and visual hierarchy

The base form combines compact early-fastback purity, muscular shoulders, a long hood, a planted later-body stance, modern muscle proportions, disciplined aero, and advanced cooling logic. The hierarchy must read in this order:

1. Fastback roofline and greenhouse.
2. Long hood and broad shoulders.
3. Low, planted chassis.
4. Engine-bay hardware and cooling package.
5. Configuration-specific armor, aero, cargo, lighting, and instrumentation.

The restored form is clean, focused, and road/track credible. The wasteland form is the same car after use: patched panels, recovery gear, shielding, tires, cargo, and exposed repair history.

## 3. Mechanical truth

The 254-component simulation is the authority. Visual entities are projections of it. The minimum visible systems are engine, induction, cooling, lubrication, fuel, ignition, electrical, transmission, driveline, differential, suspension, steering, brakes, tires, chassis, body, armor, lighting, survival, telemetry, and cargo.

Failure must cascade: radiator damage causes coolant loss, heat rise, oil-pressure degradation, warning codes, smoke/thermal feedback, power loss, and eventual seizure. The player must be able to diagnose the failure through physical inspection and telemetry rather than a magical health bar.

## 4. Build families

- Restored: coherent clean road/track machine.
- Road Racer: low mass, high aero, track tires, limited protection.
- Highway Interceptor: pursuit cooling, protected lighting, reinforced front structure.
- Wasteland Endurance: all-terrain tires, cargo, shielding, recovery hardware.
- Drag Monster: extreme boost, rear traction, minimal cargo and protection.
- Armored Pursuit: armor, protection, thermal and mass penalties.
- Hybrid: deliberate compromise across systems.
- Heavy Hauler: reinforced chassis, industrial engine, dually rear axle.
- High-Tech Scavenger: modern aero and sensors grafted onto an old chassis.
- Nomad: living/cargo systems, solar, fuel, monitoring, closed visibility.

Every family changes physical simulation values and visible assembly parts.

## 5. Industrial survival layer

Hazard builds use explosion-proof conduit, sealed connectors, intrinsically safe barriers, protected lights, filtration, gas monitoring, and insulated cabin controls. These are not decorative: they determine whether Kingmaker can operate near refinery leaks, irradiated dust, flooded infrastructure, or blackout zones.

Scavenged instrumentation—pressure transmitters, control valves, fuel-composition sensors, VFD panels, CAN interfaces, and gas monitors—creates alternate diagnosis and tuning paths.

## 6. Runtime architecture

Simulation runs independently of rendering. RealityKit entities carry modular mechanical components. The vehicle system updates thermodynamics, transmission state, fault codes, deformation, procedural wheel state, dashboard telemetry, audio mix, and thermal feedback. The scene hierarchy remains replaceable by USDZ assets without changing simulation IDs.

## 7. Creation order

1. Lock the XR-13 silhouette and assembly naming.
2. Build the clean/restored chassis, cabin, wheel, and engine-bay assets.
3. Build separated powertrain, cooling, suspension, dashboard, armor, cargo, and instrumentation parts.
4. Create wasteland and one performance configuration from the same assembly.
5. Author blend shapes for body deformation.
6. Author PBR materials and thermal/emissive masks.
7. Author engine, drivetrain, failure, repair, telemetry, and radio audio stems.
8. Assemble `XR13_Assembly` in Reality Composer Pro.
9. Bind runtime components and test diagnosis, repair, startup, driving, damage, towing, and save/reload.

## Acceptance definition

Kingmaker is created when the player can discover the shell, inspect its systems, diagnose a real fault, install a real part, start the engine, drive, damage the vehicle, hear and see the consequence, choose a build direction, save, reload, and find the same physical machine waiting for them.
