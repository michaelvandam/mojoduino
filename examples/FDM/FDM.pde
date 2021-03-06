#include <EEPROM.h>
#include <TimedAction.h>
#include <Button.h>
#include <FiniteStateMachine.h>
#include <Wire.h>
#include <mojo.h> 
#include "HardwareSerialRS485.h"
#include "I2CValve.h"
#include "MultiDAC.h"
#include "AMComm.h"  // AllMotion communication control library

#define DEBUGMTR
/*
* FDM Parameters
*/
const char BADZ[] PROGMEM = "?RAISEZ";
const char UPRESP[] PROGMEM = "UP";
const char DOWNRESP[] PROGMEM = "DOWN";
const char XERR[] PROGMEM = "?XERR";
const char YERR[] PROGMEM = "?YERR";
const char ZERR[] PROGMEM = "?ZERR";
const char SYRERR[] PROGMEM = "?SYRERR";
const char READY[] PROGMEM = "READY";
const char MAX[] PROGMEM = "MAX";
const char MOV[]  PROGMEM = "MOVE";
const char POS[]  PROGMEM = "POS";
const char WAIT[] PROGMEM = "WAIT";
const char NONERESP[] PROGMEM = "NONE";


const long MOTORCTRLTIMEOUT = 10000;
const unsigned long MAXPOSX = 168000;
const unsigned long MAXPOSY = 380000;
const int MAXVALVEPOS = 6;

/*** Rotary Valve Setup ***/
I2CValve valve = I2CValve (0x07,10);
/*** DAC Setup ***/
MultiDAC DAC1; //MultiDAC(0x41);
MultiDAC DAC2; //MultiDAC(0x51);
MultiDAC *DACs[2] = {&DAC1, &DAC2};

boolean HOMEX = true;
boolean HOMEY = true;

int ledPin = 13;
int upPin = 45;
int downPin = 47;
int upSensorPin = 55;
int downSensorPin = 54;
int ventPin = 43;
int vacPin = 6;
int airValve1 = 23;
int airValve2 = 25;
int airValve3 = 27;
int airValve4 = 29;
int airValve5 = 31;
int airValve6 = 33;
int airValve7 = 35;
int airValve8 = 37;
int vacValve1 = 49;
int vacValve2 = 51;
int vacValve3 = 53;



unsigned long xpos = 0;
unsigned long ypos = 0;
char syringecmd[64];
int selectedVacValve = 0;
int vacSpeed=0;
enum ZPosition {UP, DOWN, ZERROR};
ZPosition zpos = UP;

AMComm MotorCtrlX = AMComm(Serial3RS485, '2'); //Device at address '2'
AMComm MotorCtrlY = AMComm(Serial3RS485, '1');  //Device at address '1'
AMComm SyringeCtrl = AMComm(Serial2RS485, '1');  //Device at address '2'


Button upSensor = Button(upSensorPin,PULLUP);
Button downSensor = Button(downSensorPin,PULLUP);

TimedAction zTimeout = TimedAction(10000,gozerror);

/* 
* PRM States
*/

//X Motion State
State XStartup = State(initialX);
State XMoving = State(moveToXPosition, xmoving, movecomplete);
State XError = State(xerror);


//Y Motion State
State YStartup = State(initialY);
State YMoving = State(moveToYPosition, ymoving, movecomplete);
State YError = State(yerror);

//Z Motion State
State ZStartup = State(initialZ);
State ZMoving = State(moveToZPosition, zmoving, movecomplete);
State ZFree = State(moveToZPosition, zmoving, zmovecomplete);
State ZError = State(standby);


//Syringe Motion State
State SyringeStartup = State(initialSyringe);
State SyringeMoving = State(syringesend, syringemoving, movecomplete);
State SyringeError = State(syringeerror);

// Motion Standby States
State MotionStandby = State(motionstandby);

/* 
* Create FDM FSMs
*/
FSM PRMMotionX = FSM(XStartup);//XStartup);
FSM PRMMotionY = FSM(YStartup);//YStartup);
FSM PRMMotionZ = FSM(MotionStandby);//ZStartup);
FSM Syringe = FSM(MotionStandby);//SyringeStartup);

/*
* Parsing Functions
*/
boolean isEmpty(char *param) {
    if (strlen(param)==0)
        return true;
    return false;
}

boolean isValidXPosition(unsigned long pos) {
  if (0 <= pos && pos <= MAXPOSX) {
    return true;
  }
  return false;
}

