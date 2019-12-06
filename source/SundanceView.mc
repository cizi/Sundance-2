using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Lang;
using Toybox.Application;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.Math;
using Toybox.Activity;
using Toybox.ActivityMonitor;
using Toybox.SensorHistory;
using Toybox.Application;

class SundanceView extends WatchUi.WatchFace {
	
	// pictures
	hidden var imgBg;
	hidden var moonPhase;
	hidden var mountain;
	hidden var stepsPic;
	
	// others
	hidden var settings;
	hidden var app;
	hidden var value = null;
	
	// Sunset / sunrise vars
	hidden var location = null;
	hidden var gLocationLat = null;
    hidden var gLocationLng = null ;
    
    function initialize() {    
        WatchFace.initialize();
        imgBg = new WatchUi.Bitmap({
            :rezId=>Rez.Drawables.Bg,
            :locX=>0,
            :locY=>0
        });      
        
        mountain = new WatchUi.Bitmap({
            :rezId=>Rez.Drawables.Mnt,
            :locX=>94,
            :locY=>191
        });        
        settings = System.getDeviceSettings();
        app = Application.getApp();
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
      	mountain.draw(dc);
 
        // Get the current time and format it correctly
        var timeFormat = "$1$:$2$";
        var clockTime = System.getClockTime();
        var hours = clockTime.hour;
        if (!System.getDeviceSettings().is24Hour) {
        	var ampm = View.findDrawableById("TimeAmPm");
        	ampm.setText("AM");
            if (hours > 12) {
                hours = hours - 12;
                ampm.setText("PM");
            }
            ampm.draw(dc);
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
        alt.setText(getAltitude());
        alt.draw(dc);   
        
        var info = ActivityMonitor.getInfo();
        var stepPosX = 94;
        if (info.steps > 10) { stepPosX = 89; }
        if (info.steps > 100) { stepPosX = 84; }
        if (info.steps > 1000) { stepPosX = 79; }
        if (info.steps > 1000) { stepPosX = 74; }
  
        stepsPic = new WatchUi.Bitmap({
            :rezId=>Rez.Drawables.Steps,
            :locX=>stepPosX,
            :locY=>166
        });
        stepsPic.draw(dc);
        var stepsId = View.findDrawableById("TodaySteps");
        stepsId.setText(info.steps.toString() + "/" + info.stepGoal.toString());
        stepsId.draw(dc);
            
        
        // Get today's sunrise/sunset times in current time zone.
        var location = Activity.getActivityInfo().currentLocation;
        // System.println(location);
        if (location) {
	        location = location.toDegrees(); // Array of Doubles.
        	gLocationLat = location[0].toFloat();
			gLocationLng = location[1].toFloat();
			
			app.setProperty("LastLocationLat", gLocationLat);
			app.setProperty("LastLocationLng", gLocationLng);						
		} else {
			var lat = app.getProperty("LastLocationLat");
			if (lat != null) {
				gLocationLat = lat;
			}

			var lng = app.getProperty("LastLocationLng");
			if (lng != null) {
				gLocationLng = lng;
			}			
        }
        
        if (gLocationLat != null) {
        	var sunTimes = getSunTimes(gLocationLat, gLocationLng, null, /* tomorrow */ false);
			// System.println(sunTimes[0]);
			// System.println(sunTimes[1]);
			
			dc.setPenWidth(6);
			var halfWidth=dc.getWidth() / 2;
			var rLocal=halfWidth - 2;
			var lineStart = 270 - (sunTimes[0] * 15);
			var lineEnd = 270 - (sunTimes[1] * 15);
			dc.setColor(0xFFFF00, Graphics.COLOR_BLACK);
			dc.drawArc(halfWidth, halfWidth, rLocal, Graphics.ARC_CLOCKWISE, lineStart, lineEnd);
			
			dc.setPenWidth(10);
			var currTimeCoef = (today.hour + (today.min.toFloat() / 60)) * 15;
			var currTimeStart = 272 - currTimeCoef;	// 270 was corrected better placing of current time holder
			var currTimeEnd = 268 - currTimeCoef;	// 270 was corrected better placing of current time holder 
			dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
			dc.drawArc(halfWidth, halfWidth, rLocal - 2, Graphics.ARC_CLOCKWISE, currTimeStart, currTimeEnd);
        } else {
        	value = "gps?";
        }
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
	    // 3 => Waning Gibbous Moon
	    // 4 => Full Moon
	    // 5 => Waxing Gibbous Moon
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
	
	/**
	* With thanks to ruiokada. Adapted, then translated to Monkey C, from:
	* https://gist.github.com/ruiokada/b28076d4911820ddcbbc
	*
	* Calculates sunrise and sunset in local time given latitude, longitude, and tz.
	*
	* Equations taken from:
	* https://en.wikipedia.org/wiki/Julian_day#Converting_Julian_or_Gregorian_calendar_date_to_Julian_Day_Number
	* https://en.wikipedia.org/wiki/Sunrise_equation#Complete_calculation_on_Earth
	*
	* @method getSunTimes
	* @param {Float} lat Latitude of location (South is negative)
	* @param {Float} lng Longitude of location (West is negative)
	* @param {Integer || null} tz Timezone hour offset. e.g. Pacific/Los Angeles is -8 (Specify null for system timezone)
	* @param {Boolean} tomorrow Calculate tomorrow's sunrise and sunset, instead of today's.
	* @return {Array} Returns array of length 2 with sunrise and sunset as floats.
	*                 Returns array with [null, -1] if the sun never rises, and [-1, null] if the sun never sets.
	*/
	private function getSunTimes(lat, lng, tz, tomorrow) {

		// Use double precision where possible, as floating point errors can affect result by minutes.
		lat = lat.toDouble();
		lng = lng.toDouble();

		var now = Time.now();
		if (tomorrow) {
			now = now.add(new Time.Duration(24 * 60 * 60));
		}
		var d = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
		var rad = Math.PI / 180.0d;
		var deg = 180.0d / Math.PI;
		
		// Calculate Julian date from Gregorian.
		var a = Math.floor((14 - d.month) / 12);
		var y = d.year + 4800 - a;
		var m = d.month + (12 * a) - 3;
		var jDate = d.day
			+ Math.floor(((153 * m) + 2) / 5)
			+ (365 * y)
			+ Math.floor(y / 4)
			- Math.floor(y / 100)
			+ Math.floor(y / 400)
			- 32045;

		// Number of days since Jan 1st, 2000 12:00.
		var n = jDate - 2451545.0d + 0.0008d;
		//Sys.println("n " + n);

		// Mean solar noon.
		var jStar = n - (lng / 360.0d);
		//Sys.println("jStar " + jStar);

		// Solar mean anomaly.
		var M = 357.5291d + (0.98560028d * jStar);
		var MFloor = Math.floor(M);
		var MFrac = M - MFloor;
		M = MFloor.toLong() % 360;
		M += MFrac;
		//Sys.println("M " + M);

		// Equation of the centre.
		var C = 1.9148d * Math.sin(M * rad)
			+ 0.02d * Math.sin(2 * M * rad)
			+ 0.0003d * Math.sin(3 * M * rad);
		//Sys.println("C " + C);

		// Ecliptic longitude.
		var lambda = (M + C + 180 + 102.9372d);
		var lambdaFloor = Math.floor(lambda);
		var lambdaFrac = lambda - lambdaFloor;
		lambda = lambdaFloor.toLong() % 360;
		lambda += lambdaFrac;
		//Sys.println("lambda " + lambda);

		// Solar transit.
		var jTransit = 2451545.5d + jStar
			+ 0.0053d * Math.sin(M * rad)
			- 0.0069d * Math.sin(2 * lambda * rad);
		//Sys.println("jTransit " + jTransit);

		// Declination of the sun.
		var delta = Math.asin(Math.sin(lambda * rad) * Math.sin(23.44d * rad));
		//Sys.println("delta " + delta);

		// Hour angle.
		var cosOmega = (Math.sin(-0.83d * rad) - Math.sin(lat * rad) * Math.sin(delta))
			/ (Math.cos(lat * rad) * Math.cos(delta));
		//Sys.println("cosOmega " + cosOmega);

		// Sun never rises.
		if (cosOmega > 1) {
			return [null, -1];
		}
		
		// Sun never sets.
		if (cosOmega < -1) {
			return [-1, null];
		}
		
		// Calculate times from omega.
		var omega = Math.acos(cosOmega) * deg;
		var jSet = jTransit + (omega / 360.0);
		var jRise = jTransit - (omega / 360.0);
		var deltaJSet = jSet - jDate;
		var deltaJRise = jRise - jDate;

		var tzOffset = (tz == null) ? (System.getClockTime().timeZoneOffset / 3600) : tz;
		return [
			/* localRise */ (deltaJRise * 24) + tzOffset,
			/* localSet */ (deltaJSet * 24) + tzOffset
		];
	}
}