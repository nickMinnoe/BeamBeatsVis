// needed for handling midi datas
import themidibus.*; //Import the library
import javax.sound.midi.MidiMessage; 


import http.requests.*;
// convert to base64?
import javax.xml.bind.DatatypeConverter;

MidiBus myBus; 

// uri to connect to
String defaultLoc = "http://beambeats.cias.rit.edu/visualization/acceptVis.php";

int backColor = 34;
int midiDevice  = 0;
boolean clicked = false;

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
int velPivot = 0;

// all for timing and saving/sending data to server
int start;
int playLength = 60000;
int interval = 1500;
int introTime = 4300;
int whiteA = 0;

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
  tempG = createGraphics(768, 768, JAVA2D);
  tempG.noStroke();
  textAlign(CENTER);
  PFont font = createFont("Neutra2Display-Titling.otf", 48);
  textFont(font);
}

void draw() {

  background(backColor);

  // -----   End show conditions
  if(millis() - start >= playLength+(interval*5)+(introTime*1.7)){
    //reset the system
    allMidi.clear();
    redMidi.clear();
    bluMidi.clear();
    purMidi.clear();
    yelMidi.clear();
    playing.clear();
    start = millis();
    clicked = false;
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
  } else if(clicked&&millis() - start >= playLength+(interval*4)+(introTime*1.7)) {
    //save purple
    
    regDraw(purMidi);
    if (saveP) {
      saveP = false;
      saveNSend("pur");
    }
    
    //saveP = true;
  } else if (clicked&&millis() - start >= playLength+(interval*3)+(introTime*1.7)) {
    // save red
    
    regDraw(redMidi);
    if (saveR) {
      saveR = false;
      saveToFile("red");
    }
  } else if (clicked&&millis() - start >= playLength+(interval*2)+(introTime*1.7)) {
    // save yellow 
    
    regDraw(yelMidi);
    if (saveY) {
      saveY = false;
      saveToFile("yel");
    }
  } else if (clicked&&millis() - start >= playLength+interval+(introTime*1.7)) {
    // save blue 
    
    regDraw(bluMidi);
    if (saveB) {
      saveB = false;
      saveToFile("blu");
    }
  } else if (clicked&&millis() - start >= playLength+(introTime*1.5)) {
    // save all midi 
    regDraw(allMidi);
    if (saveA) {
      saveA = false;
      saveToFile("all");
    }
  } else if(clicked&&millis() - start >= introTime){
    // normal playing

  for (int i =0; i<allMidi.size(); i++) {

    int[] cur = allMidi.get(i);
    a = (cur[4]-(start+introTime)) * angleInc;
    finalPos = 20*(cur[1] + 1)+55;
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
  }
  if(millis() - start >= playLength+introTime){
      whiteA += 4;
      if(whiteA >= 65) whiteA=65;
      fill(255, whiteA);
      rect(width/2,height/2,width,height);
      fill(0);
      text("Done!", width/2, height/2); 
      text("Here's what you made", width/2, height/2+60);
    }
  } else if(clicked){
    fill(255);
     if(millis()-start >= introTime - 400){
       text("PLAY!", width/2, height/2);
     } else{
       text("Get ready to Rock!", width/2, height/2);
       text((introTime-400-(millis()-start))/1000+1, width/2, height/2+60);
     }
  } else{
     // waiting
     println("back in black");
       fill(255);
       text("Get ready to Rock!", width/2, height/2);
       start = millis();
  }
}

// TheMididBus method, triggers when noteOn recieved
// add to playing array and parse data
void noteOn(int channel, int noteNum, int vel) {
  if(!clicked){
    clicked = true;
  } else{
  if(introTime <= millis()-start && millis()-start <= playLength+(introTime)){
  int octave = (noteNum/12) -1;
  int note = noteNum%12;
  int tplayed = millis();
  println("Note num "+ noteNum + "; Octave " + octave + ", channel " + channel+", vel "+vel);
  int hue = 0;
  int saturation = 0;
  int brightness = 0;
  int alpha = 100 - note*7;
  if (octave==1) {
    hue = 352;
    saturation = 83;
    brightness = 92;
  } else if (octave==2) {
    hue = 190;
    saturation = 100;
    brightness = 83;
  } else if (octave==3) {
    hue = 40;
    saturation = 91;
    brightness = 98;
  } else if (octave==4) {
    hue = 307;
    saturation = 76;
    brightness = 60;
  }

  int[] temp = {octave, note, channel, vel, tplayed, hue, saturation, brightness, alpha};
  playing.add(temp);
}
  }
}

// TheMididBus method, triggers when noteOn recieved
// remove from beingplayed array, add to allMidi array
void noteOff(int channel, int noteNum, int vel) {
  int octave = (noteNum/12) -1;
  int note = noteNum%12;
  
  int[] temp = {octave, note, channel};
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
      }else if(cur[0]==4){
        purMidi.add(finished);
      }
    }
  }
}
void saveToFile(String imgName){
  tempG.save(imgName+".png");
  
}

// replacing mouseClicked
void saveNSend(String imgName) {
  //change this line to save from a passed in object
  print("In here");
  tempG.save(imgName+".png");
  delay(1000);

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
  
  
  PostRequest post = new PostRequest(defaultLoc);
  post.addData("all", thisIsBaseA);
  post.addData("pur", thisIsBaseP);
  post.addData("red", thisIsBaseR);
  post.addData("blu", thisIsBaseB);
  post.addData("yel", thisIsBaseY);
  post.send();
}

void regDraw(ArrayList<int[]> looper){
 tempG.beginDraw();
    tempG.clear();
    tempG.noStroke();
    tempG.rectMode(CENTER);
    for (int i =0; i<looper.size(); i++) {

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