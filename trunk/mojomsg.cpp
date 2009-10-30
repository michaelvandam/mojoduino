#include "mojomsg.h"
#include "mojo.h"
#include "mojodefs.h"
#include <inttypes.h>

/***********************************************
 * COMMAND METHODS
 ***********************************************/
Command::Command() {
  //empty
  clear();
}
void Command::clear() {
  cmd[0]='\0';
  param[0]='\0';
  reply[0] = '\0';
}

char *Command::getCmd() {
  return cmd;
}


char *Command::getParam() {
  return param;
}

char *Command::getReply() {
  return reply;
}

void Command::setCmd(const char *cmdStr) {
  strcpy(cmd,cmdStr);
}

void Command::setParam(const char *paramStr) {

  if (paramStr==NULL){
    strcpy(param,"");
  } else {
    strcpy(param,paramStr);
  }
}


void Command::setReply(const char *replyStr) {
  strcpy(reply, replyStr);
}


void Command::setReply(char c) {
  reply[0] = c;
  reply[1] = '\0';
}

void Command::setReply(long c) {
  char buf[10];
  ltoa(c, buf,10);
  strcpy(reply,buf);
}


/***********************************************
 * MESSAGE METHODS
 ***********************************************/
Message::Message() {
  init();
}

Message::Message(char *msgString) {
  init();
  load(msgString);
}

void Message::load(char *msgString) {
  strcpy(_msgString, msgString);
  parse();
}

Command *Message::getCmd() {
  Command *c; 
  if (cmdretindex > cmdindex-1) return NULL;
  c = &cmds[cmdretindex];
  cmdretindex++;
  return c;
}

int Message::len() {
  return cmdindex;
}
void Message::reset() {
  int i;
  senderAddress = NULL;
  recieverAddress = NULL;
  *_msgString='\0';
  cmdindex = 0;
  cmdretindex = 0;
  err = NOERR;
  for(i=0;i<=MAXCMDS;i++) {
    cmds[i].clear();
  }

}

char Message::getSenderAddress() {
  return senderAddress;
}

char Message::getRecieverAddress() {
  return recieverAddress;
}

void Message::setSenderAddress(char address) {
  senderAddress = address;
}

void Message::setRecieverAddress(char address) {
  recieverAddress = address;
}

void Message::init() {
  reset();
}

void Message::parse() {
  char *paddrr;
  char *psend;
  char *prec;
  char *pcmd;
  char *pparam;
  char *context1;
  char *context2;
  char *context3;

  paddrr = strtok(_msgString,ADDSEP1); //NOw Points to tokenized Address
  paddrr+=2;

  prec = strtok_r(paddrr,ADDSEP2,&context3); //Now points to tokenized reciever
  psend = strtok_r(NULL,ADDSEP2,&context3); //Now points to tokenized sender

  setSenderAddress(*psend);
  setRecieverAddress(*prec);

  pcmd = strtok(NULL,ADDSEP1);  //Now points to begining of commands
  pcmd = strtok_r(pcmd, CMDSEP, &context1); //Now points tokenized first commands with param

  while(pcmd) {
    pparam=NULL;
    context2 = NULL;
    pcmd = strtok_r(pcmd, PARAMSEP, &context2); //Now points to only command
    pparam = strtok_r(NULL, PARAMSEP, &context2); //For some reason this doesnt work when PARAMSEP not in string???!!?

  
    if (addCommand(pcmd,pparam)<0) {
      break;
    };
    pcmd = strtok_r(NULL, CMDSEP, &context1); //Move to next command
  }    

}

int8_t Message::addCommand(char* cmd, char *param) {
  if (cmdindex > MAXCMDS) {
    return TOOLONGERR;
  } 
  else {
    cmds[cmdindex].setCmd(cmd);
    cmds[cmdindex].setParam(param);
    cmds[cmdindex].setReply("");
  }
  cmdindex++;
  return NOERR;
}

char * Message::reply() {
  //char reply[REPLYLEN];
  int index = 0;
  strcpy(response, getHeader());

  for(int i = 0;i<cmdindex;i++) {
    strcat(response, RESPCHAR);
    strcat(response, cmds[i].getCmd());
    if (strlen(cmds[i].getReply()) > 0) {
      strcat(response,PARAMSEP);
      strcat(response, cmds[i].getReply());
    }
    strcat(response, CMDSEP);
  }
  index = strlen(response);
  response[index] = ENDMSG;
  response[index+1] = '\0';

  return response;
}

char *Message::getHeader() {
  header[0] = STARTMSG;
  header[1] = STARTMSG;
  header[2] = getSenderAddress();
  header[3] = '\0';
  strcat(header, ADDSEP2);
  header[4] = mojo.getAddress();
  header[5] = '\0';
  strcat(header, ADDSEP1);
  header[6] = '\0';

  return header;

}

