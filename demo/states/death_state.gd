# Final state. Stops moving, drops loot if a scene is assigned, fades the body
# out, then frees it. There is no way out of this state: nothing transitions.
extends State

@export var loot_scene: PackedScene
## Chance (0..1) to drop loot_scene on death.
@export var drop_chance: float = 0.4

func enter() -> void:
	actor.velocity = Vector2.ZERO
	_drop_loot()
	var sprite: Sprite2D = actor.sprite
	var tween := actor.create_tween().set_parallel(true)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.45)
	tween.tween_property(sprite, "scale", sprite.scale * 1.5, 0.45)
	await tween.finished
	actor.died.emit()
	actor.queue_free()

func _drop_loot() -> void:
	if loot_scene and randf() < drop_chance:
		var loot := loot_scene.instantiate()
		actor.get_parent().add_child(loot)
		loot.global_position = actor.global_position
