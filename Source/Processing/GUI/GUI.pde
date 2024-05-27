import controlP5.*;
import oscP5.*;
import netP5.*;

// global variables for sending messages to supercollider
OscP5 oscP5;
NetAddress supercolliderAddress;
ControlP5 cp5;

// font for small text
PFont subtitle;

// global variables for GUI elements
myButton buttonHarmonizer;
myButton buttonHarmocoder;
DropdownList dropdownKeyRoot;
Toggle selectMajorMinor;
Slider sendMicToFx;
Slider micHarmXfade;
Slider micGain;
Slider reverbLevel;
Led ledChorus;
Led ledDistortion;

// variables for dropdown menu animation
boolean isOpening = false;
boolean isClosing = false;
int targetHeight = 150;
int barHeight = 20;
int animationSpeed = 5;

// global variables to set the automatic harmonizer
String majorMinor = "major";
int rootKey = 0;

// global states of toggles
boolean selectMajorMinorState = true;

void setup() {
  size(800, 800);
  
  cp5 = new ControlP5(this);
  
  oscP5 = new OscP5(this, 12000); // Local port for Processing
  supercolliderAddress = new NetAddress("127.0.0.1", 57120);
  
  // Create a new font with the desired size
  subtitle = createFont("Action_Man.ttf", 13); // Replace "Arial" with the desired font and 30 with the desired size
  
  // Insert the labels
  cp5.addTextlabel("effects")
     .setText("monitor ur FX!")
     .setPosition(150, 330)
     .setFont(createFont("Action_Man.ttf", 20))
     .setColor(color(255));
     
  cp5.addTextlabel("midiHarm")
     .setText("connect ur \nMIDI \ncontroller! ;)")
     .setPosition(40, 180)
     .setFont(createFont("Action_Man.ttf", 17))
     .setColor(color(255));     
     
  cp5.addTextlabel("volume")
     .setText("Control ur mix settings!")
     .setPosition(460, 330)
     .setFont(createFont("Action_Man.ttf", 20))
     .setColor(color(255)); 
     
  cp5.addTextlabel("autoHarm")
     .setText("Control your automatic Harm!")
     .setPosition(450, 245)
     .setFont(createFont("Action_Man.ttf", 20))
     .setColor(color(255));      
 
  // buttons to switch between automatic harmonizer and harmonizer with MIDI
  buttonHarmonizer = new myButton(220, 70, 70, 110, 10, false, "Harmonizer");
  buttonHarmocoder = new myButton(40, 70, 70, 110, 10, true, "Harmocoder");
     
  // Create a DropdownList for the key
  dropdownKeyRoot = cp5.addDropdownList("Select Key Root")
                .setPosition(365, 70)
                .setSize(200, barHeight) // Width and height
                .setItemHeight(30) // Height of each item
                .setBarHeight(barHeight) // Height of the main bar
                .setColorBackground(color(184, 183, 153, 95)) // Background color
                .setColorActive(color(178, 127, 135)) // Active background color
                .setColorForeground(color(255, 182, 193))
                .setLock(true) // by default the harmocoder is selected (cannot be clicked)
                .setFont(subtitle)
                .setColorValue(255);
  dropdownKeyRoot.getCaptionLabel().setColor(color(255)); // Title text color (white)
  
  // Add items to the DropdownList with the names of the musical notes
  dropdownKeyRoot.addItem("C", 0);
  dropdownKeyRoot.addItem("C#", 1);
  dropdownKeyRoot.addItem("D", 2);
  dropdownKeyRoot.addItem("D#", 3);
  dropdownKeyRoot.addItem("E", 4);
  dropdownKeyRoot.addItem("F", 5);
  dropdownKeyRoot.addItem("F#", 6);
  dropdownKeyRoot.addItem("G", 7);
  dropdownKeyRoot.addItem("G#", 8);
  dropdownKeyRoot.addItem("A", 9);
  dropdownKeyRoot.addItem("A#", 10);
  dropdownKeyRoot.addItem("B", 11);
  
  // Create a toggle to select major or minor harmonization (for auto harm)
  selectMajorMinor = cp5.addToggle("selectMajorMinor")
     .setPosition(600, 70)
     .setSize(140, 70)
     .setValue(false)
     .setMode(ControlP5.SWITCH)
     .setLabel("major")
     .setFont(subtitle)
     .setLock(true)
     .setColorBackground(color(138, 43, 226, 95))
     .setColorActive(color(255, 165, 0, 95));
     
     
  micGain = cp5.addSlider("micGain")
     .setPosition(490, 370)
     .setSize(40, 375)
     .setRange(0, 1)
     .setLabel("Mic gain")
     .setValue(1) 
     .setFont(subtitle)
     .setColorForeground(color(142, 69, 133))   
     .setColorBackground(color(211, 110, 112))
     .setColorActive(color(255, 240, 220, 0));
    
  
  sendMicToFx = cp5.addSlider("sendMicToFx")
     .setPosition(590, 370)
     .setSize(40, 375)
     .setRange(0, 1)
     .setLabel("Mic to Fx")
     .setValue(0.5)
     .setFont(subtitle)
     .setColorForeground(color(106, 90, 205))  
     .setColorBackground(color(157, 193, 131))
     .setColorActive(color(255, 240, 220, 0));
     
     
  micHarmXfade = cp5.addSlider("micHarmXfade")
     .setPosition(690, 370)
     .setSize(40, 375)
     .setRange(0, 1)
     .setLabel("Mic/Harm \nXfade")
     .setValue(0.5)
     .setFont(subtitle)
     .setColorForeground(color(41, 49, 51)) 
     .setColorBackground(color(128, 0, 32))
     .setColorActive(color(255, 240, 220, 0));

  reverbLevel = cp5.addSlider("reverbLevel")
     .setPosition(80, 350)
     .setSize(20, 400)
     .setRange(0, 100)
     .setValue(50)
     .setLabel("Reverb level")
     .setLock(true) 
     .setFont(subtitle)
     .setColorForeground(color(153, 102, 51))  
     .setColorBackground(color(205, 92, 92))   // Background color of the slider
     //.setColorActive(color(255, 240, 220))  // Color when the slider is active (clicked)
     .setColorValueLabel(color(255, 255, 255))  // Color of the value shown
     .setColorCaptionLabel(color(255, 255, 255)); // Color of the label
     
  ledChorus = new Led(265, 475, 30, false, "CHORUS"); // initialize the LED with a red color
  ledDistortion = new Led(265, 625, 30, false, "DISTORTION"); // initialize the LED with a red color

  // tell supercollider that by default the harmocoder is selected
  OscMessage harmSelectedMsg = new OscMessage("/harmSelected");
  String msg = "harmocoder";
  harmSelectedMsg.add(msg);
  oscP5.send(harmSelectedMsg, supercolliderAddress);
  
  // tell supercollider the default value of input sliders
  OscMessage sendMicToFxMsg = new OscMessage("/micSendToFx");
  OscMessage micHarmXfadeMsg = new OscMessage("/micHarmXfade");
  OscMessage micGainMsg = new OscMessage("/micGain");
  
  sendMicToFxMsg.add(sendMicToFx.getValue());
  oscP5.send(sendMicToFxMsg, supercolliderAddress);
  
  micHarmXfadeMsg.add(micHarmXfade.getValue());
  oscP5.send(micHarmXfadeMsg, supercolliderAddress);
  
  micGainMsg.add(micGain.getValue());
  oscP5.send(micGainMsg, supercolliderAddress);
}


