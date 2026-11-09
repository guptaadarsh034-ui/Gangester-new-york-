extends Node3D
## Streamed regional world, transport terminals, shops and police dispatch.
signal radio_message(message: String)
signal region_changed(region_name: String)
signal wanted_changed(level: int)

const REGIONS: Array[Dictionary] = [
	{"name":"New York City","kind":"city","style":0,"base":Vector3(0,0,0),"landmark":"Manhattan / Brooklyn"},
	{"name":"San Francisco","kind":"city","style":1,"base":Vector3(3000,0,0),"landmark":"Bayfront / Downtown"},
	{"name":"London","kind":"city","style":2,"base":Vector3(6000,0,0),"landmark":"Westminster / City"},
	{"name":"Edinburgh","kind":"city","style":3,"base":Vector3(9000,0,0),"landmark":"Old Town / Castle"},
	{"name":"Kent","kind":"town","style":4,"base":Vector3(12000,0,0),"landmark":"High Street / Countryside"},
	{"name":"Gloucester","kind":"town","style":5,"base":Vector3(15000,0,0),"landmark":"Cathedral Quarter"},
	{"name":"Sussex","kind":"town","style":6,"base":Vector3(18000,0,0),"landmark":"Coastal Town"}
]
const CHUNK_SIZE: float = 220.0
const LOAD_RADIUS: int = 1
var player: CharacterBody3D
var active_region: int = 0
var loaded_chunks: Dictionary = {}
var chunk_root: Node3D
var ui_layer: CanvasLayer
var travel_panel: PanelContainer
var status_label: Label
var radio_label: Label
var wanted_level: int = 0
var crime_points: float = 0.0
var dispatch_timer: float = 0.0
var police_units: Array[CharacterBody3D] = []
var taxi_active: bool = false
var in_shop: bool = false
var shop_return: Vector3
var shop_return_region: int = 0
var wanted_decay: float = 0.0

func initialize(target: CharacterBody3D, parent: Node) -> void:
	player = target
	chunk_root = Node3D.new()
	chunk_root.name = "StreamedWorld"
	parent.add_child(chunk_root)
	_build_ui(parent)
	_load_region(0, false)
	radio_message.emit("DISPATCH: City services online. Welcome to New York.")
	region_changed.emit("New York City")

func _process(delta: float) -> void:
	if not is_instance_valid(player): return
	_update_streaming()
	_update_wanted(delta)
	_update_police(delta)
	if taxi_active and Input.is_action_just_pressed("interact"):
		taxi_active = false

func _update_streaming() -> void:
	var base: Vector3 = REGIONS[active_region].base
	var local: Vector3 = player.global_position - base
	var cx: int = floori(local.x / CHUNK_SIZE)
	var cz: int = floori(local.z / CHUNK_SIZE)
	var wanted: Dictionary = {}
	for x in range(cx-LOAD_RADIUS, cx+LOAD_RADIUS+1):
		for z in range(cz-LOAD_RADIUS, cz+LOAD_RADIUS+1):
			if active_region == 0 and x == 0 and z == 0: continue
			var key: String = "%d:%d:%d" % [active_region,x,z]
			wanted[key] = true
			if not loaded_chunks.has(key):
				loaded_chunks[key] = _make_chunk(active_region,x,z)
	var stale: Array = []
	for key in loaded_chunks.keys():
		if not wanted.has(key): stale.append(key)
	for key in stale:
		var node: Node3D = loaded_chunks[key]
		if is_instance_valid(node): node.queue_free()
		loaded_chunks.erase(key)

