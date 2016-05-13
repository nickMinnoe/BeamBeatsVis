# BeamBeatsVis

##How it should work

When you run the sketch it should wait for a note to be played. Then, after a countdown, for a minute it will visualize notes on the screen. This uses will display 5 different colors. Channels 0-3 each have a unique color, and everything else will be black. After the minute is up, it will display all the notes and then each the notes for each channel on their own. It will save them to a file, send a post request to the designated server, then delete the files.

__For simple changes, like which channels are being visualized, or colors, look at noteOn().__

##What's here?

The .pde is the processing(3) file. The other file is just a font for our branding, if you remove it the program will error, but control+f "font" and delete any line dealing with fonts.

##Setting it up

1. For some reason I couldn't get the midibus library to work unless you used Processing 3 32bit. I couldn't receive any midi data on the 64bit version.
2. In the processing sketch go to the Sketch drop down, Import Library and install "The Midibus"(for receiving music notes) and "HTTP request for processing" (for sending data to the server)
3. Run the code once. This will provide a list of available midi-connections. Change the "midiDevice" var to match the index of that device.
4. This is set up to send the visualizations to a server. change the value of the "defaultLoc" variable to be the location that will accept them.
5. Run the code, should be working now. This is set up to run for one minute, change the playLength" var to change the time, and angleInc (360/playLength).

##Weird things to look out for

Occassionally when running the sketch no midi-data comes through at all. I close the processing window and re-open the sketch and it works again.
Also rarely, after a few runs it will get a null-pointer exception. Stop and re-run the sketch and it _shouldn't_ happen again. This only happened once or twice out of all the times I ran it.

##Testing

The easiest way to test this is to have a device that outputs midi and can connect to your computer with a USB adapter.

The other option allows you to test on your computer without an actual input device, but you need to download a few things.
  [__Midi-ox__](http://www.midiox.com): this is an incredibly useful tool. Firstly, this will allow you to test input from any device, make sure it is receiving the port the data is coming through (makes sure it's not just processing not working.) Further, it can allow you to play a notes through your computer's keyboard.
  
  __Midi-yoke__: This piece of software allows you to make internal connections. With this you can send the keyboard data from midi-ox through a midi-yoke port, then accept the port as input for processing. This can be found on the same page as midi-ox.

[__Request bin__](requestb.in): This can be used for test data sent to the server. This will make a very simple page capable of accepting the post requests you send and displaying the data you sent.
