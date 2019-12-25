using Toybox.WatchUi;
using Toybox.Graphics as Gfx;
using Toybox.System;
using Toybox.Lang;
using Toybox.Application as App;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.Math;
using Toybox.Activity;
using Toybox.ActivityMonitor;
using Toybox.SensorHistory;
using Toybox.Application;

class SundanceView extends WatchUi.WatchFace {

	// const for settings 
	const MOON_PHASE = 0;
	const SUNSET_SUNSRISE = 1;
	const STEPS = 4;
	const HR = 5;
	const BATTERY = 6;
	const ALTITUDE = 7;
	const DISABLED = 100;
	
	// others
	hidden var settings;
	hidden var app;
	hidden var is240dev;
	hidden var is280dev;
	
	// Sunset / sunrise vars
	hidden var location = null;
	hidden var gLocationLat = null;
    hidden var gLocationLng = null;
    
    hidden var fnt01 = null;
    hidden var fnt02 = null;
    hidden var fnt03 = null;
    hidden var fnt04 = null;
    hidden var fnt05 = null;
    hidden var fnt07 = null;
    hidden var fnt08 = null;
    hidden var fnt09 = null;
    hidden var fnt11 = null;
    hidden var fnt10 = null;
    hidden var fnt13 = null;
    hidden var fnt14 = null;
    hidden var fnt15 = null;
    hidden var fnt16 = null;
    hidden var fnt17 = null;
    hidden var fnt19 = null;
    hidden var fnt20 = null;
    hidden var fnt21 = null;
    hidden var fnt22 = null;
    hidden var fnt23 = null;
    hidden var fntIcons = null;
    
    hidden var halfWidth = null;
    hidden var field1 = null;
    hidden var field2 = null;
    hidden var field3 = null;
    hidden var field4 = null;
    
    function initialize() {    
        WatchFace.initialize();
        app = App.getApp();
        
        fnt01 = WatchUi.loadResource(Rez.Fonts.fntSd01);
        fnt02 = WatchUi.loadResource(Rez.Fonts.fntSd02);
        fnt03 = WatchUi.loadResource(Rez.Fonts.fntSd03);
        fnt04 = WatchUi.loadResource(Rez.Fonts.fntSd04);
       	fnt05 = WatchUi.loadResource(Rez.Fonts.fntSd05);       
		fnt07 = WatchUi.loadResource(Rez.Fonts.fntSd07);
		fnt08 = WatchUi.loadResource(Rez.Fonts.fntSd08);
		fnt09 = WatchUi.loadResource(Rez.Fonts.fntSd09);
        fnt10 = WatchUi.loadResource(Rez.Fonts.fntSd10);
        fnt11 = WatchUi.loadResource(Rez.Fonts.fntSd11);
        fnt13 = WatchUi.loadResource(Rez.Fonts.fntSd13);
        fnt14 = WatchUi.loadResource(Rez.Fonts.fntSd14);
        fnt15 = WatchUi.loadResource(Rez.Fonts.fntSd15);
        fnt16 = WatchUi.loadResource(Rez.Fonts.fntSd16);
        fnt17 = WatchUi.loadResource(Rez.Fonts.fntSd17);
        fnt19 = WatchUi.loadResource(Rez.Fonts.fntSd19);
        fnt20 = WatchUi.loadResource(Rez.Fonts.fntSd20);
        fnt21 = WatchUi.loadResource(Rez.Fonts.fntSd21);
        fnt22 = WatchUi.loadResource(Rez.Fonts.fntSd22);
        fnt23 = WatchUi.loadResource(Rez.Fonts.fntSd23);
        fntIcons = WatchUi.loadResource(Rez.Fonts.fntIcons);
    }

