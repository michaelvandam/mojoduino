#include <FiniteStateMachine.h>
#include <mojo.h>
#include "HardwareSerialRS485.h"

int ledPin = 13;

/*
* RDM Parameters
*/
enum Reagent{
  NONE=0,
  REAGENT1=1,
  REAGENT2=2,
  REAGENT3=3,
  REAGENT4=4
};

Reagent SelectedReagent = NONE;


/* 
* RDM States
*/
State standby = State(gostandby);
State delivering = State(godeliver);
State loading = State(goload);
State cleaning = State(goclean);
State pumping = State(gopump);
/* 
* Create RDM FSM
*/
FSM RDM = FSM(standby);


/*
* Parsing Functions
*/
/*
* Parsing Functions
*/

int isGo(char *param) {
    if (strcmp(param, GOPARAM) == 0) 
        return true;
    return false;
}

int isEmpty(char *param) {
    if (strlen(param)==0)
        return true;
    return false;
}

void processSimpleStateParam( State& state, Command& cmd ) {
    char *param = cmd.getParam();
    if (isEmpty(param)) {
      
        if (RDM.isInState(state)) {
          cmd.setReply(TRUERESP);
        } else {
          cmd.setReply(FALSERESP);
        }
    
    } else if (isGo(param)) {
    
        RDM.transitionTo(state);
        cmd.setReply(DONERESP);
    
    } else {
        cmd.setReply(BADPARAM);
    }
}

void processSelectParam( State& state, Command& cmd ) {
  char *param = cmd.getParam();
  int index = atoi(param);
   if ((index <= NONE)||(index>REAGENT4)) {
     SelectedReagent = NONE;
     cmd.setReply(BADPARAM);
   } else if (isEmpty(param)) {
     itoa((int)SelectedReagent, param, 10);
     cmd.setReply(param);
   } else {
     SelectedReagent = (Reagent)index;
     RDM.transitionTo(state);
    cmd.setReply(param);
  }
}


/* 
* Callbacks          
*/

//Callback for standby
void cbStandby( Command &cmd ) {
  processSimpleStateParam(standby, cmd);
}

//Callback for running
void cbDeliver( Command &cmd ) {
  processSelectParam(delivering, cmd);
}

//Callback for clean
void cbClean( Command &cmd ) {
  processSelectParam(cleaning, cmd);
}

//Callback loading
void cbLoad( Command &cmd ) {
  processSimpleStateParam(loading, cmd);
}

//Callback Pump
void cbPump( Command &cmd ) {
  processSimpleStateParam(pumping, cmd);
}


void setup()
{
  /*** SETUP MOJO COMMUNICATOR  ***/
  Serial1RS485.setControlPin(2);
  mojo.setSerial(Serial1RS485);  //Set which serial to listen on
  
  mojo.loadBaudrateEEPROM(); //Load baudrate from EEPROM
  mojo.loadAddressEEPROM(); //Load address from EEPROM
  
  /*** ATTACH CALLBACKS HERE ***/
  addCallback("STDBY", cbStandby);
  addCallback("DELVR", cbDeliver);
  addCallback("CLEAN", cbClean);
  addCallback("LOAD", cbLoad);  
  addCallback("PUMP", cbPump);
  /*** ATTACH DEFAULT CALLBACKS ***/
  setupDefaultCallbacks(); 
  
  /*** ADDITIONAL RDM SETUP CODE ***/
}

void loop() {
  mojo.run(); // Run mojo communicator 
  RDM.update(); // Run RDM
}


/*** UTILITY FUNCTIONS FOR FSM ***/

void deliverReagent() {
    switch(SelectedReagent) {
      case NONE:
        break;
      case REAGENT1:
        //OPEN VALVE REAGENT1
        break;
      case REAGENT2:
        //OPEN VALVE REAGENT2
        break;
      case REAGENT3:
        //OPEN VALVE REAGENT3
        break;
      case REAGENT4:
        //OPEN VALVE REAGENT4
        break;
      default:
        // OOPS?
        break;
  }
}


void cleanReagent() {
    switch(SelectedReagent) {
      case NONE:
        break;
      case REAGENT1:
        //OPEN CLEAN VALVE REAGENT1
        break;
      case REAGENT2:
        //OPEN CLEAN VALVE REAGENT2
        break;
      case REAGENT3:
        //OPEN CLEAN VALVE REAGENT3
        break;
      case REAGENT4:
        //OPEN CLEAN VALVE REAGENT4
        break;
      default:
        // OOPS?
        break;
  }
}


void gostandby() {  
  //OPEN AIR VALVE TO VENT
  //CLOSE REAGENT VALVES
  }

void godeliver() {  
  //OPEN VALVE TO PRESSURE
  deliverReagent();
}


void goclean() {
  //OPEN VALVE TO VENT
  cleanReagent();
}

void goload() { 
  //Open to vent
  //Close Reagent valves
}
 
void gopump() {
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
   

   

