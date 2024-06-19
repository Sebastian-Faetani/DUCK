extends CharacterBody3D

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var player : CharacterBody3D = get_tree().get_first_node_in_group("player")
@onready var attack_speed_timer = $AttackSpeedTimer
@onready var hurtbox = $hurtbox

@onready var animated_sprite_3d = $AnimatedSprite3D

@export var move_speed = 6.0
@export var attack_range = 1.5
@export var attack_speed = 2
@export var enemy_max_health = 20
@onready var enemy_current_health = enemy_max_health
@export var enemyDamage = 5

enum ENTITY_STATE {
	PATROLLING,
	DANCE,
	CHASE,
	ATTACK,
}

@export var entity_state = ENTITY_STATE.PATROLLING
var player_overlapping: bool = false

var can_move = true
var enemyDead = false
var provoked := false
var can_attack: bool = true
var aggro_range := 7

@onready var navigation_agent_3d = $NavigationAgent3D


func _ready() -> void:
	pass

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
	
	match entity_state:
		ENTITY_STATE.PATROLLING:
			animated_sprite_3d.play("idle")
			can_move = true
		ENTITY_STATE.DANCE:
			can_move = false
		ENTITY_STATE.CHASE:
			can_move = true
		ENTITY_STATE.ATTACK:
			can_move = false
			if can_attack == true and hurtbox.player_overlapping:
				can_attack = false
				attempt_to_kill_player()
				attack_speed_timer.start(attack_speed); await attack_speed_timer.timeout
				can_attack = true
				entity_state = ENTITY_STATE.PATROLLING
	
	var dir = global_position.direction_to(next_position)
	var distance = global_position.distance_to(player.global_position)
	
	dir.y = 0.0
	dir = dir.normalized()
	if dir:
		look_at_player(dir)
		velocity = dir * move_speed
	move_and_slide()

func look_at_player(direction: Vector3) -> void:
	var adjusted_direction = direction
	adjusted_direction.y = 0
	look_at(global_position + adjusted_direction, Vector3.UP, true)

func attempt_to_kill_player():
	#var dist_to_player = global_position.distance_to(player.global_position)
	#if dist_to_player > attack_range:
		#return
	#
	#var eye_line = Vector3.UP * 1.5
	#var query = PhysicsRayQueryParameters3D.create(global_position+eye_line, player.global_position+eye_line, 1)
	#var result = get_world_3d().direct_space_state.intersect_ray(query)
	#if result.is_empty():
	animated_sprite_3d.play("attack")
	await animated_sprite_3d.animation_finished
	entity_state = ENTITY_STATE.PATROLLING
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
	await animated_sprite_3d.animation_finished
	$enemyBody.disabled = true


func _on_hurtbox_body_entered(body):
	if body.is_in_group("player"):
		provoked = true
		entity_state = ENTITY_STATE.ATTACK
		player_overlapping = true


func _on_hurtbox_body_exited(body):
	pass # Replace with function body.
