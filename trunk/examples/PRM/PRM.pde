#include <EEPROM.h>
#include <TimedAction.h>
#include <Button.h>
#include <FiniteStateMachine.h> 
#include <mojo.h> 
#include "HardwareSerialRS485.h"
#include "AMComm.h"  // AllMotion communication control library

#define MAXTEMP 300.0
#define TMPOFFSETLIMIT 128
#define TMPOFFSETEEADDRLOW 3
#define TMPOFFSETEEADDRHIGH 4
/*
* PRM Parameters
*/
const char BADZ[] PROGMEM = "?LOWERZ";
const char UPRESP[] PROGMEM = "UP";
const char DOWNRESP[] PROGMEM = "DOWN";
const char XERR[] PROGMEM = "?XERR";
const char ZERR[] PROGMEM = "?ZERR";
const char MAX[] PROGMEM = "MAX";
const long MOTORCTRLTIMEOUT = 10000;

int upPin = 47;
int downPin = 49;
int tranPin = 41;
int coolPin = 43;
int coolPin2 = 45;
int mixPin = 6;
int statusPin = 13;
int ledPin = 13;
int heaterPin = 5;
int therm1 = 8;
int therm2 = 2;

float setPoint = 0;
int mixSpeed = 0;
int tmpOffset = 0;

enum XPosition {HOME, POSITION1, POSITION2, POSITION3};

enum ZPosition {UP, DOWN};

XPosition xpos = HOME;
ZPosition zpos = DOWN;

AMComm MotorCtrl = AMComm(Serial3RS485, '1'); //Device at address '1'
//AMComm TempCtrl = AMComm(Serial3RS485, '2');  //Device at address '2'

Button upSensor = Button(57,PULLUP);
Button downSensor = Button(54,PULLUP);

TimedAction zTimeout = TimedAction(10000,gozerror);

/* 
* PRM States
*/

//X Motion State
State XMoving = State(xstartmove, xmoving, movecomplete);
State XError = State(xerror);

//Z Motion State
State ZMoving = State(zstartmove, zmoving, zmovecomplete);
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

//Heater States
State HeaterStandby = State(goheateroff, gostandby, gostandby);
State HeaterOn = State(goheater);
State HeaterOverride = State(goheateroverride);

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
FSM PRMHeater = FSM(HeaterStandby);



void writeTempOffset() {
  EEPROM.write(TMPOFFSETEEADDRLOW, tmpOffset);
  EEPROM.write(TMPOFFSETEEADDRHIGH, tmpOffset >> 8);  
}

void loadTempOffset() {
  tmpOffset = (int)((EEPROM.read(TMPOFFSETEEADDRHIGH) << 8) | (EEPROM.read(TMPOFFSETEEADDRLOW)));
}


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
      cmd.setReply_P(ONRESP);
    else
      cmd.setReply_P(OFFRESP);
  } else {
    if( isPSTR(cmd.getParam(), ONRESP) ) {
      //Turn On Cool
      cmd.setReply_P(ONRESP);
      PRMCool.transitionTo(CoolOn);
    } else if( isPSTR(cmd.getParam(), OFFRESP)) {
      //Turn Off Cool
      cmd.setReply_P(OFFRESP);
      PRMCool.transitionTo(CoolOff);
    } else {
      cmd.setReply_P(BADPARAM);
    }
  }
  
}

