extends Node

enum Difficulty { EASY, NORMAL, HARD, EXTREME }

var current_difficulty: Difficulty = Difficulty.NORMAL
var player_count: int = 5
var thinking_time: int = 90 # 秒
var current_theme: String = ""
var restart_same_theme =0

# プレイヤーごとの割り当て数字を保持 {"プレイヤー名": 85, ...}
var player_numbers: Dictionary = {} 
var final_ordered_names: Array = [] # これを追加
# お題と比重
var themes = [
	# 【食べ物・生活】
	{"text": "食べ物の人気度", "min_text": "不人気", "max_text": "国民的大人気", "weight": 1},
	{"text": "無人島に持っていきたいもの", "min_text": "いらない", "max_text": "絶対必要", "weight": 1},
	{"text": "ペットにしたい動物", "min_text": "飼いたくない", "max_text": "最高に飼いたい", "weight": 1},
	{"text": "最強の武器", "min_text": "素手", "max_text": "伝説の聖剣", "weight": 1},
	{"text": "一生これしか食べられないなら？", "min_text": "きつい", "max_text": "幸せ", "weight": 1},
	# 【感性・価値観が出る】
	{"text": "モテる人の条件", "min_text": "どうでもいい", "max_text": "必須条件", "weight": 1},
	{"text": "かっこいいと思う職業", "min_text": "地味", "max_text": "花形", "weight": 1},
	{"text": "理想の休日の過ごし方", "min_text": "最悪", "max_text": "最高", "weight": 1},
	{"text": "言われて嬉しい言葉", "min_text": "響かない", "max_text": "感涙", "weight": 1},
	{"text": "「贅沢だな」と感じること", "min_text": "日常的", "max_text": "最高級の贅沢", "weight": 1},
	# 【スリル・大喜利系】
	{"text": "ゾンビに囲まれた時の生存率", "min_text": "即脱落", "max_text": "無双して生き残る", "weight": 1},
	{"text": "超能力として持つのに便利なもの", "min_text": "ゴミ捨て場を当てる程度", "max_text": "時空操作", "weight": 1},
	{"text": "「こいつ、強そうだな」と思う特徴", "min_text": "弱そう", "max_text": "ラスボス感", "weight": 1},
	{"text": "明日世界が終わるなら何をする？", "min_text": "寝るだけ", "max_text": "全力で楽しむ", "weight": 1},
	{"text": "魔法学園で習いたい魔法", "min_text": "火を灯すだけ", "max_text": "禁忌の魔術", "weight": 1},
	# 【日常生活・あるある】
	{"text": "コンビニでつい買ってしまうもの", "min_text": "買わない", "max_text": "絶対カゴに入れる", "weight": 1},
	{"text": "家事の面倒くささ", "min_text": "楽勝", "max_text": "一生やりたくない", "weight": 1},
	{"text": "ちょうどいいお出かけの距離", "min_text": "玄関先", "max_text": "宇宙旅行", "weight": 1},
	{"text": "カバンの中に入っていると安心するもの", "min_text": "ゴミ", "max_text": "命の恩人レベル", "weight": 1},
	{"text": "100円ショップで価値を感じるもの", "min_text": "妥当", "max_text": "1万円でも買う", "weight": 1},# 【追加テーマ】
	{"text": "楽しいこと", "min_text": "退屈", "max_text": "最高にエキサイティング", "weight": 1},
	{"text": "美味しいもの", "min_text": "まずい", "max_text": "ほっぺが落ちる", "weight": 1},
	{"text": "楽しかった旅行先", "min_text": "退屈", "max_text": "最高にエキサイティング", "weight": 30},
	{"text": "衝撃的な思い出", "min_text": "退屈", "max_text": "度肝抜かれる", "weight": 30},
	{"text": "{player}の良いところ", "min_text": "よくない所", "max_text": "いいところ", "weight": 10},
	{"text": "右隣の人がやりそうな事", "min_text": "絶対やらない", "max_text": "やりそうすぎて怖い", "weight": 1}
]
# --- GameManager.gd 内 ---

# 現在参加しているプレイヤーの中からランダムに一人名前を返す関数
func get_random_player_name() -> String:
	var active_names = SaveManager.save_data["players"].slice(0, player_count)
	if active_names.size() > 0:
		return active_names.pick_random() # 配列からランダムに1つ抽出
	return "誰か"

# お題リストの更新例
# {player} という文字列を入れておくのがポイントです
func update_themes_with_player():
	themes = [
		{"text": "楽しいこと", "weight": 10},
		{"text": "美味しいもの", "weight": 10},
		{"text": "右隣の人がやりそうな事", "weight": 5},
		{"text": "{player}が演じていそうなキャラ", "weight": 5}, # 追加
		{"text": "{player}が好きそうなもの", "weight": 5}      # 追加
	]
# 重み付け抽選でお題を決定
func roll_theme() -> String:
	var total_weight = 0
	for t in themes:
		total_weight += t["weight"]
# 2. 当たるまで無限ループ
	while true:
		for t in themes:
			# このアイテムが選ばれる確率 (例: 1 / 23)
			var chance = randi()%total_weight
			#print(chance)
			# 0.0 〜 1.0 の乱数が確率を下回ったら当選！
			if  chance < t["weight"]:
				print("当選:", t)
				current_theme =t["text"]
				return t["text"] # ここで関数を抜ける（無限ループ終了）
	return themes[0]["text"]
# 数字を配り直す関数
func redistribute_numbers():
	player_numbers.clear()
	var numbers = []
	for i in range(1, 101):
		numbers.append(i)
	numbers.shuffle()
	
	var active_names = SaveManager.save_data["players"].slice(0, player_count)
	for p_name in active_names:
		player_numbers[p_name] = numbers.pop_back()
# 難易度に応じて偏差を絞った数字を生成
func generate_numbers():
	player_numbers.clear()
	var players = SaveManager.save_data["players"].slice(0, player_count)
	
	# 難易度が高いほど数字が密集する（spreadが狭くなる）
	var spread: int
	match current_difficulty:
		Difficulty.EASY: spread = 75     # 1~100 (ほぼランダム)
		Difficulty.NORMAL: spread = 50   # 基準値 ±30 の範囲
		Difficulty.HARD: spread = 25     # 基準値 ±15 の範囲
		Difficulty.EXTREME: spread = 10   # 基準値 ±5 の範囲

	# 基準となる数字（1〜100）をランダムに決定
	var base_number = randi_range(1 + spread, 100 - spread)
	
	var used_numbers = []
	for p_name in players:
		var num = 0
		var is_unique = false
		while not is_unique:
			if current_difficulty == Difficulty.EASY:
				num = randi_range(1, 100)
			else:
				num = randi_range(base_number - spread, base_number + spread)
				
			# 1〜100に収め、重複を防ぐ
			num = clamp(num, 1, 100)
			if not used_numbers.has(num):
				used_numbers.append(num)
				is_unique = true
				
		player_numbers[p_name] = num
