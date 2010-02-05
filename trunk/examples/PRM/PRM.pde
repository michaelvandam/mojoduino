#include <TimedAction.h>
#include <Button.h>
#include <FiniteStateMachine.h> 
#include <mojo.h> 
#include "HardwareSerialRS485.h"
#include "AMComm.h"  // AllMotion communication control library

/*
* PRM Parameters
*/
const char BADZ[] PROGMEM = "?LOWERZ";
const char UPRESP[] PROGMEM = "UP";
const char DOWNRESP[] PROGMEM = "DOWN";
const char XERR[] PROGMEM = "?XERR";
const char ZERR[] PROGMEM = "?ZERR";
const char ON[] PROGMEM = "ON";
const char OFF[] PROGMEM = "OFF";
const long MOTORCTRLTIMEOUT = 10000;

int upPin = 31;
int downPin = 29;

enum XPosition {HOME, POSITION1, POSITION2, POSITION3};

enum ZPosition {UP, DOWN};

XPosition xpos = HOME;
ZPosition zpos = DOWN;

AMComm MotorCtrl = AMComm(Serial3RS485, '1'); //Device at address '1'
//AMComm TempCtrl = AMComm(Serial3RS485, '2');  //Device at address '2'

Button upSensor = Button(54,PULLUP);
Button downSensor = Button(55,PULLUP);

TimedAction zTimeout = TimedAction(8000,gozerror);

/* 
* PRM States
*/

//X Motion State
State XMoving = State(xstartmove, xmoving, movecomplete);
State XError = State(xerror);

//Z Motion State
State ZMoving = State(zstartmove, zmoving, movecomplete);
State ZError = State(standby);

State XStartup = State(initialX);
State ZStartup = State(initialZ);

// Motion Standby States
State MotionStandby = State(motionstandby);

//Transfer States
State TransferOn = State(transferon, standby, standby);
State TransferOff = State(transferoff, standby, standby);

//Cooling States
State CoolOn = State(coolon, standby, standby);
State CoolOff = State(cooloff, standby, standby);


/*
* Up Down buttons
*/
//Button upSensor = Button(54,PULLUP);


/* 
* Create PRM FSMs
*/
FSM PRMMotionX = FSM(XStartup);
FSM PRMMotionZ = FSM(ZStartup);
FSM PRMTransfer = FSM(TransferOff);
FSM PRMCool = FSM(CoolOff);


/*
* Parsing Functions
*/

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

boolean isPSTR(const char *param, PGM_P pstr) {
 if (strcmp_P(param, pstr) == 0) 
    return true;
  return false;
}

/* 
* Callbacks          
*/

//Cool Callback
void cbCool( Command &cmd ) {
  if (isEmpty(cmd.getParam())) {
    if (PRMCool.isInState(CoolOn)) 
      cmd.setReply_P(ON);
    else
      cmd.setReply_P(OFF);
  } else {
    if( isPSTR(cmd.getParam(), ON) ) {
      //Turn On Cool
      cmd.setReply_P(ON);
      PRMCool.transitionTo(CoolOn);
    } else if( isPSTR(cmd.getParam(), OFF)) {
      //Turn Off Cool
      cmd.setReply_P(OFF);
      PRMCool.transitionTo(CoolOff);
    } else {
      cmd.setReply_P(BADPARAM);
    }
  }
  
}

//Transfer Callbacks
void cbTransfer( Command &cmd ) {
  const char *result;
  if (isEmpty(cmd.getParam())) {
    if (PRMTransfer.isInState(TransferOn)) 
      cmd.setReply_P(ON);
    else
      cmd.setReply_P(OFF);
  } else {
    cmd.setReply(cmd.getParam());
    if( isPSTR(cmd.getParam(), ON) ) {
      //Turn On Cool
      cmd.setReply_P(ON);
      PRMTransfer.transitionTo(TransferOn);
    } else if( isPSTR(cmd.getParam(), OFF)) {
      //Turn Off Cool
      cmd.setReply_P(OFF);
      PRMTransfer.transitionTo(TransferOff);
    } else {
      cmd.setReply_P(BADPARAM);
    }
  } 
}


//Callback POSX
void cbMoveX( Command &cmd ) {
  // Read param - determin postion then go to moving state!
    int pos;
    char *param = cmd.getParam();
    
    if (isMoving()) {  // Can't move if already moving
       cmd.setReply_P(BUSYRESP);
       
   } else if(isUp()) { // Can't move if UP
       cmd.setReply_P(BADZ);
   } else if (isEmpty(param)) {  // Return current position
         if (PRMMotionX.isInState(XError)) {
           cmd.setReply_P(XERR);
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
          cmd.setReply_P(BUSYRESP);
        } else {
          cmd.setReply_P(BADPARAM);
        }
    }
}

//Callback for POSZ
void cbMoveZ( Command &cmd ) {
  // Read param - determin postion then go to moving state!
    char *param = cmd.getParam();
    
    if (isMoving()) {  // Can't move if already moving
       cmd.setReply_P(BUSYRESP);
    } else if (isEmpty(param)) {
      if(PRMMotionZ.isInState(ZError)) {
          cmd.setReply_P(ZERR);        
      } else if(zpos==DOWN) {
          cmd.setReply_P(DOWNRESP);
      } else if(zpos == UP) {
          cmd.setReply_P(UPRESP);
      }
    } else {
         if (strcmp(param, "UP")==0) {
          zpos = UP;
          PRMMotionZ.transitionTo(ZMoving);
          cmd.setReply_P(BUSYRESP);
          
        } else if (strcmp(param, "DOWN")==0){
          zpos = DOWN;
          PRMMotionZ.transitionTo(ZMoving);
          cmd.setReply_P(BUSYRESP);
          
        } else {
            cmd.setReply_P(BADPARAM);
        }
    }
}

