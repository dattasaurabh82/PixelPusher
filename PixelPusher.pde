// ** imports for adding ping command string attrbutes
import java.io.*;
import java.util.*;

import mqtt.*;
import ch.bildspur.artnet.*;
import ch.bildspur.artnet.packets.*;
import ch.bildspur.artnet.events.*;
import controlP5.*;
import processing.video.*;



/*
 TODO:
 [x] Fix bug with high pixel nbr
 [x] Save/Load settings
 [x] Reset
 [x] ArtNet connectivity
 [] Resize video to default size
 [x] Remove one layer
 [x] Activate one layer on press
 [x] Proper value on array to send DMX values
 [x] Take appropriate color depending on pixel position (right/left)
 [] Extend to more universe
 [x] Add margin static variable
 [x] Not saving when passing from one field to another
 [x] Pause/Resume videos
 [x] Deal when trying to load file from the settings and it's removed
 [x] Button to load file
 -- Indian's additions / recommendations
 [-] Make a button to clear LED pixels.
 [x] On exit, trigger "clear" LED pixels beore exiting.
 [x] [prev bug] [note: check on win] [method: update()]frame count based constant Artnet IP addr validation.
 [x] [prev bug] [note: check on win] [method: update()]fix Frame Freezing on cursor entering input text field for artnet client's
 [x] IP validation for artNet client's IP
 [-] IP validation for MQTT client's IP [Matthieu] [ref: use boolean "isValidInet4Address(String addr)"]
 [x] Better highlight the current strip (thicker + Green color frame )
 [x] Add an info pop-up on launch
 [] clonsole   pay pause clear etc. 
 */

Println console;

static final int pingdelay = 10;


static final color FONT_COLOR = #cccccc;
static final color FONT_COLOR_DARK = #222222;
static final color COLOR_MAIN = #cccccc;
static final color COLOR_SIDE = #00c66e;
static final color COLOR_GREEN = #00c66e;
static final color COLOR_RED = #DD2737;

static final int MARGIN = 50;
static final int LAYER_SPACING = 120;
static final PVector VIDEO_S = new PVector(500, 40);
static final int PIXEL_SIZE = 20;

static int PIXEL_NBR = 170;
static int ACTIVE_LAYER = -1;

enum OS {
  WINDOWS,
    MAC,
    UNIX
}


ControlP5 cp5;
ArtNetClient artNet;
boolean isArtnetConnected = false;
boolean prevArtnetStatus = false;
String artnet_client_ip = "127.0.0.1";
String old_artnet_client_ip = "127.0.0.1";

MQTTClient mqtt;
boolean isMqttConnected = false;
String currentTopic;

LayerContainer[] layers = new LayerContainer[4];

OS os;

