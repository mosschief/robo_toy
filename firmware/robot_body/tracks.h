// Two track motors on a TB6612FNG driver, with soft starts.
#pragma once
#include <Arduino.h>

namespace Tracks {
  void begin();
  void update();                      // call often (ramps toward the target)
  void drive(int8_t left, int8_t right);   // -100 .. 100 percent
  void stop();
  void setSpeedScale(uint8_t percent);     // 50 when the battery is low
  bool movingForward();
}
