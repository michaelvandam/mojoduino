#include <FiniteStateMachine.h> 
#include <mojo.h> 
#include "HardwareSerialRS485.h"

#include "AMComm.h"  // AllMotion communication control library
/*
* PRM Parameters
*/
const char BADZ[] = "?LOWERZ";
const char UPRESP[] = "UP";
const char DOWNRESP[] = "DOWN";
const char XERR[] = "?XERR";
const long MOTORCTRLTIMEOUT = 10000;

enum XPosition {HOME, POSITION1, POSITION2, POSITION3};

enum ZPosition {UP, DOWN};

XPosition xpos = HOME;
ZPosition zpos = DOWN;

AMComm MotorCtrl = AMComm(Serial1RS485, '1'); //Device at address '1'
AMComm TempCtrl = AMComm(Serial1RS485, '2');  //Device at address '2'
  
/* 
* PRM States
*/

//X Motion State
State XMoving = State(xstartmove, xmoving, movecomplete);
State XError = State(xerror);

//Z Motion State
State ZMoving = State(zstartmove, zmoving, movecomplete);


State XStartup = State(initialX);
State ZStartup = State(initialZ);

// Motion Standby States
State MotionStandby = State(motionstandby);


/* 
* Create PRM FSMs
*/
FSM PRMMotionX = FSM(XStartup);
FSM PRMMotionZ = FSM(ZStartup);



/*
* Parsing Functions
*/

boolean isGo(char *param) {
    if (strcmp(param, GOPARAM) == 0) 
        return true;
    return false;
}

boolean isEmpty(char *param) {
    if (strlen(param)==0)
        return true;
    return false;
}

boolean isValidXPosition( int pos) {
  if (HOME <= (XPosition)pos && (XPosition)pos <= POSITION3)
    return true;
  return false;
}

boolean isUp() {
  if (zpos == UP)
    return true;
  return false;
}

boolean isMoving() {
  if (PRMMotionX.isInState(XMoving) || PRMMotionZ.isInState(ZMoving))
    return true;
  return false;
  
}

void processXMotionParam(Command& cmd ) {
    int pos;
    char *param = cmd.getParam();
    
    if (isMoving()) {  // Can't move if already moving
       cmd.setReply(BUSYRESP);
       
   } else if(isUp()) { // Can't move if UP
       cmd.setReply(BADZ);
   } else if (isEmpty(param)) {  // Return current position
         if (PRMMotionX.isInState(XError)) {
           cmd.setReply(XERR);
         } else {
           itoa((int)xpos, param, 10);
           cmd.setReply(param);
         }
    } else { // Check that user send valid position then move to it
        
        if (strcmp(param, "HOME")==0) {
          param[0]='0'; param[1]='\0'; 
        }
        
        pos = atoi(param);
        if (isValidXPosition(pos)) {
          xpos = (XPosition)pos;
          PRMMotionX.transitionTo(XMoving);
          cmd.setReply(BUSYRESP);
        } else {
          cmd.setReply(BADPARAM);
        }
    }
}


void processZMotionParam(Command& cmd ) {
    char *param = cmd.getParam();
    
    
    if (isMoving()) {  // Can't move if already moving
       cmd.setReply(BUSYRESP);
    } else if (isEmpty(param)) {
      if(zpos == UP)
        cmd.setReply(UPRESP);
      else
        cmd.setReply(DOWNRESP);
    } else {
        if (strcmp(param, "UP")==0) {
          zpos = UP;
          PRMMotionZ.transitionTo(ZMoving);
          cmd.setReply(BUSYRESP);
          
        } else if (strcmp(param, "DOWN")==0){
          zpos = DOWN;
          PRMMotionZ.transitionTo(ZMoving);
          cmd.setReply(BUSYRESP);
          
        } else {
            cmd.setReply(BADPARAM);
        }
    }
}




/* 
* Callbacks          
*/

//Callback for standby
void cbMoveX( Command &cmd ) {
  // Read param - determin postion then go to moving state!
  processXMotionParam(cmd);
}

void cbMoveZ( Command &cmd ) {
  // Read param - determin postion then go to moving state!
  processZMotionParam(cmd);
}



void setup()
{
  
  
  /*** SETUP MOJO COMMUNICATOR  ***/
  mojo.setSerial(Serial);  //Set which serial to listen on
  mojo.loadBaudrateEEPROM(); //Load baudrate from EEPROM
  mojo.loadAddressEEPROM(); //Load address from EEPROM
  
  /*** ATTACH CALLBACKS HERE ***/
  addCallback("PX", cbMoveX);
  addCallback("PZ", cbMoveZ);
  
  /*** ATTACH DEFAULT CALLBACKS ***/
  setupDefaultCallbacks(); 
  
  /*** ADDITIONAL PRM SETUP CODE ***/
  Serial1RS485.begin(9600);
  //Serial1RS485.begin(9600);
  Serial1RS485.setControlPin(2);
  MotorCtrl.setTimeout(MOTORCTRLTIMEOUT);  //Set timeout to 5sec
  
}

void loop() {
  mojo.run(); // Run mojo communicator 
  PRMMotionX.update(); // Run RDM
  PRMMotionZ.update(); // Run RDM
}


/*** UTILITY FUNCTIONS FOR FSM ***/

void xstartmove() {
  //Serial.println("Start moving X");
  // Send command to move to Xpos then auto transition to moving state
  moveToXPosition();
}

void xmoving() {

    //Serial1.println("XMoving");
    //MotorCtrl.sendQuery();    
    MotorCtrl.receive();
        
    if ( MotorCtrl.messageReady()) {
        
       if (MotorCtrl.isBusy()==false)
          PRMMotionX.transitionTo(MotionStandby);
     } else {
       MotorCtrl.sendQuery();
     }
     
     if (MotorCtrl.isInTimeout()) {
       PRMMotionX.transitionTo(XError);
     }
     
}


void zstartmove() {
  //Serial.println("Start moving Z");
  // Change valve state
  moveToZPosition();
}

void zmoving() {
  //Serial.println("Moving Z");
  // If we have sensors poll till in position otherwise ....
  PRMMotionZ.transitionTo(MotionStandby);
}

void movecomplete() {
  //Serial.println("Move Complete");
  // Do clean up stuff - probably nothing
}

void motionstandby() {
   // Empty Message - do nothing
}


// Function to move to X Positions (will send commands on USART!)
void moveToXPosition() {
  switch(xpos) {
    case HOME:
      MotorCtrl.send("Z4000000z0aE42680aC50au1000n8R");
      //Send command to home
      break;
    case POSITION1:
      MotorCtrl.send("A10000R");
      //Send command to goto pos 1
      break;
    case POSITION2:
      MotorCtrl.send("A20000R");
      //Send command to goto pos 2
      break;
    case POSITION3:
      MotorCtrl.send("A30000R");
      //Send command to goto pos 3
      break;
    default:
      break;
  }
}

// Function to move to Z Positions (will change valve states!)
void moveToZPosition() {
  switch(zpos) {
    case UP:
      //Serial.println("Go up");
      //Send command to go UP
      break;
    case DOWN:
      //Serial.println("Go down");
      //Send command to go UP
      break;
    default:
      break;
  }
}


void initialX() {
  xpos = HOME;
  PRMMotionX.transitionTo(XMoving);  
}

void initialZ() {
  zpos = DOWN;
  PRMMotionZ.transitionTo(ZMoving);
}

void xerror() {
  // Probably send terminate here...
}
