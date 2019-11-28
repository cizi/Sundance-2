using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Lang;
using Toybox.Application;
using Toybox.Time;
using Toybox.Time.Gregorian;

class SundanceView extends WatchUi.WatchFace {
	
	hidden var imgBg;

    function initialize() {
        WatchFace.initialize();
        imgBg = new WatchUi.Bitmap({
            :rezId=>Rez.Drawables.Bg,
            :locX=>0,
            :locY=>0
        });
        
    }

    // Load your resources here
    function onLayout(dc) {
        setLayout(Rez.Layouts.WatchFace(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
    }

    // Update the view
    function onUpdate(dc) {
    	// Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);
        
       	imgBg.draw(dc);
 
        // Get the current time and format it correctly
        var timeFormat = "$1$:$2$";
        var clockTime = System.getClockTime();
        var hours = clockTime.hour;
        if (!System.getDeviceSettings().is24Hour) {
            if (hours > 12) {
                hours = hours - 12;
            }
        } else {
            if (Application.getApp().getProperty("UseMilitaryFormat")) {
                timeFormat = "$1$$2$";
                hours = hours.format("%02d");
            }
        }
        var timeString = Lang.format(timeFormat, [hours, clockTime.min.format("%02d")]);

        // Update the view
        var time = View.findDrawableById("TimeLabel");
        // view.setColor(Application.getApp().getProperty("ForegroundColor"));
        time.setText(timeString);
        time.draw(dc);
        
        var today = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var dateString = Lang.format(
		    "$1$ $2$",
		    [
		        getNameDay(today.day_of_week),
		        today.day
		    ]
		);
        var date = View.findDrawableById("DateLabel");
        // view.setColor(Application.getApp().getProperty("ForegroundColor"));
        
        date.setText(dateString);
        date.draw(dc);
        
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() {
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() {
    }
    
    function getNameDay(dayNr) {
    	switch (dayNr) {
    		case 1:
    		return "Sunday";
    		break;
    		
    		case 2:
    		return "Monday";
    		break;
    		
    		case 3:
    		return "Tuesday";
    		break;
    		
    		case 4:
    		return "Wednesday";
    		break;
    		
    		case 5:
    		return "Thursday";
    		break;
    		
    		case 6:
    		return "Friday";
    		break;
    		
    		case 7:
    		return "Saturday";
    		break;
    	}
    }

}


