extends Control

var active_thing = null:
	set(thing):
		define_thing(thing)

# placeholder obviously, get smartr
var e1 = load("res://entities/engine/engine01_test.tscn")
var e2 = load("res://entities/engine/engine02_test.tscn")
var e3 = load("res://entities/engine/engine03_test_wv2000.tscn")
var e4 = load("res://entities/engine/engine04_test.tscn")
var e5 = load("res://entities/engine/engine05_test.tscn")

var c3 = load("res://entities/cannon/can03_test.tscn")
var c4 = load("res://entities/cannon/can04_test.tscn")
var c5 = load("res://entities/cannon/can05_test.tscn")

var h1 = load("res://entities/hull/hull01_test.tscn")
var h2 = load("res://entities/hull/hull02_test.tscn")
var h3 = load("res://entities/hull/hull01b_test.tscn")
var h4 = load("res://entities/hull/hull03_test_wv2000.tscn")
var h5 = load("res://entities/hull/hull_04_testa1.tscn")
var h6 = load("res://entities/hull/hull_05_testa1.tscn")
var h7 = load("res://entities/hull/hull_06_testa1.tscn")

var t1 = load("res://entities/turret/turret01_test.tscn")
var t2 = load("res://entities/turret/turret02_test.tscn")

var tr1 = load("res://entities/transmission/trans01_test.tscn")
var tr2 = load("res://entities/transmission/trans02_test_wz2000.tscn")

var s3 = load("res://entities/suspension/sus03_overhaul.tscn")

var w1 = load("res://entities/wheel/wheel01_test.tscn")
var w2 = load("res://entities/wheel/wheel02_wz2000.tscn")
var w3 = load("res://entities/wheel/wheel03_wz_idler.tscn")
var w4 = load("res://entities/wheel/wheel03_wz_sprocket.tscn")
var w5 = load("res://entities/wheel/wheel03_wz_tracked.tscn")

@onready var engines: Array = [e1,e2,e3,e4,e5,c3,c4,h1,h2,h3,h4,h5,h6,h7,t1,t2,w1,w2,w3,w4,w5,e1,e2,e3,e4,e5,e1,e2,e3,e4,e5,tr1,tr2]
@onready var guns: Array = [c3,c4]
@onready var hulls: Array = [h1,h2,h3,h4,h5,h6,h7]
@onready var turrets: Array = [t1,t2]
@onready var suspensions: Array = [s3]
@onready var wheels: Array = [w1,w2,w3,w4,w5]
@onready var transmissions: Array = [tr1,tr2]


var part_button = load("res://entities/hud/hud_part_button.tscn")

var part_snapshotter

var categories: Array[String] = ["Engine","Gun","Hull","Turret","Suspension"]




func _ready() -> void:
	populate_parts()
	if active_thing == null:
		$PartWindow/PartSpinner.part_load = e1
		active_thing = $PartWindow/PartSpinner.part
		
	

func populate_parts():
	for i in engines:
		var new_button = part_button.instantiate()
		new_button.part_load = i
		new_button.part_selected.connect(update_thing)
		$ScrollContainer/GridContainer.add_child(new_button)

func update_thing(value):
	var thingupdate = load(value.scene_file_path)
	$PartWindow/PartSpinner.part_load = thingupdate
	active_thing = $PartWindow/PartSpinner.part
	print(value)
	pass

func define_thing(thing):
	$PartName.text = thing.long_name
	$PartDescriptionContainer/PartDescription.text = thing.description
	
	$Header.text = thing.component_name
	$PartStatName1.text = "Weight"
	$PartStatValue1.text = thousands_sep(thing.weight) + "kg"
	$PartStatName2.text = "Dimensions"
	$PartStatValue2.text = thousands_sep(thing.length) + "l + " + thousands_sep(thing.width) + "w + " + thousands_sep(thing.depth) + "h"
	
	
	if thing is Component_Engine:
		$PartStatName3.text = "Horsepower"
		$PartStatValue3.text = str(thing.horsepower)
		$PartStatName4.text = "RPM Idle / RPM Max"
		$PartStatValue4.text = str(thing.RPM_idle) + " / " + str(thing.RPM_max)
		$PartStatName5.text = "RPM Up / RPM Down"
		$PartStatValue5.text = str(thing.RPM_shift_up) + " / " + str(thing.RPM_shift_down)
	
	$ButtonMaster.thing = thing

func thousands_sep(number, prefix=''):
	number = int(number)
	var neg = false
	if number < 0:
		number = -number
		neg = true
	var string = str(number)
	var mod = string.length() % 3
	var res = ""
	for i in range(0, string.length()):
		if i != 0 && i % 3 == mod:
			res += ","
		res += string[i]
	if neg: res = '-'+prefix+res
	else: res = prefix+res
	return res
