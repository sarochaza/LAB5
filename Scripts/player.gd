extends CharacterBody3D

# ====== Tunables ======
@export var speed: float = 14.0
@export var fall_acceleration: float = 75.0
@export var jump_impulse: float = 20.0
@export var bounce_impulse: float = 16.0

@export_node_path("AnimationPlayer") var anim_player_path: NodePath
@export var ANIM_WALK: String = "CharacterArmature|Walk"
@export var ANIM_IDLE: String = "CharacterArmature|Idle"
@export var ANIM_DEATH: String = "CharacterArmature|Death"
@export var ANIM_PUNCH_LEFT: String = "CharacterArmature|Punch_Left"
@export var ANIM_PUNCH_RIGHT: String = "CharacterArmature|Punch_Right"
@onready var attack_area: Area3D = $attack
@onready var attack_shape: CollisionShape3D = $attack/CollisionShape3D

signal hit

var target_velocity: Vector3 = Vector3.ZERO
var _can_control: bool = true
var _attacking: bool = false   # กันไม่ให้เคลื่อนไหวตอนต่อย

@onready var _pivot: Node3D = $Pivot
@onready var _anim: AnimationPlayer = null

func _ready() -> void:
	if anim_player_path != NodePath(""):
		_anim = get_node_or_null(anim_player_path)
	else:
		_anim = find_child("AnimationPlayer", true, false)

func _physics_process(delta: float) -> void:
	if not _can_control:
		_apply_gravity(delta)
		velocity = target_velocity
		move_and_slide()
		return

	# ถ้ากำลังต่อยอยู่ ให้หยุด movement
	if _attacking:
		return

	var direction := Vector3.ZERO

	# --- Input Movement ---
	if Input.is_action_pressed("move_right"):
		direction.x += 1.0
	if Input.is_action_pressed("move_left"):
		direction.x -= 1.0
	if Input.is_action_pressed("move_back"):
		direction.z += 1.0
	if Input.is_action_pressed("move_forward"):
		direction.z -= 1.0

	if is_on_floor() and Input.is_action_just_pressed("jump"):
		target_velocity.y = jump_impulse

	# --- Input Attack ---
	if Input.is_action_just_pressed("attack"):
		_play_attack_anim()
		return

	# --- Facing Direction ---
	var moving := false
	if direction != Vector3.ZERO:
		direction = direction.normalized()
		var facing := Vector3(direction.x, 0.0, direction.z)
		_pivot.basis = Basis.looking_at(-facing, Vector3.UP)
		moving = true
	_play_move_anim(moving)

	# --- Ground velocity ---
	target_velocity.x = direction.x * speed
	target_velocity.z = direction.z * speed

	# --- Vertical / gravity ---
	_apply_gravity(delta)

	# --- Move ---
	velocity = target_velocity
	move_and_slide()

	# --- Squash mobs & bounce ---
	for i in range(get_slide_collision_count()):
		var col := get_slide_collision(i)
		if col.get_collider() == null:
			continue
		if col.get_collider().is_in_group("mob"):
			var mob = col.get_collider()
			if Vector3.UP.dot(col.get_normal()) > 0.1:
				mob.squash()
				target_velocity.y = bounce_impulse
				break

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		target_velocity.y -= fall_acceleration * delta

# -------- Animation Helpers --------
func _play_move_anim(moving: bool) -> void:
	if _anim == null or _attacking:
		return
	if moving:
		if _anim.current_animation != ANIM_WALK:
			_anim.play(ANIM_WALK)
	else:
		if _anim.current_animation != ANIM_IDLE:
			_anim.play(ANIM_IDLE)

func _play_attack_anim() -> void:
	if _anim == null:
		return
	_attacking = true

	# เปิด hitbox
	attack_shape.disabled = false

	var anim_name: String
	if randf() < 0.5:
		anim_name = ANIM_PUNCH_LEFT
	else:
		anim_name = ANIM_PUNCH_RIGHT

	_anim.play(anim_name)
	await _anim.animation_finished

	# ปิด hitbox
	attack_shape.disabled = true
	_attacking = false

# -------- Death --------
func die() -> void:
	if not _can_control:
		return
	_can_control = false
	hit.emit()
	target_velocity = Vector3.ZERO

	if _anim != null and _anim.has_animation(ANIM_DEATH):
		_anim.play(ANIM_DEATH)
		await _anim.animation_finished
	queue_free()

func _on_mob_detector_body_entered(_body: Node3D) -> void:
	die()

func _on_attack_body_entered(body: Node3D) -> void:
	if body.is_in_group("mob"):
		if body.has_method("squash"):
			body.squash()


func _on_coin_body_entered(body: Node3D) -> void:
		if body.is_in_group("coin"):
			$Coinsound.play()
			if body.has_method("collect"):
				body.collect()
