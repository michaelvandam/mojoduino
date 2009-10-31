#include <FiniteStateMachine.h>
#include <mojo.h>

/*
* CPM Parameters
*/
enum Reagent{
  NONE=0,
  WASH=1,
  SAMPLE=2,
  ELUTE=3,
};

Reagent SelectedReagent = NONE;


/* 
* CPM States
*/

State standby = State(gostandby);
State delivering = State(godeliver);
State cleaning = State(goclean);
State loadingSample = State(goloadsample);
State loadingReagents = State(goloadreagents);
State trapping = State(gotrap);
State washing = State(gowash);
State eluting = State(goelute);


/* 
* Create CPM FSM
*/
FSM CPM = FSM(standby);


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
        //Check current state
        cmd.setReply("?");
    
    } else if (isGo(param)) {
    
        CPM.transitionTo(state);
        cmd.setReply(DONERESP);
    
    } else {
        cmd.setReply(BADPARAM);
    }
}

void processSelectParam( State& state, Command& cmd ) {
  char *param = cmd.getParam();
  int index = atoi(param);
   if ((index <= NONE)||(index>ELUTE)) {
     SelectedReagent = NONE;
     cmd.setReply(BADPARAM);
   } else if (isEmpty(param)) {
     itoa((int)SelectedReagent, param, 10);
     cmd.setReply(param);
   } else {
     SelectedReagent = (Reagent)index;
     CPM.transitionTo(state);
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
    processSelectParam(delivering,cmd);
}

//Callback for clean
void cbClean( Command &cmd ) {
    processSelectParam(cleaning,cmd);
}

//Callback loading sample
void cbLoadSamp( Command &cmd ) {
  processSimpleStateParam(loadingSample, cmd);
}

//Callback loading reagents
void cbLoadReagents( Command &cmd ) {
  processSimpleStateParam(loadingReagents, cmd);
}


//Callback trapping
void cbTrap( Command &cmd ) {
    processSimpleStateParam(trapping, cmd);
}

//Callback washing
void cbWash( Command &cmd ) {
  processSimpleStateParam(washing, cmd);
}

//Callback eluting
void cbElute( Command &cmd ) {
    processSimpleStateParam(eluting, cmd);
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
  addCallback("LDSAMP", cbLoadSamp);
  addCallback("LDRGTS", cbLoadReagents);
  addCallback("TRAP", cbTrap);
  addCallback("WASH", cbWash);
  addCallback("ELUTE", cbElute);
  
  /*** ATTACH DEFAULT CALLBACKS ***/
  setupDefaultCallbacks(); 
  
  /*** ADDITIONAL RDM SETUP CODE ***/
  
}

void loop() {
  mojo.run(); // Run mojo communicator 
  CPM.update(); // Run CPM
}


/*** UTILITY FUNCTIONS FOR FSM ***/

void deliverReagent() {
    switch(SelectedReagent) {
      case NONE:
        break;
      case WASH:
        //OPEN VALVE REAGENT1
        break;
      case SAMPLE:
        //OPEN VALVE REAGENT2
        break;
      case ELUTE:
        //OPEN VALVE REAGENT3
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
      case WASH:
        //OPEN CLEAN VALVE REAGENT1
        break;
      case SAMPLE:
        //OPEN CLEAN VALVE REAGENT2
        break;
      case ELUTE:
        //OPEN CLEAN VALVE REAGENT3
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

void goloadsample() { 
  //Open to vent
  //Close Reagent valves
}
 
 void goloadreagents() { 
  //Open to vent
  //Close Reagent valves
}
 
void gotrap() { 
  //Open to vent
  //Close Reagent valves
}
   
void gowash() { 
  //Open to vent
  //Close Reagent valves
}

void goelute() { 
  //Open to vent
  //Close Reagent valves
}   

