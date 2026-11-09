extends CharacterBody3D

enum CombatState { PATROL, ALERT, CHASE, ATTACK, DEAD }
@export var walk_speed: float = 1.65
@export var chase_speed: float = 3.15
@export var detection_range: float = 23.0
@export var attack_range: float = 2.15
@export var max_health: int = 100
var health: int = 100
var target: Node3D
var state: CombatState = CombatState.PATROL
var attack_timer: float = 0.0
var alert_timer: float = 0.0
var patrol_clock: float = 0.0
var gravity: float = 22.0
var left_arm: Node3D
var right_arm: Node3D
var left_leg: Node3D
var right_leg: Node3D
var walk_clock: float = 0.0
var spawn_position: Vector3
var hit_flash: float = 0.0

func _ready() -> void:
	health = max_health
	spawn_position = global_position
	left_arm = get_node_or_null("Arm_-1") as Node3D
	right_arm = get_node_or_null("Arm_1") as Node3D
	left_leg = get_node_or_null("Leg_-1") as Node3D
	right_leg = get_node_or_null("Leg_1") as Node3D

func _physics_process(delta: float) -> void:
	if state == CombatState.DEAD: return
	attack_timer = maxf(0.0, attack_timer - delta)
	alert_timer = maxf(0.0, alert_timer - delta)
	hit_flash = maxf(0.0, hit_flash - delta)
	if not is_instance_valid(target):
		velocity = Vector3.ZERO
		return
	var offset := target.global_position - global_position
	offset.y = 0.0
	var distance := offset.length()
	if distance <= detection_range and state == CombatState.PATROL:
		state = CombatState.ALERT
		alert_timer = 0.55
	elif state == CombatState.ALERT and alert_timer <= 0.0:
		state = CombatState.CHASE
	if state == CombatState.ALERT:
		velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta)
	elif distance <= attack_range:
		state = CombatState.ATTACK
		velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta)
		if attack_timer <= 0.0 and target.has_method("take_damage"):
			attack_timer = 1.15
			target.take_damage(7)
	elif distance <= detection_range or state == CombatState.CHASE:
		state = CombatState.CHASE
		var direction := offset.normalized()
		velocity.x = direction.x * chase_speed
		velocity.z = direction.z * chase_speed
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), 8.0 * delta)
	else:
		state = CombatState.PATROL
		patrol_clock += delta
		var patrol_target := spawn_position + Vector3(sin(patrol_clock * 0.45) * 2.4, 0, cos(patrol_clock * 0.35) * 1.5)
		var patrol_direction := patrol_target - global_position
		patrol_direction.y = 0
		if patrol_direction.length() > 0.2:
			patrol_direction = patrol_direction.normalized()
			velocity.x = patrol_direction.x * walk_speed
			velocity.z = patrol_direction.z * walk_speed
			rotation.y = lerp_angle(rotation.y, atan2(-patrol_direction.x, -patrol_direction.z), 5.0 * delta)
	if distance > 0.1 and state == CombatState.ATTACK:
		rotation.y = lerp_angle(rotation.y, atan2(-offset.x, -offset.z), 10.0 * delta)
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0
	var speed := Vector2(velocity.x, velocity.z).length()
	walk_clock += delta * 8.0
	var gait := sin(walk_clock) * clampf(speed / chase_speed, 0.0, 1.0)
	if left_arm: left_arm.rotation.x = gait * 0.38
	if right_arm: right_arm.rotation.x = -gait * 0.38
	if left_leg: left_leg.rotation.x = -gait * 0.55
	if right_leg: right_leg.rotation.x = gait * 0.55
	move_and_slide()

func take_damage(amount: int) -> void:
	if state == CombatState.DEAD: return
	health = maxi(0, health - amount)
	state = CombatState.CHASE
	if is_instance_valid(target):
		var away := global_position - target.global_position
		away.y = 0
		if away.length() > 0.01:
			velocity += away.normalized() * 2.2
	if health <= 0:
		state = CombatState.DEAD
		velocity = Vector3.ZERO
		var fade := create_tween()
		fade.tween_property(self, "scale", Vector3(0.01, 0.01, 0.01), 0.28)
		fade.tween_callback(queue_free)
