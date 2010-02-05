#include <FiniteStateMachine.h>
#include "mojo.h"

int ledPin = 13;

//RDM States
State standby = State(gostandby);
State running = State(gorun);
State loading = State(goloading);

//Create RDM FSM
FSM RDM = FSM(standby);

//Example callback
void Hello( Command &cmd ) {
  Serial.println("Hello, World!");
  cmd.setReply("WORLD!");
}

//Callback for standby
void cbStandby( Command &cmd ) {
  RDM.transitionTo(standby);
  //cmd.setReply(DONERESP);
}

//Callback for running
void cbRun( Command &cmd ) {
  RDM.transitionTo(running);
  //cmd.setReply(DONERESP);
}

//Callback loading
void cbLoad( Command &cmd ) {
  RDM.transitionTo(loading);
  //cmd.setReply(DONERESP);
}

void setup()
{
  /*** SETUP MOJO COMMUNICATOR  ***/
  mojo.setSerial(Serial);  //Set which serial to listen on
  mojo.loadBaudrateEEPROM(); //Load baudrate from EEPROM
  mojo.loadAddressEEPROM(); //Load address from EEPROM
  
  /*** ATTACH CALLBACKS HERE ***/
  addCallback("HELLO", Hello); //Add Hello callback
  addCallback("STDBY", cbStandby);
  addCallback("RUN", cbRun);  
  addCallback("LOAD", cbLoad);  
  
  /*** ATTACH DEFAULT CALLBACKS ***/
  setupDefaultCallbacks(); 
  
  /*** ADDITIONAL RDM SETUP CODE ***/
  pinMode(ledPin,OUTPUT);
}

void loop() {
  mojo.run(); // Run mojo communicator 
  RDM.update(); // Run RDM
}


/*** UTILITY FUNCTIONS FOR FSM ***/
void gostandby() {  digitalWrite(ledPin, LOW); }

void gorun() {  digitalWrite(ledPin, HIGH); }

void goloading() { 
    static int state = HIGH;
    static long previousMillis;
    long interval = 1000; 
     
     
    if (millis() - previousMillis > interval) {
      previousMillis = millis();
      if (state == LOW)
          state = HIGH;
      else
          state = LOW;
      
      digitalWrite(ledPin, state);
    }
}
 
   
   
