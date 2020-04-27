using Toybox.Math;
using Toybox.Time;
using Toybox.Time.Gregorian;

class UiCalc {

      // Calculate the coordinates for hige indicators numbers (hours) on the edge of the dial
      function calculateDial(size) {
        var linesCoords = {};
        var options = {
            :year   => 2020,
            :month  => 1,
            :day    => 1,
            :hour   => 11
        };
        
        var dialPointMoment = Gregorian.moment(options);
        linesCoords.put(options[:hour], calculateCoordsByTime(momentToInfo(dialPointMoment), size, 8, 2.5)); 
        for(var hoursCount = 3; hoursCount <= 24; hoursCount+=3) {
            if (linesCoords.get(options[:hour] + hoursCount) == null) {
                dialPointMoment = dialPointMoment.add(new Time.Duration(Gregorian.SECONDS_PER_HOUR * hoursCount));
                linesCoords.put(options[:hour] + hoursCount, calculateCoordsByTime(momentToInfo(dialPointMoment), size, 8, 2.5));  
            }
        }
    
        return linesCoords;
    }
    
    // Calculate the coordinates for small indicators numbers (hours) on the edge of the dial
      function calculateDialSmall(size) {
        var linesCoords = {};
        
        // smaller dials first
        var options = {
            :year   => 2020,
            :month  => 1,
            :day    => 1,
            :hour   => 12
        };
        
        var dialPointMoment = Gregorian.moment(options);
        for(var hoursCount = 0; hoursCount <= 24; hoursCount+=1) {
            dialPointMoment = dialPointMoment.add(new Time.Duration(Gregorian.SECONDS_PER_HOUR * hoursCount));
            linesCoords.put(options[:hour] + hoursCount, calculateCoordsByTime(momentToInfo(dialPointMoment), size, 3, 1.8));   
        }
    
        return linesCoords;
    }


    // Hour pointer calculating
    function calculateCoordsByTime(timeInfo, size, height, width) {
        var angleToNrCorrection = 5.95;              
        var secondTimeCoef = ((timeInfo.hour + (timeInfo.min.toFloat() / 60)) * 15);
        var halfWidth = size / 2;
        
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
        
        return [trianglPointX1, trianglPointY1, trianglPointX2, trianglPointY2, trianglPointX3, trianglPointY3]; 
    }
    
    
    function momentToInfo(moment) {
        if (moment == null) {
            return null;
        }

        var tinfo = Time.Gregorian.info(new Time.Moment(moment.value() + 30), Time.FORMAT_SHORT);
        return tinfo;
    }
}