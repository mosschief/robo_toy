// Tank robot: body controller for the Arduino Nano (Otto Nano shield).
//
// Modes (short press of the mode button cycles, the face shows the number):
//   1 PLAY     looks around, blinks, says hello when a hand comes close
//   2 EXPLORE  drives around on its own and turns away from obstacles
//   3 DANCE    dances to a tune
//   4 MY PROGRAM  runs myProgram() from my_program.h once
//   5 FACE TEST   shows which face module is which (for wiring)
// Hold the button 1.5 s to go to sleep (and again to wake up).
// The phone app (ESP32-CAM) can drive and control everything; when it stops
// sending, Tank goes back to the mode it was in.
//
// Upload: Tools > Board > Arduino Nano, Processor > ATmega328P (Old Bootloader
// for most clones). Flip the PROG/RUN switch to PROG first.
// Needs the "VL53L0X" library by Pololu (Library Manager).

#include "config.h"
#include "robot.h"
#include "face.h"
#include "sound.h"
#include "joints.h"
#include "tracks.h"
#include "sensors.h"
#include "my_program.h"

enum Mode : uint8_t { MODE_PLAY, MODE_EXPLORE, MODE_DANCE, MODE_PROGRAM, MODE_FACE_TEST, MODE_COUNT, MODE_SLEEP = 99 };
Mode mode = MODE_PLAY;
Mode modeBeforeSleep = MODE_PLAY;
bool remoteActive = false;
uint32_t lastRemoteDrive = 0, lastRemoteAny = 0, lastTelemetry = 0;
uint32_t nextIdleMove = 0, helloCooldown = 0;
bool lowBatteryShown = false;
bool pendingShort = false, pendingLong = false;   // button presses seen while busy

// ---------------- serial link to the ESP32-CAM ----------------
// Lines of text, for example "D 50 -50" (drive), "F 1" (face), "S 2" (sound),
// "J 4 120" (joint 4 to 120 degrees), "P 1" (pose), "M 1" (mode), "G 0" (guard off).
char line[32];
uint8_t lineLen = 0;

void setMode(Mode m);

void doPose(uint8_t p) {
  switch (p) {
    case 0: robot.rest(); break;
    case 1: robot.armsUp(); break;
    case 2: robot.hug(); break;
    case 3: robot.arms(90, 90); robot.elbows(10, 10); break;          // point forward
    case 4: robot.arms(170, 40); robot.elbows(30, 60); break;         // one arm up
    case 5: robot.wave(); break;
  }
}

void handleLine(char *s) {
  char cmd = s[0];
  int a = 0, b = 0;
  char *p = s + 1;
  a = strtol(p, &p, 10);
  b = strtol(p, &p, 10);
  lastRemoteAny = millis();
  switch (cmd) {
    case 'D':
      remoteActive = true;
      lastRemoteDrive = millis();
      robot.drive(constrain(a, -100, 100), constrain(b, -100, 100));
      break;
    case 'J': if (a >= 0 && a < JOINT_COUNT) Joints::move((Joint)a, b); break;
    case 'F': robot.face((Expression)constrain(a, 0, EXPRESSION_COUNT - 1)); break;
    case 'S': robot.sound((Sound)constrain(a, 0, SOUND_COUNT - 1)); break;
    case 'P': doPose(a); break;
    case 'M': if (a >= 0 && a < MODE_COUNT) setMode((Mode)a); break;
    case 'G': robot.guard = a != 0; break;
    case 'H': break;   // heartbeat
  }
}

void readLink() {
  while (Serial.available()) {
    char c = Serial.read();
    if (c == '\n' || c == '\r') {
      if (lineLen) { line[lineLen] = 0; handleLine(line); lineLen = 0; }
    } else if (lineLen < sizeof(line) - 1) {
      line[lineLen++] = c;
    } else {
      lineLen = 0;   // garbage: drop it
    }
  }
  // the phone stopped sending drive commands: stop the tracks
  if (remoteActive && millis() - lastRemoteDrive > REMOTE_TIMEOUT_MS) {
    robot.stop();
    remoteActive = false;
  }
}

void sendTelemetry() {
  if (millis() - lastTelemetry < TELEMETRY_MS) return;
  lastTelemetry = millis();
  Serial.print(F("T "));
  Serial.print(Sensors::distanceMm());
  Serial.print(' ');
  Serial.print(Sensors::batteryMv());
  Serial.print(' ');
  Serial.print(mode == MODE_SLEEP ? 9 : (uint8_t)mode);
  Serial.print(' ');
  Serial.println((uint8_t)Face::current());
}

