# Bastion Vale

A small 3D tower defence made with [Doriax Engine](https://github.com/doriaxengine/doriax).

Alien craft come out of a portal and follow the road to your keep. Build towers on the pads
along the way and stop them before they get there, since every craft that reaches the gate
knocks points off the keep. Lose all 20 and the level is over. Green Vale has 8 waves and
Frost Hollow, which opens once Green Vale is won, has 10 tougher ones in the snow. A win is
worth one to three stars, depending on how much of the keep is still standing.

Open the folder in Doriax Editor and press **Play** on `Intro Scene`.

## Controls

| Input | Action |
| --- | --- |
| Click a build pad | Select it |
| 1, 2, 3 or the build bar | Build a ballista, cannon or frost tower on the selected pad |
| U or Upgrade | Upgrade the selected tower (twice at most) |
| X, Delete or Sell | Sell the selected tower for 60% of what was spent on it |
| Space, N or Send Now | Call the next wave early, the seconds left on the clock are paid as gold |
| F or the speed button | Play at double speed |
| WASD / arrows, right or middle mouse drag | Move the camera |
| Q / E | Turn the camera |
| Mouse wheel | Zoom |
| Esc / P | Pause (Esc first clears the selection) |

On phones and tablets, tap a pad to select it, drag with one finger to move the camera and
pinch to zoom. The HUD buttons do everything else.

The ballista fires fast at one target, the cannon is slow but hits everything around the
impact, and the frost tower does little damage but slows down what it hits. The scouts are
quick and weak, raiders sit in the middle, brutes take a lot of shots, and a mothership leads
the last waves.

## Project

- `Intro Scene`: the title screen, a raid hovering over the vale with `Title Menu` as a child
  scene. The menu shows the stars and best score of each level.
- `Green Vale`, `Frost Hollow`: the levels. Each has a `Level` entity with the
  `LevelDirector` script, and uses `HUD Scene`, `Pause Scene`, `Victory Scene` and
  `Defeat Scene` as child scenes. The road is the `Waypoint` entities under `Road`.
- `Loading Scene`: shown by `SceneManager` while a level loads.
- `bundles/`: the build pad, the three towers, the four enemies and the keep. Towers and
  enemies are spawned with `BundleManager` while the game runs.
- `scripts/`: the Lua scripts. `GameState` holds what the level and the HUD share,
  `Waves` lists each level's waves and `Towers` the tower prices.
- The ground is a Terrain with painted layers (grass, path, rock, gravel, and snow in Frost
  Hollow). The muzzle flashes, impacts, explosions, building dust and the torches at the
  keep gate are particles actions inside the bundles.

Stars and best scores are saved with `UserSettings`.

## Credits

Models, UI, icons, particles, skyboxes and sounds are CC0 assets by
[Kenney](https://kenney.nl): Tower Defense Kit, Castle Kit, UI Pack - RPG Expansion, Game
Icons, Particle Pack, Skyboxes, Interface Sounds, Impact Sounds and Music Jingles. The
terrain textures are CC0 from [ambientCG](https://ambientcg.com). The Lilita One font is
under the SIL Open Font License. Licenses are in `assets/licenses/`.

The tower and enemy icons (renders of the kit models) and the icy colour map of the frost
tower were made for this game and are CC0 as well.
