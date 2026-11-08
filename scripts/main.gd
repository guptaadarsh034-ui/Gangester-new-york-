extends Node3D
const PLAYER = preload("res://scripts/player.gd")
const ENEMY = preload("res://scripts/enemy.gd")
var player: CharacterBody3D
var guards: Array[Node3D] = []
var parcel: Node3D
var stage := 0
var title_label: Label
var objective_label: Label
var health_label: Label
var phone_panel: PanelContainer
var phone_gps_label: Label
var phone_status_label: Label
var drivable_car: CharacterBody3D
var in_vehicle := false
var vehicle_speed := 0.0
var vehicle_hint: Label

func _ready() -> void:
	_input_setup()
	_city()
	_make_player()
	_mission()
	_hud()
	_refresh()

func _process(_delta: float) -> void:
	if not is_instance_valid(player): return
	_update_vehicle(get_process_delta_time())
	health_label.text = "♥  %d" % player.health
	if is_instance_valid(phone_gps_label): phone_gps_label.text = objective_label.text
	if player.health <= 0 and stage < 3:
		stage = 4
		_refresh()
	if stage == 0 and player.global_position.distance_to(Vector3(0,0,-16)) < 5:
		stage = 1
		_refresh()
	if stage == 1 and _guard_count() == 0:
		stage = 2
		_refresh()
	if stage == 2 and player.global_position.distance_to(Vector3(0,0,-17)) < 3 and Input.is_action_just_pressed("interact"):
		stage = 3
		if is_instance_valid(parcel): parcel.queue_free()
		_refresh()
	if stage == 3 and player.global_position.distance_to(Vector3(0,0,22)) < 5:
		stage = 5
		_refresh()

func _input_setup() -> void:
	var map := {"move_left":[KEY_A,KEY_LEFT],"move_right":[KEY_D,KEY_RIGHT],"move_forward":[KEY_W,KEY_UP],"move_back":[KEY_S,KEY_DOWN],"interact":[KEY_E,KEY_SPACE]}
	for action in map:
		InputMap.add_action(action)
		for code in map[action]:
			var e := InputEventKey.new()
			e.physical_keycode = code
			InputMap.action_add_event(action,e)

func _mat(color: Color, roughness := 0.85, metallic := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	m.metallic = metallic
	return m

func _city() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.12,0.25,0.48)
	sky_mat.sky_horizon_color = Color(0.78,0.58,0.42)
	sky_mat.ground_bottom_color = Color(0.12,0.14,0.18)
	sky_mat.ground_horizon_color = Color(0.48,0.42,0.38)
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62,0.68,0.82)
	env.ambient_light_energy = 0.85
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color(0.48,0.52,0.62)
	env.fog_density = 0.006
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48,-32,0)
	sun.light_color = Color(1.0,0.82,0.66)
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	add_child(sun)
	_box("Road",Vector3(0,-0.35,0),Vector3(18,0.5,110),Color(0.075,0.09,0.12),true)
	for side in [-1,1]:
		_box("Sidewalk",Vector3(side*11,-0.1,0),Vector3(4,0.4,110),Color(0.55,0.53,0.48),true)
		_box("Curb",Vector3(side*8.9,0.02,0),Vector3(0.28,0.28,110),Color(0.72,0.69,0.6),true)
	for z in range(-50,55,10):
		_box("LaneDash",Vector3(0,-0.075,z),Vector3(0.18,0.04,4.5),Color(0.96,0.78,0.38),false)
		_box("CrosswalkA",Vector3(-7.8,-0.065,z),Vector3(1.2,0.04,0.65),Color(0.82,0.83,0.8),false)
		_box("CrosswalkB",Vector3(7.8,-0.065,z),Vector3(1.2,0.04,0.65),Color(0.82,0.83,0.8),false)
	for side in [-1,1]:
		for i in range(6):
			var z := -43.0 + i * 17.0
			var h := 13.0 + float((i*7)%9)
			_building(Vector3(side*23,h*0.5-0.1,z),Vector3(12,h,14),i+int(side*2))
		for z in range(-38,45,20):
			_streetlight(side,z)
			_tree(Vector3(side*13.2,0,z+7))
	# Landmark buildings and skyline silhouettes
	_building(Vector3(-39,11, -8),Vector3(15,22,20),8)
	_building(Vector3(39,15, 13),Vector3(16,30,18),11)
	_box("Warehouse",Vector3(0,3.5,-22),Vector3(19,7,13),Color(0.36,0.39,0.43),false)
	_box("WarehouseRoof",Vector3(0,7.15,-22),Vector3(19.6,0.35,13.6),Color(0.16,0.19,0.23),false)
	_box("WarehouseDoor",Vector3(0,2.2,-15.35),Vector3(5,4.4,0.2),Color(0.08,0.1,0.13),false)
	_box("WarehouseSign",Vector3(0,5.4,-15.28),Vector3(7,0.85,0.18),Color(0.9,0.42,0.12),false)
	_box("Safehouse",Vector3(0,2.5,29),Vector3(15,5,9),Color(0.48,0.28,0.19),false)
	_box("SafehouseRoof",Vector3(0,5.1,29),Vector3(15.6,0.35,9.6),Color(0.16,0.17,0.2),false)
	_vehicle_prop(Vector3(-6,0.15,7),Color(0.12,0.35,0.72))
	_create_drivable_car(Vector3(-6,0.1,7))
	_vehicle_prop(Vector3(6,0.15,-5),Color(0.72,0.19,0.12))
	_vehicle_prop(Vector3(-6,0.15,-31),Color(0.82,0.68,0.18))
	_build_neighborhood_extension()


