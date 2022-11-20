local module = {}

local quartic = import('env/util/cardannoFerarri').solveQuartic

function module.SolveTrajectory(
	
	origin: Vector3,
	projectileSpeed: number,
	targetPos: Vector3,
	targetVelocity: Vector3,
	pickLongest: boolean?,
	gravity: number?
	
	): Vector3?
	
	local g: number = gravity or workspace.Gravity

	local disp: Vector3 = targetPos - origin
	local p, q, r: number = targetVelocity.X, targetVelocity.Y, targetVelocity.Z
	local h, j, k: number = disp.X, disp.Y, disp.Z
	local l: number = -.5 * g 

	local solutions = quartic(
		l*l,
		-2*q*l,
		q*q - 2*j*l - projectileSpeed*projectileSpeed + p*p + r*r,
		2*j*q + 2*h*p + 2*k*r,
		j*j + h*h + k*k
	)
	if solutions then
		local posRoots: {number} = table.create(2)
		for _, v in solutions do --filter out the negative roots
			if v > 0 then
				table.insert(posRoots, v)
			end
		end
		if posRoots[1] then
			local t: number = posRoots[if pickLongest then 2 else 1]
			local d: number = (h + p*t)/t
			local e: number = (j + q*t - l*t*t)/t
			local f: number = (k + r*t)/t
			return origin + Vector3.new(d, e, f)
		end
	end
	return
end

return module
