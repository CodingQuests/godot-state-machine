class_name Slime
extends CharacterBody2D
## The body the state machine drives. The active state sets velocity; this
## script only finds the player, flips the sprite, and wires combat into the
## machine: getting hit forces Hitstun, running out of health forces Death.

signal died

@export var max_health: int = 3
@export var knockback_force: float = 260.0
## While recovering from its leap the slime is wide open (the punish window):
## hits do this much more damage and knockback. Driven by the Attack state.
@export var vulnerable_mult: int = 2
@export var vulnerable_knockback: float = 1.8

var vulnerable: bool = false
var health: int = 3
var target: Node2D

@onready var state_machine: StateMachine = $StateMachine
@onready var detection: Node2D = $Detection
@onready var sprite: Sprite2D = $Sprite2D
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D


func _ready() -> void:
	health = max_health
	target = get_tree().get_first_node_in_group("player")


func _process(_delta: float) -> void:
	# The player may not exist yet when we are ready, or may have been replaced.
	if target == null or not is_instance_valid(target):
		target = get_tree().get_first_node_in_group("player")
	if velocity.x != 0.0:
		sprite.flip_h = velocity.x < 0.0


## Called by the player's sword. Forces a transition from outside the machine.
func take_hit(from_position: Vector2, amount: int) -> void:
	if health <= 0:
		return
	health -= amount * (vulnerable_mult if vulnerable else 1)
	var force := knockback_force * (vulnerable_knockback if vulnerable else 1.0)
	velocity = (global_position - from_position).normalized() * force
	if health <= 0:
		state_machine.change_state("Death")
	else:
		state_machine.change_state("Hitstun")


## A quick white flash, used by the Hitstun state.
func flash() -> void:
	sprite.modulate = Color(3, 3, 3)
	create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.15)
