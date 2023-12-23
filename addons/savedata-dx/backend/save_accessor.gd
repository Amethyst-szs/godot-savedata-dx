extends Node

## SaveDataDX plugin by Amethyst-szs - 
## Used to manage reading/writing save data.
## This class is meant to be used as an autoload singleton,
## access it via "SaveAccessor" in your scritps.
class_name SaveAccessorPlugin

#region Imports

# Include datatype parser for converting Object into JSON
const datatype_dict_parser: Script = preload("res://addons/savedata-dx/backend/datatype_parser.gd")
var dict_parse = datatype_dict_parser.new()

# Include settings script for accessing and modifying save data settings
var settings: Script = preload("res://addons/savedata-dx/settings.gd")

#endregion

#region Settings

## Directory to store save files
var SAVE_DIR: String = ""
## Name of the common file
var SAVE_COMMON_NAME: String = ""
## Name of the automatic save file
var SAVE_AUTO_NAME: String = ""
## File extension used by save files
var SAVE_EXTENSION_NAME: String = ""

func setup_settings_data():
	SAVE_DIR = settings.get_setting("SAVE_DIR")
	SAVE_COMMON_NAME = settings.get_setting("SAVE_COMMON_NAME")
	SAVE_AUTO_NAME = settings.get_setting("SAVE_AUTO_NAME")
	SAVE_EXTENSION_NAME = settings.get_setting("SAVE_EXTENSION_NAME")

#endregion

#region Signals

## Emitted when the thread becomes busy due to a request
signal thread_busy
## Emitted when the current save/load is finished, regardless of success
signal thread_complete

## Emitted when saving to a slot is completed successfully
signal save_slot_complete
## Emitted when saving the common data is completed successfully
signal save_common_complete
## Emitted when loading a slot is completed successfully
signal load_slot_complete
## Emitted when loading the common data is completed successfully
signal load_common_complete

## Emitted when the active_save_slot is updated to a new, different value
signal active_slot_changed

## Emitted when a save call fails
signal save_error
## Emitted when a load call fails
signal load_error

#endregion

#region End-user Functions

## Current save slot, useful to manage which file is getting read/written to
var active_save_slot: int = 0:
	set (value):
		# Clamp value to be zero or higher
		if value < 0:
			push_warning("Cannot have an active save slot below zero! Defaulting to zero")
			value = max(0, value)
		
		if not active_save_slot == value:
			active_slot_changed.emit()
		
		active_save_slot = value
	get:
		return active_save_slot

## Sets the "active_save_slot", and emits "active_slot_changed" if the new slot is different
func set_active_slot(index: int) -> void:
	active_save_slot = index

## Checks if a file exists for the active save slot, does not ensure it is valid
func is_active_slot_exist() -> bool:
	return is_slot_exist(active_save_slot)

## Writes to the active save slot, and emits "save_slot_complete" when successful
func write_active_slot() -> void:
	write_slot(active_save_slot)

## Loads data from the active save slot, and emits "load_slot_complete" when successful
func read_active_slot() -> void:
	read_slot(active_save_slot)

## Checks if a file exists for autosave slot, does not ensure it is valid
func is_autosave_exist() -> bool:
	var path = SAVE_DIR + "s" + SAVE_AUTO_NAME + SAVE_EXTENSION_NAME
	return FileAccess.file_exists(path)

## Writes to the autosave slot, and emits "save_slot_complete" when successful
func write_autosave_slot() -> void:
	if is_thread_busy:
		_thread_busy_warning()
		return
		
	thread_request.type = ThreadRequestType.WRITE_SLOT
	thread_request.is_slot_auto = true
	thread_semaphore.post()

## Loads data from the autosave slot, and emits "load_slot_complete" when successful
func read_autosave_slot() -> void:
	if is_thread_busy:
		_thread_busy_warning()
		return
		
	thread_request.type = ThreadRequestType.READ_SLOT
	thread_request.is_slot_auto = true
	thread_semaphore.post()

## Checks if a file exists for a specific save slot index, does not ensure it is valid
func is_slot_exist(index: int) -> bool:
	var path = SAVE_DIR + "s" + str(index) + SAVE_EXTENSION_NAME
	return FileAccess.file_exists(path)

## Writes to a specific save slot index, and emits "save_slot_complete" when successful
func write_slot(index: int) -> void:
	if is_thread_busy:
		_thread_busy_warning()
		return
		
	thread_request.type = ThreadRequestType.WRITE_SLOT
	thread_request.slot_id = index
	thread_request.is_slot_auto = false
	thread_semaphore.post()