func _build_neighborhood_extension() -> void:
	# Expand the starter street into a compact Manhattan-style neighbourhood grid.
	for z in [-43.0, 38.0]:
		_box("CrossStreet", Vector3(0,-0.31,z), Vector3(150,0.48,15), Color(0.075,0.09,0.12), true)
		for x in range(-68, 70, 12):
			_box("CrossStreetDash", Vector3(float(x),-0.055,z), Vector3(5,0.035,0.18), Color(0.94,0.78,0.43), false)
		for x in [-7.0, -5.0, -3.0, -1.0, 1.0, 3.0, 5.0, 7.0]:
			_box("CrosswalkStripe", Vector3(x,-0.045,z-7.1), Vector3(1.1,0.035,0.55), Color(0.84,0.86,0.85), false)
	# Extra blocks, with varied heights and colours, create a deeper skyline.
	for side in [-1,1]:
		for row in range(3):
			var x: float = float(side) * (48.0 + float(row % 2) * 15.0)
			var z: float = -31.0 + float(row) * 34.0
			var height: float = 17.0 + float((row * 11 + side * 7) % 19)
			_building(Vector3(x,height*0.5-0.1,z), Vector3(13.0,height,17.0), row + side * 5 + 17)
			if row != 1:
				_tree(Vector3(float(side)*31.0,0,z+11.0))
	# A few recognisable city details at street level.
	for side in [-1,1]:
		for z in [-30.0, 12.0]:
			_box("ShopAwning", Vector3(float(side)*17.2,3.0,z), Vector3(0.35,0.45,5.0), Color(0.78,0.22,0.12), false)
			_box("ShopSign", Vector3(float(side)*17.0,4.0,z), Vector3(0.22,0.55,4.2), Color(0.94,0.72,0.28), false)
	# Distant silhouettes make the playable district feel surrounded by a city.
	for i in range(12):
		var side: float = -1.0 if i % 2 == 0 else 1.0
		var z: float = -55.0 + float(i / 2) * 19.0
		var h: float = 28.0 + float((i * 13) % 34)
		_building(Vector3(side*82.0,h*0.5-0.1,z), Vector3(16.0,h,18.0), i+24)

