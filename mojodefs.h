#ifndef Mojodefs_h
#define Mojodefs_h



//Mojo Limits
#define MAXMSGSIZE 128
#define MAXCMDS 8
#define MAXCMDLEN 8
#define MAXPARAMLEN 17
#define REPLYLEN MAXCMDLEN + MAXPARAMLEN + 1


//Errors
#define NOERR 0
#define TOOLONGERR -1

//Device Specific
const char DEVICEID[] = "Default-0.1";


//Mojo Special Characters
const char ENDMSG = '$'; // Change to '\r'
const char STARTMSG = '>';
const char CMDSEP[] = ";";
const char ADDSEP1[] = ":";
const char ADDSEP2[] = ",";
const char PARAMSEP[] = "=";
const char BROADCASTADDY = '0';
const char RESPCHAR[] = "*";

//#define ADDR_EEPROM 0x0000


#endif
