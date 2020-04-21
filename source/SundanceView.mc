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
    const FLOORS = 2;
    const CALORIES = 3;
    const STEPS = 4;
    const HR = 5;
    const BATTERY = 6;
    const ALTITUDE = 7;
    const PRESSURE = 8;
    const SECOND_TIME = 10;
    const DISABLED = 100;
    const DISTANCE = 11;
    const PRESSURE_GRAPH_BORDER = 3;    // pressure border to change the graph in hPa
    const BATTERY_IN_DAYS = 12;

    // others
    hidden var settings;
    hidden var app;
    hidden var is240dev;
    hidden var is280dev;
    hidden var secPosX;
    hidden var secPosY;
    hidden var secFontWidth;
    hidden var secFontHeight;
    hidden var uc;
    hidden var smallDialCoordsLines;
    hidden var smallDialCoordsNums;

    // Sunset / sunrise / moon phase vars
    hidden var sc;
    hidden var sunriseMoment;
    hidden var sunsetMoment;
    hidden var blueAmMoment;
    hidden var bluePmMoment;
    hidden var goldenAmMoment;
    hidden var goldenPmMoment;
    
    hidden var dawn;
    hidden var dusk;
    hidden var astroDawn;
    hidden var astroDusk;
    
    hidden var location = null;
    hidden var moonPhase;

    // night mode
    hidden var frColor = null;
    hidden var bgColor = null;
    hidden var themeColor = null;

    hidden var fntIcons = null;
    hidden var fntDataFields = null;
    hidden var fntNk57_80 = null;
    hidden var fntNk57_35 = null;

    hidden var halfWidth = null;
    hidden var field1 = null;
    hidden var field2 = null;
    hidden var field3 = null;
    hidden var field4 = null;

    function initialize() {
        WatchFace.initialize();
        app = App.getApp();
        sc = new SunCalc();
        uc = new UiCalc();
        
        fntIcons = WatchUi.loadResource(Rez.Fonts.fntIcons);
        fntDataFields = WatchUi.loadResource(Rez.Fonts.fntDataFields);
        
        fntNk57_35 = WatchUi.loadResource(Rez.Fonts.fntNk57_35);
        fntNk57_80 = WatchUi.loadResource(Rez.Fonts.fntNk57_80);
    }

    // Load your resources here
    function onLayout(dc) {
        setLayout(Rez.Layouts.WatchFace(dc));
        is240dev = (dc.getWidth() == 240);
        is280dev = (dc.getWidth() == 280);

        halfWidth = dc.getWidth() / 2;
        secFontHeight = Gfx.getFontHeight(Gfx.FONT_SYSTEM_SMALL);
        secFontWidth = (is280dev ? 24 : 22);
        secPosX = dc.getWidth() - 36;
        secPosY = halfWidth - (secFontHeight + 26);

        var yPosFor23 = ((dc.getHeight() / 6).toNumber() * 4) - 9;
        field1 = [halfWidth - 23, 60];
        field2 = [(dc.getWidth() / 5) + 2, yPosFor23];
        field3 = [halfWidth + 56, yPosFor23];
        field4 = [(dc.getWidth() / 13) * 7, ((dc.getHeight() / 4).toNumber() * 3) - 6];     // on F6 [140, 189]

        smallDialCoordsLines = uc.calculateSmallDialLines(halfWidth);

        // sun / moon etc. init
        sunriseMoment = null;
        sunsetMoment = null;
        blueAmMoment = null;
        bluePmMoment = null;
        goldenAmMoment = null;
        goldenPmMoment = null;
        dawn = null;
        dusk = null;
        astroDawn = null;
        astroDusk = null;
        moonPhase = null;
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
    }

    // Update the view
    function onUpdate(dc) {
        if (dc has :clearClip) {    // Clear any partial update clipping.
            dc.clearClip();
        }

        var now = Time.now();
        var today = Gregorian.info(now, Time.FORMAT_MEDIUM);
        // if don't have the sun times load it if from position or load again in midnight
        if ((sunriseMoment == null) || (sunsetMoment == null)) {
            reloadSuntimes(now);    // calculate for current date
        }

        // the values are known, need to find last sun event for today and recalculated the first which will come tomorrow
        if ((sunriseMoment != null) && (sunsetMoment != null) && (location != null)) {  // TODO
            var lastSunEventInDayMoment = (App.getApp().getProperty("ShowGoldenBlueHours") ? bluePmMoment : sunsetMoment);
            var nowWithOneMinute = now.add(new Time.Duration(60));
            // if sunrise moment is in past && is after last sunevent (bluePmMoment / sunsetMoment) need to recalculate
            if ((nowWithOneMinute.compare(sunriseMoment) > 0) && (nowWithOneMinute.compare(lastSunEventInDayMoment) > 0)) { // is time to recalculte?
                var nowWithOneDay = now.add(new Time.Duration(Gregorian.SECONDS_PER_DAY));
                reloadSuntimes(nowWithOneDay);
            }
        }

        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);
        settings = System.getDeviceSettings();
        var isNight = checkIfNightMode(sunriseMoment, sunsetMoment, new Time.Moment(now.value()));  // needs to by firts bucause of isNight variable
        if (isNight) {
            frColor = 0x000000;
            bgColor = 0xFFFFFF;
            themeColor = (App.getApp().getProperty("NightModeTheme") ? App.getApp().getProperty("NightModeThemeColor") : App.getApp().getProperty("DaylightProgess"));
        } else {
            frColor = App.getApp().getProperty("ForegroundColor");
            bgColor = App.getApp().getProperty("BackgroundColor");
            themeColor = App.getApp().getProperty("DaylightProgess");
        }

        // BACKGROUND vs FOREGROUND 
        dc.setColor(bgColor, Gfx.COLOR_TRANSPARENT);    // nmake background
        dc.fillCircle(halfWidth, halfWidth, halfWidth + 1);

        // NEXT SUN EVENT
        drawSunsetSunriseLine(field1[0], field1[1], dc, today);     // all SUN SUN eventse from public variables
        drawSunsetSunriseTime(halfWidth, halfWidth + 20, dc);           // draw the times
        drawDial(dc, today);                                        // main dial

        // MOON
        today = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        drawMoonPhase(halfWidth, 36, dc, getMoonPhase(today));
        
        // DATE
        if (App.getApp().getProperty("DateFormat") != DISABLED) {
            var dateString = getFormatedDate();
            dc.setColor(frColor, Gfx.COLOR_TRANSPARENT);
            dc.drawText(halfWidth, 48, Gfx.FONT_TINY, dateString, Gfx.TEXT_JUSTIFY_CENTER);
        }
      
        
        // Logging pressure history all the time on each hour
        var lastPressureLoggingTime = (app.getProperty("lastPressureLoggingTime") == null ? null : app.getProperty("lastPressureLoggingTime").toNumber());
        if ((today.min == 0) && (today.hour != lastPressureLoggingTime)) {
            hadnlePressureHistorty(getPressure());
            app.setProperty("lastPressureLoggingTime", today.hour);
        }
        
        // second time calculation and dial drawing if any
        var secondTime = calculateSecondTime(new Time.Moment(now.value()));
        if (App.getApp().getProperty("ShowSecondTimeOnDial")) {
            //drawTimePointerInDial(secondTime, App.getApp().getProperty("SecondTimePointerType"), App.getApp().getProperty("SecondTimeOnDialColor"), dc);
        }
              
        // drawDataField(App.getApp().getProperty("Opt1"), 1, field1, today, secondTime, dc);  // FIELD 1
        // drawDataField(App.getApp().getProperty("Opt2"), 2, field2, today, secondTime, dc);  // FIELD 2
        // drawDataField(App.getApp().getProperty("Opt3"), 3, field3, today, secondTime, dc);  // FIELD 3
        // drawDataField(App.getApp().getProperty("Opt4"), 4, field4, today, secondTime, dc);  // FIELD 4
        
        if (App.getApp().getProperty("ShowNotificationAndConnection")) {
            drawBtConnection(dc);
            drawNotification(dc);
        }
        if (App.getApp().getProperty("AlarmIndicator")) {
            drawBell(dc);
        }

        // TIME
        dc.setColor(frColor, Gfx.COLOR_TRANSPARENT);
        var timeString = getFormattedTime(today.hour, today.min);
        dc.drawText(dc.getWidth() - (dc.getFontHeight(Gfx.FONT_SYSTEM_TINY)) - 18 , 110, fntNk57_35, timeString[:amPmFull], Gfx.TEXT_JUSTIFY_CENTER);
        dc.drawText(halfWidth + 70, halfWidth - (Gfx.getFontHeight(fntNk57_80)) + 14, fntNk57_80, timeString[:formatted], Gfx.TEXT_JUSTIFY_RIGHT);
        dc.drawText(secPosX, secPosY, fntNk57_35, today.sec.format("%02d"), Gfx.TEXT_JUSTIFY_RIGHT); // seconds
        
        // BATERRY
        var batteryInDays = (App.getApp().getProperty("BatteryType") == 12);
        drawBattery(halfWidth + 20, dc.getHeight() - 34, dc, today, batteryInDays);
        
        // CURRENT TIME POINTER
        drawPointToDialFilled(dc, bgColor, today);
    }


    function onPartialUpdate(dc) {
        if (App.getApp().getProperty("ShowSeconds")) {
            dc.setClip(secPosX - secFontWidth, secPosY - 2, secFontWidth, secFontHeight);
            dc.setColor(frColor, bgColor);
            dc.clear();
            var today = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
            dc.drawText(secPosX, secPosY, Gfx.FONT_TINY, today.sec.format("%02d"), Gfx.TEXT_JUSTIFY_RIGHT); // seconds
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
    
    
    // Draw data field by params. One function do all the fields by coordinates and position
    function drawDataField(dataFiled, position, fieldCors, today, secondTime, dc) {
        switch (dataFiled) {
            case HR:
            drawHr(fieldCors[0], fieldCors[1], dc, position);
            break;

            case PRESSURE:
            drawPressure(fieldCors[0], fieldCors[1], dc, getPressure(), today, position);
            break;

            case STEPS:
            drawSteps(fieldCors[0], fieldCors[1], dc, position);
            break;
            
            case DISTANCE:
            drawDistance(fieldCors[0], fieldCors[1], dc, position);
            break;

            case ALTITUDE:
            drawAltitude(fieldCors[0], fieldCors[1], dc, position);
            break;

            case FLOORS:
            drawFloors(fieldCors[0], fieldCors[1], dc, position);
            break;

            case CALORIES:
            drawCalories(fieldCors[0], fieldCors[1], dc, position);
            break;
            
            case SECOND_TIME:
            drawSecondTime(fieldCors[0], fieldCors[1], dc, secondTime, position);
            break;
        }
    }    
    
    // Calculate second time from setting option
    // returns Gregorian Info
    function calculateSecondTime(todayMoment) {
        var utcOffset = System.getClockTime().timeZoneOffset * -1;
        var utcMoment = todayMoment.add(new Time.Duration(utcOffset));
        var secondTimeMoment = utcMoment.add(new Time.Duration(App.getApp().getProperty("SecondTimeUtcOffset")));
        
        return sc.momentToInfo(secondTimeMoment);
    }
    
    
    // Draw second time liek a data field
    function drawSecondTime(xPos, yPos, dc, secondTime, position) {
        if (position == 1) {
            xPos += 24;
            yPos -= 17;
        }
        if (position == 2) {
            xPos += 21;
        }
        if (position == 3) {
            xPos -= (is280dev ? -2 : (is240dev ? 9 : 3));
        }
        if (position == 4) {
            xPos -= ((is240dev == false) && (is280dev == false) ? 9 : 5);
        }
        var value = getFormattedTime(secondTime.hour, secondTime.min);
        value = value[:formatted] + value[:amPm];
        dc.setColor(frColor, Gfx.COLOR_TRANSPARENT);
        dc.drawText(xPos, yPos, fntDataFields, value, Gfx.TEXT_JUSTIFY_CENTER);
    }

    // Load or refresh the sun times
    function reloadSuntimes(now) {
        var suntimes = getSunTimes(now);
        sunriseMoment = suntimes[:sunrise];
        sunsetMoment = suntimes[:sunset];
        blueAmMoment = suntimes[:blueAm];
        bluePmMoment = suntimes[:bluePm];
        goldenAmMoment = suntimes[:goldenAm];
        goldenPmMoment = suntimes[:goldenPm];
       
        dawn = suntimes[:dawn];
        dusk = suntimes[:dusk];
        astroDawn = suntimes[:astroDawn];
        astroDusk = suntimes[:astroDusk];       
    }

    // Draw current HR
    function drawHr(xPos, yPos, dc, position) {
        if (position == 1) {
            xPos += 44;
            yPos = (is240dev ? yPos - 18 : yPos - 16);
        }
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
        dc.setColor(themeColor, Gfx.COLOR_TRANSPARENT);
        dc.drawText(xPos - 44, yPos - 3, fntIcons, "3", Gfx.TEXT_JUSTIFY_LEFT);

        dc.setColor(frColor, Gfx.COLOR_TRANSPARENT);
        var hr = "--";
        if (Activity.getActivityInfo().currentHeartRate != null) {
            hr = Activity.getActivityInfo().currentHeartRate.toString();
        }
        dc.drawText(xPos - 19, yPos, fntDataFields, hr, Gfx.TEXT_JUSTIFY_LEFT);
    }


    // calculate sunset and sunrise times based on location
    // return array of moments
    function getSunTimes(now) {
        // Get today's sunrise/sunset times in current time zone.
        var sunrise = null;
        var sunset = null;
        var blueAm = null;
        var bluePm = null;
        var goldenAm = null;
        var goldenPm = null;
        
        var dawn = null;
        var dusk = null;
        var astroDawn = null;
        var astroDusk = null;

        location = Activity.getActivityInfo().currentLocation;
        if (location) {
            location = Activity.getActivityInfo().currentLocation.toRadians();
            app.setProperty("location", location);
        } else {
            location =  app.getProperty("location");
        }
         if (location != null) {
            sunrise = sc.calculate(now, location, SUNRISE);
            sunset = sc.calculate(now, location, SUNSET);

            blueAm = sc.calculate(now, location, BLUE_HOUR_AM);
            bluePm = sc.calculate(now, location, BLUE_HOUR_PM);

            goldenAm = sc.calculate(now, location, GOLDEN_HOUR_AM);
            goldenPm = sc.calculate(now, location, GOLDEN_HOUR_PM);
            
            astroDawn = sc.calculate(now, location, ASTRO_DAWN);
            astroDusk = sc.calculate(now, location, ASTRO_DUSK);
            
            dawn = sc.calculate(now, location, DAWN);
            dusk = sc.calculate(now, location, DUSK);
        }

        return {
            :sunrise => sunrise,
            :sunset => sunset,
            :blueAm => blueAm,
            :bluePm => bluePm,
            :goldenAm => goldenAm,
            :goldenPm => goldenPm,
            :astroDawn => astroDawn,
            :astroDusk => astroDusk,
            :dawn => dawn,
            :dusk => dusk
        };
    }

    function drawSunsetSunriseLine(xPos, yPos, dc, today) {
        if ((sunriseMoment != null) && (sunsetMoment != null)) {
            var rLocal = halfWidth - 2;
            var pen = 32;
            
            dc.setPenWidth(pen);
            dc.setColor(0x000055, Gfx.COLOR_TRANSPARENT);
            dc.drawArc(halfWidth, halfWidth, rLocal, Gfx.ARC_CLOCKWISE, 0, 360);           

            // ASTRO_DAWN to ASTRO_DUSK
            drawDialLine(
                halfWidth,
                halfWidth,
                rLocal,
                sc.momentToInfo(astroDawn),
                sc.momentToInfo(astroDusk),
                pen,
                0x5500AA,
                dc
            );
            
            // DAWN to DUSK
            drawDialLine(
                halfWidth,
                halfWidth,
                rLocal,
                sc.momentToInfo(dawn),
                sc.momentToInfo(dusk),
                pen,
                0x0000AA,
                dc
            );

            // BLUE & GOLDEN HOUR
            drawDialLine(
                halfWidth,
                halfWidth,
                rLocal,
                sc.momentToInfo(blueAmMoment),
                sc.momentToInfo(bluePmMoment),
                pen,
                0x5555FF,       // blue
                dc
            );

            // NORMAL SUN = GOLDEN COLOR
            drawDialLine(
                halfWidth,
                halfWidth,
                rLocal,
                sc.momentToInfo(sunriseMoment),
                sc.momentToInfo(sunsetMoment),
                pen,
                0xFFAA55,       // orange
                dc
            );

            // GOLDEN = NORMAL COLOR
            drawDialLine(
                halfWidth,
                halfWidth,
                rLocal,
                sc.momentToInfo(goldenAmMoment),
                sc.momentToInfo(goldenPmMoment),
                pen,
                themeColor,
                dc
            );
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
            if ((sunriseMoment != null) && (sunsetMoment != null)) {        
                var currSunriseMoment = sc.momentToInfo(sunriseMoment);
                var currSunsetMoment = sc.momentToInfo(sunsetMoment);
                
                // Convert to same format as sunTimes, for easier comparison. Add a minute, so that e.g. if sun rises at
                // 07:38:17, then 07:38 is already consided daytime (seconds not shown to user).
                now = now.add(new Time.Duration(60));

                // Before sunrise today: today's sunrise is next.
                /* if (sunriseMoment.compare(now) > 0) {       // now < sc.momentToInfo(sunrise)
                    // nextSunEvent = sc.momentToInfo(sunriseMoment);
                    // After sunrise today, before sunset today: today's sunset is next.
                } else if (sunsetMoment.compare(now) > 0) { // now < sc.momentToInfo(sunset)
                    // nextSunEvent = sc.momentToInfo(sunsetMoment);
                } else */
                
                if (sunsetMoment.compare(now) <= 0) {    // This is here just for sure if some time condition won't meet the timing
                            // comparation. It menas I will force calculate the next event, the rest will be updated in
                            // the next program iteration -  After sunset today: tomorrow's sunrise (if any) is next.
                    now = now.add(new Time.Duration(Gregorian.SECONDS_PER_DAY));
                    var sunrise = sc.calculate(now, location, SUNRISE);
                    currSunriseMoment = sc.momentToInfo(sunrise);
                }
                
                dc.setColor(frColor, Gfx.COLOR_TRANSPARENT);               
                var value = getFormattedTime(currSunriseMoment.hour, currSunriseMoment.min);
                value = value[:formatted] + value[:amPmFullSmall];
                dc.drawText(halfWidth - 30, halfWidth + 4, fntDataFields, value, Gfx.TEXT_JUSTIFY_RIGHT);
                
                value = getFormattedTime(currSunsetMoment.hour, currSunsetMoment.min); 
                value = value[:formatted] + value[:amPmFullSmall];
                dc.drawText(halfWidth + 30, halfWidth + 4, fntDataFields, value, Gfx.TEXT_JUSTIFY_LEFT);

                dc.drawText(halfWidth - 14, halfWidth + 4, fntIcons, "@", Gfx.TEXT_JUSTIFY_LEFT);   // up
                dc.drawText(halfWidth - 8, halfWidth + 10, fntIcons, "<", Gfx.TEXT_JUSTIFY_LEFT);    // down
            }
        }
    }


    // check if night mode on and if is night
    function checkIfNightMode(sunrise, sunset, now) {
        var isNight = false;
        if (App.getApp().getProperty("NightMode") && (sunrise != null) && (sunset != null)) {
            now = now.add(new Time.Duration(60));   // add 1 minute because I need to switch the colors in the next onUpdate iteration
            if (sunrise.compare(now) > 0) {     // Before sunrise today: today's sunrise is next.
                isNight = true;
            } else if (sunset.compare(now) > 0) {   // After sunrise today, before sunset today: today's sunset is next.
                isNight = false;
            } else {    // This is here just for sure if some time condition won't meet the timing
                        // comparation. It menas I will force calculate the next event, the rest will be updated in
                        // the next program iteration -  After sunset today: tomorrow's sunrise (if any) is next.
                isNight = true;
            }
        }

        return isNight;
    }

    // Will draw bell if is alarm set
    function drawBell(dc) {
        if (settings.alarmCount > 0) {
            var xPos = dc.getWidth() / 2;
            var yPos = ((dc.getHeight() / 6).toNumber() * 4) + 2;
            dc.setColor(frColor, bgColor);
            dc.fillCircle(xPos, yPos, 7);
            // dc.drawText(posX - 10, posY - 18, fntIcons, ":", Gfx.TEXT_JUSTIFY_LEFT);

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
        dc.setPenWidth(1);
        
        // smaller dials first
        var options = {
            :year   => today.year,
            :month  => today.month, // 3.x devices can also use :month => Gregorian.MONTH_MAY
            :day    => today.day,
            :hour   => 11
        };
        
        var dialPointMoment = Gregorian.moment(options);
        for(var hoursCount = 0; hoursCount <= 24; hoursCount+=1) {
            dialPointMoment = dialPointMoment.add(new Time.Duration(Gregorian.SECONDS_PER_HOUR * hoursCount));
            drawSuuntoLikePointer(dc, bgColor, sc.momentToInfo(dialPointMoment), 3, 1.8, true, frColor);    
        }
        
        options = {
            :year   => today.year,
            :month  => today.month, // 3.x devices can also use :month => Gregorian.MONTH_MAY
            :day    => today.day,
            :hour   => 10
        };
        
        dialPointMoment = Gregorian.moment(options);
        drawSuuntoLikePointer(dc, 0xFF0000, sc.momentToInfo(dialPointMoment), 8, 2.5, false, 0); 
        for(var hoursCount = 3; hoursCount <= 24; hoursCount+=3) {
            dialPointMoment = dialPointMoment.add(new Time.Duration(Gregorian.SECONDS_PER_HOUR * hoursCount));
            drawSuuntoLikePointer(dc, frColor, sc.momentToInfo(dialPointMoment), 8, 2.5, false, 0);    
        }
        
        
    }
    

    // draw the by params
    function drawDialNum(dc, coordinatesArray, value, font) {
        var char = null;
        for(var i = 0; i < value.length(); i+=1) {
            char = value.substring(i, i + 1);
            dc.drawText(coordinatesArray[i * 2], coordinatesArray[(i * 2) + 1], font, char, Gfx.TEXT_JUSTIFY_CENTER);
        }
    }


    // Draw steps info
    function drawSteps(posX, posY, dc, position) {
        if (position == 1) {
            posX -= 10;
            posY = (is240dev ? posY - 18 : posY - 16);
        }
        if (position == 2) {
            posX = (is240dev ? (posX - 6) : (posX - 4));
        }
        if (position == 3) {
            posX = (is240dev ? (posX - 40) : (posX - 36));
        }
        if (position == 4) {
            posX = (is240dev ? (posX - 40) : (posX - 41));
        }

        dc.setColor(themeColor, bgColor);
        dc.drawText(posX - 4, posY - 4, fntIcons, "0", Gfx.TEXT_JUSTIFY_LEFT);

        dc.setColor(frColor, Gfx.COLOR_TRANSPARENT);
        var info = ActivityMonitor.getInfo();
        var stepsCount = info.steps;
        if (is240dev && (stepsCount > 999) && ((position == 2) || (position == 3))){
            stepsCount = (info.steps / 1000.0).format("%.1f").toString() + "k";
        }
        //dc.drawText(posX + 22, posY, fntDataFields, stepsCount.toString(), Gfx.TEXT_JUSTIFY_LEFT);
        dc.drawText(posX + 22, posY, fntDataFields, stepsCount.toString(), Gfx.TEXT_JUSTIFY_LEFT);
    }
    
    
    // Draw steps info
    function drawDistance(posX, posY, dc, position) {
        if (position == 1) {
            posX -= 10;
            posY -= (is240dev ? 18 : 16);
        }
        if (position == 2) {
            posX -= (is240dev ? 6 : (is280dev ? 14 : 4));
        }
        if (position == 3) {
            posX -= (is240dev ? 40 : 36);
        }
        if (position == 4) {
            posX -= (is240dev ? 40 : 41);
        }

        dc.setColor(themeColor, bgColor);
        dc.drawText(posX - 4, posY - 4, fntIcons, "7", Gfx.TEXT_JUSTIFY_LEFT);

        dc.setColor(frColor, Gfx.COLOR_TRANSPARENT);
        var info = ActivityMonitor.getInfo();
        var distanceKm = (info.distance / 100000).format("%.2f");
        if (is280dev || (position == 1) || (position == 4))  {
            distanceKm = distanceKm.toString() + "km";
        }
        dc.drawText(posX + 22, posY, fntDataFields, distanceKm.toString(), Gfx.TEXT_JUSTIFY_LEFT);
    }


    // Draw floors info
    function drawFloors(posX, posY, dc, position) {
        if (position == 1) {
            posX += 2;
            posY = (is240dev ? posY - 18 : posY - 16);
        }
            if (position == 3) {
                posX -= 32;
        }
        if (position == 4) {
            posX = (is240dev ? (posX - 25) : (posX - 28));
        }

        dc.setColor(themeColor, Gfx.COLOR_TRANSPARENT);
        dc.drawText(posX - 4, posY - 4, fntIcons, "1", Gfx.TEXT_JUSTIFY_LEFT);

        dc.setColor(frColor, Gfx.COLOR_TRANSPARENT);
        var info = ActivityMonitor.getInfo();
        dc.drawText(posX + 22, posY, fntDataFields, info.floorsClimbed.toString(), Gfx.TEXT_JUSTIFY_LEFT);
    }


    // Draw calories per day
    function drawCalories(posX, posY, dc, position) {
        if (position == 1) {
            posX -= 2;
            posY = (is240dev ? posY - 18 : posY - 16);
        }
            if (position == 3) {
                posX = (is240dev ? (posX - 38) : (posX - 32));
        }
        if (position == 4) {
            posX = (is240dev ? (posX - 32) : (posX - 32));
        }

        dc.setColor(themeColor, Gfx.COLOR_TRANSPARENT);
        dc.drawText(posX - 2, posY - 4, fntIcons, "6", Gfx.TEXT_JUSTIFY_LEFT);

        dc.setColor(frColor, Gfx.COLOR_TRANSPARENT);
        var info = ActivityMonitor.getInfo();
        var caloriesCount = info.calories;
        if (is240dev && (caloriesCount > 999) && ((position == 2) || (position == 3))){
            caloriesCount = (caloriesCount / 1000.0).format("%.1f").toString() + "M";
        }
        dc.drawText(posX + 20, posY, fntDataFields, caloriesCount.toString(), Gfx.TEXT_JUSTIFY_LEFT);
    }


    // Draw BT connection status
    function drawBtConnection(dc) {
        if ((settings has : phoneConnected) && (settings.phoneConnected)) {
            // var radius = 5;
            dc.setColor(Gfx.COLOR_BLUE, Gfx.COLOR_TRANSPARENT);
            dc.drawText(halfWidth - 17, dc.getHeight() - Gfx.getFontHeight(Gfx.FONT_TINY) - 26, fntIcons, "8", Gfx.TEXT_JUSTIFY_LEFT);
            // dc.fillCircle((dc.getWidth() / 2) - 9, dc.getHeight() - Gfx.getFontHeight(Gfx.FONT_TINY) - (radius * 3), radius);
        }
    }


    // Draw notification alarm
    function drawNotification(dc) {
        if ((settings has : notificationCount) && (settings.notificationCount)) {
            // var radius = 5;
            dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT);
            dc.drawText(halfWidth - 1, dc.getHeight() - Gfx.getFontHeight(Gfx.FONT_TINY) - 26, fntIcons, "5", Gfx.TEXT_JUSTIFY_LEFT);
            // dc.fillCircle((dc.getWidth() / 2) + 6, dc.getHeight() - Gfx.getFontHeight(Gfx.FONT_TINY) - (radius * 3), radius);
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
    function drawMoonPhase(xPos, yPos, dc, phase) {
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
                    dc.setPenWidth(radius - 2);
                    dc.setColor(bgColor, frColor);
                    dc.drawArc(xPos + 5, yPos, radius + 5, Gfx.ARC_CLOCKWISE, 270, 90);
                } else if (phase == 5) {
                    dc.setPenWidth(radius - 2);
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
    function drawBattery(xPos, yPos, dc, time, inDays) {
        dc.setPenWidth(1);
        
        var batteryPercent = System.getSystemStats().battery;
        var batteryColor = 0xAAAAAA;
        if (batteryPercent <= 10) {
            batteryColor = Gfx.COLOR_RED;
        } else if (batteryPercent <= 25) {
            batteryColor = Gfx.COLOR_ORANGE;
        } else if (batteryPercent <= 50) {
            batteryColor = themeColor;
        }

        dc.setColor(batteryColor, bgColor);
        var batteryWidth = 28;
        dc.drawRectangle(xPos - 34, yPos + 4, batteryWidth, 8);    // battery
        dc.drawRectangle(xPos + batteryWidth - 34, yPos + 6, 2, 4); // battery top        
               
        var batteryState = ((batteryPercent * batteryWidth) / 100).toNumber();
        dc.fillRectangle(xPos + 1 - 34, yPos + 5, batteryState + 1, 6);

        var batText = batteryPercent.toNumber().toString() + "%";
        dc.setColor(frColor, Gfx.COLOR_TRANSPARENT);
        if (inDays) {
            if (time.min % 10 == 0) {   // battery is calculating each ten minutes (hope in more accurate results)
                getRemainingBattery(time, batteryPercent);
            }
            batText = (app.getProperty("remainingBattery") == null ? "W8" : app.getProperty("remainingBattery").toString());
        }  
       // dc.drawText(xPos + 29 - 34, yPos, fntDataFields, batText, Gfx.TEXT_JUSTIFY_LEFT);  
    }
    
    
    // set variable named remainingBattery to remaining battery in days / hours
    function getRemainingBattery(time, batteryPercent) { 
        if (System.getSystemStats().charging) {         // if charging
            app.setProperty("remainingBattery", "W8");  // will show up "wait" sign
        } else {
            var bat = app.getProperty("batteryTime");
            if (bat == null) {
                bat = [time.now().value(), batteryPercent];
                app.setProperty("batteryTime", bat);
                app.setProperty("remainingBattery", "W8");    // still waiting for battery
            } else {
                var nowValue = time.now().value(); 
                if (bat[1] < batteryPercent) {              // if the battery will increase (charging, F6X Solar or heat)
                    bat = [nowValue, batteryPercent];       // will save the new battery state for next calculating round
                    app.setProperty("batteryTime", bat);
                } else if (bat[1] > batteryPercent) {
                    var remaining = (bat[1] - batteryPercent).toFloat() / (nowValue - bat[0]).toFloat();
                    remaining = remaining * 60 * 60;    // percent consumption per hour
                    remaining = batteryPercent.toFloat() / remaining;
                    if (remaining > 48) { 
                        remaining = Math.round(remaining / 24).toNumber() + "d";
                    } else {
                        remaining = Math.round(remaining).toNumber() + "h";
                    }
                    app.setProperty("remainingBattery", remaining);
                } 
            }
        }
    }
    

    // draw altitude
    function drawAltitude(xPos, yPos, dc, position) {
        if (position == 1) {
            xPos = (is240dev ? xPos + 32 : xPos + 34);
            yPos = (is240dev ? yPos - 18 : yPos - 16);
        }
        if (position == 2) {
            xPos = ((is240dev || is280dev) ? xPos + 42 : xPos + 40);
        }
        if (position == 3) {
            xPos += 8;
        }

        dc.setColor(frColor, Gfx.COLOR_TRANSPARENT);
        var alt = getAltitude();
        if (is280dev || (position == 1) || (position == 4)) {
            alt = alt[:altitude] + alt[:unit];
        } else {
            alt = alt[:altitude];
        }
        dc.drawText(xPos - 18, yPos, fntDataFields, alt, Gfx.TEXT_JUSTIFY_LEFT);
        //dc.drawText(xPos - 18, yPos, fntDataFields, alt, Gfx.TEXT_JUSTIFY_LEFT);

        // coordinates correction text to mountain picture
        xPos = xPos - 46;
        yPos = yPos + 2;
        dc.setPenWidth(2);

        dc.setColor(themeColor, bgColor);
        dc.drawText(xPos, yPos - 6, fntIcons, ";", Gfx.TEXT_JUSTIFY_LEFT);

        /*dc.setColor(themeColor, bgColor);
        dc.drawLine(xPos + 1, yPos + 14, xPos + 5, yPos + 7);
        dc.drawLine(xPos + 5, yPos + 7, xPos + 7, yPos + 10);
        dc.drawLine(xPos + 7, yPos + 10, xPos + 11, yPos + 2);
        dc.drawLine(xPos + 11, yPos + 2, xPos + 20, yPos + 15); */
    }

    // Draw the pressure state and current pressure
    function drawPressure(xPos, yPos, dc, pressure, today, position) {
        if (position == 1) {
            xPos += 30;
            yPos = (is240dev ? yPos - 18 : yPos - 16);
        }
        if (position == 2) {
            xPos += 30;
        }
        if ((position == 3) && is240dev) {
            xPos -= 4;
        }
        var lastPressureLoggingTime = (app.getProperty("lastPressureLoggingTime") == null ? null : app.getProperty("lastPressureLoggingTime").toNumber());
        if ((today.min == 0) && (today.hour != lastPressureLoggingTime)) {   // grap is redrawning only in whole hour
            var baroFigure = 0;
            var pressure3 = app.getProperty("pressure8");
            var pressure2 = app.getProperty("pressure4");
            var pressure1 = app.getProperty("pressure0");
            var PRESSURE_GRAPH_BORDER = App.getApp().getProperty("PressureGraphBorder");    // pressure border to change the graph in hPa
            if (pressure1 != null) {    // always should have at least pressure1 but test it for sure
                pressure1 = pressure1.toNumber();
                pressure2 = (pressure2 == null ? pressure1 : pressure2.toNumber()); // if still dont have historical data, use the current data
                pressure3 = (pressure3 == null ? pressure1 : pressure3.toNumber());
                if ((pressure3 - pressure2).abs() < PRESSURE_GRAPH_BORDER) {    // baroFigure 1 OR 2
                    if ((pressure2 > pressure1) && ((pressure2 - pressure1) >= PRESSURE_GRAPH_BORDER)) {    // baroFigure 1
                        baroFigure = 1;
                    }
                    if ((pressure1 > pressure2) && ((pressure1 - pressure2) >= PRESSURE_GRAPH_BORDER)) {    // baroFigure 2
                        baroFigure = 2;
                    }
                }
                if ((pressure3 > pressure2) && ((pressure3 - pressure2) >= PRESSURE_GRAPH_BORDER)) {    // baroFigure 3, 4, 5
                    baroFigure = 4;
                    if ((pressure2 > pressure1) && ((pressure2 - pressure1) >= PRESSURE_GRAPH_BORDER)) {    // baroFigure 3
                        baroFigure = 3;
                    }
                    if ((pressure1 > pressure2) && ((pressure1 - pressure2) >= PRESSURE_GRAPH_BORDER)) {    // baroFigure 5
                        baroFigure = 5;
                    }
                }
                if ((pressure2 > pressure3) && ((pressure2 - pressure3) >= PRESSURE_GRAPH_BORDER)) {    // baroFigure 6, 7, 8
                    baroFigure = 7;
                    if ((pressure2 > pressure1) && ((pressure2 - pressure1) >= PRESSURE_GRAPH_BORDER)) {    // FIGIRE 6
                        baroFigure = 6;
                    }
                    if ((pressure1 > pressure2) && ((pressure1 - pressure2) >= PRESSURE_GRAPH_BORDER)) {    // baroFigure 8
                        baroFigure = 8;
                    }
                }
            }
            app.setProperty("baroFigure", baroFigure);
        }        
        
        var baroFigure = (app.getProperty("baroFigure") == null ? 0 : app.getProperty("baroFigure").toNumber());
        drawPressureGraph(xPos - 34, yPos + 10, dc, baroFigure);
        dc.setColor(frColor, Gfx.COLOR_TRANSPARENT);
        dc.drawText(xPos - 6, yPos, fntDataFields, pressure.toString(), Gfx.TEXT_JUSTIFY_LEFT);
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
        dc.setPenWidth(3);
        dc.setColor(themeColor, bgColor);
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
            :amPmFullSmall => amPmFull.toLower(),
            :isMilitary => isMilitary,
            :formatted => Lang.format(timeFormat, [hour, min.format("%02d")])
        };
    }

    // Return one of 8 moon phase by date
    // Trying to cache for better optimalization, becase calculation is needed once per day (date)
    // 0 => New Moon
    // 1 => Waxing Crescent Moon
    // 2 => Quarter Moon
    // 3 => Waning Gibbous Moon
    // 4 => Full Moon
    // 5 => Waxing Gibbous Moon
    // 6 => Last Quarter Moon
    // 7 => Waning Crescent Moon
    function getMoonPhase(today) {
        if ((moonPhase == null) || ((today.hour == 0) && (today.min == 0))) {
            var year = today.year;
            var month = today.month;
            var day = today.day;
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
            moonPhase = b;
        }

        return moonPhase;
    }

    // Returns altitude info with units
    function getAltitude() {
        // Note that Activity::Info.altitude is supported by CIQ 1.x, but elevation history only on select CIQ 2.x
        // devices.
        var unit = "";
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
        }

        return {
            :altitude => value,
            :unit => unit
        };
    }

    
    // Returns pressure in hPa
    function getPressure() {
        var pressure = null;
        var value = 0;  // because of some watches not have barometric sensor
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

    
    /// Each hour is the pressure saved (durring last 8 hours) for creation a simple graph
    // storing 8 variables but working just with 4 right now (8,4.1)
    function hadnlePressureHistorty(pressureValue) {
        var pressures = ["pressure0", "pressure1", "pressure2", "pressure3", "pressure4", "pressure5", "pressure6", "pressure7", "pressure8"];
        var preindex = -1;
        for(var pressure = pressures.size(); pressure > 1; pressure-=1) {
            preindex = pressure - 2;
            if ((preindex >= 0) && (app.getProperty(pressures[preindex]) != null)) {
                app.setProperty(pressures[pressure - 1], app.getProperty(pressures[preindex]));
            }
        }
        app.setProperty("pressure0", pressureValue);
    }


    // Draw filled pointer like a trinagle to dial by the settings
    function drawPointToDialFilled(dc, color, timeInfo) {
        var angleToNrCorrection = 5.99;
        var daylightProgessWidth = 12; 
        var rLocal = halfWidth - daylightProgessWidth + 6;
        dc.setColor(color, Gfx.COLOR_TRANSPARENT);

        var secondTimeCoef = ((timeInfo.hour + (timeInfo.min.toFloat() / 60) + angleToNrCorrection) * 15);
        // the top  point touching the DaylightProgessWidth
        var angleDeg = (secondTimeCoef * Math.PI) / 180;
        var trianglPointX1 = ((rLocal * Math.cos(angleDeg)) + halfWidth);
        var trianglPointY1 = ((rLocal * Math.sin(angleDeg)) + halfWidth);
        
        var secondTimeTriangleCircle = halfWidth - (daylightProgessWidth + 8);
        // one of the lower point of tringle        
        var trianglePointAngle = secondTimeCoef - 4;
        angleDeg = (trianglePointAngle * Math.PI) / 180;
        var trianglPointX2 = ((secondTimeTriangleCircle * Math.cos(angleDeg)) + halfWidth);
        var trianglPointY2 = ((secondTimeTriangleCircle * Math.sin(angleDeg)) + halfWidth);
        
        // one of the higher point of tringle
        trianglePointAngle = secondTimeCoef + 4;
        angleDeg = (trianglePointAngle * Math.PI) / 180;
        var trianglPointX3 = ((secondTimeTriangleCircle * Math.cos(angleDeg)) + halfWidth);
        var trianglPointY3 = ((secondTimeTriangleCircle * Math.sin(angleDeg)) + halfWidth);
        
        dc.fillPolygon([[trianglPointX1, trianglPointY1], [trianglPointX2, trianglPointY2], [trianglPointX3, trianglPointY3]]); 
    }
    
    // Draw filled pointer like a trinagle to dial by the settings
    /*function drawPointToDialTransparent(dc, color, timeInfo) {
        var angleToNrCorrection = 5.99;
        var daylightProgessWidth = App.getApp().getProperty("DaylightProgessWidth");
        var rLocal = halfWidth - daylightProgessWidth + 2;  // line in day light
        dc.setPenWidth(2);
        dc.setColor(color, Gfx.COLOR_TRANSPARENT);

        var secondTimeCoef = ((timeInfo.hour + (timeInfo.min.toFloat() / 60) + angleToNrCorrection) * 15);
        // the top  point touching the DaylightProgessWidth
        var angleDeg = (secondTimeCoef * Math.PI) / 180;
        var trianglPointX1 = ((rLocal * Math.cos(angleDeg)) + halfWidth);
        var trianglPointY1 = ((rLocal * Math.sin(angleDeg)) + halfWidth);
        
        var secondTimeTriangleCircle = halfWidth - (daylightProgessWidth + App.getApp().getProperty("CurrentTimePointerWidth"));
        // one of the lower point of tringle        
        var trianglePointAngle = secondTimeCoef - 4;
        angleDeg = (trianglePointAngle * Math.PI) / 180;
        var trianglPointX2 = ((secondTimeTriangleCircle * Math.cos(angleDeg)) + halfWidth);
        var trianglPointY2 = ((secondTimeTriangleCircle * Math.sin(angleDeg)) + halfWidth);
        
        // one of the higher point of tringle
        trianglePointAngle = secondTimeCoef + 4;
        angleDeg = (trianglePointAngle * Math.PI) / 180;
        var trianglPointX3 = ((secondTimeTriangleCircle * Math.cos(angleDeg)) + halfWidth);
        var trianglPointY3 = ((secondTimeTriangleCircle * Math.sin(angleDeg)) + halfWidth);
        
        dc.drawLine(trianglPointX1, trianglPointY1, trianglPointX2, trianglPointY2);
        dc.drawLine(trianglPointX2, trianglPointY2, trianglPointX3, trianglPointY3);
        dc.drawLine(trianglPointX3, trianglPointY3, trianglPointX1, trianglPointY1);
    }*/
    
    // Draw pointer like a Suunto pointer to dial by the settings
    function drawSuuntoLikePointer(dc, color, timeInfo, height, width, tiny, tinyColor) {
        var angleToNrCorrection = 5.95;              
        var secondTimeCoef = ((timeInfo.hour + (timeInfo.min.toFloat() / 60)) * 15);
        
        // the top  point touching the DaylightProgessWidth
        var secondTimeTriangleCircle = halfWidth - height;
        secondTimeCoef = ((timeInfo.hour + (timeInfo.min.toFloat() / 60) + angleToNrCorrection) * 15);
        var angleDeg = (secondTimeCoef * Math.PI) / 180;
        var trianglPointX1 = ((secondTimeTriangleCircle * Math.cos(angleDeg)) + halfWidth);
        var trianglPointY1 = ((secondTimeTriangleCircle * Math.sin(angleDeg)) + halfWidth);
        
        // one of the lower point of tringle        
        var trianglePointAngle = secondTimeCoef - width;
        angleDeg = (trianglePointAngle * Math.PI) / 180;
        var trianglPointX2 = ((halfWidth * Math.cos(angleDeg)) + halfWidth);
        var trianglPointY2 = ((halfWidth * Math.sin(angleDeg)) + halfWidth);
        
        // one of the higher point of tringle
        trianglePointAngle = secondTimeCoef + width;
        angleDeg = (trianglePointAngle * Math.PI) / 180;
        var trianglPointX3 = ((halfWidth * Math.cos(angleDeg)) + halfWidth);
        var trianglPointY3 = ((halfWidth * Math.sin(angleDeg)) + halfWidth);
        
        if (tiny) {
            dc.setPenWidth(4);
            dc.setColor(tinyColor, Gfx.COLOR_TRANSPARENT);
            dc.drawLine(trianglPointX1, trianglPointY1, trianglPointX2, trianglPointY2);
            dc.drawLine(trianglPointX1, trianglPointY1, trianglPointX3, trianglPointY3);
        }
        dc.setColor(color, Gfx.COLOR_TRANSPARENT);
        dc.fillPolygon([[trianglPointX1, trianglPointY1], [trianglPointX2, trianglPointY2], [trianglPointX3, trianglPointY3]]); 
    }
}
