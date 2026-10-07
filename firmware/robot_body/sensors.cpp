#include "sensors.h"
#include <Wire.h>
#include <VL53L0X.h>
#include "config.h"

namespace {
VL53L0X tof;
bool tofOk = false;
uint16_t dist = 9999;
uint32_t distAt = 0;
uint16_t battMv = 0;
uint32_t lastBatt = 0;
bool btnDown = false, shortFlag = false, longFlag = false, longFired = false;
uint32_t btnSince = 0, lastBtnChange = 0;
}  // namespace

namespace Sensors {
void begin() {
  pinMode(PIN_MODE_BUTTON, INPUT_PULLUP);
  Wire.begin();
  Wire.setWireTimeout(3000, true);     // a loose sensor cable must never freeze the robot
  tof.setTimeout(30);
  tofOk = tof.init();
  if (tofOk) {
    tof.setMeasurementTimingBudget(33000);
    tof.startContinuous(50);
  }
  battMv = analogRead(PIN_BATTERY) * (5000.0f * BATTERY_DIVIDER / 1023.0f);
}

void update() {
  uint32_t t = millis();
  if (tofOk && (tof.readReg(VL53L0X::RESULT_INTERRUPT_STATUS) & 0x07)) {
    uint16_t mm = tof.readReg16Bit(VL53L0X::RESULT_RANGE_STATUS + 10);
    tof.writeReg(VL53L0X::SYSTEM_INTERRUPT_CLEAR, 0x01);
    dist = (mm == 0 || mm > 2000) ? 9999 : mm;
    distAt = t;
  }
  if (t - distAt > 500) dist = 9999;   // stale reading: assume clear

  if (t - lastBatt > 500) {
    lastBatt = t;
    uint16_t mv = analogRead(PIN_BATTERY) * (5000.0f * BATTERY_DIVIDER / 1023.0f);
    battMv = (battMv * 3 + mv) / 4;    // smooth out motor dips
  }

  bool down = digitalRead(PIN_MODE_BUTTON) == LOW;
  if (down != btnDown && t - lastBtnChange > 30) {
    lastBtnChange = t;
    btnDown = down;
    if (down) { btnSince = t; longFired = false; }
    else if (!longFired) shortFlag = true;
  }
  if (btnDown && !longFired && t - btnSince > 1500) { longFired = true; longFlag = true; }
}

uint16_t distanceMm() { return dist; }
bool hasDistance() { return tofOk; }
uint16_t batteryMv() { return battMv; }
bool buttonPressed() { bool f = shortFlag; shortFlag = false; return f; }
bool buttonLongPressed() { bool f = longFlag; longFlag = false; return f; }
}  // namespace Sensors
