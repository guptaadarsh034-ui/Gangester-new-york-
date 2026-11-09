extends CharacterBody3D
signal crime_committed
signal health_changed(value: int)
signal ammo_changed(current: int, reserve: int)

@export var move_speed: float = 6.2
@export var sprint_multiplier: float = 1.55
@export var health: int = 100
@export var magazine_size: int = 12
@export var reserve_ammo: int = 72
var ammo: int = 12
var gravity: float = 22.0
var cooldown: float = 0.0
var reload_timer: float = 0.0
var camera: Camera3D
var camera_pivot: Node3D
var camera_yaw: float = 0.0
var camera_pitch: float = -13.0
var in_vehicle: bool = false
var left_arm: Node3D
var right_arm: Node3D
var left_leg: Node3D
var right_leg: Node3D
var walk_clock: float = 0.0
var recoil: float = 0.0
var muzzle_flash: MeshInstance3D
var weapon_root: Node3D
var is_dead: bool = false

func _ready() -> void:
	ammo = magazine_size
	camera_pivot = Node3D.new()
	camera_pivot.name = "CameraPivot"
	camera_pivot.position = Vector3(0, 1.58, 0)
	add_child(camera_pivot)
	camera = Camera3D.new()
	camera.name = "FollowCamera"
	camera.position = Vector3(0, 2.1, 6.5)
	camera.rotation_degrees.x = camera_pitch
	camera.fov = 72.0
	camera.current = true
	camera_pivot.add_child(camera)
	left_arm = get_node_or_null("Arm_-1") as Node3D
	right_arm = get_node_or_null("Arm_1") as Node3D
	left_leg = get_node_or_null("Leg_-1") as Node3D
	right_leg = get_node_or_null("Leg_1") as Node3D
	weapon_root = get_node_or_null("WeaponRoot") as Node3D
	muzzle_flash = get_node_or_null("MuzzleFlash") as MeshInstance3D
	if muzzle_flash: muzzle_flash.visible = false
	ammo_changed.emit(ammo, reserve_ammo)

func apply_look(delta_pixels: Vector2) -> void:
	if is_dead: return
	camera_yaw -= delta_pixels.x * 0.0045
	camera_pitch = clampf(camera_pitch - delta_pixels.y * 0.12, -38.0, 18.0)
	camera_pivot.rotation.y = camera_yaw - rotation.y
	camera.rotation_degrees.x = camera_pitch

func _physics_process(delta: float) -> void:
	if in_vehicle or is_dead:
		velocity = Vector3.ZERO
		return
	cooldown = maxf(0.0, cooldown - delta)
	if reload_timer > 0.0:
		reload_timer = maxf(0.0, reload_timer - delta)
		if reload_timer == 0.0:
			var needed: int = magazine_size - ammo
			var loaded: int = mini(needed, reserve_ammo)
			ammo += loaded
			reserve_ammo -= loaded
			ammo_changed.emit(ammo, reserve_ammo)
	var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := Vector3(input_vector.x, 0.0, input_vector.y).rotated(Vector3.UP, camera_yaw)
	var sprinting := Input.is_action_pressed("sprint") and not Input.is_action_pressed("aim")
	var speed := move_speed * (sprint_multiplier if sprinting else 1.0)
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
	var aiming := Input.is_action_pressed("aim")
	camera.fov = lerpf(camera.fov, 54.0 if aiming else 72.0, 9.0 * delta)
	if aiming:
		rotation.y = lerp_angle(rotation.y, camera_yaw, 12.0 * delta)
	if Input.is_action_just_pressed("reload"):
		reload()
	if Input.is_action_pressed("fire"):
		shoot()
	recoil = move_toward(recoil, 0.0, 8.0 * delta)
	if weapon_root:
		weapon_root.rotation.x = -0.08 if aiming else 0.0
		weapon_root.position.z = -0.12 - recoil * 0.12
	if muzzle_flash and muzzle_flash.visible and cooldown > 0.20:
		muzzle_flash.visible = false
	var planar_speed := Vector2(velocity.x, velocity.z).length()
	var stride := clampf(planar_speed / (move_speed * sprint_multiplier), 0.0, 1.0)
	walk_clock += delta * (11.0 if sprinting else 7.5)
	var gait := sin(walk_clock) * stride
	if left_arm: left_arm.rotation.x = gait * (0.42 if not aiming else 0.05)
	if right_arm: right_arm.rotation.x = -gait * (0.42 if not aiming else 0.05) - recoil * 0.25
	if left_leg: left_leg.rotation.x = -gait * 0.62
	if right_leg: right_leg.rotation.x = gait * 0.62
	camera_pivot.rotation.y = camera_yaw - rotation.y
	move_and_slide()

func take_damage(amount: int) -> void:
	if is_dead: return
	health = maxi(0, health - amount)
	health_changed.emit(health)
	if health <= 0:
		is_dead = true
		velocity = Vector3.ZERO

func reload() -> void:
	if reload_timer > 0.0 or ammo >= magazine_size or reserve_ammo <= 0 or is_dead: return
	reload_timer = 1.45
	if weapon_root: weapon_root.rotation.x = -0.55
	ammo_changed.emit(ammo, reserve_ammo)

func shoot() -> void:
	if cooldown > 0.0 or reload_timer > 0.0 or is_dead: return
	if ammo <= 0:
		reload()
		return
	cooldown = 0.28
	ammo -= 1
	ammo_changed.emit(ammo, reserve_ammo)
	recoil = 1.0
	crime_committed.emit()
	if muzzle_flash:
		muzzle_flash.visible = true
		var flash_tween := create_tween()
		flash_tween.tween_interval(0.075)
		flash_tween.tween_callback(_hide_muzzle_flash)
	var origin := camera.global_position
	var query := PhysicsRayQueryParameters3D.create(origin, origin + -camera.global_transform.basis.z * 70.0)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty() and hit.collider.has_method("take_damage"):
		hit.collider.take_damage(50)

func _hide_muzzle_flash() -> void:
	if is_instance_valid(muzzle_flash): muzzle_flash.visible = false
