# Harmocoder

## Introduction

This project combines SuperCollider, JUCE, Arduino and Processing to create a musical system where the singer is able to expand its vocal performance using an harmonizer in a new creative and intelligent way.
Basically, a harmonizer is an audio device that adds harmonic notes to an input audio signal, producing a rich and complex musical effect.
In this project, we didnt't implement only a classic automatic harmonizer but also a sort of fusion between a harmonizer and a vocoder that we indeed called Harmocoder.
While in the automatic harmonizer the way in which the harmonization is realized is fixed, from the moment that given the key of the scale each input note of the singer is dynamically used as root note to build the chord, in the harmocoder the singer is completely free to choose how to harmonize its voice playing simultaneously to its vocal performance a MIDI keyboard.
Each note sung by the artist will be pitched accordingly to the keys pressed at that specific instant.
This working principle can be seem proper of a vocoder but the main difference between a vocoder and our harmocoder is that the first uses the audio input (vocal sample or others) to shape the formant of what it's played with the MIDI keyboard, while in the second case the input is meant to be only the voice and with the keyboard is only pitched up or down but keeping the same harmonic content of the input (same timber).
To let even more degree of flexibility to the artist, we decided to add the possibility to process the output sound of the harmonizer with some effects applied and removed based on the gesture of the singer and on the light changing in the environment where the performance takes place.
To obtain such a goal, we exploited two  arduino sensors: a digital 3D accelerometer and an analog grayScale light intensity sensor.
The first one, attached to a glove that must be worn by the singer, map the orizontal and vertical scroll in the air to respectively turn on or turn off a distortion plugin (implemented with Juce) and a chorus effect (realized in supercollider), while the second dynamically change the dry/wet parameter of the light intensity sensed on the stage.
The main idea at the base of our project is to let the artist be able to significantly extend the horizon of its performance with the least effort possible.
That's the reason why we adopted a really basic GUI, trying to avoid the annoying interaction of setting some parameteres by clicking on them in favour of a more natural one which is able to let the artist more focus on what he's singing and harmonizing with the keyboard.

## Requirements

- SuperCollider
- JUCE
- Arduino IDE
- An Arduino (e.g., Arduino Uno)
- Hardware components (potentiometers, buttons, etc.)
- Grove 3-Axis Digital Accellerometer (±16g)
- Analog greyscale Sensor
- Wires and breadboard for connections

## Installation

### SuperCollider

1. Download and install SuperCollider from the [official website](https://supercollider.github.io/download).
2. Install any necessary plugins by following the instructions on the SuperCollider website.
3. Install sc3 supecollider exstensions

### JUCE

1. Download and install JUCE from the [official website](https://juce.com/get-juce).
2. Follow the instructions to set up JUCE with your preferred IDE (Xcode, Visual Studio, etc.).

### Arduino

1. Download and install the Arduino IDE from the [official website](https://www.arduino.cc/en/software).
2. Upload the firmware for the Arduino provided in the `arduino/firmware` directory.

### Processing

1. Download and install the Processing IDE from the [official website](https://processing.org/download).
2. Run the processing code provided in the ........ directory.


## Project Structure

- `arduino/`: Contains the Arduino code.
  - `firmware/`: Source code for the Arduino.
- `juce/`: Contains the JUCE project.
  - `Source/`: Source code for the user interface and SuperCollider integration.
- `supercollider/`: Contains SuperCollider scripts.
  - `harmonizer.scd`: Main script for signal processing.

## Hardware Setup

1. Connect wirings to the Arduino as described in `arduino/firmware/wiring_diagram.png`.
2. Upload the firmware to the Arduino using the Arduino IDE.

## Software Setup

### SuperCollider

1. Open `supercollider/harmonizer.scd` in SuperCollider.
2. Execute the code by pressing `Ctrl+Enter` (Windows/Linux) or `Cmd+Enter` (Mac).

### Distortion Plugin

1. Open

### Arduino

1. Ensure the Arduino is connected to the computer and the firmware is properly uploaded.
2. The Arduino should now be able to send and receive data from the JUCE software.

## Usage

1. Launch the  application. A window with controls for the harmonizer parameters should appear.
2. Adjust the parameters using the JUCE user interface or the physical controls connected to the Arduino.
3. Use SuperCollider to send audio signals to the harmonizer and listen to the output.


---

Thank you for choosing our Harmonizer! We hope you enjoy creating music with this unique tool.
