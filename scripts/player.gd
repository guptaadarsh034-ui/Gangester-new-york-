extends CharacterBody3D

@export var move_speed: float = 6.2
@export var sprint_multiplier: float = 1.55
@export var health: int = 100
var gravity: float = 22.0
var cooldown: float = 0.0
var camera: Camera3D
var camera_pivot: Node3D
var camera_yaw: float = 0.0
var camera_pitch: float = -13.0
var in_vehicle: bool = false

func _ready() -> void:
	camera_pivot = Node3D.new()
	camera_pivot.name = "CameraPivot"
	camera_pivot.position = Vector3(0, 1.55, 0)
	add_child(camera_pivot)
	camera = Camera3D.new()
	camera.name = "FollowCamera"
	camera.position = Vector3(0, 2.1, 6.5)
	camera.rotation_degrees.x = camera_pitch
	camera.fov = 72.0
	camera.current = true
	camera_pivot.add_child(camera)

func apply_look(delta_pixels: Vector2) -> void:
	camera_yaw -= delta_pixels.x * 0.0045
	camera_pitch = clampf(camera_pitch - delta_pixels.y * 0.12, -38.0, 18.0)
	camera_pivot.rotation.y = camera_yaw
	camera.rotation_degrees.x = camera_pitch

func _physics_process(delta: float) -> void:
	if in_vehicle:
		velocity = Vector3.ZERO
		return
	cooldown = maxf(0.0, cooldown - delta)
	var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := Vector3(input_vector.x, 0.0, input_vector.y).rotated(Vector3.UP, camera_yaw)
	var speed := move_speed * (sprint_multiplier if Input.is_action_pressed("sprint") else 1.0)
	if direction.length() > 0.08:
		direction = direction.normalized()
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		if not Input.is_action_pressed("aim"):
			rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), 10.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_speed * 7.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, move_speed * 7.0 * delta)
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = 7.0
	elif not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0
	camera.fov = lerpf(camera.fov, 54.0 if Input.is_action_pressed("aim") else 72.0, 9.0 * delta)
	if Input.is_action_pressed("fire"):
		shoot()
	move_and_slide()

func take_damage(amount: int) -> void:
	health = maxi(0, health - amount)

func shoot() -> void:
	if cooldown > 0.0:
		return
	cooldown = 0.28
	var origin := camera.global_position
	var query := PhysicsRayQueryParameters3D.create(origin, origin + -camera.global_transform.basis.z * 70.0)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty() and hit.collider.has_method("take_damage"):
		hit.collider.take_damage(50)
