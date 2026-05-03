extends Control

@onready var list_container = %VBox_ResultList
@onready var status_label = %Label_Status
@onready var check_all_button = %Button_Check_All
@onready var difficulty_input = $%OptionButton_Difficulty
@onready var restart_container = %Grid_Play_Buttons
# 各種発表モードボタンをグループ化した親ノード（一括無効化用）
@onready var mode_button_container = %Grid_Modes

var ideal_order: Array = [] 
var is_game_over: bool = false
var is_revealing: bool = false # 自動発表中フラグ
var success_count: int = 0
var is_manual_mode: bool = false
var wait_time =1

func _ready():
	check_all_button.hide()
	if restart_container: restart_container.hide()
	
	_calculate_ideal_order()
	_setup_list()

	%Min_text.text = GameManager.current_min_text
	%Max_text.text = GameManager.current_max_text
	# 難易度選択肢の初期化
	difficulty_input.clear()
	difficulty_input.add_item("簡単")
	difficulty_input.add_item("普通")
	difficulty_input.add_item("難しい")
	difficulty_input.add_item("ゲキムズ")
	difficulty_input.selected = GameManager.current_difficulty
	
	status_label.text = "発表モードを選択してください"

# --- 判定ロジック ---

func _reveal_item(item):
	if item.is_revealed: return
	
	var current_idx = item.get_index()
	var is_correct = (item.player_name == ideal_order[current_idx])
	
	item.reveal(is_correct)
	
	if is_correct:
		if not is_game_over:
			success_count += 1
			wait_time = 1+ success_count *0.4
			if success_count == GameManager.player_count -1:
				wait_time = 0
			status_label.text = "%d人正解！" % success_count
			
			if success_count == GameManager.player_count:
				_trigger_all_success_perfection()
				_update_save_record(true) # 記録更新（完全成功）
			elif is_manual_mode:
				status_label.text = "正解！次は誰かな？"
	else:
		is_game_over = true
		status_label.text = "ドボン！順位が違います"
		status_label.modulate = Color.RED
		check_all_button.show()
		_update_save_record(false) # 記録更新（失敗）
		Input.vibrate_handheld(500)

# --- 記録の保存処理 ---
func _update_save_record(is_perfect: bool):
	# 1. GameManagerのenumからSaveManagerのキー文字列を取得
	var diff_key = ""
	match GameManager.current_difficulty:
		GameManager.Difficulty.EASY: diff_key = "easy"
		GameManager.Difficulty.NORMAL: diff_key = "normal"
		GameManager.Difficulty.HARD: diff_key = "hard"
		GameManager.Difficulty.EXTREME: diff_key = "extreme"
	
	# 2. 該当難易度のレコード参照を取得
	var record = SaveManager.save_data["records"][diff_key]

	# 3. 連勝記録(streak)の更新
	if is_perfect:
		record["streak"] += 1
		# 成功した日付を記録（例: 2026-04-24）
		var dict = Time.get_date_dict_from_system()
		record["date"] = "%04d-%02d-%02d" % [dict.year, dict.month, dict.day]
	else:
		record["streak"] = 0 # 失敗したら連勝ストップ
	
	# 4. 最大成功人数(people)の更新
	if success_count > record["people"]:
		record["people"] = success_count
		if record["streak"]> SaveManager.save_data["records"][diff_key]["streak"]:
			# 5. ディスクに保存
			SaveManager.save_data_to_disk()
			print("記録を保存しました: ", diff_key, record)
	
# --- モード選択ボタン制御 ---

func _lock_mode_buttons():
	# 発表が始まったらモード選択ボタンを触れなくする
	#mode_button_container.hide()
	if mode_button_container:
		mode_button_container.set_process_input(false)
		# ボタン自体を無効化（見た目でもわかるように）
		mode_button_container.hide()
		for btn in mode_button_container.get_children():
			if btn is Button: btn.disabled = true

func _on_button_manual_pressed() -> void:
	TweenManager.pop_up(%Button_Manual)
	await get_tree().create_timer(0.3).timeout
	if is_revealing: return
	_lock_mode_buttons()
	is_manual_mode = true
	status_label.text = "正しい順位の人をタップして！"
	Input.vibrate_handheld(50)

