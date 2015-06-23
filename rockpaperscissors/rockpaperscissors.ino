/* This program implements a simple rock-paper-scissors game. An XBee will be
 * attached to the Arduino on an XBee shield. The Arduino will 'count down'
 * until it is ready for players to choose either rock, paper, or scissors.
 * Once both players have made a selection, their selections will be revealed
 * and the winner indicated.
 *
 * This code is written assuming use of an Arduino Leonardo and access to the
 * hardware serial port 'Serial1'.  It will need to be modified slightly if you
 * choose to use a software serial port or another variant of Arduino.
 */

// Uses the 'xbee-arduino' library.
// https://code.google.com/p/xbee-arduino/
#include <XBee.h>

// Constant values to specify player selections.
#define NO_CHOICE 0
#define ROCK 1
#define PAPER 2
#define SCISSORS 4

// Digital I/O pins on the remote XBees. Change if necessary.
#define ROCK_PIN 1
#define PAPER_PIN 2
#define SCISSORS_PIN 3

// Declares which I/O pins on the Arduino correspond to the LEDs for each player.
int pins[2][3] = {
  { 2, 3, 4 }, // Player 1: Rock, Paper, Scissors
  { 5, 6, 7 }  // Player 2: Rock, Paper, Scissors
};

// Used to determine which player an I/O packet corresponds to.
const uint16_t PLAYER1_XBEE_ADDR = 0x1235;
const uint16_t PLAYER2_XBEE_ADDR = 0x1236;

XBee xbee = XBee();

int player1 = NO_CHOICE,
    player2 = NO_CHOICE;

//===============================
// Utility functions

void clearAll() {
  for (int i = 0; i < 3; i++) {
    digitalWrite(pins[0][i], LOW);
    digitalWrite(pins[1][i], LOW);
  }
}
void turnAllOn() {
  for (int i = 0; i < 3; i++) {
    digitalWrite(pins[0][i], HIGH);
    digitalWrite(pins[1][i], HIGH);
  }
}
int choiceToPinIndex(int choice) {
  switch (choice) {
    case ROCK:
      return 0;
    case PAPER:
      return 1;
    case SCISSORS:
      return 2;
    default:
      return -1;
  }
}

/**
 * Pre-game light show, a countdown. Goes like this:
 * [x] [ ] [ ]
 * [x] [ ] [ ]
 * (delay)
 * [ ] [x] [ ]
 * [ ] [x] [ ]
 * (delay)
 * [ ] [ ] [x]
 * [ ] [ ] [x]
 * (delay)
 * [x] [x] [x]
 * [x] [x] [x]
 *
 * Analogous to shouting "rock, paper, scissors" before playing.
 */
void pregame() {
  // Clear out all the pins.
  clearAll();
  delay(300);

  // Initiate a "countdown." Start with the first pair of LEDs.
  for (int i = 0; i < 3; i++) {
    digitalWrite(pins[0][i], HIGH);
    digitalWrite(pins[1][i], HIGH);

    delay(250);

    digitalWrite(pins[0][i], LOW);
    digitalWrite(pins[1][i], LOW);
  }

  // Now that we're ready, turn all the LEDs on.
  turnAllOn();

  player1 = player2 = NO_CHOICE;
}

int getChoiceFromResponse(Rx16IoSampleResponse response) {
  boolean rock, paper, scissors;

  rock = !response.isDigitalOn(ROCK_PIN, 0);
  paper = !response.isDigitalOn(PAPER_PIN, 0);
  scissors = !response.isDigitalOn(SCISSORS_PIN, 0);

  // If only one is active, then return that.
  if (rock && !(paper || scissors)) return ROCK;
  if (paper && !(rock || scissors)) return PAPER;
  if (scissors && !(rock || paper)) return SCISSORS;

  // None are active, or more than one is active.
  return NO_CHOICE;
}

/**
 * Make the LED for the given choice flash a few times, to indicate they won.
 * If `player` is -1, it is assumed that both players tied, and so the same LED
 * for both players will be flashed.
 */
void presentWinner(int player, int choice) {
  int pin = choiceToPinIndex(choice);
  boolean writeLow = true;

  int i = 0;
  do {
    if (player < 0) {
      digitalWrite(pins[0][pin], writeLow ? LOW : HIGH);
      digitalWrite(pins[1][pin], writeLow ? LOW : HIGH);
    } else {
      digitalWrite(pins[player][pin], writeLow ? LOW : HIGH);
    }

    writeLow = !writeLow;
    delay(250);
  } while (++i < 4);
}

//=============================
// Required Arduino functions

void setup() {
  // Turn all the necessary pins to OUTPUT mode
  for (int i = 0; i < 2; i++) {
    for (int j = 0; j < 3; j++) {
      pinMode(pins[i][j], OUTPUT);

      // Also turn them all off
      digitalWrite(pins[i][j], LOW);
    }
  }

  // Set up the XBee interface.
  Serial1.begin(9600);
  xbee.begin(Serial1);

  // Start the game.
  pregame();
}

void loop() {
  if (player1 == NO_CHOICE || player2 == NO_CHOICE) {
    // At least one player has not made a selection yet.
    xbee.readPacket(100);

    if (xbee.getResponse().isAvailable() && xbee.getResponse().getApiId() == RX_16_IO_RESPONSE) {
      // And it's an IO sample response.
      Rx16IoSampleResponse response = Rx16IoSampleResponse();
      xbee.getResponse().getRx16IoSampleResponse(response);

      // Determine if this data is from one of the players in this game.
      int *player;

      switch (response.getRemoteAddress16()) {
        case PLAYER1_XBEE_ADDR:
          player = &player1;
          break;
        case PLAYER2_XBEE_ADDR:
          player = &player2;
          break;
        default:
          // IO sample from the XBee on the shield, or some other XBee on this
          // network.
          return;
      }

      int choice = getChoiceFromResponse(response);
      if (choice == NO_CHOICE || *player != NO_CHOICE) {
        // No buttons are being pushed, or the player has already made a
        // selection.
        return;
      }

      // Set the player's selection.
      *player = choice;
    }
  } else {
    // Both players have made a selection.

    // Clear all LEDs.
    clearAll();

    // Turn on the LEDs for each player.
    digitalWrite(pins[0][choiceToPinIndex(player1)], HIGH);
    digitalWrite(pins[1][choiceToPinIndex(player2)], HIGH);

    // Decide who won.
    int winner = -1;

    if (player1 == ROCK && player2 == SCISSORS ||
        player1 == SCISSORS && player2 == PAPER ||
        player1 == PAPER && player2 == ROCK) {
      winner = 0;
    } else if (player1 != player2) {
      // Both players had a different hand, and Player 1 wasn't the winner... hence player 2 wins.
      winner = 1;
    }

    // Indicate who won. If `winner` is -1, both player's LEDs will flash.
    presentWinner(winner, (winner ? player2 : player1));

    // Wait a moment.
    delay(1500);

    // Start another round.
    pregame();
  }
}
