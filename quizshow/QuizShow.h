enum QS_State {
  // Reading the question, or just "paused".
  READING_QUESTION,
  // Read XBee packets in, waiting for the right signal to arrive.
  // Also (using state tracked elsewhere) ignores buzzes from teams who
  // have already buzzed in.
  READY_FOR_ANSWERS,
  // A team is buzzed in. A timer goes down...
  BUZZED_IN
};
