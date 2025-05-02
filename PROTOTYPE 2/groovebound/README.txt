Groove Bound prototype scaffold – run with: love groovebound

This is the initial scaffold for the Groove Bound game prototype.
The scaffold includes basic framework components:
- State management system
- Event bus for communication between components
- Logging system for debugging
- Grid-based UI system
- Debug display overlay

Directory Structure:
- src/core: Core game components (state_stack, event_bus, paths, settings, logger)
- src/systems: Game systems (to be implemented)
- src/ui: UI components and states
- src/data: Game data tables
- src/save: Save data management
- assets/placeholders: Placeholder assets
- logs: Runtime and error logs
- tests: Test scripts
- docs: Documentation
- web-build: Web export (future)

To run the game:
1. Install LÖVE engine from https://love2d.org/
2. Navigate to the game directory
3. Run: love groovebound
