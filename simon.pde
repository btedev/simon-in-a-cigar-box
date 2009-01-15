/* ==================================================
  Simon in a Cigar Box - a Simon-like memory game for the Arduino.  
  The MIT License (http://www.opensource.org/licenses/mit-license.php)
  Copyright (c) 2009 Barry Ezell  
===================================================*/

#define MAX 10          //user will win when successfully repeating MAX sequences.  
#define LED_1 7
#define LED_2 8
#define LED_3 10
#define LED_4 11
#define BUTTON_1 2
#define BUTTON_2 3
#define BUTTON_3 4
#define BUTTON_4 5
#define SPEAKER 9

// TONES  ==========================================
#define C1 3830    // 261 Hz 
#define E1 3038
#define G1 2550
#define C2 1912

// STATES =========================================
#define NEW 0
#define SIMON 1
#define USER 2
#define END 3

int seq[MAX];              //array holding simon-generated sequence
int userSeq[MAX];          //array holding user-input sequence
int curPos=1;              //current position in sequence (start with two lights/tones)
int userPos=-1;             //sequence user has clicked thus far in turn
int buttons[] = { BUTTON_1,BUTTON_2,BUTTON_3,BUTTON_4 };
int leds[]={ LED_1,LED_2,LED_3,LED_4 };
int tones[]={ C1,E1,G1,C2 };  //each led/button/tone is related by index
int state = NEW;
int buttonTmp=-1;
boolean won=false;          //records whether user won for use in end-state blinking

void setup() { 
  pinMode(SPEAKER,OUTPUT);
  pinMode(BUTTON_1,INPUT);
  pinMode(BUTTON_2,INPUT);
  pinMode(BUTTON_3,INPUT);
  pinMode(BUTTON_4,INPUT);
  pinMode(LED_1,OUTPUT);
  pinMode(LED_2,OUTPUT);
  pinMode(LED_3,OUTPUT);
  pinMode(LED_4,OUTPUT);
  randomSeed(analogRead(0));  //reading analog from an unconnected pin
  testComponents();
}

void loop() {
  switch(state) {
    case SIMON:
      goSimon();
      break;
    case USER:
      goUser();
      break;
    case NEW:
      makeGame();
      break;
    case END:
      signalEnd();
      break;
  }
}

void makeGame() {
  for(int i=0; i<MAX; i++) {
    seq[i]=random(0,4);   
  }
  state=SIMON;  //simon's turn first!
}

void goSimon() {
  int signal;  //led/tone combo 
  delay(1000);
  for(int i=0; i<=curPos; i++) {
    signal=seq[i];
    digitalWrite(leds[signal],HIGH);
    playTone(tones[signal],200000);
    digitalWrite(leds[signal],LOW);
    delay(200);
  }  
  state=USER; 
}

void goUser() {
  //Loop over buttons, if pressed and buttonTmp is not set (== -1), set buttonTmp.
  //If buttonTmp unset and buttonTmp has a value, add this to the user-pressed sequence.  
  boolean allLow = true;
  for(int i=0; i<4; i++) {
    if (digitalRead(buttons[i]) == HIGH && buttonTmp == -1) {
      buttonTmp = i;      
      allLow = false;
      //signal user that we've registered button by lighting corresponding led and sounding tone
      digitalWrite(leds[i],HIGH);
      playTone(tones[i],130000);
      digitalWrite(leds[i],LOW);
    } 
  }
  
  if (allLow && buttonTmp > -1) {
    //user just released button, add button to sequence
    userPos+=1;
    userSeq[userPos]=buttonTmp;
    buttonTmp=-1;    
    delay(200);
    
    if (!checkSequence(userPos)) {     
      signalLoss();      
    } else if (userPos == curPos) {
      if (userPos == MAX-1) {
        signalWin();
      } else {
        userPos=-1;
        curPos+=1;
        state=SIMON;          
      }
    }//check sequence correct
  }//if button just released
}

boolean checkSequence(int userPos) {
  for(int i=0; i<=userPos; i++) {
    if (seq[i] != userSeq[i]) return false;
  }
  return true;
}

// Pulse the SPEAKER to play a tone for a particular duration
void playTone(int tone, long duration) {
  long elapsed_time = 0;
  while (elapsed_time < duration) {
    digitalWrite(SPEAKER,HIGH);
    delayMicroseconds(tone / 2);

    // DOWN
    digitalWrite(SPEAKER, LOW);
    delayMicroseconds(tone / 2);

    // Keep track of how long we pulsed
    elapsed_time += (tone);
  }
}

void signalEnd() {
  //note: signalLoss() or signalWin() will always preceed this
  int led = 0;
  if (won) {
    led = LED_4;
  } else {
    led = LED_1;
  }
  digitalWrite(led,HIGH);
  delay(700);
  digitalWrite(led,LOW);
  delay(700);
}

void signalLoss() {
  playTone(6000,120000); 
  delay(20);
  playTone(6000,120000); 
  state=END;
}

void signalWin() {
  playTone(G1,120000);
  delay(20);
  playTone(C2,120000);
  delay(20);
  playTone(C2,120000);
  won=true;
  state=END;
}

void testComponents() {
  for(int i=0; i<4; i++) {
    digitalWrite(leds[i],HIGH);
    playTone(tones[i],100000); 
    digitalWrite(leds[i],LOW);
  } 
}
