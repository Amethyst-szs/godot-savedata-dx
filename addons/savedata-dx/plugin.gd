@tool
extends EditorPlugin

const SaveView = preload("./view/save_view.tscn")
var save_view

func _enter_tree():
	# Ensure various folders
	DirAccess.make_dir_recursive_absolute(SaveAccessorPlugin.SAVE_DIR)
	DirAccess.make_dir_recursive_absolute("res://addons/savedata-dx/slot/")
	DirAccess.make_dir_recursive_absolute("res://addons/savedata-dx/common/")
	
	# Setup singletons for accessing and holding save data
	add_autoload_singleton("SaveAccessor", "res://addons/savedata-dx/backend/save_accessor.gd")
	add_autoload_singleton("SaveHolder", "res://addons/savedata-dx/backend/save_holder.gd")
	
	# Return here if editor hint is not present
	if not Engine.is_editor_hint():
		return
	
	# Instantiate save view main screen and hide from view
	save_view = SaveView.instantiate()
	save_view.editor_plugin = self
	get_editor_interface().get_editor_main_screen().add_child(save_view)
	_make_visible(false)

func _exit_tree():
	# Remove singletons for accessing and holding save data
	remove_autoload_singleton("SaveAccessor")
	remove_autoload_singleton("SaveHolder")
	
	# Delete save view main screen
	if is_instance_valid(save_view):
		save_view.queue_free()

func _has_main_screen():
	return true

func _make_visible(visible):
	if save_view:
		save_view.visible = visible

func _get_plugin_name():
	return "Saves"

func _get_plugin_icon():
	return get_editor_interface().get_base_control().get_theme_icon("Save", "EditorIcons")
