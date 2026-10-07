// The easy way to program Tank. Use these in my_program.h.
//
//   robot.forward(1000);         drive forward for 1 second
//   robot.turnLeft(500);         spin left for half a second
//   robot.face(HAPPY);           HAPPY SAD SURPRISED ANGRY SLEEPY LOVE DIZZY WINK SILLY NEUTRAL
//   robot.sound(SND_HAPPY);      SND_BEEP SND_HELLO SND_HAPPY SND_SAD SND_SURPRISE SND_UHOH SND_DANCE
//   robot.arms(90, 90);          left and right shoulder: 0 down, 90 forward, 180 up
//   robot.wave();                wave hello with the right arm
//   robot.look(-1);              look left (-1), ahead (0) or right (1) with eyes and head
//   robot.wait(500);             do nothing for half a second
//   if (robot.distance() < 200)  something is closer than 20 cm
#pragma once
#include <Arduino.h>
#include "config.h"
#include "face.h"
#include "sound.h"

class Robot {
 public:
  void begin();
  void service();                       // keeps everything running; called by wait()

  // driving (speed 0..100 percent, default gentle)
  void forward(uint16_t ms, uint8_t speed = 60);
  void backward(uint16_t ms, uint8_t speed = 60);
  void turnLeft(uint16_t ms, uint8_t speed = 60);
  void turnRight(uint16_t ms, uint8_t speed = 60);
  void drive(int8_t left, int8_t right);   // keep driving until stop()
  void stop();

  // body
  void arms(int16_t left, int16_t right);
  void elbows(int16_t left, int16_t right);
  void head(int16_t angle);              // 90 = ahead
  void look(int8_t dir);
  void wave();
  void armsUp();
  void hug();
  void rest();

  // face and sound
  void face(Expression e);
  void sound(Sound s);

  // senses
  uint16_t distance();
  uint16_t batteryMv();

  // time
  bool wait(uint16_t ms);                // returns false if the program was cancelled
  bool cancelled = false;
  void (*hook)() = nullptr;              // extra work to do while waiting (button, phone link)

  // obstacle guard: forward driving stops at STOP_DISTANCE_MM
  bool guard = true;
  bool blocked();                        // true while the guard is stopping us

 private:
  bool waitMoves();
  int8_t wantL = 0, wantR = 0;
  bool wasBlocked = false;
};

extern Robot robot;