func _load_region(index: int, announce: bool) -> void:
	for node in loaded_chunks.values():
		if is_instance_valid(node): node.queue_free()
	loaded_chunks.clear()
	active_region = clampi(index,0,REGIONS.size()-1)
	var base: Vector3 = REGIONS[active_region].base
	player.global_position = base + Vector3(0,0.1,22)
	player.velocity = Vector3.ZERO
	for x in range(-LOAD_RADIUS,LOAD_RADIUS+1):
		for z in range(-LOAD_RADIUS,LOAD_RADIUS+1):
			if active_region == 0 and x == 0 and z == 0: continue
			var key: String = "%d:%d:%d" % [active_region,x,z]
			loaded_chunks[key] = _make_chunk(active_region,x,z)
	if announce:
		var region_name: String = REGIONS[active_region].name
		radio_message.emit("TRAVEL CONTROL: Arrived in %s. Local services available." % region_name)
		region_changed.emit(region_name)
		_close_travel()

func travel_to(index: int, by_air: bool) -> void:
	if index < 0 or index >= REGIONS.size(): return
	if index == active_region:
		var base: Vector3 = REGIONS[index].base
		player.global_position = base + Vector3(0,0.1,90)
		radio_message.emit("TAXI DISPATCH: Dropped at the %s district." % REGIONS[index].landmark)
		_close_travel()
		return
	if by_air:
		radio_message.emit("AIR TRAFFIC CONTROL: Flight cleared. Preparing route to %s." % REGIONS[index].name)
	else:
		radio_message.emit("TAXI DISPATCH: Long-distance fare accepted. Driving to %s." % REGIONS[index].name)
	_load_region(index,true)

func _make_chunk(region_id: int, cx: int, cz: int) -> Node3D:
	var data: Dictionary = REGIONS[region_id]
	var style: int = int(data.style)
	var origin: Vector3 = data.base + Vector3(float(cx)*CHUNK_SIZE,0,float(cz)*CHUNK_SIZE)
	var root := Node3D.new()
	root.name = "Chunk_%d_%d_%d" % [region_id,cx,cz]
	chunk_root.add_child(root)
	var road_mat := _material(Color(0.055,0.065,0.078))
	var sidewalk_mat := _material(Color(0.42,0.42,0.39))
	_add_box(root,"RoadNS",origin+Vector3(0,-0.3,0),Vector3(18,0.5,CHUNK_SIZE),road_mat,true)
	_add_box(root,"RoadEW",origin+Vector3(0,-0.3,0),Vector3(CHUNK_SIZE,0.5,18),road_mat,true)
	_add_box(root,"SidewalkN",origin+Vector3(-13,-0.08,0),Vector3(8,0.3,CHUNK_SIZE),sidewalk_mat,true)
	_add_box(root,"SidewalkS",origin+Vector3(13,-0.08,0),Vector3(8,0.3,CHUNK_SIZE),sidewalk_mat,true)
	_add_box(root,"SidewalkE",origin+Vector3(0,-0.08,-13),Vector3(CHUNK_SIZE,0.3,8),sidewalk_mat,true)
	_add_box(root,"SidewalkW",origin+Vector3(0,-0.08,13),Vector3(CHUNK_SIZE,0.3,8),sidewalk_mat,true)
	var palette: Array[Color] = _palette(style)
	var blocks: int = 3 if data.kind == "city" else 2
	for bx in range(blocks):
		for bz in range(blocks):
			var px: float = -75.0 + float(bx)*75.0
			var pz: float = -75.0 + float(bz)*75.0
			if absf(px) < 24.0 or absf(pz) < 24.0: continue
			var seed: int = abs(cx*73+cz*37+region_id*113+bx*19+bz*11)
			var h: float = (18.0 + float(seed%7)*5.0) if data.kind == "city" else (7.0+float(seed%4)*2.4)
			var w: float = 24.0 if data.kind == "city" else 27.0
			var d: float = 26.0
			var color: Color = palette[seed%palette.size()]
			_make_building(root,origin+Vector3(px,h*0.5-0.1,pz),Vector3(w,h,d),color,style,seed)
			if seed%4 == 0:
				_make_shop(root,origin+Vector3(px,0,pz),style,seed)
	if cx == 0 and cz == 0:
		_make_transport_hub(root,origin,style)
	return root

