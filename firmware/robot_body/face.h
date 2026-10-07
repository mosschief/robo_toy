// 16 x 16 face on four chained MAX7219 8x8 modules.
#pragma once
#include <Arduino.h>
#include "faces_data.h"

enum Expression : uint8_t {
  NEUTRAL, HAPPY, SAD, SURPRISED, ANGRY, SLEEPY, LOVE, DIZZY, WINK, SILLY,
  EXPRESSION_COUNT
};

namespace Face {
  void begin();
  void update();                              // call often: blinking, talking, redraw
  void show(Expression e);                    // pick a whole expression
  void set(EyesId eyes, MouthId mouth);       // or mix eyes and mouth yourself
  void look(int8_t dir);                      // -1 left, 0 ahead, 1 right (keeps the mouth)
  void talk(bool on);                         // animate the mouth while a sound plays
  void showDigit(uint8_t n);                  // big number, for mode changes
  void testPattern();                         // module numbers + "up" arrows, for wiring
  void testPatternOff();
  void brightness(uint8_t level);
  Expression current();
}