void setup() {
  //Base sketch init
  size(1680, 800);

  surface.setTitle(app_title);
  surface.setLocation(displayWidth/2-width/2, displayHeight/2-height/2);

  //Quit handler
  DisposeHandler dh = new DisposeHandler(this);

  //Check OS
  String strOS = System.getProperty("os.name");
  if (strOS.contains("Windows"))
    os = OS.WINDOWS;
  else if (strOS.contains("Mac"))
    os = OS.MAC;
  else if (strOS.contains("Linux"))
    os = OS.UNIX;

  //Setup
  frameRate(30);
  noStroke();
  textAlign(CENTER, CENTER);

  PFont font = createFont("RobotoMono-Regular.ttf", 14);
  PFont fontS = createFont("RobotoMono-Regular.ttf", 12);
  textFont(font);

  //CP5
  cp5 = new ControlP5(this);
  cp5.setColorBackground(COLOR_MAIN);
  cp5.setColorForeground(COLOR_SIDE);
  cp5.setColorActive(COLOR_GREEN);
  cp5.setFont(new ControlFont(font));

  ControlFont cfSmall = new ControlFont(fontS);

  cp5.addTextfield("mqtt_server", MARGIN, MARGIN, 300, 40)
    .setValue("mqtt://localhost:1883")
    .setColor(FONT_COLOR_DARK)
    .setAutoClear(false)
    .getCaptionLabel().setText("MQTT SERVER").setColor(FONT_COLOR).setFont(cfSmall);

  cp5.addTextfield("mqtt_topic", MARGIN, 80+MARGIN, 300, 40)
    .setValue("/pixelpusher/layer")
    .setColor(FONT_COLOR_DARK)
    .setAutoClear(false)
    .getCaptionLabel().setText("MQTT TOPIC").setColor(FONT_COLOR).setFont(cfSmall);

  cp5.addTextfield("artnet_ip", 400+MARGIN, MARGIN, 300, 40)
    .setValue("127.0.0.1")
    .setColor(FONT_COLOR_DARK)
    .setAutoClear(false)
    .getCaptionLabel().setText("ARTNET IP").setColor(FONT_COLOR).setFont(cfSmall);

  cp5.addTextfield("pixel_nbr", 790+MARGIN, MARGIN, 80, 40)
    .setValue(String.valueOf(PIXEL_NBR))
    .setColor(FONT_COLOR_DARK)
    .setAutoClear(false)
    .getCaptionLabel().setText("PIXEL NUMBER\n- 1 to 170 -").setColor(FONT_COLOR).setFont(cfSmall);

  cp5.addButton("save_settings")
    .setPosition(width-200-MARGIN, MARGIN)
    .setSize(180, 40)
    .setColorBackground(FONT_COLOR)
    .setColorActive(FONT_COLOR_DARK)
    .getCaptionLabel().setText("SAVE").setColor(FONT_COLOR_DARK);

  cp5.addButton("load_settings")
    .setPosition(width-200-MARGIN, 50+MARGIN)
    .setSize(180, 40)
    .setColorBackground(FONT_COLOR)
    .setColorActive(FONT_COLOR_DARK)
    .getCaptionLabel().setText("LOAD").setColor(FONT_COLOR_DARK);

  cp5.addButton("reset")
    .setPosition(width-200-MARGIN, 100+MARGIN)
    .setSize(180, 40)
    .setColorBackground(FONT_COLOR)
    .setColorActive(FONT_COLOR_DARK)
    .getCaptionLabel().setText("RESET").setColor(FONT_COLOR_DARK);

  cp5.addButton("play_movies")
    .setPosition(MARGIN, 730)
    .setSize(100, 40)
    .setColorBackground(FONT_COLOR)
    .setColorActive(FONT_COLOR_DARK)
    .getCaptionLabel().setText("PLAY").setColor(FONT_COLOR_DARK);

  cp5.addButton("pause_movies")
    .setPosition(MARGIN+110, 730)
    .setSize(100, 40)
    .setColorBackground(FONT_COLOR)
    .setColorActive(FONT_COLOR_DARK)
    .getCaptionLabel().setText("PAUSE ALL").setColor(FONT_COLOR_DARK);

  Textarea consoleArea =
    cp5.addTextarea("console")
    .setPosition((width/2) + 100, MARGIN)
    .setSize(480, 140)
    .setColor(FONT_COLOR_DARK)
    .setColorBackground(#555555)
    .setColorForeground(COLOR_GREEN);

  console = cp5.addConsole(consoleArea);

  println("[OS] " + os);

  //Init all the layers
  for (int i=0; i<layers.length; i++) {
    layers[i] = new LayerContainer(this, i, new PVector(MARGIN, 200 + MARGIN + (i*LAYER_SPACING)), cp5);
  }

  //Load settings
  load_settings();

  //ArtNet
  // -- M's edit
  //thread("artnet_ip");

  // -- D's edit
  artnet_client_ip = cp5.get(Textfield.class, "artnet_ip").getText();
  println("[ARTNET] Pinging IP: " +  artnet_client_ip);
  thread("check_artnet_client");

  artNet = new ArtNetClient(null);
  artNet.start();

  //MQTT
  mqtt = new MQTTClient(this);
  mqttConnect();


  // - D's addition: pop-up
  if (!disable_popup) {
    UIManager.put("OptionPane.minimumSize", new Dimension(360, 120));
    JOptionPane.showMessageDialog(null, poup_msg, app_title, JOptionPane.CLOSED_OPTION);
  }
}

void update() {
  //-- M's edit
  //Ping ArtNet server every 10s to check connectivity
  //if (frameCount % (frameRate*10) == 0 ) {
  //thread("artnet_ip");
  //}

  // -- D's new edit: Automatically check at certain frequency
  int pm = int(frameCount % (frameRate*pingdelay));
  // == 0, for some reason;s wasn't working
  // Note: makeshift method
  if (pm >= 0 && pm < 2) {
    artnet_client_ip = cp5.get(Textfield.class, "artnet_ip").getText();
    // Note: Ommited "[PING]..." a no need to say "pinging..." all the time because it just floods the console.
    thread("check_artnet_client");
  }

  //// -- D's new edit: Automatically check while typing
  //if (cp5.get(Textfield.class, "artnet_ip").isFocus()) {
  //  artnet_client_ip = cp5.get(Textfield.class, "artnet_ip").getText();
  //  // check if value changed ...
  //  if (!artnet_client_ip.equals(old_artnet_client_ip)) {
  //    // Check for IP validity (if a legit IP, only then ...)
  //    if (isValidInet4Address(artnet_client_ip)) {
  //      println("[ARTNET] IP address is valid");
  //      println("[ARTNET] Pinging IP: " +  artnet_client_ip);
  //      thread("check_artnet_client");
  //      old_artnet_client_ip = artnet_client_ip;
  //    } else {
  //      println("[ARTNET] Not a valid IP Addr.");
  //    }
  //  }
  //}



  //If no active layer, do not send anything
  if (ACTIVE_LAYER == -1)
    return;

  //Convert the active layer colors into a byte array to send over DMX
  color[] colors = layers[ACTIVE_LAYER].visualization.colors;
  byte[] dmxData = new byte[512];
  for (int i=0; i<colors.length; i++) {
    dmxData[i*3] = (byte) red(colors[i]);
    dmxData[i*3+1] = (byte) green(colors[i]);
    dmxData[i*3+2] = (byte) blue(colors[i]);
  }

  //Send the data
  artNet.unicastDmx(cp5.get(Textfield.class, "artnet_ip").getText(), 0, 0, dmxData);
}



void draw() {
  update();

  background(30);

  //Draw connection status for MQTT
  if (isMqttConnected)
    fill(COLOR_GREEN);
  else
    fill(COLOR_RED);
  rect(305+MARGIN, MARGIN, 40, 40);


  //Draw connection status for ArtNet

  if (isArtnetConnected) {
    fill(COLOR_GREEN);
  } else {
    fill(COLOR_RED);
  }
  rect(705+MARGIN, MARGIN, 40, 40);

  // console msg for art net status
  if (isArtnetConnected != prevArtnetStatus) {
    if (isArtnetConnected) {
      println("[ARTNET] client available");
    } else {
      println("[ARTNET] client un-available!");
    }
    prevArtnetStatus = isArtnetConnected;
  }

  fill(255);
  //Draw the layers
  for (LayerContainer layer : layers) {
    layer.draw();
  }
}



static void selectLayer(int _layerID) {
  ACTIVE_LAYER = _layerID;
  println("Active layer: " + ACTIVE_LAYER);
}


void clearLED() {
  byte[] dmxData = new byte[512];
  for (int i=0; i<PIXEL_NBR; i++) {
    dmxData[i*3] = (byte) 0;
    dmxData[i*3+1] = (byte) 0;
    dmxData[i*3+2] = (byte) 0;
  }

  //Send the data
  artNet.unicastDmx(cp5.get(Textfield.class, "artnet_ip").getText(), 0, 0, dmxData);
}


void mqttConnect() {
  if (isMqttConnected)
    mqtt.disconnect();

  try {
    String ip = cp5.get(Textfield.class, "mqtt_server").getText();
    println("[MQTT] Trying to connect to " + ip);
    mqtt.connect(ip, "pixelpusher");
  }
  catch(Exception _e) {
    println("[MQTT] Could not connect to server");
    println(_e.toString());
    isMqttConnected = false;
    return;
  }
}



boolean isOnline(String _ip) {
  boolean status = false;

  // -- M's proposal - tested on win
  if (os == OS.WINDOWS) {
    Runtime r = Runtime.getRuntime();
    try {
      println("[PING] Pinging IP: " + _ip);
      Process p = r.exec("ping " + _ip);
      int ev = p.waitFor();
      if (ev == 0) status = true;
      else status = false;
      //return ev == 0;
    }
    catch(Exception _e) {
      println("[PING] Can't ping");
      //return false;
      status = false;
    }
  } else if (os == OS.MAC) {
    // -- D's new edit - tested on mac
    //boolean status = false;
    List<String> command = new ArrayList<String>();
    command.add("ping");
    command.add("-c");
    command.add("2");
    command.add(_ip);

    ProcessBuilder pb = new ProcessBuilder(command);

    try {
      Process process = pb.start();
      int returnVal = process.waitFor();
      if (returnVal == 0) status = true;
      else status = false;
    }
    catch(Exception _e) {
      status = false;
    }
    //return status;
  }
  return status;
  //return false;
}



///// DELEGATES /////////

void mousePressed() {
  //Check if modification has been made on MQTT text field
  if (cp5.get(Textfield.class, "mqtt_topic").isFocus()) {
    mqtt_topic(cp5.get(Textfield.class, "mqtt_topic").getText());
  }
  if (cp5.get(Textfield.class, "mqtt_server").isFocus()) {
    mqttConnect();
  }
  if (cp5.get(Textfield.class, "pixel_nbr").isFocus()) {
    pixel_nbr(cp5.get(Textfield.class, "pixel_nbr").getText());
  }
  //if (cp5.get(Textfield.class, "artnet_ip").isFocus()) {
  //  thread("artnet_ip");
  //}
  // ** No need to check here on mouse entry.
  // ** We should instead check while we are typing in the field, moved to: update()
}

// [x]on key pressed
// [x]in art net ip field
// [x]check text for 3 dots
// [x]then check for ip validity
// [x]then trigger a 1 time event (if not equal to last value)

//void keyPressed() {
//  if (cp5.get(Textfield.class, "artnet_ip").isFocus()) {
//    artnet_client_ip = cp5.get(Textfield.class, "artnet_ip").getText();
//    long dot_count = artnet_client_ip.chars().filter(ch -> ch == '.').count();
//    if (dot_count == 3) {
//      if (isValidInet4Address(artnet_client_ip)) {
//        if (!artnet_client_ip.equals(old_artnet_client_ip)) {
//          println("[ARTNET] IP address is valid");
//          println("[ARTNET] Pinging IP: " +  artnet_client_ip);
//          thread("check_artnet_client");
//          old_artnet_client_ip = artnet_client_ip;
//        }
//      }
//    }
//  }
//}


//Movies
void movieEvent(Movie _m) {
  _m.read();
}

//CP5
void mqtt_topic(String _str) {
  if (!isMqttConnected)
    return;

  //Unsubscribe from old topic and register to the new one
  mqtt.unsubscribe(currentTopic);
  currentTopic = _str;
  mqtt.subscribe(currentTopic);
}

void mqtt_server(String _s) {
  mqttConnect();
}

// -- M's edit
//void artnet_ip(){
//  //Ping artnet IP
//  isArtnetConnected = isOnline(cp5.get(Textfield.class, "artnet_ip").getText());
//}

// -- D's edits
// The prev func was a callback function from the cp5 textField() instance and the supplied argument
// is the text from the field. On change, we can read that.
// ** Note for M: You were using the name of the callback function, without arguments and calling the same callback function from other events.
void artnet_ip(String _ip) {
  artnet_client_ip = _ip;
  // Check for IP validity. if a legit IP, then ...
  if (isValidInet4Address(artnet_client_ip)) {
    println("[ARTNET] Pinging IP: " +  artnet_client_ip);
    thread("check_artnet_client");
  } else {
    println("[ARTNET] Not a valid IP Addr.");
  }
}


// this an alternate function, just like the call back function above
void check_artnet_client() {
  isArtnetConnected = isOnline(artnet_client_ip);
}

void pixel_nbr(String _pxlNbr) {
  try {
    int tmp = Integer.parseInt(_pxlNbr);
    if (tmp > 0 && tmp < 171)
      PIXEL_NBR = tmp;
    else
      return;
  }
  catch(Exception _e) {
    println("[PIXEL NBR] Wrong value input");
    return;
  }

  //Reset the pixelvisualization with new pixel number
  for (LayerContainer layer : layers) {
    layer.visualization.reset();
  }
}

void save_settings() {
  println("Save settings");

  String mqttServer = cp5.get(Textfield.class, "mqtt_server").getText();
  String mqttTopic = cp5.get(Textfield.class, "mqtt_topic").getText();
  String artnetIp = cp5.get(Textfield.class, "artnet_ip").getText();

  JSONObject json = new JSONObject();

  json.setString("mqtt_server", mqttServer);
  json.setString("mqtt_topic", mqttTopic);
  json.setString("artnet_ip", artnetIp);
  json.setInt("pixel_nbr", PIXEL_NBR);

  JSONArray fNames = new JSONArray();
  for (int i=0; i<layers.length; i++) {
    JSONObject p = new JSONObject();
    p.setString("file_" + i, layers[i].path);
    fNames.setJSONObject(i, p);
  }
  json.setJSONArray("video_paths", fNames);

  saveJSONObject(json, "data/settings.json");
}

void load_settings() {
  println("Load settings");

  JSONObject json = loadJSONObject("data/settings.json");

  cp5.get(Textfield.class, "mqtt_server").setText(json.getString("mqtt_server"));
  cp5.get(Textfield.class, "mqtt_topic").setText(json.getString("mqtt_topic"));
  cp5.get(Textfield.class, "artnet_ip").setText(json.getString("artnet_ip"));

  PIXEL_NBR = json.getInt("pixel_nbr");
  cp5.get(Textfield.class, "pixel_nbr").setText(String.valueOf(PIXEL_NBR));

  JSONArray fNames = json.getJSONArray("video_paths");
  for (int i=0; i<fNames.size(); i++) {
    String name = fNames.getJSONObject(i).getString("file_" + i);
    if (name != null)
      layers[i].setMovie(this, name);
  }
}

void reset() {
  println("Reset");

  JSONObject json = new JSONObject();

  json.setString("mqtt_server", "mqtt://localhost:1883");
  json.setString("mqtt_topic", "/pixelpusher/layer");
  json.setString("artnet_ip", "127.0.0.1");
  json.setInt("pixel_nbr", 170);

  JSONArray fNames = new JSONArray();
  for (int i=0; i<layers.length; i++) {
    JSONObject p = new JSONObject();
    p.setString("file_" + i, "");
    fNames.setJSONObject(i, p);
    layers[i].stopMovie();
  }
  json.setJSONArray("video_paths", fNames);

  saveJSONObject(json, "data/settings.json");

  load_settings();
}

void play_movies() {
  for (LayerContainer layer : layers) {
    if (layer.movie == null)
      continue;
    layer.movie.loop();
  }
}

void pause_movies() {
  for (LayerContainer layer : layers) {
    if (layer.movie == null)
      continue;
    layer.movie.pause();
  }
}

//FILE SELECTION
void fileSelected(File _fSelect, int _id) {
  for (LayerContainer layer : layers) {
    if (_id == layer.id) {
      layer.setMovie(this, _fSelect.getAbsolutePath());
      break;
    }
  }
}

void fileSelected_0(File _fSelect) {
  fileSelected(_fSelect, 0);
}

void fileSelected_1(File _fSelect) {
  fileSelected(_fSelect, 1);
}

void fileSelected_2(File _fSelect) {
  fileSelected(_fSelect, 2);
}

void fileSelected_3(File _fSelect) {
  fileSelected(_fSelect, 3);
}

//MQTT
void messageReceived(String _topic, byte[] _payload) {
  int t = Integer.parseInt(new String(_payload));
  println("[MQTT] Received: " + t + " from " + _topic);

  if (_topic.equals(currentTopic) && t < layers.length && t >= 0) {
    selectLayer(t);
  }
}

void clientConnected() {
  println("[MQTT] Connected");

  isMqttConnected = true;
  currentTopic = cp5.get(Textfield.class, "mqtt_topic").getText();
  mqtt.subscribe(currentTopic);
}

void connectionLost() {
  println("[MQTT] Connection lost");
  isMqttConnected = false;
}


//boolean pauseConsole;
//void keyPressed() {
//  switch(key) {
//    case('p'):
//    pauseConsole = !pauseConsole;
//    break;
//    case('c'):
//    console.clear();
//    break;
//  }

//  if (pauseConsole) {
//    println("console paused");
//    println("press \"p\" to un-pause");
//    delay(10);
//    console.pause();
//  } else {
//    console.play();
//    println("un-paused");
//  }
//}
