/*
Extra utils holder for over-engineering methods
 
 [fill in details as needed here, for future]
 License: "seek GITA for wisdom"
 
 -love
 Laoban SD
 */

// Copy pasted from here (method 6, as dated on 08.03.2022):
// https://www.techiedelight.com/validate-ip-address-java/
import java.net.Inet4Address;
import java.net.UnknownHostException;



public static boolean isValidInet4Address(String ip) {
  try {
    if (ip.equals("localhost"))
      return true;
    else
      return Inet4Address.getByName(ip).getHostAddress().equals(ip);
  }
  catch (UnknownHostException ex) {
    return false;
  }
}


// ** imports for adding pop-up dialog box on launch
import java.awt.Dimension;
import javax.swing.UIManager;
import javax.swing.JOptionPane;

boolean disable_popup = true;
String app_title = "Single Strip Neopixel ArtNet controller";
String poup_msg = "VER: 0.1\nDate: Mar 2022\n\nA simple trigger based [MQTT]\nSingle addressable neopixel led strip\n"+
  "content controller, based on\nARTNET.\n\nBY: Matthieu Cherubini & Saurabh Datta\n" +
  "Innovation Center Asia";
