# ResultItem.gd
extends PanelContainer

var player_name: String = ""
var my_number: int = 0
var is_revealed: bool = false

@onready var label = %Label_Name
# ここで duplicate() を呼ぶことで、このアイテム専用のスタイルになります
@onready var style_box = get_theme_stylebox("panel").duplicate() as StyleBoxFlat

func _ready():
	# 自分専用に複製したスタイルを自分に適用し直す
	add_theme_stylebox_override("panel", style_box)

func setup(p_name: String, num: int):
	player_name = p_name
	my_number = num
	label.text = player_name
	# 初期状態の色（例えば黒やグレー）にリセット
	style_box.bg_color = load("res://style/Player_style_box_flat.tres").bg_color 

# オープン時の処理
func reveal(is_correct: bool):
	if is_revealed: return
	is_revealed = true
	
	# 名前と数字を表示
	label.text = " %s : [ %d ] " % [player_name, my_number]
	
	# 当たりは緑、ハズレは赤
	var target_color = Color("#00FF41") if is_correct else Color("#FF3131")
	
	# 1.2秒かけて色を変更
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(style_box, "bg_color", target_color, 1.2)
	
	# Neo-Brutalism演出：正解なら少し大きく跳ねさせる
	if is_correct:
		TweenManager.pop_up(self, 0.4)

# 【演出B】虹色に光る演出
func start_rainbow_animation():
	var tween = create_tween().set_loops()
	tween.tween_method(set_bg_hue, 0.0, 1.0, 3.0)

func set_bg_hue(hue: float):
	style_box.bg_color = Color.from_hsv(hue, 0.8, 1.0) # 少し彩度を落とすと文字が見やすい
