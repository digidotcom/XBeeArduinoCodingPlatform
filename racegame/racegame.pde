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

// Change the following line of code to the serial port connector to your XBee.
final String XBEE_PORT = "COM5";
final int XBEE_BAUD = 9600;
final int CAR_COUNT = 4;             // Number of racers
final int XPOS_CAR_OFFSET = 80;      // X Position of first car
final int XPOS_CAR_SPACER = 100;     // X space between cars
final int YPOS_RACE_SIZE = 600;      // Size of the race course in pixels
final int VELOCITY_SCALER = 10000;   // Scales car speed by milliseconds specified
final int RACE_COURSE_UNITS = 20000; // Size of the race course in arbitrary "units"
final int XPOS_CAR_SIZE = 10;        // Size of the car in the x axis
final int YPOS_CAR_SIZE = 30;        // Size of the car in the y axis
XBeeDevice xbeeDevice;
final IOLine[] INPUT_PINS = {IOLine.DIO0_AD0, 
                             IOLine.DIO1_AD1,
                             IOLine.DIO2_AD2,
                             IOLine.DIO3_AD3};
CarTracker[] cars = new CarTracker[CAR_COUNT];                             
                             
/*
 * The CarTracker class tracks the status of a car
 * in the race game.  It tracks the car's button events, velocity,
 * distance traveled, and color.
 */
class CarTracker {
  private int[] millisPassed = {0, 0, 0};
  private int millisIndex = 0;
  private int distance = 0;  
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

void setup() {
  String[] colors = {"blue", "red", "green", "yellow"};

  // initialize the cars
  for (int i = 0; i < CAR_COUNT; i++) {
    cars[i] = new CarTracker();
    cars[i].setColor(colors[i]);
  }
  try {     
    xbeeDevice = new Raw802Device(XBEE_PORT, XBEE_BAUD);
    xbeeDevice.open();
  }
  catch (Exception e) {
      System.out.println("Failed to initialize XBee.");
      e.printStackTrace();
      System.exit(1);
  }
    // Hooks the button handler to capture button press events.
    xbeeDevice.addIOSampleListener(new InputListener());    
    size(500, 700); 
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
  int spacer = 30;
 
  for (int i = 0; i < CAR_COUNT; i++) {
    cars[i].setDistance(cars[i].getDistance() + cars[i].getVelocity());
    drawCar(i);
  }
  
  checkWinner();  
}

class InputListener implements IIOSampleReceiveListener {
  @Override
  public void ioSampleReceived(RemoteXBeeDevice remoteDevice, IOSample ioSample) {
    if (ioSample.hasDigitalValues()) {      
      for (int i = 0; i < CAR_COUNT; i++) {
        IOValue ioValue = ioSample.getDigitalValue(INPUT_PINS[i]);
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
