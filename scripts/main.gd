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
func _ready() -> void:
	_input_setup()
	_city()
	_make_player()
	_mission()
	_hud()
	_refresh()
func _process(_delta: float) -> void:
	if not is_instance_valid(player): return
	health_label.text = "HEALTH  %d" % player.health
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
func _city() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = Sky.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.48,0.55,0.68)
	env.ambient_light_energy = 0.7
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48,-32,0)
	add_child(sun)
	_box("Asphalt",Vector3(0,-0.35,0),Vector3(18,0.5,90),Color(0.12,0.14,0.17),true)
	_box("WestWalk",Vector3(-11,-0.1,0),Vector3(4,0.4,90),Color(0.42,0.42,0.4),true)
	_box("EastWalk",Vector3(11,-0.1,0),Vector3(4,0.4,90),Color(0.42,0.42,0.4),true)
	for z in range(-40,45,12):
		_box("LaneStripe",Vector3(0,-0.08,z),Vector3(0.22,0.05,5),Color(0.9,0.82,0.5),false)
	for side in [-1,1]:
		for i in range(4):
			var z := -32.0 + i * 21.0
			var h := 9.0 + float((i*7)%5)
			_box("CityBlock",Vector3(side*19,h*0.5-0.1,z),Vector3(11,h,15),Color(0.18+i*0.025,0.22,0.28),true)
	_box("Warehouse",Vector3(0,3.5,-22),Vector3(19,7,13),Color(0.28,0.31,0.34),false)
	_box("WarehouseDoor",Vector3(0,2.2,-15.35),Vector3(5,4.4,0.2),Color(0.08,0.1,0.12),false)
	_box("Safehouse",Vector3(0,2.5,29),Vector3(15,5,9),Color(0.28,0.24,0.2),false)
func _box(n: String,p: Vector3,s: Vector3,c: Color,solid: bool) -> Node3D:
	var root: Node3D = StaticBody3D.new() if solid else MeshInstance3D.new()
	root.name=n
	root.position=p
	var mesh := BoxMesh.new()
	mesh.size=s
	var mat := StandardMaterial3D.new()
	mat.albedo_color=c
	mesh.material=mat
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
		(root as MeshInstance3D).material_override=mat
	add_child(root)
	return root
func _make_player() -> void:
	player=CharacterBody3D.new()
	player.name="Player"
	player.set_script(PLAYER)
	_character_visual(player,Color(0.12,0.28,0.58),0.42)
	player.position=Vector3(0,-0.1,22)
	add_child(player)
func _character_visual(body: CharacterBody3D,color: Color,radius: float) -> void:
	var mesh := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius=radius
	capsule.height=1.8
	var mat := StandardMaterial3D.new()
	mat.albedo_color=color
	capsule.material=mat
	mesh.mesh=capsule
	mesh.position.y=0.9
	body.add_child(mesh)
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
		_character_visual(guard,Color(0.62,0.12,0.1),0.43)
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
	title_label=_label(ui,"MISSION 01 | THE STOLEN PACKAGE",Vector2(24,18),25)
	objective_label=_label(ui,"",Vector2(24,55),18)
	health_label=_label(ui,"HEALTH 100",Vector2(24,88),18)
	_button(ui,"◀",Vector2(25,-105),Vector2(85,70),false,"move_left")
	_button(layer,"▶",Vector2(205,-105),Vector2(85,70),false,"move_right")
	_button(layer,"▲",Vector2(115,-180),Vector2(85,70),false,"move_forward")
	_button(layer,"▼",Vector2(115,-90),Vector2(85,70),false,"move_back")
	var fire := _button(layer,"FIRE",Vector2(-130,-105),Vector2(105,75),true,"")
	fire.pressed.connect(func(): player.shoot())
	var act := _button(layer,"ACTION",Vector2(-130,-195),Vector2(105,75),true,"")
	act.pressed.connect(_interact)
func _label(parent: Control,txt: String,pos: Vector2,size: int) -> Label:
	var l := Label.new()
	l.text=txt
	l.position=pos
	l.add_theme_font_size_override("font_size",size)
	l.add_theme_color_override("font_color",Color.WHITE)
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
	parent.add_child(b)
	if action != "":
		b.button_down.connect(func(): Input.action_press(action))
		b.button_up.connect(func(): Input.action_release(action))
	return b
func _interact() -> void:
	Input.action_press("interact")
	await get_tree().create_timer(0.15).timeout
	Input.action_release("interact")
func _guard_count() -> int:
	var count := 0
	for g in guards:
		if is_instance_valid(g): count += 1
	return count
func _refresh() -> void:
	match stage:
		0: objective_label.text="OBJECTIVE: Reach the warehouse"
		1: objective_label.text="OBJECTIVE: Defeat guards (%d remaining)" % _guard_count()
		2: objective_label.text="OBJECTIVE: Stand by the package and tap ACTION"
		3: objective_label.text="OBJECTIVE: Escape to the green safehouse marker"
		4: objective_label.text="MISSION FAILED — Restart the game"
		5: objective_label.text="MISSION COMPLETE! Package secured."
