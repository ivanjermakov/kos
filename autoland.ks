set timestep to 0.1.

until false {	
	if (addons:tr:hasimpact) {
		set h to alt:radar.
		set vs to ship:verticalspeed.
		set main to -target:position.
		set adj to target:geoposition:position - addons:tr:impactpos:position.
		set dist to adj:mag.
		set st to "idle".
		set maxThrottle to 1.0.
		set aggressiveness to 10.
		set minAggressiveness to 1.5.
		
		if (h > 2000) {
			// ignore slowing down until this low
			set dir to adj.
		} else {
			// closer to the target -> smoother adjustments
		    set heightC to h / 2000.
			set dir to main + ((minAggressiveness + aggressiveness * heightC) * adj).
		}
		set angle to ship:facing:forevector:normalized * dir:normalized.
		set err to 1 - (angle + 1) / 2.

		lock steering to dir.
		lock throttle to 0.0.

		if (
			(h < 10000 and dist > 500) or
			(h < 5000 and dist > 200) or
			(h < 2000 and dist > 100) or
			(h < 1000 and dist > 50) or
			(h < 500 and dist > 20)
		) {
			if (err > 0.1) {
				set st to "error high".
			} else {
				set st to "getting closer to target".
				// apply less throttle when closer to the target
				lock throttle to min(sqrt(dist * 10 / h), maxThrottle).
				wait timestep.
			}
		}
		
		if (
			(h < 2000 and vs < -100) or
			(h < 1000 and vs < -50) or
			(h < 500 and vs < -20) or
			(h < 100 and vs < -10) or
			(h < 20 and vs < -3)
		) {
			set st to "slowing down".
			lock throttle to maxThrottle.
			wait timestep.
		}

		if (h < 100) {
			gear on.
		}
		
		clearscreen.
		print "dir: " + dir.
		print "dist: " + dist.
		print "vs: " + vs.
		print "alt: " + h.
		print "err: " + round(err, 2).
		print " ".
		print "st: " + st.
	}
	if (st = "idle") {
		wait timestep.
	}
}
