extends Actor

const trail_scene = preload("res://src/Helpers/Trail.tscn")
const _JUMP_EVENT = "Jump"
const COMBOTIME = 1;
const _LEFT_FACING_SCALE = -1.0
const _RIGHT_FACING_SCALE = 1.0

var _isAttacking: bool = false
var _beingHurt: bool = false
var _canTakeDamage: bool = false
var _directionFacing: Vector2 = Vector2.ZERO
var _trail = []
var _invincibilityTimer: Timer = Timer.new()
var _attackPoints = 3;
var _attackResetTimer: Timer = Timer.new()

onready var sprite: Sprite = $Sprite
onready var rightHitBox: CollisionShape2D = $attack/sideSwipeRight

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_invincibilityTimer.connect("timeout",self,"_on_invincibility_timeout") 
	_invincibilityTimer.one_shot = true
	add_child(_invincibilityTimer)
	
	_attackResetTimer.connect("timeout",self,"_on_combo_timeout") 
	_attackResetTimer.one_shot = true
	add_child(_attackResetTimer)
	
	_invincibilityTimer.start(3)
	
	_maxHealth = 10
	_health = _maxHealth
	_acceleration = .1
	_speed = 200
	_directionFacing.x = .1;
	$TrailTimer.connect("timeout", self, "add_trail")
	$AnimationTree.active = true


func _physics_process(_delta: float) -> void:
	var direction = Vector2.ZERO
	
	if !_canTakeDamage:
		self.modulate =  Color(2,2,2,2) if Engine.get_frames_drawn() % 5 == 0 else Color(1,1,1,1)
	
	if(!_isAttacking):
		direction = evaluatePlayerInput()
		
	if(!_beingHurt):
		_velocity = getMovement(direction, _speed, _acceleration)
		_velocity = move_and_slide(_velocity)


func _on_invincibility_timeout() -> void:
	self.modulate = Color(1,1,1,1)
	_canTakeDamage = true
	
	
func _on_combo_timeout() -> void:
	print("combo reset")
	_attackPoints = 3


func add_trail() -> void:
	if(get_parent() != null):
		var trail      = trail_scene.instance()
		trail.player   = self
		trail.position = self.position
		get_parent().add_child(trail)
		_trail.push_front(trail)


func take_damage(damage: int, direction: Vector2, force: float) -> void:
	if _canTakeDamage:
		_canTakeDamage = false
		_beingHurt = true
		print("call hurt logic")
		$AnimationTree.get("parameters/playback").travel("Hurt")
		_invincibilityTimer.start(2)
		.take_damage(damage, direction, force)

# callback function to for when the hurt animation is playing
func setHurtAnimationPlaying():
	print("play hurt animation")
	#_beingHurt = true

func evaluatePlayerInput() -> Vector2:
	#get direction for inputs
	var direction = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)
	if(direction != Vector2.ZERO):
		_directionFacing = direction
	
	if direction.x < 0:
		rightHitBox.position.x = -abs(rightHitBox.position.x)
		sprite.flip_h = true
	elif direction.x > 0:
		rightHitBox.position.x = abs(rightHitBox.position.x)
		sprite.flip_h = false
	
	if _beingHurt:
		return Vector2.ZERO
		
	#check attack inputs
	if Input.is_action_just_pressed("side_swipe_attack") or Input.is_action_pressed("side_swipe_attack"):
		doSideSwipeAttack()
		return Vector2.ZERO
		
	#set animation for direction and return for movement
	if direction == Vector2.ZERO:
		$AnimationTree.get("parameters/playback").travel("Idle")
	else:
		$AnimationTree.get("parameters/playback").travel("Walk")
	return direction


func doSideSwipeAttack():
	_isAttacking = true
	_attackResetTimer.start(COMBOTIME)
	print("Going to attack with " + String(_attackPoints))
	if _attackPoints == 3:
		$AnimationTree.get("parameters/playback").travel("SideSwipe1")
		_attackPoints = _attackPoints - 1
	elif _attackPoints == 2:
		$AnimationTree.get("parameters/playback").travel("SideSwipe2")
		_attackPoints = _attackPoints - 1
	elif _attackPoints == 1:
		$AnimationTree.get("parameters/playback").travel("SideSwipeKick")
		_attackPoints = _attackPoints - 1
	else:
		_attackPoints = 3
		_isAttacking = false


func _finishedAttack() -> void:
	print("attack finished")
	_isAttacking = false


# callback function for when hurt animation is done
func _hurtAnimationFinished() -> void:
	print("hurt animation done")
	_beingHurt = false


func _on_attack_area_entered(area: Area2D) -> void:
	if area.is_in_group("hurtbox") && area.get_parent() != null && area.get_parent().has_method("take_damage"):
		area.get_parent().take_damage(1, _directionFacing, 50000)


func sendPlayerDeadSignal():
	#restarting game, instead of sending signal
	get_tree().reload_current_scene()