void draw() {
  background(0, 70, 67);  
  
  noFill();
  stroke(color(145, 212, 171));
  strokeWeight(6);
  
  // top right rectangle
  rect(190, 20, 585, 250, 30);
  
  stroke(color(134, 239, 190));
  // bottom left rectangle
  rect(20, 320, 330, 460, 30);
  
  stroke(color(130, 191, 144));
  // bottom right rectangle
  rect(430, 320, 340, 460, 30);
  
  stroke(color(154, 191, 132));
  // top left rectangle
  rect(20, 20, 150, 250, 30);
  
  buttonHarmonizer.display();
  buttonHarmocoder.display();
  
  ledChorus.display();
  ledDistortion.display();
  
  if (isOpening) {
    int currentHeight = dropdownKeyRoot.getHeight();
    if (currentHeight < targetHeight) {
      dropdownKeyRoot.setHeight(currentHeight + animationSpeed);
    } else {
      isOpening = false;
      dropdownKeyRoot.setHeight(targetHeight);
    }
  }
  
  if (isClosing) {
    int currentHeight = dropdownKeyRoot.getHeight();
    if (currentHeight > barHeight) {
      dropdownKeyRoot.setHeight(currentHeight - animationSpeed);
    } else {
      isClosing = false;
      dropdownKeyRoot.setHeight(barHeight);
      dropdownKeyRoot.close(); // Actual closing
    }
  }
  
  cp5.draw();
}



