extends Node3D
const POLICE = preload("res://scripts/police_officer.gd")
const ASSETS = preload("res://scripts/asset_library.gd")
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
var travel_by_air: bool = true
var destination_buttons: Array[Button] = []
var in_shop: bool = false
var shop_entries: Array[Dictionary] = []
var active_shop: Dictionary = {}
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
	_update_shop_interaction()
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
		var kept: Array[Dictionary] = []
		for entry in shop_entries:
			if str(entry.get("chunk_key","")) != str(key): kept.append(entry)
		shop_entries = kept
		var node: Node3D = loaded_chunks[key]
		if is_instance_valid(node): node.queue_free()
		loaded_chunks.erase(key)

func _load_region(index: int, announce: bool) -> void:
	if active_region != index: clear_wanted()
	shop_entries.clear()
	in_shop = false
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
	if is_instance_valid(status_label): status_label.text = "%s  •  WANTED: ☆☆☆☆☆" % REGIONS[active_region].name.to_upper()
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
	var blocks: int = 2
	for bx in range(blocks):
		for bz in range(blocks):
			var px: float = -58.0 + float(bx)*116.0
			var pz: float = -58.0 + float(bz)*116.0
			if absf(px) < 24.0 or absf(pz) < 24.0: continue
			var seed: int = abs(cx*73+cz*37+region_id*113+bx*19+bz*11)
			var h: float = (18.0 + float(seed%7)*5.0) if data.kind == "city" else (7.0+float(seed%4)*2.4)
			var w: float = 34.0 if data.kind == "city" else 31.0
			var d: float = 36.0
			var color: Color = palette[seed%palette.size()]
			var building_pos: Vector3 = origin+Vector3(px,h*0.5-0.1,pz)
			var building_size: Vector3 = Vector3(w,h,d)
			var imported: Node3D = ASSETS.create_building(root,building_pos,building_size,seed)
			if imported == null:
				_make_building(root,building_pos,building_size,color,style,seed)
			if seed%4 == 0:
				_make_shop(root,origin+Vector3(px,0,pz),style,seed,"%d:%d:%d" % [region_id,cx,cz])
	# Imported Kenney street props add a real silhouette and variation to each streamed block.
	for lamp_z in [-82.0,82.0]:
		ASSETS.create_prop(root,"light-square.glb",origin+Vector3(-17,0,lamp_z),1.0)
		ASSETS.create_prop(root,"light-square.glb",origin+Vector3(17,0,lamp_z),1.0)
	ASSETS.create_city_prop(root,"tree-large.glb",origin+Vector3(-34,0,-34),1.0)
	ASSETS.create_city_prop(root,"tree-small.glb",origin+Vector3(34,0,34),1.0)
	if cx == 1 and cz == 0:
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
				_add_box(root,"FacadeWindow",Vector3(pos.x+side*(size.x*0.5+0.045),pos.y-size.y*0.5+1.8+float(floor)*3.2,z),Vector3(0.08,1.25,1.4),_material(Color(0.12,0.23,0.31) if (floor+col+seed)%3 == 0 else Color(0.64,0.55,0.37)),false)
		for col in range(2):
			var x: float = pos.x+(float(col)-0.5)*size.x*0.48
			_add_box(root,"StreetWindow",Vector3(x,pos.y-size.y*0.5+1.8+float(floor)*3.2,pos.z-size.z*0.5-0.05),Vector3(1.35,1.25,0.08),_material(Color(0.12,0.22,0.3)),false)
	if style == 2 or style == 3:
		_add_box(root,"StoneFacadeBand",pos+Vector3(0,0,size.z*0.5+0.12),Vector3(size.x,0.28,0.18),_material(color.lightened(0.22)),false)

func _make_shop(root: Node3D, pos: Vector3, style: int, seed: int, chunk_key: String) -> void:
	var sign_colors: Array[Color] = [Color(0.76,0.2,0.12),Color(0.12,0.44,0.58),Color(0.72,0.55,0.18)]
	var c: Color = sign_colors[seed%sign_colors.size()]
	_add_box(root,"ShopAwning",pos+Vector3(0,3.0,-14.2),Vector3(10,0.7,1.1),_material(c),false)
	_add_box(root,"ShopFrontGlass",pos+Vector3(0,1.5,-13.7),Vector3(8,2.8,0.12),_material(Color(0.09,0.2,0.27)),false)
	_add_box(root,"ShopDoor",pos+Vector3(4.3,1.4,-13.6),Vector3(1.0,2.6,0.2),_material(Color(0.22,0.18,0.12)),false)
	_add_box(root,"ShopNameplate",pos+Vector3(0,4.0,-14.1),Vector3(8.5,0.8,0.25),_material(Color(0.95,0.76,0.4)),false)
	var interior: Vector3 = pos + Vector3(0,-150,0)
	_add_box(root,"ShopInteriorFloor",interior+Vector3(0,-0.25,0),Vector3(16,0.5,14),_material(Color(0.24,0.22,0.18)),true)
	_add_box(root,"ShopInteriorBackWall",interior+Vector3(0,2.2,6.8),Vector3(16,4.4,0.4),_material(Color(0.35,0.31,0.25)),true)
	_add_box(root,"ShopInteriorLeftWall",interior+Vector3(-7.8,2.2,0),Vector3(0.4,4.4,14),_material(Color(0.32,0.29,0.24)),true)
	_add_box(root,"ShopInteriorRightWall",interior+Vector3(7.8,2.2,0),Vector3(0.4,4.4,14),_material(Color(0.32,0.29,0.24)),true)
	_add_box(root,"ShopCounter",interior+Vector3(0,0.75,-3.4),Vector3(10,1.5,1.2),_material(Color(0.18,0.12,0.08)),true)
	for shelf_x in [-5.5,5.5]:
		_add_box(root,"ShopShelf",interior+Vector3(shelf_x,1.5,2.0),Vector3(1.0,3.0,5.0),_material(Color(0.18,0.15,0.12)),true)
	shop_entries.append({"entrance":pos+Vector3(0,0.1,-11.0),"interior":interior,"chunk_key":chunk_key})

