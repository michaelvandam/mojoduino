#include <FiniteStateMachine.h>
#include <mojo.h>

/*
* PRM Parameters
*/
const char BADZ[] = "?LOWERZ";
const char UPRESP[] = "UP";
const char DOWNRESP[] = "DOWN";


enum XPosition {HOME, POSITION1, POSITION2, POSITION3};

enum ZPosition {UP, DOWN};

XPosition xpos = HOME;

ZPosition zpos = DOWN;


/* 
* PRM States
*/

//X Motion State
State XMoving = State(xstartmove, xmoving, movecomplete);


//Z Motion State
State ZMoving = State(zstartmove, zmoving, movecomplete);


// Motion Standby States
State MotionStandby = State(motionstandby);

//Reg States
// ???

/* 
* Create PRM FSMs
*/
FSM PRMMotionX = FSM(MotionStandby);
FSM PRMMotionZ = FSM(MotionStandby);



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
         itoa((int)xpos, param, 10);
         cmd.setReply(param);
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
}

void loop() {
  mojo.run(); // Run mojo communicator 
  PRMMotionX.update(); // Run RDM
  PRMMotionZ.update(); // Run RDM
}


/*** UTILITY FUNCTIONS FOR FSM ***/

void xstartmove() {
  Serial.println("Start moving X");
  // Send command to move to Xpos then auto transition to moving state
  moveToXPosition();
}

void xmoving() {
    Serial.println("Moving X");
    // Send command to check status when complete transition to standby
    PRMMotionX.transitionTo(MotionStandby);
}

void zstartmove() {
  Serial.println("Start moving Z");
  // Change valve state
  moveToZPosition();
}

void zmoving() {
  Serial.println("Moving Z");
  // If we have sensors poll till in position
  PRMMotionZ.transitionTo(MotionStandby);
}

void movecomplete() {
  Serial.println("Move Complete");
  // Do clean up stuff - probably nothing
}

void motionstandby() {
   // Empty Message - do nothing
}


// Functions to move to Positions
void moveToXPosition() {
  switch(xpos) {
    case HOME:
      Serial.println("Go Home");
      //Send command to home
      break;
    case POSITION1:
      Serial.println("Go Pos 1");
      //Send command to goto pos 1
      break;
    case POSITION2:
      Serial.println("Go Pos 2");
      //Send command to goto pos 2
      break;
    case POSITION3:
      Serial.println("Go Pos 3");
      //Send command to goto pos 3
      break;
    default:
      break;
  }
}

void moveToZPosition() {
  switch(zpos) {
    case UP:
      Serial.println("Go up");
      //Send command to go UP
      break;
    case DOWN:
      Serial.println("Go down");
      //Send command to go UP
      break;
    default:
      break;
  }
}

