extends CharacterBody3D
var health := 100
var target: Node3D
var timer := 0.0
func _physics_process(delta: float) -> void:
	if not is_instance_valid(target) or health <= 0: return
	timer = maxf(0.0, timer - delta)
	var d: Vector3 = target.global_position - global_position
	d.y = 0
	if d.length() > 2.0:
		d = d.normalized()
		velocity.x = d.x * 2.2
		velocity.z = d.z * 2.2
		rotation.y = atan2(-d.x, -d.z)
	else:
		velocity.x = move_toward(velocity.x, 0, 8 * delta)
		velocity.z = move_toward(velocity.z, 0, 8 * delta)
		if timer <= 0:
			timer = 1.3
			target.take_damage(8)
	velocity.y = velocity.y - 22.0 * delta if not is_on_floor() else 0.0
	move_and_slide()
func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0: queue_free()
