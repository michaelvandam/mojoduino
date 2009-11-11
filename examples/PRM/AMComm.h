// All Motion Communicator Class

#ifndef AMComm_h
#define AMComm_h


#include "WProgram.h"
#include "HardwareSerialRS485.h"

#define READYBIT (1 << 5)
#define ERRORBITS ( (1 >> 0) & (1 >> 1) & (1 >> 2) & (1 >> 3) )
#define NOERROR 0
#define INITERROR 1
#define BADCOMMAND 2
#define BADOPP 3
#define NOTINIT 5
#define OVERLOAD 6
#define NOTALLOWED 7
#define OVERFLOW 8


class AMComm
{
  public:
    AMComm();
    AMComm(HardwareSerial &S, char addr);
    HardwareSerial *serial;
    void setSerial(HardwareSerial &S);
    boolean receive();
    boolean messageReady();
    char getStatus();
    void setAddress(char addr);
    void readyForNext();
    void send(char *str);
    boolean isInError();
    boolean isBusy();
    void sendQuery();
    void setTimeout(long timeout);
    boolean isInQueryTimeout();
    boolean isInTimeout();
    //void run();
    
    
  private:
    enum RESPSSTATE {BEGIN, ADDRESS, STATUS, END};
    void init();
    void reset();
    RESPSSTATE messageState;
    char address;
    char status;
    long timeOutLimit;
    void resetTimeout();
    long previousMillis;
    long timeoutInterval;
    boolean readyToSend;    
};

#endif







