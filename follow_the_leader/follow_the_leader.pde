// XBee Java API library
import com.digi.xbee.api.models.*;
import com.digi.xbee.api.exceptions.*;
import com.digi.xbee.api.io.*;
import com.digi.xbee.api.packet.*;
import com.digi.xbee.api.connection.serial.*;
import com.digi.xbee.api.*;
import com.digi.xbee.api.listeners.*;
import com.digi.xbee.api.utils.*;
import com.digi.xbee.api.packet.raw.*;
import com.digi.xbee.api.packet.common.*;
import com.digi.xbee.api.connection.*;

import processing.serial.*;

// The serial port to use to communicate to the XBee
final String XBEE_PORT = "COM5";
final int XBEE_BAUD = 9600;

// Should complete this sentence "Press the <descriptor> button". Empty
// strings will be skipped, this will bias presses towards certain
// buttons however
String[][] buttonDescriptors = {
  { "Yellow", "Red", "Blue", "Green", "Black", "White" },
  { "First", "Second", "Third", "Fourth", "Fifth", "Sixth" },
  { "1st", "2nd", "3rd", "4th", "5th", "6th" },
};

// These are the DIO pins connected to the buttons described above
// We expect that they've already been configured as Digital Inputs
IOLine[] pinsOfInterest = {
  IOLine.DIO0_AD0,
  IOLine.DIO1_AD1,
  IOLine.DIO2_AD2,
  IOLine.DIO3_AD3,
  IOLine.DIO6,
  IOLine.DIO4_AD4,
};

XBeeDevice xbeeDevice;          // Represents the local radio
float guessTime = 10000.0;      // Initial time to press the correct button
float scaleDown = 0.9;          // Reduce guess time on each success

float milliStart;       // Track the start time of each round

// Colors used for the <descriptor> words on the screen
color[] colors = {
  color(255, 0, 0),
  color(0, 255, 0),
  color(0, 0, 255),
  color(255, 255, 255),
  color(255, 255, 0)
};

boolean done = false;     // Is the game over?
boolean success;          // Set when the user gets the button correct
IOLine correctPin = null; // Selected randomly each round as the correct button
String descriptor = "";   // Selected from the table above based on correctPin
color descriptorColor;    // The color of the <descriptor> word for a round

void setup() {
  // Graphics
  size(displayWidth, displayHeight);    // Fill the screen
  background(127);                      // Grey background
  textAlign(CENTER, BASELINE);
  textSize(height/4);  // Scale the words to fit nicely based on screen size

  // Serial
  xbeeDevice = new Raw802Device(XBEE_PORT, XBEE_BAUD);
  try {
    xbeeDevice.open();
  } catch (Exception e) {
    /* This would be unexpected. This will usually occur if the serial port
     * does not exist, or was already open.
     */
    e.printStackTrace();
  }

  // Register to receive all IO Samples
  xbeeDevice.addIOSampleListener(new ButtonListener());

  // Pick the first button we want
  newChoice();
}

void draw() {
  if (done) {
    // Game is over, no need to do anything
    return;
  }

  // Find out how much time they have left to guess
  float timeLeft = guessTime - (millis() - milliStart);
  if (timeLeft < 0) {
    // Time has run out, game over
    done = true;
    background(255, 0, 0);  // red
    textAlign(CENTER, CENTER);
    text("Game Over!", width/2, height/2);
    return;
  }

  // Fade the background from gray to black based on time remaining
  int bg = int(timeLeft / guessTime * 200);
  background(bg);

  fill(#ffffff); // White text
  text("Press the", width/2, height/3 - 100);

  fill(descriptorColor); // Random <descriptor> color text
  text(descriptor, width/2, 2*height/3 - 100);

  fill(#ffffff); // White text
  text("button", width/2, height - 100);

  if (success) {
    newChoice();  // Reset for a new choice
    success = false;
  }
}

/* Cleans up the game state and selects a button to be the new
 * one being asked for */
void newChoice() {
  // Pick a button from the configured pins
  int pinIndex = int(random(pinsOfInterest.length));
  correctPin = pinsOfInterest[pinIndex];

  // Pick a word to describe this button from the various options
  int descriptorType;
  descriptor = "";
  while (descriptor.equals("")) {
    descriptorType = int(random(buttonDescriptors.length));
    descriptor = buttonDescriptors[descriptorType][pinIndex];
  }
  // Give the word a random color to add to the mental stress
  descriptorColor = pickAColor();

  guessTime = guessTime * scaleDown; // Get faster each time
  milliStart = millis(); // Record start time.
}

// Helper function to pick a random color from the list
color pickAColor() {
  return colors[int(random(colors.length))];
}

// Listener class which assists in processing received IO data
class ButtonListener implements IIOSampleReceiveListener {
  @Override
  public void ioSampleReceived(RemoteXBeeDevice remoteDevice,
                               IOSample ioSample)
  {
    // Loop over all the inputs we care about watching
    for (IOLine pin : pinsOfInterest) {
      IOValue value = ioSample.getDigitalValue(pin);

      // Pin is pulled LOW when pressed
      if (value == IOValue.LOW) {
        if (pin == correctPin) {
          success = true;
        }
      }
    }
  }
}

// This informs Processing that we want to run in full screen mode.
boolean sketchFullScreen() {
  return true;
}
