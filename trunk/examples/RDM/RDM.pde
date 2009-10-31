#include <FiniteStateMachine.h>
#include <mojo.h>

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

/* 
* Create RDM FSM
*/
FSM RDM = FSM(standby);


/*
* Parsing Functions
*/




/* 
* Callbacks          
*/

//Callback for standby
void cbStandby( Command &cmd ) {
  RDM.transitionTo(standby);
  cmd.setReply(DONERESP);
}

//Callback for running
void cbDeliver( Command &cmd ) {
  char *param = cmd.getParam();
  int index = atoi(param);
   if ((index <= NONE)||(index>REAGENT4)) {
     SelectedReagent = NONE;
     cmd.setReply(BADPARAM);
   } else {
     SelectedReagent = (Reagent)index;
     RDM.transitionTo(delivering);
    cmd.setReply(param);
  }
}

//Callback for clean
void cbClean( Command &cmd ) {
  RDM.transitionTo(cleaning);
  cmd.setReply(DONERESP);
}

//Callback loading
void cbLoad( Command &cmd ) {
  RDM.transitionTo(loading);
  cmd.setReply(DONERESP);
}

void setup()
{
  /*** SETUP MOJO COMMUNICATOR  ***/
  mojo.setSerial(Serial);  //Set which serial to listen on
  mojo.loadBaudrateEEPROM(); //Load baudrate from EEPROM
  mojo.loadAddressEEPROM(); //Load address from EEPROM
  
  /*** ATTACH CALLBACKS HERE ***/
  addCallback("STDBY", cbStandby);
  addCallback("DELVR", cbDeliver);
  addCallback("CLEAN", cbClean);
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
 
   

   

