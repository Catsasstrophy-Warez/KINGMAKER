# Device validation checklist

Run this on a clean macOS/Xcode installation after the simulator service is
available. The repository currently has no completed device run.

1. Generate the Xcode project from project.yml.
2. Build the Swift package and app for an iPhone Simulator.
3. Launch into the garage and verify the bundled USDZ loads.
4. Walk to Kingmaker; inspect, diagnose, repair, and start it.
5. Confirm the vehicle simulation and rendered asset remain synchronized.
6. Drive, trigger the hostile encounter, hear the radio consequence, and reach
   Paradise.
7. Save, terminate, relaunch, reload, and compare the complete state.
8. Test touch controls, orientation, background/foreground, and pause/resume.
9. Profile frame time, memory, thermal state, asset loading, and texture memory.
10. Repeat on at least one physical iPhone and record signing/device results.
