// Tank robot body controller (Arduino Nano on the Otto Nano shield).
// Everything you might need to tune for your own build is in this file.
#pragma once
#include <Arduino.h>

// ---------------- pins ----------------
// D0/D1 are the link to the ESP32-CAM. Flip the PROG/RUN switch to PROG
// before uploading to the Nano over USB.
const uint8_t PIN_MODE_BUTTON = 2;   // panel button to GND
const uint8_t PIN_BUZZER      = 3;   // passive buzzer
const uint8_t PIN_AIN1 = 4, PIN_PWMA = 5, PIN_AIN2 = 7;    // TB6612 channel A = left track
const uint8_t PIN_BIN1 = 8, PIN_PWMB = 6, PIN_BIN2 = A0;   // TB6612 channel B = right track
const uint8_t PIN_MATRIX_DIN = 11, PIN_MATRIX_CS = 12, PIN_MATRIX_CLK = 13;  // hardware SPI
const uint8_t PIN_BATTERY = A6;      // 10k / 10k divider from the battery +
// Servo pins are in the JOINTS table below. A4/A5 = I2C to the VL53L0X.

// ---------------- tracks ----------------
const bool LEFT_TRACK_REVERSED  = false;   // flip if a track runs backwards
const bool RIGHT_TRACK_REVERSED = false;
const uint8_t TRACK_MAX_PWM = 200;         // 255 = full speed; lower = gentler toy
const uint8_t TRACK_ACCEL   = 4;           // PWM steps per 5 ms (soft starts save gears)
const uint16_t REMOTE_TIMEOUT_MS = 400;    // stop if the phone goes quiet

// ---------------- servos ----------------
// Angles: shoulder 0 = arm straight down, 90 = pointing forward, 180 = straight up.
// Waist 90 = facing ahead, bigger = turned left. The elbows are a fixed bend.
// D10 and A2 are free (they drove the elbows in an earlier design).
// trim: degrees added so the joint matches the drawing at rest (calibrate once).
struct JointConfig {
  uint8_t pin;
  bool reversed;
  int8_t trim;
  uint8_t minAngle, maxAngle, restAngle;
};
enum Joint : uint8_t { L_SHOULDER, R_SHOULDER, WAIST, JOINT_COUNT };
const JointConfig JOINTS[JOINT_COUNT] = {
  //  pin  reversed trim  min  max  rest
  {   9,   true,     0,   40, 180,  40 },   // left shoulder (below 40 the claw hits the fender)
  {  A1,   false,    0,   40, 180,  40 },   // right shoulder
  {  A3,   false,    0,   25, 155,  90 },   // waist (65 each way: the cables allow about 70)
};
const uint8_t ARMS_CLEAR_ANGLE = 50;       // with the waist turned, the arms swing over the
                                           // lower body: keep the shoulders at least this high
const uint16_t SERVO_SPEED_DEG_S = 180;    // how fast joints move
const uint16_t SERVO_DETACH_MS   = 1500;   // stop holding after this long still: saves power,
                                           // and lets little hands move the arms freely

// ---------------- face: 4 x MAX7219 in a 2x2 square ----------------
// Module 0 is the first one wired to the Nano. For each module give its tile
// (column, row) in the square and its rotation in quarter turns clockwise.
// Run mode 4 (face test) to check: each module shows its number and an arrow
// pointing up. Fix these values until all four arrows point up.
const uint8_t MATRIX_TILE_X[4] = {0, 1, 0, 1};
const uint8_t MATRIX_TILE_Y[4] = {0, 0, 1, 1};
const uint8_t MATRIX_ROT[4]    = {0, 0, 0, 0};
const bool MATRIX_MIRROR = false;          // some modules wire columns right-to-left
const uint8_t MATRIX_BRIGHTNESS = 4;       // 0..15

// ---------------- distance sensor ----------------
const uint16_t STOP_DISTANCE_MM    = 120;  // never drive forward closer than this
const uint16_t EXPLORE_TURN_MM     = 250;  // explore mode turns away at this distance
const uint16_t HELLO_DISTANCE_MM   = 150;  // a hand this close says hello in play mode

// ---------------- battery (2 x 18650 in series) ----------------
const uint16_t BATTERY_LOW_MV  = 6800;     // sleepy face, half speed
const uint16_t BATTERY_EMPTY_MV = 6400;    // stop driving, ask for a charge
const float BATTERY_DIVIDER = 2.0;         // 10k / 10k

// ---------------- link to the ESP32-CAM ----------------
const uint32_t LINK_BAUD = 115200;
const uint16_t TELEMETRY_MS = 200;