func _building(pos: Vector3, size: Vector3, variant: int) -> void:
	var palettes := [Color(0.35,0.42,0.52),Color(0.55,0.36,0.27),Color(0.42,0.48,0.43),Color(0.48,0.42,0.56),Color(0.65,0.52,0.35)]
	var color: Color = palettes[abs(variant)%palettes.size()]
	_box("Building",pos,size,color,true)
	_box("RoofTrim",pos+Vector3(0,size.y*0.5+0.16,0),Vector3(size.x+0.5,0.32,size.z+0.5),color.darkened(0.28),false)
	var floors := int(size.y/3.2)
	for floor in range(floors):
		for side in [-1,1]:
			for col in range(2):
				var wx: float = pos.x + float(side)*(size.x*0.5+0.035)
				var wz: float = pos.z + (float(col)-0.5)*size.z*0.48
				_box("LitWindow",Vector3(wx,pos.y-size.y*0.5+1.8+floor*3.0,wz),Vector3(0.07,1.35,1.35),Color(0.22,0.58,0.76) if (floor+col+variant)%3==0 else Color(0.13,0.2,0.28),false)
		for col in range(2):
			var wz: float = pos.z-size.z*0.5+(float(col)+0.5)*size.z*0.5
			_box("FrontWindow",Vector3(pos.x,pos.y-size.y*0.5+1.8+floor*3.0,wz),Vector3(1.5,1.35,0.07),Color(0.85,0.66,0.38) if (floor+col)%4==0 else Color(0.13,0.22,0.3),false)
	_box("Storefront",Vector3(pos.x,pos.y-size.y*0.5+1.0,pos.z-size.z*0.5-0.05),Vector3(size.x*0.55,1.7,0.12),Color(0.12,0.17,0.22),false)

func _streetlight(side: int, z: float) -> void:
	_box("LampPost",Vector3(side*9.5,3.0,z),Vector3(0.16,6,0.16),Color(0.12,0.14,0.16),false)
	_box("LampArm",Vector3(side*9.0,5.8,z),Vector3(1.1,0.13,0.13),Color(0.12,0.14,0.16),false)
	var lamp := _box("Lamp",Vector3(side*8.5,5.72,z),Vector3(0.65,0.18,0.5),Color(1.0,0.82,0.48),false)
	var light := OmniLight3D.new()
	light.position = Vector3(side*8.5,5.3,z)
	light.light_color = Color(1.0,0.72,0.38)
	light.light_energy = 0.7
	light.omni_range = 7
	add_child(light)

func _tree(pos: Vector3) -> void:
	_box("TreeTrunk",pos+Vector3(0,1.1,0),Vector3(0.55,2.2,0.55),Color(0.3,0.19,0.11),false)
	var crown := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 1.65
	mesh.height = 3.0
	crown.mesh = mesh
	crown.position = pos+Vector3(0,3.1,0)
	crown.material_override = _mat(Color(0.12,0.38,0.2))
	add_child(crown)

func _vehicle_prop(pos: Vector3, color: Color) -> void:
	_box("CarBody",pos+Vector3(0,0.75,0),Vector3(2.25,0.8,4.2),color,false)
	_box("CarCabin",pos+Vector3(0,1.42,-0.15),Vector3(1.75,0.8,2.0),Color(0.12,0.19,0.25),false)
	for x in [-1,1]:
		for z in [-1.35,1.35]:
			var wheel := MeshInstance3D.new()
			var cylinder := CylinderMesh.new()
			cylinder.top_radius = 0.42
			cylinder.bottom_radius = 0.42
			cylinder.height = 0.28
			wheel.mesh = cylinder
			wheel.rotation_degrees.z = 90
			wheel.position = pos+Vector3(x*1.12,0.48,z)
			wheel.material_override = _mat(Color(0.035,0.04,0.05))
			add_child(wheel)

func _box(n: String,p: Vector3,s: Vector3,c: Color,solid: bool) -> Node3D:
	var root: Node3D = StaticBody3D.new() if solid else MeshInstance3D.new()
	root.name=n
	root.position=p
	var mesh := BoxMesh.new()
	mesh.size=s
	mesh.material = _mat(c)
	if solid:
		var visual := MeshInstance3D.new()
		visual.mesh=mesh
		root.add_child(visual)
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size=s
		collision.shape=shape
		root.add_child(collision)
	else:
		(root as MeshInstance3D).mesh=mesh
		(root as MeshInstance3D).material_override=_mat(c)
	add_child(root)
	return root

func _make_player() -> void:
	player=CharacterBody3D.new()
	player.name="Player"
	player.set_script(PLAYER)
	_character_visual(player,Color(0.08,0.19,0.34),0.38)
	player.position=Vector3(0,-0.1,22)
	add_child(player)