// CLASSES ---------------------------------------------------------------------------
class Led {
  float x, y, r;
  color c;
  boolean state;
  String label; // Add attribute for the label
  PFont font;
  
  Led(float tempX, float tempY, float tempR, boolean tempState, String tempLabel) {
    x = tempX;
    y = tempY;
    r = tempR;
    state = tempState;
    font = createFont("Action_Man.ttf", 15);
    label = tempLabel; // Initialize the label
    if(state){
      c = color(255, 165, 0);
    } else {
      c = color(155, 65, 0);
    }
  }
  
  void display() {
    fill(c);
    noStroke();
    ellipse(x, y, r*2, r*2);
    
    // Draw the label below the LED
    fill(255); // Text color
    textFont(font);
    textAlign(CENTER);
    text(label, x, y + r + 15); // 15 is an arbitrary distance below the LED
  }
  
  boolean isClicked(float mx, float my) {
    float d = dist(mx, my, x, y);
    return d < r;
  }
  
  void changeColor() {
    if (this.state) {
      c = color(255, 165, 0); // Change to orange if the effect is on
    } else {
      c = color(155, 65, 0); // Change to dark red if the effect is off
    }
  }
  
  void changeState() {
    this.state = !this.state;
  }
}


class myButton {
  float x, y, w, h, q;
  color c;
  boolean state;
  String label;
  PFont font;
  
  myButton (float tempX, float tempY, float tempH, float tempW, float tempQ, boolean tempState, String tempLabel) {
    x = tempX;
    y = tempY;
    w = tempW;
    h = tempH;
    q = tempQ;
    
    font = createFont("Action_Man.ttf", 15);

    state = tempState;
    label = tempLabel;
    
    if (state) {
      c = color(255, 228, 181);
    } else {
      c = color(255, 228, 181, 95);
    }
  }
  
  void display() {
    fill(c);
    noStroke();
    rect(x, y, w, h, q);
  
    displayText(); // Call the method to display the text
  }
  
  // Method to display the text
  void displayText() {
    if(state){
      fill(0); // Set text color
    } else {
      fill(255);
    }
    textFont(font);
    textAlign(CENTER, CENTER); // Center the text in the button
    text(label, x + w/2, y + h/2); // Draw the text in the center of the button
  }
  
  boolean isClicked(float mx, float my) {
    return mx > x && mx < x + w && my > y && my < y + h;
  }
  
  void changeColor() {
    if (this.state) {
      c = color(255, 228, 181); // change color if selected
    } else {
      c = color(255, 228, 181, 95); 
    }
  }
  
  void changeState() {
    this.state = !this.state;
  }
}



// CONTROL--------------------------------------------------------------
void mousePressed() {
  OscMessage harmSelectedMsg = new OscMessage("/harmSelected");
  OscMessage harmSettingMsg = new OscMessage("/harmSetting");
  
  if (buttonHarmonizer.isClicked(mouseX, mouseY)) {
    
    if(buttonHarmonizer.state == false) {
      buttonHarmonizer.changeState();
      buttonHarmonizer.changeColor();
      buttonHarmocoder.changeState();
      buttonHarmocoder.changeColor();
    }
    
    // the automatic harmonizer is selected
      
    // tell SuperCollider that automatic harmonizer is selected
    harmSelectedMsg.add("harmonizer");
    oscP5.send(harmSelectedMsg, supercolliderAddress);
      
    // initialize automatic harmonizer in SuperCollider (using the last settings selected by the user)
    harmSettingMsg.add(majorMinor);
    harmSettingMsg.add(rootKey);
    oscP5.send(harmSettingMsg, supercolliderAddress);
      
    // unlock dropdown menu and toggle to set the harmonizer
    selectMajorMinor.setLock(false);
    dropdownKeyRoot.setLock(false); 
    isOpening = true;
    dropdownKeyRoot.open();
    selectMajorMinor.setColorBackground(color(138, 43, 226)); // Background color
    selectMajorMinor.setColorActive(color(255, 165, 0)); // Active color
    dropdownKeyRoot.setColorBackground(color(184, 183, 153));
    dropdownKeyRoot.getCaptionLabel().setColor(color(0)); // Caption text color (black)
    dropdownKeyRoot.setColorValue(0);
    
  } else if (buttonHarmocoder.isClicked(mouseX, mouseY)) {
    
    // the harmocoder is selected
    
    if(buttonHarmocoder.state == false) {
      buttonHarmonizer.changeState();
      buttonHarmonizer.changeColor();
      buttonHarmocoder.changeState();
      buttonHarmocoder.changeColor();
    }
    
    harmSelectedMsg.add("harmocoder"); // Add the string to the message
    oscP5.send(harmSelectedMsg, supercolliderAddress);
      
    // lock dropdown menu and toggle (harmocoder doesn't need settings)
    selectMajorMinor.setLock(true);
    dropdownKeyRoot.setLock(true);
    isClosing = true;
    selectMajorMinor.setColorBackground(color(138, 43, 226, 95)); // Background color
    selectMajorMinor.setColorActive(color(255, 165, 0, 95)); // Active color
    dropdownKeyRoot.setColorBackground(color(184, 183, 153, 95)); // Background color
    dropdownKeyRoot.getCaptionLabel().setColor(color(255)); // Text color
    dropdownKeyRoot.setColorValue(255);
  }
}


