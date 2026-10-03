# Pathfind toward the player, routing around obstacles via the NavigationAgent.
# Once we have aggro we stay locked on: only give up if the player gets past
# leash_distance. That way a detour around terrain (which briefly grows the gap)
# doesn't make the slime quit halfway. Switch to Attack in leaping range.
extends State

@export var chase_speed: float = 75.0
@export var leash_distance: float = 420.0
## Start the leap attack once the player is this close.
@export var attack_range: float = 80.0

func physics_update(_delta: float) -> void:
	if actor.target == null or not is_instance_valid(actor.target):
		transitioned.emit("Idle")
		return
	var agent: NavigationAgent2D = actor.nav_agent
	# Only re-path when the target actually moves, instead of recomputing the
	# navigation path every single frame.
	var target_pos: Vector2 = actor.target.global_position
	if agent.target_position.distance_to(target_pos) > 8.0:
		agent.target_position = target_pos
	var next_point := agent.get_next_path_position()
	var dir: Vector2 = actor.global_position.direction_to(next_point)
	actor.velocity = dir * chase_speed
	actor.move_and_slide()
	var dist: float = actor.global_position.distance_to(target_pos)
	if dist <= attack_range:
		transitioned.emit("Attack")
	elif dist > leash_distance:
		transitioned.emit("Idle")