func _update_shop_interaction() -> void:
	if not Input.is_action_just_pressed("interact") or not is_instance_valid(player): return
	if in_shop:
		player.global_position = shop_return
		player.velocity = Vector3.ZERO
		in_shop = false
		active_shop = {}
		radio_message.emit("STORE CLERK: Thanks for stopping by.")
		return
	for entry in shop_entries:
		var entrance: Vector3 = entry.entrance
		if player.global_position.distance_to(entrance) < 4.0:
			shop_return = player.global_position
			active_shop = entry
			player.global_position = entry.interior + Vector3(0,1.2,4.5)
			player.velocity = Vector3.ZERO
			in_shop = true
			radio_message.emit("STORE PA: Welcome inside. Tap ACTION at the door to leave.")
			return

func _make_transport_hub(root: Node3D, origin: Vector3, style: int) -> void:
	_add_box(root,"AirportTerminal",origin+Vector3(62,5,62),Vector3(55,10,34),_material(Color(0.22,0.29,0.35)),true)
	_add_box(root,"AirportGlassFront",origin+Vector3(62,5,44.7),Vector3(46,7,0.25),_material(Color(0.13,0.34,0.45)),false)
	_add_box(root,"Runway",origin+Vector3(130,-0.3,62),Vector3(120,0.5,28),_material(Color(0.08,0.09,0.1)),true)
	_add_box(root,"TaxiDepot",origin+Vector3(-62,2,-62),Vector3(30,4,18),_material(Color(0.16,0.24,0.19)),true)
	_add_box(root,"PoliceStation",origin+Vector3(-62,3,62),Vector3(28,6,22),_material(Color(0.16,0.22,0.3)),true)
	_add_box(root,"PoliceSign",origin+Vector3(-62,6.5,50.5),Vector3(12,1,0.3),_material(Color(0.08,0.26,0.62)),false)
	_add_box(root,"FireStation",origin+Vector3(-62,3,-115),Vector3(28,6,22),_material(Color(0.62,0.12,0.08)),true)
	_add_box(root,"FireStationDoor",origin+Vector3(-62,2,-103.5),Vector3(10,4,0.3),_material(Color(0.12,0.13,0.15)),false)
	_add_box(root,"AirportPlaneFuselage",origin+Vector3(130,7,62),Vector3(5,4,28),_material(Color(0.84,0.86,0.88)),false)
	_add_box(root,"AirportPlaneWing",origin+Vector3(130,6,62),Vector3(34,0.8,6),_material(Color(0.78,0.81,0.84)),false)
	_add_box(root,"AirportPlaneTail",origin+Vector3(130,9,74),Vector3(12,0.7,5),_material(Color(0.14,0.25,0.44)),false)
	_add_box(root,"AirportHangar",origin+Vector3(178,8,115),Vector3(42,16,36),_material(Color(0.3,0.34,0.38)),true)

