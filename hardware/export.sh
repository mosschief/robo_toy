#!/bin/sh
# Export every printable part to stl/ and render the assembly images.
# Needs OpenSCAD 2021.01 or newer (and xvfb-run on a headless machine).
set -e
cd "$(dirname "$0")"
mkdir -p stl renders
for p in lower_body lid tray waist bearing_cap clamp_ring torso chest_guard head_front head_back \
         face_carrier arm clutch_hub bumper fender antenna \
         base_frame sprocket_half sprocket_hub wheel_half road_wheel_half wheel_spacer track_link; do
  echo "== $p"
  openscad -q -D "part=\"$p\"" -o "stl/$p.stl" robot.scad
done
R="openscad --imgsize=1400,1200 --colorscheme=Tomorrow"
command -v xvfb-run >/dev/null && R="xvfb-run -a $R"
$R --camera=0,0,85,62,0,-32,880 -o renders/tank.png assembly.scad
$R --camera=0,0,85,68,0,150,880 -o renders/tank_back.png assembly.scad
$R -D EXPLODE=1 --camera=0,0,165,65,0,-35,1450 -o renders/tank_exploded.png assembly.scad
$R -D 'SHOW_TANK=false' -D 'SHOW_BASE=true' --camera=0,0,-20,60,0,-35,520 -o renders/base.png assembly.scad
