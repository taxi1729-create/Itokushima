extends Control

# --- ノードへの参照 (メイン画面) ---
@onready var count_display = $%Label_CountDisplay
@onready var difficulty_input = $%OptionButton_Difficulty
@onready var time_input = $%SpinBox_Time
@onready var volume_input = $%HSlider_Volume
@onready var record_label = $%Label_Record
@onready var fish_image = $FishImage # 今後追加する魚の画像用

# --- ノードへの参照 (プレイヤー設定パネル) ---
@onready var settings_panel = $PlayerSettingsPanel
@onready var name_list_container = $%VBox_NameList
@onready var panel_count_label = $%Label_Count

# --- 内部変数 ---
var temp_player_count: int = 5
var scene_c =0
func _ready():
	print_tree_pretty()
	print("--- ノード存在チェック ---")
	print("DifficultyInput: ", has_node("%OptionButton_Difficulty"))
	print("VolumeSlider: ", has_node("%HSlider_Volume"))
	print("TimeInput: ", has_node("%SpinBox_Time"))
	print("CountDisplay: ", has_node("%Label_CountDisplay"))
	print("------------------------")
	# 1. 難易度の選択肢を初期化
	difficulty_input.clear()
	difficulty_input.add_item("簡単")   # ID: 0
	difficulty_input.add_item("普通")   # ID: 1
	difficulty_input.add_item("難しい") # ID: 2
	difficulty_input.add_item("ゲキムズ") # ID: 3
	difficulty_input.add_theme_font_size_override("font_size", 40)
	# 2. GameManager/SaveManagerから現在の設定をUIに反映
	temp_player_count = GameManager.player_count
	difficulty_input.selected = GameManager.current_difficulty
	time_input.value = GameManager.thinking_time
	var player_array =SaveManager.save_data["players"]
	time_input.add_theme_font_size_override("font_size", 40)
	scene_c =0

	GameManager.player_count =player_array.size()
	# 音量の初期値 (SaveManagerに保存された値 or 0.5)
	var saved_vol = SaveManager.save_data.get("volume", 0.5)
	volume_input.value = saved_vol
	_on_h_slider_volume_value_changed(saved_vol)
	# 3. 表示の更新
	_update_title_display()
	_update_record_display(difficulty_input.selected)
	
	# パネルは最初は隠しておく
	settings_panel.hide()

# ----------------------------------------------------------------
# メイン画面のロジック
# ----------------------------------------------------------------

# 難易度変更時に記録表示を更新
func _on_option_button_difficulty_item_selected(index):
	TweenManager.pop_up(%OptionButton_Difficulty)
	GameManager.current_difficulty = index
	_update_record_display(index)

func _update_record_display(diff_index):
	var diff_keys = ["easy", "normal", "hard", "extreme"]
	var record = SaveManager.save_data["records"][diff_keys[diff_index]]
	
	if record["streak"] > 0:
		record_label.text = "連続成功記録: %d回\n(%d人協力 / %s)" % [
			record["streak"], record["people"], record["date"]
		]
	else:
		record_label.text = "最高記録: なし"
	
	record_label.add_theme_font_size_override("font_size", 40)

func _update_title_display():
	count_display.text = str(GameManager.player_count)
	count_display.add_theme_font_size_override("font_size", 40)
	%CardImage.hide()


# 音量スライダー操作
func _on_h_slider_volume_value_changed(value):
	TweenManager.pop_up(%HSlider_Volume)
	# マスター音量を変更
	AudioServer.set_bus_volume_db(0, linear_to_db(value))
	SaveManager.save_data["volume"] = value
	%Label_Volume.text = "音量 \n%d" %value

# 「プレイする」ボタン
func _on_button_play_pressed():
	if scene_c ==0:
		TweenManager.pop_up(%Button_Play)
		await get_tree().create_timer(0.3).timeout
		# GameManagerに最終的な設定を確定させる
		GameManager.current_difficulty = difficulty_input.selected
		GameManager.thinking_time = int(time_input.value)
		# セーブ
		SaveManager.save_data_to_disk()
		# お題と数字を生成して次シーンへ
		GameManager.roll_theme()
		GameManager.generate_numbers()
		#get_tree().change_scene_to_file
		scene_c=1
		TweenManager.change_scene("res://scene/GameplayScene.tscn")
		

# 「終了」ボタン
func _on_button_exit_pressed():
	SaveManager.save_data_to_disk()
	get_tree().quit()

# ----------------------------------------------------------------
# プレイヤー名・人数設定パネルのロジック
# ----------------------------------------------------------------

# 「人数・名前設定」ボタン（メイン画面）
func _on_button_edit_players_pressed():
	TweenManager.pop_up(%Button_EditPlayers)
	temp_player_count = GameManager.player_count
	%VBox_Settings.hide()
	settings_panel.show()
	$AnimationPlayer.play("setting_show")
	await $AnimationPlayer.animation_finished
	%VBox_Settings.show()
	_refresh_name_inputs()

func _on_button_minus_pressed():
	TweenManager.pop_up(%Button_Minus)
	if temp_player_count > 2:
		temp_player_count -= 1
		_refresh_name_inputs()

func _on_button_plus_pressed():
	TweenManager.pop_up(%Button_Plus)
	if temp_player_count < 20: # 上限20
		temp_player_count += 1
		_refresh_name_inputs()

# 名前入力欄の動的生成
func _refresh_name_inputs():
	panel_count_label.text = str(temp_player_count)
	
	# 既存の入力欄を削除
	for child in name_list_container.get_children():
		child.queue_free()
	
	# 新しく生成
	#print("aa")
	var saved_names = SaveManager.save_data["players"]
	for i in range(temp_player_count):
		var line_edit = LineEdit.new()
		if i < saved_names.size():
			line_edit.text = saved_names[i]
		else:
			line_edit.text = "プレイヤー" + str(i + 1)
		#line_edit.add_theme_font_size_override() =40
		line_edit.add_theme_font_size_override("font_size", 40)	
		line_edit.add_theme_color_override("font_color", Color.BLACK)
		line_edit.add_theme_color_override("caret_color", Color.BLACK)
		line_edit.add_theme_constant_override("caret_width", 4)
		line_edit.add_theme_stylebox_override("normal", load("/Users/kojimatakuya/ito-kushima/style/Player_style_box_flat.tres"))
		line_edit.add_theme_stylebox_override("forcus", load("/Users/kojimatakuya/ito-kushima/style/Player_style_box_flat.tres"))
		line_edit.set_script(load("res://script/web_line_edit.gd"))
		#add_child(my_edit)
		line_edit.placeholder_text = "ここをタップ"
		name_list_container.add_child(line_edit)

# 「反映して戻る」ボタン（パネル内）
func _on_button_apply_pressed():
	TweenManager.pop_up(%Button_Apply)
	var new_names = []
	for child in name_list_container.get_children():
		if child is LineEdit:
			new_names.append(child.text)
	print("保存された名前リスト: ", SaveManager.save_data["players"])

	GameManager.player_count = temp_player_count
	SaveManager.save_data["players"] = new_names

	%VBox_Settings.hide()
	$AnimationPlayer.play("setting_hide")
	await $AnimationPlayer.animation_finished
	_update_title_display()
	settings_panel.hide()


func _on_button_play_button_down() -> void:

	%CardImage.show()
	$AnimationPlayer.play("do_you_play")
func _on_button_play_button_up() -> void:
	%CardImage.hide()


func _on_spin_box_time_value_changed(value: float) -> void:
	TweenManager.pop_up(%SpinBox_Time)