    // Load your resources here
    function onLayout(dc) {
        setLayout(Rez.Layouts.WatchFace(dc));   
        is240dev = (dc.getWidth() == 240); 
        is280dev = (dc.getWidth() == 280); 

        halfWidth = dc.getWidth() / 2;
        field1 = [halfWidth - 23, 60];
        field2 = [(dc.getWidth() / 5) + 2, (dc.getHeight() / 13) * 9];		// on F6 [54, 180]
        field3 = [halfWidth + 56, ((dc.getHeight() / 6).toNumber() * 4) - 9];		
        field4 = [(dc.getWidth() / 13) * 7, ((dc.getHeight() / 4).toNumber() * 3) - 6];		// on F6 [140, 189]          
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
      
      	drawDial(dc);												// main dial  	
    	if (App.getApp().getProperty("ShowFullDial")) {		// subdial small numbers
	    	drawNrDial(dc);
    	}
    	var today = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
    	
        drawSunsetSunriseLine(field1[0], field1[1], dc, today);		// SUNSET / SUNRICE line
      	    	
      	if (App.getApp().getProperty("ShowAltitude")) {
	     	drawAltitude(field4[0], field4[1], dc);
      	}
      	
      	if (App.getApp().getProperty("ShowBattery")) {
	      	drawBattery(field3[0], field3[1], dc, 3);
      	}
     	
      	if (App.getApp().getProperty("AlarmIndicator")) {
	      	drawBell(dc);
      	}
      	
      	if (App.getApp().getProperty("ShowNotificationAndConnection")) {
	      	drawBtConnection(dc);
	      	drawNotification(dc);      	
      	}
      	
      	if (App.getApp().getProperty("ShowSteps")) {
	      	drawSteps(field2[0], field2[1], dc);
      	}
      	
        // Get the current time and format it correctly
        dc.setColor(App.getApp().getProperty("ForegroundColor"), Gfx.COLOR_TRANSPARENT);
        var timeFormat = "$1$:$2$";
        var hours = today.hour;
        if (!System.getDeviceSettings().is24Hour) {
        	var ampm = "AM";
            if (hours > 12) {
                hours = hours - 12;
                ampm = "PM";
            }      
            dc.drawText(54, ((dc.getHeight() / 2) - Gfx.getFontHeight(Gfx.FONT_SYSTEM_NUMBER_HOT) / 2) + 2, Gfx.FONT_XTINY, ampm, Gfx.TEXT_JUSTIFY_CENTER);
        } else {
            if (App.getApp().getProperty("UseMilitaryFormat")) {
                timeFormat = "$1$$2$";
                hours = hours.format("%02d");
            }
        }
        var timeString = Lang.format(timeFormat, [hours, today.min.format("%02d")]);       
		dc.drawText(dc.getWidth() / 2, (dc.getHeight() / 2) - (Gfx.getFontHeight(Gfx.FONT_SYSTEM_NUMBER_HOT) / 2), Gfx.FONT_SYSTEM_NUMBER_HOT, timeString, Gfx.TEXT_JUSTIFY_CENTER);
        
        if (App.getApp().getProperty("DateFormat") != 5) {
	        var dateString = getFormatedDate();
	        dc.drawText((dc.getWidth() / 2), 65, Gfx.FONT_TINY, dateString, Gfx.TEXT_JUSTIFY_CENTER);    
        }
        
        // FIELD 1
        switch (App.getApp().getProperty("Opt1")) {
        	case MOON_PHASE:
        		today = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        		drawMoonPhase(dc, getMoonPhase(today.year, today.month, today.day));
        	break;
        	
        	case SUNSET_SUNSRISE:
        		drawSunsetSunriseTime(field1[0], field1[1], dc, today);
        	break;
        }      
        
        
        // FIELD 4
        switch (App.getApp().getProperty("Opt4")) {
        	case HR:
        	drawHr(field4[0], field4[1], dc);
        	break;
        	
        	case BATTERY:
	        drawBattery(field4[0], field4[1], dc, 4);
        	break;
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
    
    // Draw current HR
    function drawHr(xPos, yPos, dc) {
     	dc.setColor(App.getApp().getProperty("DaylightProgess"), Gfx.COLOR_TRANSPARENT);
    	dc.drawText(xPos - 49, yPos - 2, fntIcons, "3", Gfx.TEXT_JUSTIFY_LEFT);
    	
    	dc.setColor(App.getApp().getProperty("ForegroundColor"), Gfx.COLOR_TRANSPARENT);
        dc.drawText(xPos - 19, yPos, Gfx.FONT_XTINY, "110", Gfx.TEXT_JUSTIFY_LEFT);
    }
    
    function drawSunsetSunriseLine(xPos, yPos, dc, today) {
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
				dc.setPenWidth(App.getApp().getProperty("DaylightProgessWidth"));
				var rLocal = halfWidth - 2;
				var lineStart = 270 - (sunTimes[0] * 15);
				var lineEnd = 270 - (sunTimes[1] * 15);
				dc.setColor(App.getApp().getProperty("DaylightProgess"), App.getApp().getProperty("BackgroundColor"));
				dc.drawArc(halfWidth, halfWidth, rLocal, Gfx.ARC_CLOCKWISE, lineStart, lineEnd);
			
				dc.setPenWidth(15);
				var currTimeCoef = (today.hour + (today.min.toFloat() / 60)) * 15;
				var currTimeStart = 272 - currTimeCoef;	// 270 was corrected better placing of current time holder
				var currTimeEnd = 268 - currTimeCoef;	// 270 was corrected better placing of current time holder 
				dc.setColor(App.getApp().getProperty("CurrentTimePointer"), App.getApp().getProperty("BackgroundColor"));
				dc.drawArc(halfWidth, halfWidth, rLocal - 3, Gfx.ARC_CLOCKWISE, currTimeStart, currTimeEnd);			
        	}
    	}  
    }
    
