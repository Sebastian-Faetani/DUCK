extends CharacterBody3D

class_name Enemy

@onready var animated_sprite_3d = $AnimatedSprite3D

@export var move_speed = 6.0
@export var attack_range = 2.0
@export var enemy_max_health = 20
@onready var enemy_current_health = enemy_max_health
@export var enemyDamage = 0.001

@onready var player : CharacterBody3D = get_tree().get_first_node_in_group("player")
var enemyDead = false

func _ready():
	animated_sprite_3d.animation_finished.connect(queue_free)

func _physics_process(_delta):
	if enemyDead:
		return
	if player == null:
		return
	
	var dir = player.global_position - global_position
	dir.y = 0.0
	dir = dir.normalized()
	
	velocity = dir * move_speed
	move_and_slide()
	attempt_to_kill_player()

#KillingPlayer
func attempt_to_kill_player():
	var dist_to_player = global_position.distance_to(player.global_position)
	if dist_to_player > attack_range:
		return
	
	var eye_line = Vector3.UP * 1.5
	var query = PhysicsRayQueryParameters3D.create(global_position+eye_line, player.global_position+eye_line, 1)
	var result = get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		player.takeDamage()

func enemyTakeDamage(dmg_amount):
	enemy_current_health -= dmg_amount
	if enemy_current_health <= 0:
		enemyDeath()

func enemyDeath():
	enemyDead = true
	$DeathSound.play()
	animated_sprite_3d.play("death")
	$CollisionShape3D.disabled = true

