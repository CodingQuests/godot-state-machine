extends CharacterBody2D
## Demo player: WASD to move, Space or left click to swing. The swing hits any
## slime in front of you, which forces that slime's machine into Hitstun.

signal health_changed(current: int)

@export var speed: float = 130.0
@export var max_health: int = 100
const SWING_RANGE := 40.0
const SWING_ARC := 1.2
const SWING_COOLDOWN := 0.35

var health: int = 100
var facing := Vector2.RIGHT
var _cooldown := 0.0
var _knockback := Vector2.ZERO

@onready var sprite: Sprite2D = $Sprite2D
@onready var blade: Node2D = $Blade


func _ready() -> void:
	add_to_group("player")
	health = max_health


func _physics_process(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	if health <= 0:
		return
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if dir != Vector2.ZERO:
		facing = dir.normalized()
		if absf(dir.x) > 0.1:
			sprite.flip_h = dir.x < 0.0
	velocity = dir * speed + _knockback
	_knockback = _knockback.move_toward(Vector2.ZERO, 900.0 * delta)
	move_and_slide()
	blade.rotation = facing.angle()
	if Input.is_action_just_pressed("attack") and _cooldown <= 0.0:
		_swing()


func _swing() -> void:
	_cooldown = SWING_COOLDOWN
	blade.scale = Vector2(1.4, 1.4)
	create_tween().tween_property(blade, "scale", Vector2.ONE, 0.15)
	for node in get_tree().get_nodes_in_group("slimes"):
		var slime := node as Node2D
		var to: Vector2 = slime.global_position - global_position
		if to.length() <= SWING_RANGE and absf(to.angle_to(facing)) <= SWING_ARC:
			slime.take_hit(global_position, 1)


## Called by the slime's Attack state when its landing hits us.
func take_damage(amount: int) -> void:
	if health <= 0:
		return
	health = maxi(0, health - amount)
	health_changed.emit(health)
	sprite.modulate = Color(3, 1, 1)
	create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.2)


## Called by the slime's Attack state: a shove away from where it landed.
func apply_hit(from_position: Vector2, _amount: int) -> void:
	_knockback = (global_position - from_position).normalized() * 220.0