   	// draw next sun event 
    function drawSunsetSunriseTime(xPos, yPos, dc, today) {   
	    if (gLocationLat != null) { 
	    	var sunTimes = getSunTimes(gLocationLat, gLocationLng, null, /* tomorrow */ false);	
	    	if ((sunTimes[0] != null) && (sunTimes[1] != null)) {
				var nextSunEvent = 0;
				// Convert to same format as sunTimes, for easier comparison. Add a minute, so that e.g. if sun rises at
				// 07:38:17, then 07:38 is already consided daytime (seconds not shown to user).
				var now = today.hour + ((today.min + 1) / 60.0);
			
				// Before sunrise today: today's sunrise is next.
				if (now < sunTimes[0]) {
					nextSunEvent = sunTimes[0];
					drawSun(xPos, yPos, dc, false);
				// After sunrise today, before sunset today: today's sunset is next.
				} else if (now < sunTimes[1]) {
					nextSunEvent = sunTimes[1];
					drawSun(xPos, yPos, dc, true);
				// After sunset today: tomorrow's sunrise (if any) is next.
				} else {
					sunTimes = getSunTimes(gLocationLat, gLocationLng, null, /* tomorrow */ true);
					nextSunEvent = sunTimes[0];
					drawSun(xPos, yPos, dc, false);
				}        		
		  		      	
		      	var hour = Math.floor(nextSunEvent).toLong() % 24;
				var min = Math.floor((nextSunEvent - Math.floor(nextSunEvent)) * 60);
				var value = getFormattedTime(hour, min); // App.getApp().getFormattedTime(hour, min);
				value = value[:hour] + ":" + value[:min] + value[:amPm]; 			      	
		        dc.setColor(App.getApp().getProperty("ForegroundColor"), Gfx.COLOR_TRANSPARENT);
		        dc.drawText(halfWidth - 2, yPos - 15, Gfx.FONT_XTINY, value, Gfx.TEXT_JUSTIFY_LEFT);
	        }
        }
    }
    
    // Will draw bell if is alarm set
    function drawBell(dc) {
    	if (settings.alarmCount > 0) {
    		var xPos = dc.getWidth() / 2;
    		var yPos = ((dc.getHeight() / 6).toNumber() * 4) + 2;
    		dc.setColor(App.getApp().getProperty("ForegroundColor"), App.getApp().getProperty("BackgroundColor"));
    		dc.fillCircle(xPos, yPos, 7);
    	
    		// stands
    		dc.setPenWidth(3);	
    		dc.drawLine(xPos - 5, yPos, xPos - 7, yPos + 7);
    		dc.drawLine(xPos + 5, yPos, xPos + 7, yPos + 7);
    		
    		dc.setPenWidth(2);
    		dc.drawLine(xPos - 5, yPos - 7, xPos - 9, yPos - 3);
    		dc.drawLine(xPos + 6, yPos - 7, xPos + 10, yPos - 3);
    		
    		dc.setColor(App.getApp().getProperty("BackgroundColor"), App.getApp().getProperty("ForegroundColor"));
    		dc.fillCircle(xPos, yPos, 5);
    		
    		// hands
    		dc.setColor(App.getApp().getProperty("ForegroundColor"), App.getApp().getProperty("BackgroundColor"));
    		dc.drawLine(xPos, yPos, xPos, yPos - 5);
    		dc.drawLine(xPos, yPos, xPos - 2, yPos + 4);
      	}
    } 
    
