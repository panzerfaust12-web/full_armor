extends Node

var vehicle_load_array: Array = [[0, "res://entities/hull/hull03_test_wv2000.tscn"], [1, "res://entities/engine/engine03_test_wv2000.tscn"], [2, "res://entities/wheel/wheel02_wz2000.tscn"], [3, "res://entities/wheel/wheel02_wz2000.tscn"], [4, "res://entities/wheel/wheel02_wz2000.tscn"], [5, "res://entities/transmission/trans02_test_wz2000.tscn"]]

var save: ConfigFile = ConfigFile.new()

func _ready() -> void:
	load_game()

func delete_save():
	var clear_save = save.load("user://save.cfg")
	if clear_save != OK:
		print("NO SAVE FILE FOUND")
		return
	save.save("user://save_backup.cfg")
	DirAccess.remove_absolute("user://save.cfg")
	
func save_game():
	var new_save = ConfigFile.new()
	new_save.set_value("Base","vehicle_build", vehicle_load_array)
	new_save.save("user://save.cfg")
	
func load_game():
	var load_save = save.load("user://save.cfg")
	if load_save != OK:
		print("NO SAVE FILE FOUND")
		return
	vehicle_load_array = save.get_value("Base","vehicle_build")
