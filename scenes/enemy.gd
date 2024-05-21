extends CharacterBody3D

class_name Enemy

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var navigation_agent_3d = $NavigationAgent3D

@onready var animated_sprite_3d = $AnimatedSprite3D

@export var move_speed = 6.0
@export var attack_range = 1.5
@export var enemy_max_health = 20
@onready var enemy_current_health = enemy_max_health
@export var enemyDamage = 0.001

@onready var player : CharacterBody3D = get_tree().get_first_node_in_group("player")
var enemyDead = false
var provoked := false
var aggro_range := 12.0

func _ready() -> void:
	animated_sprite_3d.animation_finished.connect(queue_free)

func _process(_delta: float) -> void:
	if provoked:
		navigation_agent_3d.target_position = player.global_position
	
func _physics_process(delta: float) -> void:
	var next_position = navigation_agent_3d.get_next_path_position()
	if enemyDead:
		return
	if player == null:
		return
	
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	var dir = global_position.direction_to(next_position)
	var distance = global_position.distance_to(player.global_position)
	
	if distance <= aggro_range:
		provoked = true
	
	dir.y = 0.0
	dir = dir.normalized()
	if dir:
		look_at_player(dir)
		velocity = dir * move_speed
	move_and_slide()
	attempt_to_kill_player()

func look_at_player(direction: Vector3) -> void:
	var adjusted_direction = direction
	adjusted_direction.y = 0
	look_at(global_position + adjusted_direction, Vector3.UP, true)

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
	provoked = true
	enemy_current_health -= dmg_amount
	if enemy_current_health <= 0:
		enemyDeath()

func enemyDeath():
	enemyDead = true
	$DeathSound.play()
	animated_sprite_3d.play("death")
	$CollisionShape3D.disabled = true

