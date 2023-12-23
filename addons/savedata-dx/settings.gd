extends RefCounted

const DEFAULT_SETTINGS = {
	"SAVE_DIR": "user://sv/",
	"SAVE_COMMON_NAME": "common",
	"SAVE_AUTO_NAME": "auto",
	"SAVE_EXTENSION_NAME": ".save",
	"KEY": "-G{=P1~Sy?BLty>7iBFI*G:w0#gI;nvP.[|x2F~H|PMAI&6mMLSW-Y^T%}9wYa+M",
}

const valid_key_characters: String = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890~`!@#$%^&*()_-+={[}]|:;<,>.?"

static func prepare() -> void:
	# Set up defaults
	for setting in DEFAULT_SETTINGS:
		if ProjectSettings.has_setting("savedata/general/%s" % setting):
			ProjectSettings.set_initial_value("savedata/general/%s" % setting, DEFAULT_SETTINGS[setting])
	ProjectSettings.save()

static func set_setting(key: String, value) -> void:
	ProjectSettings.set_setting("savedata/general/%s" % key, value)
	ProjectSettings.set_initial_value("savedata/general/%s" % key, DEFAULT_SETTINGS[key])
	ProjectSettings.save()

static func get_setting(key: String):
	if ProjectSettings.has_setting("savedata/general/%s" % key):
		return ProjectSettings.get_setting("savedata/general/%s" % key)
	else:
		return DEFAULT_SETTINGS[key]

static func get_settings(only_keys: PackedStringArray = []) -> Dictionary:
	var settings: Dictionary = {}
	for key in DEFAULT_SETTINGS.keys():
		if only_keys.is_empty() or key in only_keys:
			settings[key] = get_setting(key)
	return settings
