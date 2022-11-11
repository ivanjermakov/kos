set timestep to 0.01.
// TODO: calculate based on TWR
set maxThrottle to 0.4.
set errThrottle to 0.05.
set aggressiveness to 8.
set minAggressiveness to 1.5.
set errTolerance to 0.05.
set slowDownCeiling to 1000.

until false {	
	if (addons:tr:hasimpact) {
		// at close target proximity, use distance to target as height
		if alt:radar < 1000 {
			set h to target:position:mag.
		} else {
			set h to alt:radar.
		}
		set vs to ship:verticalspeed.
		set main to -target:position.
		set adj to target:geoposition:position - addons:tr:impactpos:position.
		set dist to adj:mag.
		set st to "idle".
		
		if (h > slowDownCeiling) {
			// ignore slowing down until this low
			set dir to adj.
		} else {
			// closer to the target -> smoother adjustments
		    set heightC to h / slowDownCeiling.
			set dir to main + ((minAggressiveness + aggressiveness * heightC) * adj).
		}
		set angle to ship:facing:forevector:normalized * dir:normalized.
		set err to 1 - (angle + 1) / 2.

		lock steering to dir.

		if (
			(h < 5000 and vs < -200) or
			(h < 1000 and vs < -100) or
			(h < 200 and vs < -20)
		) {
			set st to "full slowing down".	
			set dir to main.
			// TODO: refactor
			set angle to ship:facing:forevector:normalized * dir:normalized.
			set err to 1 - (angle + 1) / 2.
			if (err > errTolerance) {
				set st to st + " [error high]".
				lock throttle to errThrottle.
			} else {
				lock throttle to maxThrottle * 2.
			}
			wait timestep.
		} else if (
			(h < 5000 and vs < -200) or
			(h < 400 and vs < -20) or
			(h < 50 and vs < -10) or
			(h < 20 and vs < -5) or
			(h < 3 and vs < -1)
		) {
			set st to "slowing down".	
			if (err > errTolerance / 2) {
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
			wait timestep.
		} else	if (
			vs < 0 and
			(
				(dist > 2000) or
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
				lock throttle to min(dist * 10 / h, maxThrottle).
			}
			wait timestep.
		} else {
			// reduce movement to keep trajectory
			// set dir to ship:facing:forevector.
		}
		
		if (h < 100) {
			gear on.
		}
		
		clearscreen.
		print "dist: " + dist.
		print "vs: " + vs.
		print "alt: " + h.
		print "err: " + round(err, 2).
		print "steering: " + steering.
		print "throttle: " + throttle.
		print " ".
		print "st: " + st.
	} else {
		sas on.
		break.
	}
	if (st = "idle") {
		lock throttle to 0.0.
		wait timestep.
	}
}
