extends CharacterBody3D
class_name Enemy

@export var speed = 5.0
@export var attack_range := 1.5
@export var cooldown_time = 1
@export var dance_time = 5
@export var max_hp = 30
@export var attack_damage := 20

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var navigation_agent_3d = $NavigationAgent3D
@onready var animated_sprite_3d = $AnimatedSprite3D
@onready var attack_cooldown = $AttackCooldown
@onready var dance_timer = $DanceTimer
@onready var animation_tree = $AnimationTree
@onready var playback: AnimationNodeStateMachinePlayback = animation_tree["parameters/playback"]

@onready var randomPos = Vector3(randf_range(-75, 50), position.y, randf_range(-85, 20))
@onready var wanderTimer = 60.0

var lastPos

var player
var distance
var provoked := false
var aggro_range := 15.0
var see_range := 30.0
var can_move := true
var can_attack := true
var enemyDead: = false
var hp: int = max_hp:
	set(value):
		hp = value
		if hp <= 0:
			enemyDead = true
			can_move = false
			provoked = false
			playback.travel("death")
			await animated_sprite_3d.animation_finished
			queue_free()


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")


func _process(delta):
	if provoked == false and can_move == true:
		patrol(delta)
	if provoked == true:
		chase()
	

func _physics_process(delta):
	if enemyDead == true:
		return
	var next_position = navigation_agent_3d.get_next_path_position()
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta


	var direction = global_position.direction_to(next_position)
	distance = global_position.distance_to(player.global_position)
	
	if distance < aggro_range:
		provoked = true
	elif distance > see_range:
		provoked = false
	
	if distance <= attack_range and can_attack == true:
		can_move = false
		can_attack = false
		playback.travel("attack")
		attack_cooldown.start(cooldown_time)
		
		
		
	elif distance > attack_range:
		can_move = true
	
	#if can_move == true:
		#playback.travel("idle")
	
	if provoked == false:
		dance_timer.start(dance_time)
	
	if direction:
		look_at_target(direction)
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	if can_move == true:
		move_and_slide()


func look_at_target(direction: Vector3) -> void:
	var adjusted_direction = direction
	adjusted_direction.y = 0
	look_at(global_position + adjusted_direction, Vector3.UP, true)

func attack() -> void:
	if distance <= attack_range:
		print("damage")
		player.CURRENT_PLAYER_HEALTH -= attack_damage

func chase():
	navigation_agent_3d.target_position = player.global_position

func patrol(delta):
	provoked = false
	navigation_agent_3d.target_position = randomPos
	if (abs(randomPos.x - global_position.x) <= 5 and abs(randomPos.z - global_position.z) <= 5)  or wanderTimer <= 0:
		randomPos = Vector3(randf_range(player.global_position.x-40, player.global_position.x+40), position.y, randf_range(player.global_position.z-40, player.global_position.z+40))
		clamp(randomPos.x, -75, 50)
		clamp(randomPos.z, -85, 20)
		wanderTimer = 60.0
	wanderTimer -= delta

func enemyTakeDamage(dmg_amount):
	provoked = true
	hp -= dmg_amount

func _on_attack_cooldown_timeout():
	can_attack = true


func _on_dance_timer_timeout():
	can_move = false
	if provoked == false:
		playback.travel("dance")
