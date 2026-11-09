extends RefCounted
## Runtime loader for imported CC0 Kenney city assets.
## Assets are downloaded by the Android workflow before Godot's import pass.
const BUILDINGS: Array[String] = [
	"building-type-a.glb","building-type-b.glb","building-type-c.glb","building-type-d.glb",
	"building-type-e.glb","building-type-f.glb","building-type-g.glb","building-type-h.glb",
	"building-type-i.glb","building-type-j.glb","building-type-k.glb","building-type-l.glb",
	"building-type-m.glb","building-type-n.glb","building-type-o.glb","building-type-p.glb",
	"building-type-q.glb","building-type-r.glb","building-type-s.glb","building-type-t.glb",
	"building-type-u.glb"
]
const BUILDING_ROOT := "res://assets/kenney/city-suburban/Models/GLB format/"
const ROAD_ROOT := "res://assets/kenney/city-roads/Models/GLB format/"

static func create_building(parent: Node3D, position: Vector3, target_size: Vector3, seed: int) -> Node3D:
	var filename: String = BUILDINGS[posmod(seed,BUILDINGS.size())]
	var path: String = BUILDING_ROOT + filename
	if not ResourceLoader.exists(path):
		return null
	var packed := load(path) as PackedScene
	if packed == null:
		return null
	var instance := packed.instantiate() as Node3D
	if instance == null:
		return null
	parent.add_child(instance)
	var bounds := AABB()
	var has_bounds := false
	for candidate in instance.find_children("*","MeshInstance3D",true,false):
		var mesh_node := candidate as MeshInstance3D
		if mesh_node == null or mesh_node.mesh == null:
			continue
		var local_transform: Transform3D = instance.global_transform.affine_inverse() * mesh_node.global_transform
		var part: AABB = local_transform * mesh_node.get_aabb()
		bounds = part if not has_bounds else bounds.merge(part)
		has_bounds = true
	if not has_bounds or bounds.size.x <= 0.01 or bounds.size.z <= 0.01:
		instance.queue_free()
		return null
	var factor: float = minf(target_size.x / bounds.size.x,target_size.z / bounds.size.z)
	factor = clampf(factor,0.55,3.2)
	instance.scale = Vector3.ONE * factor
	instance.position = position - Vector3(0,bounds.position.y * factor,0)
	var collider := StaticBody3D.new()
	collider.name = "BuildingCollision"
	collider.position = position + Vector3(0,bounds.size.y * factor * 0.5,0)
	parent.add_child(collider)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(bounds.size.x * factor * 0.82,bounds.size.y * factor,bounds.size.z * factor * 0.82)
	shape.shape = box
	collider.add_child(shape)
	return instance

static func create_prop(parent: Node3D, filename: String, position: Vector3, scale_factor: float = 1.0) -> Node3D:
	var path: String = ROAD_ROOT + filename
	if not ResourceLoader.exists(path):
		return null
	var packed := load(path) as PackedScene
	if packed == null:
		return null
	var instance := packed.instantiate() as Node3D
	if instance == null:
		return null
	parent.add_child(instance)
	instance.position = position
	instance.scale = Vector3.ONE * scale_factor
	return instance
