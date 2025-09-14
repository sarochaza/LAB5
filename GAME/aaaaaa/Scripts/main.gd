# res://Scripts/Main.gd
extends Node

@export var mob_scene: PackedScene
@export var coin_scene: PackedScene
@export var spawnplayer: Marker3D
@onready var player_scene: PackedScene = preload("res://Scenes/player.tscn")

func _ready() -> void:
	$UserInterface/Retry.hide()

func _on_mob_timer_timeout() -> void:
	var mob = mob_scene.instantiate()
	var mob_spawn_location = get_node("SpawnPath/SpawnLocation")
	mob_spawn_location.progress_ratio = randf()

	var player_position = $Player.position
	mob.initialize(mob_spawn_location.position, player_position)
	add_child(mob)

	# ต่อสัญญาณนับคะแนน
	mob.squashed.connect($UserInterface/ScoreLabel._on_mob_squashed.bind())

	# ถ้าต้องการโอกาส 30% ในการเกิดเหรียญ ให้ใช้ < 0.3
	if randf() < 0.3:
		_spawn_coin(mob_spawn_location.position)

func _spawn_coin(spawn_pos: Vector3) -> void:
	if coin_scene == null:
		return
	var coin = coin_scene.instantiate()
	# เหรียญเป็น Area3D → ใช้ global_position
	coin.global_position = spawn_pos

	# ให้เหรียญรู้ตำแหน่ง player (หรือละได้ถ้าไม่ใช้ look_at)
	var player_position = $Player.position
	if "initialize" in coin:
		coin.initialize(spawn_pos, player_position)

	add_child(coin)

	# ต่อสัญญาณนับเหรียญไปที่ CoinLabel
	if coin.has_signal("collected"):
		coin.collected.connect($UserInterface/CoinLabel._on_coin_collected)

func _on_player_hit() -> void:
	$MobTimer.stop()
	$UserInterface/Retry.show()

func _unhandled_input(event) -> void:
	if event.is_action_pressed("ui_accept") and $UserInterface/Retry.visible:
		get_tree().reload_current_scene()

func _on_coin_timer_timeout() -> void:
	# ถ้าคุณยังมีเส้นทาง spawn coin แยกผ่าน PathFollow ก็ทำได้เช่นกัน
	var coin = coin_scene.instantiate()

	var coin_spawn_location = get_node("coinPath/coinFollow3D")
	coin_spawn_location.progress_ratio = randf()

	var player_position = $Player.position
	if "initialize" in coin:
		coin.initialize(coin_spawn_location.position, player_position)

	coin.global_position = coin_spawn_location.position
	add_child(coin)

	if coin.has_signal("collected"):
		coin.collected.connect($UserInterface/CoinLabel._on_coin_collected)
