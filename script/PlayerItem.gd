# PlayerItem.gd
extends PanelContainer

var player_name: String = ""
var my_number: int = 0
var is_peeking_enabled: bool = false # インフォボタンの状態

@onready var label = $Label_Name

func setup(p_name: String, num: int):
	player_name = p_name
	my_number = num
	label.text = player_name

# 覗き見機能の制御
func set_peek_mode(enabled: bool):
	is_peeking_enabled = enabled
	if not enabled:
		label.text = player_name

# タップ（マウスダウン）している間だけ数字を表示
func _gui_input(event):
	if is_peeking_enabled and event is InputEventMouseButton:
		if event.pressed:
			label.text = player_name + str(" : ") +str(my_number)
			Input.vibrate_handheld(50) # 軽く振動
		else:
			label.text = player_name