// ---------------- modes ----------------
void setMode(Mode m) {
  robot.stop();
  robot.rest();
  Face::testPatternOff();
  mode = m;
  if (m == MODE_SLEEP) {
    robot.face(SLEEPY);
    robot.sound(SND_SLEEP);
    return;
  }
  robot.face(NEUTRAL);
  Face::showDigit(m + 1);
  Sounds::beeps(m + 1);
  if (m == MODE_FACE_TEST) Face::testPattern();
}

void playMode() {
  uint32_t t = millis();
  // say hello to a hand in front of the chest
  if (robot.distance() < HELLO_DISTANCE_MM && t > helloCooldown) {
    helloCooldown = t + 8000;
    robot.face(HAPPY);
    robot.sound(SND_HELLO);
    robot.wave();
    robot.face(NEUTRAL);
    return;
  }
  // now and then, look around
  if (t > nextIdleMove) {
    nextIdleMove = t + random(3000, 8000);
    int8_t dir = random(-1, 2);
    robot.look(dir);
    if (random(4) == 0) robot.arms(random(40, 120), random(40, 120));
    else robot.arms(JOINTS[L_SHOULDER].restAngle, JOINTS[R_SHOULDER].restAngle);
  }
}

void exploreMode() {
  if (robot.distance() > EXPLORE_TURN_MM) {
    robot.drive(45, 45);
    return;
  }
  robot.stop();
  robot.face(SURPRISED);
  robot.sound(SND_UHOH);
  robot.backward(400, 45);
  int8_t dir = random(2) ? 1 : -1;
  robot.look(dir);
  // spin until the way ahead is clear (give up after 3 s)
  robot.drive(dir * 50, -dir * 50);
  uint32_t until = millis() + 3000;
  while (millis() < until && robot.distance() < EXPLORE_TURN_MM + 100) {
    if (!robot.wait(20)) return;
  }
  robot.stop();
  robot.look(0);
  robot.face(NEUTRAL);
}

void danceMode() {
  robot.face(HAPPY);
  robot.sound(SND_DANCE);
  for (uint8_t i = 0; i < 2 && !robot.cancelled; i++) {
    robot.arms(170, 40); robot.head(60);  robot.wait(450);
    robot.arms(40, 170); robot.head(120); robot.wait(450);
  }
  robot.face(SILLY);
  robot.turnLeft(600, 60);
  robot.armsUp(); robot.wait(400);
  robot.face(WINK);
  robot.turnRight(600, 60);
  robot.hug(); robot.wait(500);
  robot.face(LOVE);
  robot.rest(); robot.head(90);
  robot.wait(1200);
}

void sleepMode() {
  robot.stop();
}

// Called from inside robot.wait(): lets the button and the phone interrupt long moves.
void checkInterrupts() {
  readLink();
  if (Sensors::buttonPressed()) { pendingShort = true; robot.cancelled = true; }
  if (Sensors::buttonLongPressed()) { pendingLong = true; robot.cancelled = true; }
  if (remoteActive && mode != MODE_PLAY) robot.cancelled = true;
}

// ---------------- setup / loop ----------------
void setup() {
  Serial.begin(LINK_BAUD);
  randomSeed(analogRead(A7));
  robot.begin();
  robot.hook = checkInterrupts;
  Serial.println(F("I tank"));
  robot.face(HAPPY);
  robot.sound(SND_HELLO);
  robot.wait(800);
  setMode(MODE_PLAY);
}

void loop() {
  robot.cancelled = false;
  robot.service();
  readLink();
  sendTelemetry();

  // button: short = next mode, long = sleep / wake
  bool shortPress = Sensors::buttonPressed() || pendingShort;
  bool longPress = Sensors::buttonLongPressed() || pendingLong;
  pendingShort = pendingLong = false;
  if (longPress) {
    if (mode == MODE_SLEEP) setMode(modeBeforeSleep);
    else { modeBeforeSleep = mode; setMode(MODE_SLEEP); }
    return;
  }
  if (shortPress) {
    setMode(mode == MODE_SLEEP ? modeBeforeSleep : (Mode)((mode + 1) % MODE_COUNT));
    return;
  }

  // battery
  uint16_t mv = robot.batteryMv();
  if (mv > 3000 && mv < BATTERY_EMPTY_MV) {
    if (!lowBatteryShown) { robot.face(SAD); robot.sound(SND_SAD); lowBatteryShown = true; }
    return;
  }

  // the phone is driving: keep the face/arms responsive, no autonomous moves
  if (remoteActive) return;

  switch (mode) {
    case MODE_PLAY: playMode(); break;
    case MODE_EXPLORE: exploreMode(); break;
    case MODE_DANCE: danceMode(); break;
    case MODE_PROGRAM:
      myProgram();
      robot.stop();
      if (!robot.cancelled) setMode(MODE_PLAY);
      break;
    case MODE_FACE_TEST: break;
    case MODE_SLEEP: sleepMode(); break;
    default: break;
  }
}
