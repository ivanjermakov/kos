set timestep to 0.01.
// TODO: calculate based on TWR
set maxThrottle to 1.0.
set errThrottle to 0.1.
set aggressiveness to 4.
set minAggressiveness to 1.5.
set errTolerance to 0.1.
set slowDownCeiling to 500.

until false {	
	if (addons:tr:hasimpact) {
		set h to target:position:mag.
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
		lock throttle to 0.0.

		if (
			(h < 5000 and vs < -200) or
			(h < 300 and vs < -20) or
			(h < 50 and vs < -5) or
			(h < 5 and vs < -2)
		) {
			if (err > errTolerance / 2) {
				set st to "error high".
				lock throttle to (1 / err) * errThrottle.
			} else {
				set st to "slowing down".	
				lock throttle to maxThrottle.
			}
			wait timestep.
		} else	if (
			vs < 0 and
			(
				(h < 20000 and dist > 1000) or
				(h < 5000 and dist > 200) or
				(h < 1000 and dist > 50) or
				(h < 200 and dist > 20) or
				(h < 100 and dist > 10)
			)
		) {
			if (err > errTolerance) {
				set st to "error high".
				lock throttle to (1 / err) * errThrottle.
			} else {
				set st to "getting closer to target".
				// apply less throttle when closer to the target
				lock throttle to min(dist * 10 / h, maxThrottle).
			}
			wait timestep.
		} else {
			// reduce movement to keep trajectory
			set dir to ship:facing:forevector.
		}
		
		if (h < 100) {
			gear on.
		}
		
		clearscreen.
		print "dist: " + dist.
		print "vs: " + vs.
		print "alt: " + h.
		print "err: " + round(err, 2).
		print " ".
		print "st: " + st.
	} else {
		sas on.
		break.
	}
	if (st = "idle") {
		wait timestep.
	}
}
