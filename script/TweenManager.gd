# TweenManager.gd (Autoload登録名: TweenManager)
extends CanvasLayer

# --- 設定用の変数 ---
@onready var transition_rect = $%TransitionRect # シーン遷移用の黒い四角

func _ready():
	#print("VolumeSlider: ", has_node("%TransitionRect"))
	# シーン遷移用のRectを準備（最前面かつ画面サイズに合わせる）
	layer = 100 # 他のUIより上に表示
	transition_rect.color = Color.BLACK
	transition_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE # 通常時はクリックを通す
	_reset_transition_rect()


# --- 1. ポップアップ演出 (n秒かけて拡大縮小) ---
func pop_up(target: Control, duration: float = 0.3, delay: float = 0.01):
	if not target: return
	target.pivot_offset = target.size / 2
	target.scale = Vector2.ONE
	
	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	tween.tween_property(target, "scale", Vector2(1.1,1.1), 0.5*duration)
	if delay > 0: tween.tween_interval(delay)
	tween.tween_property(target, "scale", Vector2.ONE, duration)
	
# --- 2. 汎用プロパティ操作 (Dictionary形式) ---
# TweenManager.play_anim(self, {"modulate": Color.RED}, 0.5) のように使う
func play_anim(target: Object, params: Dictionary, duration: float = 0.2):
	if not target: return
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	for key in params.keys():
		var value = params[key]
		# 回転(rotation)が度数指定ならラジアンに変換
		if key == "rotation":
			value = deg_to_rad(value)
		
		# シェーダーパラメータの場合はパスを補完
		if key.begins_with("shader_"):
			var shader_param = "material:shader_parameter/" + key.replace("shader_", "")
			tween.tween_property(target, shader_param, value, duration)
		else:
			tween.tween_property(target, key, value, duration)
	return tween

# --- 3. シーン遷移 (右から左へ流れる) ---
func change_scene(target_scene_path: String, speed: float = 0.5):
	transition_rect.mouse_filter = Control.MOUSE_FILTER_STOP # 遷移中は操作禁止
	var screen_width = get_viewport().get_visible_rect().size.x
	
	# 右から画面を覆う
	var tween_in = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween_in.tween_property(transition_rect, "position:x", 0, speed)
	
	await tween_in.finished
	
	# シーン切り替え
	get_tree().change_scene_to_file(target_scene_path)
	
	# 1フレーム待機して新しいシーンを安定させる
	await get_tree().process_frame
	
	# 左へはけていく
	var tween_out = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween_out.tween_property(transition_rect, "position:x", -screen_width, speed)
	
	await tween_out.finished
	_reset_transition_rect()

func _reset_transition_rect():
	var screen_size = get_viewport().get_visible_rect().size
	transition_rect.size = screen_size
	transition_rect.position = Vector2(screen_size.x, 0) # 右外側に待機
	transition_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
