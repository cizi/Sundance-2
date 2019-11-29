using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Lang;
using Toybox.Application;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.Math;
using Toybox.Activity;
using Toybox.SensorHistory;

class SundanceView extends WatchUi.WatchFace {
	
	hidden var imgBg;
	hidden var moonPhase;
	hidden var settings;

    function initialize() {    
        WatchFace.initialize();
        imgBg = new WatchUi.Bitmap({
            :rezId=>Rez.Drawables.Bg,
            :locX=>0,
            :locY=>0
        });      
        settings = System.getDeviceSettings();
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
        
        var today = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        var dateString = Lang.format(
		    "$1$ $2$ $3$",
		    [
		        today.day_of_week.substring(0,3),
		        today.day,
		        today.month
		    ]
		);
        var date = View.findDrawableById("DateLabel");
        // view.setColor(Application.getApp().getProperty("ForegroundColor"));        
        date.setText(dateString);
        date.draw(dc);
        
        today = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var moonPhaseNr = getMoonPhase(today.day, today.month, today.year);
        drawMoonPhase(dc, moonPhaseNr);
        
        var alt = View.findDrawableById("Altitude");
        // view.setColor(Application.getApp().getProperty("ForegroundColor"));   
          
        alt.setText(getAltitude());
        alt.draw(dc);       
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
    
    function getMoonPhase(year, month, day)
	{
	    var c = 0;
	    var e = 0;
	    var jd = 0;
	    var b = 0;
	
	    if (month < 3) {
	        year--;
	        month += 12;
	    }
	
	    ++month;
	
	    c = 365.25 * year;
	
	    e = 30.6 * month;
	
	    jd = c + e + day - 694039.09; //jd is total days elapsed
	
	    jd /= 29.5305882; //divide by the moon cycle
	
	    b = jd.toNumber(); //int(jd) -> b, take integer part of jd
	
	    jd -= b; //subtract integer part to leave fractional part of original jd
	
	    b = Math.round(jd * 8); //scale fraction from 0-8 and round
	
	    if (b >= 8 ) {
	        b = 0; //0 and 8 are the same so turn 8 into 0
	    }
	
	    // 0 => New Moon
	    // 1 => Waxing Crescent Moon
	    // 2 => Quarter Moon
	    // 3 => Waxing Gibbous Moon
	    // 4 => Full Moon
	    // 5 => Waning Gibbous Moon
	    // 6 => Last Quarter Moon
	    // 7 => Waning Crescent Moon
	    
	    return b.abs();
	}
	
	function drawMoonPhase(dc, phase) {
		var xPos = (dc.getWidth() / 2) - 10;
        var yPos = 43;
        if (phase == 0) {
			moonPhase = new WatchUi.Bitmap({
	            :rezId	=> Rez.Drawables.MP0,
	            :locX	=> xPos,
	            :locY	=> yPos
	        });        
        } else if (phase == 1) {
			moonPhase = new WatchUi.Bitmap({
	            :rezId	=> Rez.Drawables.MP1,
	            :locX	=> xPos,
	            :locY	=> yPos
	        }); 
		} else if (phase == 2) {
			moonPhase = new WatchUi.Bitmap({
	            :rezId	=> Rez.Drawables.MP2,
	            :locX	=> xPos,
	            :locY	=> yPos
	        }); 
		} else if (phase == 3) {
			moonPhase = new WatchUi.Bitmap({
	            :rezId	=> Rez.Drawables.MP3,
	            :locX	=> xPos,
	            :locY	=> yPos
	        }); 
		} else if (phase == 4) {
			moonPhase = new WatchUi.Bitmap({
	            :rezId	=> Rez.Drawables.MP4,
	            :locX	=> xPos,
	            :locY	=> yPos
	        });
		} else if (phase == 5) {
			moonPhase = new WatchUi.Bitmap({
	            :rezId	=> Rez.Drawables.MP5,
	            :locX	=> xPos,
	            :locY	=> yPos
	        }); 
		} else if (phase == 6) {
			moonPhase = new WatchUi.Bitmap({
	            :rezId	=> Rez.Drawables.MP6,
	            :locX	=> xPos,
	            :locY	=> yPos
	        }); 
		} else if (phase == 7) {
			moonPhase = new WatchUi.Bitmap({
	            :rezId	=> Rez.Drawables.MP7,
	            :locX	=> xPos,
	            :locY	=> yPos
	        }); 
		}
        moonPhase.draw(dc); 
	}
	
	function getAltitude() {
		// Note that Activity::Info.altitude is supported by CIQ 1.x, but elevation history only on select CIQ 2.x
		// devices.
		var unit;
		var sample;
		var value = "";
		var activityInfo = Activity.getActivityInfo();
		var altitude = activityInfo.altitude;
		if ((altitude == null) && (Toybox has :SensorHistory) && (Toybox.SensorHistory has :getElevationHistory)) {
			sample = SensorHistory.getElevationHistory({ :period => 1, :order => SensorHistory.ORDER_NEWEST_FIRST })
				.next();
			if ((sample != null) && (sample.data != null)) {
				altitude = sample.data;
			}
		}
		if (altitude != null) {
			// Metres (no conversion necessary).
			if (settings.elevationUnits == System.UNIT_METRIC) {
				unit = "m";
			// Feet.
			} else {
				altitude *= /* FT_PER_M */ 3.28084;
				unit = "ft";
			}
			value = altitude.format("%d");
			value += unit;
		}
		
		return value;
	}
}


