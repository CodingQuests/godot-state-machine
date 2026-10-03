# Short stagger after getting hit. Holds for stun_time while the knockback
# fades, then back to Chase.
extends State

@export var stun_time: float = 0.3
var _timer: float = 0.0

func enter() -> void:
	_timer = stun_time
	actor.flash()

func physics_update(delta: float) -> void:
	_timer -= delta
	actor.velocity = actor.velocity.move_toward(Vector2.ZERO, 600.0 * delta)
	actor.move_and_slide()
	if _timer <= 0.0:
		transitioned.emit("Chase")
