extends Node2D
## Spots the player by distance: true when the target is within detection_radius.
## Swap in a raycast if you want line of sight.

@export var detection_radius: float = 110.0


func can_see(target: Node2D) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	return global_position.distance_to(target.global_position) <= detection_radius
