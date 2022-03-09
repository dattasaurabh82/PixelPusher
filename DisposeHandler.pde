public class DisposeHandler{
    PixelPusher pixelPusher;
    
    DisposeHandler(PixelPusher _pp){
        pixelPusher = _pp;
        pixelPusher.registerMethod("dispose", this);
    }
    
    public void dispose(){
        pixelPusher.clearLED();
    }
}
