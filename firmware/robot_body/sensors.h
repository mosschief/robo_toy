// VL53L0X distance sensor (non-blocking), battery voltage, mode button.
#pragma once
#include <Arduino.h>

namespace Sensors {
  void begin();
  void update();                  // call often
  uint16_t distanceMm();          // 9999 = nothing in range or no sensor
  bool hasDistance();             // false if the sensor did not answer at start-up
  uint16_t batteryMv();
  bool buttonPressed();           // true once per short press
  bool buttonLongPressed();       // true once when held for 1.5 s
}
