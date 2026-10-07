// YOUR PROGRAM. Press the mode button until the face shows 4, and Tank runs this once.
// See robot.h for everything Tank can do. Change it, upload, and try it!
#pragma once
#include "robot.h"

void myProgram() {
  robot.face(HAPPY);
  robot.sound(SND_HELLO);
  robot.wave();
  robot.wait(500);

  // drive forward until something is close, then back up and spin
  robot.drive(50, 50);
  while (robot.distance() > 250) {
    if (!robot.wait(20)) return;
  }
  robot.stop();
  robot.face(SURPRISED);
  robot.sound(SND_UHOH);
  robot.backward(600);
  robot.turnLeft(700);

  robot.face(LOVE);
  robot.armsUp();
  robot.sound(SND_HAPPY);
  robot.wait(1500);
  robot.rest();
}
