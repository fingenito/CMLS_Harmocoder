# Harmocoder

## Introduction

This project combines SuperCollider, JUCE, Arduino and Processing to create a musical system where the singer is able to expand its vocal performance using an harmonizer in a new creative and intelligent way.
Basically, a harmonizer is an audio device that adds harmonic notes to an input audio signal, producing a rich and complex musical effect.
In this project, we didnt't implement just a classic automatic harmonizer but also a sort of fusion between a harmonizer and a vocoder that we indeed called Harmocoder.
While in the automatic harmonizer the way in which the harmonization is realized is fixed, from the moment that given the key of the scale each input note of the singer is dynamically used as root note to build the chord, in the harmocoder the singer is completely free to choose how to harmonize its voice playing simultaneously to its vocal performance a MIDI keyboard.
Each note sung by the artist will be pitched accordingly to the keys pressed at that specific instant.
This working principle can be seem proper of a vocoder but the main difference between a vocoder and our harmocoder is that the first uses the audio input (vocal sample or others) to shape the formant of what it's played with the MIDI keyboard, while in the second case with the keyboard it is only possible to pitche up or down the audio input but keeping the same harmonic content (same timber).
To let even more degree of flexibility to the artist, we decided to add the possibility to process the output sound of the harmonizer with some effects applied and removed according to the gesture of the singer and on the changing light in the environment where the performance takes place.
To obtain such a goal, we exploited two  arduino sensors: a digital 3D accelerometer and an analog grayScale light intensity sensor.
The first one, attached to a glove that must be worn by the singer, map the orizontal and vertical scroll in the air to respectively turn on or turn off a distortion plugin (implemented with Juce) and a chorus effect (realized in Supercollider), while the second dynamically change the amount of a reverb (implemented in Supercollider) according to the light intensity sensed on the stage.
The main idea at the base of our project is to let the artist be able to significantly extend the horizon of its performance with the least effort possible.
That's the reason why we adopted a really basic GUI (implemented in Processing), trying to reduce as much as possible the annoying interaction based on setting some parameteres by clicking on them in favour of a more natural one which is able to let the artist focus on what he's singing and harmonising with the keyboard.

## Requirements

- SuperCollider
- JUCE
- Arduino IDE
- An Arduino (e.g., Arduino Uno)
- Grove 3-Axis Digital Accellerometer (±16g)
- Analog greyscale Sensor
- Wires and breadboard for connections

## Installations required to build the environment

### SuperCollider

1. Download and install SuperCollider from the [official website](https://github.com/supercollider/supercollider).
2. Install any necessary plugins by following the instructions on the SuperCollider website.
3. Install sc3 supecollider exstensions required for letting work our system: the Tartini pitch tracker and the VSTPlugin extension to allow to open and interact with a .VST3 plugin directly inside supercollider  


### JUCE

1. Download and install JUCE from the [official website](https://github.com/juce-framework/JUCE).
2. Follow the instructions to set up JUCE with your preferred IDE (Xcode, Visual Studio, etc.).

### Arduino

1. Download and install the Arduino IDE from the [official website](https://www.arduino.cc/en/software).
3. Install in the IDE the library required to use the 3D accelerometer provided in the `Source/Arduino` directory.

### Processing

1. Download and install the Processing IDE from the [official website](https://processing.org/download).


## Project Structure

- `Source/Arduino/`: Contains the Arduino code.
  - `detectionSensors/`: Source code for the Arduino.
- `Source/Juce/`: Contains the JUCE project.
  - `Distortion_Effect/`: Source code for the plugin opened and used in Supercollider.
- `Source/Supercollider/`: Contains SuperCollider script.
  - `Harmocoder.scd`: Main script for the signal processing of the whole project.
- `Source/Processing/`: Contains Processing script.
  - `GUI.pde`: Contains the GUI implementation. 

## Setting up the system

### Arduino
1. Connect wirings to the Arduino as described in `arduino/firmware/wiring_diagram.jpg`.
2. Upload the firmware provided in the `Source/Arduino/detectionSensors` directory to the Arduino board using the Arduino IDE. At this point if you keep connected the board to your computer, Arduino should has already started sending messages via serial communication.


### Juce

1. Open the file Distortion_Effect.jucer and build the project with you own IDE.
2. Search the file .VST3 inside the folder `Build` that will have just been generated and move it in the folder where you usually keep your musical plugin to be sure that it will be found by the VSTPlugin extension of Supercollider.

### SuperCollider

1. Open `Source/Supercollider/Harmocoder.scd` in SuperCollider.
2. Boot the server 
4. Execute the first block of code enclosed in brackets by pressing `Ctrl+Enter` (Windows/Linux) or `Cmd+Enter` (Mac) to setup the Harmocoder.
5. Execute at the same way also the second block to start the comunication with the other parts of the system
6. Press `Ctrl+.` (Windows/Linux) or `Cmd+.` (Mac) to effectively start the Harmocoder. Now you should be able to hear something because the Harmocoder, even if it's not yet comunicating with the other nodes of the system, is already processing your voice taken from the computer mic.

### Processing
1. Open the file GUI.pde to launch the user interface. Now all the nodes 


## Usage

Connect your MIDI keyboard to your computer and see the tutorial at this [AGGIUNGI VIDEO] link to understand how to interact with the GUI!


---

Thank you for choosing our Harmonizer! We hope you enjoy creating music with this unique tool.