    // Draw the master dial 
    function drawDial(dc) {
    	// this part is draw the net over all display
    	dc.setColor(App.getApp().getProperty("ForegroundColor"), App.getApp().getProperty("BackgroundColor"));
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
      	dc.setColor(App.getApp().getProperty("BackgroundColor"), App.getApp().getProperty("ForegroundColor"));     	
      	dc.drawCircle(halfScreen, halfScreen, halfScreen - 1);
      	dc.fillCircle(halfScreen, halfScreen, halfScreen - App.getApp().getProperty("SmallHoursIndicatorSize"));
      	
      	// draw the master pieces in 24, 12, 6, 18 hours point
      	var masterPointLen = 12;
      	var masterPointWid = 4; 
      	dc.setColor(App.getApp().getProperty("ForegroundColor"), Gfx.COLOR_TRANSPARENT);
      	dc.setPenWidth(masterPointWid);
      	dc.drawLine(halfScreen, 0, halfScreen, masterPointLen);
      	dc.drawLine(halfScreen, dc.getWidth(), halfScreen, dc.getWidth() - masterPointLen); 
      	dc.drawLine(0, halfScreen - (masterPointWid / 2), masterPointLen, halfScreen - (masterPointWid / 2)); 
      	dc.drawLine(dc.getWidth(), halfScreen - (masterPointWid / 2), dc.getWidth() - masterPointLen, halfScreen - (masterPointWid / 2)); 
    
    	// numbers
    	dc.drawText(halfScreen, masterPointLen - 3, Gfx.FONT_TINY, "12", Gfx.TEXT_JUSTIFY_CENTER);	// 12
    	dc.drawText(halfScreen, dc.getHeight() - Gfx.getFontHeight(Gfx.FONT_TINY) - 11, Gfx.FONT_TINY, "24", Gfx.TEXT_JUSTIFY_CENTER);	// 24   	
    	dc.drawText(dc.getWidth() - 15, halfScreen - (Gfx.getFontHeight(Gfx.FONT_TINY) / 2) - 3, Gfx.FONT_TINY, "18", Gfx.TEXT_JUSTIFY_RIGHT);	// 18
    	dc.drawText(15, halfScreen - (Gfx.getFontHeight(Gfx.FONT_TINY) / 2) - 3, Gfx.FONT_TINY, "06", Gfx.TEXT_JUSTIFY_LEFT);	// 06
    }
    
