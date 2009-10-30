//#include <EEPROM.h>  // <-- Doesn't work with this commented out

#include "mojo.h"
#include "mojodispatch.h"
#include "mojocallbacks.h"

void Hello( Command &cmd ) {
  Serial.println("Hello, World!");
  cmd.setReply("WORLD!");
}

void setup()
{
  Serial.begin(9600);
  mojo.setSerial(Serial);
  mojo.setAddress('a');
  addCallback("HELLO", Hello);
  setupDefaultCallbacks();
}

void loop() {
  mojo.run();
}
