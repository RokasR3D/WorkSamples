-- TurnTable_1_00.ms
-- Rokas Rakauskas

if ((turnTab != undefined) and (turnTab.isDisplayed)) do (destroyDialog turnTab)

rollout turnTab "Turntable Setup"
(
	spinner startSpn "Anim Start: " range:[-100000, 100000, 0] type:#integer 
	spinner endSpn "Anim End: " range:[1, 100000, 100] type:#integer 
	spinner fovSpn "Camera Fov: " range:[0.1, 179.9, 45.0]
	spinner vOffsetAngleSpn "Vertical Offset Angle" range:[0.0, 90.0, 30.0]
	button createB "Create" width:90 height:20 

	function numCmp numA numB min:True = (
	-- returns the smaller number of the two given
	-- set min to False to get the larger number
	-- couldn't find equivalents of min() max() function in maxScript
		local larger = numB
		local smaller = numA
		if numA > numB do
		(
			larger = numA
			smaller = numB
		)

		if min then
		(
			return smaller
		)
		else
		(
			return larger
		)
	) 
	-- end of numCmp

	function distanceOffsetForCorner opposite adjacent lengthFov angleOffset vFov = (
	-- triangle A B C, 
	-- A is at origin, B coordinates are [opposite, adjacent]
	-- angle at C is vFov
	-- returns distance from A to C
		local angleA = abs(atan(opposite/adjacent) - angleOffset)
		local angleB = 360 - angleA - vFov
		-- here we use the law of sines to figure out the distance the camera has to be away from the centre of the model
		-- so that vertical fov touches a corner of the box
		-- sin(a)/a = sin(b)/b
		-- angleB is opposite the distance we are trying to work out
		-- the only know distance is from the centre to the corner - lengthFov , so called because it is opposite the fov angle
		-- sin(fov)/ lengthFov = sin(angleB)/soughtDistance
		-- soughtDistance = lengthFov/sin(fov) * sin(angleB)
		return abs( soughtDistance = lengthFov/sin(vFov) * sin(angleB) )

	)

	function modelSetup renderObj =
	-- groups and moves geometry to the center of the scene
	(
		-- get the complete bounding box
		finalMin = [100000000, 10000000, 10000000]
		finalMax = [-100000000, -10000000, -10000000]
		for obj in renderObj do 
		(
			for i=1 to 3 do
			(
				finalMin[i] = numCmp finalMin[i] obj.min[i]
				finalMax[i] = numCmp finalMax[i] obj.max[i] min:False
			)
		)
		t= [0.5, 0.5, 0] -- interpolation values for the bottom centre
		bottomCentre = [0,0,0]
		for i=1 to 3 do
		(
			bottomCentre[i] = finalMax[i]*t[i] +finalMin[i]*(1-t[i])
		)
		radius = sqrt( (bottomCentre[1]-finalMax[1])^2 + (bottomCentre[2]-finalMax[2])^2 )
		turntableBase = cone smooth:on radius1:(1.5*radius) radius2:(radius*1.51) pos:bottomCentre height:(radius*-0.1)

		-- parent all the render objects to the base to move them easy
		for obj in renderObj do 
		(
			obj.parent = turntableBase
		)
		turntableBase.pos = [0, 0, 0]

		-- animate the turntable
		animStart = startSpn.value
		animEnd = endSpn.value
		animationRange = interval animStart animEnd 

		maxops.setDefaultTangentType #linear #linear

		with animate on 
		(
			at time animStart turntableBase.rotation.controller.z_rotation = 0
			at time animEnd turntableBase.rotation.controller.z_rotation = 360
		)

		-- calculate where we want the camera
		local hFov = fovSpn.value
		local r_aspect = (renderHeight as float)/renderWidth
		-- note we are only getting half of the vertical fov as that is all that is used in later operations
		local vFov = atan(tan(hFov/2.0)*r_aspect )
		-- instead of a bounding box we use a bounding cilinder
		-- from top down the turntable is bound by a circle
		-- horizontal fov is tangent to this circle
		camDistance = radius* 1/sin( hFov/2)
		centreHeight = (finalMax[3] - finalMin[3])*0.5
		-- from the side the turntable is bound by a rectangle
		-- same height as the model bounding box, length 2 * radius
		-- search through all the points of this rectangle so that they are all still visible to camera

		local angleOffset = vOffsetAngleSpn.value
		local lengthFov = sqrt( centreHeight^2.0 + radius ^ 2.0)
		soughtDistance = 0 
		soughtDistance = distanceOffsetForCorner centreHeight radius lengthFov angleOffset vFov
		camDistance = numCmp camDistance soughtDistance min:False

		soughtDistance = distanceOffsetForCorner -centreHeight radius lengthFov angleOffset vFov
		camDistance = numCmp camDistance soughtDistance min:False

		soughtDistance = distanceOffsetForCorner centreHeight -radius lengthFov angleOffset vFov
		camDistance = numCmp camDistance soughtDistance min:False

		-- renderCam =Targetcamera pos:[camXOffset, 0.0, camZOffset] target:(targetObject pos:[0.0, 0.0, camZOffset]) fov:fov
		camXPos = cos( angleOffset) * camDistance
		camZPos = sin( angleOffset) * camDistance + centreHeight
		renderCam = Targetcamera target:(targetObject pos:[0.0, 0.0, centreHeight]) fov:hFov pos:[ camXPos, 0.0, camZPos ]

	)

	on createB pressed do 
	(
		sel = GetCurrentSelection()
		selGeoOnly = for obj in sel where superClassOf obj == geometryClass collect obj
		modelSetup( selGeoOnly )
		
		--fov = fovSpn.value
		--Targetcamera pos:[50, 0 , 0] target:(targetObject pos:[0, 0, 0] ) fov:fov
	)
)

createDialog turnTab 200 150
