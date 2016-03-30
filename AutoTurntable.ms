-- autoTurntable.ms
-- Usage:
-- 	Running this script shows a dialog listing options for turntable set up
-- 	In the dialog set the frame range, set the angle offset, pick a renderer.
-- 	Select the geometry you want to render and click create
-- 	Note that the script creates turntable base parents geo to it and moves them to the center of the scene
-- 	The camera placement is based on the bounding box, so that the whole of geo is visible for the whole frame range
-- 	Clicking create in a scene already set up with this script, rebuilds the turntable based on geo under the turntableBase
-- 	If you wish to restart click clear and start with a new selection
-- 
-- made on 3DsMax 2016
-- made by: Rokas Rakauskas

if ((autoTurntableWnd != undefined) and (autoTurntableWnd.isDisplayed)) then (destroyDialog autoTurntableWnd)

rollout autoTurntableWnd "Turntable Setup"
(
	spinner startSpn "Anim Start: " range:[-100000, 100000, 0] type:#integer 
	spinner endSpn "Anim End: " range:[1, 100000, 100] type:#integer 
	spinner fovSpn "Camera Fov: " range:[0.1, 179.9, 45.0]
	spinner vOffsetAngleSpn "Camera Angle Offset" range:[0.0, 90.0, 30.0]
	spinner distanceOffsetSpn "Camera Distance Offset" range:[0.1, 10000.0, 1.0]
	radioButtons rendererRdo "renderer" labels:#("default", "vray") default:1 enabled:False
	button createBtn "Create" width:90 height:20 across:2
	button clearBtn "Clear" width:90 height:20 

	-- define all the names we are gonna use in the rest of the program
	global autoTurntable_baseName = "autoTurntableBase"
	global autoTurntable_cameraName = "autoTurntableCamera"
	global autoTurntable_lightName = "autoTurntableLight"
	global autoTurntable_materialName = "autoTurntableBaseMaterial"
	global autoTurntable_pathName = "autoTurntableCameraPath"

	on autoTurntableWnd open do
	(
		if ((vray != undefined) and (classof Vray == RendererClass ))do
		(
			rendererRdo.enabled = true
		)
	)
	-- end, on autoTurntableWnd open

	function numCmp numA numB min:True = 
	(
	-- returns the smaller number of the two given
	-- set min to False to get the larger number
	-- couldn't find equivalents of min() max() functions in maxScript
		local larger = numB
		local smaller = numA
		local float returnNumber 
		if numA > numB then
		(
			larger = numA
			smaller = numB

		)

		if min then
		(
			returnNumber = smaller

		)
		else
		(
			returnNumber = larger

		)
		-- apparently return statements are slow in maxscript
		returnNumber 
	) 
	-- end of numCmp

	function distanceOffsetForCorner opposite adjacent lengthFov angleOffset vFov = 
	(
	-- triangle A B C, 
	-- A is at origin, B coordinates are [opposite, adjacent]
	-- distance between A and B is lengthFov, precalculated outside the function
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
		local returnNumber= abs( soughtDistance = lengthFov/sin(vFov) * sin(angleB) )
		returnNumber

	)
	-- end of distanceOffsetForCorner

	function modelSetup renderObj turntableBase renderCam = 
	(
	-- groups and moves geometry to the center of the scene

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
		-- end boundingBox loop
		t= [0.5, 0.5, 0] -- interpolation values for the bottom centre
		bottomCentre = [0,0,0]
		for i=1 to 3 do
		(
			bottomCentre[i] = finalMax[i]*t[i] +finalMin[i]*(1-t[i])
		)
		radius = sqrt( (bottomCentre[1]-finalMax[1])^2 + (bottomCentre[2]-finalMax[2])^2 )

		turntableBase.radius1 = 1.49*radius
		turntableBase.radius2 = 1.5*radius
		turntableBase.pos = bottomCentre
		turntableBase.height = radius * 0.1
		-- parent all the render objects to the base to move them easy
		turntableBase.pos = bottomCentre - turntableBase.height
		for obj in renderObj do 
		(
			obj.parent = turntableBase

		)
		-- move everything to the centre of the scene
		turntableBase.pos = [0, 0, 0]

		-- calculate where we want the camera
		local hFov = fovSpn.value
		local r_aspect = (renderHeight as float)/renderWidth
		-- note we are only getting half of the vertical fov as that is all that is used in later operations
		local vFov = atan(tan(hFov/2.0)*r_aspect )
		-- instead of a bounding box we use a bounding cilinder
		-- from top down the turntable is bound by a circle
		-- horizontalFov is tangent to this circle
		camDistance = radius* 1/sin( hFov/2)
		centreHeight = (finalMax[3] - finalMin[3])*0.5
		-- from the side the turntable is bound by a rectangle
		-- same height as the model bounding box, length 2 * radius
		-- search through all the points of this rectangle so that they are all still visible to camera
		local angleOffset = vOffsetAngleSpn.value
		local lengthFov = sqrt( centreHeight^2.0 + radius ^ 2.0)

		soughtDistance = distanceOffsetForCorner centreHeight radius lengthFov angleOffset vFov 
		camDistance = numCmp camDistance soughtDistance min:False

		soughtDistance = distanceOffsetForCorner -centreHeight radius lengthFov angleOffset vFov
		camDistance = numCmp camDistance soughtDistance min:False

		soughtDistance = distanceOffsetForCorner centreHeight -radius lengthFov angleOffset vFov 
		camDistance = numCmp camDistance soughtDistance min:False

		camZPos = sin( angleOffset) * camDistance + centreHeight
		renderCam.rotation = eulerangles (angleOffset-90) 0.0 0.0
		renderCam.fov = hFov
		setTransformLockFlags renderCam #all
		-- set the clipping distances, 1.5 is to take into account the base
		renderCam.clipManually = True
		clippingDistance = (1.0/cos(angleOffset))*lengthFov*1.5
		renderCam.nearClip = camDistance - clippingDistance
		renderCam.farClip = camDistance + clippingDistance
		renderCam.targetDistance = camDistance

		-- animate the camera
		-- apparently animating the camera instead of the base helps with cacheing
		animStart = startSpn.value
		animEnd = endSpn.value
		animationRange = interval animStart animEnd 

		turntablePath = Circle radius:camDistance pos:[0.0, 0.0, camZPos] steps:20 enabled:true name:autoTurntable_pathName
		turntableConstraint = Path_Constraint follow:True constantVel:True
		renderCam.pos.controller = turntableConstraint
		renderCam.pos.controller.path = turntablePath
		setTransformLockFlags turntablePath #all

	)
	-- end of modelSetup

	function clearAll = 
	(
		local autoTurntableBase = getNodeByName autoTurntable_baseName exact:True
		-- select all children in case we want to rebuild
		if autoTurntableBase != undefined then
		(
			if autoTurntableBase.children.count > 0  then 
			(
				
				ClearSelection()
				for child in autoTurntableBase.children do
				(
					selectmore child
					child.parent = undefined
				)
			)
			delete autoTurntableBase
		)
		-- end if, turntable children check

		autoTurntableCamera = getNodeByName autoTurntable_cameraName exact:True
		if autoTurntableCamera != undefined then
		(
			delete autoTurntableCamera
		)
		-- end if, turntable camera check

		autoTurntableLight = getNodeByName autoTurntable_lightName exact:True
		if autoTurntableLight != undefined then
		(
			delete autoTurntableLight
		)
		-- end if, turntable light check

		baseMaterial = getNodeByName autoTurntable_materialName
		if baseMaterial != undefined then
		(
			delete baseMaterial
		)
		-- end if, turntable material check

		turntablePath = getNodeByName autoTurntable_pathName exact:True
		if turntablePath != undefined then
		(
			delete turntablePath
		)
		-- end if, turntable path check
	)
	-- end clearAll

	on clearBtn pressed do 
	(
		clearAll()
	)
	-- end on clearBtn pressed

	on createBtn pressed do
	(
		-- make sure we start from the begining
		clearAll()
		-- create turntable base
		autoTurntable_base = cone smooth:on heightsegs:1 capsegs:1 sides:50 name:autoTurntable_baseName
		-- create turntable camera
		autoTurntable_renderCam = Freecamera name:autoTurntable_cameraName

		-- create lights and assign material to the base
		baseColour = (color 90.0 90.0 90.0 )
		case rendererRdo.state of 
		(
			1: (
				Skylight name:autoTurntable_lightName castShadows:on
				baseMaterial = Standardmaterial name:autoTurntable_materialName diffuse:baseColour
				autoTurntable_base.material = baseMaterial
				)
			2: (
				VRayLight name:autoTurntable_lightName castShadows:on multiplier:0.1
				baseMaterial = vraymtl name:autoTurntable_materialName diffuse:baseColour
				autoTurntable_base.material = baseMaterial
				)
		)

		sel = GetCurrentSelection()
		selGeoOnly = for obj in sel where superClassOf obj == geometryClass collect obj
		-- all the calculations are done in the following function
		modelSetup selGeoOnly autoTurntable_base autoTurntable_renderCam 
		max vpt camera
		
	)
	-- end on createBtn pressed

)

createDialog autoTurntableWnd 250 180
