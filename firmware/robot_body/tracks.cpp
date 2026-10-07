#include "tracks.h"
#include "config.h"

namespace {
int16_t target[2] = {0, 0}, now[2] = {0, 0};
uint8_t scale = 100;
uint32_t lastStep = 0;

void output(uint8_t side, int16_t pwm) {
  bool rev = side == 0 ? LEFT_TRACK_REVERSED : RIGHT_TRACK_REVERSED;
  if (rev) pwm = -pwm;
  uint8_t in1 = side == 0 ? PIN_AIN1 : PIN_BIN1;
  uint8_t in2 = side == 0 ? PIN_AIN2 : PIN_BIN2;
  uint8_t pwmPin = side == 0 ? PIN_PWMA : PIN_PWMB;
  digitalWrite(in1, pwm > 0);
  digitalWrite(in2, pwm < 0);
  analogWrite(pwmPin, abs(pwm));
}
}  // namespace

namespace Tracks {
void begin() {
  const uint8_t pins[] = {PIN_AIN1, PIN_AIN2, PIN_PWMA, PIN_BIN1, PIN_BIN2, PIN_PWMB};
  for (uint8_t p : pins) { pinMode(p, OUTPUT); digitalWrite(p, LOW); }
}

void drive(int8_t left, int8_t right) {
  left = constrain(left, -100, 100);
  right = constrain(right, -100, 100);
  target[0] = (int32_t)left * TRACK_MAX_PWM * scale / 10000;
  target[1] = (int32_t)right * TRACK_MAX_PWM * scale / 10000;
}

void stop() { target[0] = target[1] = 0; }

void setSpeedScale(uint8_t percent) { scale = constrain(percent, 0, 100); }

void update() {
  uint32_t t = millis();
  if (t - lastStep < 5) return;
  lastStep = t;
  for (uint8_t s = 0; s < 2; s++) {
    int16_t d = target[s] - now[s];
    // stopping is always allowed at full rate; speeding up is ramped
    int16_t step = (abs(target[s]) < abs(now[s])) ? TRACK_ACCEL * 3 : TRACK_ACCEL;
    now[s] += constrain(d, -step, step);
    output(s, now[s]);
  }
}

bool movingForward() { return target[0] + target[1] > 0; }
}  // namespace Tracks
