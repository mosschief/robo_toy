#include "face.h"
#include <SPI.h>
#include "config.h"

namespace {
uint16_t fb[16];
bool dirty = true;
EyesId eyes = EYES_OPEN, shownEyes = EYES_OPEN;
MouthId mouth = MOUTH_SMILE;
Expression expr = NEUTRAL;
bool talking = false;
bool overlay = false;           // a digit or test pattern is on screen
uint32_t overlayUntil = 0;
uint32_t nextBlink = 0, blinkEnd = 0, nextTalk = 0;
bool talkOpen = false;

struct Pair { EyesId e; MouthId m; };
const Pair EXPRESSIONS[EXPRESSION_COUNT] = {
  {EYES_OPEN, MOUTH_SMILE}, {EYES_OPEN, MOUTH_GRIN}, {EYES_SAD, MOUTH_FROWN},
  {EYES_BIG, MOUTH_OH}, {EYES_ANGRY, MOUTH_FLAT}, {EYES_SLEEPY, MOUTH_FLAT},
  {EYES_HEART, MOUTH_SMILE}, {EYES_DIZZY, MOUTH_ZIGZAG}, {EYES_WINK, MOUTH_GRIN},
  {EYES_OPEN, MOUTH_TONGUE},
};

// 3 x 5 digits for showDigit, scaled 2x
const uint8_t DIGITS[10][5] PROGMEM = {
  {7,5,5,5,7},{2,6,2,2,7},{7,1,7,4,7},{7,1,7,1,7},{5,5,7,1,1},
  {7,4,7,1,7},{7,4,7,5,7},{7,1,1,2,2},{7,5,7,5,7},{7,5,7,1,7}};

void sendAll(uint8_t reg, uint8_t data) {
  digitalWrite(PIN_MATRIX_CS, LOW);
  for (uint8_t m = 0; m < 4; m++) { SPI.transfer(reg); SPI.transfer(data); }
  digitalWrite(PIN_MATRIX_CS, HIGH);
}

bool pixel(uint8_t x, uint8_t y) { return (fb[y] >> (15 - x)) & 1; }

// One 8-pixel row of module m, as that module's digit register wants it.
uint8_t moduleRow(uint8_t m, uint8_t r) {
  uint8_t out = 0;
  for (uint8_t c = 0; c < 8; c++) {
    uint8_t x, y;
    switch (MATRIX_ROT[m] & 3) {
      case 0: x = c;     y = r;     break;
      case 1: x = r;     y = 7 - c; break;
      case 2: x = 7 - c; y = 7 - r; break;
      default: x = 7 - r; y = c;    break;
    }
    if (pixel(MATRIX_TILE_X[m] * 8 + x, MATRIX_TILE_Y[m] * 8 + y))
      out |= MATRIX_MIRROR ? (1 << c) : (0x80 >> c);
  }
  return out;
}

void flush() {
  for (uint8_t r = 0; r < 8; r++) {
    digitalWrite(PIN_MATRIX_CS, LOW);
    for (int8_t m = 3; m >= 0; m--) { SPI.transfer(r + 1); SPI.transfer(moduleRow(m, r)); }
    digitalWrite(PIN_MATRIX_CS, HIGH);
  }
  dirty = false;
}

void compose() {
  for (uint8_t i = 0; i < 9; i++) fb[i] = pgm_read_word(&EYES_BITMAPS[shownEyes][i]);
  MouthId m = (talking && talkOpen) ? MOUTH_TALK : mouth;
  for (uint8_t i = 0; i < 7; i++) fb[9 + i] = pgm_read_word(&MOUTH_BITMAPS[m][i]);
  dirty = true;
}

bool blinks(EyesId e) { return e == EYES_OPEN || e == EYES_LEFT || e == EYES_RIGHT || e == EYES_ANGRY || e == EYES_SAD; }
}  // namespace

namespace Face {
void begin() {
  pinMode(PIN_MATRIX_CS, OUTPUT);
  digitalWrite(PIN_MATRIX_CS, HIGH);
  SPI.begin();
  SPI.beginTransaction(SPISettings(4000000, MSBFIRST, SPI_MODE0));
  sendAll(0x0F, 0);      // display test off
  sendAll(0x09, 0);      // no BCD decode
  sendAll(0x0B, 7);      // scan all 8 rows
  sendAll(0x0C, 1);      // wake up
  brightness(MATRIX_BRIGHTNESS);
  show(NEUTRAL);
  flush();
}

void brightness(uint8_t level) { sendAll(0x0A, level & 0x0F); }

void update() {
  uint32_t now = millis();
  if (overlay) {
    if (now < overlayUntil) { if (dirty) flush(); return; }
    overlay = false;
    compose();
  }
  // blink every few seconds
  if (blinks(eyes)) {
    if (blinkEnd && now >= blinkEnd) { shownEyes = eyes; blinkEnd = 0; compose(); }
    else if (!blinkEnd && now >= nextBlink) {
      shownEyes = EYES_BLINK; blinkEnd = now + 140; nextBlink = now + random(2500, 6000); compose();
    }
  }
  if (talking && now >= nextTalk) { talkOpen = !talkOpen; nextTalk = now + random(90, 180); compose(); }
  if (dirty) flush();
}

void set(EyesId e, MouthId m) {
  eyes = shownEyes = e; mouth = m; blinkEnd = 0;
  if (!overlay) compose();
}

void show(Expression e) {
  if (e >= EXPRESSION_COUNT) return;
  expr = e;
  set(EXPRESSIONS[e].e, EXPRESSIONS[e].m);
}

void look(int8_t dir) { set(dir < 0 ? EYES_LEFT : dir > 0 ? EYES_RIGHT : EXPRESSIONS[expr].e, mouth); }

void talk(bool on) { if (talking != on) { talking = on; talkOpen = false; if (!overlay) compose(); } }

void showDigit(uint8_t n) {
  memset(fb, 0, sizeof fb);
  for (uint8_t r = 0; r < 5; r++) {
    uint8_t bits = pgm_read_byte(&DIGITS[n % 10][r]);
    uint16_t row = 0;
    for (uint8_t c = 0; c < 3; c++) if (bits & (4 >> c)) row |= 0x3 << (9 - c * 2);
    fb[3 + r * 2] = fb[4 + r * 2] = row;
  }
  overlay = true; overlayUntil = millis() + 900; dirty = true;
}

void testPattern() {
  memset(fb, 0, sizeof fb);
  // module-local drawing: an up arrow in each tile plus dots = tile number + 1
  for (uint8_t t = 0; t < 4; t++) {
    uint8_t tx = (t & 1) * 8, ty = (t >> 1) * 8;
    const uint8_t arrow[6] = {0x18, 0x3C, 0x7E, 0x18, 0x18, 0x18};
    for (uint8_t r = 0; r < 6; r++) fb[ty + r] |= (uint16_t)arrow[r] << (8 - tx);
    for (uint8_t d = 0; d <= t; d++) fb[ty + 7] |= (uint16_t)0x80 >> (d * 2) << (8 - tx);
  }
  overlay = true; overlayUntil = millis() + 600000UL; dirty = true;
}

void testPatternOff() { overlay = false; compose(); }

Expression current() { return expr; }
}  // namespace Face
