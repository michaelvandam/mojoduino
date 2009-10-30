#ifndef Mojodispatch_h
#define Mojodispatch_h
#include "mojo.h"

typedef void (*CALLBACKFXN)( Command &Cmd );

class Callback
{
    public:
        Callback();
        CALLBACKFXN getFxn();
        void setFxn(CALLBACKFXN f);
        void setCallbackName(const char *cbname);
        void callFxn(Command &cmd);
        int forMe(Command &cmd);
        
    private:
        char callbackName[MAXCMDLEN];
        CALLBACKFXN callbackfxn;
        void init();
};


void cmdDispatch(Command *cmd);

void msgDispatch(Message *msg);

void addCallback(const char *callbackName, CALLBACKFXN f);

extern Callback callbacks[MAXCMDS];

#endif