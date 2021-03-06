// needed for handling midi datas
import themidibus.*;
import javax.sound.midi.MidiMessage; 
// required to send post request to server
import http.requests.*;
// convert to base64
import javax.xml.bind.DatatypeConverter;

MidiBus myBus; 

// ******** Variables to configure ********
String defaultLoc = "http://beambeats.cias.rit.edu/visualization/acceptVis.php";
int midiDevice  = 0; // index of the midi input device
float angleInc = .006; // 360/playLength - for calculating position around circle
// do you want to do something different for slow notes? This is a threshhold
int velPivot = 0;
int playLength = 60000; // play time in milliseconds
// ------ end -------------

int backColor = 34;
boolean clicked = false;

//channel to color mappings
final int purChannel = 0;
final int redChannel = 1;
final int bluChannel = 2;
final int yelChannel = 3;

// holds notes of different types for drawing
ArrayList<int[]> playing; // currently playing
ArrayList<int[]> allMidi; // all notes that have finished playing
// array of each captured color
ArrayList<int[]> redMidi;
ArrayList<int[]> yelMidi;
ArrayList<int[]> bluMidi;
ArrayList<int[]> purMidi;

// **************** Brendan's code ******************
public class Bend
{
  int channel;
  int note;
  float bend;
  int time;

  public Bend(int _channel, int _note, float _bend)
  {
    channel = _channel;
    note = _note;
    bend = _bend;
    time = millis();
  }

  public int to_color()
  {
    int alpha = note_to_alpha(note);
    alpha /= 2;

    switch(channel)
    {
      case purChannel: return color(307, 76, 60, alpha);
      case redChannel: return color(352, 83, 92, alpha);
      case bluChannel: return color(190, 100, 83, alpha);
      case yelChannel: return color(40, 91, 98, alpha);
      default: return color(0,0,0,0); //transparent
    }
  }
}

ArrayList<Bend> bends = new ArrayList<Bend>();

boolean[][] noteStatuses = new boolean[16][12]; // [channel][note] (MIDI has max of 16 channels)
// -------------- end Brendan's code -----------------

// drawing vars
float dis;
boolean show;
int difT;
float finalPos;
float a;

// all for timing and saving/sending data to server
int start;
int interval = 1500; // display interval
int introTime = 4300; // how long the countdown/play show
int whiteA = 0;

// test to prevent saving every frame
boolean saveA = true;
boolean saveR = true;
boolean saveY = true;
boolean saveB = true;
boolean saveP = true;

//used for drawing on at the end, allows saving without background
PGraphics tempG;

// fonts to use to maintain branding
PFont font;
PFont fontSmall;

void setup() {
  fullScreen();
  MidiBus.list(); // lists available midi devices
  start = millis();
  myBus = new MidiBus(this, midiDevice, 1); //hook up midibus
  // initialize arrays
  playing = new ArrayList<int[]>();
  allMidi = new ArrayList<int[]>();
  redMidi = new ArrayList<int[]>();
  yelMidi = new ArrayList<int[]>();
  bluMidi = new ArrayList<int[]>();
  purMidi = new ArrayList<int[]>();
  colorMode(HSB, 360, 100, 100, 100);
  rectMode(CENTER);
  noStroke();
  tempG = createGraphics(768, 768, JAVA2D);
  tempG.noStroke();
  textAlign(CENTER);
  font = createFont("Neutra2Display-Titling.otf", 48);
  fontSmall = createFont("Neutra2Display-Titling.otf", 32);
}

