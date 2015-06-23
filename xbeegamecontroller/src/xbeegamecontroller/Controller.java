package xbeegamecontroller;

import com.digi.xbee.api.Raw802Device;
import com.digi.xbee.api.RemoteXBeeDevice;
import com.digi.xbee.api.XBeeDevice;
import com.digi.xbee.api.exceptions.XBeeException;
import com.digi.xbee.api.io.IOLine;
import com.digi.xbee.api.io.IOSample;
import com.digi.xbee.api.io.IOValue;
import com.digi.xbee.api.listeners.IIOSampleReceiveListener;
import processing.core.PApplet;

import java.lang.reflect.Method;

public class Controller {
    private final IOLine xAxis = IOLine.DIO2_AD2;
    private final IOLine yAxis = IOLine.DIO1_AD1;
    private final IOLine rightButton = IOLine.DIO4_AD4;
    private final IOLine leftButton = IOLine.DIO6;

    private PApplet parent;
    private Method buttonEvent;

    private XBeeDevice xBeeDevice;

    private int x, y;
    private IOValue rightLast, leftLast;

    /* The constructor really should not take a port and baud, it should be able to specify a remote XBee
       the data of which we are handling.  For the moment, just assume that only one XBee will report on this
       network and that XBee is the game controller. We could allow the user to provide an array of XBee EUI64
       values and use that to recognize multiple controllers.
     */

    public Controller(PApplet p, String port, int baud) throws XBeeException {
        parent = p;
        p.registerMethod("dispose", this);
        try {
            buttonEvent = parent.getClass().getMethod("buttonEvent", boolean.class, boolean.class);
        } catch (Exception e) {
            // No event in user's sketch to call
        }

        System.out.println(buttonEvent);

        xBeeDevice = new Raw802Device(port, baud);
        xBeeDevice.open();
        xBeeDevice.addIOSampleListener(new IIOSampleReceiveListener() {
            @Override
            public void ioSampleReceived(RemoteXBeeDevice remoteXBeeDevice, IOSample ioSample) {
                // Inverted due to orientation of joystick on board
                x = ioSample.getAnalogValue(xAxis);
                y = 1023 - ioSample.getAnalogValue(yAxis);

                doButtonEvents(ioSample);
            }
        });
    }

    private void doButtonEvents(IOSample ioSample) {
        if (buttonEvent != null) {
            try {
                IOValue rightValue = ioSample.getDigitalValue(rightButton);
                IOValue leftValue = ioSample.getDigitalValue(leftButton);

                if (rightValue != rightLast || leftValue != leftLast) {
                    buttonEvent.invoke(parent, leftValue == IOValue.LOW, rightValue == IOValue.LOW);
                }

                rightLast = rightValue;
                leftLast = leftValue;

            } catch (Exception e) {
                System.err.println("Disabled xbeegamecontroller buttonEvent due to error");
                e.printStackTrace();
                buttonEvent = null;
            }
        }
    }

    public void dispose() {
        xBeeDevice.close();
    }

    public int getX() {
        return x;
    }

    public int getY() {
        return y;
    }
}
