/* This program implements a simple "Stop It!" LED game. An XBee will
 * be attached to the Arduino on an XBee Shield.  This code will drive
 * a "point of light" to move around a series of LEDs, and wait on a
 * remote user's input to stop the light at a certain point.  Then, the
 * light begins moving again, and it is up to another player to stop it
 * a second time.  If this second player stops the light in the same
 * place, a green LED lights up to indicate success.
 *
 * Remote user input is detected as a specified input pin state going
 * low.  This will typically happen due to a button being pressed.
 *
 * To reset the game and play again, both players must hold their buttons
 * down simultaneously, and then release.
 *
 * This code is written assuming use of an Arduino Leonardo and access
 * to the hardware serial port 'Serial1'.  It will need to be modified
 * slightly if you choose to use a software serial port or another
 * variant of Arduino.
 */

#define NO_LED -1
// Set to 1 to make the LEDs light up in the opposite order
// when it's player 2's turn.
#define SWITCH_DIRECTIONS 0

// Uses the 'xbee-arduino' library.
// https://code.google.com/p/xbee-arduino/
#include <XBee.h>

XBee xbee = XBee();

// Change these as necessary.
uint16_t REMOTE_ADDR[] = { 0x1235, 0x1236 }; // MY parameter values of remote nodes

// The pins controlling the LEDs, in the order in which they will light up.
// The two examples below assumed the LEDs are wired up as shown in the diagram
// in the kit documentation.
int pins[] = { 2, 3, 4, 5, 6, 11, 10, 9, 8, 7 }; // Move around in a circle
//{ 7, 2, 3, 8, 9, 4, 5, 10, 11, 6 }; // Wind back and forth between the two rows

// Pin controlling the success LED
int SUCCESS_PIN = 13;
// Remote XBee DIO pin controlling the LED
int REMOTE_LED_PIN = 0; // DIO0
// Remote XBee DIO pin to monitor
int REMOTE_BUTTON_PIN = 1; // DIO1

// How long each LED is lit before moving to the next, in milliseconds.
int INTERVAL = 40;

// Do not change.
int PIN_COUNT = sizeof(pins) / sizeof(int);

// The index (in the 'pins' array above) of the currently lit-up LED.
int whichLit = 0;
// The last time we changed which LED was lit up.
unsigned long previousMillis = 0;

// Which LED player 1 landed on
int player1Pin = NO_LED;
// Which LED player 2 landed on
int player2Pin = NO_LED;

// Tracks whether each player is currently pushing their button.
// (Updates with each I/O packet that is received.)
boolean buttonPressed[] = { false, false };

void setup() {
  // Open the local serial port and tell the xbee-arduino library to
  // use it for XBee traffic.
  Serial1.begin(9600);
  xbee.begin(Serial1);
  
  // Configure LED pins
  for (int i = 0; i < PIN_COUNT; i++) {
    pinMode(pins[i], OUTPUT);
  }
  
  // Configure the success pin as output.
  pinMode(SUCCESS_PIN, OUTPUT);
  
  // Seed the random number generator.
  randomSeed(analogRead(12));
  
  // Turn off all LEDs, shuffle the players,
  // and prepare for gameplay.
  initialize();
}

// Called in setup, and when restarting play.
void initialize() {
  // Reset all the pins
  for (int i = 0; i < PIN_COUNT; i++) {
    turnOff(i);
  }
  digitalWrite(SUCCESS_PIN, LOW);
  
  shufflePlayers();
  
  // Signal to the first player that it's their turn.
  // Sometimes these commands don't work, so send them twice.
  for (int i = 0; i < 2; i++) {
    indicateTurn(REMOTE_ADDR[0], true);
    indicateTurn(REMOTE_ADDR[1], false);
  }
  
  // Check and make sure player 1 is not pressing their button.
  // If they are, wait until they release it.
  readData();
  while (buttonPressed[0]) {
    readData();
  }
  
  // Turn on the first LED.
  turnOn(0);
  
  // Reset other variables.
  player1Pin = player2Pin = NO_LED;
  previousMillis = millis();
  whichLit = 0;
}

void loop() {
  unsigned long now = millis();
  
  // Read in a packet from the XBee, if there is one available,
  // and process it.
  readData();
  
  // Advance the LED if it is time to do so.
  if (now > previousMillis + INTERVAL) {
    // Switch off the current LED.
    turnOff(whichLit);
    
    // Change which LED is lit up.
    advanceLed();
    
    // Reset the timer.
    previousMillis = millis();
  }
  
  // Switch on the current LED.
  turnOn(whichLit);
  
  // If it's player 2's turn and this is the LED player 1 landed on,
  // light up the success LED.
  if (player1Pin != NO_LED && player2Pin == NO_LED) {
    digitalWrite(SUCCESS_PIN, whichLit == player1Pin);
  }
  // If both players have gone, light up the success LED if they
  // landed on the same light.
  if ((player1Pin != NO_LED) && (player2Pin != NO_LED) && (player1Pin == player2Pin)) {
    digitalWrite(SUCCESS_PIN, HIGH);
  }
  
  // Is it player 1's turn?
  if (player1Pin == NO_LED) {
    // Are they pushing their button?
    if (buttonPressed[0]) {
      // They are. Record their position.
      player1Pin = whichLit;
      
      // Flash the LED.
      flash(whichLit);
      
      // Wait until both buttons are released (so that if player 2 is holding their
      // button right now, we wait until they release it).
      while (buttonPressed[0]) {
        readData();
      }
      while (buttonPressed[1]) {
        // These are two while loops, rather than one loop with an OR-ed condition,
        // so that once player 1 releases the button, we just wait for player 2, rather
        // than allowing an infinite handoff between the two.
        readData();
      }
      
      // Signal to the second player that it's their turn.
      indicateTurn(REMOTE_ADDR[0], false);
      indicateTurn(REMOTE_ADDR[1], true);
      
      // Reset the timer.
      previousMillis = millis();
      
      // Reset the pin position.
      whichLit = 0;
    }
  } else if (player2Pin == NO_LED) {
    // It's player 2's turn.
    // Ensure the LED player 1 landed on is lit up.
    turnOn(player1Pin);
    
    if (buttonPressed[1]) {
      // The button is pushed. Record their position.
      player2Pin = whichLit;
      
      // Turn off the LED on their board - it's no longer their turn.
      indicateTurn(REMOTE_ADDR[1], false);
      
      // Flash the LED.
      flash(whichLit);
      whichLit = NO_LED;
      
      // Reset the timer.
      previousMillis = millis();
    }
  } else {
    // Both players have gone.
    
    // Wait until they are both pressing their button...
    while (!(buttonPressed[0] && buttonPressed[1])) {
      readData();
    }
    
    // Then wait for them both to release...
    while (buttonPressed[0] || buttonPressed[1]) {
      readData();
    }
    
    // Pause for a moment.
    delay(1000);
    
    // Start again.
    initialize();
  }
}

