# Kingmaker condition-state reference

The XR-13 is not one static mesh. Every addressable assembly must support visual condition states that remain linked to simulation state.

## Damaged

Visible impact deformation, scratches, fresh gouges, bent panels, leaking fluids, exposed wiring, and partial functionality. The assembly remains present and repairable.

## Rusted

Long-term exposure: oxidized paint, pitting, surface corrosion, seized fasteners, faded materials, brittle hoses, and reduced reliability. Rust can coexist with functional operation.

## Broken

Failed or missing function: detached parts, fractured assemblies, destroyed housings, collapsed suspension, missing panels, disabled lights, fluid loss, or a vehicle that cannot operate. Broken does not mean cosmetically dramatic only; it must affect simulation capability.

## Repaired

Function restored through physical work. Repaired parts may still show scars, mismatched materials, welds, replacement hardware, or residual rust. “Repaired” is not equivalent to factory-new; it means operational and persistent.

The runtime mapping is defined by `KingmakerConditionVisualProfile` and `ComponentCondition`.
