#include "mojo.h"

void Hello( Command &cmd ) {
  Serial.println("Hello, World!");
  cmd.setReply("WORLD!");
}

void setup()
{
  mojo.setSerial(Serial);
  mojo.loadBaudrateEEPROM();
  mojo.loadAddressEEPROM();
  addCallback("HELLO", Hello);
  setupDefaultCallbacks();
}

void loop() {
  mojo.run();
}