#include "HardwareSerialRS485.h"

int Ctrl1 = 2;
  int count = 10;
  int i = 0;
char buffer[10];


void setup() {  
  
  Serial1RS485.begin(9600);
  Serial1RS485.setControlPin(2);

}

void loop() {
  int c;
  
  
  Serial1RS485.println("Writing");
  
}
