# Robot toy concepts (round 1)

OpenSCAD concept models for a tough, kid-proof Arduino robot toy that reuses
Otto DIY Humanoid ("fat version") electronics.

- `concept_a_tank.scad`: tracks, two 2-joint arms, turning head
- `concept_b_brick.scad`: 4WD with bumper and fenders, two arms, carry handle (recommended)
- `concept_c_digger.scad`: two big wheels, turret with one 3-joint claw arm
- `tank_v2.scad`: chosen Tank, revision 2 (bought track chassis, ESP32-CAM)
- `parts.scad`: shared placeholder parts (MAX7219 8x8, HC-SR04, SG90, wheels, tracks)
- `index.html` + `renders/`: concept sheet

Render a view:

```sh
xvfb-run -a openscad -o out.png --imgsize=1200,1000 \
  --camera=0,0,110,62,0,-32,820 --colorscheme=Tomorrow concepts/concept_b_brick.scad
```
