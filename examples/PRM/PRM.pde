#include <FiniteStateMachine.h>
#include <mojo.h>

/*
* PRM Parameters
*/
const char BADZ[] = "?LOWERZ";
const char UPRESP[] = "UP";
const char DOWNRESP[] = "DOWN";
const char XERR[] = "?XERR";

enum XPosition {HOME, POSITION1, POSITION2, POSITION3};

enum ZPosition {UP, DOWN};

XPosition xpos = HOME;
ZPosition zpos = DOWN;

/* 
* PRM States
*/

//X Motion State
State XMoving = State(xstartmove, xmoving, movecomplete);
State XError = State(xerror);


//Z Motion State
State ZMoving = State(zstartmove, zmoving, movecomplete);
State ZError = State(zerror);

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
    
   if (PRMMotionX.isInState(XError)) {
       cmd.setReply(XERR);
    } else if (isMoving()) {  // Can't move if already moving
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
  Serial1.begin(9600);
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


char getReply() {
  enum RESPSSTATE {BEGIN, ADDRESS, STATUS, END};
  static RESPSSTATE respState = BEGIN;
  byte c = 0;
  while (Serial1.available() > 0) {
     c = Serial1.read();
     Serial.print("REC:");
     Serial.println(c);
     switch(respState) {
       case BEGIN:
         Serial.println("<BEGIN>");
         if (c =='/')
           c = 0;
           respState = ADDRESS;
         break;
       case ADDRESS:
         Serial.println("<ADDRESS>");
         if (c == '0') {
           c = 0; respState = STATUS;
         } else 
           respState = BEGIN;
         break;
       case STATUS:
         Serial.println("<STATUS>");
          respState = BEGIN;
          Serial.flush();
          return c;
          break;
       default:
         Serial.println("<DEFAULT>");
         c = 0;
         respState = BEGIN;       
      }
  
    return 0;  
    }
}

void xmoving() {
    static char response;
    static int count = 0;
    const int LIMIT = 50;
    const int REPLYTIMEOUT = 100;
    static int withoutReply = 0;
    
    
    if (response = getReply()) {
       withoutReply=0;
       Serial.println(response);
       if (!(motorBusy(response)) || !(motorInError(response)) )
          PRMMotionX.transitionTo(MotionStandby);
    } else {
      count++;
      if (count > LIMIT) {  // Only send query when limit is reached!
        count = 0;
        Serial1.println("/1Q\r\n");
      } else
          withoutReply++;
    }
      
    if (withoutReply > REPLYTIMEOUT || motorInError(response) ) {
      PRMMotionX.transitionTo(XError);
    }
    //Serial.println("Moving X");
    // Send command to check status when complete transition to standby
    
}


boolean motorBusy(char response) {
  // Check status byte in here!
  Serial.print("StatusByte:");
  Serial.println(response);
  return false;
}

boolean motorInError(char response) {
  // Check for error!
  return false;
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
      Serial1.println("/1Z4000000z0aE42680aC50au1000R\r");
      //Send command to home
      break;
    case POSITION1:
      Serial1.println("/1A1000000R\r");
      //Send command to goto pos 1
      break;
    case POSITION2:
      Serial1.println("/1A2000000R\r");
      //Send command to goto pos 2
      break;
    case POSITION3:
      Serial1.println("/1A3000000R\r");
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


void initialX() {
  xpos = HOME;
  PRMMotionX.transitionTo(XMoving);  
}

void initialZ() {
  zpos = DOWN;
  PRMMotionZ.transitionTo(ZMoving);
}


void xerror(){
}

void zerror(){
}
