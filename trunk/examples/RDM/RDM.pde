#include <FiniteStateMachine.h>
#include <mojo.h>
#include "HardwareSerialRS485.h"


byte ledPin = 13;
byte valve1Clean = 31;
byte valve1Lower= 47;
byte valve2Clean = 29;
byte valve2Lower = 45;
byte valve3Clean = 27;
byte valve3Lower = 43;
byte valve4Clean = 25;
byte valve4Lower = 41;
byte valveVentPress = 23;
byte valveWaste = 39;
byte OPEN = HIGH;
byte CLOSE = LOW;
byte wasteState = CLOSE;

boolean resetDeliverValves = false;
boolean resetCleanValves = false;


/*
* RDM Parameters
*/
enum Reagent{
  NONE=0,
  REAGENT1=1,
  REAGENT2=2,
  REAGENT3=3,
  REAGENT4=4,
  ALL=5
};

Reagent SelectedReagent = NONE;
Reagent SelectedCleanReagent = NONE;


/* 
* RDM States
*/
State standby = State(gostandby, doNothing, doNothing);
State delivering = State(godeliver);
State loading = State(goload);
State cleaning =State(goclean);
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

boolean isPSTR(const char *param, PGM_P pstr) {
 if (strcmp_P(param, pstr) == 0) 
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
          cmd.setReply_P(TRUERESP);
        } else {
          cmd.setReply_P(FALSERESP);
        }
    
    } else if (isPSTR(param,GOPARAM)) {
    
        RDM.transitionTo(state);
        cmd.setReply_P(DONERESP);
    
    } else {
        cmd.setReply_P(BADPARAM);
    }
}

/* 
* Callbacks          
*/

//Callback for standby
void cbStandby( Command &cmd ) {
  processSimpleStateParam(standby, cmd);
}

//Callback loading
void cbLoad( Command &cmd ) {
  processSimpleStateParam(loading, cmd);
}

//Callback for running
void cbDeliver( Command &cmd ) {
  char *param = cmd.getParam();
  
  if (isPSTR(param, ALLRESP)) {
    SelectedReagent = ALL;
    resetDeliverValves = true;
    RDM.transitionTo(delivering);
    cmd.setReply(param);
  } else {
    int index = atoi(param);
     if ((index <= NONE)||(index>REAGENT4)) {
       SelectedReagent = NONE;
       cmd.setReply_P(BADPARAM);
     } else if (isEmpty(param)) {
       itoa((int)SelectedReagent, param, 10);
       cmd.setReply(param);
     } else {
       SelectedReagent = (Reagent)index;
       resetDeliverValves = true;
       RDM.transitionTo(delivering);
      cmd.setReply(param);
     }
  }
}

//Callback for clean
void cbClean( Command &cmd ) {
  char *param = cmd.getParam();

  int index = atoi(param);
   if ((index <= NONE)||(index>REAGENT4)) {
     SelectedCleanReagent = NONE;
     cmd.setReply_P(BADPARAM);
   } else if (isEmpty(param)) {
     itoa((int)SelectedCleanReagent, param, 10);
     cmd.setReply(param);
   } else {
     SelectedCleanReagent = (Reagent)index;
     resetCleanValves = true;
     RDM.transitionTo(cleaning);
    cmd.setReply(param);
  }
}

void cbWaste( Command &cmd ) {
  char * param = cmd.getParam();
  
  if (isEmpty(param)) {
    if (wasteState==OPEN) 
      cmd.setReply_P(OPENPARAM);
    else
      cmd.setReply_P(CLOSEPARAM);
  } else if (isPSTR(param,OPENPARAM)) {
      wasteState = OPEN;
      digitalWrite(valveWaste,wasteState);
      cmd.setReply_P(OPENPARAM);
  } else if (isPSTR(param,CLOSEPARAM)) {
      wasteState = CLOSE;
      digitalWrite(valveWaste,wasteState);
      cmd.setReply_P(CLOSEPARAM);
  } else {
    cmd.setReply_P(BADPARAM);
  }
  
}