public void controlEvent(ControlEvent theEvent) {
  OscMessage harmSettingMsg = new OscMessage("/harmSetting");
  OscMessage sendMicToFxMsg = new OscMessage("/micSendToFx");
  OscMessage micHarmXfadeMsg = new OscMessage("/micHarmXfade");
  OscMessage micGainMsg = new OscMessage("/micGain");

  if (theEvent.isFrom(dropdownKeyRoot)) {
    // save the root key value selected with the dropdown menu
    println("Selected: " + theEvent.getController().getValue() + " (" + theEvent.getController().getLabel() + ")");
    rootKey = int(theEvent.getController().getValue());
    
    // send settings to SuperCollider with the root key updated
    harmSettingMsg.add(majorMinor);
    harmSettingMsg.add(rootKey);
    oscP5.send(harmSettingMsg, supercolliderAddress);
  }
  else if (theEvent.isFrom(selectMajorMinor)) {
    // save the majorMinor value selected with the toggle
    selectMajorMinorState = theEvent.getController().getValue() == 1;
    println("Toggle State: " + selectMajorMinorState);
    majorMinor = selectMajorMinorState ? "minor" : "major";
    selectMajorMinor.setLabel(majorMinor);
    println("majorminor selected: " + majorMinor);
    
    // send settings to SuperCollider with the majorMinor value updated
    harmSettingMsg.add(majorMinor);
    harmSettingMsg.add(rootKey);
    oscP5.send(harmSettingMsg, supercolliderAddress);

  } else if (theEvent.isFrom(sendMicToFx)) {
      sendMicToFxMsg.add(theEvent.getController().getValue());
      oscP5.send(sendMicToFxMsg, supercolliderAddress);
  } else if (theEvent.isFrom(micHarmXfade)) {
      micHarmXfadeMsg.add(theEvent.getController().getValue());
      oscP5.send(micHarmXfadeMsg, supercolliderAddress);
  } else if (theEvent.isFrom(micGain)) {
      micGainMsg.add(theEvent.getController().getValue());
      oscP5.send(micGainMsg, supercolliderAddress);
  }
}

void oscEvent(OscMessage msg) {
  if (msg.checkAddrPattern("/reverbValueMsg")) { // Check if the message has the topic "/sliderMsg"
      // println("Slider Value: " + msg.get(0).floatValue()); // Print the slider value
      reverbLevel.setValue(msg.get(0).floatValue()*100);
  } else if (msg.checkAddrPattern("/accYValueMsg")) {
      if(intToBoolean(msg.get(0).intValue()) != ledDistortion.state) {
        ledDistortion.changeState();
        ledDistortion.changeColor();  
      }
  } else if (msg.checkAddrPattern("/accZValueMsg")) {
      if(intToBoolean(msg.get(0).intValue()) != ledChorus.state) {
        ledChorus.changeState();
        ledChorus.changeColor();
      }
  }
  
}

// UTILITIES ---------------------------------------------------------------------------
boolean intToBoolean(int value) {
  return value != 0;
}
