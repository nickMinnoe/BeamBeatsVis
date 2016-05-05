// needed for handling midi datas
import themidibus.*; //Import the library
import javax.sound.midi.MidiMessage; 

// DELETE THIS SHIT (and the file in code) put this in instead ServToClient
// import processing.net.*;
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

// changed to:  Client cc
private WebSocketClient cc;
// uri to connect to
String defaultLoc = "ws://localhost:8887";

int backColor = 0;
int midiDevice  = 0;
int fCounter;

// lists of stuff
ArrayList<int[]> playing;
ArrayList<int[]> allMidi;
ArrayList<int[]> redMidi;
ArrayList<int[]> yelMidi;
ArrayList<int[]> bluMidi;
ArrayList<int[]> purMidi;

// drawing vars
float dis;
boolean show;
int difT;
float finalPos;
float a;
float angleInc = .006;
int velPivot = 85;

// all for timing and saving/sending data to server
int start;
int playLength = 60000;
int interval = 2500;
boolean saveA = true;
boolean saveR = true;
boolean saveY = true;
boolean saveB = true;
boolean saveP = true;
PGraphics tempG;

void setup() {
  fullScreen();
  MidiBus.list();
  start = millis();
  myBus = new MidiBus(this, midiDevice, 1);
  playing = new ArrayList<int[]>();
  allMidi = new ArrayList<int[]>();
  redMidi = new ArrayList<int[]>();
  yelMidi = new ArrayList<int[]>();
  bluMidi = new ArrayList<int[]>();
  purMidi = new ArrayList<int[]>();
  colorMode(HSB, 360, 100, 100, 100);
  rectMode(CENTER);
  noStroke();
  // DELETE THIS SHIT
  // will be switched for this: cc = new Client(this, "hostname", "port");
  setupCC();
  cc.connect();
  // end shit to delete
  tempG = createGraphics(width, height, JAVA2D);
  tempG.noStroke();
  fCounter = 0;
}