void setup()
{
  
  /*** SETUP MOJO COMMUNICATOR  ***/
  mojo.setDeviceType_P(PSTR("RDM-V0.1"));
  SerialRS485.setControlPin(4);
  mojo.setSerial(SerialRS485);  //Set which serial to listen on
  
  mojo.loadBaudrateEEPROM(); //Load baudrate from EEPROM
  mojo.loadAddressEEPROM(); //Load address from EEPROM
  /*** ATTACH DEFAULT CALLBACKS ***/
  setupDefaultCallbacks(); 
  /*** ATTACH CALLBACKS HERE ***/
  addCallback("STDBY", cbStandby);
  addCallback("DELVR", cbDeliver);
  addCallback("CLEAN", cbClean);
  addCallback("WASTE", cbWaste);
  addCallback("LOAD", cbLoad);

  pinMode(13,OUTPUT);
  for(int i=23; i<53;i=i+2) {
  pinMode(i,OUTPUT);
  digitalWrite(i,LOW);
  
  }
  /*** ADDITIONAL RDM SETUP CODE ***/
}

void loop() {
  mojo.run(); // Run mojo communicator 
  RDM.update(); // Run RDM
}


/*** UTILITY FUNCTIONS FOR FSM ***/
void vent() {
  digitalWrite(valveVentPress,CLOSE);
}

void pressurize() {
  digitalWrite(valveVentPress,OPEN);
}
void closeall() {
    static int stat = 1;
    if(stat == 1) {
      digitalWrite(13,LOW);
      stat = 0;
    } else {
      digitalWrite(13,HIGH);
      stat=1;
    }
    
    for(int i=23;i<53;i=i+2) {
    digitalWrite(i,LOW);
    }
}

void closeCleaningValves() {
  digitalWrite(valve1Clean,LOW);
  digitalWrite(valve2Clean,LOW);
  digitalWrite(valve3Clean,LOW);
  digitalWrite(valve4Clean,LOW);
}

void closeDeliverValves() {
  digitalWrite(valve1Lower,LOW);
  digitalWrite(valve2Lower,LOW);
  digitalWrite(valve3Lower,LOW);
  digitalWrite(valve4Lower,LOW);
}

void deliverReagent() {
    closeCleaningValves();
    if(resetDeliverValves == true) {
      closeDeliverValves();
      resetDeliverValves=false;
    }
  
    switch(SelectedReagent) {
      case NONE:
        break;
      case REAGENT1:
        //OPEN VALVE REAGENT1
        digitalWrite(valve1Lower,OPEN);
        pressurize();
        break;
      case REAGENT2:
        //OPEN VALVE REAGENT2
        digitalWrite(valve2Lower,OPEN);
        pressurize();
        break;
      case REAGENT3:      
        //OPEN VALVE REAGENT3
        digitalWrite(valve3Lower,OPEN);
        pressurize();
        break;
      case REAGENT4:
        //OPEN VALVE REAGENT4
        digitalWrite(valve4Lower,OPEN);
        pressurize();
        break;
      case ALL:
        digitalWrite(valve1Lower,OPEN);
        digitalWrite(valve2Lower,OPEN);
        digitalWrite(valve3Lower,OPEN);
        digitalWrite(valve4Lower,OPEN);
        pressurize();
        break;
      default:
        // OOPS?
        break;
  }
}


void cleanReagent() {
    if(resetCleanValves == true) {
      closeCleaningValves(); 
      resetCleanValves=false;
    }
    
    switch(SelectedCleanReagent) {
      case NONE:
        break;
      case REAGENT1:
        vent();
        digitalWrite(valve1Clean,OPEN);
        //OPEN CLEAN VALVE REAGENT1
        break;
      case REAGENT2:
        vent();
        digitalWrite(valve2Clean,OPEN);
        //OPEN CLEAN VALVE REAGENT2
        break;
      case REAGENT3:
        vent();
        digitalWrite(valve3Clean,OPEN);
        //OPEN CLEAN VALVE REAGENT3
        break;
      case REAGENT4:
        vent();
        digitalWrite(valve4Clean,OPEN);
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
  //    closeall();
  closeCleaningValves();
  vent();
  closeDeliverValves();
    
}

void godeliver() {  
  //OPEN VALVE TO PRESSURE
  deliverReagent();
}

void godeliverstandby() {
  //DO NOTHING!!!
}


void goclean() {
  //OPEN VALVE TO VENT
  cleanReagent();
}

void goload() { 
  //Open to vent
  //Close Reagent valves
  closeCleaningValves();
  vent();
  closeDeliverValves();

}
 
void doNothing() {
}


   

