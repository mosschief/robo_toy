# Building Tank

Tank is a tough, kid-proof Arduino robot: a printed tracked base (a scaled-up
SMARS-style design), a printed body
with a waist that turns the whole upper body on the tank base, two slim arms
with claws, a 16 x 16 LED face, a Wi-Fi camera in the chest with a laser distance sensor, and a phone control page. It reuses
the Otto DIY "fat version" electronics (Nano + shield, servos, LED matrix,
buzzer).

![Tank](../hardware/renders/tank.png)

## 1. Parts

### Already in your Otto kits

| Part | Qty | Notes |
|---|---|---|
| Otto Nano board (Nano + I/O shield) | 1 | body controller |
| Micro servos | 3 | 2 shoulders, 1 waist. Use **MG90S** (metal gears, same size) for the waist if you can, and for the shoulders too |
| MAX7219 8x8 LED matrix, 32 x 32 mm module | 4 | the face; buy one more if you have 3 |
| Passive buzzer, 12 mm | 1 | |
| Dupont cables | ~20 | |

### To buy

| Part | Qty | Notes |
|---|---|---|
| JGA25-370 gear motor, 6 V, 130-200 rpm, 4 mm D shaft | 2 | track drive; check the face screw spacing (`MOT_HOLE_SP`) and shaft offset (`MOT_OFF`) in `config.scad` |
| 608 skateboard bearings (8 x 22 x 7) | 12 | idlers and road wheels |
| M8 x 45 bolts + washers + nyloc nuts | 6 | wheel axles |
| M3 x 25 screws + M3 nyloc nuts | 42 | track link pins |
| M3 x 20 screws | 6 | sprocket halves to hub |
| M3 x 6 set screws | 2 | sprocket hub onto the motor shaft |
| *(or instead of all of the above)* TP101 / T101 aluminium tank chassis with motors | 1 | set `BASE = "bought"` in `config.scad` |
| ESP32-CAM (AI-Thinker, OV2640) + ESP32-CAM-MB USB adapter | 1 | camera, Wi-Fi |
| VL53L0X distance sensor breakout (GY-VL53L0XV2, ~25 x 10.7 mm) | 1 | |
| TB6612FNG motor driver | 1 | |
| 2 x 18650 holder (series, 7.4 V) + 2S protection board + 2 cells | 1 | |
| USB-C 2S (8.4 V) charging module | 1 | charge without opening the robot |
| 5 V 5 A buck converter (XL4015 type) | 1 | servos + logic + camera |
| KCD1 rocker switch (13 x 19 mm cut-out) | 1 | power |
| Mini slide switch SS12D00 | 1 | PROG / RUN |
| 16 mm momentary panel button | 1 | mode button |
| Resistors: 10k x 2 (battery sense), 1k + 2k (3.3 V divider) | | |
| 470 uF 10 V capacitor | 1 | across the ESP32-CAM 5 V input |
| 6808-2RS ball bearing (40 x 52 x 7 mm) | 1 | the waist turntable |
| Compression springs ~8 mm OD x 12 mm, 0.6-0.8 mm wire | 3 | clutches |
| M3 heat-set inserts (M3 x 5.7) | ~45 | |
| M3 socket screws 8, 10, 12, 20, 30 mm + washers + 3 nuts; M3 x 8 countersunk x 6 | | |
| M2 x 6 self-tapping screws | ~25 | servo tabs, horn-to-hub |
| Clear PETG / polycarbonate sheet, 2 mm | 72 x 72 + 24 x 24 | face window, lens window |
| Velcro strap 20 mm | 1 | holds the battery |

## 2. Printing

Export all parts with `hardware/export.sh` (or open `hardware/robot.scad`
in OpenSCAD and set `part`). Ready-made STLs are in `hardware/stl/`.

**Body parts in PETG** (PLA cracks when dropped): 4 walls, 5 top/bottom layers,
30 % gyroid, 0.2 mm layers. **TPU 95A** for bumpers and the antenna.

| STL | Qty | Material | Notes |
|---|---|---|---|
| lower_body | 1 | PETG | open side up, no supports |
| lid | 1 | PETG | |
| tray | 1 | PETG | pegboard for the boards |
| waist | 1 | PETG | already upside down (plate on the bed) |
| bearing_cap | 1 | PETG | |
| clamp_ring | 1 | PETG | |
| torso | 1 | PETG | already upside down (top on the bed); supports only in the two shoulder holes |
| chest_guard | 1 | PETG | |
| head_front | 1 | PETG | face down |
| head_back | 1 | PETG | |
| face_carrier | 1 | PETG | |
| base_frame | 1 | PETG | already upside down (deck on the bed), 102 x 176 mm |
| track_link | 42 | PETG | outside face down; 21 per track |
| sprocket_half | 4 | PETG | |
| sprocket_hub | 2 | PETG | flange down |
| wheel_half | 4 | PETG | idlers |
| road_wheel_half | 8 | PETG | |
| wheel_spacer | 6 | PETG | |
| arm | 2 | PETG | **mirror one** in the slicer for the left arm; supports under the claw |
| clutch_hub | 3 | PETG | ridges up |
| fender | 2 | PETG | **mirror one** |
| bumper | 2 | TPU | |
| antenna | 1 | TPU | |

