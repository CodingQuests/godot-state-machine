# Wander in a random direction for roam_time, then go back to Idle. Spotting the
# player jumps straight to Chase.
extends State

@export var roam_speed: float = 35.0
@export var roam_time: float = 2.0
var _timer: float = 0.0
var _dir: Vector2 = Vector2.RIGHT

func enter() -> void:
	_timer = roam_time
	var dirs := [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]
	_dir = dirs[randi() % dirs.size()]

func physics_update(delta: float) -> void:
	if actor.detection.can_see(actor.target):
		transitioned.emit("Chase")
		return
	_timer -= delta
	actor.velocity = _dir * roam_speed
	actor.move_and_slide()
	if _timer <= 0.0:
		transitioned.emit("Idle")
