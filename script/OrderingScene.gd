extends Control

# --- ノード参照 ---
@onready var list_container = %VBox_PlayerList
@onready var theme_label = %Label_Theme
@onready var timer_label = %TimerLabel
@onready var info_button = %Button_Info
@onready var pause_button = %Button_Pause
@onready var game_timer = $Timer_Thinking

# --- 内部状態 ---
var is_peeking_mode: bool = false
var is_manual_paused: bool = false
var dragged_item = null
var drag_start_mouse_y = 0.0
var drag_offset_y = 0.0
var drag_start_y =0
var get_changed_y =0
var submit =0
var scene_c =0
func _ready():
	# お題の表示
	theme_label.text = "  お題:\n " + GameManager.current_theme
	submit =0
	%Button_Submit.text = "これで確定！\n(2回タップ)"
	# プレイヤーパネルの動的生成
	_setup_player_list()
	timer_label.modulate = Color(0, 0, 0)
	scene_c =0
	# タイマーの初期設定と開始
	game_timer.wait_time = GameManager.thinking_time
	%Min_text.text = GameManager.current_min_text
	%Max_text.text = GameManager.current_max_text
	game_timer.start()

func _process(_delta):
	# タイマー表示の更新
	if not game_timer.is_stopped():
		var time_left = int(game_timer.time_left)
		timer_label.text = "残り時間: %d秒" % time_left
		
		# タイムアップ処理
		if time_left <= 0:
			submit =1
			_on_button_submit_pressed()

# --- リストの初期化 ---
func _setup_player_list():
	# 既存のリストをクリア
	for child in list_container.get_children():
		child.queue_free()
	
	# GameManagerからプレイヤーを取得して生成
	var players = SaveManager.save_data["players"].slice(0, GameManager.player_count)
	for p_name in players:
		var item = preload("res://scene/PlayerItem.tscn").instantiate()
		list_container.add_child(item)
		item.setup(p_name, GameManager.player_numbers[p_name])
		
		# 入力イベントをこのスクリプトの関数に接続
		item.gui_input.connect(_on_item_gui_input.bind(item))

# --- ドラッグ＆ドロップ安定化ロジック ---

func _on_item_gui_input(event, item):
	# 覗き見モード中や手動停止中はドラッグ不可
	if is_peeking_mode or is_manual_paused:
		return 

	if event is InputEventMouseButton:
		if event.pressed:
			# ドラッグ開始
			dragged_item = item
			drag_start_mouse_y = get_global_mouse_position().y
			drag_start_y = dragged_item.global_position.y
			get_changed_y = drag_start_y
			item.z_index = 10 # 前面に表示
			item.scale = Vector2(1.2,1.2) # 前面に表示
			item.modulate.a = 0.7 # 透けさせる演出
		else:
			# ドラッグ終了
			if dragged_item:
				_finalize_drag(dragged_item)
				dragged_item = null

	if event is InputEventMouseMotion and dragged_item:
		# マウスの移動量を計算
		var current_mouse_y = get_global_mouse_position().y
		var diff = current_mouse_y - drag_start_mouse_y
		
		# 見た目の位置だけをずらす（VBoxContainerの自動配置を維持したまま移動）
		dragged_item.global_position.y = drag_start_y + diff
		
		# 入れ替え判定
		_check_swap(dragged_item)

func _check_swap(target):
	var mouse_y = get_global_mouse_position().y
	
	for other in list_container.get_children():
		if other == target: continue
		
		# 相手のパネルの中心位置を計算
		var other_center_y = other.global_position.y + (other.size.y / 2)
		var other_global_y = other.global_position.y
		# マウスが相手の中心を超えたらノードのインデックスを入れ替える
		if (target.get_index() < other.get_index() and mouse_y > other_center_y) or \
		   (target.get_index() > other.get_index() and mouse_y < other_center_y):
			
			list_container.move_child(target, other.get_index())
			get_changed_y =other_global_y
			# 重要：入れ替えた瞬間にマウスの基準点をリセットすることで、
			# 「一箇所に固まる」「一番上に吸い付く」のを防ぐ
			#drag_start_mouse_y = mouse_y
			#target.position.y = mouse_y
			break

func _finalize_drag(item):
	item.z_index = 0
	item.scale = Vector2(1,1)
	item.modulate.a = 1.0
	# 見た目の座標をリセットしてVBoxに整列させる
	item.global_position.y = get_changed_y 

# --- タイマー・覗き見制御（バイブレーション付き） ---

func _on_button_info_pressed():
	TweenManager.pop_up(%Button_Info)
	is_peeking_mode = !is_peeking_mode
	_update_game_state()
	# 各パネルにモードを通知
	for item in list_container.get_children():
		item.set_peek_mode(is_peeking_mode)
	info_button.icon = load("res://image/脳のイラスト12.png") if is_peeking_mode else load("res://image/横顔アイコン.png")
	info_button.text = "覗き見中\n (停止)" if is_peeking_mode else "覗き見\nしちゃう？"
	Input.vibrate_handheld(100) # 0.1秒振動

# ⏸ 時間停止ボタン
func _on_button_pause_pressed():
	TweenManager.pop_up(%Button_Pause)
	is_manual_paused = !is_manual_paused
	_update_game_state()
	
	pause_button.icon = load("res://image/再生ボタン.png") if is_manual_paused else load("res://image/再生停止ボタン.png")
	Input.vibrate_handheld(50)

# タイマーの稼働状態を同期
func _update_game_state():
	if is_peeking_mode or is_manual_paused:
		game_timer.paused = true
		timer_label.modulate = Color(1, 0.5, 0.5) # 停止中は赤っぽく
	else:
		game_timer.paused = false
		timer_label.modulate = Color(0, 0, 0)

# --- 最終確定 ---
func _on_button_submit_pressed():
	if scene_c ==0:
		TweenManager.pop_up(%Button_Submit)
		# 現在の並び順（名前の配列）を取得
		%Button_Submit.text = "決定には\nもう一度タップ"
		%Button_Submit.modulate = Color(1, 0.5, 0.5) # 停止中は赤っぽく
		if submit ==1:
			%Button_Submit.text = "決定!!"
			await get_tree().create_timer(0.3).timeout
			var final_order = []
			for item in list_container.get_children():
				final_order.append(item.player_name)
			# GameManagerに結果を渡してリザルトシーンへ
			GameManager.final_ordered_names = final_order
			scene_c =1
			TweenManager.change_scene("res://scene/ResultScene.tscn")
		else:
			submit =1
