// Tank robot: camera and phone control (AI-Thinker ESP32-CAM).
//
// What it does:
//   - makes a Wi-Fi network "Tank-XXXX" (or joins your home Wi-Fi, see config.h)
//   - serves a control page at http://192.168.4.1 with live video, a joystick,
//     and buttons for faces, sounds, arm poses and modes
//   - passes every command to the Nano over a serial link, and shows the
//     distance and battery readings the Nano sends back
//   - accepts over-the-air updates from the Arduino IDE (port "tank")
//
// Board: "AI Thinker ESP32-CAM" (esp32 core 2.x or 3.x). Flash it the first time
// on the ESP32-CAM-MB USB adapter; after that you can update it over Wi-Fi.

#include "esp_camera.h"
#include <WiFi.h>
#include <ArduinoOTA.h>
#include "esp_http_server.h"
#include "config.h"
#include "page.h"

// AI-Thinker ESP32-CAM camera pins
#define PWDN_GPIO_NUM 32
#define RESET_GPIO_NUM -1
#define XCLK_GPIO_NUM 0
#define SIOD_GPIO_NUM 26
#define SIOC_GPIO_NUM 27
#define Y9_GPIO_NUM 35
#define Y8_GPIO_NUM 34
#define Y7_GPIO_NUM 39
#define Y6_GPIO_NUM 36
#define Y5_GPIO_NUM 21
#define Y4_GPIO_NUM 19
#define Y3_GPIO_NUM 18
#define Y2_GPIO_NUM 5
#define VSYNC_GPIO_NUM 25
#define HREF_GPIO_NUM 23
#define PCLK_GPIO_NUM 22

HardwareSerial Link(2);
httpd_handle_t webServer = nullptr, streamServer = nullptr;
bool cameraOk = false;

// latest telemetry from the Nano: "T <distance mm> <battery mV> <mode> <face>"
volatile uint16_t telDist = 9999, telMv = 0;
volatile uint8_t telMode = 0, telFace = 0;
volatile uint32_t telAt = 0;
SemaphoreHandle_t linkLock;

void linkSend(const char *line) {
  xSemaphoreTake(linkLock, portMAX_DELAY);
  Link.print(line);
  Link.print('\n');
  xSemaphoreGive(linkLock);
}

void readLink() {
  static char buf[48];
  static uint8_t n = 0;
  while (Link.available()) {
    char c = Link.read();
    if (c == '\n' || c == '\r') {
      buf[n] = 0;
      if (n > 2 && buf[0] == 'T') {
        unsigned d, mv, mode, face;
        if (sscanf(buf + 1, "%u %u %u %u", &d, &mv, &mode, &face) == 4) {
          telDist = d; telMv = mv; telMode = mode; telFace = face; telAt = millis();
        }
      }
      n = 0;
    } else if (n < sizeof(buf) - 1) {
      buf[n++] = c;
    } else {
      n = 0;
    }
  }
}

// ---------------- camera ----------------
bool startCamera() {
  camera_config_t c = {};
  c.ledc_channel = LEDC_CHANNEL_0;
  c.ledc_timer = LEDC_TIMER_0;
  c.pin_d0 = Y2_GPIO_NUM; c.pin_d1 = Y3_GPIO_NUM; c.pin_d2 = Y4_GPIO_NUM; c.pin_d3 = Y5_GPIO_NUM;
  c.pin_d4 = Y6_GPIO_NUM; c.pin_d5 = Y7_GPIO_NUM; c.pin_d6 = Y8_GPIO_NUM; c.pin_d7 = Y9_GPIO_NUM;
  c.pin_xclk = XCLK_GPIO_NUM; c.pin_pclk = PCLK_GPIO_NUM; c.pin_vsync = VSYNC_GPIO_NUM;
  c.pin_href = HREF_GPIO_NUM; c.pin_sccb_sda = SIOD_GPIO_NUM; c.pin_sccb_scl = SIOC_GPIO_NUM;
  c.pin_pwdn = PWDN_GPIO_NUM; c.pin_reset = RESET_GPIO_NUM;
  c.xclk_freq_hz = 20000000;
  c.pixel_format = PIXFORMAT_JPEG;
  c.frame_size = CAMERA_FRAME_SIZE;
  c.jpeg_quality = CAMERA_JPEG_QUALITY;
  c.fb_count = psramFound() ? 2 : 1;
  c.fb_location = psramFound() ? CAMERA_FB_IN_PSRAM : CAMERA_FB_IN_DRAM;
  c.grab_mode = CAMERA_GRAB_LATEST;
  if (esp_camera_init(&c) != ESP_OK) return false;
  sensor_t *s = esp_camera_sensor_get();
  s->set_vflip(s, CAMERA_FLIP);
  s->set_hmirror(s, CAMERA_FLIP);
  return true;
}

// ---------------- web handlers ----------------
esp_err_t indexHandler(httpd_req_t *req) {
  httpd_resp_set_type(req, "text/html");
  return httpd_resp_send(req, PAGE_HTML, HTTPD_RESP_USE_STRLEN);
}