    // Draw numbers in the dial
    function drawNrDial(dc) {
    	dc.setColor(App.getApp().getProperty("ForegroundColor"), Gfx.COLOR_TRANSPARENT);   	
    	
       	var angleDeg = 0;
    	var pointX = 0;
    	var pointY = 0;
    	var halfScreen = dc.getWidth() / 2;
    	var hoursCircle = halfScreen - 15;
    	var angleToNrCorrection = -6;
    	for(var nr = 1; nr < 24; nr+=1) {
	      	if ((nr != 6) && (nr != 12) && (nr != 18)) {
	      		angleDeg = ((nr * 15) * Math.PI) / 180;
	      		pointX = ((hoursCircle * Math.cos(angleDeg)) + halfScreen);
	      		pointY = ((hoursCircle * Math.sin(angleDeg)) + halfScreen);
	      			      		
	      		switch (nr + angleToNrCorrection) {
	      			case 1:
						dc.drawText(pointX.toNumber(), pointY.toNumber() - 15, fnt01, "1", Gfx.TEXT_JUSTIFY_CENTER);
	      			break;
	      			
	      			case 2:
						dc.drawText(pointX.toNumber() + 1, pointY.toNumber() - 14, fnt02, "2", Gfx.TEXT_JUSTIFY_CENTER);
	      			break;
	      			
	      			case 3:
						dc.drawText(pointX.toNumber() + 3, pointY.toNumber() - 15, fnt03, "3", Gfx.TEXT_JUSTIFY_CENTER);
	      			break;
	      			
	      			case 4:
						dc.drawText(pointX.toNumber() + 4, pointY.toNumber() - 12, fnt04, "4", Gfx.TEXT_JUSTIFY_CENTER);
	      			break;
	      			
	      			case 5:
						dc.drawText(pointX.toNumber() + 4, pointY.toNumber() - 14, fnt05, "5", Gfx.TEXT_JUSTIFY_CENTER);
	      			break;
	      		
	      			case 7:
						dc.drawText(pointX.toNumber() + 4, pointY.toNumber() - 12, fnt07, "7", Gfx.TEXT_JUSTIFY_CENTER);
	      			break;
	      			
	      			case 8:
						dc.drawText(pointX.toNumber() + 4, pointY.toNumber() - 10, fnt08, "8", Gfx.TEXT_JUSTIFY_CENTER);
	      			break;
	      			
	      			case 9:
						dc.drawText(pointX.toNumber() + 4, pointY.toNumber() - 8, fnt09, "9", Gfx.TEXT_JUSTIFY_CENTER);
	      			break;
	      			
	      			case 10:
	      				dc.drawText(pointX.toNumber(), pointY.toNumber() - 7, fnt10, "1", Gfx.TEXT_JUSTIFY_CENTER);
						dc.drawText(pointX.toNumber() + 6, pointY.toNumber() - 10, fnt10, "0", Gfx.TEXT_JUSTIFY_CENTER);
	      			break;
	      		
	      			case 11:
	      				dc.drawText(pointX.toNumber() - 2, pointY.toNumber() - 6, fnt11, "1", Gfx.TEXT_JUSTIFY_CENTER);
						dc.drawText(pointX.toNumber() + 6, pointY.toNumber() - 8, fnt11, "1", Gfx.TEXT_JUSTIFY_CENTER);
	      			break;
	      			
	      			case 13:
	      				dc.drawText(pointX.toNumber() - 5, pointY.toNumber() - 8, fnt13, "1", Gfx.TEXT_JUSTIFY_CENTER);
						dc.drawText(pointX.toNumber() + 3, pointY.toNumber() - 5, fnt13, "3", Gfx.TEXT_JUSTIFY_CENTER);
	      			break;
	      			
	      			case 14:
	      				dc.drawText(pointX.toNumber() - 6, pointY.toNumber() - 10, fnt14, "1", Gfx.TEXT_JUSTIFY_CENTER);
						dc.drawText(pointX.toNumber() + 2, pointY.toNumber() - 4, fnt14, "4", Gfx.TEXT_JUSTIFY_CENTER);
	      			break;
	      				
	      			case 15:
	      				dc.drawText(pointX.toNumber() - 6, pointY.toNumber() - 11, fnt15, "1", Gfx.TEXT_JUSTIFY_CENTER);
						dc.drawText(pointX.toNumber(), pointY.toNumber() - 5, fnt15, "5", Gfx.TEXT_JUSTIFY_CENTER);
	      			break;
	      			
	      			case 16:
	      				dc.drawText(pointX.toNumber() - 5, pointY.toNumber() - 13, fnt16, "1", Gfx.TEXT_JUSTIFY_CENTER);
						dc.drawText(pointX.toNumber() - 1, pointY.toNumber() - 5, fnt16, "6", Gfx.TEXT_JUSTIFY_CENTER);
	      			break;
	      			
	      			case 17:
	      				dc.drawText(pointX.toNumber() - 5, pointY.toNumber() - 15, fnt17, "1", Gfx.TEXT_JUSTIFY_CENTER);
						dc.drawText(pointX.toNumber() - 3, pointY.toNumber() - 6, fnt17, "7", Gfx.TEXT_JUSTIFY_CENTER);
	      			break;
	      			
	      			case -1:	// 23
	      				dc.drawText(pointX.toNumber() - 6, pointY.toNumber() - 15, fnt23, "2", Gfx.TEXT_JUSTIFY_CENTER);
						dc.drawText(pointX.toNumber() + 3, pointY.toNumber() - 17, fnt23, "3", Gfx.TEXT_JUSTIFY_CENTER);
	      			break;
	      			
	      			case -2:	// 22
	      				dc.drawText(pointX.toNumber() - 5, pointY.toNumber() - 12, fnt22, "2", Gfx.TEXT_JUSTIFY_CENTER);
						dc.drawText(pointX.toNumber() + 4, pointY.toNumber() - 17, fnt22, "2", Gfx.TEXT_JUSTIFY_CENTER);
	      			break;
	      			
	      			case -3:	// 21
	      				dc.drawText(pointX.toNumber() - 5, pointY.toNumber() - 10, fnt21, "2", Gfx.TEXT_JUSTIFY_CENTER);
						dc.drawText(pointX.toNumber() + 1, pointY.toNumber() - 18, fnt21, "1", Gfx.TEXT_JUSTIFY_CENTER);
	      			break;
	      			
	      			case -4:	// 20
	      				dc.drawText(pointX.toNumber() - 5, pointY.toNumber() - 10, fnt20, "2", Gfx.TEXT_JUSTIFY_CENTER);
						dc.drawText(pointX.toNumber(), pointY.toNumber() - 19, fnt20, "0", Gfx.TEXT_JUSTIFY_CENTER);
	      			break;
	      			
	      			case -5:	// 19
	      				dc.drawText(pointX.toNumber() - 5, pointY.toNumber() - 10, fnt19, "1", Gfx.TEXT_JUSTIFY_CENTER);
						dc.drawText(pointX.toNumber() - 3, pointY.toNumber() - 18, fnt19, "9", Gfx.TEXT_JUSTIFY_CENTER);
	      			break;
	      		}
      		}
      	}
    }
    