func _character_visual(body: CharacterBody3D,color: Color,radius: float) -> void:
	var torso := MeshInstance3D.new()
	var torso_mesh := CapsuleMesh.new()
	torso_mesh.radius = radius*0.9
	torso_mesh.height = 1.05
	torso_mesh.material = _mat(color)
	torso.mesh = torso_mesh
	torso.position = Vector3(0,1.12,0)
	body.add_child(torso)
	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.27
	head_mesh.height = 0.54
	head_mesh.material = _mat(Color(0.72,0.49,0.34))
	head.mesh = head_mesh
	head.position = Vector3(0,1.9,0)
	body.add_child(head)
	for side in [-1,1]:
		var arm := MeshInstance3D.new()
		var limb := CapsuleMesh.new()
		limb.radius = 0.13
		limb.height = 0.85
		limb.material = _mat(color.darkened(0.2))
		arm.mesh = limb
		arm.position = Vector3(side*0.42,1.15,0)
		arm.rotation.z = deg_to_rad(side*10)
		body.add_child(arm)
		var leg := MeshInstance3D.new()
		var leg_mesh := CapsuleMesh.new()
		leg_mesh.radius = 0.16
		leg_mesh.height = 0.8
		leg_mesh.material = _mat(Color(0.07,0.08,0.1))
		leg.mesh = leg_mesh
		leg.position = Vector3(side*0.18,0.42,0)
		body.add_child(leg)
	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius=radius
	shape.height=1.8
	col.shape=shape
	col.position.y=0.9
	body.add_child(col)

func _mission() -> void:
	for i in range(3):
		var guard := CharacterBody3D.new()
		guard.set_script(ENEMY)
		guard.target=player
		guard.position=Vector3(-4+i*4,-0.1,-17+(i%2)*3)
		_character_visual(guard,Color(0.48,0.09,0.08),0.4)
		add_child(guard)
		guards.append(guard)
	parcel=_box("StolenPackage",Vector3(0,0.65,-17),Vector3(1,1.1,1),Color(0.75,0.48,0.13),false)
	_box("ExtractionZone",Vector3(0,0.02,22),Vector3(5,0.06,5),Color(0.1,0.65,0.25),false)

func _hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var ui := Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(ui)
	title_label=_label(ui,"GANGSTER: NEW YORK  •  CHAPTER 01",Vector2(28,18),24)
	objective_label=_label(ui,"",Vector2(28,55),19)
	health_label=_label(ui,"♥  100",Vector2(28,88),20)
	_button(ui,"◀",Vector2(28,-105),Vector2(78,68),false,"move_left")
	_button(ui,"▶",Vector2(194,-105),Vector2(78,68),false,"move_right")
	_button(ui,"▲",Vector2(111,-174),Vector2(78,68),false,"move_forward")
	_button(ui,"▼",Vector2(111,-91),Vector2(78,68),false,"move_back")
	var fire := _button(ui,"FIRE",Vector2(-135,-108),Vector2(112,78),true,"")
	fire.pressed.connect(func(): player.shoot())
	var act := _button(ui,"ACTION",Vector2(-135,-198),Vector2(112,78),true,"")
	act.pressed.connect(_interact)
	var hint := _label(ui,"WASD / TOUCH TO MOVE     •     FIRE TO SHOOT",Vector2(-330,-28),13)
	vehicle_hint = _label(ui,"Walk up to the blue car and tap ACTION to drive",Vector2(28,122),15)
	hint.anchor_left = 1.0
	hint.anchor_right = 1.0
	_phone_ui(ui)

func _label(parent: Control,txt: String,pos: Vector2,size: int) -> Label:
	var l := Label.new()
	l.text=txt
	l.position=pos
	l.add_theme_font_size_override("font_size",size)
	l.add_theme_color_override("font_color",Color(1,0.96,0.86))
	l.add_theme_color_override("font_shadow_color",Color(0,0,0,0.9))
	l.add_theme_constant_override("shadow_offset_x",2)
	l.add_theme_constant_override("shadow_offset_y",2)
	parent.add_child(l)
	return l

