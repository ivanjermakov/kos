// CONFIGURATION

// sleep at the end of each step
set timestep to 0.1.

// distance from center of mass to the ground when vessel is landed
set comFromGround to 6.0.

// throttle cap
// TODO: calculate based on TWR
set maxThrottle to 1.0.

// min throttle for smooth slowing down
set minThrottle to 0.3.

// throttle use for error corrections
set errThrottle to 0.1.

// aggressiveness value to use over slowDownCeiling
set aggressiveness to 10.0.

// base aggressiveness value
set minAggressiveness to 2.0.

// correct up to set error
set errTolerance to 0.1.

// decrease agressiveness under this altitude
set slowDownCeiling to 1000.

// don't glide under this altitude
set glideCeiling to 500.

// controls gliding angle
set glideAggressiveness to 10.0.

// enable gliding
set enableGliding to true.


// globals
set infinity to 1e10.
set rangeAchieved to false.

until false {	
	if (addons:tr:hasimpact) {
		set vs to ship:verticalspeed.
		set main to -target:position.
		set adj to target:geoposition:position - addons:tr:impactpos:position.
		set dist to adj:mag.
		// at close target proximity, use distance to target as height
		if (alt:radar < 1000 and dist < 100) {
			set h to target:position:mag - comFromGround.
		} else {
			set h to alt:radar.
		}
		set st to "idle".
		
		// TODO: keep lower agr on high dist
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

		set forceSlowDownLimit to getForceSlowDownLimit().
		set slowDownLimit to getSlowDownLimit().
		if (forceSlowDownLimit > vs) {
			set st to "force slowing down".	
			if (err > errTolerance) {
				set st to st + " [error high]".
				lock throttle to (1 / err) + errThrottle.
			} else {
				if (forceSlowDownLimit / vs > 2) {
					// bypass max throttle, emergency
					lock throttle to 1.0.
				} else {
					lock throttle to maxThrottle.
				}
			}
		} else if (slowDownLimit > vs) {
			set st to "slowing down".	
			if (err > errTolerance) {
				set st to st + " [error high]".
				lock throttle to errThrottle.
			} else {
				set throttleK to min(((slowDownLimit - vs) / -slowDownLimit) ^ 1/4, 1.0).
				lock throttle to throttleK * maxThrottle + minThrottle.
			}
		} else	if (vs < 0 and not rangeAchieved) {
			set st to "getting closer to target".
			if (err > errTolerance) {
				set st to st + " [error high]".
				lock throttle to errThrottle.
			} else {
				lock throttle to min(min(dist * 10 / h, 1.0) * maxThrottle, maxThrottle).
			}
		} else {
			lock throttle to 0.0.
			if (enableGliding and h > glideCeiling) {
				set st to "gliding".
				set glide to main - (min(dist / 100, 1.0) * glideAggressiveness * adj).
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
		print "proximityRange:":padright(20) + proximityRange[0] + "-" + proximityRange[1].
		print "rangeAchieved:":padright(20) + rangeAchieved.
		print "forceSlowDownLimit:":padright(20) + forceSlowDownLimit.
		print "slowDownLimit:":padright(20) + slowDownLimit.
		print " ".
		print "vs:":padright(20) + round(vs, 2).
		print "alt:":padright(20) + round(h, 2).
		print "totalAgr:":padright(20) + round(totalAgr, 2).
		print "err:":padright(20) + round(err, 2).
		print "throttle:":padright(20) + round(throttle, 2).
		print " ".
		print "st:":padright(20) + st.
	} else {
		end().
		break.
	}

	wait timestep.
}

function end {
	set throttle to 0.
	sas on.
	wait 1.
	set sasmode to "RADIALOUT".
}

// getProximityRange :: List
// returns list of two scalars: [min proximity, max proximity]
function getProximityRange {
	if (h < 20) {
		return list(2, 5).
	} else if (h < 50) {
		return list(5, 10).
	} else if (h < 100) {
		return list(10, 20).
	} else if (h < 200) {
		return list(10, 50).
	} else if (h < 500) {
		return list(20, 100).
	} else if (h < 1000) {
		return list(20, 200).
	} else if (h < 2000) {
		return list(100, 200).
	} else if (h < 5000) {
		return list(200, 500).
	} else if (h < 20000) {
		return list(500, 2000).
	} else {
		return list(1000, 2000).
	}
}

// getForceSlowDownLimit :: scalar
// returns ceiling vertical speed for current altitude for forced slow down
function getForceSlowDownLimit {
	if (h < 500) { return -100. }
	else if (h < 1000) { return -100. }
	else if (h < 5000) { return -400. }
	else if (h < 50000) { return -1500. }
	else { return -infinity. }
}

// getSlowDownLimit :: scalar
// returns ceiling vertical speed for current altitude for regular slow down
function getSlowDownLimit {
	if (h < 20) { return -5. }
	else if (h < 100) { return -10. }
	else if (h < 400) { return -20. }
	else if (h < 600) { return -50. }
	else { return -infinity. }
}