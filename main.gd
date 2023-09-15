extends Node

#最大列数
const WIDTH: int = 7
#最大行数
const HEIGHT: int = 7

const OFFSET: int = 70
const Y_OFFSET: int = -2


#Blockを配置しない座標を集めた配列
var empty_grids: Array[Vector2i] = [
	Vector2i(0, 0),
	Vector2i(0, 6),
	Vector2i(6, 0),
	Vector2i(6, 6),
	Vector2i(2, 3),
	Vector2i(3, 3),
	Vector2i(4, 3),
]

var all_blocks = []


@onready var x_start = ((get_window().size.x / 2.0) - ((WIDTH/2.0) * OFFSET ) + (OFFSET / 2))
@onready var y_start = ((get_window().size.y / 2.0) + ((HEIGHT/2.0) * OFFSET ) - (OFFSET / 2))

@onready var spawn_block_list: Array = [
	preload("res://scenes/block/block_blue.tscn"),
	preload("res://scenes/block/block_green.tscn"),
	preload("res://scenes/block/block_pink.tscn"),
	preload("res://scenes/block/block_red.tscn"),
	preload("res://scenes/block/block_yellow.tscn"),
]

func _ready()->void:
	randomize()
	all_blocks = initialize_2d_array()
	spawn_dots()

	
func initialize_2d_array()->Array:
	var array = []
	for i_c in WIDTH:
		array.append([])
		for i_r in HEIGHT:
			array[i_c].append(null)
	return array


func spawn_dots():
	for i_c in WIDTH:
		for i_r in HEIGHT:
			if !empty_grids.has(Vector2i(i_c, i_r)):
				var block_instance: Block = spawn_block_list.pick_random().instantiate()
				var loops: int = 0
				#　配置するdotがマッチしていれば置きなおし
				while (match_at(i_c, i_r, block_instance.get_color()) && loops < 100):
					loops += 1
					block_instance = spawn_block_list.pick_random().instantiate()
				add_child(block_instance)
				block_instance.position = grid_to_pixel(i_c, i_r)
				all_blocks[i_c][i_r] = block_instance
			

func match_at(column: int, row: int, color: String)->bool:
	if column > 1:
		if all_blocks[column - 1][row] != null && all_blocks[column - 2][row] != null:
			if all_blocks[column - 1][row].get_color() == color && all_blocks[column - 2][row].get_color() == color:
				return true
	if row > 1:
		if all_blocks[column][row - 1] != null && all_blocks[column][row - 2] != null:
			if all_blocks[column][row - 1].get_color() == color && all_blocks[column][row - 2].get_color() == color:
				return true
	return false


#グリッド座標からグローバル座標へ変換する
func grid_to_pixel(column: int, row: int)->Vector2:
	var new_x = x_start + OFFSET * column
	var new_y = y_start + -OFFSET * row
	return Vector2(new_x, new_y)


#グローバル座標からグリッド座標へ変換する	
func pixel_to_grid(pixel_x: float ,pixel_y: float)->Vector2i:
	var new_x = round((pixel_x - x_start) / OFFSET)
	var new_y = round((pixel_y - y_start) / -OFFSET)
	return Vector2i(new_x, new_y)
