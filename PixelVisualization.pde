class PixelVisualization{
    
    PVector pos;
    color[] colors;
    
    PixelVisualization(PVector _pos){
        pos = _pos;
        colors = new color[PixelPusher.PIXEL_NBR];
    }
    
    void draw(Movie _m){
        _m.loadPixels();
        if(_m.pixels.length == 0)
            return;
        
        int pvX = (int) pos.x;
        stroke(PixelPusher.FONT_COLOR_DARK);
        
        int pixelW = (width-220) / PixelPusher.PIXEL_NBR;
        int quarter = PixelPusher.PIXEL_NBR / 4;
        int cellW = _m.width / PixelPusher.PIXEL_NBR;
        
        for(int i=0; i<PixelPusher.PIXEL_NBR; i++){
            //Get index in the pixels array related to current color in video
            int v = (int) map(i, 0, PixelPusher.PIXEL_NBR, 0, _m.width);
            //int v = i * cellW;
            
            //Check if the pixel is more on the left/right/middle to pick a color value that match the orientation
            //from 0/4 to 1/4 -> pick left pixel of the cell
            //from 1/4 to 3/4 -> pick middle pixel of the cell
            //from 3/4 to 4/4 -> pick right pixel of the cell
            if(i > quarter && i <= quarter * 3){
                v += (cellW / 2);
            }
            else if(i > quarter * 3){
                v += (cellW-1);
            }
            
            //Get pixel color from the video
            color c = _m.pixels[v];
            
            //Draw the pixel output
            fill(c);
            rect(pvX, pos.y, pixelW, PixelPusher.PIXEL_SIZE);
            pvX += pixelW;
            
            //Save the color 
            colors[i] = c;
        }
        
        noStroke();
    }
    
    void reset(){
        colors = new color[PixelPusher.PIXEL_NBR];
    }
}
