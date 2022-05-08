extends KinematicBody2D

onready var player = get_node("AnimationPlayer")
onready var gunRotation = get_node("GunRotation")
onready var bulletPosition = get_node("GunRotation/Position2D")

const UP = Vector2(0, -1)
const GRAVITY = 20
const MAXFALLSPEED = 200
const MAXSPEED = 80
const JUMPFORCE = 300
const ACCELERATION = 10

var motion = Vector2()
var jumpsLeft = 2
var bulletSpeed = 300
var bullet = preload("res://Scenes/Bullet.tscn")

var unStopableAnimations = ["Attack", "Couch"]
onready var defaultBulletPosition = bulletPosition.position
onready var couchBulletPosition = bulletPosition.position + Vector2(0, 6)
onready var couchBulletPosition1 = bulletPosition.position + Vector2(0, -6)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func initCalc():
	motion.y += GRAVITY
	motion.y = min(MAXFALLSPEED, motion.y)
	motion.x = clamp(motion.x, -MAXSPEED, MAXSPEED)
	
	if is_on_floor():
		jumpsLeft = 2

func _physics_process(_delta):
	initCalc()
	
	if Input.is_action_pressed("attack"):
		shoot()
	if Input.is_action_pressed("couch"):
		motion.x = lerp(motion.x, 0, 0.2)
	if Input.is_action_just_released("couch"):
		bulletPosition.position = defaultBulletPosition
	
	if Input.is_action_pressed("couch"):
		if Input.is_action_pressed("attack"):
			couch("gun")
		else:
			couch("normal")
	elif Input.is_action_pressed("attack") and Input.is_action_pressed("right"):
		runAndGun("right")
	elif Input.is_action_pressed("attack") and Input.is_action_pressed("left"):
		runAndGun("left")
	elif Input.is_action_pressed("right"):
		moveHorizontal("right")
	elif Input.is_action_pressed("left"):
		moveHorizontal("left")
	else:
		if Input.is_action_pressed("attack"):
			player.play("Attack")
		motion.x = lerp(motion.x, 0, 0.2)
		if unStopableAnimations.find(player.current_animation) == -1:
			player.play("Idle")
	
	if Input.is_action_just_pressed("jump"):
		if !is_on_floor() and jumpsLeft > 0:
			motion.y = -JUMPFORCE
		elif is_on_floor():
			motion.y = -JUMPFORCE;
		jumpsLeft -= 1
	
	if !is_on_floor():
		if motion.y < 0:
			if Input.is_action_pressed("attack"):
				player.play("JumpAndGun")
			else:
				player.play("Jump")
		elif motion.y > 0:
			player.play("Fall")
	
	motion = move_and_slide(motion, UP)

func couch(action):
	match action:
		"normal":
			player.play("Couch")
		"gun":
			player.play("CouchAndGun")
	#Change the gun position
	if $Sprite.flip_h:
		bulletPosition.position = couchBulletPosition1
	else:
		bulletPosition.position = couchBulletPosition

func changeFacing(direction):
	match direction:
		"right":
			$Sprite.flip_h = false
			gunRotation.rotation_degrees = 0
		"left":
			$Sprite.flip_h = true
			gunRotation.rotation_degrees = 180

func motionUpdate(direction):
	changeFacing(direction)
	match direction:
		"right":
			motion.x += ACCELERATION
		"left":
			motion.x -= ACCELERATION

func moveHorizontal(direction):
	motionUpdate(direction)
	player.play("Run")

func runAndGun(direction):
	motionUpdate(direction)
	if direction == "right" or direction == "left":
		player.play("RunAndGun")

func shoot():
	var bulletInstance = bullet.instance()
	
	bulletInstance.position = bulletPosition.global_position
	bulletInstance.rotation = gunRotation.rotation
	bulletInstance.apply_impulse(Vector2(), Vector2(bulletSpeed, 0).rotated(gunRotation.rotation))
	
	get_tree().get_root().call_deferred("add_child", bulletInstance)
