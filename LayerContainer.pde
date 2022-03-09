class LayerContainer {

  Movie movie;
  PixelVisualization visualization;

  PVector pos;
  PVector videoPos;
  PVector visualizationPos;
  int id;
  Button activateBtn;
  Button loadBtn;
  String path;


  LayerContainer(PixelPusher _pp, int _id, PVector _pos, ControlP5 _cp5) {
    id = _id;

    pos = _pos;
    videoPos = new PVector(_pos.x + 100, _pos.y);
    visualizationPos = new PVector(_pos.x + 100, _pos.y + VIDEO_S.y + 5);

    //Init pixel visualization
    visualization = new PixelVisualization(visualizationPos);

    //Init Cp5 UI for this layer
    _cp5.addTextlabel("LAYER_" + id)
      .setText("LAYER " + id)
      .setPosition((int) _pos.x, (int) _pos.y)
      .setColorValue(PixelPusher.FONT_COLOR);

    activateBtn = _cp5.addButton("activate_layer_" + id)
      .setPosition(pos.x+3, pos.y+25)
      .setSize(60, 15)
      .setColorBackground(PixelPusher.FONT_COLOR)
      .addListener(new ControlListener() {
      void controlEvent(ControlEvent _e) {
          if(movie != null)
              PixelPusher.selectLayer(id);
      }
    }
    );

    activateBtn.getCaptionLabel().setText("");

    _cp5.addButton("delete_layer_" + id)
      .setPosition(pos.x+3, pos.y+50)
      .setSize(60, 15)
      .setColorBackground(PixelPusher.COLOR_RED)
      .setColorForeground(PixelPusher.FONT_COLOR)
      .setColorActive(COLOR_RED)
      .addListener(new ControlListener() {
      void controlEvent(ControlEvent _e) {
          if(movie != null){
            stopMovie();
            PixelPusher.ACTIVE_LAYER = -1;
            _pp.clearLED();
          }
      }
    }
    )
    .getCaptionLabel().setText("");


    loadBtn = _cp5.addButton("load_video_" + id)
      .setPosition(videoPos.x, videoPos.y+20)
      .setSize((int)PixelPusher.VIDEO_S.x, (int)PixelPusher.VIDEO_S.y)
      .addListener(new ControlListener() {
      void controlEvent(ControlEvent _e) {
        selectInput("Select a video file", "fileSelected_" + id);
        PixelPusher.ACTIVE_LAYER = id;
      }
    }
    );

    loadBtn.getCaptionLabel().setText("LOAD FILE");
  }

  void draw() {
    //Display frame
    noFill();
    stroke(150);

    if (PixelPusher.ACTIVE_LAYER == id) {
      strokeWeight(5);
      stroke(COLOR_GREEN);
    } else {
      strokeWeight(1);
      stroke(150);
    }
    rect(pos.x-10, pos.y-10, width-(2*PixelPusher.MARGIN), PixelPusher.VIDEO_S.y + PixelPusher.PIXEL_SIZE + 5 + 20);

    strokeWeight(1);
    noStroke();

    //Display active rect
    if (PixelPusher.ACTIVE_LAYER == id)
      activateBtn.setColorBackground(PixelPusher.COLOR_GREEN);
    else
      activateBtn.setColorBackground(PixelPusher.FONT_COLOR);
    fill(255);

    //Display video and pixel visualization
    if (movie != null) {
      float pixelW = (width-220) / PixelPusher.PIXEL_NBR;
      image(movie, videoPos.x, videoPos.y, pixelW * PixelPusher.PIXEL_NBR, PixelPusher.VIDEO_S.y);
      visualization.draw(movie);
    }
  }

  //Load the movie which has been drag&dropped
  void setMovie(PixelPusher _p, String _path) {
    //Check if the path exists or if the file still exists
    File f = dataFile(_path);
    if (_path.equals("") || !f.isFile())
      return;

    try {
      movie = new Movie(_p, _path);
      movie.loop();
      path = _path;

      //Hide button
      loadBtn.hide();
    }
    catch(Exception _e) {
      println("[MOVIE] Could not load the movie file");
    }
  }


  //Stop the movie
  void stopMovie() {
    if (movie == null)
      return;

    path = "";
    movie.stop();
    movie.dispose();
    movie = null;

    loadBtn.show();
  }
}