func _on_item_clicked(event, item):
	# クリック/タップ判定
	print("press_item",item)
	if event is InputEventMouseButton and event.pressed:
		# マニュアルモード中、または自動発表中でない場合に有効
		if is_manual_mode or (not is_revealing and not is_game_over):
			_lock_mode_buttons()
			_reveal_item(item)

# --- 発表演出 ---

func _on_button_top_down_pressed():
	TweenManager.pop_up(%Button_TopDown)
	await get_tree().create_timer(0.3).timeout
	if is_revealing: return
	is_revealing = true
	_lock_mode_buttons()
	for item in list_container.get_children():
		if is_game_over: break
		await get_tree().create_timer(wait_time).timeout
		_reveal_item(item)
	is_revealing = false

func _on_button_bottom_up_pressed():
	TweenManager.pop_up(%Button_BottomUp)
	await get_tree().create_timer(0.3).timeout
	if is_revealing: return
	is_revealing = true
	_lock_mode_buttons()
	var items = list_container.get_children()
	items.reverse()
	for item in items:
		if is_game_over: break
		await get_tree().create_timer(wait_time).timeout
		_reveal_item(item)
	is_revealing = false

func _on_button_random_pressed():
	TweenManager.pop_up(%Button_Random)
	await get_tree().create_timer(0.3).timeout
	if is_revealing: return
	is_revealing = true
	_lock_mode_buttons()
	var unrevealed = []
	for item in list_container.get_children():
		if not item.is_revealed: unrevealed.append(item)
	
	while unrevealed.size() > 0 and not is_game_over:
		await get_tree().create_timer(wait_time).timeout
		var random_item = unrevealed.pick_random()
		unrevealed.erase(random_item)
		_reveal_item(random_item)
	is_revealing = false

# --- その他共通処理 ---

func _on_option_button_difficulty_item_selected(index):
	TweenManager.pop_up(%OptionButton_Difficulty)
	await get_tree().create_timer(0.3).timeout
	GameManager.current_difficulty = index

func _calculate_ideal_order():
	var players = GameManager.player_numbers.keys()
	players.sort_custom(func(a, b):
		return GameManager.player_numbers[a] > GameManager.player_numbers[b]
	)
	ideal_order = players

func _setup_list():
	for p_name in GameManager.final_ordered_names:
		var item = preload("res://scene/ResultItem.tscn").instantiate()
		list_container.add_child(item)
		item.setup(p_name, GameManager.player_numbers[p_name])
		item.gui_input.connect(_on_item_clicked.bind(item))

func _trigger_all_success_perfection():
	status_label.text = "✨ PERFECT! 全員成功 ✨"
	status_label.modulate = Color.GOLD
	Input.vibrate_handheld(1000)
	for item in list_container.get_children():
		item.start_rainbow_animation()
	_show_final_options()

func _show_final_options():
	check_all_button.hide()
	if restart_container: restart_container.show()

func _on_button_check_all_pressed():
	TweenManager.pop_up(%Button_Check_All)
	await get_tree().create_timer(0.3).timeout
	for item in list_container.get_children():
		if not item.is_revealed:
			var idx = item.get_index()
			item.reveal(item.player_name == ideal_order[idx])
			await get_tree().create_timer(0.2).timeout
	check_all_button.hide()
	_show_final_options()

# --- 遷移/リスタート ---

func _on_button_restart_new_theme_pressed():
	
	TweenManager.pop_up(%Button_Restart_NewTheme)
	await get_tree().create_timer(0.3).timeout
	GameManager.current_theme = GameManager.roll_theme()
	GameManager.generate_numbers()
	_change_to_gameplay()

func _on_button_restart_same_theme_pressed():
	TweenManager.pop_up(%Button_Restart_SameTheme)
	await get_tree().create_timer(0.3).timeout
	GameManager.generate_numbers()
	GameManager.restart_same_theme =1
	_change_to_gameplay()

func _on_button_back_title_pressed():
	TweenManager.pop_up(%Button_BackTitle)
	await get_tree().create_timer(0.3).timeout
	TweenManager.change_scene("res://scene/TitleScene.tscn")

func _change_to_gameplay():
	TweenManager.change_scene("res://scene/GameplayScene.tscn")
