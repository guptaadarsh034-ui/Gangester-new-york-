extends RefCounted
# Procedural visual pass for the 0.3.0 Android graphics milestone.
# Keeps the GL Compatibility renderer and avoids heavyweight post-processing.

static func apply(world: Node3D) -> void:
	_upgrade_environment(world)
	for node in world.get_children():
		if node.name == "Building":
			_upgrade_building(world, node)
		elif node.name == "Carl's Car":
			_upgrade_player_car(world, node)
		elif node.name == "Player":
			_upgrade_player(world)
	_add_street_details(world)

static func _mat(color: Color, roughness: float = 0.72, metallic: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material

static func _mesh_box(parent: Node3D, label: String, pos: Vector3, size: Vector3, color: Color, roughness: float = 0.72, metallic: float = 0.0) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = label
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = _mat(color, roughness, metallic)
	instance.mesh = mesh
	instance.position = pos
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(instance)
	return instance

static func _mesh_cylinder(parent: Node3D, label: String, pos: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = label
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.material = _mat(color, 0.48, 0.12)
	instance.mesh = mesh
	instance.position = pos
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(instance)
	return instance

static func _upgrade_environment(world: Node3D) -> void:
	for child in world.get_children():
		if child is WorldEnvironment:
			var environment: Environment = child.environment
			if environment:
				environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
				environment.tonemap_exposure = 1.08
				environment.tonemap_white = 1.12
				environment.adjustment_enabled = true
				environment.adjustment_brightness = 1.04
				environment.adjustment_contrast = 1.08
				environment.adjustment_saturation = 1.12
				environment.fog_enabled = true
				environment.fog_density = 0.0045
		elif child is DirectionalLight3D:
			child.shadow_enabled = true
			child.shadow_bias = 0.035
			child.directional_shadow_max_distance = 90.0
			child.light_energy = 1.35

static func _upgrade_building(world: Node3D, building: Node3D) -> void:
	var body_mesh: MeshInstance3D
	for child in building.get_children():
		if child is MeshInstance3D and child.mesh is BoxMesh:
			body_mesh = child
			break
	if body_mesh == null:
		return
	var dimensions: Vector3 = (body_mesh.mesh as BoxMesh).size
	var center: Vector3 = building.position
	var half_x := dimensions.x * 0.5
	var half_y := dimensions.y * 0.5
	var half_z := dimensions.z * 0.5
	var stone := Color(0.18, 0.21, 0.25)
	var trim := Color(0.72, 0.67, 0.57)
	# Architectural cornices and vertical facade pilasters break up flat block faces.
	_mesh_box(world, "FacadeCornice", center + Vector3(0, half_y - 0.35, -half_z - 0.12), Vector3(dimensions.x + 0.45, 0.22, 0.28), trim)
	_mesh_box(world, "FacadeBaseTrim", center + Vector3(0, -half_y + 0.35, -half_z - 0.13), Vector3(dimensions.x + 0.2, 0.18, 0.24), stone)
	for side in [-1.0, 1.0]:
		_mesh_box(world, "FacadePilaster", center + Vector3(side * (half_x - 0.38), 0, -half_z - 0.16), Vector3(0.22, maxf(2.0, dimensions.y - 0.8), 0.22), trim.darkened(0.12))
	# Rooftop ventilation equipment adds recognizable city silhouettes.
	var roof_y := center.y + half_y + 0.28
	var ac_color := Color(0.31, 0.35, 0.38)
	_mesh_box(world, "RooftopHVAC", center + Vector3(-half_x * 0.42, roof_y, 0), Vector3(1.7, 0.65, 1.25), ac_color, 0.58, 0.25)
	_mesh_box(world, "HVACGrille", center + Vector3(-half_x * 0.42, roof_y, -0.64), Vector3(1.25, 0.34, 0.035), Color(0.12, 0.15, 0.17), 0.5, 0.35)
	_mesh_box(world, "RoofUtility", center + Vector3(half_x * 0.35, roof_y - 0.08, 0.25), Vector3(1.1, 0.45, 0.9), Color(0.39, 0.34, 0.28))

static func _upgrade_player_car(world: Node3D, car: Node3D) -> void:
	var chrome := Color(0.58, 0.63, 0.68)
	var glass := Color(0.035, 0.10, 0.15)
	var light := Color(1.0, 0.82, 0.48)
	var rear := Color(0.8, 0.035, 0.025)
	_mesh_box(car, "FrontBumper", Vector3(0, 0.43, -2.12), Vector3(2.18, 0.22, 0.16), chrome, 0.32, 0.72)
	_mesh_box(car, "RearBumper", Vector3(0, 0.43, 2.12), Vector3(2.18, 0.22, 0.16), chrome, 0.32, 0.72)
	for side in [-1.0, 1.0]:
		_mesh_box(car, "LEDHeadlamp", Vector3(side * 0.77, 0.82, -2.115), Vector3(0.48, 0.22, 0.045), light, 0.25, 0.25)
		_mesh_box(car, "TailLamp", Vector3(side * 0.78, 0.82, 2.115), Vector3(0.42, 0.25, 0.05), rear, 0.3, 0.1)
		_mesh_box(car, "SideMirror", Vector3(side * 0.98, 1.35, -0.72), Vector3(0.24, 0.18, 0.34), chrome, 0.35, 0.55)
		_mesh_box(car, "WindowTrim", Vector3(side * 0.89, 1.43, -0.15), Vector3(0.045, 0.82, 1.95), chrome, 0.3, 0.6)
	# Hood crease and rear deck details.
	_mesh_box(car, "HoodAccent", Vector3(0, 1.17, -1.42), Vector3(0.055, 0.018, 1.05), chrome, 0.3, 0.65)
	_mesh_box(car, "RearPlate", Vector3(0, 0.77, 2.145), Vector3(0.62, 0.22, 0.025), Color(0.82, 0.84, 0.78), 0.45, 0.1)

static func _upgrade_player(world: Node3D) -> void:
	var player := world.get_node_or_null("Player") as Node3D
	if player == null:
		return
	var jacket := Color(0.055, 0.12, 0.22)
	var leather := Color(0.035, 0.045, 0.06)
	_mesh_box(player, "JacketCollar", Vector3(0, 1.62, -0.02), Vector3(0.52, 0.16, 0.42), jacket)
	_mesh_box(player, "JacketHem", Vector3(0, 0.72, 0), Vector3(0.58, 0.12, 0.42), jacket.darkened(0.22))
	_mesh_box(player, "UtilityBelt", Vector3(0, 0.78, -0.015), Vector3(0.62, 0.09, 0.43), leather, 0.48, 0.25)
	for side in [-1.0, 1.0]:
		_mesh_box(player, "ShoulderSeam", Vector3(side * 0.34, 1.43, 0), Vector3(0.13, 0.2, 0.42), jacket.lightened(0.12))
		_mesh_box(player, "Boot", Vector3(side * 0.18, 0.08, -0.07), Vector3(0.25, 0.18, 0.42), leather, 0.5, 0.05)
	var hair := SphereMesh.new()
	hair.radius = 0.245
	hair.height = 0.18
	var hair_node := MeshInstance3D.new()
	hair_node.name = "Hair"
	hair.material = _mat(Color(0.055, 0.035, 0.025), 0.9)
	hair_node.mesh = hair
	hair_node.position = Vector3(0, 2.12, 0)
	player.add_child(hair_node)

static func _add_street_details(world: Node3D) -> void:
	# Manhole covers, hydrants and protective bollards give the street scale and texture.
	for z in [-34.0, -2.0, 29.0]:
		var cover := _mesh_cylinder(world, "ManholeCover", Vector3(4.8, -0.075, z), 0.62, 0.055, Color(0.19, 0.21, 0.22))
		cover.rotation_degrees.x = 90
		_mesh_cylinder(world, "ManholeInset", Vector3(4.8, -0.04, z), 0.39, 0.025, Color(0.29, 0.31, 0.32))
	for side in [-1.0, 1.0]:
		for z in [-25.0, 7.0, 39.0]:
			var x: float = side * 8.1
			_mesh_cylinder(world, "FireHydrant", Vector3(x, 0.52, z), 0.24, 0.95, Color(0.72, 0.075, 0.035))
			_mesh_cylinder(world, "HydrantCap", Vector3(x, 1.02, z), 0.29, 0.13, Color(0.82, 0.12, 0.055))
			for offset in [-0.7, 0.7]:
				_mesh_cylinder(world, "StreetBollard", Vector3(side * 9.0, 0.55, z + offset), 0.12, 1.0, Color(0.18, 0.2, 0.22))
