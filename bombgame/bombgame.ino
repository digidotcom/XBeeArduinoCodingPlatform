/* This program implements a simple multiplayer bomb defuser game.
 * An XBee will be attached to the Arduino on an XBee Shield.  This
 * code will receive I/O packets from remote XBees when players pull
 * wires connecting digital inputs to ground.  Each player only pulls
 * a single wire on their turn.  If a player acts out-of-turn, their
 * bomb explodes (their LED lights up) and gameplay ends.  If a player
 * pulls a wire which the other player has already pulled, their bomb
 * explodes and gameplay ends.  To restart the game, reset the Arduino.
 *
 * Additional gameplay notes:
 * - Due to the fairly simple implementation here, a single game can
 *   potentially continue indefinitely, if players begin reconnecting
 *   wires.  The game logic only checks for pins which are both high
 *   at the same time, and so returning a pin to a low state will not
 *   trigger any game-ending logic on its own.
 *
 * This code is written assuming using of an Arduino Leonardo and access
 * to the hardware serial port 'Serial1'.  It will need to be modified
 * slightly if you choose to use a software serial port or another
 * variant of Arduino.
 */

// Uses the 'xbee-arduino' library.
// https://code.google.com/p/xbee-arduino/
#include <XBee.h>

XBee xbee = XBee();

// Change as necessary
uint16_t REMOTE_ADDR[] = { 0x1235, 0x1236 }; // MY parameter values of remote nodes
int WIRE[] = { 0, 1, 2, 3 }; // Digital input pins used
uint8_t LED_AT_COMMAND[] = {'D', '7'}; // Command used to change the status LED on each remote node

// Set this to an array the same length as REMOTE_ADDR[].
int previous[] = { 0, 0 };

// How long to wait, in milliseconds, for a successful AT command response
// (when changing remote LED state).
const int AT_COMMAND_TIMEOUT = 2000;

// Do not change.
const int WIRE_COUNT = sizeof(WIRE) / sizeof(int);
const int PLAYER_COUNT = sizeof(REMOTE_ADDR) / sizeof(uint16_t);
Rx16IoSampleResponse response = Rx16IoSampleResponse();

int currentPlayer = 0;

boolean firstLoop = true;
boolean gameOver = false;

void setup() {
  // Open the local serial port and tell the xbee-arduino library to
  // use it for XBee traffic.
  Serial1.begin(9600);
  xbee.begin(Serial1);

  // Record expected initial I/O state for each player.
  for (int i = 0; i < PLAYER_COUNT; i++) {
    previous[i] = 0;
  }
}

void loop() {
  // If the game has just begin, run through some initialization logic.
  if (firstLoop) {
    firstLoop = false;
    onFirstLoop();
  }

  // If the game is over, delay for a moment to avoid wasting CPU time,
  // then restart the loop function.
  if (gameOver) {
    delay(1000);
    return;
  }

  // Read a packet in from the XBee, if one is available.
  xbee.readPacket();

  if (xbee.getResponse().isAvailable() && xbee.getResponse().getApiId() == RX_16_IO_RESPONSE) {
    // It's an I/O sample. Parse the packet.
    xbee.getResponse().getRx16IoSampleResponse(response);

    // If this packet is from someone who is playing out of turn, signal their loss.
    if (response.getRemoteAddress16() != REMOTE_ADDR[currentPlayer]) {
      gameOver = true;
      signalExplosion(response.getRemoteAddress16());
      return;
    }

    // For I/O comparison, we could use the `isDigitalOn` method of the response; however,
    // this game is concerned with tracking and comparing the overall I/O state of the
    // devices, and not any individual pin, and so it is easier to parse out the digital I/O
    // bitmask directly as done below than it would be to build that up using `isDigitalOn`
    // inside a for-loop, for example.
    
    // The xbee-arduino library presents the I/O data as the bytes contained in the packet.
    uint8_t *data = response.getData();
    // The first byte is the number of sample, the next two bytes are the channel bitmask,
    // and the two bytes after that are the digital data.
    unsigned int io = (data[3] << 8) | data[4];

    // If the current player is 0, the 'previous' is PLAYER_COUNT-1. Otherwise, subtract 1.
    int previousPlayer = (currentPlayer ? currentPlayer : PLAYER_COUNT) - 1;

    // If the pin that went high was already high on the other player's board,
    // then this player loses.
    unsigned int shared = io & previous[previousPlayer];
    if (shared) { // shared != 0
      // Previous player already cut that wire.
      gameOver = true;
      signalExplosion(response.getRemoteAddress16());
      return;
    }

    // Otherwise, record this player's new I/O state, and move on to the next player.
    previous[currentPlayer] = io;
    currentPlayer = (currentPlayer + 1) % PLAYER_COUNT;
  }
}

//============================================
// Game-specific functions.

// Turn on the LED associated with the XBee at the given address.
void signalExplosion(uint16_t address) {
  // Build a remote AT command to turn on the given player's LED.
  uint8_t value[] = {5};
  RemoteAtCommandRequest request = RemoteAtCommandRequest(address, LED_AT_COMMAND, value, 1);

  // Send the command.
  xbee.send(request);
}

// Turn off the LED associated with the XBee at the given address. Used during
// game initialization.
void clearLed(uint16_t address) {
  // Build a remote AT command to turn off the given player's LED.
  uint8_t value[] = {4};
  RemoteAtCommandRequest request = RemoteAtCommandRequest(address, LED_AT_COMMAND, value, 1);
  
  // Send the command.
  xbee.send(request);

  // Wait for a successful response, or time out after AT_COMMAND_TIMEOUT milliseconds.
  unsigned long start = millis();
  while (1) {
    // Read a packet in from the XBee, if one is available.
    xbee.readPacket();

    if (!xbee.getResponse().isAvailable()) {
      // No data.
    } else {
      if (xbee.getResponse().getApiId() == REMOTE_AT_COMMAND_RESPONSE) {
        // It's a response to an AT command. Parse the packet.
        RemoteAtCommandResponse response = RemoteAtCommandResponse();
        xbee.getResponse().getRemoteAtCommandResponse(response);

        if (response.getRemoteAddress16() == address && response.isOk()) {
          // The command was successful. (Assumes these are the only AT commands
          // going out over the network.)
          break;
        }
      }
    }

    if (millis() > start + AT_COMMAND_TIMEOUT) {
      // We've waited for at least the specified timeout. Break out of the loop.
      break;
    }
  }
}

// Called when the game is about to begin. Clears all players' LEDs.
void onFirstLoop() {
  // Sometimes these commands don't send successfully, so send them twice.
  for (int i = 0; i < 2; i++) {
    for (int i = 0; i < PLAYER_COUNT; i++) {
      // Clear the player's LED.
      clearLed(REMOTE_ADDR[i]);
      // Pause for a short moment.
      delay(500);
    }
  }
}
