/**
 * Mechanical Sketching Toy
 */
import java.util.*;

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
import processing.core.PApplet;

XBeeDevice xbeeDevice;

// Change as necessary. Specifies how to address the XBee.
final String XBEE_PORT = "COM5";
final int XBEE_BAUD = 9600;
// Change as necessary. Specifies the MY parameter values of each 'player', and the pin used for the potentiometer.
final XBee16BitAddress[] addrs = {
    new XBee16BitAddress("1235"), /* controls movement left and right */
    new XBee16BitAddress("1236")  /* controls movement up and down */
};
final IOLine POT_PIN = IOLine.DIO1_AD1;

// Change if necessary. Specifies the maximum value of the potentiometer reading.
final int MAX_POT_VALUE = 1023;

int oldX, oldY, x, y;
boolean firstSample = true;

// Multiply this by potentiometer value to get coordinates for screen.
float X_MULT, Y_MULT;


// Game displays full screen. Also needs size() call in setup()
boolean sketchFullScreen() {
  return true;
}

//========================
// Utility functions

void clearScreen() {
  background(#cccccc);
}

// End utility functions
//========================

void setup() {
  // Make the game take up the whole screen
  size(displayWidth, displayHeight);
  
  X_MULT = displayWidth / (float)MAX_POT_VALUE;
  Y_MULT = displayHeight / (float)MAX_POT_VALUE;
  
  // Red background.
  clearScreen();
  
  xbeeDevice = new Raw802Device(XBEE_PORT, XBEE_BAUD);
  try {
    xbeeDevice.open();
  } catch (Exception e) {
    System.err.println("Failed to initialize XBee");
    e.printStackTrace();
    System.exit(1);
  }
  
  // InputListener is defined at the bottom of this file.
  xbeeDevice.addIOSampleListener(new InputListener(this));
}

// The synchronized keyword here, and inside the InputListener below, ensures
// that the code inside draw() and inside the InputListener do not run at the
// same time.
synchronized void draw() {
  // Keep lines from going outside display.
  if (x < 0) x = 0;
  if (x > displayWidth) x = displayWidth;
  if (y < 0) y = 0;
  if (y > displayHeight) y = displayHeight;
  
  fill(#000000);
  line(oldX, oldY, x, y);

  // Save off X and Y positions as oldX and oldY.
  oldX = x;
  oldY = y;
}

void mouseClicked() {
  clearScreen();
}

class InputListener implements IIOSampleReceiveListener {
  private PApplet applet;

  public InputListener(PApplet applet) {
    this.applet = applet;
  }

  @Override
  public void ioSampleReceived(RemoteXBeeDevice remoteDevice, IOSample ioSample) {
    synchronized (this.applet) {
      XBee16BitAddress addr = remoteDevice.get16BitAddress();
    
      if (ioSample.hasAnalogValue(POT_PIN)) {
        int potValue = ioSample.getAnalogValue(POT_PIN);
        
        if (addr.equals(addrs[0])) {
          x = (int) (potValue * X_MULT);
        } else if (addr.equals(addrs[1])) {
          // Invert Y axis, so turning it right moves up, not down.
          y = (int) ((MAX_POT_VALUE - potValue) * Y_MULT);
        } else {
          // Sample is from an unrecognized device - ignore it.
          return;
        }

        if (firstSample) {
          // If this is the first I/O sample received, the line will be a dot
          // instead. This prevents drawing an initial line from 0,0 to x,y.
          firstSample = false;
          oldX = x;
          oldY = y;
        }
      }
    }
  }
}