## 3. Wiring

```
                 +-------------------- 7.4 V (2 x 18650) ---------------------+
 USB-C 2S charger -> battery -> rocker switch -+-> TB6612 VM (motors)        |
                                               +-> buck in  -> 5 V rail ------+
 5 V rail -> Nano 5V, servo V+ (shield), MAX7219 VCC, VL53L0X VIN, TB6612 VCC + STBY,
             ESP32-CAM 5V (470 uF cap at its pins). All grounds together.
 Battery + -> 10k -> A6 -> 10k -> GND   (battery voltage)
```

| Nano pin | Goes to |
|---|---|
| D0 (RX) | ESP32-CAM GPIO14 (TX), **through the PROG/RUN switch** |
| D1 (TX) | 1k -> ESP32-CAM GPIO15 (RX) -> 2k -> GND |
| D2 | mode button (other leg to GND) |
| D3 | buzzer + (other leg to GND) |
| D4 / D7 / D5 | TB6612 AIN1 / AIN2 / PWMA (left track) |
| D8 / A0 / D6 | TB6612 BIN1 / BIN2 / PWMB (right track) |
| D9 | left shoulder servo |
| A1 | right shoulder servo |
| A3 | waist servo |
| D10, A2 | free |
| D11 / D12 / D13 | MAX7219 DIN / CS / CLK (first module of the chain) |
| A4 / A5 | VL53L0X SDA / SCL |
| A6 | battery divider |

The four MAX7219 modules chain DOUT -> DIN. The camera and its board live in
the chest; the face cable goes down through the hole in the head floor into
the torso. Everything from the torso goes down to the Nano through the slot at
the back of the waist plate and the curved slot in the lid. Leave about 10 cm
of slack below the lid so the waist can turn both ways.

## 4. Assembly

0. **Base.** Inserts into the 6 deck holes. Bolt each motor to the inside of
   its side frame (2 x M3 from outside), shaft through the big hole, and zip-tie
   the can into its cradle. Screw the two sprocket halves onto a hub (3 x M3 x
   20), push it onto the motor shaft and tighten the set screw on the flat.
   Press a 608 into each wheel half; each wheel is two halves with a spacer
   between them on an M8 x 45 bolt (head inside the frame, washer and nyloc
   outside). Build each track from 21 links (M3 x 25 + nyloc per joint, horns
   facing in), wrap it round, join the last link, then slide the idler back in
   its slot until the track is snug and tighten the idler nut.
1. **Inserts.** Press M3 heat-set inserts into every round boss: lower body
   (6 on the rim, 4 bumper, 6 fender, 4 tray), lid (3 round the bearing
   housing), waist plate (3 in the bottom of the tube), torso (4 underneath,
   4 for the chest guard, 4 on top for the head), head (4 face-carrier,
   4 back-cap).
2. **Clutch hubs.** Screw each servo's round horn into a hub (2 x M2 from the
   horn side). Slide an M3 nut into the side slot later, after the hub is on the servo.
3. **Torso.** Fit the shoulder servos from inside so their tabs sit against the
   bulkheads, shafts out through the side holes; screw the tabs (M2). Centre
   every servo (90 deg) before fitting hubs. Press hubs onto the splines, drive the servo's centre screw through the
   hub, then slide in the nuts.
4. **Chest.** Slide the ESP32-CAM into its rails from below, lens forward;
   slide the VL53L0X into its rails. Put the 24 x 24 clear sheet into the chest
   guard and screw the guard on (4 x M3 x 8).
5. **Waist.** Press the 6808 bearing into the housing on the lid and screw the
   bearing cap on (3 x M3 x 8 countersunk). Feed the torso cables down through
   the slot at the back of the waist plate and bolt the torso onto the plate
   (4 x M3 x 10 from under the plate). Push the plate's tube down through the
   bearing, lay the torso on its back and screw the clamp ring onto the bottom
   of the tube (3 x M3 x 8 countersunk): now the body turns but can't lift out.
6. **Lower body.** Tray on its standoffs (the waist servo tower comes up
   through it), boards on the tray (nylon standoffs or zip ties), battery in its
   cradle with the strap, switches and charge port in the back, buzzer in its
   holder behind the grille, mode button in the lid. Drop the waist servo into
   its tower (tabs on the rim, 2 x M2), centre it, fit its clutch hub and slide
   the nut in.