func _palette(style: int) -> Array[Color]:
	match style:
		0: return [Color(0.36,0.40,0.46),Color(0.48,0.34,0.26),Color(0.42,0.48,0.43),Color(0.53,0.47,0.38)]
		1: return [Color(0.82,0.69,0.49),Color(0.52,0.61,0.63),Color(0.76,0.73,0.64),Color(0.34,0.47,0.52)]
		2: return [Color(0.48,0.36,0.28),Color(0.59,0.53,0.43),Color(0.40,0.42,0.43),Color(0.62,0.56,0.47)]
		3: return [Color(0.36,0.39,0.42),Color(0.48,0.45,0.39),Color(0.33,0.38,0.42),Color(0.58,0.54,0.45)]
		_: return [Color(0.68,0.57,0.42),Color(0.55,0.49,0.38),Color(0.46,0.53,0.43),Color(0.70,0.65,0.52)]

func _make_building(root: Node3D, pos: Vector3, size: Vector3, color: Color, style: int, seed: int) -> void:
	var body := _add_box(root,"Building",pos,size,_material(color),true)
	_add_box(root,"RoofCornice",pos+Vector3(0,size.y*0.5+0.3,0),Vector3(size.x+1.0,0.5,size.z+1.0),_material(color.darkened(0.25)),false)
	var rows: int = maxi(1,int(size.y/3.5))
	for floor in range(rows):
		for side in [-1.0,1.0]:
			for col in range(2):
				var z: float = pos.z+(float(col)-0.5)*size.z*0.48
				_add_box(root,"FacadeWindow",Vector3(pos.x+side*(size.x*0.5+0.045),pos.y-size.y*0.5+1.8+float(floor)*3.2,z),Vector3(0.08,1.25,1.4),_material(Color(0.12,0.23,0.31) if (floor+col+seed)%3 else Color(0.64,0.55,0.37)),false)
		for col in range(2):
			var x: float = pos.x+(float(col)-0.5)*size.x*0.48
			_add_box(root,"StreetWindow",Vector3(x,pos.y-size.y*0.5+1.8+float(floor)*3.2,pos.z-size.z*0.5-0.05),Vector3(1.35,1.25,0.08),_material(Color(0.12,0.22,0.3)),false)
	if style == 2 or style == 3:
		_add_box(root,"StoneFacadeBand",pos+Vector3(0,0,size.z*0.5+0.12),Vector3(size.x,0.28,0.18),_material(color.lightened(0.22)),false)

func _make_shop(root: Node3D, pos: Vector3, style: int, seed: int) -> void:
	var sign_colors: Array[Color] = [Color(0.76,0.2,0.12),Color(0.12,0.44,0.58),Color(0.72,0.55,0.18)]
	var c: Color = sign_colors[seed%sign_colors.size()]
	_add_box(root,"ShopAwning",pos+Vector3(0,3.0,-14.2),Vector3(10,0.7,1.1),_material(c),false)
	_add_box(root,"ShopFrontGlass",pos+Vector3(0,1.5,-13.7),Vector3(8,2.8,0.12),_material(Color(0.09,0.2,0.27)),false)
	_add_box(root,"ShopDoor",pos+Vector3(4.3,1.4,-13.6),Vector3(1.0,2.6,0.2),_material(Color(0.22,0.18,0.12)),false)
	_add_box(root,"ShopNameplate",pos+Vector3(0,4.0,-14.1),Vector3(8.5,0.8,0.25),_material(Color(0.95,0.76,0.4)),false)

