# Egg Heist: Wild Run — Godot 4.7.2

A browser-ready Godot rebuild of the Egg Heist prototype, designed as an original game inspired by the egg-stealing/guardian-chase loop rather than a copy of another game's proprietary assets.

## Included

- Godot 4.7.2 project using the GL Compatibility renderer for Web export.
- Large continuous map: Safe Zone + 8 connected biomes (Forest, Lake, Desert, Jungle, Snow, Volcano, Abyss, Prehistoric).
- Tall continuous arena walls, structural buttresses, lighting, fog, sky, environment props and biome transitions.
- 12 farm pens around the Safe Zone.
- Farm progression Lv.1–13. Capacity starts at 6 animals and reaches 18 at Lv.13.
- Farm upgrade board placed outside the player's pen.
- Treadmill training with 8 visual levels and stronger blue energy details at higher levels.
- Separate Trails Shop. Trail is rendered as a continuous 3D ribbon, not particle dots.
- Third-person character controller. No sprint button: movement speed automatically scales with the Speed stat.
- Desktop camera + mobile touch controls. Left side = movement, right side = camera. Layout remains visible in landscape orientation.
- Full-screen option and High/Balanced/Mobile quality settings.
- Egg stealing, guardian wake-up, chase, hit/drop, delivery to farm, pets and passive income.
- Original generated audio for egg pickup, guardian wake, hit, buying and upgrading.
- Eight large procedural guardian models: Chicken, Swan, Scorpion, Tiger, Yeti, three-headed Cerberus, Moby-style whale and T-Rex.
- Guardian sleep/alert/chase/return states with body lean, limb animation, acceleration and close-range speed-up.
- Local save in `user://egg_heist_save.json` (browser storage when exported to Web).
- GitHub Actions workflow that automatically exports Godot Web and deploys GitHub Pages.

## Open in Godot

1. Install Godot 4.7.2 Standard.
2. Import `project.godot`.
3. Press F6/F5 to run.

## Web export

The project already includes a `Web` export preset using single-threaded Web export for broad browser compatibility.

With GitHub Pages, the included `.github/workflows/deploy-pages.yml` downloads Godot 4.7.2 plus export templates, imports the project, exports `web/index.html`, and deploys the `web` directory.

## Public link

Once this folder is committed to a GitHub repository with Pages enabled for GitHub Actions, the workflow publishes it at a URL similar to:

`https://<github-user>.github.io/<repository>/`

## Multiplayer

The layout contains 12 farm slots and is designed for a 12-player room. A true browser multiplayer release also needs a public WSS backend; GitHub Pages only hosts the client. The static Web build is playable without that server.
