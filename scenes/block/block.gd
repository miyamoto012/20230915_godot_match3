class_name Block
extends Node2D

@export var _color: String = ""

var _matched: bool = false

@onready var color_rect = $ColorRect


func get_color()->String:
	return _color

	
func set_matched(value: bool)->void:
	_matched = value


func get_matched()->bool:
	return _matched
