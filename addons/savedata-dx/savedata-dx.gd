@tool
extends EditorPlugin

func _enter_tree():
	add_autoload_singleton("SaveAccessor", "res://addons/savedata-dx/backend/save_accessor.gd")
	add_autoload_singleton("SaveHolder", "res://addons/savedata-dx/backend/save_holder.gd")

func _exit_tree():
	remove_autoload_singleton("SaveAccessor")
	remove_autoload_singleton("SaveHolder")
