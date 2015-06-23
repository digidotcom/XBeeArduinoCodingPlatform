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

/* 
 * Game configuration section
 */

// Change the following line of code to the serial port connector to your XBee.
final String XBEE_PORT = "COM5";
// Increase this to add additional racers (one per XBee not including the 
// coordinator).
final int CAR_COUNT = 2;            // Number of racers
final int XBEE_BAUD = 9600;      
final int XPOS_CAR_OFFSET = 80;      // X Position of first car
final int XPOS_CAR_SPACER = 50;     // X space between cars
final int YPOS_RACE_SIZE = 600;      // Size of the race course in pixels
final int VELOCITY_SCALER = 10000;   // Scales car speed by milliseconds specified
final int RACE_COURSE_UNITS = 20000; // Size of the race course in arbitrary "units"
final int XPOS_CAR_SIZE = 10;        // Size of the car in the x axis
final int YPOS_CAR_SIZE = 30;        // Size of the car in the y axis
/* 
 * End configuration 
 */

boolean message;
XBeeDevice xbeeDevice;
final IOLine INPUT_PIN = IOLine.DIO1_AD1;

class CarTracker {
  private int[] millisPassed = {0, 0, 0};
  private int millisIndex = 0;
  private int distance = 0;  
  private XBee16BitAddress xbeeAddress = new XBee16BitAddress(new byte[] {0, 0});
  private int mycolor = 0;
  boolean buttonState = false;
  
  public CarTracker() {
    millisIndex = distance = 0;
    buttonState = false;
  }

  // Sets the color of the car.
  public void setColor(String thecolor) {
    switch (thecolor.charAt(0)) {
    case 'y':
      mycolor = 0xFFFFFF00;
      break;
    case 'r':
      mycolor = 0xFFFF0000;
      break;
    case 'b':      
      mycolor = 0xFF0000FF;
      break;
    case 'g':
      mycolor = 0xFF00FF00;
      break;
      // pick a random color
    default:
      // This picks a random color by picking a random 
      // number between 129-225 for red, green and blue. 
      mycolor = 0xFF000000 +
              (128 + int(random(128)) * 0x10000) + 
              128 + int(random(128)) * 0x100 + 
              128 + int(random(128));
      break;
    }
  }
  
  // Sets the pen to the color of the car.
  public int getColor() {
    return mycolor;
  }
  
  public XBee16BitAddress getXBeeAddress() {
    return xbeeAddress;
  }
  
  public void setXBeeAddress(XBee16BitAddress xbeeAddress) {
    this.xbeeAddress = xbeeAddress;
  }
  
  public boolean isXBeeAddressZero() {
    return xbeeAddress.equals(XBee16BitAddress.COORDINATOR_ADDRESS);
  }
  
  public int getDistance() {
    return distance;
  }  
  
  public void setDistance(int distance) {
    this.distance = distance;
  }
  
  public void setButtonState(boolean buttonState) {
    this.buttonState = buttonState;
  }
  
  public boolean getButtonState() {
    return buttonState;
  }  
  
  // Record a button press event (records
  // the time that the button was pressed).
  public void buttonEvent() {
    millisPassed[millisIndex] = millis();   
    // This make a round-robin index of the
    // millisPassed array so that millisIndex
    // always moves to the next postion in the array
    // or goes back to 0 (i.e., the sequence is
    // 0,1,2,0,1,2,0,1,2,0...)
    millisIndex = ++millisIndex % 3;
  }
  
  /* 
   * Returns the current velocity of the car
   * based on the speed of the last 3 button 
   * presses.
   */
  public int getVelocity() {
    int current = millis();
    int slowest = 0;
    for (int i = 0; i< 3; i++) {
      if (millisPassed[i] == 0) {
        slowest = 0x7fffffff;
        break;
      }      
      if (slowest < current - millisPassed[i]) {
         slowest = current - millisPassed[i];
      }
    }
    // As more than VELOCITY_SCALER milliseconds passes since the third to last
    // button press, the car will come to a stop.  
    return VELOCITY_SCALER/slowest;
  }
}

CarTracker[] cars = new CarTracker[CAR_COUNT];

