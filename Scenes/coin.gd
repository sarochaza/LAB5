extends CharacterBody3D

signal collected
func _ready() -> void:
	add_to_group("coin")
	
func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		print("เก็บเหรียญแล้ว!")
		collected.emit()
		$Coinsound.play()
		queue_free()

func collect():
	collected.emit()
	queue_free()
	
func initialize(start_position: Vector3, player_position: Vector3) -> void:
	# กำหนดตำแหน่งเริ่มต้นของเหรียญ
	global_position = start_position

	# ถ้าอยากให้ coin หันไปทาง player
	look_at(player_position, Vector3.UP)

	# ถ้าไม่อยากให้หมุนเลย (อยู่เฉย ๆ) → ลบบรรทัด look_at() ทิ้งได้