## Loads data a specific save slot index, and emits "load_slot_complete" when successful
func read_slot(index: int) -> void:
	if is_thread_busy:
		_thread_busy_warning()
		return
		
	thread_request.type = ThreadRequestType.READ_SLOT
	thread_request.slot_id = index
	thread_request.is_slot_auto = false
	thread_semaphore.post()

## Checks if the common save exists in save directory
func is_common_exist() -> bool:
	var path = SAVE_DIR + SAVE_COMMON_NAME + SAVE_EXTENSION_NAME
	return FileAccess.file_exists(path)

## Writes the common data to disk, and emits "save_common_complete" when successful
func write_common() -> void:
	if is_thread_busy:
		_thread_busy_warning()
		return
		
	thread_request.type = ThreadRequestType.WRITE_COMMON
	thread_semaphore.post()

## Reads the common data from the disk, and emits "load_common_complete" when successful
func read_common() -> void:
	if is_thread_busy:
		_thread_busy_warning()
		return
		
	thread_request.type = ThreadRequestType.READ_COMMON
	thread_semaphore.post()

#endregion

#region Backend functions called by thread

## Not intended for the end user.  
## Functionality for save slot writing, handled on a seperate thread
func _write_slot_thread_func(index: int, is_auto_slot: bool) -> void:
	# Get file name to write from
	var file_name: String = ""
	if is_auto_slot:
		file_name = "s%s" % [SAVE_AUTO_NAME]
	else:
		file_name = "s%s" % [str(index)]
	
	if _write_backend(file_name, SaveHolder.slot):
		# Tell the signal that the save is finished successfully
		call_deferred("emit_signal", "save_slot_complete")
	else:
		call_deferred("emit_signal", "save_error")

## Not intended for the end user.  
## Functionality for save slot reading, handled on a seperate thread
func _read_slot_thread_func(index: int, is_auto_slot: bool) -> void:
	# Get file name to read from
	var file_name: String = ""
	if is_auto_slot:
		file_name = "s%s" % [SAVE_AUTO_NAME]
	else:
		file_name = "s%s" % [str(index)]
	
	# Get dictionary from file
	var dict: Dictionary = _read_backend_by_name(file_name)
	if dict.is_empty():
		call_deferred("emit_signal", "load_error")
		return
	
	# Create a new current save and write each key from the JSON into it
	SaveHolder.reset_slot()
	_dict_to_object(dict, [SaveHolder.slot])
	
	# Tell the signal that the load is finished
	call_deferred("emit_signal", "load_slot_complete")

## Not intended for the end user.  
## Functionality for common writing, handled on a seperate thread
func _write_common_thread_func() -> void:
	if _write_backend(SAVE_COMMON_NAME, SaveHolder.common):
		# Tell the signal that the save is finished successfully
		call_deferred("emit_signal", "save_common_complete")
	else:
		call_deferred("emit_signal", "save_error")

## Not intended for the end user.  
## Functionality for common reading, handled on a seperate thread
func _read_common_thread_func() -> void:
	# Get dictionary from file in save directory
	var dict: Dictionary = _read_backend_by_name(SAVE_COMMON_NAME)
	if dict.is_empty():
		call_deferred("emit_signal", "load_error")
		return
	
	# Create a new common save and write each key from the JSON into it
	SaveHolder.reset_common()
	_dict_to_object(dict, [SaveHolder.common])
	
	# Tell the signal that the load is finished
	call_deferred("emit_signal", "load_slot_complete")

# Backend functions handling reading and writing of data

## Not intended for the end user.  
## Write object to disk with file name, called by write_slot and write_common
func _write_backend(name: String, object) -> bool:
	# Ensure the directory 100% exists to avoid issues
	DirAccess.make_dir_absolute(SAVE_DIR)
	
	var file_path = SAVE_DIR + name + SAVE_EXTENSION_NAME
	
	# Attempt to open new file and print an error if it fails
	var file = FileAccess.open_encrypted_with_pass(file_path, FileAccess.WRITE, settings.get_setting("KEY"))
	if file == null:
		printerr("FileAccess open error: " + str(FileAccess.get_open_error()))
		return false
	
	# Create a dictionary out of the object using the parser
	var data: Dictionary = _object_to_dict(object)
	
	# Write this JSON data to disk
	var json_string = JSON.stringify(data, "\t")
	file.store_string(json_string)
	file.close()
	
	return true

## Not intended for the end user.  
## Write stringified JSON to disk at path
func _write_backend_with_json_string(path: String, json_string: String) -> bool:
	# Ensure the directory 100% exists to avoid issues
	DirAccess.make_dir_absolute(SAVE_DIR)
	
	# Attempt to open new file and print an error if it fails
	var file = FileAccess.open_encrypted_with_pass(path, FileAccess.WRITE, settings.get_setting("KEY"))
	if file == null:
		printerr("FileAccess open error: " + str(FileAccess.get_open_error()))
		return false
	
	# Write this data to disk
	file.store_string(json_string)
	file.close()
	
	return true

