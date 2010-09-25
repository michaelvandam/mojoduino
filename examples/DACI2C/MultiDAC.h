
/*Functions
#define WRITE      0x00
#define UPDATE     0x01

#define WRITE_UPD  0x03
#define PWR_DWN    0x04
#define ADDRESS    0x0F



Analog Pin Addresses
#define A    0x00
#define B    0x01
#define C    0x02
#define D    0x03
#define E    0x04
#define F    0x05
#define G    0x06
#define H    0x07
#define ALL  0x0F
*/

#ifndef MultiDAC_h
#define MultiDAC_h
#endif

#define WRITE_PWR  0x02
#define MAX_OUT    0x08

class Output{
  public:
    Output(); 				
    Output(char addr, char dacaddress);		
    void setValue(unsigned int value);
    char getAddress();    
    
  private:
    void setPinAddress(char addr);

    //Variables
    char          pinaddress;
    unsigned int  value;
    char          DACaddress;
};

class MultiDAC{
  public:
    MultiDAC(); 				
    MultiDAC(char addr);		
    char  getAddress();    
    Output outputs[8];
    
  private:
    void init();
    void setAddress(char addr);
    //Variables
    char          address;//I2C Bus Address
    unsigned int  value; 
};


