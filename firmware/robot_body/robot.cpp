#include "robot.h"
#include "tracks.h"
#include "joints.h"
#include "sensors.h"

Robot robot;

void Robot::begin() {
  Sensors::begin();
  Face::begin();
  Sounds::begin();
  Tracks::begin();
  Joints::begin();
}

bool Robot::blocked() { return guard && wasBlocked; }

void Robot::service() {
  Sensors::update();
  // obstacle guard: never push forward into something close
  bool close = Sensors::distanceMm() < STOP_DISTANCE_MM;
  int8_t l = wantL, r = wantR;
  if (guard && close && (l + r) > 0) {
    int8_t fwd = (l + r) / 2;
    l -= fwd; r -= fwd;                  // keep the turning part, drop the forward part
    if (!wasBlocked) { Face::show(SURPRISED); Sounds::play(SND_SURPRISE); }
    wasBlocked = true;
  } else {
    wasBlocked = false;
  }
  uint16_t mv = Sensors::batteryMv();
  if (mv > 3000 && mv < BATTERY_EMPTY_MV) { l = r = 0; }
  Tracks::setSpeedScale(mv > 3000 && mv < BATTERY_LOW_MV ? 50 : 100);
  Tracks::drive(l, r);
  Tracks::update();
  Joints::update();
  Sounds::update();
  Face::talk(Sounds::playing());
  Face::update();
}

bool Robot::wait(uint16_t ms) {
  uint32_t end = millis() + ms;
  while ((int32_t)(millis() - end) < 0) {
    service();
    if (hook) hook();
    if (cancelled) return false;
  }
  return true;
}

bool Robot::waitMoves() {
  while (Joints::busy()) { service(); if (hook) hook(); if (cancelled) return false; }
  return true;
}

void Robot::drive(int8_t left, int8_t right) { wantL = left; wantR = right; }
void Robot::stop() { wantL = wantR = 0; }

void Robot::forward(uint16_t ms, uint8_t speed)   { drive(speed, speed);   wait(ms); stop(); }
void Robot::backward(uint16_t ms, uint8_t speed)  { drive(-speed, -speed); wait(ms); stop(); }
void Robot::turnLeft(uint16_t ms, uint8_t speed)  { drive(-speed, speed);  wait(ms); stop(); }
void Robot::turnRight(uint16_t ms, uint8_t speed) { drive(speed, -speed);  wait(ms); stop(); }

void Robot::arms(int16_t left, int16_t right) { Joints::move(L_SHOULDER, left); Joints::move(R_SHOULDER, right); }
void Robot::waist(int16_t angle) { Joints::move(WAIST, angle); }
void Robot::look(int8_t dir) { Face::look(dir); waist(90 - dir * 45); }

void Robot::wave() {
  Joints::move(R_SHOULDER, 165);
  if (!waitMoves()) return;
  for (uint8_t i = 0; i < 3; i++) {
    Joints::move(R_SHOULDER, 130); if (!waitMoves()) return;
    Joints::move(R_SHOULDER, 170); if (!waitMoves()) return;
  }
  Joints::move(R_SHOULDER, JOINTS[R_SHOULDER].restAngle);
}

void Robot::armsUp() { arms(175, 175); }
void Robot::hug() { arms(100, 100); }
void Robot::rest() { Joints::rest(); }

void Robot::face(Expression e) { Face::show(e); }
void Robot::sound(Sound s) { Sounds::play(s); }

uint16_t Robot::distance() { return Sensors::distanceMm(); }
uint16_t Robot::batteryMv() { return Sensors::batteryMv(); }
