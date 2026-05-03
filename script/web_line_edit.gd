extends LineEdit

func _gui_input(event):
	# クリックまたはタップされた判定
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		if event.pressed:
			# Web（GitHub Pages）で実行されている場合のみ
			if OS.has_feature("web"):
				_open_web_input()
			else:
				grab_focus()

func _open_web_input():
	# JavaScriptのpromptを呼び出して入力を受け取る
	var result = JavaScriptBridge.eval("prompt('文字を入力してください', '" + text + "');")
	
	# キャンセルされなかった場合（nullでない場合）、LineEditに反映
	if result != null:
		text = result
		# テキスト変更のシグナルを自前で発行（他で監視している場合のため）
		emit_signal("text_submitted", result)
