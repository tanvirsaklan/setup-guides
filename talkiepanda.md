# Prorject: TokiPanda
## Technical Objective
A robot is built for teaching kids some learning materials through a series of interactive sessions. It includes an audio interface for interacting with the robot. 
### Audio streaming and learning sessions
When the robot is turned on and connects to wifi, it sends an HTTP request to the server to start the learning session. The server responds with a "OK" status, sample response:
```bash
HTTP/1.1 200 OK
Content-Type: application/json
{
    "status": "ok",
    "message": ""
}
```
Then sever sends greetings audio to the robot. Robot plays the audio and waits for the kid to respond. When the learning session starts, server sends an audio containing questions for the kid to answer. Sample incoming question audio:
```bash
HTTP/1.1 200 OK
Content-Type: application/json
{
    "status": "question",
    "message": "
        "audio": "sample.wav",
        "waiting_period": "15"
    "
}
```
Robot plays the audio and waits necessary time (waiting_period) for the kid to respond. After playing the audio, robot activates microphone and collects audio data from the kid. The collected audio is sent back to the server. server responds with "OK" to the robot's request after the audio is sent back.
Sample response \#1:
```bash
HTTP/1.1 200 OK
Content-Type: application/json
{
    "status": "next_question",
    "message": "
        "audio1": "congratulations.wav",
        "audio2": "next_question.wav",
        "waiting_period": "15"
    "
}
```
Sample response \#2:
```bash
HTTP/1.1 200 OK
Content-Type: application/json
{
    "status": "question_repeat",
    "message": "
        "audio1": "saying_wrong_answer.wav",
        "audio2": "question.wav",
        "waiting_period": "15"
    "
}
```
Sample response \#3:
```bash
HTTP/1.1 200 OK
Content-Type: application/json
{
    "status": "next_question_with_previous_answer",
    "message": "
        "audio1": "right_answer.wav",
        "audio2": "next_question.wav",
        "waiting_period": "15"
    "
}
```
### Video feed processing for robot's movement with kids
Video feed is streamed to the server for real-time monitoring. When the robot is turned on, camera feed is enabled and streams video to the server using wifi. Server always responds to the robot's requests as "OK" unless the kid away from the center. Sample response is:
```bash
HTTP/1.1 200 OK
Content-Type: application/json
{
    "status": "ok",
    "message": ""
}
```
When the kid is away, sample server response is:
```bash
HTTP/1.1 200 OK
Content-Type: application/json{
    "status": "move",
    "message": "
        "right":"0.1cm",
        "left":"0.1cm",
        "forward":"0.1cm",
        "backward":"0.0cm",
    "
}
```
Inside robot, esp32s3-N4R16 sends signal to esp32c3-devkit via esp-now. esp32c3-devkit receives the signal and moves the robot accordingly by calculating the distance, motor speed and direction to move.  
## Server design
### Audio processing techniques
An util function `audio_processing` is used to process the audio files and generate the audio responses for the robot. The server compares featured vector of incoming .wav file with the featured vectors of probable answers and scores the percentage similarity. If the similarity score is above a threshold, the server responds with the corresponding audio file. For generating featured vectors of audio files, we used MFCC+DTW algorithom.
Visual representation of audio processing:
```mermaid
graph LR
    incoming.wav --> MFCC --> DTW --> answer.wav --> similarity_score
```
### Database models
Parent and Robot models:
```mermaid
erDiagram
    PARENT {
        int id PK
        string name
        string email
        string password
        string phone
        string address
        string robot_serial_number
    }
    CHILD {
        int id PK
        string name
        string birth_day
        string age
        string gender
        string parent_id FK
    }
    ROBOT {
        int serial_number PK
        string parent_id FK
        string active_child_id FK
        string status
        string session_mode
    }
```
Lessons --> Question --> Answer model:
```mermaid
erDiagram
    LESSON {
        int id PK
        string subject
        string routine_date
    }
    QUESTION {
        int id PK
        string lesson_id FK
        string audio_path
    }
    ANSWER_VARIANT {
        int id PK
        string question_id FK
        string answer_text
    }
    ANSWER_VARIANT_SAMPLE {
        int id PK
        string answer_variant_id FK
        string audio_path_list
        string featured_vector_list
    }
```
Child's lesson completion model:
```mermaid
erDiagram
    CHILD_LESSON_COMPLETION {
        int id PK
        int child_id FK
        int lesson_id FK
        string status
        string completion_date
    }
    CHILD_DAILY_SCORE {
        int id PK
        int child_id FK
        string date
        float score
    }
    CHILD_LEVEL_PROGRESS {
        int id PK
        int child_id FK
        int level
        float progress
        string completion_date
    }
```
now new schematic:
```mermaid
flowchart LR
    %% ======================
    %% POWER SECTION
    %% ======================
    BAT["1S Rechargeable Battery<br/>(18650 / LiPo)<br/>Robot always ON when battery inserted"]
    CHG["TP4056 USB-C Charging Module<br/>with protection preferred"]
    BOOST["5V Boost Converter<br/>Output: 5V, 2A preferred"]
    S3["ESP32-S3-N4R16 Main Board<br/>Main controller"]

    BAT -->|Battery + / -| CHG
    CHG -->|Battery output| BOOST
    BOOST -->|5V rail| S3

    %% ======================
    %% CAMERA SECTION
    %% ======================
    CAM["2MP OV2640 Camera<br/>Use dedicated camera ribbon/connector"]
    CAM -->|Camera interface<br/>do not reuse camera pins| S3

    %% ======================
    %% AUDIO INPUT
    %% ======================
    MIC["INMP441 Omnidirectional I2S Mic<br/>VDD = 3.3V<br/>GND = GND<br/>SCK = GPIO41<br/>WS = GPIO42<br/>SD = GPIO2<br/>L/R = GND"]
    S3 -->|I2S BCLK GPIO41<br/>I2S LRCLK GPIO42| MIC
    MIC -->|I2S mic data GPIO2| S3

    %% ======================
    %% AUDIO OUTPUT
    %% ======================
    AMP["MAX98357A I2S Audio Amplifier<br/>VIN = 5V<br/>GND = GND<br/>BCLK = GPIO41<br/>LRC = GPIO42<br/>DIN = GPIO1"]
    SPK["Speaker<br/>4 ohm, 3W or 5W"]

    S3 -->|I2S BCLK GPIO41<br/>I2S LRCLK GPIO42<br/>Speaker data GPIO1| AMP
    BOOST -->|5V| AMP
    AMP -->|OUT+ / OUT-| SPK

    %% ======================
    %% DISPLAY SECTION
    %% ======================
    OLED["0.96 inch OLED Display<br/>SSD1306 I2C<br/>VCC = 3.3V<br/>GND = GND<br/>SDA = GPIO21<br/>SCL = GPIO14"]
    S3 -->|I2C SDA GPIO21<br/>I2C SCL GPIO14| OLED

    %% ======================
    %% MOTOR SECTION
    %% ======================
    DRV["DRV8833 Dual Motor Driver<br/>VM = 5V motor rail<br/>GND = common GND<br/>AIN1 = GPIO47<br/>AIN2 = GPIO48<br/>BIN1 = GPIO19<br/>BIN2 = GPIO20"]
    LM["Left N20 DC Gear Motor"]
    RM["Right N20 DC Gear Motor"]

    BOOST -->|5V motor rail| DRV
    S3 -->|PWM / direction signals<br/>GPIO47, GPIO48, GPIO19, GPIO20| DRV
    DRV -->|AOUT1 / AOUT2| LM
    DRV -->|BOUT1 / BOUT2| RM

    %% ======================
    %% ANALOG MODE SELECTOR
    %% ======================
    MODE["Analog Mode Selector<br/>Potentiometer / rotary knob / resistor ladder button<br/>One side = 3.3V<br/>Other side = GND<br/>Wiper = ADC input"]
    MODE -->|Analog voltage to ADC pin<br/>choose safe free ADC-capable GPIO| S3

    %% ======================
    %% GROUND NOTE
    %% ======================
    GND["COMMON GND<br/>Battery, charger, boost, ESP32-S3,<br/>mic, amplifier, OLED, motor driver,<br/>and motors must share ground"]

    BAT --- GND
    CHG --- GND
    BOOST --- GND
    S3 --- GND
    MIC --- GND
    AMP --- GND
    OLED --- GND
    DRV --- GND

    %% ======================
    %% PCB CONNECTOR BOARD
    %% ======================
    PCB["Custom PCB Connector Board<br/>Acts as carrier/interconnect board<br/>Place headers/JST connectors for all modules"]

    PCB -.-> S3
    PCB -.-> CAM
    PCB -.-> MIC
    PCB -.-> AMP
    PCB -.-> OLED
    PCB -.-> DRV
    PCB -.-> BAT
    PCB -.-> CHG
    PCB -.-> BOOST
    PCB -.-> MODE

    %% ======================
    %% STYLE
    %% ======================
    classDef power fill:#ffe5e5,stroke:#cc0000,stroke-width:2px;
    classDef controller fill:#e5f0ff,stroke:#0055cc,stroke-width:2px;
    classDef sensor fill:#e8ffe8,stroke:#008800,stroke-width:2px;
    classDef driver fill:#fff3d6,stroke:#cc8800,stroke-width:2px;
    classDef note fill:#f2f2f2,stroke:#444,stroke-width:1px,stroke-dasharray: 5 5;

    class BAT,CHG,BOOST power;
    class S3 controller;
    class CAM,MIC,OLED,MODE sensor;
    class AMP,DRV,SPK,LM,RM driver;
    class GND,PCB note;
```