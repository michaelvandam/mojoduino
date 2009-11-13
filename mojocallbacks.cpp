
#include "mojo.h"
#include "mojocallbacks.h"
#include "mojodispatch.h"
#include "mojoresponses.h"
#include <string.h>
#include <ctype.h>
#include <stdlib.h>

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
  long baudSelect;
  char *param;
  int i=0;
  
  param = cmd.getParam();
  
  if (strlen(param)==0) {
    cmd.setReply(mojo.getBaudrate());
    return;
  }
  
  baudSelect = atol(param);
  
  while(i < BAUDRATELEN) {
    if(baudSelect==baudRates[i]) {
      break;
    }
    i++;
  }
  
  
  if (i == BAUDRATELEN) {
    cmd.setReply(BADPARAM);  
  } else {
    Serial.println(baudRates[i]);
    mojo.setBaudrate(i);
    cmd.setReply(param);
  }  
}


void savebaud( Command &cmd ) {
  //Put baud into EEPROM
  mojo.saveBaudrateEEPROM();
  cmd.setReply(DONERESP);
}

void who( Command &cmd ) {
  cmd.setReply(mojo.getDeviceType());
}

void annc( Command &cmd ) {
  long t = 5;
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







