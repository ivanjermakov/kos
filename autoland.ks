set timestep to 0.1.
// TODO: calculate based on TWR
set maxThrottle to 0.3.
set errThrottle to 0.1.
set aggressiveness to 10.0.
set minAggressiveness to 2.0.
set errTolerance to 0.01.
set slowDownCeiling to 2000.
set enableGliding to false.

until false {	
	if (addons:tr:hasimpact) {
		set vs to ship:verticalspeed.
		set main to -target:position.
		set adj to target:geoposition:position - addons:tr:impactpos:position.
		set dist to adj:mag.
		// at close target proximity, use distance to target as height
		if (alt:radar < 1000 and dist < 100) {
			set h to target:position:mag.
		} else {
			set h to alt:radar.
		}
		set glide to main - (min(dist / 100, 1.0) * aggressiveness * adj).
		set st to "idle".
		
		set heightK to min(h / slowDownCeiling, 2.0).
		set totalAgr to minAggressiveness + aggressiveness * heightK.
		set dir to main + (totalAgr * adj).
		lock err to 1 - (ship:facing:forevector:normalized * dir:normalized + 1) / 2.

		lock steering to dir.

		if (
			(h < 5000 and vs < -200) or
			(h < 1000 and vs < -100) or
			(h < 100 and vs < -20)
		) {
			set st to "full slowing down".	
			set dir to main.
			if (err > errTolerance) {
				set st to st + " [error high]".
				lock throttle to errThrottle.
			} else {
				lock throttle to maxThrottle.
			}
		} else if (
			(h < 5000 and vs < -200) or
			(h < 400 and vs < -20) or
			(h < 50 and vs < -10) or
			(h < 20 and vs < -5) or
			(h < 3 and vs < -1)
		) {
			set st to "slowing down".	
			if (err > errTolerance) {
				set st to st + " [error high]".
				lock throttle to (1 / err) * errThrottle.
			} else {
				if (vs > -20) {
				 	lock throttle to max(dist * 10 / h, errThrottle).
				} else {
					lock throttle to maxThrottle.
				}
				lock throttle to maxThrottle.
			}
		} else	if (
			vs < 0 and
			(
				(dist > 5000) or
				(h < 20000 and dist > 1000) or
				(h < 5000 and dist > 200) or
				(h < 2000 and dist > 100) or
				(h < 1000 and dist > 50) or
				(h < 200 and dist > 20) or
				(h < 100 and dist > 10) or
				(h < 50 and dist > 5) or
				(h < 10 and dist > 2)
			)
		) {
			set st to "getting closer to target".
			if (err > errTolerance) {
				set st to st + " [error high]".
				lock throttle to (1 / err) * errThrottle.
			} else {
				// apply less throttle when closer to the target
				lock throttle to min((dist * 10 / h) * maxThrottle, maxThrottle).
			}
		} else {
			lock throttle to 0.0.
			if (enableGliding and h > slowDownCeiling) {
				set st to "gliding".
				set dir to glide.
			}
		}
		
		if (h < 100) {
			gear on.
		}
		
		clearscreen.
		print "dist:":padright(10) + round(dist, 2).
		print "vs:":padright(10) + round(vs, 2).
		print "alt:":padright(10) + round(h, 2).
		print "totalAgr:":padright(10) + round(totalAgr, 2).
		print "err:":padright(10) + round(err, 2).
		print "throttle:":padright(10) + round(throttle, 2).
		print " ".
		print "st:":padright(10) + st.
	} else {
		sas on.
		break.
	}

	wait timestep.
}
