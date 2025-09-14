extends Label


var coins: int = 0


func _on_coin_collected() -> void:
	coins += 1
	text = "Coin: %d" % coins
