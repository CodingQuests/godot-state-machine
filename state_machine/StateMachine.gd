class_name StateMachine
extends Node
## Runs one State at a time. Every child node that extends State is a state, and
## its node name is its state name.
##
## The active state gets update() every frame and physics_update() every physics
## frame. A state leaves by emitting transitioned("NextStateName"), so states
## never hold a reference to each other or to the machine. Outside code (a hit,
## a cutscene) can force a change with change_state("Hitstun").

## Emitted on every change, with both state names. Handy for debug labels.
signal state_changed(from_state: String, to_state: String)

## The state to start in. If empty, the first State child is used.
@export var initial_state: State

var current_state: State


func _ready() -> void:
	for child in get_children():
		if child is State:
			child.actor = get_parent()
			child.transitioned.connect(_on_state_transitioned)
	current_state = initial_state
	if current_state == null:
		for child in get_children():
			if child is State:
				current_state = child
				break
	if current_state == null:
		push_warning("StateMachine: no State children under %s" % get_parent().name)
		return
	# Children are ready before their parent. Wait for the actor, so the first
	# state can use the actor's @onready nodes in enter().
	if not get_parent().is_node_ready():
		await get_parent().ready
	current_state.enter()
	state_changed.emit("", current_state.name)


func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)


func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)


func _on_state_transitioned(state_name: String) -> void:
	var new_state := get_node_or_null(state_name) as State
	if new_state == null or new_state == current_state:
		return
	transition_to(new_state)


## Force a change from outside, by state name.
func change_state(state_name: String) -> void:
	_on_state_transitioned(state_name)


func transition_to(new_state: State) -> void:
	var old_name := ""
	if current_state:
		old_name = current_state.name
		current_state.exit()
	current_state = new_state
	current_state.enter()
	state_changed.emit(old_name, current_state.name)