void cbTempOffset( Command &cmd) {
  char buf[5];
  if (isEmpty(cmd.getParam())) {
    ltoa(tmpOffset,buf,10);
    cmd.setReply(buf);
  } else {
     int tmp = atoi(cmd.getParam());
     if (tmp < TMPOFFSETLIMIT && tmp >= -TMPOFFSETLIMIT) {
       tmpOffset = tmp;
       writeTempOffset();
       cmd.setReply(cmd.getParam());
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
      cmd.setReply_P(ONRESP);
    else
      cmd.setReply_P(OFFRESP);
  } else {
    cmd.setReply(cmd.getParam());
    if( isPSTR(cmd.getParam(), ONRESP) ) {
      //Turn On Cool
      cmd.setReply_P(ONRESP);
      PRMTransfer.transitionTo(TransferOn);
    } else if( isPSTR(cmd.getParam(), OFFRESP)) {
      //Turn Off Cool
      cmd.setReply_P(OFFRESP);
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


void cbReset( Command &cmd ) {

    MotorCtrl.send("T");
    //Serial.println("Terminate active commands");  
    MotorCtrl.send("ar5073R");
    //Serial.println("Restart driver");
    delay(1000);
    zpos = DOWN;
    moveToZPosition();
    //Serial.println("Lower Z");
    delay(4000);
    if(downSensor.isPressed()) {
      xpos = HOME;
      moveToXPosition();
      //Serial.println("Home X");
      cmd.setReply_P(DONERESP);    
    } else {
      cmd.setReply_P(ZERR);    
    }
   
}

//Mix Callbacks
void cbMix( Command &cmd ) {
  char *param = cmd.getParam();
  if (isEmpty(param)) { 
    itoa(mixSpeed, param, 10);
    cmd.setReply(param);
  } else {
     int v = atoi(cmd.getParam());
     if ((v < 0)||(v>255)) {
       cmd.setReply_P(BADPARAM);
     } else {
     mixSpeed = v;
     analogWrite(mixPin, mixSpeed);
     cmd.setReply(param);
     } 
   }
}

//Heater callbacks
void cbHeater( Command &cmd ) {
  char* param = cmd.getParam();
  if (isEmpty(param)) {
      if ( PRMHeater.isInState(HeaterOn) ) {
        cmd.setReply_P(ONRESP);
      } else if(PRMHeater.isInState(HeaterOverride)) {
        cmd.setReply_P(MAX);
      } else {
        cmd.setReply_P(OFFRESP);
      }
  } else {
    if (isPSTR(param, ONRESP)) {
        PRMHeater.transitionTo(HeaterOn);
        cmd.setReply_P(ONRESP);
     } else if (isPSTR(param, OFFRESP)) {
        PRMHeater.transitionTo(HeaterStandby);
        cmd.setReply_P(OFFRESP);
     } else if (isPSTR(param, MAX)) {
        PRMHeater.transitionTo(HeaterOverride);
        cmd.setReply_P(MAX);
     } else {
       PRMHeater.transitionTo(HeaterStandby);
       cmd.setReply_P(BADPARAM);
     }
  }
}


void getTempStr(Command &cmd, int tmppin) {
  char *param = cmd.getParam();
  char reply[10];
  reply[0] = '\0';
  
  if (isEmpty(param)) {
    
    floatToStr(getTemp(tmppin), reply, 2);
    cmd.setReply(reply);
  
} else {
    cmd.setReply_P(BADPARAM);
  }

}

void cbGetTemp( Command &cmd ) {
    getTempStr(cmd, therm1);
}


void cbGetTemp2( Command &cmd ) {
  getTempStr(cmd, therm2);
}


void cbSetpoint( Command &cmd ) {
  char* param = cmd.getParam();
  double tmpSetpt;
  
  if (isEmpty(param)) {
    char buf[10];
    floatToStr(setPoint, buf, 2);
    cmd.setReply(buf);
  } else {
    tmpSetpt = atof(param);  
    if (tmpSetpt < MAXTEMP && tmpSetpt > 0){
        setPoint = tmpSetpt;
        cmd.setReply(param);
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
  loadTempOffset();
  
  /*** ATTACH CALLBACKS HERE ***/
  addCallback("PX", cbMoveX);
  addCallback("PZ", cbMoveZ);
  addCallback("COOL",  cbCool);
  addCallback("TRN",  cbTransfer);
  addCallback("MIX",  cbMix);
  addCallback("RST",  cbReset);
  addCallback("TMPC", cbHeater);
  addCallback("SETP", cbSetpoint);  
  addCallback("TMP", cbGetTemp);
  addCallback("TMP2", cbGetTemp2);
  addCallback("COOL",  cbCool);
  addCallback("TOFF", cbTempOffset);
  
  /*** ATTACH DEFAULT CALLBACKS ***/
  setupDefaultCallbacks(); 
  
  /*** ADDITIONAL PRM SETUP CODE ***/
  analogReference(INTERNAL);
  
  Serial3RS485.begin(9600);
  Serial3RS485.setControlPin(3);
  
  MotorCtrl.setTimeout(MOTORCTRLTIMEOUT);  //Set timeout to 5sec
  
  for(int i=23; i<53;i=i+2) {
    pinMode(i,OUTPUT);
    digitalWrite(i,LOW);
  }

  pinMode(ledPin,OUTPUT);
  pinMode(mixPin,OUTPUT);
  pinMode(statusPin,OUTPUT);
  pinMode(coolPin,OUTPUT);
  pinMode(upPin,OUTPUT);
  digitalWrite(upPin,HIGH);
  pinMode(downPin,OUTPUT);
  digitalWrite(downPin,HIGH);
  pinMode(heaterPin,OUTPUT);
  digitalWrite(heaterPin,LOW);

} 


void loop() {
  mojo.run(); // Run mojo communicator 
  PRMMotionX.update(); // Run PRM X Motion
  PRMMotionZ.update(); // Run PRM Y Motion
  PRMCool.update(); // Run PRM Cooling Valve
  PRMTransfer.update(); //Run PRM TransferValve
  PRMHeater.update();
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

void zmovecomplete() {
  delay(200);
  digitalWrite(downPin,LOW);
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
      //Serial3RS485.println("Go Home!");
      MotorCtrl.send("f1m85h20aE42680aC50au1000n8V30000Z800000R");
      //Send command to home
      break;
    case POSITION1:
      //Serial.println("Go P1!");
      MotorCtrl.send("V30000A0R");
      //Send command to goto pos 1
      break;
    case POSITION2:
      //Serial.println("Go P2!");
      MotorCtrl.send("V30000A33150R");
      //Send command to goto pos 2
      break;
    case POSITION3:
      //Serial.println("Go P3!");
      MotorCtrl.send("V30000A66600R");
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
  digitalWrite(tranPin,HIGH);
}

void transferoff() {
  // Turn transfer valve off
  digitalWrite(tranPin,LOW);
}

void coolon() {
  // Turn Cool valve on
  digitalWrite(coolPin,HIGH);
  digitalWrite(coolPin2,HIGH);
}

void cooloff() {
  // Turn cool valve off
  digitalWrite(coolPin,LOW);
  digitalWrite(coolPin2,LOW);
}

void standby() {
    // Do nothing!
 }


 void gozerror() {
   PRMMotionZ.transitionTo(ZError);
 }
 

void goheateroff() {
  digitalWrite(heaterPin, LOW);   
}

void goheater() { 
  if (getTemp(therm1) < setPoint - 1) {
      digitalWrite(heaterPin, HIGH);
  } else {
      digitalWrite(heaterPin, LOW);
  }
}

void goheateroverride() {
  if (getTemp(therm1) < MAXTEMP) {
    digitalWrite(heaterPin, HIGH);
  } else {
    digitalWrite(heaterPin, LOW);
  }
}

void gostandby() {  
  //Nothing
}
 
float getTemp(int pin) {
      float sumTemp = 0;
      float tmpTemp = 0;
      for (int i = 0; i < 10; i++) {
        tmpTemp = (analogRead(pin) / 1024.0 * 2.5 * 100);     
        sumTemp = sumTemp + tmpTemp;
      }
      //Serial.print(pin);
      //Serial.print(':');
      //Serial.println(sumTemp/8.0);
      return sumTemp / 10.0 + tmpOffset;
}

char *floatToStr(double number, char* buff, uint8_t digits) 
{ 
  // Handle negative numbers
  char *buf = buff;
  if (number < 0.0)
  {
     *buf++=('-');
     number = -number;
  }

  // Round correctly so that print(1.999, 2) prints as "2.00"
  double rounding = 0.5;
  for (uint8_t i=0; i<digits; ++i)
    rounding /= 10.0;
  
  number += rounding;

  // Extract the integer part of the number and print it
  unsigned long int_part = (unsigned long)number;
  double remainder = number - (double)int_part;
  ltoa(int_part,buf,10);
  
  
  while(*buf!='\0') {
    buf++;
   //Serial.println("Not in here");
  } //Move to end of buffer
  
  
  // Print the decimal point, but only if there are digits beyond
  if (digits > 0) {
    *buf++='.'; 
    *buf='\0';  
  }
  
  // Extract digits from the remainder one at a time
  while (digits-- > 0)
  {
    //Serial.println(digits,DEC);
    remainder *= 10.0;
    int toPrint = int(remainder);
    itoa(toPrint,buf,10);
    buf++;
    remainder -= toPrint; 
  } 
    //Terminate string
  return buff;
}