void draw() {

  background(backColor);

  // -----   End show conditions
  if(millis() - start >= playLength+(interval*5)){
    //reset the system
    allMidi.clear();
    redMidi.clear();
    bluMidi.clear();
    purMidi.clear();
    yelMidi.clear();
    playing.clear();
    start = millis();
    saveA = true;
    saveY = true;
    saveB = true;
    saveP = true;
    saveR = true;
    
  String fileName = sketchPath("all.png");
  File file = sketchFile(fileName);
  String fileNameR = sketchPath("red.png");
  File fileR = sketchFile(fileNameR);
  String fileNameY = sketchPath("yel.png");
  File fileY = sketchFile(fileNameY);
  String fileNameB = sketchPath("blu.png");
  File fileB = sketchFile(fileNameB);
  String fileNameP = sketchPath("pur.png");
  File fileP = sketchFile(fileNameP);
  System.gc(); // the key to succes
  file.delete();
  fileR.delete();
  fileB.delete();
  fileY.delete();
  fileP.delete();
  } else if(millis() - start >= playLength+(interval*4)) {
    //save purple
    
    regDraw(purMidi);
    if (saveP) {
      saveP = false;
      saveNSend("pur");
    }
    
    //saveP = true;
  } else if (millis() - start >= playLength+(interval*3)) {
    // save red
    
    regDraw(redMidi);
    if (saveR) {
      saveR = false;
      saveNSend("red");
    }
  } else if (millis() - start >= playLength+(interval*2)) {
    // save yellow 
    
    regDraw(yelMidi);
    if (saveY) {
      saveY = false;
      saveNSend("yel");
    }
  } else if (millis() - start >= playLength+interval) {
    // save blue 
    
    regDraw(bluMidi);
    if (saveB) {
      saveB = false;
      saveNSend("blu");
    }
  } else if (millis() - start >= playLength) {
    // save all midi 
    
    regDraw(allMidi);
    if (saveA) {
      saveA = false;
      saveNSend("all");
    }
  } else {
    // normal playing

  for (int i =0; i<allMidi.size(); i++) {

    int[] cur = allMidi.get(i);
    a = cur[4] * angleInc;
    finalPos = 25*(cur[1] + 1)+65;
    difT = millis() - cur[4];

    if (difT >= 500) {
      dis = finalPos;
      show = true;
    } else {
      dis = (float)(finalPos*Math.cbrt(difT/500.0));
      show = false;
    }
    int x = floor(width/2 + (dis * cos(radians(a))));
    int y = floor(height/2 + (dis * sin(radians(a))));
    int duration = floor(sqrt((cur[9])/25));
    pushMatrix();
    translate(x, y);
    rotate(radians(a));
    fill(color(cur[5], cur[6], cur[7], cur[8]));
    rect(0, 0, 12+(duration), 12+(duration));
    if (show) {
      if (cur[3] <= velPivot) {
        // show little squares on sides
        fill(color(cur[5], cur[6], cur[7], cur[8]*.5));
        rect(-25, 0, 7+(duration), 7+(duration));
        rect(25, 0, 7+(duration), 7+(duration));
      } else {
        // show little burst squares
        fill(color(cur[5], cur[6], cur[7], cur[8]*.5));
        difT = millis() - (cur[4]+500);
        if (difT >= 150) {
          dis = 75;
          show = true;
        } else {
          dis = (float)(65*Math.cbrt(difT/250.0));
          show = false;
        }
        for (int c=0; c<3; c++) {
          int la = -60+(c*60);
          int lx = floor((dis * cos(radians(la))));
          int ly = floor((dis * sin(radians(la))));
          pushMatrix();
          translate(lx, ly);
          rotate(radians(la));
          rect(0, 0, 5, 5);
          popMatrix();
        }
      }// end little burst sq
    } // end show
    popMatrix();
  }

  for (int i =0; i<playing.size(); i++) {

    int[] cur = playing.get(i);
    //used for size calculation
    finalPos = 25*(cur[1] + 1)+65;
    difT = millis() - cur[4];
    int duration = floor(sqrt((difT)/25));
    if (difT >= 500) {
      dis = finalPos;
      show = true;
    } else {
      dis = (float)(finalPos*Math.cbrt(difT/500.0));
      show = false;
    }

    // calculate angle around circle
    a = cur[4] * angleInc;
    int x = floor(width/2 + (dis * cos(radians(a))));
    int y = floor(height/2 + (dis * sin(radians(a))));
    // transformations done to accurately rotate squares
    pushMatrix();
    translate(x, y);
    rotate(radians(a));
    fill(color(cur[5], cur[6], cur[7], cur[8]));
    rect(0, 0, 12+(duration), 12+(duration));
    if (show) {
      if (cur[3] <= velPivot) {
        // show little squares on sides
        fill(color(cur[5], cur[6], cur[7], cur[8]*.5));
        rect(-25, 0, 7+(duration), 7+(duration));
        rect(25, 0, 7+(duration), 7+(duration));
      } else {
        // show little burst squares
        fill(color(cur[5], cur[6], cur[7], cur[8]*.5));
        difT = millis() - (cur[4]+500);
        if (difT >= 150) {
          dis = 75;
          show = true;
        } else {
          dis = (float)(65*Math.cbrt(difT/250.0));
          show = false;
        }
        for (int c=0; c<3; c++) {
          int la = -60+(c*60);
          int lx = floor((dis * cos(radians(la))));
          int ly = floor((dis * sin(radians(la))));
          pushMatrix();
          translate(lx, ly);
          rotate(radians(la));
          rect(0, 0, 5, 5);
          popMatrix();
        }
      }// end little burst sq
    } //
    popMatrix();
  }
  }
}

// TheMididBus method, triggers when noteOn recieved
// add to playing array and parse data
void noteOn(int channel, int noteNum, int vel) { 
  if(millis() - start <= playLength){
  int octave = (noteNum/12) -1;
  int note = noteNum%12;
  int tplayed = millis();
  println("Note num "+ noteNum + "; Octave " + octave + ", channel " + channel+", vel "+vel);
  int hue = 0;
  int saturation = 0;
  int brightness = 0;
  int alpha = 100 - note*7;
  // CHANNEL CHANGE switch comparisons
  if (channel==0) {
    hue = 307;
    saturation = 76;
    brightness = 60;
  } else if (channel==1) {
    hue = 352;
    saturation = 83;
    brightness = 92;
  } else if (channel==2) {
    hue = 190;
    saturation = 100;
    brightness = 83;
  } else if (channel==3) {
    hue = 40;
    saturation = 91;
    brightness = 98;
  }
  // CHANNEL CHANGE - switch octave/channel in array
  int[] temp = {channel, note, octave, vel, tplayed, hue, saturation, brightness, alpha};
  playing.add(temp);
}
}

