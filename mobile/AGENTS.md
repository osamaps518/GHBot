Rules for AI coding agents working on the mobile app, on top of the root AGENTS.md.

## Code shape
- Each function, class or widget does one thing you can name in a few words. When a body does several, split it into named pieces in the same file.
- Splitting means naming a piece, not adding a layer: no new file, interface, base class or controller with a single user unless the issue needs it.
- A screen's `build` reads as its list of sections. Each section is a private widget class below it, not a `_buildX()` method.
