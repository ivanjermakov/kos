// configuration
set timestep to 0.1.
// TODO: calculate based on TWR
set maxThrottle to 1.0.
set errThrottle to 0.1.
set aggressiveness to 10.0.
set minAggressiveness to 2.0.
set errTolerance to 0.1.
set slowDownCeiling to 2000.
set glideCeiling to 1000.
set enableGliding to true.

// globals
set rangeAchieved to false.

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
		
		set heightK to min(h / slowDownCeiling, 1.0).
		set totalAgr to minAggressiveness + aggressiveness * heightK.
		set dir to main + (totalAgr * adj).
		lock err to 1 - (ship:facing:forevector:normalized * dir:normalized + 1) / 2.
		lock proximityRange to getProximityRange().
		if (rangeAchieved) {
			if (dist > proximityRange[1]) {
				set rangeAchieved to false.
			}
		} else {
			if (dist < proximityRange[0]) {
				set rangeAchieved to true.
			}
		}

		lock steering to dir.

		if (
			(h < 50000 and vs < -1500) or
			(h < 20000 and vs < -600) or
			(h < 10000 and vs < -400) or
			(h < 5000 and vs < -200) or
			(h < 1000 and vs < -100) or
			(h < 100 and vs < -20)
		) {
			set st to "force slowing down".	
			if (err > errTolerance) {
				set st to st + " [error high]".
				lock throttle to (1 / err) + errThrottle.
			} else {
				// bypass max throttle, emergency
				lock throttle to 1.0.
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
				lock throttle to errThrottle.
			} else {
				if (vs > -20) {
				 	lock throttle to max(dist * 10 / h, errThrottle).
				} else {
					lock throttle to maxThrottle.
				}
				lock throttle to maxThrottle.
			}
		} else	if (
			vs < 0 and not rangeAchieved
		) {
			set st to "getting closer to target".
			if (err > errTolerance) {
				set st to st + " [error high]".
				lock throttle to errThrottle.
			} else {
				// apply less throttle when closer to the target
				lock throttle to min(min(dist * 10 / h, 1.0) * maxThrottle, maxThrottle).
			}
		} else {
			lock throttle to 0.0.
			if (enableGliding and h > glideCeiling) {
				set st to "gliding".
				set dir to glide.
			}
		}
		
		if (h < 100) {
			gear on.
		} else {
			gear off.
		}
		
		clearscreen.
		print "dist:":padright(20) + round(dist, 2).
		print "proximityRange":padright(20) + proximityRange[0] + "-" + proximityRange[1].
		print "rangeAchieved":padright(20) + rangeAchieved.
		print " ".
		print "vs:":padright(20) + round(vs, 2).
		print "alt:":padright(20) + round(h, 2).
		print "totalAgr:":padright(20) + round(totalAgr, 2).
		print "err:":padright(20) + round(err, 2).
		print "throttle:":padright(20) + round(throttle, 2).
		print " ".
		print "st:":padright(20) + st.
	} else {
		sas on.
		break.
	}

	wait timestep.
}

// getProximityRange :: List
// returns list of two scalars: [min proximity, max proximity]
function getProximityRange {
	if (h < 10) {
		return list(1, 2).
	} else if (h < 50) {
		return list(2, 10).
	} else if (h < 100) {
		return list(10, 20).
	} else if (h < 200) {
		return list(20, 50).
	} else if (h < 1000) {
		return list(50, 100).
	} else if (h < 2000) {
		return list(100, 200).
	} else if (h < 5000) {
		return list(200, 500).
	} else if (h < 20000) {
		return list(500, 1000).
	} else {
		return list(1000, 2000).
	}
}