// TheMididBus method, triggers when noteOn recieved
// remove from beingplayed array, add to allMidi array
void noteOff(int channel, int noteNum, int vel) {
  int octave = (noteNum/12) -1;
  int note = noteNum%12;
  //CHANNEL CHANGE - switch octave/channel in array
  int[] temp = {channel, note, octave};
  for (int i=0; i<playing.size(); i++) {
    int[] cur = playing.get(i);
    if (temp[0] == cur[0] && temp[1] == cur[1] && temp[2] == cur[2]) {
      int dur = millis() - cur[4];
      int[] finished = append(cur, dur);
      allMidi.add(finished);
      playing.remove(i);
      
      if(cur[0]==2){
        redMidi.add(finished);
      }else if(cur[0]==3){
        bluMidi.add(finished);
      }else if(cur[0]==4){
        yelMidi.add(finished);
      }else if(cur[0]==5){
        purMidi.add(finished);
      }
    }
  }
}

//bend goes from -1.0 to 1.0
void channelBend(int channel, float bend)
{
  println("Pitch " + bend);
}

void midiMessage(MidiMessage message) { // You can also use midiMessage(MidiMessage message, long timestamp, String bus_name)
  //check if it's a pitch bend message
  if(message.getStatus() >> 4 == 14)
  {
    int channel = message.getStatus() & 0x0F;
    int value = message.getMessage()[1] & 0xFF; //7 LSB
    value = value | (message.getMessage()[2] << 7); //7 MSB
    float bend = map(value, 0, 16384, -1, 1); //magic maximum numbers from MIDI spec
    
    //only report bends of significance
    if(abs(bend) > 0.005)
    {
      channelBend(channel, bend);
    }
  }
}


// DELETE THIS SHIT replace with nothing
void setupCC() {
  try { 
    cc = new WebSocketClient( new URI( defaultLoc ), new Draft_10() ) {

      @Override
        public void onMessage( String message ) {
        println( "got: stuff" );
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
  } 
  catch( URISyntaxException ex) {
    println( defaultLoc+" is not a valid Web Adress");
  }
}

// replacing mouseClicked
void saveNSend(String imgName) {
  //change this line to save from a passed in object
  tempG.save(imgName+".png");
  delay(1000);

  byte[] imageBytes = loadBytes(imgName+".png");
  String thisIsBase = DatatypeConverter.printBase64Binary(imageBytes);

  // DELETE THIS SHIT
  // replace with: cc.write(thisIsBase);
  
  // commenting out for testing
  //cc.send(thisIsBase);
}

void regDraw(ArrayList<int[]> looper){
 tempG.beginDraw();
    tempG.clear();

    for (int i =0; i<looper.size(); i++) {

      int[] cur = looper.get(i);
      a = cur[4] * angleInc;
      finalPos = 25*(cur[1] + 1)+65;
      dis = finalPos;
      int x = floor(width/2 + (dis * cos(radians(a))));
      int y = floor(height/2 + (dis * sin(radians(a))));
      int duration = floor(sqrt((cur[9])/25));
      tempG.pushMatrix();
      tempG.translate(x, y);
      tempG.rotate(radians(a));
      tempG.fill(color(cur[5], cur[6], cur[7], cur[8]));
      tempG.rect(0, 0, 12+(duration), 12+(duration));
        if (cur[3] <= velPivot) {
          // show little squares on sides
          tempG.fill(color(cur[5], cur[6], cur[7], cur[8]*.5));
          tempG.rect(-25, 0, 7+(duration), 7+(duration));
          tempG.rect(25, 0, 7+(duration), 7+(duration));
        } else {
          // show little burst squares
          tempG.fill(color(cur[5], cur[6], cur[7], cur[8]*.5));
          dis = 75;
          for (int c=0; c<3; c++) {
            int la = -60+(c*60);
            int lx = floor((dis * cos(radians(la))));
            int ly = floor((dis * sin(radians(la))));
            tempG.pushMatrix();
            tempG.translate(lx, ly);
            tempG.rotate(radians(la));
            tempG.rect(0, 0, 5, 5);
            tempG.popMatrix();
          }
        }// end little burst sq
        tempG.popMatrix();
      } // end show
      
    tempG.endDraw();
    
    image(tempG, 0, 0);
}