## Not intended for the end user.  
## Read save file by file name and return dictionary
func _read_backend_by_name(name: String) -> Dictionary:
	return _read_backend(SAVE_DIR + name + SAVE_EXTENSION_NAME)

## Not intended for the end user.  
## Read save file by path and return dictionary
func _read_backend(path: String) -> Dictionary:
	# Get the content of the path
	var content = _read_backend_raw_data(path)
	if content == null or content.is_empty():
		return {}
	
	# Convert this content into a JSON if possible
	var data: Dictionary = JSON.parse_string(content)
	if data == null:
		printerr("Cannot parse %s as json string, data is null! (%s)" % [path, content])
		return {}
	
	# Return the JSON data to then be converted into a object later
	return data

## Not intended for the end user.  
## Read save file by path and return raw string data
func _read_backend_raw_data(path: String) -> String:
	# Verify the file exists and return early if not
	if not FileAccess.file_exists(path):
		printerr("Cannot open non-existent file at %s" % [path])
		return ""
	
	# Open the file and return if something goes wrong (another program controlling it for example)
	var file = FileAccess.open_encrypted_with_pass(path, FileAccess.READ, settings.get_setting("KEY"))
	if file == null:
		printerr("FileAccess open error: " + str(FileAccess.get_open_error()))
		return ""
	
	# Get the content of the open file
	var content = file.get_as_text()
	file.close()
	
	# Print message saying that the dictionary is empty if needed
	if content.is_empty():
		push_warning("File at %s was parsed correctly, but contains no data" % [path])
	
	# Return the JSON data to then be converted into a object later
	return content

#endregion

#region Multithreading System

## What kind of action are you requesting the thread to perform
enum ThreadRequestType {
	UNKNOWN = -1,
	WRITE_SLOT,
	READ_SLOT,
	WRITE_COMMON,
	READ_COMMON
}

## Class containing information about what the thread should start doing
class ThreadRequest:
	var type: ThreadRequestType = ThreadRequestType.UNKNOWN
	var slot_id: int = 0
	var is_slot_auto: bool = false

## The thread used for reading/writting save data
var thread: Thread

## Trigger used to start the thread's process
var thread_semaphore: Semaphore

## Information about what the thread should be doing
var thread_request: ThreadRequest = ThreadRequest.new()

## Is the thread currently busy
var is_thread_busy: bool = false:
	set(value):
		is_thread_busy = value
		
		if value:
			call_deferred("emit_signal", "thread_busy")
		else:
			call_deferred("emit_signal", "thread_complete")

## Should the thread be terminated
var is_thread_terminate: bool = false

func _ready():
	# Prepare copy of frequently used settings data
	setup_settings_data()
	
	# Prepare the settings menu if this is in the editor
	if Engine.is_editor_hint():
		settings.prepare()
	
	# Setup thread and and its components
	thread_semaphore = Semaphore.new()
	
	thread = Thread.new()
	thread.start(_thread_func, Thread.PRIORITY_NORMAL)

func _thread_func():
	while true:
		thread_semaphore.wait()
		if is_thread_terminate: break
		
		is_thread_busy = true
		
		match(thread_request.type):
			ThreadRequestType.WRITE_SLOT:
				await _write_slot_thread_func(thread_request.slot_id, thread_request.is_slot_auto)
			ThreadRequestType.READ_SLOT:
				await _read_slot_thread_func(thread_request.slot_id, thread_request.is_slot_auto)
			ThreadRequestType.WRITE_COMMON:
				await _write_common_thread_func()
			ThreadRequestType.READ_COMMON:
				await _read_common_thread_func()
		
		is_thread_busy = false
		
		if is_thread_terminate: break

func _thread_busy_warning():
	push_warning("Save/Load request ignored cause SaveAccessor thread is busy!
	You can be notified when the thread is free with the \"thread_complete\" signal")

func _exit_tree():
	is_thread_terminate = true
	thread_semaphore.post()
	thread.wait_to_finish()

#endregion

#region Backend Save Parsing Utilities

