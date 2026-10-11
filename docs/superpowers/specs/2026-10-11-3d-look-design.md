# 3D Look — Design

Date: 2026-10-11 · Reference: the user's Short "Name this song before the marble stops" (warm dark room, chrome marble,
glowing brass bars hanging on wires, real shadows on the wall behind, angled camera).

## Decisions

- Renderer: **SceneKit** 3D scene. The physics engine, songs, beat snapping, challenges, store and all tests stay as they
  are; only the drawing (today's SpriteKit `RunScene`) is replaced.
- The marble still moves in a flat plane (a marble run on a wall), so building stays as easy as now.
- Camera: the same 3D room all the time. While building, the camera faces the wall straight on (precise dragging and
  tilting); on **Drop** it eases into an angled, following camera like the video, and back when the song ends.
- Rooms: the **warm room** first (brass bars, dark wall). A chosen background is shown on the back wall (darkened).
  Holiday rooms later.
- "Name this song" mode: later, its own spec.

## Scene

Units: 1 scene unit = 100 engine points. Engine (x right, y down, 0…720 wide) → scene `X = (x − 360)/100`, `Y = −y/100`,
`Z = 0` for the marble's plane. (`SceneMapping`, pure, tested both ways.)

- **Back wall**: a large plane at `Z = −1.2`, warm dark plaster (or the chosen background, tinted), receiving shadows.
- **Lights**: one warm spot light above and in front, casting soft shadows of the bars, wires and marble onto the wall;
  low ambient fill; a gradient environment map for reflections.
- **Marble**: sphere, physically based, metalness 1, low roughness (chrome), reflecting the room. Skins become its texture
  (with a lower metalness so the pattern shows).
- **Bars**: boxes with thickness (14 pt tall, 20 pt deep), brass material; their glow (emission) turns on when hit, and
  gold when on the beat (the beat halo becomes emission). Two thin **wires** rise from each bar's ends to above the screen.
- **Bumpers**: short brass cylinders (pegs) facing the camera. **Ramps**: the curve extruded into a rail.
- **Hopper**: small brass funnel. **Cup** (challenges): a glowing ring on the wall.
- Note labels, selection ring, tilt handle, predicted path and beat rings: drawn in a 2D overlay (`SKScene` as the
  view's `overlaySKScene`) at the projected positions, so they stay crisp and readable.
- Hit: the bar flashes (emission pulse), a small spark burst (particles), the marble keeps its chrome look.

## Interaction

Touches are mapped from the screen onto the wall plane (`Z = 0`) by unprojecting with the current camera, then the
existing drag logic runs unchanged in engine coordinates (move, tilt handle, hopper, pan). Vertical panning moves the
camera exactly as the 2D camera does now. The `GameModel` interface doesn't change.

## Camera

- Build: perspective camera on the wall's normal, narrow field of view (looks nearly flat), framing 720 points wide.
- Play: eases (0.6 s) to a camera rotated about 12° down and 8° sideways, following the marble's height, then back.
- Reduce Motion: no angle change; plain follow.

## Rollout

- `RunView3D` (UIViewRepresentable around `SCNView`) + `RunScene3D` (scene building, per-frame update, touches).
- DEBUG-only switch to compare old/new renderer during development; the old SpriteKit renderer is removed once the 3D one
  is verified on device.
- Menu demo (`AttractScene`) moves to the same 3D room in a second step.

## Testing

- Unit: `SceneMapping` engine↔scene round trips; touch unprojection lands on the right engine point for known cameras;
  camera framing shows the full width; play-camera angles.
- Existing 113 tests unchanged.
- Visual: simulator screenshots in build and play, with bars hit and a skin; performance check (60 fps target, shadows on).

## Out of scope

"Name this song" mode, holiday 3D rooms, 3D menu (second step), haptics changes.
