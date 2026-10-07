// Tank robot: camera + Wi-Fi board (AI-Thinker ESP32-CAM).
#pragma once

// Wi-Fi. By default Tank makes its own network: join "Tank-XXXX" with the
// password below, then open http://192.168.4.1 on the phone or tablet.
// To use your home Wi-Fi instead, fill in HOME_SSID / HOME_PASSWORD; Tank
// falls back to its own network if it cannot connect within 10 seconds.
#define AP_PASSWORD   "tankrobot"      // at least 8 characters
#define HOME_SSID     ""
#define HOME_PASSWORD ""
#define HOSTNAME      "tank"           // also the over-the-air update name

// Serial link to the Nano: ESP32 GPIO14 (TX) -> Nano D0 (RX),
// Nano D1 (TX) -> 1k/2k divider -> ESP32 GPIO15 (RX).
#define LINK_TX_PIN 14
#define LINK_RX_PIN 15
#define LINK_BAUD   115200

// Camera picture. FRAMESIZE_QVGA (320x240) is smooth on most phones;
// FRAMESIZE_VGA (640x480) is sharper but slower.
#define CAMERA_FRAME_SIZE FRAMESIZE_QVGA
#define CAMERA_JPEG_QUALITY 14          // 10 = best, 63 = worst
#define CAMERA_FLIP false               // set true if the picture is upside down

#define FLASH_LED_PIN 4                 // the bright LED on the board = headlight