## Not intended for the end user.  
## Converts object class into dictionary for saving process
func _object_to_dict(obj: Object) -> Dictionary:
	# Create empty dictionary and get all properties from object
	var members = obj.get_property_list()
	var member_index: int = 0
	var dict: Dictionary = {}
	
	# Iterate through all members
	for member in members:
		member_index += 1
		if member_index <= 3:
			continue
		
		# Write the member to dictionary depending on type of member
		match(typeof(obj.get(member.name))):
			TYPE_OBJECT: # Call self and create sub-dictionary for object
				dict[member.name] = _object_to_dict(obj.get(member.name))
			TYPE_ARRAY: # Expand the array with function and add to dictionary
				dict[member.name] = _expand_array_for_dict(obj.get(member.name))
			TYPE_VECTOR2, TYPE_VECTOR2I:
				dict[member.name] = dict_parse.parse_vector2(obj.get(member.name))
			TYPE_VECTOR3, TYPE_VECTOR3I:
				dict[member.name] = dict_parse.parse_vector3(obj.get(member.name))
			TYPE_VECTOR4, TYPE_VECTOR4I, TYPE_QUATERNION:
				dict[member.name] = dict_parse.parse_vector4(obj.get(member.name))
			TYPE_COLOR:
				dict[member.name] = dict_parse.parse_color(obj.get(member.name))
			_: # Default behavior
				dict[member.name] = obj.get(member.name)
	
	return dict

## Not intended for the end user.  
## Converts inside of array into dictionaries, allowing arrays of objects to be saved correctly
func _expand_array_for_dict(list: Array) -> Array:
	# Create empty array
	var new_list: Array = []
	
	# Iterate through all items
	for item in list:
		match(typeof(item)):
			TYPE_OBJECT: # Call object to dict converter for item
				new_list.push_back(_object_to_dict(item))
			TYPE_ARRAY: # Create sub array
				new_list.push_back(_expand_array_for_dict(item))
			TYPE_VECTOR2, TYPE_VECTOR2I:
				new_list.push_back(dict_parse.parse_vector2(item))
			TYPE_VECTOR3, TYPE_VECTOR3I:
				new_list.push_back(dict_parse.parse_vector3(item))
			TYPE_VECTOR4, TYPE_VECTOR4I, TYPE_QUATERNION:
				new_list.push_back(dict_parse.parse_vector4(item))
			TYPE_COLOR:
				new_list.push_back(dict_parse.parse_color(item))
			_: # Default behavior
				new_list.push_back(item)
	
	return new_list

## Not intended for the end user.  
## Writes dictionary data into object, including dedicated array handling
func _dict_to_object(dict: Dictionary, obj_ref: Array) -> void:
	# Iterate through every key in dictionary
	for key in range(dict.size()):
		# Get the variable from the object reference so you can compare type
		var member: Array = [obj_ref[0].get(dict.keys()[key])]
		
		# Perform different behavior depending on the type of this member
		match(typeof(member[0])):
			TYPE_NIL: # Make sure this property exists on the object
				push_warning("Loading SaveData: Property \"%s\" does not exist on object"
				% [dict.keys()[key]])
				continue
			TYPE_OBJECT: # Call self again with sub-object
				_dict_to_object(dict.values()[key], member)
			TYPE_ARRAY:
				_handle_array_in_dict_for_object(dict.values()[key], member[0], dict.keys()[key])
			_: # Default behavior
				obj_ref[0].set(dict.keys()[key], dict.values()[key])

## Not intended for the end user. 
## Handle converting a dictionary array into a typed array, part of the dict_to_obj method
func _handle_array_in_dict_for_object(dict_ar: Array, obj_ar: Array, ar_name: String) -> void:
	# Get the type of the array
	var type: int = obj_ar.get_typed_builtin()
	var obj_type: Object = obj_ar.get_typed_script()
	
	# Reset array to empty to avoid duplication if the array has default values
	if not obj_ar.is_empty():
		obj_ar.clear()
	
	# Handle proceeding from here differently depending on type
	match(type):
		TYPE_OBJECT: # Handle an object inside an array
			# Iterate through every index in the dictionary array
			for item in dict_ar:
				# Create new object of array's type, then build it with dict_to_obj
				obj_ar.push_back(obj_type.new())
				_dict_to_object(item, [obj_ar.back()])
		TYPE_BOOL, TYPE_FLOAT, TYPE_STRING, TYPE_DICTIONARY:
			for item in dict_ar:
				obj_ar.push_back(item)
		TYPE_INT:
			for item in dict_ar:
				obj_ar.push_back(int(item))
		_: # Error if the array has a bad type
			push_error("SaveData script arrays must be typed with one of the following types:
			Object, bool, int, float, string, or dictionary.
			Name of array that spawned error: %s
			
			All scripts that extend from object are valid here,
			this includes scripts created with the SaveData menu.
			To use other types, put those types inside an object and use that object."
			% [ar_name])
			return

#endregion