// /cmd?c=D%2050%2050  -> one line to the Nano. Only known command letters pass.
esp_err_t cmdHandler(httpd_req_t *req) {
  char query[64], value[40];
  if (httpd_req_get_url_query_str(req, query, sizeof query) != ESP_OK ||
      httpd_query_key_value(query, "c", value, sizeof value) != ESP_OK) {
    httpd_resp_send_err(req, HTTPD_400_BAD_REQUEST, "missing c");
    return ESP_FAIL;
  }
  // decode %20 and + into spaces
  char line[40]; uint8_t n = 0;
  for (char *p = value; *p && n < sizeof(line) - 1; p++) {
    if (*p == '+') line[n++] = ' ';
    else if (*p == '%' && p[1] && p[2]) { char h[3] = {p[1], p[2], 0}; line[n++] = (char)strtol(h, nullptr, 16); p += 2; }
    else line[n++] = *p;
  }
  line[n] = 0;
  if (!strchr("DJFSPMGH", line[0]) || strchr(line, '\n')) {
    httpd_resp_send_err(req, HTTPD_400_BAD_REQUEST, "unknown command");
    return ESP_FAIL;
  }
  linkSend(line);
  httpd_resp_set_hdr(req, "Cache-Control", "no-store");
  return httpd_resp_send(req, "ok", 2);
}

esp_err_t statusHandler(httpd_req_t *req) {
  char json[96];
  bool fresh = millis() - telAt < 2000;
  snprintf(json, sizeof json, "{\"dist\":%u,\"mv\":%u,\"mode\":%u,\"face\":%u,\"nano\":%s,\"camera\":%s}",
           telDist, telMv, telMode, telFace, fresh ? "true" : "false", cameraOk ? "true" : "false");
  httpd_resp_set_type(req, "application/json");
  httpd_resp_set_hdr(req, "Cache-Control", "no-store");
  return httpd_resp_send(req, json, HTTPD_RESP_USE_STRLEN);
}

esp_err_t lightHandler(httpd_req_t *req) {
  char query[16], v[4] = "0";
  if (httpd_req_get_url_query_str(req, query, sizeof query) == ESP_OK) httpd_query_key_value(query, "on", v, sizeof v);
  digitalWrite(FLASH_LED_PIN, v[0] == '1');
  return httpd_resp_send(req, "ok", 2);
}

#define BOUNDARY "tankframe"
esp_err_t streamHandler(httpd_req_t *req) {
  if (!cameraOk) { httpd_resp_send_err(req, HTTPD_500_INTERNAL_SERVER_ERROR, "no camera"); return ESP_FAIL; }
  httpd_resp_set_type(req, "multipart/x-mixed-replace;boundary=" BOUNDARY);
  httpd_resp_set_hdr(req, "Access-Control-Allow-Origin", "*");
  char head[80];
  while (true) {
    camera_fb_t *fb = esp_camera_fb_get();
    if (!fb) return ESP_FAIL;
    int len = snprintf(head, sizeof head, "\r\n--" BOUNDARY "\r\nContent-Type: image/jpeg\r\nContent-Length: %u\r\n\r\n", fb->len);
    esp_err_t r = httpd_resp_send_chunk(req, head, len);
    if (r == ESP_OK) r = httpd_resp_send_chunk(req, (const char *)fb->buf, fb->len);
    esp_camera_fb_return(fb);
    if (r != ESP_OK) return r;   // the phone went away
  }
}

void startServers() {
  httpd_config_t cfg = HTTPD_DEFAULT_CONFIG();
  cfg.server_port = 80;
  cfg.ctrl_port = 32768;
  httpd_uri_t uris[] = {
    {"/", HTTP_GET, indexHandler, nullptr},
    {"/cmd", HTTP_GET, cmdHandler, nullptr},
    {"/status", HTTP_GET, statusHandler, nullptr},
    {"/light", HTTP_GET, lightHandler, nullptr},
  };
  if (httpd_start(&webServer, &cfg) == ESP_OK)
    for (auto &u : uris) httpd_register_uri_handler(webServer, &u);

  httpd_config_t scfg = HTTPD_DEFAULT_CONFIG();
  scfg.server_port = 81;
  scfg.ctrl_port = 32769;
  httpd_uri_t stream = {"/stream", HTTP_GET, streamHandler, nullptr};
  if (httpd_start(&streamServer, &scfg) == ESP_OK) httpd_register_uri_handler(streamServer, &stream);
}

// ---------------- Wi-Fi ----------------
void startWifi() {
  WiFi.setHostname(HOSTNAME);
  if (strlen(HOME_SSID)) {
    WiFi.mode(WIFI_STA);
    WiFi.begin(HOME_SSID, HOME_PASSWORD);
    for (int i = 0; i < 40 && WiFi.status() != WL_CONNECTED; i++) delay(250);
    if (WiFi.status() == WL_CONNECTED) {
      Serial.printf("Joined %s, open http://%s\n", HOME_SSID, WiFi.localIP().toString().c_str());
      return;
    }
  }
  uint8_t mac[6];
  WiFi.mode(WIFI_AP);
  WiFi.softAPmacAddress(mac);
  char ssid[16];
  snprintf(ssid, sizeof ssid, "Tank-%02X%02X", mac[4], mac[5]);
  WiFi.softAP(ssid, AP_PASSWORD);
  Serial.printf("Network %s, open http://%s\n", ssid, WiFi.softAPIP().toString().c_str());
}

void setup() {
  Serial.begin(115200);
  pinMode(FLASH_LED_PIN, OUTPUT);
  digitalWrite(FLASH_LED_PIN, LOW);
  linkLock = xSemaphoreCreateMutex();
  Link.begin(LINK_BAUD, SERIAL_8N1, LINK_RX_PIN, LINK_TX_PIN);
  cameraOk = startCamera();
  if (!cameraOk) Serial.println("Camera did not start: check the ribbon cable");
  startWifi();
  startServers();
  ArduinoOTA.setHostname(HOSTNAME);
  ArduinoOTA.setPassword(AP_PASSWORD);
  ArduinoOTA.begin();
  linkSend("S 1");   // Tank says hello when the phone link is up
}

void loop() {
  readLink();
  ArduinoOTA.handle();
  delay(2);
}