func _make_regional_landmark(root: Node3D, origin: Vector3, style: int) -> void:
	match style:
		1:
			# Stylised Golden Gate bridge: twin towers, deck and suspension cables.
			_add_box(root,"BayBridgeDeck",origin+Vector3(105,18,145),Vector3(150,2.2,12),_material(Color(0.72,0.25,0.12)),true)
			for x in [42.0,168.0]:
				_add_box(root,"BayBridgeTower",origin+Vector3(x,43,145),Vector3(5,52,6),_material(Color(0.78,0.28,0.13)),true)
				_add_box(root,"BayBridgeCrossbar",origin+Vector3(x,60,145),Vector3(10,3,7),_material(Color(0.78,0.28,0.13)),false)
			for z in range(95,196,12):
				_add_box(root,"BridgeCable",origin+Vector3(105,29,float(z)),Vector3(0.18,23,0.18),_material(Color(0.78,0.62,0.48)),false)
		2:
			_add_box(root,"BigBenTower",origin+Vector3(108,31,145),Vector3(12,62,12),_material(Color(0.55,0.48,0.37)),true)
			_add_box(root,"ClockFace",origin+Vector3(108,47,138.6),Vector3(5,5,0.3),_material(Color(0.88,0.82,0.62)),false)
			_add_box(root,"TowerBridgeDeck",origin+Vector3(55,8,95),Vector3(100,2,12),_material(Color(0.32,0.4,0.48)),true)
			for x in [12.0,98.0]:
				_add_box(root,"TowerBridgePier",origin+Vector3(x,19,95),Vector3(8,38,10),_material(Color(0.48,0.4,0.32)),true)
		3:
			_add_box(root,"CastleRock",origin+Vector3(105,12,150),Vector3(75,24,50),_material(Color(0.27,0.29,0.3)),true)
			_add_box(root,"EdinburghCastleKeep",origin+Vector3(105,30,150),Vector3(22,36,18),_material(Color(0.4,0.38,0.34)),true)
			for x in [95.0,115.0]:
				_add_box(root,"CastleTower",origin+Vector3(x,42,142),Vector3(7,22,7),_material(Color(0.38,0.35,0.31)),true)
		4:
			_add_box(root,"KentWindmillBase",origin+Vector3(105,9,145),Vector3(12,18,12),_material(Color(0.76,0.7,0.57)),true)
			for angle in [0.0,90.0,180.0,270.0]:
				var blade := _add_box(root,"WindmillBlade",origin+Vector3(105,22,138),Vector3(1.2,18,0.4),_material(Color(0.92,0.88,0.78)),false)
				blade.rotation_degrees.z = angle
		5:
			_add_box(root,"GloucesterCathedralNave",origin+Vector3(105,10,145),Vector3(60,20,26),_material(Color(0.62,0.55,0.44)),true)
			_add_box(root,"GloucesterCathedralTower",origin+Vector3(105,31,145),Vector3(16,42,16),_material(Color(0.58,0.5,0.4)),true)
		6:
			_add_box(root,"SussexSeafront",origin+Vector3(105,0.1,180),Vector3(170,0.3,40),_material(Color(0.2,0.42,0.55)),false)
			_add_box(root,"SussexPier",origin+Vector3(105,4,145),Vector3(80,1,8),_material(Color(0.42,0.3,0.2)),true)

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
		unit.set_script(POLICE)
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
	var active_units: Array[CharacterBody3D] = []
	for unit in police_units:
		if not is_instance_valid(unit): continue
		active_units.append(unit)
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
	police_units = active_units

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
	status_label.text = "%s  •  WANTED: ☆☆☆☆☆" % REGIONS[active_region].name.to_upper()
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
	var mode_row := HBoxContainer.new()
	stack.add_child(mode_row)
	var flight_mode := Button.new()
	flight_mode.text = "AIRPORT FLIGHT"
	flight_mode.custom_minimum_size = Vector2(150,38)
	mode_row.add_child(flight_mode)
	flight_mode.pressed.connect(func(): travel_by_air = true; _refresh_destinations())
	var taxi_mode := Button.new()
	taxi_mode.text = "LONG-DISTANCE TAXI"
	taxi_mode.custom_minimum_size = Vector2(150,38)
	mode_row.add_child(taxi_mode)
	taxi_mode.pressed.connect(func(): travel_by_air = false; _refresh_destinations())
	for i in range(REGIONS.size()):
		var button := Button.new()
		button.text = "%s  —  %s" % [REGIONS[i].name, "CITY" if REGIONS[i].kind=="city" else "TOWN"]
		button.custom_minimum_size.y = 42
		stack.add_child(button)
		destination_buttons.append(button)
		var destination: int = i
		button.pressed.connect(func(): travel_to(destination,travel_by_air))
	var close := Button.new()
	close.text = "CLOSE MAP"
	close.custom_minimum_size.y = 42
	stack.add_child(close)
	close.pressed.connect(_close_travel)

func _refresh_destinations() -> void:
	for i in range(destination_buttons.size()):
		var method: String = "FLY" if travel_by_air else "TAXI"
		destination_buttons[i].text = "%s TO %s" % [method,REGIONS[i].name.to_upper()]

func _open_travel() -> void:
	_refresh_destinations()
	travel_panel.visible = true
	get_tree().paused = false

func _close_travel() -> void:
	if is_instance_valid(travel_panel): travel_panel.visible = false

func _taxi_local() -> void:
	if taxi_active: return
	taxi_active = true
	var cab := CharacterBody3D.new()
	cab.name = "CityTaxi"
	cab.position = player.global_position + Vector3(4,0,4)
	var body := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(2.1,0.8,4.0)
	mesh.material = _material(Color(0.88,0.68,0.12))
	body.mesh = mesh
	body.position.y = 0.75
	cab.add_child(body)
	get_parent().add_child(cab)
	radio_message.emit("TAXI DISPATCH: Your cab is pulling up. Please wait.")
	await get_tree().create_timer(1.5).timeout
	if is_instance_valid(cab): cab.queue_free()
	travel_to(active_region,false)
	taxi_active = false