7. **Close up.** Feed the torso cables through the curved slot in the lid to the
   Nano, leaving slack. Lid onto the lower body so the tube's grooves sit on the
   waist hub (6 x M3 countersunk). Drop the waist spring screw (M3 x 20 + washer
   + spring) through the hole in the top of the torso and tighten it into the
   hub nut until the body only turns by hand with a firm twist. Lower body onto
   the base deck (6 x M3 x 10 through the floor slots into the deck inserts), fenders and bumpers on.
8. **Arms.** Hang each arm on its shoulder hub: M3 x 30 + washer + spring from
   the outside into the hub nut. Tighten until the arm clicks round only with a
   firm twist.
9. **Head.** Clear 72 x 72 sheet against the inside of the face opening, the
   four matrices face-first into the carrier, carrier screwed on (4 x M3 x 10).
   Feed the face cable down through the floor hole, set the head on the torso
   and screw it down from inside (4 x M3 x 12 through the floor bosses). Push
   the TPU antenna into the top. Close the back cap.

## 5. Software

**Nano** (`firmware/robot_body`): Arduino IDE, board *Arduino Nano*, processor
*ATmega328P (Old Bootloader)* for most clones. Install the **VL53L0X** library by
Pololu. Flip PROG/RUN to **PROG**, upload, flip back to **RUN**.

**ESP32-CAM** (`firmware/robot_cam`): install the *esp32* boards package, board
*AI Thinker ESP32-CAM*. First upload on the ESP32-CAM-MB adapter; later uploads
work over Wi-Fi (port "tank", password = `AP_PASSWORD`).

**Faces:** edit the pictures in `tools/faces.txt`, then run
`python3 tools/make_faces.py` and upload the Nano again.

**Your own program:** edit `firmware/robot_body/my_program.h`; the commands are
listed at the top of `robot.h`. Press the mode button until the face shows 4.

## 6. First start and calibration

1. Power on: Tank says hello and shows mode 1 (Play).
2. Press the mode button until the face shows **5** (face test). Each module
   should show an arrow pointing up and 1-4 dots. Fix `MATRIX_TILE_X/Y`,
   `MATRIX_ROT` and `MATRIX_MIRROR` in `config.h` until it does.
3. Check the rest pose: shoulders ~40 deg forward, the body facing straight
   ahead. Adjust `trim` in `config.h`, or loosen the spring screw and click the
   part round one notch (60 deg) if it is far off. If the body turns right when
   you slide "Turn body" left on the phone, set `reversed` for the waist.
4. Drive from the phone: join Wi-Fi **Tank-XXXX** (password `tankrobot`), open
   **http://192.168.4.1**. If a track runs backwards set
   `LEFT_TRACK_REVERSED` / `RIGHT_TRACK_REVERSED`.

## 7. Using it

| Mode | Face shows | What Tank does |
|---|---|---|
| Play | 1 | turns its body to look around, blinks, waves at a hand held near its chest |
| Explore | 2 | drives on its own, backs off and turns away from obstacles |
| Dance | 3 | dances to a tune |
| My code | 4 | runs `myProgram()` once |
| Face test | 5 | wiring check for the face |
| Sleep | hold 1.5 s | sleepy face, nothing moves; hold again to wake |

The phone page has a joystick, Slow/Fast, a Light (the camera board's LED),
Bumper (the stop-before-a-wall guard, on by default), faces, sounds, arm poses,
modes and a Turn body slider. When the phone stops sending, the tracks stop within
0.4 s.

## Safety

* Lithium cells: use a protected 2S pack, charge only through the charger
  module, and keep the lid screwed shut.
* The shoulder and waist clutches click round instead of breaking when a child
  forces an arm or twists the body; the springs are inside, so no small parts
  come loose.
* With the body turned, the arms swing over the lower body, so the firmware
  keeps the shoulders at least `ARMS_CLEAR_ANGLE` (50 deg) up.
* `TRACK_MAX_PWM` and the Slow default keep it at walking pace.

## Things to check on your parts

* **Motors**: JGA25-370 sellers differ in face screw spacing and shaft offset;
  set `MOT_*` in `config.scad`. The TB6612 is fine for these at the default
  `TRACK_MAX_PWM`; if a motor stalls a lot, lower the speed.
* **Bought chassis instead**: set `BASE = "bought"` and `CH_*` to its size, and
  drill the deck to match the lower body floor slots.
* **Matrix modules**: the face carrier is for 32 x 32 mm (FC-16 style) modules.
  The older 50 x 32 mm boards with the chip below the LEDs won't fit; tell us
  and the carrier can be redrawn with the top row flipped.
* **Bearing**: the lid and plate are drawn for a 6808-2RS (40 x 52 x 7 mm);
  set `BR` in `config.scad` for another size.
* **ESP32-CAM lens position**: `CAM_X`, `CAM_Z` in `config.scad`.
* **Back panel heights**: the charge port (z 35 mm), PROG/RUN switch (z 26) and
  Nano USB opening (z 25-37) sit above the rear bumper. Mount the charger
  module and the Nano (on standoffs) so their sockets line up with the holes.
