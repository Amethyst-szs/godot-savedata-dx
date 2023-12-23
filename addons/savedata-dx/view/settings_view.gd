@tool
extends Control

var is_setup_complete: bool = false

var settings = null
var main_view: Control = null:
	set(value):
		main_view = value
		settings = value.accessor_inst.settings
		prepare()

func prepare():
	var use_theme: Theme = get_parent().theme
	setup_theme(self, use_theme)
	
	setup_line_edit(%Directory, "SAVE_DIR")
	setup_line_edit(%CommonName, "SAVE_COMMON_NAME")
	setup_line_edit(%AutoName, "SAVE_AUTO_NAME")
	setup_line_edit(%Extension, "SAVE_EXTENSION_NAME")
	
	%EncryptionReroll.icon = get_theme_icon("Reload", "EditorIcons")
	%EncryptionKey.text = settings.get_setting("KEY")
	
	is_setup_complete = true

func setup_line_edit(node: LineEdit, key: String):
	var data: String = settings.get_setting(key)
	if data != settings.DEFAULT_SETTINGS[key]:
		node.text = data

func setup_theme(node, use_theme: Theme):
	if not node is Control:
		return
	
	node.theme = use_theme
	for child in node.get_children():
		if not child is Control:
			continue
		
		child.theme = use_theme
		if child.get_child_count() > 0:
			setup_theme(child, use_theme)

func _on_directory_text_changed(new_text: String):
	var key: String = "SAVE_DIR"
	if is_setup_complete:
		if not new_text.is_empty():
			settings.set_setting(key, new_text)
		else:
			settings.set_setting(key, settings.DEFAULT_SETTINGS[key])

func _on_common_name_text_changed(new_text: String):
	var key: String = "SAVE_COMMON_NAME"
	if is_setup_complete:
		if not new_text.is_empty():
			settings.set_setting(key, new_text)
		else:
			settings.set_setting(key, settings.DEFAULT_SETTINGS[key])

func _on_auto_name_text_changed(new_text: String):
	var key: String = "SAVE_AUTO_NAME"
	if is_setup_complete:
		if not new_text.is_empty():
			settings.set_setting(key, new_text)
		else:
			settings.set_setting(key, settings.DEFAULT_SETTINGS[key])

func _on_extension_text_changed(new_text: String):
	var key: String = "SAVE_EXTENSION_NAME"
	if is_setup_complete:
		if not new_text.is_empty():
			settings.set_setting(key, new_text)
		else:
			settings.set_setting(key, settings.DEFAULT_SETTINGS[key])

func _on_encryption_reroll_pressed():
	settings.set_setting("KEY", _key_generator())
	%EncryptionKey.text = settings.get_setting("KEY")

func _key_generator() -> String:
	var key: String = "" 
	for i in range(64):
		var rand_idx: int = randi() % settings.valid_key_characters.length()
		key += settings.valid_key_characters[rand_idx]
	
	return key