void readData() {
  // Read a packet in from the XBee, if one is available.
  xbee.readPacket();
  
  if (xbee.getResponse().isAvailable() && xbee.getResponse().getApiId() == RX_16_IO_RESPONSE) {
    // New data is available. Parse the packet.
    Rx16IoSampleResponse response = Rx16IoSampleResponse();
    xbee.getResponse().getRx16IoSampleResponse(response);
    
    // Determine whether this button is pressed (the I/O pin is low).
    boolean button_down = !response.isDigitalOn(REMOTE_BUTTON_PIN, 0);
    
    // Record the button state for this player.
    uint16_t addr = response.getRemoteAddress16();
    if (addr == REMOTE_ADDR[0]) {
      buttonPressed[0] = button_down;
    } else if (addr == REMOTE_ADDR[1]) {
      buttonPressed[1] = button_down;
    }
  }
}

// Uses a remote AT command to turn on/off the LED on the remote player's board.
void indicateTurn(uint16_t address, boolean isTheirTurn) {
  // Convert pin number (e.g. 0) to a char.
  char dioNumber = char(REMOTE_LED_PIN + '0');
  
  // Build the remote AT command.
  uint8_t cmd[] = {'D', dioNumber};
  // If it is this player's turn, we turn their LED on (high). Otherwise, we turn it off (low).
  uint8_t value[] = { isTheirTurn ? 5 : 4 };
  RemoteAtCommandRequest request = RemoteAtCommandRequest(address, cmd, value, 1);
  
  // Send the remote AT command.
  xbee.send(request);
  
  // Wait for a response, for up to 3 seconds.
  unsigned long start = millis();
  while (1) {
    // Read a packet in from the XBee, if one is available.
    xbee.readPacket();
    
    if (xbee.getResponse().isAvailable()) {
      // Check for an AT command response
      
      if (xbee.getResponse().getApiId() == RX_16_IO_RESPONSE) {
        // Received I/O data. Ignore.
      } else if (xbee.getResponse().getApiId() == REMOTE_AT_COMMAND_RESPONSE) {
        // It's an AT command response.
        RemoteAtCommandResponse response = RemoteAtCommandResponse();
        xbee.getResponse().getRemoteAtCommandResponse(response);
        
        // Is it the one we're looking for, and did it work?
        // (Assumes that no other remote AT commands are in process currently.)
        if (response.getRemoteAddress16() == address && response.isOk()) {
          // If so, break out of this loop.
          break;
        }
      }
    }
    
    if (millis() > start + 3000) {
      // We've waited at least three seconds. Break out of the loop.
      break;
    }
  }
} 

//=====================================
// Utility functions

void turnOn(int which) {
  if (which == NO_LED) return;
  digitalWrite(pins[which], HIGH);
}
void turnOff(int which) {
  if (which == NO_LED) return;
  digitalWrite(pins[which], LOW);
}

void flash(int which) {
  turnOff(which);
  delay(100);
  
  turnOn(which);
  delay(100);
  
  turnOff(which);
  delay(100);
  
  turnOn(which);
  delay(700);
}

void advanceLed() {
  static boolean moveRight = true;
  
#if SWITCH_DIRECTIONS
  // Version 1: Left-to-right for player 1, right-to-left for player 2.
  if (player1Pin == NO_LED) {
    whichLit = (whichLit + 1) % PIN_COUNT;
  } else {
    whichLit = (whichLit ? whichLit : PIN_COUNT) - 1;
  }
#else
  // Version 2: Bounce left-to-right and then right-to-left.
  if (moveRight) {
    // Move one LED to the right...
    if (whichLit == PIN_COUNT - 1) {
      // Unless we're at the far right, in which case, go left.
      moveRight = false;
      whichLit--;
    } else {
      whichLit++;
    }
  } else {
    // Move one LED to the left
    if (whichLit == 0) {
      // Unless we're at the far left, in which case, go right.
      moveRight = true;
      whichLit++;
    } else {
      whichLit--;
    }
  }
#endif
}

void shufflePlayers() {
  if (random(1) < 0.5) {
    uint16_t tmp = REMOTE_ADDR[0];
    REMOTE_ADDR[0] = REMOTE_ADDR[1];
    REMOTE_ADDR[1] = tmp;
  }
}
