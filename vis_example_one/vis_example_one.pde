// SimpleMidi.pde

// Add in duration tracking
// Octave and note distinction

import themidibus.*; //Import the library
import javax.sound.midi.MidiMessage; 

MidiBus myBus; 

int currentColor = 0;
int midiDevice  = 0;
ArrayList<int[]> playing;
ArrayList<int[]> allMidi;
int start;

void setup() {
  size(480, 320);
  MidiBus.list();
  start = millis();
  myBus = new MidiBus(this, midiDevice, 4);
  playing = new ArrayList<int[]>();
  allMidi = new ArrayList<int[]>();
  colorMode(HSB);
  rectMode(CENTER);
}

void draw() {
  background(currentColor);
  
  for(int i =0; i<playing.size(); i++){
    
    int[] current = playing.get(i);
    // chance color based on octave
    fill(color((current[0]-2)*100, 255, 255));
    //used for size calculation
    int duration = (millis() - current[3])/100;
    // calculate angle around circle
    float a = current[3] * .002;
    int x = floor(240 + ((10*(current[1] + 1)+50) * cos(radians(a))));
    int y = floor(160 + ((10*(current[1] + 1)+50) * sin(radians(a))));
    // transformations done to accurately rotate squares
    pushMatrix();
    translate(x, y);
    rotate(radians(a));
    rect(0, 0, 5+duration, 5+duration);
    //return to normal grid
    popMatrix();
  }
  
  for(int i =0; i<allMidi.size(); i++){
    
    int[] current = allMidi.get(i);
    fill(color((current[0]-2)*100, 255, 255));
    float a = current[3] * .002;
    int x = floor(240 + ((10*(current[1] + 1)+50) * cos(radians(a))));
    int y = floor(160 + ((10*(current[1] + 1)+50) * sin(radians(a))));
    pushMatrix();
    translate(x, y);
    rotate(radians(a));
    rect(0, 0, 5+(current[4]/100), 5+(current[4]/100));
    popMatrix();
  }
}

// TheMididBus method, triggers when noteOn recieved
// add to playing array and parse data
void noteOn(int channel, int noteNum, int vel) { 
  int octave = (noteNum/12) -1;
  int note = noteNum%12;
  int tplayed = millis();
  println("Note num "+ noteNum + "; Note " + note + ", vel " + vel);
  
   int[] temp = {octave, note, channel, tplayed};
   playing.add(temp);
  }

// TheMididBus method, triggers when noteOn recieved
// remove from beingplayed array, add to allMidi array
void noteOff(int channel, int noteNum, int vel){
  int octave = (noteNum/12) -1;
  int note = noteNum%12;
  
  int[] temp = {octave, note, channel};
  for(int i=0; i<playing.size(); i++){
    int[] current = playing.get(i);
    if(temp[0] == current[0] && temp[1] == current[1] && temp[2] == current[2]){
      int dur = millis() - current[3];
      int[] finished = append(current, dur);
      allMidi.add(finished);
      playing.remove(i);
    }
  }
}
// placeholder to print allMidi
void mouseClicked(){
  for(int i=0; i<allMidi.size(); i++){
    print(i + "\n");
    printArray(allMidi.get(i));
  }
  //print(allMidi);
}