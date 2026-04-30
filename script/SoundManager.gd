# SoundManager.gd
extends Node

# 効果音を保持する変数を宣言（インスペクターからアサイン可能に）
var sounds = {
#	"click": preload("res://sound/click.wav"),
#	"hover": preload("res://sound/hover.wav"),
#	"cancel": preload("res://sound/cancel.wav")
}

func play(sound_name: String, pitch: float = 1.0):
	if sounds.has(sound_name):
		var player = AudioStreamPlayer.new()
		add_child(player)
		
		player.stream = sounds[sound_name]
		player.pitch_scale = pitch # 音の高さ（n秒かけて変化させると面白い）
		player.play()
		
		# 再生が終わったら自動でノードを削除する（メモリ節約）
		player.finished.connect(player.queue_free)
