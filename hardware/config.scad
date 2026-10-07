// Tank robot: every dimension in one place (mm).
// Change these to match the parts you actually bought, then re-export.

$fn = 48;

// ---------- print / fasteners ----------
WALL      = 3;      // shell wall. Print PETG, 4 perimeters, 30% gyroid.
INS_D     = 4.2;    // hole for an M3 x 5.7 brass heat-set insert
INS_L     = 6;
BOSS_D    = 9;
M3        = 3.4;    // M3 clearance
M3_HEAD   = 6.6;    // M3 socket head counterbore
M2_PILOT  = 1.8;    // servo tab screws (self-tapping M2)
NUT_AF    = 5.9;    // M3 nut across flats (+clearance)
NUT_T     = 2.7;
CLR       = 0.3;    // general fit clearance

// ---------- MG90S / SG90 micro servo ----------
SV_L      = 22.8;   // body length (long axis)
SV_W      = 12.2;   // body width
SV_TAB_L  = 32.2;   // length across mounting tabs
SV_TAB_T  = 2.5;    // tab thickness
SV_BELOW  = 15.9;   // body bottom to underside of tabs
SV_ABOVE  = 4.3;    // top of tabs to top of body
SV_SPLINE = 12.6;   // top of tabs to tip of output spline
SV_SCREW  = 27.8;   // tab screw hole spacing
SV_SHAFT  = 5.6;    // output shaft offset from body centre along long axis
SV_DOME_D = 12.0;   // gear dome around the spline

// Round "disk" servo horn that comes with the servo
HORN_D    = 21.0;
HORN_T    = 2.0;
HORN_HOLE_R = 7.5;  // radius of the screw holes used to fix horn to the clutch hub

// ---------- breakaway clutch (one design, used at all 5 joints) ----------
// Horn hub (on the servo) has radial V ridges; the limb has matching grooves.
// An M3 screw + compression spring (8 mm OD, ~12 mm long) presses them together.
// A hard yank makes the limb click round instead of stripping servo gears.
CL_D      = 26;
CL_T      = 9;      // hub body thickness
CL_RIDGES = 6;
CL_RH     = 1.6;    // ridge height
CL_RW     = 3.4;    // ridge base width
HUB_FACE  = 10.1;   // tab top -> hub servo-side face (horn sits on the spline)
LIMB_GAP  = 0.3;
LIMB_FACE = HUB_FACE + CL_T + LIMB_GAP;   // tab top -> limb contact face (19.4)
WELL_D    = 30;     // recess the hub sits in, so limbs stay close to the body
SPRING_D  = 9;      // counterbore for spring + washer

// ---------- bought chassis ----------
// "mini TP101" style aluminium tank chassis. Measure yours and edit.
CH_L = 193; CH_W = 163; CH_H = 60; TR_W = 30;
DECK_GAP = (CH_W - 2 * TR_W);             // free width between the tracks

// ---------- lower body (sits on the chassis deck) ----------
LB = [96, 176, 47];     // X width, Y length, Z height of the tub
LB_R = 8;
LID_T = 3;

// ---------- torso ----------
TO = [96, 80, 56];
TO_R = 10;
SHOULDER_Z = 38;        // shoulder axis height above torso bottom
SHOULDER_Y = 0;

// ---------- head ----------
HD = [100, 72, 100];
HD_R = 12;
FACE_Z = 52;            // centre of the 16x16 display above head bottom
NECK_GAP = 1;           // head bottom to torso top

// ---------- arms ----------
UA_T = 40;              // upper arm thickness (X) - holds the elbow servo
UA_W = 30;              // upper arm width (Y)
UA_LEN = 62;            // shoulder axis to elbow axis
FA_T = 20;              // forearm thickness
FA_W = 26;
FA_LEN = 58;            // elbow axis to wrist

// ---------- face: 4 x MAX7219 8x8 modules in a 2x2 square ----------
MX = 32.2;              // module outline (FC-16 style, 32 x 32 PCB)
MX_DEPTH = 9;           // matrix block + PCB, without the header pins
MX_GAP = 0.8;           // printed divider between modules
FACE_WIN = 66;          // visible opening in the head
WIN_SHEET = [72, 72, 2];// clear PETG / polycarbonate sheet

// ---------- chest: ESP32-CAM + VL53L0X ----------
CAM_X = -10;  CAM_Z = 30;      // lens centre on the torso front
TOF_X = 17;   TOF_Z = 30;
CAM_PCB = [27, 40.5, 1.6];
TOF_PCB = [10.7, 25, 1.6];      // GY-VL53L0XV2 breakout, mounted upright
CHEST_WIN = [52, 26, 2];        // clear window sheet over lens + sensor

// ---------- world placement (z = 0 is the chassis deck top) ----------
Z_LB    = 0;
Z_TORSO = LB[2] + LID_T;
Z_HEAD  = Z_TORSO + TO[2] + NECK_GAP;
