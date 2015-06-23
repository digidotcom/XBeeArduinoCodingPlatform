/* This program implements a simple hide and seek game. An XBee will
 * be attached to the Arduino on an XBee shield.  This code will
 * periodically send an ATDB (RSSI) command to another XBee being
 * sought and display the received signal value on six LEDs attached
 * to digital outputs.
 *
 * For convenience, the six LEDS are assumed to be attached to digital
 * pins eight through thirteen.  These pin indices are used directly.
 * Use of different pins is left as an exercise to the reader.
 *
 * This code is written assuming use of an Arduino Leonardo and access
 * to the hardware serial port 'Serial1'.  It will need to be modified
 * slightly if you choose to use a software serial port or another
 * variant of Arduino.
 */

// Uses the 'xbee-arduino' library.
// https://code.google.com/p/xbee-arduino/
#include <XBee.h>

// Uncomment the line below to include activity logging of this application to the
// serial port of your Arduino Leonardo
//#define SERIAL_LOG 1

XBee xbee = XBee();

// The address of the remote XBee that we're seeking
XBeeAddress64 remote = XBeeAddress64(0x0013a200, 0x40c179e1);

// The command to send to the remote XBee
uint8_t db_command[] = { 'D', 'B' };

// RSSI values that will light progressive LEDS based on signal strength.
// Signals can take on ranges of:
//      XBee: 23 - 92
//      XBee-PRO: 36 - 100
// The range here uses the outliers of both, so will work, but this
//can be improved if you know the family you've selected.
int led_breaks[] = { 100, 87, 74, 62, 49, 36 };

// Track the last time we requested RSSI so we can send periodically.
unsigned long last_sent;

void setup() {

#ifdef SERIAL_LOG
  // Wait for serial to attach
  Serial.begin(9600);
  while (!Serial) ;
#endif

  // Open the local serial port and tell the xbee-arduino library to
  // use it for XBee traffic.
  Serial1.begin(9600);
  xbee.begin(Serial1);

  // Configure LED pins, start them off
  for (int i = 8 ; i <= 13 ; i++) {
    pinMode(i, OUTPUT);
    digitalWrite(i, LOW);
  }
  // Turn 8 on as an indication that the sketch is running
  digitalWrite(8, HIGH);

  // Perform our first signal request
  requestRssi();
}

void loop() {
  // Find out if a packet is available
  xbee.readPacket();

  if (xbee.getResponse().isAvailable()) {
    // Process any packets received
    switch (xbee.getResponse().getApiId()) {
    case REMOTE_AT_COMMAND_RESPONSE:
      // Send any AT response off to be handled (we only care about DB though)
      processAtResponse();
      break;
    default:
#ifdef SERIAL_LOG
      // Our code doesn't care about any other packet so inform the
      // serial monitor in case someone is interested and proceed.
      Serial.print("Got unhandled API frame: ");
      Serial.println(xbee.getResponse().getApiId());
#endif

      break;
    }
  }

  if (xbee.getResponse().isError()) {
#ifdef SERIAL_LOG
    // On error we have no sophisticated handling strategy, so inform
    // the serial monitor and continue.
    Serial.print("Error: ");
    Serial.println(xbee.getResponse().getErrorCode());
#endif
  }

  // Generate requests once per second.
  if (millis() - last_sent > 1000) {
    requestRssi();
  }
}

void processAtResponse() {
  // Get the response details out of the packet.
  RemoteAtCommandResponse rsp = RemoteAtCommandResponse();
  xbee.getResponse().getRemoteAtCommandResponse(rsp);

  // Check if this is a DB response (only thing we expect)
  if (memcmp(db_command, rsp.getCommand(), 2) == 0) {

    uint8_t status = rsp.getStatus();
#ifdef SERIAL_LOG
    if (status != 0) {
      Serial.println("Error status");
      Serial.println(status);
    }
#endif

    uint8_t rssi = 255;
    if (status == 0) {
      // getValue returns a pointer to array of uint8_t.  We know that
      // on success for ATDB the RSSI will be present in the first (and
      // only) position.
      rssi = *rsp.getValue();
      if (rsp.getValueLength() != 1) {
        /* A failed response does not contain the payload as expected,
         * turn off all the LEDs by indicating worst case RSSI.
         */
#ifdef SERIAL_LOG
        Serial.println("Bad value length");
#endif
        rssi = 255;
      }
#ifdef SERIAL_LOG
      // Record signal to serial monitor
      Serial.println(rssi);
#endif
    }

    /* Progressively light LEDs based on signal thresholds. Low DB
     * response values indicate better signal strength as the value is
     * the absolute value of negative dBm.
     */
    for (int i = 0 ; i < 6 ; i++) {
      if (rssi < led_breaks[i]) {
        digitalWrite(i+8, HIGH);
      } else {
         digitalWrite(i+8, LOW);
      }
    }
  }
}

// Create and send an ATDB request to the remote XBee
void requestRssi() {
  RemoteAtCommandRequest req = RemoteAtCommandRequest(remote, db_command);
#ifdef SERIAL_LOG
  Serial.println("Making RSSI request");
#endif
  xbee.send(req);
  last_sent = millis();
}
