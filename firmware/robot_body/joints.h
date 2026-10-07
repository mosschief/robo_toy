// Arm servos: smooth moves, limits, and letting go when idle.
#pragma once
#include <Arduino.h>
#include "config.h"

namespace Joints {
  void begin();
  void update();                                   // call often
  void move(Joint j, int16_t angle);               // clamped to the joint's limits
  void moveAll(int16_t ls, int16_t le, int16_t rs, int16_t re);
  void rest();
  bool busy();                                     // any joint still moving
  uint8_t angle(Joint j);
}
