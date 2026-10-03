extends Node2D
## The demo arena: a navigation region, three slimes, a player, a label over
## each slime showing its current state, and a log of the last transitions.
## Dead slimes come back after a few seconds. Everything in demo/ is
## scaffolding; the state machine itself is state_machine/.

const ROOM := Rect2(-176, -120, 352, 240)
const SLIME := preload("res://demo/Slime.tscn")
const LOG_LINES := 8

@onready var _log: Label = $UI/Log
@onready var _hp: Label = $UI/HP

var _lines: Array[String] = []
var _spawns: Dictionary = {}


func _ready() -> void:
	_build_navigation()
	$Player.health_changed.connect(_on_player_health)
	_on_player_health($Player.health)
	for slime in $Slimes.get_children():
		_spawns[slime.name] = slime.position
		_watch(slime)


## An open room: one rectangle the NavigationAgent2Ds can path across.
func _build_navigation() -> void:
	var poly := NavigationPolygon.new()
	var r := ROOM.grow(-14.0)
	poly.vertices = PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
	poly.add_polygon(PackedInt32Array([0, 1, 2, 3]))
	$NavigationRegion2D.navigation_polygon = poly


func _watch(slime: Slime) -> void:
	var label: Label = slime.get_node("StateLabel")
	# The machine already entered its first state during the slime's ready.
	if slime.state_machine.current_state:
		label.text = slime.state_machine.current_state.name
	slime.state_machine.state_changed.connect(func(from_state: String, to_state: String):
		label.text = to_state
		if from_state != "":
			_add_line("%s: %s > %s" % [slime.name, from_state, to_state]))
	slime.died.connect(_respawn.bind(slime.name))


func _respawn(slime_name: String) -> void:
	await get_tree().create_timer(3.0).timeout
	var slime: Slime = SLIME.instantiate()
	slime.name = slime_name
	slime.position = _spawns[slime_name]
	$Slimes.add_child(slime)
	_watch(slime)


func _add_line(text: String) -> void:
	_lines.push_front(text)
	if _lines.size() > LOG_LINES:
		_lines.resize(LOG_LINES)
	_log.text = "Transitions\n" + "\n".join(_lines)


func _on_player_health(current: int) -> void:
	_hp.text = "HP %d" % current if current > 0 else "You fell. Press R to restart."


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key and key.pressed and not key.echo and key.keycode == KEY_R:
		get_tree().reload_current_scene()


func _draw() -> void:
	draw_rect(ROOM, Color(0.11, 0.1, 0.13))
	var x := ROOM.position.x
	while x <= ROOM.end.x:
		draw_line(Vector2(x, ROOM.position.y), Vector2(x, ROOM.end.y), Color(1, 1, 1, 0.05))
		x += 32.0
	var y := ROOM.position.y
	while y <= ROOM.end.y:
		draw_line(Vector2(ROOM.position.x, y), Vector2(ROOM.end.x, y), Color(1, 1, 1, 0.05))
		y += 32.0
	draw_rect(ROOM, Color(0.45, 0.4, 0.5), false, 3.0)
