#!/bin/sh
# Export every printable part to stl/ and render the assembly images.
# Needs OpenSCAD 2021.01 or newer (and xvfb-run on a headless machine).
set -e
cd "$(dirname "$0")"
mkdir -p stl renders
for p in lower_body lid tray torso chest_guard head_front head_back face_carrier \
         upper_arm_inner upper_arm_outer forearm clutch_hub bumper fender antenna; do
  echo "== $p"
  openscad -q -D "part=\"$p\"" -o "stl/$p.stl" robot.scad
done
R="openscad --imgsize=1400,1200 --colorscheme=Tomorrow"
command -v xvfb-run >/dev/null && R="xvfb-run -a $R"
$R --camera=0,0,60,62,0,-32,780 -o renders/tank.png assembly.scad
$R --camera=0,0,60,68,0,150,780 -o renders/tank_back.png assembly.scad
$R -D EXPLODE=1 --camera=0,0,110,65,0,-35,1150 -o renders/tank_exploded.png assembly.scad
