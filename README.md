# Tank: a tough Arduino robot toy

A kid-proof robot on a printed tracked base. Its upper body turns at the waist,
the arms and waist click instead of breaking, and it has a 16 x 16 LED face,
a Wi-Fi camera and a distance sensor in the chest, and a phone control page. It reuses the electronics from
the Otto DIY "fat version" (Nano + shield, servos, LED matrix, buzzer).

![Tank](hardware/renders/tank.png)

| Folder | What's in it |
|---|---|
| [docs/BUILD.md](docs/BUILD.md) | parts list, printing, wiring, assembly, setup |
| [hardware/](hardware) | OpenSCAD source (`robot.scad`, `config.scad`), `stl/`, `renders/`, `export.sh` |
| [firmware/robot_body](firmware/robot_body) | Arduino Nano: face, arms, tracks, sensor, modes, `my_program.h` |
| [firmware/robot_cam](firmware/robot_cam) | ESP32-CAM: Wi-Fi, live video, phone control page |
| [tools/](tools) | `faces.txt` (draw faces) and `make_faces.py` |
| [concepts/](concepts) | the earlier concept rounds |