    // Draw sunset or sunrice image 
    function drawSun(posX, posY, dc, up) {
    	var radius = 8;
    	var penWidth = 2;
    	dc.setPenWidth(penWidth);
    	dc.setColor(App.getApp().getProperty("DaylightProgess"), App.getApp().getProperty("BackgroundColor"));
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
    	dc.setColor(App.getApp().getProperty("BackgroundColor"), App.getApp().getProperty("ForegroundColor"));
    	dc.fillRectangle(posX - radius - 1, posY + penWidth, (radius * 2) + (penWidth * 2), radius);
    }
    
    // Draw steps image
    function drawSteps(posX, posY, dc) {
    	if (dc.getWidth() == 280) {	// FENIX 6X correction
      		posX -= 10;
      		posY += 2;
      	}
      	if (is240dev) {	// 240x240 device correction
      		posY += 5;
      	}
    	dc.setColor(App.getApp().getProperty("DaylightProgess"), App.getApp().getProperty("BackgroundColor"));
    	/*
    	dc.fillCircle(posX, posY, 2);	// left bottom
    	dc.fillCircle(posX, posY-8, 3); // left middle
    	dc.fillCircle(posX, posY-10, 3); // left top
    	
    	dc.fillCircle(posX+12, posY-4, 2);	// right bottom
    	dc.fillCircle(posX+12, posY-12, 3); // right middle
    	dc.fillCircle(posX+12, posY-14, 3); // right top
    	*/
    	
    	dc.drawText(posX - 5, posY - 19, fntIcons, "0", Gfx.TEXT_JUSTIFY_LEFT);
    	
    	dc.setColor(App.getApp().getProperty("ForegroundColor"), Gfx.COLOR_TRANSPARENT);
    	var info = ActivityMonitor.getInfo();
    	var stepsCount = info.steps;
    	if (is240dev && (stepsCount > 999)){
    		stepsCount = (info.steps / 1000.0).format("%.1f").toString() + "k";
    	}
		dc.drawText(posX + 22, posY - 16, Gfx.FONT_XTINY, stepsCount.toString(), Gfx.TEXT_JUSTIFY_LEFT);
    }
    
    // Draw BT connection status
    function drawBtConnection(dc) {
    	if ((settings has : phoneConnected) && (settings.phoneConnected)) {
    		var radius = 5;
    		dc.setColor(Gfx.COLOR_BLUE, App.getApp().getProperty("BackgroundColor"));
       		dc.fillCircle((dc.getWidth() / 2) - 9, dc.getHeight() - Gfx.getFontHeight(Gfx.FONT_TINY) -(radius * 3), radius);	
   		}
    }
    
    // Draw notification alarm
    function drawNotification(dc) {
    	if ((settings has : notificationCount) && (settings.notificationCount)) {
    		var radius = 5;
    		dc.setColor(Gfx.COLOR_RED, App.getApp().getProperty("BackgroundColor"));
       		dc.fillCircle((dc.getWidth() / 2) + 6, dc.getHeight() - Gfx.getFontHeight(Gfx.FONT_TINY) - (radius * 3), radius);	
   		} 
    }
    
