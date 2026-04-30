extends Node

const SAVE_PATH = "user://scene/ito_save_data.json"

var save_data = {
	"volume": 0.5,
	"players": ["プレイヤー1", "プレイヤー2", "プレイヤー3", "プレイヤー4", "プレイヤー5"],
	"records": {
		"easy": {"streak": 0, "people": 0, "date": ""},
		"normal": {"streak": 0, "people": 0, "date": ""},
		"hard": {"streak": 0, "people": 0, "date": ""},
		"extreme": {"streak": 0, "people": 0, "date": ""}
	}
}

func _ready():
	load_data()

func save_data_to_disk():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()

func load_data():
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		if error == OK:
			var loaded_data = json.get_data()
			# デフォルト値に上書き統合（アプデで項目が増えてもクラッシュしないため）
			save_data.merge(loaded_data, true)
		file.close()
