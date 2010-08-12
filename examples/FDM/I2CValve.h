/*
  I2Cvalve library for Wiring & Arduino
*/

#ifndef I2CValve_h
#define I2CValve_h
//#endif

//Set arduino's TWI frequency low.

#define ERR	-1
#define CADDRESS (address<<1)
#define CPOS	'P'
#define HOMEVP	'M'
#define SUPDATE	'S'
#define EMPTY	0x00


class I2CValve{
  public:
    I2CValve(); 				//Initialize a valve object (Constructor)
    I2CValve(char addr, int sz);		//Initialize a valve object, specify address as char
    int getPosition();    //Returns stored position from status var.
    void setPosition(int position);
    void goHome();
    boolean isValidPosition(int position);
    
  private:
    //Methods
    void init();				//Private - initialize values for instance
    void reset();				//Private - resets values in case of error
    void setAddress(char addr); //Private - sets address variable
    void setValveSize(int sz);  //Private - sets size variable
    //Variables
    int 	vstatus;//Position of valve or error if it has occurred.
    int 	size;	//Number of positions on valve
    char 	address;//I2C Bus Address of valve
};

#endif