func _button(parent: Control,txt: String,pos: Vector2,size: Vector2,right: bool,action: String) -> Button:
	var b := Button.new()
	b.text=txt
	b.position=pos
	b.size=size
	b.anchor_left=1.0 if right else 0.0
	b.anchor_right=b.anchor_left
	b.anchor_top=1.0
	b.anchor_bottom=1.0
	b.add_theme_font_size_override("font_size",20)
	b.add_theme_color_override("font_color",Color.WHITE)
	b.add_theme_stylebox_override("normal",_button_style(Color(0.08,0.12,0.18,0.88)))
	b.add_theme_stylebox_override("pressed",_button_style(Color(0.65,0.19,0.09,0.95)))
	parent.add_child(b)
	if action != "":
		b.button_down.connect(func(): Input.action_press(action))
		b.button_up.connect(func(): Input.action_release(action))
	return b

func _button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.95,0.67,0.28,0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	return style

func _interact() -> void:
	Input.action_press("interact")
	await get_tree().create_timer(0.15).timeout
	Input.action_release("interact")


func _create_drivable_car(pos: Vector3) -> void:
	drivable_car = CharacterBody3D.new()
	drivable_car.name = "Carl's Car"
	drivable_car.position = pos
	var body_mesh := MeshInstance3D.new()
	var body_shape := BoxMesh.new()
	body_shape.size = Vector3(2.25, 0.8, 4.2)
	body_shape.material = _mat(Color(0.12,0.35,0.72),0.42,0.25)
	body_mesh.mesh = body_shape
	body_mesh.position.y = 0.75
	drivable_car.add_child(body_mesh)
	var cabin := MeshInstance3D.new()
	var cabin_shape := BoxMesh.new()
	cabin_shape.size = Vector3(1.72,0.8,2.0)
	cabin_shape.material = _mat(Color(0.08,0.16,0.22),0.25,0.15)
	cabin.mesh = cabin_shape
	cabin.position = Vector3(0,1.42,-0.15)
	drivable_car.add_child(cabin)
	for x in [-1.0,1.0]:
		for z in [-1.35,1.35]:
			var wheel := MeshInstance3D.new()
			var wheel_mesh := CylinderMesh.new()
			wheel_mesh.top_radius = 0.42
			wheel_mesh.bottom_radius = 0.42
			wheel_mesh.height = 0.28
			wheel_mesh.material = _mat(Color(0.025,0.03,0.04))
			wheel.mesh = wheel_mesh
			wheel.rotation_degrees.z = 90
			wheel.position = Vector3(x*1.12,0.48,z)
			drivable_car.add_child(wheel)
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.2,1.6,4.1)
	collision.shape = box
	collision.position.y = 0.8
	drivable_car.add_child(collision)
	add_child(drivable_car)

func _update_vehicle(delta: float) -> void:
	if not is_instance_valid(drivable_car) or not is_instance_valid(player): return
	if not in_vehicle:
		if player.global_position.distance_to(drivable_car.global_position) < 3.4 and Input.is_action_just_pressed("interact"):
			in_vehicle = true
			player.in_vehicle = true
			player.global_position = drivable_car.global_position
			vehicle_speed = 0.0
			vehicle_hint.text = "DRIVING: WASD / TOUCH to steer • ACTION to exit"
		return
	if Input.is_action_just_pressed("interact"):
		in_vehicle = false
		player.in_vehicle = false
		player.global_position = drivable_car.global_position + drivable_car.global_transform.basis.x * 2.2
		vehicle_hint.text = "Walk up to the blue car and tap ACTION to drive"
		return
	var throttle := Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	var steering := Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	vehicle_speed = move_toward(vehicle_speed, throttle * 13.0, 10.0 * delta)
	if absf(vehicle_speed) > 0.25:
		drivable_car.rotation.y -= steering * 1.65 * delta * signf(vehicle_speed)
	var forward := -drivable_car.global_transform.basis.z
	drivable_car.velocity.x = forward.x * vehicle_speed
	drivable_car.velocity.z = forward.z * vehicle_speed
	drivable_car.velocity.y = -22.0 * delta if not drivable_car.is_on_floor() else 0.0
	drivable_car.move_and_slide()
	player.global_position = drivable_car.global_position

func _guard_count() -> int:
	var count := 0
	for g in guards:
		if is_instance_valid(g): count += 1
	return count

