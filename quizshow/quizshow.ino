/* This program implements a simple quiz show buzzer. An XBee will be attached
 * to the Arduino on an XBee shield. This code will allow a 'host' to use
 * buttons connected to the Arduino to drive different game states. There are
 * distinct states for reading a question (which can be used as a general
 * 'paused' state), waiting for players to buzz in, and a player being buzzed
 * in.
 *
 * Players 'buzz in' by grounding a specific digital input pin on their remote
 * XBee nodes. This will typically be done by pressing a button. Once a player
 * buzzes in and answers the question, the host can record their answer as
 * incorrect (in which case they cannot buzz in until the next question), or as
 * correct (in which case the game resets and the host reads the next
 * question).
 *
 * This code is written assuming use of an Arduino Leonardo and access to the
 * hardware serial port 'Serial1'.  It will need to be modified slightly if you
 * choose to use a software serial port or another variant of Arduino.
 */

// Uses the 'xbee-arduino' library.
// https://code.google.com/p/xbee-arduino/
#include <XBee.h>
#include "QuizShow.h"

XBee xbee = XBee();

// Change these as necessary.
const uint16_t REMOTE_ADDR[] = { 0x1235, 0x1236 }; // MY parameter values of remote nodes
const int LED_PINS[] = {2, 3, 4};
const int STATUS_PIN = 5;
const int BUTTON_PINS[] = {8, 9, 10}; // reset, correct, incorrect.
const int BUZZ_IN_PIN = 1; // DIO1

// This array must be kept at least the same length as REMOTE_ADDR.
boolean playerBuzzedIn[] = { false, false, false };

// Do not change these.
const int PLAYER_COUNT = sizeof(REMOTE_ADDR) / sizeof(uint16_t);
QS_State currentState;
int currentPlayer = -1;

void setup() {
  // The game starts in the 'reading question' state. The status LED will pulse
  // until the host presses the green button to move to the answering state.
  resetToQuestion();

  // Configure the output pins on the Arduino.
  for (int i = 0; i < PLAYER_COUNT; i++) {
    pinMode(LED_PINS[i], OUTPUT);
    digitalWrite(LED_PINS[i], LOW);
  }

  // Status LED is off initially.
  pinMode(STATUS_PIN, OUTPUT);
  analogWrite(STATUS_PIN, 0);

  // Configure the input (button) pins on the Arduino.
  for (int i = 0; i < 3; i++) {
    pinMode(BUTTON_PINS[i], INPUT_PULLUP);
  }

  // Open the local serial port and tell the xbee-arduino library to use it for
  // XBee traffic.
  Serial1.begin(9600);
  xbee.begin(Serial1);
}

void loop() {
  // Call one of the do_ methods below, depending on which state the game is in
  // currently.

  switch (currentState) {
    case READING_QUESTION:
      do_reading_question();
      break;
    case READY_FOR_ANSWERS:
      do_ready_for_answers();
      break;
    case BUZZED_IN:
      do_buzzed_in();
      break;
    default:
      // Should only happen if a new state is introduced in QuizShow.h or some
      // bug is introduced in this code.
      break;
  }
}

void do_reading_question() {
  static int pulse_value = 255;
  static int pulse_modifier = -5;

  if (answerCorrectButtonPressed()) {
    // Signal that we're done reading the question.
    currentState = READY_FOR_ANSWERS;

    while (answerCorrectButtonPressed()) {
      // Wait until the button is released. Otherwise, if a team buzzes in
      // quickly, we could immediately accept their answer.
    }
  } else {
    // While reading the question, pulse the status light.

    if (pulse_value == 255) {
      // If the LED is at its brightest, start fading down.
      pulse_modifier = -5;
    }
    if (pulse_value == 0) {
      // If the LED is off, start fading up.
      pulse_modifier = 5;
    }

    // Set the LED brightness.
    pulse_value += pulse_modifier;
    analogWrite(STATUS_PIN, pulse_value);

    // Keep reading in packets from the XBee (and ignoring them).
    xbee.readPacket(10); // 10 ms timeout
  }
}

