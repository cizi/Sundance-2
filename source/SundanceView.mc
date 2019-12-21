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
	
		// others
	hidden var settings;
	hidden var app;
	
	// Sunset / sunrise vars
	hidden var location = null;
	hidden var gLocationLat = null;
    hidden var gLocationLng = null ;
    
    function initialize() {    
        WatchFace.initialize();
        app = Application.getApp();
    }

    // Load your resources here
    function onLayout(dc) {
        setLayout(Rez.Layouts.WatchFace(dc));     
        
    	// if (Application.getApp().getProperty("BackgroundColor") == 0x000000) {
        /* imgBg = new WatchUi.Bitmap({
            :rezId=>Rez.Drawables.Bg,
            :locX=>0,
            :locY=>0
        });  */    
        
        //} else {
        	/* imgBg = new WatchUi.Bitmap({
	            :rezId=>Rez.Drawables.BgInvert,
	            :locX=>0,
	            :locY=>0
	        }); 
        } */
        
        
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
        settings = System.getDeviceSettings();
      
      	//imgBg.draw(dc);
      	drawDial(dc);
      	
     	drawAltitude(dc);
      	
      	drawBattery(dc);
      	drawBell(dc);
      	
      	if (Application.getApp().getProperty("ShowNotificationAndConnection")) {
	      	drawBtConnection(dc);
	      	drawNotification(dc);      	
      	}
      	
      	var xPos = (dc.getWidth() / 5) + 2; // 54
      	var yPos = (dc.getHeight() / 13) * 9; // 180
      	drawSteps(xPos, yPos, dc);
      	
        // Get the current time and format it correctly
        var timeFormat = "$1$:$2$";
        var today = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        var hours = today.hour;
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
        var timeString = Lang.format(timeFormat, [hours, today.min.format("%02d")]);

        // Update the view
        var time = View.findDrawableById("TimeLabel");
        time.setText(timeString);
        dc.setColor(Application.getApp().getProperty("ForegroundColor"), Application.getApp().getProperty("BackgroundColor"));
        time.draw(dc);
        
        if (Application.getApp().getProperty("DateFormat") != 5) {
	        var dateString = getFormatedDate();
	        var date = View.findDrawableById("DateLabel");        
	        date.setText(dateString);
	        dc.setColor(Application.getApp().getProperty("ForegroundColor"), Application.getApp().getProperty("BackgroundColor"));
	        date.draw(dc);      
        }
        
        // Moon phase is requireds 
        if (Application.getApp().getProperty("Opt1") == 0) {	
        	today = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        	drawMoonPhase(dc, getMoonPhase(today.year, today.month, today.day));
        }        
        
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
        	
			if ((sunTimes[0] != null) && (sunTimes[1] != null)) {      	
	        	if (Application.getApp().getProperty("Opt1") == 1) {	// sunset / sunrise is wanted by setting
	        		var nextSunEvent = 0;

					// Convert to same format as sunTimes, for easier comparison. Add a minute, so that e.g. if sun rises at
					// 07:38:17, then 07:38 is already consided daytime (seconds not shown to user).
					var now = today.hour + ((today.min + 1) / 60.0);
	        	
	        		// Before sunrise today: today's sunrise is next.
					if (now < sunTimes[0]) {
						nextSunEvent = sunTimes[0];
						drawSun(105, 60, dc, false);
					// After sunrise today, before sunset today: today's sunset is next.
					} else if (now < sunTimes[1]) {
						nextSunEvent = sunTimes[1];
						drawSun(105, 60, dc, true);
					// After sunset today: tomorrow's sunrise (if any) is next.
					} else {
						sunTimes = getSunTimes(gLocationLat, gLocationLng, null, /* tomorrow */ true);
						nextSunEvent = sunTimes[0];
						drawSun(105, 60, dc, false);
					}        		
	      	
			      	var sunTime = View.findDrawableById("SunTimes");		      	
			      	var hour = Math.floor(nextSunEvent).toLong() % 24;
					var min = Math.floor((nextSunEvent - Math.floor(nextSunEvent)) * 60);
					var value = getFormattedTime(hour, min); // App.getApp().getFormattedTime(hour, min);
					value = value[:hour] + ":" + value[:min] + value[:amPm]; 
			      	
			        sunTime.setText(value);
			        dc.setColor(Application.getApp().getProperty("ForegroundColor"), Application.getApp().getProperty("BackgroundColor"));
			        sunTime.draw(dc);
	        	}
			
				dc.setPenWidth(Application.getApp().getProperty("DaylightProgessWidth"));
				var halfWidth=dc.getWidth() / 2;
				var rLocal=halfWidth - 2;
				var lineStart = 270 - (sunTimes[0] * 15);
				var lineEnd = 270 - (sunTimes[1] * 15);
				dc.setColor(Application.getApp().getProperty("DaylightProgess"), Application.getApp().getProperty("BackgroundColor"));
				dc.drawArc(halfWidth, halfWidth, rLocal, Graphics.ARC_CLOCKWISE, lineStart, lineEnd);
			
				dc.setPenWidth(15);
				var currTimeCoef = (today.hour + (today.min.toFloat() / 60)) * 15;
				var currTimeStart = 272 - currTimeCoef;	// 270 was corrected better placing of current time holder
				var currTimeEnd = 268 - currTimeCoef;	// 270 was corrected better placing of current time holder 
				dc.setColor(Application.getApp().getProperty("CurrentTimePointer"), Application.getApp().getProperty("BackgroundColor"));
				dc.drawArc(halfWidth, halfWidth, rLocal - 3, Graphics.ARC_CLOCKWISE, currTimeStart, currTimeEnd);			
        	}
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
    
    // Will draw bell if is alarm set
    function drawBell(dc) {
    	if (settings.alarmCount > 0) {
    		var xPos = dc.getWidth() / 2;
    		var yPos = ((dc.getHeight() / 6).toNumber() * 4) + 2;
    		dc.setColor(Application.getApp().getProperty("ForegroundColor"), Application.getApp().getProperty("BackgroundColor"));
    		dc.fillCircle(xPos, yPos, 7);
    	
    		// stands
    		dc.setPenWidth(3);	
    		dc.drawLine(xPos - 5, yPos, xPos - 7, yPos + 7);
    		dc.drawLine(xPos + 5, yPos, xPos + 7, yPos + 7);
    		
    		dc.setPenWidth(2);
    		dc.drawLine(xPos - 5, yPos - 7, xPos - 9, yPos - 3);
    		dc.drawLine(xPos + 6, yPos - 7, xPos + 10, yPos - 3);
    		
    		dc.setColor(Application.getApp().getProperty("BackgroundColor"), Application.getApp().getProperty("ForegroundColor"));
    		dc.fillCircle(xPos, yPos, 5);
    		
    		// hands
    		dc.setColor(Application.getApp().getProperty("ForegroundColor"), Application.getApp().getProperty("BackgroundColor"));
    		dc.drawLine(xPos, yPos, xPos, yPos - 5);
    		dc.drawLine(xPos, yPos, xPos - 2, yPos + 4);
      	}
    } 
    
    // Draw the master dial 
    function drawDial(dc) {
    	// this part is draw the net over all display
    	dc.setColor(Application.getApp().getProperty("ForegroundColor"), Application.getApp().getProperty("BackgroundColor"));
      	dc.setPenWidth(2);
      	var halfScreen = dc.getWidth() / 2;
      	var pointX = 0;
      	var pointY = 0;
      	var angleDeg = 0;
      	for(var angle = 0; angle < 360; angle+=15) {
	      	if ((angle != 0) && (angle != 90) && (angle != 180) && (angle != 270)) {
	      		angleDeg = (angle * Math.PI) / 180;
	      		pointX = ((halfScreen * Math.cos(angleDeg)) + halfScreen);
	      		pointY = ((halfScreen * Math.sin(angleDeg)) + halfScreen);	      
	      		dc.drawLine(halfScreen, halfScreen, pointX, pointY); 
      		}
      	}
      	// hide the middle of the net to shows just pieces on the edge of the screen
      	dc.setColor(Application.getApp().getProperty("BackgroundColor"), Application.getApp().getProperty("ForegroundColor"));     	
      	dc.drawCircle(halfScreen, halfScreen, halfScreen - 1);
      	dc.fillCircle(halfScreen, halfScreen, halfScreen - 8);
      	
      	// draw the master pieces in 24, 12, 6, 18 hours point
      	var masterPointLen = 12;
      	var masterPointWid = 4; 
      	dc.setColor(Application.getApp().getProperty("ForegroundColor"), Graphics.COLOR_TRANSPARENT);
      	dc.setPenWidth(masterPointWid);
      	dc.drawLine(halfScreen, 0, halfScreen, masterPointLen);
      	dc.drawLine(halfScreen, dc.getWidth(), halfScreen, dc.getWidth() - masterPointLen); 
      	dc.drawLine(0, halfScreen - (masterPointWid / 2), masterPointLen, halfScreen - (masterPointWid / 2)); 
      	dc.drawLine(dc.getWidth(), halfScreen - (masterPointWid / 2), dc.getWidth() - masterPointLen, halfScreen - (masterPointWid / 2)); 
    
    	// numbers
    	dc.drawText(halfScreen, 8, Graphics.FONT_TINY, "12", Graphics.TEXT_JUSTIFY_CENTER);	// 12
    	dc.drawText(dc.getWidth() - 16, halfScreen - 18, Graphics.FONT_TINY, "18", Graphics.TEXT_JUSTIFY_RIGHT);	// 18
    	dc.drawText(halfScreen, dc.getHeight() - 40, Graphics.FONT_TINY, "24", Graphics.TEXT_JUSTIFY_CENTER);	// 24
    	dc.drawText(16, halfScreen - 18, Graphics.FONT_TINY, "06", Graphics.TEXT_JUSTIFY_LEFT);	// 06
    	
    	// numbers
    	drawNrDial(dc);
    }
    
    // Draw numbers in the dial
    function drawNrDial(dc) {
    	var halfWidth = dc.getWidth() / 2;
    	var haldHeight = dc.getHeight() / 2;
    	dc.setColor(Application.getApp().getProperty("ForegroundColor"), Graphics.COLOR_TRANSPARENT);
    	
    	// 10
    	var fnt10 = WatchUi.loadResource(Rez.Fonts.fntSd10);
    	dc.drawText(70, 23, fnt10, "1", Graphics.TEXT_JUSTIFY_CENTER);
    	dc.drawText(78, 19, fnt10, "0", Graphics.TEXT_JUSTIFY_CENTER);
    	
    	// 11
    	var fnt11 = WatchUi.loadResource(Rez.Fonts.fntSd11);
    	dc.drawText(96, 12, fnt11, "1", Graphics.TEXT_JUSTIFY_CENTER);
    	dc.drawText(104, 10, fnt11, "1", Graphics.TEXT_JUSTIFY_CENTER);
    	
    	// 09
    	var fnt09 = WatchUi.loadResource(Rez.Fonts.fntSd09);
    	dc.drawText(46, 43, fnt09, "0", Graphics.TEXT_JUSTIFY_CENTER);
    	dc.drawText(53, 37, fnt09, "9", Graphics.TEXT_JUSTIFY_CENTER);
    	
    	// 08
    	var fnt08 = WatchUi.loadResource(Rez.Fonts.fntSd08);
    	dc.drawText(29, 67, fnt08, "0", Graphics.TEXT_JUSTIFY_CENTER);
    	dc.drawText(34, 59, fnt08, "8", Graphics.TEXT_JUSTIFY_CENTER);
    	
    	// 07
    	var fnt07 = WatchUi.loadResource(Rez.Fonts.fntSd07);
    	dc.drawText(20, 95, fnt07, "0", Graphics.TEXT_JUSTIFY_CENTER);
    	dc.drawText(23, 86, fnt07, "7", Graphics.TEXT_JUSTIFY_CENTER);
    }
    
    // Draw sunset or sunrice image 
    function drawSun(posX, posY, dc, up) {
    	var radius = 8;
    	var penWidth = 2;
    	dc.setPenWidth(penWidth);
    	dc.setColor(Application.getApp().getProperty("DaylightProgess"), Application.getApp().getProperty("BackgroundColor"));
    	dc.fillCircle(posX, posY, radius);
    	dc.drawLine(posX - 12, posY + 1 , posX + 14, posY + 1);
    	
    	// arrow up
    	dc.drawLine(posX, posY - (radius * 2), posX, posY - (radius * 2) + 8);
    	if (up) {
    		dc.drawLine(posX, posY - (radius * 2) + 7, posX + 6, posY - (radius * 2) + 3);
    		dc.drawLine(posX, posY - (radius * 2) + 7, posX - 6, posY - (radius * 2) + 3);
    	} else {	// arrow down
    		dc.drawLine(posX, posY - (radius * 2), posX + 6, posY - (radius * 2) + 3);
    		dc.drawLine(posX, posY - (radius * 2), posX - 6, posY - (radius * 2) + 3);
    	}
    	
    	// beams
    	dc.drawLine(posX - 7, posY - radius - 1, posX - radius - 2, posY - radius - 3);
    	dc.drawLine(posX + 7, posY - radius - 1, posX + radius + 2, posY - radius - 3);
		dc.drawLine(posX - 10, posY - radius + 4, posX - radius - 5, posY - radius + 2);
		dc.drawLine(posX + 10, posY - radius + 4, posX + radius + 5, posY - radius + 2);
    	
    	// hide second half of sun
    	dc.setColor(Application.getApp().getProperty("BackgroundColor"), Application.getApp().getProperty("ForegroundColor"));
    	dc.fillRectangle(posX - radius - 1, posY + penWidth, (radius * 2) + (penWidth * 2), radius);
    }
    
    // Draw steps image
    function drawSteps(posX, posY, dc) {
    	if (dc.getWidth() == 280) {	// FENIX 6X correction
      		posX -= 10;
      	}
    	dc.setColor(Application.getApp().getProperty("DaylightProgess"), Application.getApp().getProperty("BackgroundColor"));
    	dc.fillCircle(posX, posY, 2);	// left bottom
    	dc.fillCircle(posX, posY-8, 3); // left middle
    	dc.fillCircle(posX, posY-10, 3); // left top
    	
    	dc.fillCircle(posX+12, posY-4, 2);	// right bottom
    	dc.fillCircle(posX+12, posY-12, 3); // right middle
    	dc.fillCircle(posX+12, posY-14, 3); // right top
    	
    	var info = ActivityMonitor.getInfo();
        dc.setColor(Application.getApp().getProperty("ForegroundColor"), Application.getApp().getProperty("BackgroundColor"));
    	dc.drawText(posX + 22, posY - 16, Graphics.FONT_XTINY, info.steps.toString(), Graphics.TEXT_JUSTIFY_LEFT);
    }
    
    // Draw BT connection status
    function drawBtConnection(dc) {
    	if ((settings has : phoneConnected) && (settings.phoneConnected)) {
    		dc.setColor(Graphics.COLOR_BLUE, Application.getApp().getProperty("BackgroundColor"));
       		dc.fillCircle((dc.getWidth() / 2) - 9, dc.getHeight() - 43, 5);	
   		}
    }
    
    // Draw notification alarm
    function drawNotification(dc) {
    	if ((settings has : notificationCount) && (settings.notificationCount)) {
    		dc.setColor(Graphics.COLOR_RED, Application.getApp().getProperty("BackgroundColor"));
       		dc.fillCircle((dc.getWidth() / 2) + 6, dc.getHeight() - 43, 5);	
   		} 
    }
    
    // Returns formated date by settings
    function getFormatedDate() {
    	var ret = "";
    	if (Application.getApp().getProperty("DateFormat") <= 3) {
    		var today = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
    		if (Application.getApp().getProperty("DateFormat") == 1) {
    			ret = Lang.format("$1$ $2$ $3$", [today.day_of_week, today.day, today.month]);
    		} else if (Application.getApp().getProperty("DateFormat") == 2) {
    			ret = Lang.format("$1$ $2$ $3$", [today.day_of_week, today.month, today.day]);
    		} else {
    			ret = Lang.format("$1$ $2$", [today.day_of_week, today.day]);
    		}  		
    	} else {
    		var today = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
    		ret = Lang.format("$1$ / $2$", [today.month, today.day]);
    	}
    	
    	return ret;
    }
    
    // Return one of 8 moon phase by date 
    // 0 => New Moon
    // 1 => Waxing Crescent Moon
    // 2 => Quarter Moon
    // 3 => Waning Gibbous Moon
    // 4 => Full Moon
    // 5 => Waxing Gibbous Moon
    // 6 => Last Quarter Moon
    // 7 => Waning Crescent Moon
    function getMoonPhase(year, month, day) {
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
	    b = Math.round(jd * 8).abs(); //scale fraction from 0-8 and round
	    if (b >= 8 ) {
	        b = 0; //0 and 8 are the same so turn 8 into 0
	    }
	    
	    return b;
	}
	
	// Draw a moon by phase
	function drawMoonPhase(dc, phase) {
		var xPos = (dc.getWidth() / 2);
        var yPos = (dc.getHeight() / 5).toNumber(); //43;
        var radius = 9;
        dc.setColor(Application.getApp().getProperty("ForegroundColor"), Application.getApp().getProperty("BackgroundColor"));
        if (phase == 0) {
	        dc.setPenWidth(2);
        	dc.drawCircle(xPos, yPos, radius);
        } else {
        	dc.fillCircle(xPos, yPos, radius);
        	if (phase == 1) {
        		dc.setColor(Application.getApp().getProperty("BackgroundColor"), Application.getApp().getProperty("ForegroundColor"));
        		dc.fillCircle(xPos - 5, yPos, radius);			
			} else if (phase == 2) {
				dc.setColor(Application.getApp().getProperty("BackgroundColor"), Application.getApp().getProperty("ForegroundColor"));
        		dc.fillRectangle(xPos - radius, yPos - radius, radius, (radius * 2) + 2);		
			} else if (phase == 3) {
				dc.setPenWidth(8);
				dc.setColor(Application.getApp().getProperty("BackgroundColor"), Application.getApp().getProperty("ForegroundColor"));
				dc.drawArc(xPos + 5, yPos, radius + 5, Graphics.ARC_CLOCKWISE, 270, 90);
			} else if (phase == 5) {
				dc.setPenWidth(8);
				dc.setColor(Application.getApp().getProperty("BackgroundColor"), Application.getApp().getProperty("ForegroundColor"));
				dc.drawArc(xPos - 5, yPos, radius + 5, Graphics.ARC_CLOCKWISE, 90, 270);				
			} else if (phase == 6) {
				dc.setColor(Application.getApp().getProperty("BackgroundColor"), Application.getApp().getProperty("ForegroundColor"));
        		dc.fillRectangle(xPos + (radius / 2) - 3, yPos - radius, radius, (radius * 2) + 2);
			} else if (phase == 7) {
				dc.setColor(Application.getApp().getProperty("BackgroundColor"), Application.getApp().getProperty("ForegroundColor"));
        		dc.fillCircle(xPos + 5, yPos, radius);	
			}      	
        }
	}
	
	// Draw battery witch % state
	function drawBattery(dc) {
		dc.setPenWidth(1);
		if (System.getSystemStats().battery <= 10) {
	      	dc.setColor(Graphics.COLOR_RED, Application.getApp().getProperty("BackgroundColor"));
		} else {
	      	dc.setColor(Application.getApp().getProperty("ForegroundColor"), Application.getApp().getProperty("BackgroundColor"));
		}
      	var batStartX = (dc.getWidth() / 2) + 21; //151;
      	var batteryStartY = ((dc.getHeight() / 6).toNumber() * 4) - 5;// 168;
      	if (dc.getWidth() == 280) {	// FENIX 6X correction
      		batStartX += 10;
      	}
      	var batteryWidth = 23;
      	dc.drawRectangle(batStartX, batteryStartY, batteryWidth, 13);	// battery
 		dc.drawRectangle(batStartX + batteryWidth, batteryStartY + 4, 2, 5);	// battery top
 		var batteryColor = Graphics.COLOR_GREEN;
 		if (System.getSystemStats().battery <= 10) {
 			batteryColor = Graphics.COLOR_RED;
 		} else if (System.getSystemStats().battery <= 35) {
 			batteryColor = Graphics.COLOR_ORANGE;
 		}
 		
 		dc.setColor(batteryColor, Application.getApp().getProperty("BackgroundColor"));
 		var batteryState = ((System.getSystemStats().battery / 10) * 2).toNumber();
 		dc.fillRectangle(batStartX + 1, batteryStartY + 1, batteryState + 1, 11);
 		
 		// x="180" y="164"
 		var batText = System.getSystemStats().battery.toNumber().toString() + "%";
        dc.setColor(Application.getApp().getProperty("ForegroundColor"), Application.getApp().getProperty("BackgroundColor"));
 		dc.drawText(batStartX + 29, batteryStartY - 4, Graphics.FONT_XTINY, batText, Graphics.TEXT_JUSTIFY_LEFT);		
	}
	
	function  drawAltitude(dc) {        
        var xPos = (dc.getWidth() / 13) * 7; // "140" 
        var yPos = ((dc.getHeight() / 4).toNumber() * 3) - 6;  // "189"
        dc.setColor(Application.getApp().getProperty("ForegroundColor"), Application.getApp().getProperty("BackgroundColor"));
        dc.drawText(xPos, yPos, Graphics.FONT_XTINY, getAltitude(), Graphics.TEXT_JUSTIFY_CENTER);
        
        // coordinates correction
        xPos = xPos - 46;
        yPos = yPos + 2;
        dc.setPenWidth(2);
    	dc.setColor(Application.getApp().getProperty("DaylightProgess"), Application.getApp().getProperty("BackgroundColor"));
    	dc.drawLine(xPos + 1, yPos + 14, xPos + 5, yPos + 7);
    	dc.drawLine(xPos + 5, yPos + 7, xPos + 7, yPos + 10);
    	dc.drawLine(xPos + 7, yPos + 10, xPos + 11, yPos + 2);
    	dc.drawLine(xPos + 11, yPos + 2, xPos + 20, yPos + 15);
	}
	
	// Returns altitude info with units
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
	
	// Return a formatted time dictionary that respects is24Hour settings.
	// - hour: 0-23.
	// - min:  0-59.
	function getFormattedTime(hour, min) {
		var amPm = "";

		if (!System.getDeviceSettings().is24Hour) {
			// #6 Ensure noon is shown as PM.
			var isPm = (hour >= 12);
			if (isPm) {				
				// But ensure noon is shown as 12, not 00.
				if (hour > 12) {
					hour = hour - 12;
				}
				amPm = "p";
			} else {				
				// #27 Ensure midnight is shown as 12, not 00.
				if (hour == 0) {
					hour = 12;
				}
				amPm = "a";
			}
		}

		return {
			:hour => hour,
			:min => min.format("%02d"),
			:amPm => amPm
		};
	}
}