int initIndex = 0;

// Assigns XBees to the cars.  Each time around
// the draw loop prompts the next user for a button
// press until all the XBees/buttons are assigned to 
// cars.
void assignButtons() {
  String[] colors = {"blue", "red", "green", "yellow"};
  
  background(0);
  textSize(32);
  if (initIndex < 4) {
    cars[initIndex].setColor(colors[initIndex]);  
  }
  else {
    cars[initIndex].setColor("custom");
  }
  fill(cars[initIndex].getColor());
  int i = initIndex + 1;
  text("Car # " + i + " press your button.", 50, 380);
}

void setup() {
  for (int i = 0; i < CAR_COUNT; i++) {
    cars[i] = new CarTracker();    
  }
  
  try {     
    xbeeDevice = new Raw802Device(XBEE_PORT, XBEE_BAUD);
    xbeeDevice.open();
    
    // Hooks the button handler to assign buttons.    
    xbeeDevice.addIOSampleListener(new InitInputListener());
    size(500, 700);
  } 
  catch (Exception e) {
    System.out.println("XBee failed to initialize");
    e.printStackTrace();
    System.exit(1);
  }
}

void drawCar(int carNum) {
  fill(cars[carNum].getColor());
  rect(XPOS_CAR_OFFSET+XPOS_CAR_SPACER*carNum, 
       YPOS_RACE_SIZE-(cars[carNum].getDistance()*YPOS_RACE_SIZE/RACE_COURSE_UNITS), 
       XPOS_CAR_SIZE, 
       YPOS_CAR_SIZE);
}

void checkWinner() {  
  int winner = 0;
  for (int i = 0; i < CAR_COUNT; i++) {
    // If the car has traveled more than RACE_COURSE_UNITS it wins
    if (cars[i].getDistance() > RACE_COURSE_UNITS) {
        fill(cars[i].getColor());      
        background(0);
        winner = i + 1;
        textSize(32);
        text("Car " + winner + " wins!!!!", 50, 380);  
        noLoop();
        break;
    }     
  }
}


void draw() {
  background(0);
  if (initIndex < CAR_COUNT) {
    assignButtons();
  }
  else {
    int spacer = 30;
   
    for (int i = 0; i < CAR_COUNT; i++) {
      // Move the car.
      cars[i].setDistance(cars[i].getDistance() + cars[i].getVelocity());
      drawCar(i);
    }
    
    checkWinner();
  }  
}

class InitInputListener implements IIOSampleReceiveListener {
  
  @Override
  public void ioSampleReceived(RemoteXBeeDevice remoteDevice, IOSample ioSample) {
    
    try {
      XBee16BitAddress address = remoteDevice.get16BitAddress();      
      for (int i = 0; i < initIndex ; i++) {
        if (cars[i].getXBeeAddress().equals(address)) {
          return;
        }        
      }
      cars[initIndex++].setXBeeAddress(address);
      // Last car registered, reassign handler to start the race.
      if (initIndex == CAR_COUNT) {
        xbeeDevice.removeIOSampleListener(this);
        // Hooks the button handler to capture button press events.
        xbeeDevice.addIOSampleListener(new InputListener());
      }
    }
    catch (Exception e) {
      println("oops");
    }    
  }
  
}

class InputListener implements IIOSampleReceiveListener {
  @Override
  public void ioSampleReceived(RemoteXBeeDevice remoteDevice, IOSample ioSample) {
    if (ioSample.hasDigitalValues()) {
      for (int i = 0; i < CAR_COUNT; i++) {
        if (cars[i].getXBeeAddress().equals(remoteDevice.get16BitAddress())){
          IOValue ioValue = ioSample.getDigitalValue(INPUT_PIN);
          // Require both an up and down event to register a button press event.          
          if (ioValue == IOValue.LOW && cars[i].getButtonState() == true) {          
            cars[i].setButtonState(false);
            cars[i].buttonEvent();          
          }
          else if (ioValue == IOValue.HIGH && cars[i].getButtonState() == false) {
            cars[i].setButtonState(true);
          }
        }
      }
    }
  }
}
