extends Node

const SAVE_PATH := "user://egg_heist_save.json"
var data: Dictionary = {
	"cash": 25000.0,
	"speed": 900.0,
	"farm_level": 1,
	"treadmill_level": 1,
	"trail_level": 0,
	"pets": []
}

func _ready() -> void:
	load_data()

func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		for k in data.keys():
			if parsed.has(k):
				data[k] = parsed[k]

func save_data() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))

func add_cash(amount: float) -> void:
	data.cash = float(data.cash) + amount
	save_data()

func spend(amount: float) -> bool:
	if float(data.cash) < amount:
		return false
	data.cash = float(data.cash) - amount
	save_data()
	return true

func add_speed(amount: float) -> void:
	data.speed = float(data.speed) + amount
	save_data()

func farm_capacity() -> int:
	return 5 + int(data.farm_level)
