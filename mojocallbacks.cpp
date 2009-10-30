
#include "mojo.h"
#include "mojocallbacks.h"
#include "mojodispatch.h"
#include "mojoresponses.h"
#include <string.h>
#include <ctype.h>


void id( Command &cmd ) {
  char *newId;
  
  newId = cmd.getParam();  //Grab the id
  if (strlen(newId) == 0)  {  // What is my id?
    cmd.setReply(mojo.getAddress());
  } else if ( !(isprint(newId[0])) || (newId[0] == BROADCASTADDY) ||  !(strlen(newId) == 1) ) {  //Id must be printable, not broadcast and not longer than 1
    cmd.setReply(BADPARAM);
  } else {
    cmd.setReply(newId);
    mojo.setAddress(newId[0]);
    //Add eeprom here too!
    //Serial.println("Set ID!");
  }
}

void baud( Command &cmd ) {
  Serial.println("Set Baud");
  cmd.setReply(cmd.getParam());
}

void savebaud( Command &cmd ) {
  Serial.println("Save Baud");
  //Put baud into EEPROM
  cmd.setReply(cmd.getParam());
}

void who( Command &cmd ) {
  cmd.setReply(DEVICEID);
}

void annc( Command &cmd ) {
  long t = 50;
  t = t * mojo.getAddress();
  delay(t);
  //Serial.println("Delay then announce");
  who(cmd);
}

void setupDefaultCallbacks() {
  addCallback("ID", id);
  addCallback("BAUD", baud);
  addCallback("SAVBAUD", savebaud);
  addCallback("WHO", who);
  addCallback("ANNC", annc);
}