func _make_transport_hub(root: Node3D, origin: Vector3, style: int) -> void:
	_add_box(root,"AirportTerminal",origin+Vector3(62,5,62),Vector3(55,10,34),_material(Color(0.22,0.29,0.35)),true)
	_add_box(root,"AirportGlassFront",origin+Vector3(62,5,44.7),Vector3(46,7,0.25),_material(Color(0.13,0.34,0.45)),false)
	_add_box(root,"Runway",origin+Vector3(130,-0.3,62),Vector3(120,0.5,28),_material(Color(0.08,0.09,0.1)),true)
	_add_box(root,"TaxiDepot",origin+Vector3(-62,2,-62),Vector3(30,4,18),_material(Color(0.16,0.24,0.19)),true)
	_add_box(root,"PoliceStation",origin+Vector3(-62,3,62),Vector3(28,6,22),_material(Color(0.16,0.22,0.3)),true)
	_add_box(root,"PoliceSign",origin+Vector3(-62,6.5,50.5),Vector3(12,1,0.3),_material(Color(0.08,0.26,0.62)),false)

func _material(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.86
	return m

func _add_box(parent: Node3D, node_name: String, pos: Vector3, dimensions: Vector3, mat: Material, solid: bool) -> Node3D:
	var root: Node3D = StaticBody3D.new() if solid else MeshInstance3D.new()
	root.name = node_name
	root.position = pos
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	mesh.material = mat
	if solid:
		var visual := MeshInstance3D.new()
		visual.mesh = mesh
		root.add_child(visual)
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = dimensions
		collision.shape = shape
		root.add_child(collision)
	else:
		(root as MeshInstance3D).mesh = mesh
		(root as MeshInstance3D).material_override = mat
	parent.add_child(root)
	return root

func add_crime(amount: float = 1.0) -> void:
	crime_points += amount
	var next_level: int = clampi(int(ceil(crime_points/2.0)),0,5)
	if next_level > wanted_level:
		wanted_level = next_level
		wanted_changed.emit(wanted_level)
		radio_message.emit("POLICE RADIO: All units, priority %d response. Suspect reported in %s." % [wanted_level,REGIONS[active_region].name])
		dispatch_timer = 0.5

func _update_wanted(delta: float) -> void:
	if wanted_level <= 0: return
	wanted_decay += delta
	if wanted_decay > 28.0 and police_units.is_empty():
		wanted_decay = 0.0
		crime_points = maxf(0.0,crime_points-1.0)
		var new_level: int = clampi(int(ceil(crime_points/2.0)),0,5)
		if new_level != wanted_level:
			wanted_level = new_level
			wanted_changed.emit(wanted_level)
			radio_message.emit("POLICE RADIO: Search intensity reduced. Units stand by.")
	if dispatch_timer > 0.0:
		dispatch_timer -= delta
		if dispatch_timer <= 0.0: _dispatch_units()

func _dispatch_units() -> void:
	if not is_instance_valid(player): return
	var desired: int = mini(wanted_level,5)
	while police_units.size() < desired:
		var unit := CharacterBody3D.new()
		unit.name = "PolicePatrol"
		var mesh := MeshInstance3D.new()
		var capsule := CapsuleMesh.new()
		capsule.radius = 0.42
		capsule.height = 1.8
		var uniform := StandardMaterial3D.new()
		uniform.albedo_color = Color(0.035,0.12,0.34)
		capsule.material = uniform
		mesh.mesh = capsule
		mesh.position.y = 0.95
		unit.add_child(mesh)
		var collision := CollisionShape3D.new()
		var shape := CapsuleShape3D.new()
		shape.radius = 0.4
		shape.height = 1.8
		collision.shape = shape
		collision.position.y = 0.9
		unit.add_child(collision)
		var offset := Vector3(randf_range(-22.0,22.0),0,randf_range(-22.0,22.0))
		unit.global_position = player.global_position + offset
		get_parent().add_child(unit)
		police_units.append(unit)
	radio_message.emit("POLICE RADIO: %d patrol unit(s) responding. Avoid the search area." % police_units.size())

func _update_police(delta: float) -> void:
	for unit in police_units:
		if not is_instance_valid(unit): continue
		var direction: Vector3 = player.global_position-unit.global_position
		direction.y = 0.0
		if direction.length() > 3.0:
			direction = direction.normalized()
			unit.velocity.x = direction.x*4.0
			unit.velocity.z = direction.z*4.0
			unit.rotation.y = atan2(-direction.x,-direction.z)
		else:
			unit.velocity.x = move_toward(unit.velocity.x,0.0,8.0*delta)
			unit.velocity.z = move_toward(unit.velocity.z,0.0,8.0*delta)
			if randf() < delta*0.35 and player.has_method("take_damage"):
				player.take_damage(4)
		unit.velocity.y = -20.0*delta if not unit.is_on_floor() else 0.0
		unit.move_and_slide()

func clear_wanted() -> void:
	crime_points = 0.0
	wanted_level = 0
	wanted_changed.emit(0)
	for unit in police_units:
		if is_instance_valid(unit): unit.queue_free()
	police_units.clear()
	radio_message.emit("POLICE RADIO: Suspect no longer sighted. Returning to patrol.")

func _build_ui(parent: Node) -> void:
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 12
	parent.add_child(ui_layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(root)
	var map_button := Button.new()
	map_button.text = "WORLD / TRAVEL"
	map_button.position = Vector2(-190,88)
	map_button.size = Vector2(170,52)
	map_button.anchor_left = 1.0
	map_button.anchor_right = 1.0
	map_button.add_theme_font_size_override("font_size",16)
	root.add_child(map_button)
	map_button.pressed.connect(_open_travel)
	status_label = Label.new()
	status_label.text = "NEW YORK CITY  •  WANTED: ☆☆☆☆☆"
	status_label.position = Vector2(28,150)
	status_label.add_theme_font_size_override("font_size",16)
	root.add_child(status_label)
	radio_label = Label.new()
	radio_label.text = "RADIO: Dispatch channel ready"
	radio_label.position = Vector2(28,178)
	radio_label.add_theme_font_size_override("font_size",14)
	radio_label.add_theme_color_override("font_color",Color(0.65,0.88,1.0))
	root.add_child(radio_label)
	travel_panel = PanelContainer.new()
	travel_panel.position = Vector2(-360,-290)
	travel_panel.size = Vector2(350,560)
	travel_panel.anchor_left = 1.0
	travel_panel.anchor_right = 1.0
	travel_panel.anchor_top = 0.5
	travel_panel.anchor_bottom = 0.5
	travel_panel.visible = false
	root.add_child(travel_panel)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation",5)
	travel_panel.add_child(stack)
	var heading := Label.new()
	heading.text = "WORLD MAP & TRANSPORT"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size",20)
	stack.add_child(heading)
	var taxi := Button.new()
	taxi.text = "CALL TAXI  •  LOCAL DISTRICT"
	taxi.custom_minimum_size.y = 44
	stack.add_child(taxi)
	taxi.pressed.connect(_taxi_local)
	var flight := Label.new()
	flight.text = "AIRPORT FLIGHTS / LONG DISTANCE TAXI"
	flight.add_theme_font_size_override("font_size",13)
	stack.add_child(flight)
	for i in range(REGIONS.size()):
		var button := Button.new()
		button.text = "%s  —  %s" % [REGIONS[i].name, "CITY" if REGIONS[i].kind=="city" else "TOWN"]
		button.custom_minimum_size.y = 42
		stack.add_child(button)
		var destination: int = i
		button.pressed.connect(func(): travel_to(destination,true))
	var close := Button.new()
	close.text = "CLOSE MAP"
	close.custom_minimum_size.y = 42
	stack.add_child(close)
	close.pressed.connect(_close_travel)

func _open_travel() -> void:
	travel_panel.visible = true
	get_tree().paused = false

func _close_travel() -> void:
	if is_instance_valid(travel_panel): travel_panel.visible = false

func _taxi_local() -> void:
	travel_to(active_region,false)
	radio_message.emit("TAXI DISPATCH: Your cab is waiting at the curb.")
