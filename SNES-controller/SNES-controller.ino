/* Quick and dirty (S)NES to Arduboy button driver v1.2 by Mr.Blinky Apr 2018-Jul 2020
 *
 * Using digital pins so it can be easily run on any Arduino
 * Because DigitalRead and DigitalWrite are pretty slow, no delays are
 * required when changing controller pin states and reading in data
 *
 * SNES pinout     NES pinout
 *     _                __
 *    / \          GND |O \
 *    |O| GND    CLOCK |O O\ 5V
 *    |O|        LATCH |O O| 
 *    |O|         DATA |O O|
 *    |-|              |___|
 *    |O| DATA 
 *    |O| LATCH
 *    |O| CLOCK
 *    |O| 5V   
 *    |_|      
 *    
 *    ver 1.1: swapped NES controller A + B buttons, added reset pin.
 */
#define SNES_CONTROLLER //remark this line when using NES controller

//Arduboy button state masks
#define BS_UP    _BV(7)
#define BS_DOWN  _BV(4)
#define BS_LEFT  _BV(5)
#define BS_RIGHT _BV(6)
#define BS_A     _BV(3)
#define BS_B     _BV(2)

//Arduboy button driver pins
#define BUTTON_A      7
#define BUTTON_B      8
#define BUTTON_UP     A0
#define BUTTON_DOWN   A3
#define BUTTON_LEFT   A2
#define BUTTON_RIGHT  A1
#define BUTTON_RESET  9

//button status LED
#define LED     17    //RxLED on Pro Micro
#define LED_ON  LOW
#define LED_OFF HIGH

//controller pins
#define CONTROLLER_DATA  2
#define CONTROLLER_LATCH 3
#define CONTROLLER_CLOCK 4

//controller buttons to Arduboy buttons mappings
#define CONTROLLER_B        BS_A
#define CONTROLLER_Y        BS_B
#define CONTROLLER_SELECT   (BS_UP | BS_DOWN)
#define CONTROLLER_START    (BS_LEFT| BS_RIGHT)
#define CONTROLLER_UP       BS_UP
#define CONTROLLER_DOWN     BS_DOWN
#define CONTROLLER_LEFT     BS_LEFT
#define CONTROLLER_RIGHT    BS_RIGHT
#define CONTROLLER_A        BS_B
#define CONTROLLER_X        BS_A
#define CONTROLLER_L        BS_LEFT
#define CONTROLLER_R        BS_RIGHT

uint8_t buttons_state;

void setup()
{
  //controller pins
  pinMode(CONTROLLER_DATA,INPUT_PULLUP);
  pinMode(CONTROLLER_LATCH,OUTPUT);
  pinMode(CONTROLLER_CLOCK,OUTPUT);

  //button driver pins
  pinMode(BUTTON_A,OUTPUT);
  pinMode(BUTTON_B,OUTPUT);
  pinMode(BUTTON_UP,OUTPUT);
  pinMode(BUTTON_DOWN,OUTPUT);
  pinMode(BUTTON_LEFT,OUTPUT);
  pinMode(BUTTON_RIGHT,OUTPUT);
  //button status LED
  pinMode(LED,OUTPUT);
  digitalWrite(LED,LED_OFF);
}

void updateButtonState(uint8_t button)
{
  if (!digitalRead(CONTROLLER_DATA))
  {
    if (button == CONTROLLER_SELECT) setResetPin();
    buttons_state |= button;
  }
  digitalWrite(CONTROLLER_CLOCK,HIGH); //clock out next button state
  digitalWrite(CONTROLLER_CLOCK,LOW);
}

void setButtonPin(uint8_t mask, uint8_t button)
{
  if ((buttons_state & mask) != 0) digitalWrite( button,LOW);
  else digitalWrite( button,HIGH);
}

void setResetPin()
{
  pinMode(BUTTON_RESET, OUTPUT);
  digitalWrite(BUTTON_RESET, LOW);
  delay(100);
  pinMode(BUTTON_RESET,INPUT);
}

void loop()
{ //read controller button states
  buttons_state = 0;
  digitalWrite(CONTROLLER_LATCH,HIGH); //parallel load controller button states
  digitalWrite(CONTROLLER_CLOCK,LOW);  //ensure clock is low when switching to serial mode
  digitalWrite(CONTROLLER_LATCH,LOW);  //switch to serial mode
#ifdef SNES_CONTROLLER
  updateButtonState(CONTROLLER_B);
  updateButtonState(CONTROLLER_Y);
#else
  updateButtonState(CONTROLLER_A);
  updateButtonState(CONTROLLER_B);
#endif
  updateButtonState(CONTROLLER_SELECT);
  updateButtonState(CONTROLLER_START);
  updateButtonState(CONTROLLER_UP);
  updateButtonState(CONTROLLER_DOWN);
  updateButtonState(CONTROLLER_LEFT);
  updateButtonState(CONTROLLER_RIGHT);
#ifdef SNES_CONTROLLER
  updateButtonState(CONTROLLER_A);
  updateButtonState(CONTROLLER_X);
  updateButtonState(CONTROLLER_L);
  updateButtonState(CONTROLLER_R);
#endif

  //set button output pins
  setButtonPin(BS_A, BUTTON_A);
  setButtonPin(BS_B, BUTTON_B);
  setButtonPin(BS_UP, BUTTON_UP);
  setButtonPin(BS_DOWN, BUTTON_DOWN);
  setButtonPin(BS_LEFT, BUTTON_LEFT);
  setButtonPin(BS_RIGHT, BUTTON_RIGHT);
  
  //update button status LED
  if (buttons_state) digitalWrite(LED,LED_ON);
  else digitalWrite(LED,LED_OFF);
}