func _refresh() -> void:
	match stage:
		0: objective_label.text="OBJECTIVE: Reach the warehouse"
		1: objective_label.text="OBJECTIVE: Defeat guards (%d remaining)" % _guard_count()
		2: objective_label.text="OBJECTIVE: Collect the package — tap ACTION"
		3: objective_label.text="OBJECTIVE: Escape to the safehouse"
		4: objective_label.text="MISSION FAILED — Restart the game"
		5: objective_label.text="MISSION COMPLETE! Package secured."


func _phone_ui(parent: Control) -> void:
	var phone_button := Button.new()
	phone_button.text = "📱 PHONE"
	phone_button.position = Vector2(-158, 22)
	phone_button.size = Vector2(138, 58)
	phone_button.anchor_left = 1.0
	phone_button.anchor_right = 1.0
	phone_button.add_theme_font_size_override("font_size", 18)
	phone_button.add_theme_stylebox_override("normal", _button_style(Color(0.06, 0.1, 0.16, 0.94)))
	phone_button.add_theme_stylebox_override("pressed", _button_style(Color(0.18, 0.34, 0.48, 0.98)))
	parent.add_child(phone_button)

	phone_panel = PanelContainer.new()
	phone_panel.position = Vector2(-370, 94)
	phone_panel.size = Vector2(350, 420)
	phone_panel.anchor_left = 1.0
	phone_panel.anchor_right = 1.0
	phone_panel.visible = false
	phone_panel.add_theme_stylebox_override("panel", _button_style(Color(0.035, 0.055, 0.085, 0.97)))
	parent.add_child(phone_panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	phone_panel.add_child(content)

	var heading := Label.new()
	heading.text = "CARL'S SMARTPHONE"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 22)
	content.add_child(heading)

	var gps_title := Label.new()
	gps_title.text = "GPS  /  CURRENT OBJECTIVE"
	gps_title.add_theme_font_size_override("font_size", 15)
	content.add_child(gps_title)
	phone_gps_label = Label.new()
	phone_gps_label.text = "OBJECTIVE: Find your first job"
	phone_gps_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	phone_gps_label.add_theme_font_size_override("font_size", 17)
	content.add_child(phone_gps_label)

	var apps := GridContainer.new()
	apps.columns = 2
	apps.add_theme_constant_override("h_separation", 8)
	apps.add_theme_constant_override("v_separation", 8)
	content.add_child(apps)
	for app_name in ["MAP / GPS", "CONTACTS", "MESSAGES", "BANK", "MISSIONS", "SETTINGS"]:
		var app_button := Button.new()
		app_button.text = app_name
		app_button.custom_minimum_size = Vector2(145, 54)
		app_button.add_theme_font_size_override("font_size", 15)
		app_button.add_theme_stylebox_override("normal", _button_style(Color(0.12, 0.19, 0.27, 0.98)))
		apps.add_child(app_button)
		app_button.pressed.connect(func(): _phone_app_selected(app_name))

	phone_status_label = Label.new()
	phone_status_label.text = "Choose an app"
	phone_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	phone_status_label.add_theme_font_size_override("font_size", 14)
	content.add_child(phone_status_label)

	var close_button := Button.new()
	close_button.text = "CLOSE PHONE"
	close_button.custom_minimum_size = Vector2(0, 48)
	content.add_child(close_button)
	close_button.pressed.connect(func(): phone_panel.visible = false)
	phone_button.pressed.connect(func(): phone_panel.visible = not phone_panel.visible)

func _phone_app_selected(app_name: String) -> void:
	if not is_instance_valid(phone_status_label): return
	match app_name:
		"MAP / GPS":
			phone_status_label.text = "GPS is tracking Carl. Follow the current mission objective."
		"CONTACTS":
			phone_status_label.text = "CONTACTS: No contacts saved yet."
		"MESSAGES":
			phone_status_label.text = "MESSAGES: No new messages."
		"BANK":
			phone_status_label.text = "BANK BALANCE: $500"
		"MISSIONS":
			phone_status_label.text = "MISSIONS: " + objective_label.text
		_:
			phone_status_label.text = "SETTINGS: Audio and gameplay options will be added in a later update."
