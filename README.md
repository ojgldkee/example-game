# Playground Awake

A fast-launch Roblox horror/obby game built with Luau + Rojo, with Blender-generated assets.

## Core loop
Players race through a colorful indoor playplace. Every player death increases the server-wide Wake meter. At higher Wake levels, the map mutates, hazards intensify, and the mascot becomes more aggressive. At 100% Wake, the final chase begins.

## Local workflow
- Linux Mint: VS Code/Codex, Git, Rojo, Blender
- Roblox Studio (Windows/macOS): sync/build, engine testing, publishing
- iPhone: published-build playtesting

## Important setup
Replace placeholder IDs in `src/shared/Config.luau` with your Roblox Developer Product / Game Pass / animation IDs after creating them in Creator Hub.

This repository is the source of truth. Do not hand-edit generated map instances in Studio unless you intentionally port those changes back into source.
