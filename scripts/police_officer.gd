extends CharacterBody3D

var health: int = 120

func take_damage(amount: int) -> void:
	health = maxi(0,health-amount)
	if health <= 0:
		queue_free()
