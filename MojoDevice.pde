#include "mojo.h"

void Hello( Command &cmd ) {
  Serial.println("Hello, World!");
  cmd.setReply("WORLD!");
}

void setup()
{
  //Serial.begin(9600);
  mojo.setSerial(Serial);
  mojo.loadBaudrate();
  mojo.loadAddress();
  addCallback("HELLO", Hello);
  setupDefaultCallbacks();
}

void loop() {
  mojo.run();
}
