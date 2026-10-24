# Playground Awake — Production Plan

## V1 experience goal
A social horror obby where every death makes the entire playplace more dangerous. Players should understand the rule in one sentence and experience a visual escalation every 20–40 seconds.

## Launch pillars
1. **Clipable gameplay:** deaths trigger server-wide consequences and visible transformations.
2. **Readable on mobile:** large UI, high-contrast hazards, short interaction windows.
3. **Replayability:** randomized obstacle order and Wake events in later iterations.
4. **Monetization without hard paywalls:** revives, cosmetic status, convenience, server-wide novelty effects.
5. **Original identity:** original Happy mascot, playplace environment, sound language, and progression.

## Asset quality bar
The procedural Blender Happy is a starting rig. Before launch, replace/iterate until:
- silhouette reads from a phone screen,
- run/crawl cycles are distinctive,
- eyes/head track players cleanly,
- no visible weight-paint collapse,
- jumpscare timing is polished,
- imported Roblox animation IDs are configured in Config.luau.

## Before public launch
- Create a Roblox experience and private test place.
- Create Developer Products and Game Passes and paste IDs into Config.luau.
- Import Happy GLB, publish animations, wire animation IDs.
- Add final sounds/music with licensed/original assets.
- Run 1-player and multi-client Studio tests.
- Test iPhone controls/performance.
- Enable DataStore testing only in a safe test environment.
- Validate receipts, respawns, disconnect/rejoin, and exploit-sensitive remotes.
- Replace blockout map art with final branded playplace kit.
