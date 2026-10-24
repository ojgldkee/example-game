# Computer setup — Playground Awake

## What your Linux Mint machine does
Linux Mint is the source-code and asset-production environment:
- clone/pull the GitHub repo,
- run Rojo,
- edit with VS Code/Codex,
- run Blender scripts,
- build local .rbxl files for inspection/versioning.

Roblox Studio itself is officially supported on Windows and macOS, not Linux. Use Windows for the Studio sync/test/publish stage.

## Linux Mint setup

### 1. Install Git
```bash
sudo apt update
sudo apt install -y git curl
```

### 2. Clone this repository
```bash
cd ~
git clone https://github.com/ojgldkee/example-game.git
cd example-game
```

### 3. Install Rokit
```bash
curl -sSf https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.sh | bash
```
Close/reopen Terminal if requested.

### 4. Install the pinned project tools
```bash
cd ~/example-game
rokit install
rojo --version
```

### 5. Build the Roblox place file
```bash
mkdir -p build
rojo build default.project.json -o build/PlaygroundAwake.rbxl
```

### 6. Install Blender
Use Linux Mint Software Manager or:
```bash
sudo apt install -y blender
```

### 7. Generate Happy V2
```bash
mkdir -p exports
blender --background --python blender/generate_happy.py
```
Expected outputs:
- `exports/happy_v2.blend`
- `exports/happy_v2.glb`

Happy V2 includes a more detailed mascot mesh, facial structure, jaw/eye bones, hands, shoes, and authored actions for idle, walk, run, crawl, lunge, roar, wall peek, ceiling crawl, and jumpscare. It still needs visual inspection before launch.

## Windows / Roblox Studio setup

### 1. Install Roblox Studio
Install Studio from Roblox Creator Hub and sign in to the Roblox account that will own the experience.

### 2. Install Rojo on Windows
Install Rokit using the official Windows installer/PowerShell method, clone this same repo, then:
```powershell
rokit install
rojo plugin install
```

### 3. Create the Roblox experience
In Studio:
1. Create a new Baseplate experience.
2. Publish it to Roblox under the intended owner/group.
3. Keep the first version private while testing.

### 4. Run Rojo
From the repo folder in Windows:
```powershell
rojo serve
```
Then in Studio open the Rojo plugin, connect to the local server, and sync the project.

### 5. Test the generated map
Press Play and verify:
- lobby spawns correctly,
- all 12 checkpoints trigger in order,
- moving/falling/spinning obstacles work,
- dying raises Wake,
- 65%+ Wake activates Happy,
- 100% triggers final chase,
- finish awards Wins/Tickets/XP,
- settings and store UI scale correctly on mobile emulation.

### 6. Import Happy
Import `exports/happy_v2.glb` using Studio's 3D importer.
Move the final model into:
`ReplicatedStorage > Assets > Happy`

The game automatically prefers this imported Happy model over the fallback blockout.

### 7. Publish animations
Open the Animation Editor for Happy, review/refine each animation, publish them, and copy the resulting asset IDs into:
`src/shared/Config.luau > Config.AnimationIds`

Required launch animations:
- idle
- walk
- run
- crawl
- lunge
- roar
- wall peek
- ceiling crawl
- jumpscare

### 8. Add audio
Upload or choose properly licensed/original sounds and place their asset IDs in:
`Config.SoundIds`

### 9. Create monetization
In Creator Hub create the Game Passes and Developer Products listed in `Config.GamePasses` and `Config.Products`. Paste every real ID into `Config.luau`.

Do not leave monetization IDs as 0 for launch.

### 10. Enable DataStore testing carefully
For a private development place, enable Studio API access only when you're ready to test persistence. Keep production data separate from throwaway test data whenever possible.

### 11. Multiplayer test
Use Studio's multi-client test with several players and test:
- simultaneous deaths,
- checkpoint validation,
- final chase,
- player leaving/rejoining,
- receipt processing,
- duplicate purchases,
- low FPS/device emulation.

### 12. Publish a private phone build
Publish the private experience, open Roblox on iPhone, join it, and test real touch controls and performance.

## Before public release
Do not public-launch until:
- Happy's final model/animations have been visually approved,
- every placeholder ID is replaced,
- all purchases have been test-bought in a safe environment,
- DataStore save/rejoin tests pass,
- no errors appear during multi-client sessions,
- iPhone performance is acceptable,
- thumbnails/icon/game description are finished.