void setup()
{
  
  
  /*** SETUP MOJO COMMUNICATOR  ***/
  //downSensor.setup(PULLDOWN);
  mojo.setDeviceType("PRM-V0.1");
  mojo.setSerial(SerialRS485);  //Set which serial to listen on
  SerialRS485.setControlPin(4);
  mojo.loadBaudrateEEPROM(); //Load baudrate from EEPROM
  mojo.loadAddressEEPROM(); //Load address from EEPROM
  
  /*** ATTACH CALLBACKS HERE ***/
  addCallback("PX", cbMoveX);
  addCallback("PZ", cbMoveZ);
  addCallback("COOL",  cbCool);
  addCallback("TRN",  cbTransfer);
  
  
  /*** ATTACH DEFAULT CALLBACKS ***/
  setupDefaultCallbacks(); 
  
  /*** ADDITIONAL PRM SETUP CODE ***/
  Serial3RS485.begin(9600);
  Serial3RS485.setControlPin(3);
  
  MotorCtrl.setTimeout(MOTORCTRLTIMEOUT);  //Set timeout to 5sec
  
  for(int i=23; i<53;i=i+2) {
    pinMode(i,OUTPUT);
    digitalWrite(i,LOW);
  }
  pinMode(13,OUTPUT);
  pinMode(23,OUTPUT);
  pinMode(25,OUTPUT);
  pinMode(upPin,OUTPUT);
  digitalWrite(upPin,HIGH);
  pinMode(downPin,OUTPUT);
  digitalWrite(downPin,HIGH);
} 


void loop() {
  mojo.run(); // Run mojo communicator 
  PRMMotionX.update(); // Run PRM X Motion
  PRMMotionZ.update(); // Run PRM Y Motion
  PRMCool.update(); // Run PRM Cooling Valve
  PRMTransfer.update(); //Run PRM TransferValve
}


/*** UTILITY FUNCTIONS FOR FSM ***/

void xstartmove() {
  //Serial.println("Start moving X");
  // Send command to move to Xpos then auto transition to moving state
  moveToXPosition();
}

void xmoving() {
    #ifdef DEBUGSER
    Serial1.println("XMoving");
    #endif
    MotorCtrl.sendQuery();    
    MotorCtrl.receive();
        
    if ( MotorCtrl.messageReady() ) {
       //Serial.println("Message Ready");
       if (MotorCtrl.isBusy()==false) {
           //Serial.println("Motor No Busy");
           PRMMotionX.transitionTo(MotionStandby);
     } else {
       //Serial.println("Send Query!");
          MotorCtrl.sendQuery();
     }
    }
     
     if (MotorCtrl.isInTimeout()) {
       //Serial.println("Timeout!");
       PRMMotionX.transitionTo(XError);
     }
     
}


void zstartmove() {
  //Serial.println("Start moving Z");
  // Change valve state
  moveToZPosition();
}

void zmoving() {
    if (zpos == UP) {
      if (upSensor.isPressed()) {
         PRMMotionZ.transitionTo(MotionStandby);
      } else {
        zTimeout.check();
      }
    } else if (zpos == DOWN) {
      if(downSensor.isPressed()) {
      PRMMotionZ.transitionTo(MotionStandby);
      } else {
        zTimeout.check();        
      }
    }
    
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
      //Serial.println("Go Home!");
      MotorCtrl.send("f1m65h20aE42680aC50au1000n8V1200000Z80000000R");
      //Send command to home
      break;
    case POSITION1:
      //Serial.println("Go P1!");
      MotorCtrl.send("V1200000A0R");
      //Send command to goto pos 1
      break;
    case POSITION2:
      //Serial.println("Go P2!");
      MotorCtrl.send("V1200000A33500R");
      //Send command to goto pos 2
      break;
    case POSITION3:
      //Serial.println("Go P3!");
      MotorCtrl.send("V1200000A67000R");
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
      digitalWrite(upPin,HIGH);
      digitalWrite(downPin,LOW);
      //Send command to go UP
      break;
    case DOWN:
      //Serial.println("Go down");
      digitalWrite(upPin,LOW);
      digitalWrite(downPin,HIGH);
      //Send command to go UP
      break;
    default:
      break;
  }
  zTimeout.reset();
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
  //MotorCtrl.send("TR");
  // Probably send terminate here...
}


void transferon() {
  // Turn transfer valve on
  digitalWrite(25,HIGH);
}

void transferoff() {
  // Turn transfer valve off
  digitalWrite(25,LOW);
}

void coolon() {
  // Turn transfer valve on
  digitalWrite(23,HIGH);
}

void cooloff() {
  // Turn transfer valve off
  digitalWrite(23,LOW);
}

void standby() {
    // Do nothing!
 }


 void gozerror() {
   PRMMotionZ.transitionTo(ZError);
 }
