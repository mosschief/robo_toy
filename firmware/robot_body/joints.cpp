#include "joints.h"
#include <Servo.h>

namespace {
Servo servos[JOINT_COUNT];
float pos[JOINT_COUNT];
uint8_t target[JOINT_COUNT];
uint32_t settledAt[JOINT_COUNT];
uint32_t lastUpdate = 0;

void writeServo(uint8_t j) {
  const JointConfig &c = JOINTS[j];
  int16_t a = (int16_t)(pos[j] + 0.5f) + c.trim;
  if (c.reversed) a = 180 - a;
  if (!servos[j].attached()) servos[j].attach(c.pin);
  servos[j].write(constrain(a, 0, 180));
}
}  // namespace

namespace Joints {
void begin() {
  for (uint8_t j = 0; j < JOINT_COUNT; j++) {
    pos[j] = target[j] = JOINTS[j].restAngle;
    writeServo(j);
    settledAt[j] = millis();
  }
  lastUpdate = millis();
}

void move(Joint j, int16_t a) {
  if (j >= JOINT_COUNT) return;
  target[j] = constrain(a, JOINTS[j].minAngle, JOINTS[j].maxAngle);
}

void moveAll(int16_t ls, int16_t le, int16_t rs, int16_t re) {
  move(L_SHOULDER, ls); move(L_ELBOW, le); move(R_SHOULDER, rs); move(R_ELBOW, re);
}

void rest() { for (uint8_t j = 0; j < JOINT_COUNT; j++) move((Joint)j, JOINTS[j].restAngle); }

void update() {
  uint32_t t = millis();
  uint32_t dt = t - lastUpdate;
  if (dt < 15) return;
  lastUpdate = t;
  float maxStep = SERVO_SPEED_DEG_S * dt / 1000.0f;
  for (uint8_t j = 0; j < JOINT_COUNT; j++) {
    float d = target[j] - pos[j];
    if (fabsf(d) > 0.01f) {
      pos[j] += constrain(d, -maxStep, maxStep);
      writeServo(j);
      settledAt[j] = t;
    } else if (servos[j].attached() && t - settledAt[j] > SERVO_DETACH_MS) {
      servos[j].detach();
    }
  }
}

bool busy() {
  for (uint8_t j = 0; j < JOINT_COUNT; j++) if (fabsf(target[j] - pos[j]) > 0.5f) return true;
  return false;
}

uint8_t angle(Joint j) { return (uint8_t)(pos[j] + 0.5f); }
}  // namespace Joints