boolean isValidYPosition(unsigned long pos) {
  if (0 <= pos && pos <= MAXPOSY) {
    return true;
  }
  return false;
}

    
boolean isUp() {
  if (zpos == UP)
    return true;
  return false;
}


boolean isMoving() {
  if (PRMMotionX.isInState(XMoving) || PRMMotionZ.isInState(ZMoving) || PRMMotionY.isInState(YMoving))
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

//Callback POSX
void cbMoveX( Command &cmd ) {
  // Read param - determin postion then go to moving state!
    unsigned long pos;
    char *param = cmd.getParam();
    
    if (isMoving()) {  // Can't move if already moving
       cmd.setReply_P(BUSYRESP);       
   } else if(!upSensor.isPressed()) { // Can't move if Down
       cmd.setReply_P(BADZ);
   } else if (isEmpty(param)) {  // Return current position
         if (PRMMotionX.isInState(XError)) {
           cmd.setReply_P(XERR);
         } else {
           ultoa(xpos, param, 10);
           cmd.setReply(param);
         }
    } else { // Check that user send valid position then move to it
        if (strcmp(param, "HOME")==0) {
          HOMEX=true;
          PRMMotionX.transitionTo(XMoving);
          cmd.setReply_P(BUSYRESP);
        } else {       
          pos = atol(param);
          if (isValidXPosition(pos)) {
           cmd.setReply(param);
            xpos = pos;
            PRMMotionX.transitionTo(XMoving);
          } else {
            cmd.setReply_P(BADPARAM);
          }
        }
    }
}

//Callback POSY
void cbMoveY( Command &cmd ) {
  // Read param - determin postion then go to moving state!
    unsigned long pos;
    char *param = cmd.getParam();
    
    if (isMoving()) {  // Can't move if already moving
       cmd.setReply_P(BUSYRESP);       
   } else if(!upSensor.isPressed()) { // Can't move if Down
       cmd.setReply_P(BADZ);
   } else if (isEmpty(param)) {  // Return current position
         if (PRMMotionY.isInState(YError)) {
           cmd.setReply_P(YERR);
         } else {
           ultoa(ypos, param, 10);
           cmd.setReply(param);
         }
    } else { // Check that user send valid position then move to it
        if (strcmp(param, "HOME")==0) {
          HOMEY=true;
          PRMMotionY.transitionTo(YMoving);
          cmd.setReply_P(BUSYRESP);
        } else {       
          pos = atol(param);
          if (isValidYPosition(pos)) {
           cmd.setReply(param);
            ypos = pos;
            PRMMotionY.transitionTo(YMoving);
          } else {
            cmd.setReply_P(BADPARAM);
          }
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
      } else if(zpos==UP) {
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
        } else if (strcmp(param, "FREE")==0){
          zpos = DOWN;
          PRMMotionZ.transitionTo(ZFree);
          cmd.setReply_P(BUSYRESP);         
        } else {
            cmd.setReply_P(BADPARAM);
        }
    }
}


//Callback Syringe
void cbSyringe( Command &cmd ) {
  // Read param - determine postion then go to moving state!
    char *param = cmd.getParam();
    if (Syringe.isInState(SyringeMoving)) {
      cmd.setReply_P(BUSYRESP);
    } else if (isEmpty(param)) {  // Return current position
         if (Syringe.isInState(SyringeError)) {
           cmd.setReply_P(SYRERR);
         } else {
           cmd.setReply_P(READY);
         }
    } else { // Run syringe command
            strcpy(syringecmd, param);
            Syringe.transitionTo(SyringeMoving);
            cmd.setReply(param);
    }
}


void cbValvePosition( Command &cmd ){
  
  char *param = cmd.getParam();
  int pos;
  if (isEmpty(param)) {
    pos = valve.getPosition();
    itoa(pos, param, 10);
    cmd.setReply(param);    
  } else if (strcmp(param, "HOME")==0) {
    valve.goHome();
  } else {
    if ( valve.isValidPosition(pos=atoi(param))) {
      cmd.setReply(param);
      valve.setPosition(pos);
    } else {
      cmd.setReply_P(BADPARAM);
    }
  }
}


void cbVacValve( Command &cmd  ) {
  char *param = cmd.getParam();
  char *cmdstr = cmd.getCmd();
  int vacValve=-1;
  digitalWrite(vacValve1,LOW);
  digitalWrite(vacValve2,LOW);
  digitalWrite(vacValve3,LOW);
  cmd.setReply(param);  
  if (isPSTR(param,NONERESP)) {
        selectedVacValve = 0;
  } else {
      
      switch (param[0]) {
        case '1':
          digitalWrite(vacValve1,HIGH);
          digitalWrite(vacValve2,LOW);
          digitalWrite(vacValve3,LOW);  
          selectedVacValve = 1;
          break;
        case '2':
          digitalWrite(vacValve1,LOW);
          digitalWrite(vacValve2,HIGH);
          digitalWrite(vacValve3,LOW);  
          selectedVacValve = 2;
          break;
        case '3':
          digitalWrite(vacValve1,LOW);
          digitalWrite(vacValve2,LOW);
          digitalWrite(vacValve3,HIGH);  
          selectedVacValve = 3;
          break;
        default:
          selectedVacValve = 0;
          cmd.setReply_P(BADPARAM);
          break;
       }
       Serial.println();
       Serial.print("SetValve:");
       Serial.println(selectedVacValve);
  }  
}
 
//Mix Callbacks
void cbVac( Command &cmd ) {
  char *param = cmd.getParam();
  if (isEmpty(param)) { 
    if(digitalRead(vacPin)==HIGH) {
      cmd.setReply_P(ONRESP);
    } else {
      cmd.setReply_P(OFFRESP);
    }
  } else {
     if (isPSTR(param,ONRESP)) {
       digitalWrite(vacPin, HIGH);       
     } else if (isPSTR(param,OFFRESP)){ 
       digitalWrite(vacPin, LOW);
     cmd.setReply(param);
     } else {
        cmd.setReply_P(BADPARAM);     
     }
   }
}
 
  
void cbAirValve( Command &cmd  ) {
  char *param = cmd.getParam();
  char *cmdstr = cmd.getCmd();
  int selectedValve;
  
  switch (cmdstr[2]) {
    case '1':
      selectedValve = airValve1;
      break;
    case '2':
      selectedValve = airValve2;
      break;
    case '3':
      selectedValve = airValve3;
      break;
    case '4':
      selectedValve = airValve4;
      break;
    case '5':
      selectedValve = airValve5;
      break;
    case '6':
      selectedValve = airValve6;
      break;
    case '7':
      selectedValve = airValve7;
      break;
    case '8':
      selectedValve = airValve8;
      break;
    default:
      break;

  }
  
  if (isEmpty(param)) {
    if (digitalRead(selectedValve)==HIGH) {
        cmd.setReply_P(ONRESP);
    } else {
        cmd.setReply_P(OFFRESP);
    }
  } else {
    if (isPSTR(param,ONRESP)) {
      digitalWrite(selectedValve,HIGH);
      cmd.setReply_P(ONRESP);
    } else if (isPSTR(param,OFFRESP)) {
      digitalWrite(selectedValve,LOW);
      cmd.setReply_P(OFFRESP);
    } else {
      cmd.setReply_P(BADPARAM);
    }
  }
}


void cbReset( Command &cmd ) {
    MotorCtrlX.send("T");
    //Serial.println("Terminate active commands");  
    MotorCtrlX.send("ar5073R");
    //Serial.println("Restart driver");
    delay(1000);
    zpos = DOWN;
    moveToZPosition();
    //Serial.println("Lower Z");
    delay(4000);
    if(downSensor.isPressed()) {
      xpos = 0;
      HOMEX=true;
      moveToXPosition();
      //Serial.println("Home X");
      cmd.setReply_P(DONERESP);    
    } else {
      cmd.setReply_P(ZERR);    
    }
   
}

void cbDacValue( Command &cmd  ) {
  char *param = cmd.getParam();
  char *cmdstr = cmd.getCmd();
  int selectedDAC;
  int selectedPin;
  long val;
  char * splitpos;
  
  selectedDAC = atoi(&cmdstr[3]);
  if (isEmpty(param)) {
        Serial.println();
        Serial.print("Selected DAC:");
        Serial.print(cmdstr);
        Serial.println(selectedDAC);
  } else {
        selectedPin = param[0]-'0';
        if (selectedPin < MAX_OUT) {
          splitpos = strchr(param,',');
          Serial.println();
          Serial.print("Selected DAC:");Serial.println(selectedDAC);
          Serial.print("Selected Pin:");Serial.println(selectedPin);
          val = atol(splitpos+1);
          if (val < MAX_VAL && val > 0) {
            Serial.print("Value:");Serial.println(val);               
            DACs[selectedDAC]->outputs[selectedPin].setValue((unsigned int)val);
            cmd.setReply(param);  
          } else {
            cmd.setReply_P(BADPARAM);
          }
          

          
 
        } else {
          cmd.setReply_P(BADPARAM);
        }        
  }
}



void setup()
{
  
  
  /*** SETUP MOJO COMMUNICATOR  ***/
  //downSensor.setup(PULLDOWN);
  mojo.setDeviceType("FDM-V0.1");
  mojo.setSerial(SerialRS485);  //Set which serial to listen on
  SerialRS485.setControlPin(4);
  mojo.loadBaudrateEEPROM(); //Load baudrate from EEPROM
  mojo.loadAddressEEPROM(); //Load address from EEPROM
  
  /*** ATTACH CALLBACKS HERE ***/
  addCallback("PX", cbMoveX);
  addCallback("PZ", cbMoveZ);
  addCallback("PY", cbMoveY);
  addCallback("SYR", cbSyringe);
  addCallback("VP", cbValvePosition);
  addCallback("AV1", cbAirValve);
  addCallback("AV2", cbAirValve);
  addCallback("AV3", cbAirValve);
  addCallback("AV4", cbAirValve);   
  addCallback("AV5", cbAirValve);   
  addCallback("AV6", cbAirValve);   
  addCallback("AV7", cbAirValve);   
  addCallback("AV8", cbAirValve);   
  addCallback("DAC0", cbDacValue);   
  addCallback("DAC1", cbDacValue);
  addCallback("VACV",cbVacValve);
  addCallback("VAC", cbVac);  
  
  
  /*** ATTACH DEFAULT CALLBACKS ***/
  setupDefaultCallbacks(); 
  
  /*** ADDITIONAL PRM SETUP CODE ***/
  analogReference(INTERNAL);
  
  /*** SETUP COMMUNICATION ***/
  Wire.begin();   //Start Wire library as I2C Master 
  TWBR = ((F_CPU / 32000l) - 16) / 2;

/*** //Turn off Pullup Resistors
  pinMode(20,INPUT);
  digitalWrite(20,LOW);
  pinMode(21,INPUT);
  digitalWrite(21,LOW);
***/  
  Serial3RS485.begin(9600);
  Serial3RS485.setControlPin(3);
  Serial2RS485.begin(38400);
  Serial2RS485.setControlPin(2);
  
  DAC1 = MultiDAC(0x41);
  DAC2 = MultiDAC(0x51);
  MotorCtrlX.setTimeout(MOTORCTRLTIMEOUT);  //Set timeout to 5sec
  MotorCtrlY.setTimeout(MOTORCTRLTIMEOUT);  //Set timeout to 5sec
  
  for(int i=23; i<=53;i=i+2) {
    pinMode(i,OUTPUT);
    digitalWrite(i,LOW);
  }

  pinMode(ledPin,OUTPUT);
  pinMode(upPin,OUTPUT);
  digitalWrite(upPin,HIGH);
  pinMode(downPin,OUTPUT);
  digitalWrite(downPin,HIGH);
} 


void loop() {  
    #ifdef DEBUGMTR
    //Serial.println("***Receive Mojo MSG");
    #endif
    mojo.run(); // Run mojo communicator 
    PRMMotionX.update(); // Run PRM X Motion
    PRMMotionY.update(); // Run PRM X Motion
    PRMMotionZ.update(); // Run PRM Y Motion
    Syringe.update();
    
}


/*** UTILITY FUNCTIONS FOR FSM ***/


/*******************************
X Motion Fxns
*******************************/
// Function to move to X Positions (will send commands on USART!)
void moveToXPosition() {
  char posstr[16];
  char buf[64];
  
  #ifdef DEBUGMTR
  Serial.println(">>>Send X Motor command");
  #endif
  
  if (!upSensor.isPressed() && !(isUp())) {
    PRMMotionX.transitionTo(XError);
    zTimeout.reset();  
  } else {
    if(HOMEX == true) {
        MotorCtrlX.send("f1m100h15aE12500L150V38000z0Z180000R");
        xpos=0;
        HOMEX = false;
    } else {
      ltoa(xpos, posstr, 10);
      buf[0] = 'A'; buf[1]='\0';
      strcat(buf, posstr);
      strcat(buf,"R");
      MotorCtrlX.send(buf);
    }
  }
}

//**** Function to monitor  X motor status
void xmoving() {
    #ifdef DEBUGMTR
    Serial.println(">>>X is Moving");
    #endif
    
      if (MotorCtrlX.receiveMessage()) {
        #ifdef DEBUGMTR
         Serial.println("X Message Ready");
        #endif
       if (MotorCtrlX.isBusy()==false) {
          #ifdef DEBUGMTR         
          Serial.println("X Motor Not Busy");
          #endif
          MotorCtrlX.readyForNext();
          PRMMotionX.transitionTo(MotionStandby);
        }
        #ifdef DEBUGMTR 
        else {                    
             Serial.println("X Motor Busy");             
        }
        #endif
      }

      if (MotorCtrlX.isInTimeout()) {
        #ifdef DEBUGMTR          
        Serial.println("X Timeout!");
        #endif
        MotorCtrlX.readyForNext();
        PRMMotionX.transitionTo(XError);
      }  
}

/*******************************
Y Motion Fxns
*******************************/
// Function to move to X Positions (will send commands on USART!)
void moveToYPosition() {
  char posstr[16];
  char buf[64];
  
  #ifdef DEBUGMTR
  Serial.println(">>>Send  Y Motor command");
  #endif
  
  if (!upSensor.isPressed() && !(isUp())) {
    PRMMotionY.transitionTo(YError);
    zTimeout.reset();  
  } else {
    if(HOMEY == true) {
        MotorCtrlY.send("f1m35h15aE12500L200V38000z0Z400000R");    
        ypos=0;
        HOMEY = false;
    } else {
      ltoa(ypos, posstr, 10);
      buf[0] = 'A'; buf[1]='\0';
      strcat(buf, posstr);
      strcat(buf,"R");
      MotorCtrlY.send(buf);
    }
  }
}

//**** Function to monitor  Y motor status
void ymoving() {
    #ifdef DEBUGMTR
    Serial.println(">>>Y is Moving");
    #endif
    
      if (MotorCtrlY.receiveMessage()) {
        #ifdef DEBUGMTR
         Serial.println("Y Message Ready");
        #endif
       if (MotorCtrlY.isBusy()==false) {
          #ifdef DEBUGMTR         
          Serial.println("Y Motor Not Busy");
          #endif
          MotorCtrlY.readyForNext();
          PRMMotionY.transitionTo(MotionStandby);
        }
        #ifdef DEBUGMTR 
        else {                    
             Serial.println("Y Motor Busy");             
        }
        #endif
      }

      if (MotorCtrlY.isInTimeout()) {
        #ifdef DEBUGMTR          
        Serial.println("Y Timeout!");
        #endif
        MotorCtrlY.readyForNext();
        PRMMotionY.transitionTo(YError);
      }
     
}

void syringesend() {
  SyringeCtrl.send(syringecmd);
}

void syringemoving() {
    #ifdef DEBUGMTR
    Serial.println(">>>Syringe is Moving");
    #endif
      if (SyringeCtrl.receiveMessage()) {
        #ifdef DEBUGMTR
         Serial.println("Syringe Message Ready");
        #endif
       if (SyringeCtrl.isBusy()==false) {
          #ifdef DEBUGMTR         
          Serial.println("Syringe Not Busy");
          Serial.println("Reset Syringe");
          #endif
          SyringeCtrl.readyForNext();
          Syringe.transitionTo(MotionStandby);
        }
        #ifdef DEBUGMTR 
        else {                    
             Serial.println("Syringe Busy");             
        }
        #endif
      }

      if (SyringeCtrl.isInTimeout()) {
        #ifdef DEBUGMTR          
        Serial.println("X Timeout!");
        #endif
        SyringeCtrl.readyForNext();
        Syringe.transitionTo(SyringeError);
      }  
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
  HOMEX = true;
  MotorCtrlX.send("f1m100h15aE12500L150V38000z0Z180000R");
  delay(500);
  MotorCtrlX.receiveMessage();
  PRMMotionX.transitionTo(XMoving);  
}

void initialY() {
  HOMEY = true;
  MotorCtrlY.send("f1m35h15aE12500L200V38000z0Z400000R");
  delay(500);
  MotorCtrlY.receiveMessage();
  PRMMotionY.transitionTo(YMoving);  
}

void initialZ() {
  
  zpos = UP;
  PRMMotionZ.immediateTransitionTo(ZMoving);
  /*while(!upSensor.isPressed()){
    continue;
  }*/
}


void initialSyringe(){
  HOMEX = true;
  SyringeCtrl.send("YR");
  delay(500);
  SyringeCtrl.receiveMessage();
  Syringe.transitionTo(SyringeMoving);  
}

void xerror() {
  //MotorCtrl.send("TR");
  // Probably send terminate here...
}


void yerror() {
  //MotorCtrl.send("TR");
  // Probably send terminate here...
}

void syringeerror() {
  //MotorCtrl.send("TR");
  // Probably send terminate here...
}

 void gozerror() {
   zpos=ZERROR;
   PRMMotionZ.transitionTo(ZError);
 }

void standby() {  
  //Nothing
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

