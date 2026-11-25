# Studio Look — Design

Date: 2026-11-13 · Reference: a screen recording of marble-music reels (light grey wall, painted blocks on pegs, wire
rails, clear glass marble, close tilted camera following the marble, framed pictures on the wall). Replaces the dark
"warm room" from the 2026-10-11 3D look. Only the style is copied: the reference's club badges, player photos and
sponsor logos are not used.

## Decisions

- Physics unchanged: the marble's radius stays 14 points, so saved songs and all challenges play exactly as before.
  The marble looks bigger because the show camera is close (about 2.3x while a song plays).
- Building stays straight on (the 2D labels must line up with the pieces); only the show camera changes.
- All the look's numbers are in `RoomLook` (top of `Course3D.swift`) for tuning on a device.

## Room

- Wall: warm light-grey plaster (a tiling speck texture), 32 points behind the marble's plane (was 120), so shadows
  land right next to the pieces. The wall follows the view in whole texture tiles so the plaster doesn't slide.
- Light: one directional key light from high right in front (shadows fall down-left), warm ambient fill, a bright
  environment map with a "window" for highlights. Colour grade: slightly lower saturation, a little contrast, soft vignette.
- The chosen background is hung as framed pictures down the wall, alternating left and right (none: bare plaster).

## Pieces

- Bars: painted blocks in the note colour under a clear coat, chamfered, on one dark metal peg into the wall, two
  screw heads on the face. Same size as the engine's bar.
- Bumpers: painted knobs with a black rubber ring at the engine's radius, on a peg, a screw in the middle.
- Ramps: wire track: two painted rails (radius 3.2 pt, 8 pt either side of the marble's plane) placed where the
  engine's marble touches the curve, a dark spine under them, ball ends, three pegs into the wall.
- Hopper: dark metal funnel on a peg. Cup: unchanged.
- Hits still glow (emission flash on the painted material, rails included) with sparks.

## Marble

- Clear glass: a faint transparent body plus an additive shell for the highlights and the Fresnel rim.
- Inside: classic skin = an ice-blue cat's eye (four twisted vanes); other skins = their pattern on a core sphere.
- The core rolls with the marble's sideways movement.

## Show camera

- `SceneMapping.showCamera(target:viewSize:)`: 34° lens, about 320 points across at the marble, looking down about 19°
  and from about 9° to the right; the target sits at the centre of the view.
- The target eases after the marble with a small lead in the direction it moves, and leans toward the course's middle.
- Blend from the building camera over about 0.6 s (position, angles and lens). Reduce Motion: no show camera.
- `RoomLook.cinematic`: depth of field focused on the marble, light motion blur and grain while the show camera runs.

## To check on device

- Exposure and light balance (HDR exposure adaptation is on), shadow softness, glass look.
- Frame rate on the oldest supported phone with `cinematic` on; turn it off if it drops below 60 fps.
- Tests: `SceneMappingTests` (show camera centres its target, is close up, blends lens and angles).