    // Returns formated date by settings
    function getFormatedDate() {
    	var ret = "";
    	if (App.getApp().getProperty("DateFormat") <= 3) {
    		var today = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
    		if (App.getApp().getProperty("DateFormat") == 1) {
    			ret = Lang.format("$1$ $2$ $3$", [today.day_of_week, today.day, today.month]);
    		} else if (App.getApp().getProperty("DateFormat") == 2) {
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
        dc.setColor(App.getApp().getProperty("ForegroundColor"), App.getApp().getProperty("BackgroundColor"));
        if (phase == 0) {
	        dc.setPenWidth(2);
        	dc.drawCircle(xPos, yPos, radius);
        } else {
        	dc.fillCircle(xPos, yPos, radius);
        	if (phase == 1) {
        		dc.setColor(App.getApp().getProperty("BackgroundColor"), App.getApp().getProperty("ForegroundColor"));
        		dc.fillCircle(xPos - 5, yPos, radius);			
			} else if (phase == 2) {
				dc.setColor(App.getApp().getProperty("BackgroundColor"), App.getApp().getProperty("ForegroundColor"));
        		dc.fillRectangle(xPos - radius, yPos - radius, radius, (radius * 2) + 2);		
			} else if (phase == 3) {
				dc.setPenWidth(8);
				dc.setColor(App.getApp().getProperty("BackgroundColor"), App.getApp().getProperty("ForegroundColor"));
				dc.drawArc(xPos + 5, yPos, radius + 5, Gfx.ARC_CLOCKWISE, 270, 90);
			} else if (phase == 5) {
				dc.setPenWidth(8);
				dc.setColor(App.getApp().getProperty("BackgroundColor"), App.getApp().getProperty("ForegroundColor"));
				dc.drawArc(xPos - 5, yPos, radius + 5, Gfx.ARC_CLOCKWISE, 90, 270);				
			} else if (phase == 6) {
				dc.setColor(App.getApp().getProperty("BackgroundColor"), App.getApp().getProperty("ForegroundColor"));
        		dc.fillRectangle(xPos + (radius / 2) - 3, yPos - radius, radius, (radius * 2) + 2);
			} else if (phase == 7) {
				dc.setColor(App.getApp().getProperty("BackgroundColor"), App.getApp().getProperty("ForegroundColor"));
        		dc.fillCircle(xPos + 5, yPos, radius);	
			}      	
        }
	}
	
	// Draw battery witch % state
	function drawBattery(xPos, yPos, dc, position) {
		if (is240dev && (position == 3)) {
			xPos -= 6;
		}
		if (is280dev && (position == 4)) {
			xPos -= 8;
		}
		dc.setPenWidth(1);
		if (System.getSystemStats().battery <= 10) {
	      	dc.setColor(Gfx.COLOR_RED, App.getApp().getProperty("BackgroundColor"));
		} else {
	      	dc.setColor(App.getApp().getProperty("ForegroundColor"), App.getApp().getProperty("BackgroundColor"));
		}
      	if (dc.getWidth() == 280) {	// FENIX 6X correction
      		xPos += 10;
      	}
      	var batteryWidth = 23;
      	dc.drawRectangle(xPos - 34, yPos + 4, batteryWidth, 13);	// battery
 		dc.drawRectangle(xPos + batteryWidth - 34, yPos + 8, 2, 5);	// battery top
 		var batteryColor = Gfx.COLOR_GREEN;
 		if (System.getSystemStats().battery <= 10) {
 			batteryColor = Gfx.COLOR_RED;
 		} else if (System.getSystemStats().battery <= 35) {
 			batteryColor = Gfx.COLOR_ORANGE;
 		}
 		
 		dc.setColor(batteryColor, App.getApp().getProperty("BackgroundColor"));
 		var batteryState = ((System.getSystemStats().battery / 10) * 2).toNumber();
 		dc.fillRectangle(xPos + 1 - 34, yPos + 5, batteryState + 1, 11);
 		
 		// x="180" y="164"
 		var batText = System.getSystemStats().battery.toNumber().toString() + "%";
        dc.setColor(App.getApp().getProperty("ForegroundColor"), Gfx.COLOR_TRANSPARENT);
 		dc.drawText(xPos + 29 - 34, yPos, Gfx.FONT_XTINY, batText, Gfx.TEXT_JUSTIFY_LEFT);		
	}
	
	function  drawAltitude(xPos, yPos, dc) {        
        dc.setColor(App.getApp().getProperty("ForegroundColor"), Gfx.COLOR_TRANSPARENT);
        dc.drawText(xPos, yPos, Gfx.FONT_XTINY, getAltitude(), Gfx.TEXT_JUSTIFY_CENTER);
        
        // coordinates correction text to mountain picture
        xPos = xPos - 46;
        yPos = yPos + 2;
        dc.setPenWidth(2);
    	dc.setColor(App.getApp().getProperty("DaylightProgess"), App.getApp().getProperty("BackgroundColor"));
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