void draw() {
  background(backColor);

  if(millis() - start >= playLength+(interval*5)+(introTime*1.7)){
    // end of a single play experience, resets for the next
    // send data then reset the system
    sendToServer(); 
    allMidi.clear();
    redMidi.clear();
    bluMidi.clear();
    purMidi.clear();
    yelMidi.clear();
    playing.clear();
    bends.clear();

    //wipe the 2D array of [channel][note] statuses
    for(int c = 0; c < noteStatuses.length; c++)
    {
      for(int n = 0; n < noteStatuses[c].length; n++)
      {
        noteStatuses[c][n] = false;
      }
    }

    start = millis();
    clicked = false;
    saveA = true;
    saveY = true;
    saveB = true;
    saveP = true;
    saveR = true;
  // find and delte all the files we created to get byte data from
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
  } else if(clicked&&millis() - start >= playLength+(interval*4)+(introTime*1.7)) {
    // save and disaply purple
    
    regDraw(purMidi, purChannel);
    if (saveP) {
      saveP = false;
      saveToFile("pur");
    }
    
    //saveP = true;
  } else if (clicked&&millis() - start >= playLength+(interval*3)+(introTime*1.7)) {
    // save and display red
    
    regDraw(redMidi, redChannel);
    if (saveR) {
      saveR = false;
      saveToFile("red");
    }
  } else if (clicked&&millis() - start >= playLength+(interval*2)+(introTime*1.7)) {
    // save and display yellow 
    
    regDraw(yelMidi, yelChannel);
    if (saveY) {
      saveY = false;
      saveToFile("yel");
    }
  } else if (clicked&&millis() - start >= playLength+interval+(introTime*1.7)) {
    // save and display blue 
    
    regDraw(bluMidi, bluChannel);
    if (saveB) {
      saveB = false;
      saveToFile("blu");
    }
  } else if (clicked&&millis() - start >= playLength+(introTime*1.5)) {
    // save and display all midi 
    regDraw(allMidi, -1);
    if (saveA) {
      saveA = false;
      saveToFile("all");
    }
  } else if(clicked&&millis() - start >= introTime){
    // normal playing

  //draw pitch bend dots
  for(int i = 0; i < bends.size(); i++)
  {
    Bend bend = bends.get(i);
    a = (bend.time - (start+introTime)) * angleInc;
    dis = note_to_radius(bend.note);
    int x = floor(width/2 + (dis * cos(radians(a))));
    int y = floor(height/2 + (dis * sin(radians(a))));
    pushMatrix();
    translate(x, y);
    rotate(radians(a));
    fill(bend.to_color());
    int wobble = floor(map(bend.bend, 0, 0.08, 0, 3));
    rect(wobble, 0, 2, 2);
    popMatrix();
  }

// draw the completed midi-notes.
  for (int i =0; i<allMidi.size(); i++) {

    int[] cur = allMidi.get(i);
    // a is the angle on the circle based on when it was played
    a = (cur[4]-(start+introTime)) * angleInc;
    finalPos = 20*(cur[1] + 1)+55;
    difT = millis() - cur[4];
    
    // this is for the animation of them shooting out
    // dif is the radius to draw at based on note, and if the animation is done
    if (difT >= 500) {
      dis = finalPos;
      show = true;
    } else {
      dis = (float)(finalPos*Math.cbrt(difT/500.0));
      show = false;
    }
    // final x and y
    int x = floor(width/2 + (dis * cos(radians(a))));
    int y = floor(height/2 + (dis * sin(radians(a))));
    // duration affects the square size based on how long it was played
    int duration = floor(sqrt((cur[9])/25));
    pushMatrix();
    translate(x, y);
    rotate(radians(a));
    fill(color(cur[5], cur[6], cur[7], cur[8]));
    rect(0, 0, 12+(duration), 12+(duration));
    // addition affect besides the note square, change velPivot
    // to see both in a single song
    if (show) {
      if (cur[3] <= velPivot) {
        // show little squares on sides
        fill(color(cur[5], cur[6], cur[7], cur[8]*.5));
        rect(-25, 0, 7+(duration), 7+(duration));
        rect(25, 0, 7+(duration), 7+(duration));
      } else {
        // show little burst squares with animated shoot-out
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
  } // end allMidi

// repeat of allMidi but for notes that haven't been turned off yet
// difference is calculating duration instead of having the length saved
// drawn second so they show up over allMidi
  for (int i =0; i<playing.size(); i++) {

    int[] cur = playing.get(i);
    //used for size calculation
    finalPos = 20*(cur[1] + 1)+55;
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
    a = (cur[4]-(start+introTime)) * angleInc;
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
  } // and playing
  if(millis() - start >= playLength+introTime){
    // if their play time has finished transition to outro
      whiteA += 4;
      if(whiteA >= 65) whiteA=65;
      fill(255, whiteA);
      rect(width/2,height/2,width,height);
      fill(0);
      text("Done!", width/2, height/2); 
      text("Here's what you made", width/2, height/2+60);
  } 
}// and regular drawing
else if(clicked){
  // start the countdown to play
    fill(255);
    textFont(font);
     if(millis()-start >= introTime - 400){
       text("PLAY!", width/2, height/2);
     } else{
       text("Get ready to Rock!", width/2, height/2);
       text((introTime-400-(millis()-start))/1000+1, width/2, height/2+60);
     }
  } else{
     // waiting for someone to play
       fill(255);
       textFont(font);
       text("Get ready to Rock!", width/2, height/2);
       textFont(fontSmall);
       text("Play a note to begin.", width/2, height/2+60);
       start = millis();
  } //end if for normal playing
}
// ********** Bendan's code **********
int note_to_alpha(int note)
{
  return (100 - note*7);
}

int note_to_radius(int note)
{
  return 20*(note + 1)+55;
}
// -------- end Brendan's code ------------

// TheMididBus method, triggers when noteOn recieved
// add to playing array and parse data
void noteOn(int channel, int noteNum, int vel) {
  // first note played starts playTime
  if(!clicked){
    clicked = true;
  } else{
    // make sure to only listen to notes during the play time
    // won't add notes played before or after
  if(introTime <= millis()-start && millis()-start <= playLength+(introTime)){
  int octave = (noteNum/12) -1; // ach octave is 12 notes
  int note = noteNum%12;
  int tplayed = millis();
  println("Note num "+ noteNum + "; Octave " + octave + ", channel " + channel+", vel "+vel);
  int hue = 0;
  int saturation = 0;
  int brightness = 0;
  int alpha = note_to_alpha(note);
  noteStatuses[channel][note] = true;
  // CHANNEL CHANGE switch comparisons
  // set the color for each channel
  if (channel==purChannel) {
    hue = 307;
    saturation = 76;
    brightness = 60;
  } else if (channel==redChannel) {
    hue = 352;
    saturation = 83;
    brightness = 92;
  } else if (channel==bluChannel) {
    hue = 190;
    saturation = 100;
    brightness = 83;
  } else if (channel==yelChannel) {
    hue = 40;
    saturation = 91;
    brightness = 98;
  }

  // CHANNEL CHANGE - switch octave/channel in array
  int[] temp = {channel, note, octave, vel, tplayed, hue, saturation, brightness, alpha};
  playing.add(temp);
}
  }
}

// TheMididBus method, triggers when noteOn recieved
// remove from beingplayed array, add to allMidi array
void noteOff(int channel, int noteNum, int vel) {
  int octave = (noteNum/12) -1;
  int note = noteNum%12;

  noteStatuses[channel][note] = false;

  //CHANNEL CHANGE - switch octave/channel in array
  int[] temp = {channel, note, octave};
  for (int i=0; i<playing.size(); i++) {
    int[] cur = playing.get(i);
    if (temp[0] == cur[0] && temp[1] == cur[1] && temp[2] == cur[2]) {
      int dur = millis() - cur[4];
      int[] finished = append(cur, dur);
      allMidi.add(finished);
      playing.remove(i);
      
      if(cur[0]==1){
        redMidi.add(finished);
      }else if(cur[0]==2){
        bluMidi.add(finished);
      }else if(cur[0]==3){
        yelMidi.add(finished);
      }else if(cur[0]==0){
        purMidi.add(finished);
      }
    }
  }
}

void saveToFile(String imgName){
  tempG.save(imgName+".png");
}

// ****************** Brendan's code *************
//bend goes from -1.0 to 1.0
void channelBend(int channel, float bend)
{
  //lookup what notes are active
  for(int note = 0; note < noteStatuses[0].length; note++)
  {
    //if this note on this channel is being played
    if(noteStatuses[channel][note])
    {
      bends.add(new Bend(channel, note, bend));
    }
  }
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
    if(abs(bend) > 0.001)
    {
      channelBend(channel, bend);
    }
  }
  // ------------- end Brendan's code ---------------
}

// replacing mouseClicked
void sendToServer() {
  // reads in the images as byte arrays and converts to base64
  byte[] imageBytesP = loadBytes("pur.png");
  String thisIsBaseP = DatatypeConverter.printBase64Binary(imageBytesP);
  byte[] imageBytesR = loadBytes("red.png");
  String thisIsBaseR = DatatypeConverter.printBase64Binary(imageBytesR);
  byte[] imageBytesB = loadBytes("blu.png");
  String thisIsBaseB = DatatypeConverter.printBase64Binary(imageBytesB);
  byte[] imageBytesY = loadBytes("yel.png");
  String thisIsBaseY = DatatypeConverter.printBase64Binary(imageBytesY);
  byte[] imageBytesA = loadBytes("all.png");
  String thisIsBaseA = DatatypeConverter.printBase64Binary(imageBytesA);
  
  // Form the post request to send data to server
  PostRequest post = new PostRequest(defaultLoc);
  post.addData("all", thisIsBaseA);
  post.addData("pur", thisIsBaseP);
  post.addData("red", thisIsBaseR);
  post.addData("blu", thisIsBaseB);
  post.addData("yel", thisIsBaseY);
  post.send();
}

//pass -1 for channel to draw all channels
void regDraw(ArrayList<int[]> looper, int channel){
  // used to draw on transparent background for png's
    tempG.beginDraw();
    tempG.clear();
    tempG.noStroke();
    tempG.rectMode(CENTER);
    
//************** Brendan's code *************
    //draw pitch bend dots
    for(int i = 0; i < bends.size(); i++)
    {
      Bend bend = bends.get(i);
      if(bend.channel == channel || channel == -1)
      {
        a = bend.time * angleInc;
        dis = note_to_radius(bend.note);
        int x = floor(tempG.width/2 + (dis * cos(radians(a))));
        int y = floor(height/2 + (dis * sin(radians(a))));
        tempG.pushMatrix();
        tempG.translate(x, y);
        tempG.rotate(radians(a));
        tempG.fill(bend.to_color());
        int wobble = floor(map(bend.bend, 0, 0.08, 0, 3));
        tempG.rect(wobble, 0, 2, 2);
        tempG.popMatrix();
      }
    }
// ----------- end Brendan's code -------------

    //draw the notes
    for (int i =0; i<looper.size(); i++) {
      // same drawing as before, on a graphic to have transparent background
      int[] cur = looper.get(i);
      a = (cur[4]-(start+introTime+500)) * angleInc;
      finalPos = 20*(cur[1] + 1)+55;
      dis = finalPos;
      int x = floor(tempG.width/2 + (dis * cos(radians(a))));
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
    
    image(tempG, (width/2)-(height/2), 0);
}