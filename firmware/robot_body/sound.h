// Little tunes on the passive buzzer, played in the background.
#pragma once
#include <Arduino.h>

enum Sound : uint8_t { SND_BEEP, SND_HELLO, SND_HAPPY, SND_SAD, SND_SURPRISE, SND_UHOH, SND_DANCE, SND_SLEEP, SOUND_COUNT };

namespace Sounds {
  void begin();
  void update();               // call often
  void play(Sound s);
  void beeps(uint8_t n);       // n short beeps (mode changes)
  bool playing();
  void mute(bool on);
}
