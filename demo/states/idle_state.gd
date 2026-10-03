# Stand still for idle_time, then start roaming.
extends State

@export var idle_time: float = 1.5
var _timer: float = 0.0

func enter() -> void:
	_timer = idle_time
	actor.velocity = Vector2.ZERO

func physics_update(delta: float) -> void:
	if actor.detection.can_see(actor.target):
		transitioned.emit("Chase")
		return
	_timer -= delta
	actor.move_and_slide()
	if _timer <= 0.0:
		transitioned.emit("Roam")
