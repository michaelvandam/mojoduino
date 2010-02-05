
#ifndef HardwareSerialRS485_h
#define HardwareSerialRS485_h

#include <inttypes.h>

#include "HardwareSerial.h"



class HardwareSerialRS485 : public HardwareSerial
{
  protected:
    uint8_t _txc;
    int _pin;
    
  public:
    HardwareSerialRS485(ring_buffer *rx_buffer,
      volatile uint8_t *ubrrh, volatile uint8_t *ubrrl,
      volatile uint8_t *ucsra, volatile uint8_t *ucsrb,
      volatile uint8_t *udr,
      uint8_t rxen, uint8_t txen, uint8_t rxcie, uint8_t udre, uint8_t u2x, uint8_t txc);
      void setControlPin(int pin);
      void begin(long baud, int pin);
    /* default implementation: may be overridden */
    virtual void write(const char *str);
    virtual void write(const uint8_t *buffer, size_t size);
    
    
    using HardwareSerial::begin;        
    using HardwareSerial::write;
};


extern HardwareSerialRS485 SerialRS485;

#if defined(__AVR_ATmega1280__)
extern HardwareSerialRS485 Serial1RS485;
extern HardwareSerialRS485 Serial2RS485;
extern HardwareSerialRS485 Serial3RS485;
#endif

#endif
