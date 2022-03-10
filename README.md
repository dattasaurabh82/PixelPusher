# PixelPusher

## Caution

_[pixelpusher](https://github.com/hzeller/rpi-matrix-pixelpusher) is also a name of a different kind of LED control prototcol. We just like the name, hence this name for the repo. But it has nothing to do with the afore mentioned prototcol. We are instead using ARTNET DMX_

---

## What is this?

<img width="1792" alt="Screenshot 2022-03-09 at 9 09 48 PM" src="https://user-images.githubusercontent.com/4619862/157452862-2e9a9f87-c998-4d5d-8b51-cac687c7caa1.png">


A software that is able to take .mp4 video files (of a fixed size: 500x40) and by using ARTNET, it pushes the content to a NeoPixel LED strip attached to our [HARDWARE]()

Upto 4 layers of simultaneous video sources are allowed which can be to be switched between to show up on the NeoPixel LED strip, by either manually clicking or by external MQTT triggers.

### It built using:

1. [Processing 4.0b1](https://github.com/processing/processing4/releases/tag/processing-1276-4.0b1). (Tested on both macOS Monterey and Windows 10 64 bit)
2. Libraries used are (can be installed through Processing's library manager):
    - [mqtt 1.7.3](https://github.com/256dpi/processing-mqtt/releases/download/v1.7.3/mqtt.zip)
    - [artnet4j 0.6.2](https://github.com/cansik/artnet4j/releases/download/0.6.2/artnet4j.zip)
    - [controlP5 2.2.6](https://github.com/sojamo/controlp5/releases/download/v2.2.6/controlP5-2.2.6.zip)
    - [video 8.2.0](https://github.com/processing/processing-video/releases/download/r8-2.0/video-2.0.zip)

---

## Why? (with caveats)

We wanted to design a simple software to quickly test single strip video animations (__size:__ 500x40) on a __single strip__ of NeoPixel LEDs.

_Currently we are restricted to only __1 universe__ ._

In the ARTNET world, __1 universe__ means 170 pixel data.

Thus it is suitable to test on low density single NeoPixel LED strips or higher density NeoPixel LED strips (144 LED pixels / strip)

_But in the software you can play with the number (<170) according to your pixel counts._

---

license: [MIT](https://github.com/dattasaurabh82/PixelPusherNeo/blob/main/LICENSE)

Primary developer: [Matthieu Cherubini](https://github.com/mchrbn)

Soft Changes: [Saurabh Datta](https://github.com/dattasaurabh82)
