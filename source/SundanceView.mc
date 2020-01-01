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
	const FLOORS = 2;
	const STEPS = 4;
	const HR = 5;
	const BATTERY = 6;
	const ALTITUDE = 7;
	const PRESSURE = 8;
	const DISABLED = 100;
	const PRESSURE_GRAPH_BORDER = 3;	// pressure border to change the graph in hPa

	// others
	hidden var settings;
	hidden var app;
	hidden var is240dev;
	hidden var is280dev;
	hidden var secPosX;
	hidden var secPosY;
	hidden var secFontWidth;
	hidden var secFontHeight;

	// Sunset / sunrise vars
	hidden var sc;
	hidden var location = null;
	
	// night mode
	hidden var frColor = null;
	hidden var bgColor = null;
	hidden var isNight = null;

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
        sc = new SunCalc();

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
        secFontHeight = Gfx.getFontHeight(Gfx.FONT_TINY);
        secFontWidth = (is280dev ? 24 : 22);
        secPosX = dc.getWidth() - 15;
        secPosY = halfWidth - (secFontHeight / 2) - 3;
        
        var yPosFor23 = ((dc.getHeight() / 6).toNumber() * 4) - 9;
        field1 = [halfWidth - 23, 60];
        field2 = [(dc.getWidth() / 5) + 2, yPosFor23];
        field3 = [halfWidth + 56, yPosFor23];
        field4 = [(dc.getWidth() / 13) * 7, ((dc.getHeight() / 4).toNumber() * 3) - 6];		// on F6 [140, 189]
   	
    	isNight = false;
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
    }

    // Update the view
    function onUpdate(dc) {   	
		if (dc has :clearClip) {	// Clear any partial update clipping.
			dc.clearClip();
		}
		
		if (isNight) {
			frColor = 0x000000;
    		bgColor = 0xFFFFFF;
		} else {
			frColor = App.getApp().getProperty("ForegroundColor");
    		bgColor = App.getApp().getProperty("BackgroundColor");
		}
    
    	// Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);
        settings = System.getDeviceSettings();
    	var today = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);

      	drawDial(dc, today);									// main dial
    	if (App.getApp().getProperty("ShowFullDial")) {		// subdial small numbers
	    	drawNrDial(dc);
    	}

        drawSunsetSunriseLine(field1[0], field1[1], dc, today);		// SUNSET / SUNRICE line
       	if (App.getApp().getProperty("AlarmIndicator")) {
	      	drawBell(dc);
      	}
       	if (App.getApp().getProperty("ShowNotificationAndConnection")) {
	      	drawBtConnection(dc);
	      	drawNotification(dc);
      	}

        // TIME
        dc.setColor(frColor, Gfx.COLOR_TRANSPARENT);
        var timeString = getFormattedTime(today.hour, today.min);
		dc.drawText(54, ((dc.getHeight() / 2) - Gfx.getFontHeight(Gfx.FONT_SYSTEM_NUMBER_HOT) / 2) + 2, Gfx.FONT_XTINY, timeString[:amPmFull], Gfx.TEXT_JUSTIFY_CENTER);
		dc.drawText(dc.getWidth() / 2, (dc.getHeight() / 2) - (Gfx.getFontHeight(Gfx.FONT_SYSTEM_NUMBER_HOT) / 2), Gfx.FONT_SYSTEM_NUMBER_HOT, timeString[:formatted], Gfx.TEXT_JUSTIFY_CENTER);

        // DATE
        if (App.getApp().getProperty("DateFormat") != DISABLED) {
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
        		drawSunsetSunriseTime(field1[0], field1[1], dc);
        	break;
        }

        // FIELD 2
        switch (App.getApp().getProperty("Opt2")) {
        	case FLOORS:
        	drawFloors(field2[0], field2[1], dc, 2);
        	break;
        
        	case STEPS:
    		drawSteps(field2[0], field2[1], dc, 2);
    		break;

    		case HR:
    		drawHr(field2[0], field2[1], dc, 2);
    		break;

    		case PRESSURE:
        	drawPressure(field2[0], field2[1], dc, getPressure(), today, 2);
    		break;
        }

        // FIELD 3
        switch (App.getApp().getProperty("Opt3")) {
        	case FLOORS:
        	drawFloors(field3[0], field3[1], dc, 3);
        	break;
        	
        	case STEPS:
    		drawSteps(field3[0], field3[1], dc, 3);
    		break;
        	
        	case BATTERY:
	        drawBattery(field3[0], field3[1], dc, 3);
        	break;

        	case HR:
	        drawHr(field3[0], field3[1], dc, 3);
			break;
        }

        // FIELD 4
        switch (App.getApp().getProperty("Opt4")) {
        	case FLOORS:
        	drawFloors(field4[0], field4[1], dc, 4);
        	break; 
        	
        	case STEPS:
    		drawSteps(field4[0], field4[1], dc, 4);
    		break;
        	
        	case ALTITUDE:
        	drawAltitude(field4[0], field4[1], dc);
        	break;

        	case BATTERY:
	        drawBattery(field4[0], field4[1], dc, 4);
        	break;

        	case HR:
        	drawHr(field4[0], field4[1], dc, 4);
        	break;

        	case PRESSURE:
        	drawPressure(field4[0], field4[1], dc, getPressure(), today, 4);
        	break;
        }

        // Logging pressure history all the time
        if (today.min == 0) {
	        hadnlePressureHistorty(getPressure());
        }
    }
    
    
    function onPartialUpdate(dc) {
    	if (App.getApp().getProperty("ShowSeconds")) {
    		dc.setClip(secPosX - secFontWidth, secPosY - 2, secFontWidth, secFontHeight);		
			dc.setColor(frColor, bgColor);	
			dc.clear();	
    		var today = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);   	
    		dc.drawText(secPosX, secPosY, Gfx.FONT_TINY, today.sec.format("%02d"), Gfx.TEXT_JUSTIFY_RIGHT);	// seconds
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
    function drawHr(xPos, yPos, dc, position) {
    	if ((position == 2) && is240dev) {
    		xPos += 42;
    	} else if ((position == 2) && is280dev) {
    		xPos += 47;
    	} else if (position == 2) {
    		xPos += 37;
    	}
    	if ((position == 3) || (position == 4)) {
    		xPos += 11;
    	}
     	dc.setColor(App.getApp().getProperty("DaylightProgess"), Gfx.COLOR_TRANSPARENT);
    	dc.drawText(xPos - 44, yPos - 3, fntIcons, "3", Gfx.TEXT_JUSTIFY_LEFT);

    	dc.setColor(frColor, Gfx.COLOR_TRANSPARENT);
    	var hr = "--";
    	if (Activity.getActivityInfo().currentHeartRate != null) {
    		hr = Activity.getActivityInfo().currentHeartRate.toString();
    	}
        dc.drawText(xPos - 19, yPos, Gfx.FONT_XTINY, hr, Gfx.TEXT_JUSTIFY_LEFT);
    }

    function drawSunsetSunriseLine(xPos, yPos, dc, today) {
    	// Get today's sunrise/sunset times in current time zone.
        location = Activity.getActivityInfo().currentLocation;
        if (location) {
        	location = Activity.getActivityInfo().currentLocation.toRadians();
			app.setProperty("location", location);
		} else {
			location =  app.getProperty("location");
        }

        if (location != null) {
        	var now = new Time.Moment(Time.now().value());
	       	var sunrise = sc.calculate(now, location, SUNRISE);
        	var sunset = sc.calculate(now, location, SUNSET);

			if ((sunrise != null) && (sunset != null)) {
				dc.setPenWidth(App.getApp().getProperty("DaylightProgessWidth"));
				var rLocal = halfWidth - 2;

				// BLUE & GOLDEN HOUR
				if (App.getApp().getProperty("ShowGoldenBlueHours")) {
					var blueAm = sc.calculate(now, location, BLUE_HOUR_AM);
					var bluePm = sc.calculate(now, location, BLUE_HOUR_PM);
					drawDialLine(
						halfWidth,
						halfWidth,
						rLocal,
						sc.momentToInfo(blueAm),
						sc.momentToInfo(bluePm),
						App.getApp().getProperty("DaylightProgessWidth"),
						App.getApp().getProperty("BlueHourColor"),
						dc
					);

					// NORMAL SUN = GOLDEN COLOR
					drawDialLine(
						halfWidth,
						halfWidth,
						rLocal,
						sc.momentToInfo(sunrise),
						sc.momentToInfo(sunset),
						App.getApp().getProperty("DaylightProgessWidth"),
						App.getApp().getProperty("GoldenHourColor"),
						dc
					);

					// GOLDEN = NORMAL COLOR
					var goldenAm = sc.calculate(now, location, GOLDEN_HOUR_AM);
					var goldenPm = sc.calculate(now, location, GOLDEN_HOUR_PM);
					drawDialLine(
						halfWidth,
						halfWidth,
						rLocal,
						sc.momentToInfo(goldenAm),
						sc.momentToInfo(goldenPm),
						App.getApp().getProperty("DaylightProgessWidth"),
						App.getApp().getProperty("DaylightProgess"),
						dc
					);
				} else { // JUST NORMAL SUN
					drawDialLine(
						halfWidth,
						halfWidth,
						rLocal,
						sc.momentToInfo(sunrise),
						sc.momentToInfo(sunset),
						App.getApp().getProperty("DaylightProgessWidth"),
						App.getApp().getProperty("DaylightProgess"),
						dc
					);
				}

				// CURRENT TIME
				dc.setPenWidth(App.getApp().getProperty("CurrentTimePointerWidth"));
				var currTimeCoef = (today.hour + (today.min.toFloat() / 60)) * 15;
				var currTimeStart = 272 - currTimeCoef;	// 270 was corrected better placing of current time holder
				var currTimeEnd = 268 - currTimeCoef;	// 270 was corrected better placing of current time holder
				dc.setColor(App.getApp().getProperty("CurrentTimePointer"), Gfx.COLOR_TRANSPARENT);
				dc.drawArc(halfWidth, halfWidth, rLocal, Gfx.ARC_CLOCKWISE, currTimeStart, currTimeEnd);
        	}
    	}
    }


    // draw the line by the parametrs
    function drawDialLine(arcX, arcY, radius, momentStart, momentEnd, penWidth, color, dc) {
    	var angleCoef = 15;
    	dc.setPenWidth(penWidth);
    	dc.setColor(color, Gfx.COLOR_TRANSPARENT);

    	var startDecimal = momentStart.hour + (momentStart.min.toDouble() / 60);
		var lineStart = 270 - (startDecimal * angleCoef);

		var endDecimal = momentEnd.hour + (momentEnd.min.toDouble() / 60);
		var lineEnd = 270 - (endDecimal * angleCoef);

		dc.drawArc(arcX, arcY, radius, Gfx.ARC_CLOCKWISE, lineStart, lineEnd);
    }


   	// draw next sun event
    function drawSunsetSunriseTime(xPos, yPos, dc) {
	    if (location != null) {
	   		var now = new Time.Moment(Time.now().value());
	   		var sunrise = sc.calculate(now, location, SUNRISE);
	   		var sunset = sc.calculate(now, location, SUNSET);
	    	if ((sunrise != null) && (sunset != null)) {
				var nextSunEvent = 0;
				// Convert to same format as sunTimes, for easier comparison. Add a minute, so that e.g. if sun rises at
				// 07:38:17, then 07:38 is already consided daytime (seconds not shown to user).
				now = now.add(new Time.Duration(60));
				checkIfNightMode(sunrise, sunset, now);

				// Before sunrise today: today's sunrise is next.
				if (sunrise.compare(now) > 0) {		// now < sc.momentToInfo(sunrise)
					nextSunEvent = sc.momentToInfo(sunrise);
					drawSun(xPos, yPos, dc, false);
				// After sunrise today, before sunset today: today's sunset is next.
				} else if (sunset.compare(now) > 0) {	// now < sc.momentToInfo(sunset)
					nextSunEvent = sc.momentToInfo(sunset);
					drawSun(xPos, yPos, dc, true);
				// After sunset today: tomorrow's sunrise (if any) is next.
				} else {
					now = now.add(new Time.Duration(Gregorian.SECONDS_PER_DAY));
					sunrise = sc.calculate(now, location, SUNRISE);  // getSunTimes(gLocationLat, gLocationLng, null, /* tomorrow */ true);
					nextSunEvent = sc.momentToInfo(sunrise);
					drawSun(xPos, yPos, dc, false);
				}

				var value = getFormattedTime(nextSunEvent.hour, nextSunEvent.min); // App.getApp().getFormattedTime(hour, min);
				value = value[:formatted] + value[:amPm];
		        dc.setColor(frColor, Gfx.COLOR_TRANSPARENT);
		        dc.drawText(halfWidth - 2, yPos - 15, Gfx.FONT_XTINY, value, Gfx.TEXT_JUSTIFY_LEFT);
	        }
        }
    }
    
    
    // check if night mode on and if is night
    function checkIfNightMode(sunrise, sunset, now) {
    	if (App.getApp().getProperty("NightMode")) {
    		now = now.add(new Time.Duration(60));	// add 1 minute because I need to switch the colors in the next onUpdate iteration
	    	// Before sunrise today: today's sunrise is next.
			if (sunrise.compare(now) > 0) {		// now < sc.momentToInfo(sunrise)
				isNight = true;
			// After sunrise today, before sunset today: today's sunset is next.
			} else if (sunset.compare(now) > 0) {	// now < sc.momentToInfo(sunset)
				isNight = false;
			// After sunset today: tomorrow's sunrise (if any) is next.
			} else {
				isNight = true;
			}
		} else {
			isNight = false;
		}
    }

    // Will draw bell if is alarm set
    function drawBell(dc) {
    	if (settings.alarmCount > 0) {
    		var xPos = dc.getWidth() / 2;
    		var yPos = ((dc.getHeight() / 6).toNumber() * 4) + 2;
    		dc.setColor(frColor, bgColor);
    		dc.fillCircle(xPos, yPos, 7);

    		// stands
    		dc.setPenWidth(3);
    		dc.drawLine(xPos - 5, yPos, xPos - 7, yPos + 7);
    		dc.drawLine(xPos + 5, yPos, xPos + 7, yPos + 7);

    		dc.setPenWidth(2);
    		dc.drawLine(xPos - 5, yPos - 7, xPos - 9, yPos - 3);
    		dc.drawLine(xPos + 6, yPos - 7, xPos + 10, yPos - 3);

    		dc.setColor(bgColor, frColor);
    		dc.fillCircle(xPos, yPos, 5);

    		// hands
    		dc.setColor(frColor, bgColor);
    		dc.drawLine(xPos, yPos, xPos, yPos - 5);
    		dc.drawLine(xPos, yPos, xPos - 2, yPos + 4);
      	}
    }

    // Draw the master dial
    function drawDial(dc, today) {
    	var halfScreen = dc.getWidth() / 2;
      	var pointX = 0;
      	var pointY = 0;
      	var angleDeg = 0;
      	
    	dc.setColor(bgColor, Gfx.COLOR_TRANSPARENT);	// nmake background
    	dc.fillCircle(halfScreen, halfScreen, halfScreen + 1);
    	
    	// this part is draw the net over all display
    	dc.setColor(frColor, Gfx.COLOR_TRANSPARENT);
      	dc.setPenWidth(2);
      	
      	for(var angle = 0; angle < 360; angle+=15) {
	      	if ((angle != 0) && (angle != 90) && (angle != 180) && (angle != 270)) {
	      		angleDeg = (angle * Math.PI) / 180;
	      		pointX = ((halfScreen * Math.cos(angleDeg)) + halfScreen);
	      		pointY = ((halfScreen * Math.sin(angleDeg)) + halfScreen);
	      		dc.drawLine(halfScreen, halfScreen, pointX, pointY);
      		}
      	}
      	// hide the middle of the net to shows just pieces on the edge of the screen
      	dc.setColor(bgColor, Gfx.COLOR_TRANSPARENT);
      	dc.drawCircle(halfScreen, halfScreen, halfScreen - 1);
      	dc.fillCircle(halfScreen, halfScreen, halfScreen - App.getApp().getProperty("SmallHoursIndicatorSize"));

      	// draw the master pieces in 24, 12, 6, 18 hours point
      	var masterPointLen = 12;
      	var masterPointWid = 4;
      	dc.setColor(frColor, Gfx.COLOR_TRANSPARENT);
      	dc.setPenWidth(masterPointWid);
      	dc.drawLine(halfScreen, 0, halfScreen, masterPointLen);
      	dc.drawLine(halfScreen, dc.getWidth(), halfScreen, dc.getWidth() - masterPointLen);
      	dc.drawLine(0, halfScreen - (masterPointWid / 2), masterPointLen, halfScreen - (masterPointWid / 2));
      	dc.drawLine(dc.getWidth(), halfScreen - (masterPointWid / 2), dc.getWidth() - masterPointLen, halfScreen - (masterPointWid / 2));

    	// numbers
    	dc.drawText(halfScreen, masterPointLen - 3, Gfx.FONT_TINY, "12", Gfx.TEXT_JUSTIFY_CENTER);	// 12
    	dc.drawText(halfScreen, dc.getHeight() - Gfx.getFontHeight(Gfx.FONT_TINY) - 11, Gfx.FONT_TINY, "24", Gfx.TEXT_JUSTIFY_CENTER);	// 24
    	dc.drawText(15, secPosY, Gfx.FONT_TINY, "06", Gfx.TEXT_JUSTIFY_LEFT);	// 06
    	
    	if (App.getApp().getProperty("ShowSeconds")) {
    		dc.drawText(secPosX, secPosY, Gfx.FONT_TINY, today.sec.format("%02d"), Gfx.TEXT_JUSTIFY_RIGHT);	// seconds
    	} else {
    		dc.drawText(secPosX, secPosY, Gfx.FONT_TINY, "18", Gfx.TEXT_JUSTIFY_RIGHT);	// 18    	   	
    	}
    }


    // Draw numbers in the dial
    function drawNrDial(dc) {
    	dc.setColor(frColor, Gfx.COLOR_TRANSPARENT);

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
						dc.drawText(pointX.toNumber() + 5, pointY.toNumber() - 13, fnt04, "4", Gfx.TEXT_JUSTIFY_CENTER);
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
    	dc.setColor(App.getApp().getProperty("DaylightProgess"), bgColor);
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
    	dc.setColor(bgColor, frColor);
    	dc.fillRectangle(posX - radius - 1, posY + penWidth, (radius * 2) + (penWidth * 2), radius);
    }


    // Draw steps image
    function drawSteps(posX, posY, dc, position) {
    	if (position == 3) {
			posX = (is240dev ? (posX - 36) : (posX - 34));    		
      	}
      	if (position == 4) {
      		posX = (is240dev ? (posX - 36) : (posX - 41));
      	}
      	
    	dc.setColor(App.getApp().getProperty("DaylightProgess"), bgColor);
    	dc.drawText(posX - 4, posY - 4, fntIcons, "0", Gfx.TEXT_JUSTIFY_LEFT);

    	dc.setColor(frColor, Gfx.COLOR_TRANSPARENT);
    	var info = ActivityMonitor.getInfo();
    	var stepsCount = info.steps;
    	if (is240dev && (stepsCount > 999) && ((position == 2) || (position == 3))){
    		stepsCount = (info.steps / 1000.0).format("%.1f").toString() + "k";
    	}
		dc.drawText(posX + 22, posY, Gfx.FONT_XTINY, stepsCount.toString(), Gfx.TEXT_JUSTIFY_LEFT);
    }
    
    // Draw steps image
    function drawFloors(posX, posY, dc, position) {   	     	
		if (position == 3) {
			posX -= 32;    		
      	}
      	if (position == 4) {
      		posX = (is240dev ? (posX - 25) : (posX - 28));
      	}
      	
    	dc.setColor(App.getApp().getProperty("DaylightProgess"), bgColor);
    	dc.drawText(posX - 4, posY - 4, fntIcons, "1", Gfx.TEXT_JUSTIFY_LEFT);

    	dc.setColor(frColor, Gfx.COLOR_TRANSPARENT);
    	var info = ActivityMonitor.getInfo();
		dc.drawText(posX + 22, posY, Gfx.FONT_XTINY, info.floorsClimbed.toString(), Gfx.TEXT_JUSTIFY_LEFT);
    }


    // Draw BT connection status
    function drawBtConnection(dc) {
    	if ((settings has : phoneConnected) && (settings.phoneConnected)) {
    		var radius = 5;
    		dc.setColor(Gfx.COLOR_BLUE, bgColor);
       		dc.fillCircle((dc.getWidth() / 2) - 9, dc.getHeight() - Gfx.getFontHeight(Gfx.FONT_TINY) -(radius * 3), radius);
   		}
    }


    // Draw notification alarm
    function drawNotification(dc) {
    	if ((settings has : notificationCount) && (settings.notificationCount)) {
    		var radius = 5;
    		dc.setColor(Gfx.COLOR_RED, bgColor);
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


	// Draw a moon by phase
	function drawMoonPhase(dc, phase) {
		var xPos = (dc.getWidth() / 2);
        var yPos = (dc.getHeight() / 5).toNumber(); //43;
        var radius = 9;
        dc.setColor(frColor, bgColor);
        if (phase == 0) {
	        dc.setPenWidth(2);
        	dc.drawCircle(xPos, yPos, radius);
        } else {
        	dc.fillCircle(xPos, yPos, radius);
        	if (phase == 1) {
        		dc.setColor(bgColor, frColor);
        		dc.fillCircle(xPos - 5, yPos, radius);
			} else if (phase == 2) {
				dc.setColor(bgColor, frColor);
        		dc.fillRectangle(xPos - radius, yPos - radius, radius, (radius * 2) + 2);
			} else if (phase == 3) {
				dc.setPenWidth(8);
				dc.setColor(bgColor, frColor);
				dc.drawArc(xPos + 5, yPos, radius + 5, Gfx.ARC_CLOCKWISE, 270, 90);
			} else if (phase == 5) {
				dc.setPenWidth(8);
				dc.setColor(bgColor, frColor);
				dc.drawArc(xPos - 5, yPos, radius + 5, Gfx.ARC_CLOCKWISE, 90, 270);
			} else if (phase == 6) {
				dc.setColor(bgColor, frColor);
        		dc.fillRectangle(xPos + (radius / 2) - 3, yPos - radius, radius, (radius * 2) + 2);
			} else if (phase == 7) {
				dc.setColor(bgColor, frColor);
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
	      	dc.setColor(Gfx.COLOR_RED, bgColor);
		} else {
	      	dc.setColor(frColor, bgColor);
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

 		dc.setColor(batteryColor, bgColor);
 		var batteryState = ((System.getSystemStats().battery / 10) * 2).toNumber();
 		dc.fillRectangle(xPos + 1 - 34, yPos + 5, batteryState + 1, 11);

 		// x="180" y="164"
 		var batText = System.getSystemStats().battery.toNumber().toString() + "%";
        dc.setColor(frColor, Gfx.COLOR_TRANSPARENT);
 		dc.drawText(xPos + 29 - 34, yPos, Gfx.FONT_XTINY, batText, Gfx.TEXT_JUSTIFY_LEFT);
	}

	function drawAltitude(xPos, yPos, dc) {
        dc.setColor(frColor, Gfx.COLOR_TRANSPARENT);
        dc.drawText(xPos, yPos, Gfx.FONT_XTINY, getAltitude(), Gfx.TEXT_JUSTIFY_CENTER);

        // coordinates correction text to mountain picture
        xPos = xPos - 46;
        yPos = yPos + 2;
        dc.setPenWidth(2);
    	dc.setColor(App.getApp().getProperty("DaylightProgess"), bgColor);
    	dc.drawLine(xPos + 1, yPos + 14, xPos + 5, yPos + 7);
    	dc.drawLine(xPos + 5, yPos + 7, xPos + 7, yPos + 10);
    	dc.drawLine(xPos + 7, yPos + 10, xPos + 11, yPos + 2);
    	dc.drawLine(xPos + 11, yPos + 2, xPos + 20, yPos + 15);
	}

	// Draw the pressure state and current pressure
	function drawPressure(xPos, yPos, dc, pressure, today, position) {
		if (position == 2) {
				xPos += 30;
		}
		if (today.min == 0) {	// grap is redrawning only whole hour
			var baroFigure = 0;
			var pressure8 = app.getProperty("pressure8");
			var pressure4 = app.getProperty("pressure4");
			var pressure1 = app.getProperty("pressure1");
			if (pressure1 != null) {	// always should have at least pressure1 but test it for sure
				pressure1 = pressure1.toNumber();
				pressure4 = (pressure4 == null ? pressure1 : pressure4.toNumber());	// if still dont have historical data, use the current data
				pressure8 = (pressure8 == null ? pressure1 : pressure8.toNumber());
				if ((pressure8 - pressure4).abs() < PRESSURE_GRAPH_BORDER) {	// baroFigure 1 OR 2
					if ((pressure4 > pressure1) && ((pressure4 - pressure1) >= PRESSURE_GRAPH_BORDER)) { 	// baroFigure 1
						baroFigure = 1;
					}
					if ((pressure1 > pressure4) && ((pressure1 - pressure4) >= PRESSURE_GRAPH_BORDER)) { 	// baroFigure 2
						baroFigure = 2;
					}
				}
				if ((pressure8 > pressure4) && ((pressure8 - pressure4) >= PRESSURE_GRAPH_BORDER)) {	// baroFigure 3, 4, 5
					baroFigure = 4;
					if ((pressure4 > pressure1) && ((pressure4 - pressure1) >= PRESSURE_GRAPH_BORDER)) {	// baroFigure 3
						baroFigure = 3;
					}
					if ((pressure1 > pressure4) && ((pressure1 - pressure4) >= PRESSURE_GRAPH_BORDER)) {	// baroFigure 5
						baroFigure = 5;
					}
				}
				if ((pressure4 > pressure8) && ((pressure4 - pressure8) >= PRESSURE_GRAPH_BORDER)) {	// baroFigure 6, 7, 8
					baroFigure = 7;
					if ((pressure4 > pressure1) && ((pressure4 - pressure1) >= PRESSURE_GRAPH_BORDER)) {	// FIGIRE 6
						baroFigure = 6;
					}
					if ((pressure1 > pressure4) && ((pressure1 - pressure4) >= PRESSURE_GRAPH_BORDER)) {	// baroFigure 8
						baroFigure = 8;
					}
				}
			}
			app.setProperty("baroFigure", baroFigure);
		}
		var baroFigure = (app.getProperty("baroFigure") == null ? 0 : app.getProperty("baroFigure").toNumber());
		drawPressureGraph(xPos - 34, yPos + 10, dc, baroFigure);
		dc.setColor(frColor, Gfx.COLOR_TRANSPARENT);
		dc.drawText(xPos - 6, yPos, Gfx.FONT_XTINY, pressure.toString(), Gfx.TEXT_JUSTIFY_LEFT);
	}

	// Draw small pressure graph based on baroFigure
	// 0 - no change during last 8 hours - chnage don`t hit the PRESSURE_GRAPH_BORDER --
	// 1 - the same first 4 hours, then down -\
	// 2 - the same first 4 hours, then up -/
	// 3 - still down \
	// 4 - going down first 4 hours, then the same \_
	// 5 - going down first 4 house, then up \/
	// 6 - going up for first 4 hours, then down /\
	// 7 - going up for first 4 hours, then the same /-
	// 8 - stil going up /
	function drawPressureGraph(xPos, yPos, dc, figure) {
		dc.setPenWidth(2);
		dc.setColor(App.getApp().getProperty("DaylightProgess"), bgColor);
		switch (figure) {
			case 0:
				dc.drawLine(xPos, yPos, xPos + 22, yPos);
			break;

			case 1:
				dc.drawLine(xPos, yPos, xPos + 11, yPos);
				dc.drawLine(xPos + 11, yPos, xPos + 22, yPos + 9);
			break;

			case 2:
				dc.drawLine(xPos, yPos, xPos + 11, yPos);
				dc.drawLine(xPos + 11, yPos, xPos + 22, yPos - 9);
			break;

			case 3:
				dc.drawLine(xPos, yPos - 9, xPos + 22, yPos + 9);
			break;

			case 4:
				dc.drawLine(xPos, yPos - 9, xPos + 11, yPos);
				dc.drawLine(xPos + 11, yPos, xPos + 22, yPos);
			break;

			case 5:
				dc.drawLine(xPos, yPos - 9, xPos + 11, yPos);
				dc.drawLine(xPos + 11, yPos, xPos + 22, yPos - 9);
			break;

			case 6:
				dc.drawLine(xPos, yPos + 9, xPos + 11, yPos);
				dc.drawLine(xPos + 11, yPos, xPos + 22, yPos + 9);
			break;

			case 7:
				dc.drawLine(xPos, yPos + 9, xPos + 11, yPos);
				dc.drawLine(xPos + 11, yPos, xPos + 22, yPos);
			break;

			case 8:
				dc.drawLine(xPos, yPos + 9, xPos + 22, yPos - 9);
			break;
		}
	}

	// Return a formatted time dictionary that respects is24Hour settings.
	// - hour: 0-23.
	// - min:  0-59.
	function getFormattedTime(hour, min) {
		var amPm = "";
		var amPmFull = "";
		var isMilitary = false;
		var timeFormat = "$1$:$2$";

		if (!System.getDeviceSettings().is24Hour) {
			// #6 Ensure noon is shown as PM.
			var isPm = (hour >= 12);
			if (isPm) {
				// But ensure noon is shown as 12, not 00.
				if (hour > 12) {
					hour = hour - 12;
				}
				amPm = "p";
				amPmFull = "PM";
			} else {
				// #27 Ensure midnight is shown as 12, not 00.
				if (hour == 0) {
					hour = 12;
				}
				amPm = "a";
				amPmFull = "AM";
			}
		} else {
            if (App.getApp().getProperty("UseMilitaryFormat")) {
            	isMilitary = true;
                timeFormat = "$1$$2$";
                hour = hour.format("%02d");
            }
        }

		return {
			:hour => hour,
			:min => min.format("%02d"),
			:amPm => amPm,
			:amPmFull => amPmFull,
			:isMilitary => isMilitary,
			:formatted => Lang.format(timeFormat, [hour, min.format("%02d")])
		};
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

	// Returns pressure in hPa
 	function getPressure() {
 		var pressure = null;
 		var value = null;
 		// Avoid using ActivityInfo.ambientPressure, as this bypasses any manual pressure calibration e.g. on Fenix
		// 5. Pressure is unlikely to change frequently, so there isn't the same concern with getting a "live" value,
		// compared with HR. Use SensorHistory only.
		if ((Toybox has :SensorHistory) && (Toybox.SensorHistory has :getPressureHistory)) {
			var sample = SensorHistory.getPressureHistory(null).next();
			if ((sample != null) && (sample.data != null)) {
				pressure = sample.data;
			}
		}

		if (pressure != null) {
			pressure = pressure / 100; // Pa --> hPa;
			value = pressure.format("%.0f"); // + "hPa";
		}

		return value;
 	}

 	// Each hour is the pressure saved (durring last 8 hours) for creation a simple graph
 	// storing 8 variables but working just with 4 right now (8,4.1)
 	function hadnlePressureHistorty(pressure) {
 		if (app.getProperty("pressure7") != null) {
 			app.setProperty("pressure8", app.getProperty("pressure7"));
 		}

 		if (app.getProperty("pressure6") != null) {
 			app.setProperty("pressure7", app.getProperty("pressure6"));
 		}

 		if (app.getProperty("pressure5") != null) {
 			app.setProperty("pressure6", app.getProperty("pressure5"));
 		}

 		if (app.getProperty("pressure4") != null) {
 			app.setProperty("pressure5", app.getProperty("pressure4"));
 		}

 		if (app.getProperty("pressure3") != null) {
 			app.setProperty("pressure4", app.getProperty("pressure3"));
 		}

 		if (app.getProperty("pressure2") != null) {
 			app.setProperty("pressure3", app.getProperty("pressure2"));
 		}

 		if (app.getProperty("pressure1") != null) {
 			app.setProperty("pressure2", app.getProperty("pressure1"));
 		}
 		app.setProperty("pressure1", pressure);
 	}

}