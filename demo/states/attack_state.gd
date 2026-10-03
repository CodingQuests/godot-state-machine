# Leap attack with a wind-up so the player can react. The slime crouches and loads
# up for windup_time (squashing in place, facing its committed jump direction),
# then springs over leap_time seconds, snapped to 8 directions. It only connects on
# the landing frame, via a small circle where it lands, so the jump is dodgeable.
# After landing it recovers, then winds up again while the player is in range, or
# goes back to Chase.
extends State

@export var attack_damage: int = 10
## Telegraph time before the slime springs. Higher = easier to react to.
@export var windup_time: float = 0.45
## How long the jump itself takes, in seconds. Higher = slower, floatier jump.
@export var leap_time: float = 0.7
## How far the slime can leap in one jump, in pixels.
@export var leap_distance: float = 96.0
## Radius of the landing hitbox.
@export var hit_radius: float = 32.0
## How high the slime visually hops at the peak of the jump.
@export var hop_height: float = 14.0
## Pause after landing before winding up again.
@export var cooldown: float = 0.45
## Go back to chasing if the player gets this far away.
@export var leave_range: float = 140.0

enum Phase { WINDUP, LEAP, RECOVER }
var _phase := Phase.WINDUP
var _pt := 0.0
var _dir := Vector2.RIGHT
var _leap_speed := 0.0
var _base_scale := Vector2.ONE
var _have_base := false

func enter() -> void:
	if not _have_base:
		_base_scale = actor.sprite.scale
		_have_base = true
	_begin_windup()

func physics_update(delta: float) -> void:
	match _phase:
		Phase.WINDUP:
			_pt += delta
			actor.velocity = Vector2.ZERO
			actor.move_and_slide()
			# Squash down AND flush red as it charges, so the leap is unmistakable.
			var k: float = clampf(_pt / windup_time, 0.0, 1.0)
			actor.sprite.scale = _base_scale * Vector2(lerpf(1.0, 1.2, k), lerpf(1.0, 0.8, k))
			actor.sprite.modulate = Color.WHITE.lerp(Color(1.9, 0.65, 0.65), k)
			if _pt >= windup_time:
				_begin_leap()
		Phase.LEAP:
			_pt += delta
			if _pt < leap_time:
				actor.velocity = _dir * _leap_speed
				actor.move_and_slide()
				actor.sprite.position.y = -hop_height * sin(PI * _pt / leap_time)
			else:
				_land()
		Phase.RECOVER:
			_pt += delta
			actor.velocity = Vector2.ZERO
			actor.move_and_slide()
			if _pt >= cooldown:
				_decide_next()

func exit() -> void:
	actor.sprite.position.y = 0.0
	actor.sprite.scale = _base_scale
	actor.sprite.modulate = Color.WHITE
	actor.vulnerable = false

func _begin_windup() -> void:
	_phase = Phase.WINDUP
	_pt = 0.0
	actor.vulnerable = false
	# Commit the jump direction and distance now, and face it, so the telegraph is
	# honest and the player can dodge during the wind-up.
	var to_target: Vector2 = actor.target.global_position - actor.global_position
	_dir = _snap8(to_target)
	actor.sprite.flip_h = _dir.x < 0.0
	_leap_speed = clampf(to_target.dot(_dir), 24.0, leap_distance) / leap_time

func _begin_leap() -> void:
	_phase = Phase.LEAP
	_pt = 0.0
	actor.sprite.scale = _base_scale
	actor.sprite.modulate = Color.WHITE

func _land() -> void:
	actor.velocity = Vector2.ZERO
	actor.sprite.position.y = 0.0
	# Small circular hitbox where the slime landed.
	if actor.global_position.distance_to(actor.target.global_position) <= hit_radius:
		if actor.target.has_method("take_damage"):
			actor.target.take_damage(attack_damage)
		if actor.target.has_method("apply_hit"):
			actor.target.apply_hit(actor.global_position, attack_damage)
	# Spent: wide open now. Tint pale-blue (dazed) and take the punish bonus.
	_phase = Phase.RECOVER
	_pt = 0.0
	actor.vulnerable = true
	actor.sprite.modulate = Color(0.7, 0.85, 1.25)

func _decide_next() -> void:
	actor.vulnerable = false
	actor.sprite.modulate = Color.WHITE
	if actor.global_position.distance_to(actor.target.global_position) > leave_range:
		transitioned.emit("Chase")
	else:
		_begin_windup()

# Snap a direction to the nearest of the 8 compass directions.
func _snap8(v: Vector2) -> Vector2:
	if v == Vector2.ZERO:
		return _dir
	var step := PI / 4.0
	return Vector2.RIGHT.rotated(roundf(v.angle() / step) * step)
