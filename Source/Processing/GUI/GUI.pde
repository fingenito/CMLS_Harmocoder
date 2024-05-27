import controlP5.*;
import oscP5.*;
import netP5.*;

// global variables to sending msgs to supercollider
OscP5 oscP5;
NetAddress supercolliderAddress;
ControlP5 cp5;




// font for small text
PFont subtitle;

// global variables for gui elements
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
  
  oscP5 = new OscP5(this, 12000); // Porta locale per Processing
  supercolliderAddress = new NetAddress("127.0.0.1", 57120);
  
  // Crea un nuovo font con la dimensione desiderata
  subtitle = createFont("Action_Man.ttf", 13); // Sostituisci "Arial" con il font desiderato e 30 con la dimensione desiderata
  
  
  // Inserisci le scritte
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
 
  // bottoni per switchare tra harmonizer automatico e harmonizer con midi
  buttonHarmonizer = new myButton(220, 70, 70, 110, 10, false, "Harmonizer");
  buttonHarmocoder = new myButton(40, 70, 70, 110, 10, true, "Harmocoder");
     
  // Crea un DropdownList per la chiave
  dropdownKeyRoot = cp5.addDropdownList("Select Key Root")
                .setPosition(365, 70)
                .setSize(200, barHeight) // Larghezza e altezza
                .setItemHeight(30) // Altezza di ogni voce
                .setBarHeight(barHeight) // Altezza della barra principale
                .setColorBackground(color(184, 183, 153, 95)) // Colore dello sfondo
                .setColorActive(color(178, 127, 135)) // Colore dello sfondo attivo
                .setColorForeground(color(255, 182, 193))
                .setLock(true) // di default è selezionato l'harmocoder (non può essere cliccato)
                .setFont(subtitle)
                .setColorValue(255);
  dropdownKeyRoot.getCaptionLabel().setColor(color(255)); // Colore del testo del titolo (bianco)
  


  // Aggiungi voci al DropdownList con i nomi delle note musicali
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
  
  // Crea un toggle per slezionare armonizzazione major o minor (per harm auto)
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
     .setColorBackground(color(205, 92, 92))   // Colore di sfondo dello slider
     //.setColorActive(color(255, 240, 220))  // Colore quando lo slider è attivo (cliccato)
     .setColorValueLabel(color(255, 255, 255))  // Colore del valore mostrato
     .setColorCaptionLabel(color(255, 255, 255)); // Colore dell'etichetta
     
  
  ledChorus = new Led(265, 475, 30, false, "CHORUS"); // inizializza il led con un colore rosso
  ledDistortion = new Led(265, 625, 30, false, "DISTORTION"); // inizializza il led con un colore rosso

  
  
  
  
  
  // tell to supercollider that by default the first time is selected the harmocoder
  OscMessage harmSelectedMsg = new OscMessage("/harmSelected");
  String msg = "harmocoder";
  harmSelectedMsg.add(msg);
  oscP5.send(harmSelectedMsg, supercolliderAddress);
  
  // tell to supercollider the defaul value of input sliders
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
  
  // rettangolo in alto dx
  rect(190, 20, 585, 250, 30);
  
  stroke(color(134, 239, 190));
  // rettangolo in basso sx
  rect(20, 320, 330, 460, 30);
  
  stroke(color(130, 191, 144));
  //rettangolo basso dx
  rect(430, 320, 340, 460, 30);
  
  stroke(color(154, 191, 132));
  // rettangolo alto sx
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
      dropdownKeyRoot.close(); // Chiusura effettiva
    }
  }
  
  cp5.draw();

}



// CLASSES ---------------------------------------------------------------------------
class Led {
  float x, y, r;
  color c;
  boolean state;
  String label; // Aggiungi attributo per la label
  PFont font;
  
  Led(float tempX, float tempY, float tempR, boolean tempState, String tempLabel) {
    x = tempX;
    y = tempY;
    r = tempR;
    state = tempState;
    font = createFont("Action_Man.ttf", 15);
    label = tempLabel; // Inizializza la label
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
    
    // Disegna la label sotto il LED
    fill(255); // Colore del testo
    textFont(font);
    textAlign(CENTER);
    text(label, x, y + r + 15); // 15 è una distanza arbitraria sotto il LED
  }
  
  boolean isClicked(float mx, float my) {
    float d = dist(mx, my, x, y);
    return d < r;
  }
  
  void changeColor() {
    if (this.state) {
      c = color(255, 165, 0); // Cambia a verde se l'effetto è acceso
    } else {
      c = color(155, 65, 0); // Cambia a rosso se l'effetto è spento
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
  
    displayText(); // Chiama il metodo per visualizzare il testo
  }
  
  // Metodo per visualizzare il testo
  void displayText() {
    
    if(state){
      fill(0); // Imposta il colore del testo
    } else {
      fill(255);
    }
    textFont(font);
    textAlign(CENTER, CENTER); // Allinea il testo al centro del pulsante
    text(label, x + w/2, y + h/2); // Disegna il testo al centro del pulsante
  }
  
  boolean isClicked(float mx, float my) {
    return mx > x && mx < x + w && my > y && my < y + h;
  }
  
  void changeColor() {
    if (this.state) {
      c = color(255, 228, 181); // change color if is selected
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
      
    // tell to supercollider that automatic harmonizer is selected
    harmSelectedMsg.add("harmonizer");
    oscP5.send(harmSelectedMsg, supercolliderAddress);
      
    // initialize automatic harmonizer in supercollider (using the last settings selected by the user)
    harmSettingMsg.add(majorMinor);
    harmSettingMsg.add(rootKey);
    oscP5.send(harmSettingMsg, supercolliderAddress);
      
    // unlock dropdown menu and toggle to set the harmonizer
    selectMajorMinor.setLock(false);
    dropdownKeyRoot.setLock(false); 
    isOpening = true;
    dropdownKeyRoot.open();
    selectMajorMinor.setColorBackground(color(138, 43, 226)); // Colore di sfondo
    selectMajorMinor.setColorActive(color(255, 165, 0)); // Colore quando attivato
    dropdownKeyRoot.setColorBackground(color(184, 183, 153));
    dropdownKeyRoot.getCaptionLabel().setColor(color(0)); // Colore del testo del titolo (bianco)
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
    selectMajorMinor.setColorBackground(color(138, 43, 226, 95)); // Colore di sfondo
    selectMajorMinor.setColorActive(color(255, 165, 0, 95)); // Colore quando attivato
    dropdownKeyRoot.setColorBackground(color(184, 183, 153, 95)); // Colore dello sfondo
    dropdownKeyRoot.getCaptionLabel().setColor(color(255));
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
    println("Selezionato: " + theEvent.getController().getValue() + " (" + theEvent.getController().getLabel() + ")");
    rootKey = int(theEvent.getController().getValue());
    
    // send settings to supercollider with the rootkey updated
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
    
    // send settings to supercollider with the majorMinor value updated
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
  if (msg.checkAddrPattern("/reverbValueMsg")) { // Controlla se il messaggio ha il topic "/sliderMsg"
      //println("Slider Value: " + msg.get(0).floatValue()); // Stampa il valore dello slider
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
