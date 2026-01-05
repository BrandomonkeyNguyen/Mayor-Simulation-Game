class_name Main
extends Node2D

const worldGen = preload("res://scenes/world/world_gen.gd")

func _ready() -> void:
	var seedStr = ""
	if seedStr == "":
		seedStr = str(randi())
	var tileMap = await worldGen.generate_map(seedStr)
	tileMap.apply_scale(Vector2(3,3))
	add_child(tileMap)
