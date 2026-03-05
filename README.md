# Modular Momentum Controller

> A modular Godot framework for creating character controllers inspired by classic Sonic physics.

---

## What it does

Faithful inertia-based momentum physics with surface sliding, rolling and jumping states, and high-speed stability without physics breakage.

Collision detection uses a low-cost Raycast and snapping system designed to handle high velocities cleanly.

---

## Modularity

The core handles only fundamental movement and has no knowledge of added abilities. Spindash, dropdash, audio, and animations are implemented as separate modules that can be removed or replaced without touching the core.

Creating a custom character with unique stats and abilities requires no modifications to the core itself.

---

## Included modules

| Module | Description |
|---|---|
| Spindash | Classic charge-and-release dash |
| Dropdash | Mid-air dash on landing |
| Audio | Sound effect handling |
| Animations | Sprite animation controller |

---

## Accessibility

- **Coyote time** — grace period after leaving a platform
- **Jump buffering** — input registered slightly before landing

---

## Licensing

This version of the framework contains Assets owned by SEGA, everything else is under MIT licensing. If you want to use this framework for commercial use, remove every SEGA owned asset from the framework. A full MIT version of the framework is in the works.

---

## Roadmap

- **Current release** — Example implementation using classic Sonic sprites for reference
- **Asset Library release** — Clean version with no proprietary assets, submitted to the Godot Asset Library

---

## Contributing

The Asset Library version needs original sprite animations. If you're an artist interested in contributing in exchange for credit, open an issue or reach out directly.
