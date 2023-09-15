extends Node2D

enum Mouse_Input{
	PRESS,
	RELEASE,
	NONE,
}

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

#Blockシーンのインスタンスを格納する
var all_blocks = []

#左マウスボタンを押下したグリッド座標
var _pressed_grid := Vector2i(0,0)
#左マウスボタンを離したグリッド座標
var _released_grid := Vector2i(0,0)
#左マウスボタンが押下されている
var _is_press: bool = false

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
	spawn_blocks()

	
func initialize_2d_array()->Array:
	var array = []
	for i_c in WIDTH:
		array.append([])
		for i_r in HEIGHT:
			array[i_c].append(null)
	return array


func spawn_blocks():
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
	
	
#grid_positionがパズルの範囲内か調べる
func is_in_grid(grid_position: Vector2i)->bool:
	if grid_position.x >= 0 && grid_position.x < WIDTH:
		if grid_position.y >= 0 && grid_position.y < HEIGHT:
			return true
	return false


func _process(_delta)->void:
	if touch_input() == Mouse_Input.RELEASE:
		var direction := touch_difference(_pressed_grid, _released_grid)
		
		await swap_blocks(_pressed_grid.x, _pressed_grid.y, direction)
		
		if find_matches() == false:
			await swap_blocks(_pressed_grid.x, _pressed_grid.y, direction)
			return
		
		await transparent_matched_block()
		delete_matched_block()
		await fall_blocks()
		
		
		


func touch_input()->Mouse_Input:
	var mouse_position = get_global_mouse_position()
	var mouse_grid_position = pixel_to_grid(mouse_position.x, mouse_position.y)
	
	if Input.is_action_just_pressed("ui_touch"):
		if is_in_grid(mouse_grid_position):
			_pressed_grid = mouse_grid_position
			_is_press = true
			return Mouse_Input.PRESS
	if Input.is_action_just_released("ui_touch"):
		if is_in_grid(mouse_grid_position) && _is_press:
			_released_grid = mouse_grid_position
			_is_press = false
			return Mouse_Input.RELEASE
	return Mouse_Input.NONE
	

func touch_difference(grid_1: Vector2i, grid_2: Vector2i)->Vector2i:
	var difference := grid_2 - grid_1
	if abs(difference.x) > abs(difference.y):
		if difference.x > 0:
			return Vector2i(1, 0)
		elif difference.x < 0:
			return Vector2i(-1, 0)
	elif abs(difference.y) > abs(difference.x):
		if difference.y > 0:
			return Vector2i(0, 1)
		elif difference.y < 0:
			return Vector2i(0, -1)
	return Vector2i.ZERO
	
	
func swap_blocks(column: int, row: int, direction: Vector2i)->void:
	var first_block: Block = all_blocks[column][row]
	var other_block: Block = all_blocks[column + direction.x][row + direction.y]
	
	if first_block != null && other_block != null:
		all_blocks[column][row] = other_block
		all_blocks[column + direction.x][row + direction.y] = first_block
		
		var tween := get_tree().create_tween()
		tween.tween_property(first_block, 'position', grid_to_pixel(column + direction.x, row + direction.y), 0.2)
		tween.parallel()
		tween.tween_property(other_block, 'position', grid_to_pixel(column, row), 0.2)
		tween.play()
		await tween.finished
		
		
func find_matches()->bool:
	var is_matched: bool
	for i_c in WIDTH:
		for i_r in HEIGHT:
			if all_blocks[i_c][i_r] != null:
				var current_color = all_blocks[i_c][i_r].get_color()
				if i_c > 0 && i_c < WIDTH -1:
					if all_blocks[i_c - 1][i_r] != null && all_blocks[i_c + 1][i_r] != null:
						if all_blocks[i_c - 1][i_r].get_color() == current_color && all_blocks[i_c + 1][i_r].get_color() == current_color:
							is_matched = true
							all_blocks[i_c - 1][i_r].set_matched(true)
							all_blocks[i_c][i_r].set_matched(true)
							all_blocks[i_c + 1][i_r].set_matched(true)
				if i_r > 0 && i_r < HEIGHT -1:
					if all_blocks[i_c][i_r - 1] != null && all_blocks[i_c][i_r + 1] != null:
						if all_blocks[i_c][i_r - 1].get_color() == current_color && all_blocks[i_c][i_r + 1].get_color() == current_color:
							is_matched = true							
							all_blocks[i_c][i_r - 1].set_matched(true)
							all_blocks[i_c][i_r].set_matched(true)
							all_blocks[i_c][i_r + 1].set_matched(true)
	return is_matched
	

func transparent_matched_block()->void:
	var tween := get_tree().create_tween()
	
	for i_c in WIDTH:
		for i_r in HEIGHT:
			if all_blocks[i_c][i_r] != null && all_blocks[i_c][i_r].get_matched() == true:
				tween.parallel()
				tween.tween_property(all_blocks[i_c][i_r].color_rect, 'modulate', Color(1, 1, 1, 0), 0.2)
	tween.play()
	await tween.finished


func delete_matched_block()->void:
	for i_c in WIDTH:
		for i_r in HEIGHT:
			if all_blocks[i_c][i_r] != null && all_blocks[i_c][i_r].get_matched() == true:
				all_blocks[i_c][i_r].queue_free
				all_blocks[i_c][i_r] = null
				
				
#削除されて空いた空間に上にあるBlockを下に詰める
func fall_blocks()->void:
	var tween := get_tree().create_tween()
	for i_c in WIDTH:
		for i_r in HEIGHT:
			if all_blocks[i_c][i_r] == null && !empty_grids.has(Vector2i(i_c,i_r)):
				for j_r in range(i_r + 1, HEIGHT):
					if all_blocks[i_c][j_r] != null:
						tween.parallel()
						tween.tween_property(all_blocks[i_c][j_r], 'position', grid_to_pixel(i_c, i_r), 0.2)
						all_blocks[i_c][i_r] = all_blocks[i_c][j_r]
						all_blocks[i_c][j_r] = null
						break
	tween.play()
	await tween.finished