void do_ready_for_answers() {
  // Turn on the status LED.
  digitalWrite(STATUS_PIN, HIGH);

  if (resetButtonPressed()) {
    // Reset the round.
    resetToQuestion();

    // Wait until the button is released.
    while (resetButtonPressed()) {
      ;
    }

    return;
  }

  // Read a packet off the XBee, or timeout after 5ms.
  xbee.readPacket(5);

  if (xbee.getResponse().isAvailable() && xbee.getResponse().getApiId() == RX_16_IO_RESPONSE) {
    // It's an IO sample.
    Rx16IoSampleResponse response = Rx16IoSampleResponse();
    xbee.getResponse().getRx16IoSampleResponse(response);

    // The xbee-arduino library presents the I/O data as the bytes contained in the packet.
    uint8_t *data = response.getData();
    // The first byte is the number of samples, the next two bytes are the channel bitmask,
    // and the two bytes after that are the digital data.
    unsigned int io = (data[3] << 8) | data[4];

    // First, check that the sample indicates someone buzzing in.
    if (io & (1 << BUZZ_IN_PIN)) {
      // The "buzz-in pin" is unpressed. Ignore this sample.
      return;
    }

    // Determine if this XBee is a known player.
    currentPlayer = -1;
    uint16_t addr = response.getRemoteAddress16();

    for (int i = 0; i < PLAYER_COUNT; i++) {
      // If it's from a known player, and they haven't buzzed in yet...
      if (addr == REMOTE_ADDR[i] && !playerBuzzedIn[i]) {
        // Mark them down as the current answerer.
        currentPlayer = i;
        playerBuzzedIn[i] = true;

        signalBuzzIn();

        // Move to the BUZZED_IN state.
        currentState = BUZZED_IN;
        return;
      }
    }
  }
}

void do_buzzed_in() {
  if (resetButtonPressed() || answerCorrectButtonPressed()) {
    // Reset button, or 'correct' button. Both do the same thing here.

    // Reset to reading the question.
    resetToQuestion();
    resetAllLeds();

    // Wait until the button is released.
    while (resetButtonPressed() || answerCorrectButtonPressed()) {
      ;
    }
  } else if (answerIncorrectButtonPressed()) {
    // This player/team was wrong. Reset to waiting for answers.
    // (Since we don't clear out `playerBuzzedIn`, this player/team will not
    // be able to buzz in until the next question.)
    currentPlayer = -1;
    currentState = READY_FOR_ANSWERS;
    resetAllLeds();

    // Wait until the button is released.
    while (answerIncorrectButtonPressed()) {
      ;
    }
  }
}

//==================================================
// Utility functions
//==================================================

void resetToQuestion() {
  // Reset round.
  currentState = READING_QUESTION;

  // Clear out playerBuzzedIn
  for (int i = 0; i < PLAYER_COUNT; i++) {
    playerBuzzedIn[i] = false;
  }
}
void resetAllLeds() {
  // Turn off all of the individual team LEDs.
  for (int i = 0; i < PLAYER_COUNT; i++) {
    digitalWrite(LED_PINS[i], LOW);
  }
  // Turn off the status LED.
  digitalWrite(STATUS_PIN, LOW);
}

boolean resetButtonPressed() {
  return !digitalRead(BUTTON_PINS[0]);
}
boolean answerCorrectButtonPressed() {
  return !digitalRead(BUTTON_PINS[1]);
}
boolean answerIncorrectButtonPressed() {
  return !digitalRead(BUTTON_PINS[2]);
}

void signalBuzzIn() {
  // Indicate that a player has buzzed in by flashing both the status LED and
  // their individual LED a few times.
  int flashCount = 5;

  for (int i = 0; i < flashCount; i++) {
    digitalWrite(LED_PINS[currentPlayer], HIGH);
    digitalWrite(STATUS_PIN, HIGH);
    delay(100);

    digitalWrite(LED_PINS[currentPlayer], LOW);
    digitalWrite(STATUS_PIN, LOW);
    delay(100);
  }

  // End with the team's LED lit (and the status LED off).
  digitalWrite(LED_PINS[currentPlayer], HIGH);
}
