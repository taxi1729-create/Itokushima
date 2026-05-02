extends Control

# ノード参照（ユニーク名 % を設定してください）
@onready var theme_label = %Label_CurrentTheme
@onready var player_instruction = %Label_Instruction
@onready var reveal_button = %Button_Reveal
@onready var number_label = %Label_MyNumber
@onready var next_button = %Button_NextPlayer

# 内部状態管理
var current_player_index: int = 0
var player_names: Array = []
var current_theme_index: int = 0
var states =0
var theme_index =0
var theme_index_en =0
var scene_c =0
#var restart_same_theme =0
# 振動用関数
func _vibrate():
	# iOS/Android本体のバイブレーションを100ミリ秒(0.1秒)作動させる
	# PC上では何も起きませんが、スマホ実機では震えます。
	Input.vibrate_handheld(100)
func _ready():
	# 1. プレイヤーリストの取得
	player_names = SaveManager.save_data["players"].slice(0, GameManager.player_count)
	%PlayerConfirmPanel.hide()
	%Button_Decide_Theme.hide()
	%Button_NextTheme.hide()
	states =0
	theme_index =0
	theme_index_en =0
	scene_c =0
	# 2. お題の初期表示
	# GameManager.roll_theme() で既に選ばれている想定ですが、
	# リストの何番目かを特定しておきます

	_set_initial_theme_index()

# 最初のお題が決まったタイミングで振動（0.1秒）

	# 3. 数字確認画面の初期化
	number_label.hide()
	next_button.hide()
	_update_player_display()

# --- お題ローテーションロジック ---

func _set_initial_theme_index():
	# 現在のお題がリストのどこにあるか探す
	var i =0
	for t in GameManager.themes:
		print("states",states,",i",i,"size",GameManager.themes.size(),"theme_index",current_theme_index,"=",theme_index,",Enable",theme_index_en)
		if states <20 and GameManager.restart_same_theme ==0:
			current_theme_index = i
			_update_theme_display()
			await get_tree().create_timer(0.1).timeout
		if states >=20 and theme_index_en ==1:	
			theme_index_en =2
			current_theme_index =theme_index
			_update_theme_display()
			break
		states +=1
		#print(t["text"],GameManager.current_theme)
		if t["text"] == GameManager.current_theme:
			theme_index = i
			theme_index_en =1
			if states >=20:
				theme_index_en =2
				current_theme_index =theme_index	
				_update_theme_display()
				break
		i+=1

# --- GameplayScene.gd 内の関数を修正 ---

func _update_theme_display():
	var raw_text = GameManager.themes[current_theme_index]["text"]
	if theme_index_en ==2:
		_vibrate()
		%Button_Decide_Theme.show()
		%Button_NextTheme.show()
		$AnimationPlayer.play("Theme_decide")
		# 結果画面などで使うためにGameManagerに現在の最終的なお題を保存
		#GameManager.current_theme = theme_label.text
		GameManager.restart_same_theme =0
	# もしお題に "{player}" が含まれていたら置換する
	if "{player}" in raw_text:
		var r_name = GameManager.get_random_player_name()
		# replace関数で {player} を実際のプレイヤー名に書き換える
		theme_label.text = raw_text.replace("{player}", r_name)
	else:
		theme_label.text = raw_text
	var Min = GameManager.themes[current_theme_index]["min_text"]
	var Max = GameManager.themes[current_theme_index]["max_text"]
	%Label_Min_Max.text = "0: %s ~ 100:%s" % [Min ,Max] 
	GameManager.current_min_text =Min
	GameManager.current_max_text =Max
	

func _on_button_next_theme_pressed():
	TweenManager.pop_up(%Button_NextTheme)
	# インデックスを1進める。最後なら0に戻る（ループ処理）
	current_theme_index = (current_theme_index + 1) % GameManager.themes.size()
	_update_theme_display()
	# 最初のお題が決まったタイミングで振動（0.1秒）
	_vibrate()

# --- プレイヤー確認ロジック ---

func _update_player_display():
	var p_name = player_names[current_player_index]
	player_instruction.text = "[ %s ] さん\n\n周りの人に画面を\n見せないでください" % p_name
	reveal_button.show()
	number_label.hide()
	next_button.hide()

# 「タップして数字を確認」ボタン
func _on_button_reveal_pressed():
	TweenManager.pop_up(%Button_Reveal)
	var p_name = player_names[current_player_index]
	var secret_num = GameManager.player_numbers[p_name]
	
	number_label.text = str(secret_num)
	await get_tree().create_timer(0.3).timeout
	number_label.show()
	reveal_button.hide()
	next_button.show()
	_vibrate()
# 「次の人へ / 準備完了」ボタン
func _on_button_next_player_pressed():
	if scene_c ==0:
		TweenManager.pop_up(%Button_NextPlayer)
		await get_tree().create_timer(0.3).timeout
		current_player_index += 1
	
		if current_player_index < player_names.size():
			# 次のプレイヤーへ
			_update_player_display()
		else:
			# 全員確認終了 -> 順番選択シーンへ
			#get_tree().change_scene_to_file
			scene_c =1
			TweenManager.change_scene("res://scene/OrderingScene.tscn")


func _on_button_decide_theme_pressed() -> void:
	TweenManager.pop_up(%Button_Decide_Theme)
	await get_tree().create_timer(0.3).timeout
	%PlayerConfirmPanel.show()
	GameManager.current_theme = GameManager.themes[current_theme_index]["text"]
	TweenManager.pop_up(%PlayerConfirmPanel)
	%Button_Decide_Theme.hide()
	%Button_NextTheme.hide()
