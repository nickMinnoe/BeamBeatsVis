// SimpleMidi.pde

// Add in duration tracking
// Octave and note distinction

import themidibus.*; //Import the library
import javax.sound.midi.MidiMessage; 

MidiBus myBus; 

int backColor = 0;
int midiDevice  = 0;
ArrayList<int[]> playing;
ArrayList<int[]> allMidi;
int start;

void setup() {
  size(960, 640);
  MidiBus.list();
  start = millis();
  myBus = new MidiBus(this, midiDevice, 1);
  playing = new ArrayList<int[]>();
  allMidi = new ArrayList<int[]>();
  colorMode(HSB, 360, 100, 100, 100);
  rectMode(CENTER);
}

void draw() {
  background(backColor);
  
  for(int i =0; i<allMidi.size(); i++){
    
    int[] cur = allMidi.get(i);
    fill(color(cur[4], cur[5], cur[6], cur[7]));
    float a = cur[3] * .002;
    int x = floor(width/2 + ((10*(cur[1] + 1)+50) * cos(radians(a))));
    int y = floor(height/2 + ((10*(cur[1] + 1)+50) * sin(radians(a))));
    int duration = floor(sqrt((cur[8])/25));
    pushMatrix();
    translate(x, y);
    rotate(radians(a));
    rect(0, 0, 10+(duration), 10+(duration));
    popMatrix();
  }
  
  for(int i =0; i<playing.size(); i++){
    
    int[] cur = playing.get(i);
    // chance color based on octave
    fill(color(cur[4], cur[5], cur[6], cur[7]));
    //used for size calculation
    int duration = floor(sqrt((millis() - cur[3])/25));
    // calculate angle around circle
    float a = cur[3] * .002;
    int x = floor(width/2 + ((10*(cur[1] + 1)+50) * cos(radians(a))));
    int y = floor(height/2 + ((10*(cur[1] + 1)+50) * sin(radians(a))));
    // transformations done to accurately rotate squares
    pushMatrix();
    translate(x, y);
    rotate(radians(a));
    rect(0, 0, 10+duration, 10+duration);
    //return to normal grid
    popMatrix();
  }
  
  
}

// TheMididBus method, triggers when noteOn recieved
// add to playing array and parse data
void noteOn(int channel, int noteNum, int vel) { 
  int octave = (noteNum/12) -1;
  int note = noteNum%12;
  int tplayed = millis();
  println("Note num "+ noteNum + "; Octave " + octave + ", channel " + channel);
  int hue = 0;
  int saturation = 0;
  int brightness = 0;
  int alpha = 100;
  if(octave==0 && channel==0) {
   hue = 160;
   saturation = 100;
   brightness = 100;
  } else if(octave==3 && channel==0) {
    hue = 40;
    saturation = 91;
    brightness = 99;
  } else if(octave==4 && channel==0) {
    hue = 190;
    saturation = 100;
    brightness = 83;
  } else if(octave==5 && channel==0) {
    hue = 307;
    saturation = 76;
    brightness = 61;
  }
  
  int[] temp = {octave, note, channel, tplayed, hue, saturation, brightness, alpha};
  playing.add(temp);
  // myBus.sendNoteOn(channel, noteNum, vel);
  // sending the note to output device
  }

// TheMididBus method, triggers when noteOn recieved
// remove from beingplayed array, add to allMidi array
void noteOff(int channel, int noteNum, int vel){
  int octave = (noteNum/12) -1;
  int note = noteNum%12;
  
  int[] temp = {octave, note, channel};
  for(int i=0; i<playing.size(); i++){
    int[] cur = playing.get(i);
    if(temp[0] == cur[0] && temp[1] == cur[1] && temp[2] == cur[2]){
      int dur = millis() - cur[3];
      int[] finished = append(cur, dur);
      allMidi.add(finished);
      playing.remove(i);
    }
  }
}
// placeholder to print allMidi instead of sending it
// make sure I have it
void mouseClicked(){
  for(int i=0; i<allMidi.size(); i++){
    print(i + "\n");
    printArray(allMidi.get(i));
    // temporary save for testing stuffs?
    save("diagonal.tif");
  }
  //print(allMidi);
}