#ifndef Mojomsg_h
#define Mojomsg_h
#include "mojodefs.h"
#include <inttypes.h>
#include <avr/pgmspace.h>

class Command
{
    public:
        //void reset();
        Command();
        
        char *getCmd();
        void setCmd(const char *cmdStr);
        
        char *getParam();
        void setParam(const char *paramStr);
        
        char *getReply();
        void setReply();
        void setReply_P(PGM_P replyStrP);
        void setReply(const char *replyStr);
        void setReply(char c);
        void setReply(long c);
        
        void clear();
        
    private:
        char cmd[MAXCMDLEN];
        char param[MAXPARAMLEN];
        char reply[MAXPARAMLEN];
};


class Message
{
    public:
        Message();
        Message(char * msgString);
        void load(char * msgString);
        Command *getCmd();
        int len();
        void reset();
        char getSenderAddress();
        char getRecieverAddress();
        void setSenderAddress(char address);
        void setRecieverAddress(char address);
        char *reply();
        //char *cmdPtr;
        
    private:
        void init();
        char _msgString[MAXMSGSIZE];
        char response[MAXMSGSIZE];
        char header[7];
        char *getHeader();
        char senderAddress;
        char recieverAddress;
        uint8_t err;
        Command cmds[MAXCMDS];
        uint8_t cmdindex;
        uint8_t cmdretindex;
        void parse();
        int8_t addCommand(char *cmd, char *param);
        
};

#endif
