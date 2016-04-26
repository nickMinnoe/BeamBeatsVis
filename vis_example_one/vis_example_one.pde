// needed for handling midi datas
import themidibus.*; //Import the library
import javax.sound.midi.MidiMessage; 

// used for sending data to server
import java.net.URI;
import java.net.URISyntaxException;
// only needed for the java stuff I think?
import org.java_websocket.drafts.Draft_10;

import org.java_websocket.WebSocketImpl;
import org.java_websocket.client.WebSocketClient;
import org.java_websocket.handshake.ServerHandshake;

// convert to base64?
import javax.xml.bind.DatatypeConverter;

MidiBus myBus; 
private WebSocketClient cc;
String defaultLoc = "ws://localhost:8887";

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
  noStroke();
  setupCC();
  cc.connect();
}

void draw() {
  background(backColor);
  
  for(int i =0; i<allMidi.size(); i++){
    
    int[] cur = allMidi.get(i);
    float a = cur[3] * .012;
    int x = floor(width/2 + ((20*(cur[1] + 1)+50) * cos(radians(a))));
    int y = floor(height/2 + ((20*(cur[1] + 1)+50) * sin(radians(a))));
    int duration = floor(sqrt((cur[8])/25));
    pushMatrix();
    translate(x, y);
    rotate(radians(a));
    fill(color(cur[4], cur[5], cur[6], cur[7]));
    rect(0, 0, 10+(duration), 10+(duration));
    fill(color(cur[4], cur[5], cur[6], cur[7]*.5));
    rect(-15, 0, 5+(duration), 5+(duration));
    rect(15, 0, 5+(duration), 5+(duration));
    popMatrix();
  }
  
  for(int i =0; i<playing.size(); i++){
    
    int[] cur = playing.get(i);
    // chance color based on octave
    fill(color(cur[4], cur[5], cur[6], cur[7]));
    //used for size calculation
    int duration = floor(sqrt((millis() - cur[3])/25));
    // calculate angle around circle
    float a = cur[3] * .012;
    int x = floor(width/2 + ((10*(cur[1] + 1)+50) * cos(radians(a))));
    int y = floor(height/2 + ((10*(cur[1] + 1)+50) * sin(radians(a))));
    // transformations done to accurately rotate squares
    pushMatrix();
    translate(x, y);
    rotate(radians(a));
    rect(-15, 0, 5+(duration), 5+(duration));
    rect(0, 0, 10+(duration), 10+(duration));
    rect(15, 0, 5+(duration), 5+(duration));
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
  int alpha = 100 - note*7;
  if(octave==2) {
   hue = 160;
   saturation = 100;
   brightness = 100;
  } else if(octave==3) {
    hue = 40;
    saturation = 91;
    brightness = 99;
  } else if(octave==4) {
    hue = 190;
    saturation = 100;
    brightness = 83;
  } else if(octave==5) {
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

void setupCC(){
 try{ 
   cc = new WebSocketClient( new URI( defaultLoc ), new Draft_10() ) {

          @Override
          public void onMessage( String message ) {
            println( "got: " + message + "\n" );
          }

          @Override
          public void onOpen( ServerHandshake handshake ) {
            println( "You are connected to ChatServer: " + getURI() + "\n" );
          }

          @Override
          public void onClose( int code, String reason, boolean remote ) {
            println( "You have been disconnected from: " + getURI() + "; Code: " + code + " " + reason + "\n" );
          }

          @Override
          public void onError( Exception ex ) {
            println( "Exception occured ...\n" + ex + "\n" );
            ex.printStackTrace();
          }
        }; 
 } catch( URISyntaxException ex){
  println( defaultLoc+" is not a valid Web Adress");
 }
}

// make sure I have it
void mouseClicked(){
  // temporary save for testing stuffs?
  String file_name = "circle.png";
  save(file_name);
  delay(1000);
 
  byte[] imageBytes = loadBytes(file_name);
  String thisIsBase = DatatypeConverter.printBase64Binary(imageBytes);
  print("THis is working");
  
  cc.send(thisIsBase);

}