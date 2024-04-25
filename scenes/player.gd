extends CharacterBody3D

class_name Player

signal healthChanged

#Bread gund
@onready var animated_sprite_2d = $CanvasLayer/GunBase/AnimatedSprite2D
@onready var shoot_ray = $Head/ShootingRay
@onready var shoot_sound = $ShootSound
var can_shoot = true

#Body functions
@onready var head_bump_check = $HeadBumpCheck
@onready var standing_collision = $StandingCollision
@onready var crouching_collision = $CrouchingCollision
@onready var head = $Head
@export var MOUSE_SENS = 0.5
var dead = false

#Speed and movement
@export var CURRENT_SPEED = 5.0
@export var WALK_SPEED = 5.0
@export var RUN_SPEED = 10.0
@export var CROUCH_SPEED = 3.0
var lerp_speed = 10.0
var direction = Vector3.ZERO
var crouch_depth = -0.5

#States
var walking = false
var sprinting = false
var crouching = false
var sliding = false

#Slide vars
var slide_timer = 0.0
var slide_timer_max = 1.0
var slide_vector = Vector2.ZERO
var SLIDE_SPEED = 13.0

#Life

@export var MAX_PLAYER_HEALTH = 100
@onready var CURRENT_PLAYER_HEALTH: int = MAX_PLAYER_HEALTH
var isHurt: bool = false

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	animated_sprite_2d.animation_finished.connect(shoot_anim_done)
	$CanvasLayer/DeathScreen/Panel/Button.button_up.connect(restart)

func _input(event):
	if dead:
		return
	
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * MOUSE_SENS))
		head.rotate_x(deg_to_rad(-event.relative.y * MOUSE_SENS))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))

func _process(delta):
	healthChanged.emit()
	if Input.is_action_just_pressed("exit"):
		get_tree().quit()
	if Input.is_action_just_pressed("restart"):
		restart()

	if dead:
		return
	if Input.is_action_just_pressed("shoot"):
		shoot()

func _physics_process(delta):
	if dead:
		return
	
	var input_dir = Input.get_vector("move_left", "move_right", "move_foward", "move_backwards")
	
	if Input.is_action_pressed("crouch") || sliding:
		CURRENT_SPEED = CROUCH_SPEED
		head.position.y = lerp(head.position.y, 1.524 + crouch_depth, delta * lerp_speed)
		
		standing_collision.disabled = true
		crouching_collision.disabled = false
		
		#Slide begin logic
		
		if sprinting && input_dir != Vector2.ZERO:
			sliding = true
			slide_timer = slide_timer_max
			slide_vector = input_dir
		
		walking = false
		sprinting = false
		crouching = true
		
	elif !head_bump_check.is_colliding():
		
		standing_collision.disabled = false
		crouching_collision.disabled = true
		
		head.position.y = lerp(head.position.y, 1.524, delta * lerp_speed)
		
		if Input.is_action_pressed("sprint"):
			CURRENT_SPEED = RUN_SPEED
			walking = false
			sprinting = true
			crouching = false
		else:
			CURRENT_SPEED = WALK_SPEED
			walking = true
			sprinting = false
			crouching = false
	
	#Slide Logic
	if sliding:
		slide_timer -= delta
		if slide_timer <= 0:
			sliding = false
	
	direction = lerp(direction,(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta * lerp_speed)
	
	if sliding:
		direction = (transform.basis * Vector3(slide_vector.x, 0, slide_vector.y)).normalized()
	
	if direction:
		velocity.x = direction.x * CURRENT_SPEED
		velocity.z = direction.z * CURRENT_SPEED
		
		if sliding:
			velocity.x = direction.x * slide_timer * SLIDE_SPEED
			velocity.z = direction.z * slide_timer * SLIDE_SPEED
		
	else:
		velocity.x = move_toward(velocity.x, 0, CURRENT_SPEED)
		velocity.z = move_toward(velocity.z, 0, CURRENT_SPEED)
	
	move_and_slide()

func restart():
	get_tree().reload_current_scene()

func shoot():
	if !can_shoot:
		return
	can_shoot = false
	animated_sprite_2d.play("shoot")
	shoot_sound.play()
	if shoot_ray.is_colliding() and shoot_ray.get_collider().has_method("enemyDeath"):
		shoot_ray.get_collider().enemyDeath()

func shoot_anim_done():
	can_shoot = true

func takeDamage():
	CURRENT_PLAYER_HEALTH -= 0.01
	isHurt = true
	healthChanged.emit()
	if CURRENT_PLAYER_HEALTH <= 0:
		playerDeath()

func playerDeath():
	dead = true
	$CanvasLayer/DeathScreen.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

