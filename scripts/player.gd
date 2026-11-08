extends CharacterBody3D
@export var move_speed := 6.0
@export var health := 100
var gravity := 22.0
var cooldown := 0.0
var camera: Camera3D
func _ready() -> void:
	var pivot := Node3D.new()
	pivot.position = Vector3(0, 1.55, 0)
	add_child(pivot)
	camera = Camera3D.new()
	camera.position = Vector3(0, 2.1, 6.5)
	camera.rotation_degrees.x = -13
	camera.current = true
	pivot.add_child(camera)
func _physics_process(delta: float) -> void:
	cooldown = maxf(0.0, cooldown - delta)
	var v := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var d := Vector3(v.x, 0, v.y)
	if d.length() > 0.1:
		d = d.normalized()
		velocity.x = d.x * move_speed
		velocity.z = d.z * move_speed
		rotation.y = lerp_angle(rotation.y, atan2(-d.x, -d.z), 10.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed * 7 * delta)
		velocity.z = move_toward(velocity.z, 0, move_speed * 7 * delta)
	velocity.y = velocity.y - gravity * delta if not is_on_floor() else 0.0
	move_and_slide()
func take_damage(amount: int) -> void:
	health = maxi(0, health - amount)
func shoot() -> void:
	if cooldown > 0: return
	cooldown = 0.35
	var origin := camera.global_position
	var query := PhysicsRayQueryParameters3D.create(origin, origin + -camera.global_transform.basis.z * 45.0)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty() and hit.collider.has_method("take_damage"):
		hit.collider.take_damage(50)
