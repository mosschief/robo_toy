#include "sound.h"
#include "config.h"

namespace {
struct Note { uint16_t hz; uint16_t ms; };   // hz 0 = rest

const Note BEEP[] PROGMEM = {{1760, 80}, {0, 0}};
const Note HELLO[] PROGMEM = {{988, 90}, {1319, 90}, {1760, 160}, {0, 0}};
const Note HAPPY[] PROGMEM = {{1047, 80}, {1319, 80}, {1568, 80}, {2093, 200}, {0, 0}};
const Note SAD[] PROGMEM = {{784, 200}, {698, 200}, {622, 200}, {523, 400}, {0, 0}};
const Note SURPRISE[] PROGMEM = {{880, 60}, {1760, 60}, {3520, 120}, {0, 0}};
const Note UHOH[] PROGMEM = {{1175, 150}, {1, 60}, {880, 250}, {0, 0}};
const Note DANCE[] PROGMEM = {{1047, 120}, {1, 30}, {1047, 120}, {1319, 120}, {1568, 240}, {1319, 120}, {1568, 360}, {0, 0}};
const Note SLEEP[] PROGMEM = {{523, 300}, {392, 300}, {262, 500}, {0, 0}};
const Note *const TUNES[SOUND_COUNT] = {BEEP, HELLO, HAPPY, SAD, SURPRISE, UHOH, DANCE, SLEEP};

const Note *tune = nullptr;
uint8_t idx = 0;
uint32_t noteEnd = 0;
uint8_t beepsLeft = 0;
bool muted = false;

const Note BEEP_ONCE[] PROGMEM = {{2093, 70}, {1, 90}, {0, 0}};
}  // namespace

namespace Sounds {
void begin() { pinMode(PIN_BUZZER, OUTPUT); }

void play(Sound s) {
  if (s >= SOUND_COUNT || muted) return;
  tune = TUNES[s]; idx = 0; noteEnd = 0; beepsLeft = 0;
}

void beeps(uint8_t n) { if (!muted && n) { beepsLeft = n - 1; tune = BEEP_ONCE; idx = 0; noteEnd = 0; } }

bool playing() { return tune != nullptr; }

void mute(bool on) { muted = on; if (on) { noTone(PIN_BUZZER); tune = nullptr; } }

void update() {
  if (!tune || millis() < noteEnd) return;
  Note n;
  memcpy_P(&n, &tune[idx], sizeof n);
  if (n.ms == 0) {
    if (beepsLeft) { beepsLeft--; idx = 0; return; }
    noTone(PIN_BUZZER); tune = nullptr; return;
  }
  if (n.hz > 1) tone(PIN_BUZZER, n.hz, n.ms); else noTone(PIN_BUZZER);
  noteEnd = millis() + n.ms;
  idx++;
}
}  // namespace Sounds
