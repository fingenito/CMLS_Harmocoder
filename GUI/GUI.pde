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
Toggle selectHarm;
DropdownList dropdownKeyRoot;
Toggle selectMajorMinor;
Slider voiceLevel;
Slider reverbLevel;
Toggle switchChorus;
Toggle switchDistortion;


// global variables to set the automatic harmonizer
String majorMinor = "major";
int rootKey = 0;

// global states of toggles
boolean selectHarmState = true;
boolean selectMajorMinorState = true;

void setup() {
  size(700, 700);
  
  cp5 = new ControlP5(this);
  
  oscP5 = new OscP5(this, 12000); // Porta locale per Processing
  supercolliderAddress = new NetAddress("127.0.0.1", 57120);
  
  // Crea un nuovo font con la dimensione desiderata
  subtitle = createFont("Arial", 13); // Sostituisci "Arial" con il font desiderato e 30 con la dimensione desiderata
  
  // Crea un toggle per switchare tra harmonizer automatico e harmonizer con midi
  selectHarm = cp5.addToggle("selectHarm")
     .setPosition(50, 50)
     .setSize(140, 70)
     .setValue(false)
     .setMode(ControlP5.SWITCH)
     .setLabel("Harmocoder/Harmonizer")
     .setFont(subtitle);
     
  // Crea un DropdownList per la chiave
  dropdownKeyRoot = cp5.addDropdownList("Select Key Root")
                .setPosition(250, 50)
                .setSize(200, 150) // Larghezza e altezza
                .setItemHeight(30) // Altezza di ogni voce
                .setBarHeight(30) // Altezza della barra principale
                .setColorBackground(color(50)) // Colore dello sfondo
                .setColorActive(color(255, 128, 0)) // Colore dello sfondo attivo
                .setColorForeground(color(100))
                .setLock(true); // di default è selezionato l'harmocoder (non può essere cliccato)

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
     .setPosition(500, 50)
     .setSize(140, 70)
     .setValue(false)
     .setMode(ControlP5.SWITCH)
     .setLabel("Major/Minor")
     .setFont(subtitle)
     .setLock(true); // di default è selezionato l'harmocoder (non può essere cliccato)
    
  
  voiceLevel = cp5.addSlider("voiceLevel")
     .setPosition(50, 300)
     .setSize(500, 40)
     .setRange(0, 1)
     .setLabel("Voice level")
     .setValue(0.5);
  

  // Crea uno slider
  reverbLevel = cp5.addSlider("reverbLevel")
     .setPosition(50, 350)
     .setSize(500, 40)
     .setRange(0, 100)
     .setValue(50)
     .setLabel("Reverb level")
     .setLock(true);
     
  
  switchChorus = cp5.addToggle("switchChorus")
     .setPosition(50, 400)
     .setSize(140, 70)
     .setValue(false)
     .setMode(ControlP5.SWITCH)
     .setLabel("Chorus OFF/ON")
     .setFont(subtitle)
     .setLock(true);
     
  switchDistortion = cp5.addToggle("switchDistortion")
     .setPosition(50, 500)
     .setSize(140, 70)
     .setValue(false)
     .setMode(ControlP5.SWITCH)
     .setLabel("Distortion OFF/ON")
     .setFont(subtitle)
     .setLock(true);
  
     
  

  
  
  
  // tell to supercollider that by default the first time is selected the harmocoder
  OscMessage harmSelectedMsg = new OscMessage("/harmSelected");
  String msg = "harmocoder";
  harmSelectedMsg.add(msg);
  oscP5.send(harmSelectedMsg, supercolliderAddress);
  
  // to do... set the defaul value of voice volume
  //OscMessage harmSettingMsg = new OscMessage("/harmSetting");
  //harmSettingMsg.add(majorMinor);
  //harmSettingMsg.add(rootKey);
  //oscP5.send(harmSettingMsg, supercolliderAddress);


}

void draw() {
  background(200);
}

public void controlEvent(ControlEvent theEvent) {
  OscMessage harmSelectedMsg = new OscMessage("/harmSelected");
  OscMessage harmSettingMsg = new OscMessage("/harmSetting");
  OscMessage voiceLevelMsg = new OscMessage("/voiceLevel");

  
  if (theEvent.isFrom(selectHarm)) 
  {
    selectHarmState = theEvent.getController().getValue() == 1;
    println("Toggle State: " + selectHarmState);
    if(selectHarmState){
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
    } else {
      // the harmocoder is selected
      harmSelectedMsg.add("harmocoder"); // Add the string to the message
      oscP5.send(harmSelectedMsg, supercolliderAddress);
      
      // lock dropdown menu and toggle (harmocoder doesn't need settings)
      selectMajorMinor.setLock(true);
      dropdownKeyRoot.setLock(true);
    }
      
  }
  else if (theEvent.isFrom(dropdownKeyRoot)) {
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
    println("majorminor selected: " + majorMinor);
    
    // send settings to supercollider with the majorMinor value updated
    harmSettingMsg.add(majorMinor);
    harmSettingMsg.add(rootKey);
    oscP5.send(harmSettingMsg, supercolliderAddress);

  } else if (theEvent.isFrom(voiceLevel)) {
      voiceLevelMsg.add(theEvent.getController().getValue());
      oscP5.send(voiceLevelMsg, supercolliderAddress);
  }
}

void oscEvent(OscMessage msg) {
  if (msg.checkAddrPattern("/reverbValueMsg")) { // Controlla se il messaggio ha il topic "/sliderMsg"
      //println("Slider Value: " + msg.get(0).floatValue()); // Stampa il valore dello slider
      reverbLevel.setValue(msg.get(0).floatValue()*100); 
  } else if (msg.checkAddrPattern("/accYValueMsg")) {
      // println(msg.get(0).intValue());
      switchDistortion.setValue(msg.get(0).intValue() == 1);
  } else if (msg.checkAddrPattern("/accZValueMsg")) {
      //println(msg.get(0).intValue());
      switchChorus.setValue(msg.get(0).intValue() == 1);

  }
  
}
