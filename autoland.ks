until false {
	if (addons:tr:hasimpact) {
		set vs to ship:verticalspeed.
		set main to -target:position.
		set adj to target:geoposition:position - addons:tr:impactpos:position.
		set d to adj.mag.
		set h to main + (4 * adj).

		lock steering to h.

		clearscreen.
		print "h: " + h.
		print "d: " + d.
		print "vs: " + vs.
		print "alt: " + alt:radar.

		if (
			(vs < -100 and d > 2) or
			(alt:radar < 1000 and vs < -100) or
			(alt:radar < 500 and vs < -50) or
			(alt:radar < 100 and vs < -10) or
			(alt:radar < 10 and vs < -3)
		) {
			//lock throttle to 0.5.
		} else {
			//lock throttle to 0.0.
		}

		if (alt:radar < 100) {
			gear on.
		}
	}
}
