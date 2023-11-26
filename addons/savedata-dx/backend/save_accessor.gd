extends Node

# SaveDataDX plugin by Amethyst-szs
# - SaveAccessor -
#
# This autoload singleton is used to manage reading/writing save data.
# The main functions include reading, writing, and verifying a specific save slot
# as well as reading, writing, and verifying the common save data shared over all slots.

# Include datatype parser for converting Object into JSON
const datatype_dict_parser = preload("res://addons/savedata-dx/backend/datatype_parser.gd")
var dict_parse = datatype_dict_parser.new()

# Constants defining where the saves are located and how they are named/stored
const SAVE_DIR: String = "user://sv/"
const SAVE_COMMON_NAME: String = "common"
const SAVE_EXTENSION_NAME: String = ".bin"
const KEY: String = "no@NqlqGu8PTG#weQ77t$%bBQ9$HG5itZ#8#Xnbd%&L$y5Sd"

# Signal messages
signal save_slot_complete
signal save_common_complete
signal load_slot_complete
signal load_common_complete

signal save_error
signal load_error

# Check/modify a save slot determined by the variable "active_save_slot"
@export var active_save_slot: int = 0

func set_active_slot(index: int) -> void:
	active_save_slot = index
	
func is_active_slot_exist() -> bool:
	return is_slot_exist(active_save_slot)
	
func write_active_slot() -> void:
	write_slot(active_save_slot)
	
func read_active_slot() -> void:
	read_slot(active_save_slot)

# Check/modify a specific save slot, specified by index

func is_slot_exist(index: int) -> bool:
	var path = SAVE_DIR + "s" + str(index) + SAVE_EXTENSION_NAME
	return FileAccess.file_exists(path)

func write_slot(index: int) -> void:
	if write_backend("s%s" % [str(index)], SaveHolder.slot):
		# Tell the signal that the save is finished successfully
		save_slot_complete.emit()
	else:
		save_error.emit()
	

func read_slot(index: int) -> void:
	# Get dictionary from file in save directory
	var dict: Dictionary = read_backend_by_name("s%s" % [str(index)])
	if dict.is_empty():
		load_error.emit()
		return
	
	# Create a new current save and write each key from the JSON into it
	SaveHolder.reset_slot()
	for key in range(dict.size()):
		var key_name: String = dict.keys()[key]
		var value = dict.values()[key]
		SaveHolder.slot.set(key_name, value)
	
	# Tell the signal that the load is finished
	load_slot_complete.emit()


# Check/modify the common save data shared between all slots
# Note that "read_common" is automatically called on startup if it already exists

func is_common_exist() -> bool:
	var path = SAVE_DIR + SAVE_COMMON_NAME + SAVE_EXTENSION_NAME
	return FileAccess.file_exists(path)

func write_common() -> void:
	if write_backend(SAVE_COMMON_NAME, SaveHolder.common):
		# Tell the signal that the save is finished successfully
		save_common_complete.emit()
	else:
		save_error.emit()

func read_common() -> void:
	# Get dictionary from file in save directory
	var dict: Dictionary = read_backend_by_name(SAVE_COMMON_NAME)
	if dict.is_empty():
		load_error.emit()
		return
	
	# Create a new common save and write each key from the JSON into it
	SaveHolder.reset_common()
	for key in range(dict.size()):
		var key_name: String = dict.keys()[key]
		var value = dict.values()[key]
		SaveHolder.common.set(key_name, value)
	
	# Tell the signal that the load is finished
	load_common_complete.emit()

# Backend functions handling reading and writing of data

func write_backend(name: String, object) -> bool:
	# Ensure the directory 100% exists to avoid issues
	DirAccess.make_dir_absolute(SAVE_DIR)
	
	var file_path = SAVE_DIR + name + SAVE_EXTENSION_NAME
	
	# Attempt to open new file and print an error if it fails
	var file = FileAccess.open_encrypted_with_pass(file_path, FileAccess.WRITE, KEY)
	if file == null:
		printerr("FileAccess open error: " + str(FileAccess.get_open_error()))
		return false
	
	# Create a dictionary out of the object using the parser
	var data: Dictionary = object_to_dict(object)
	
	# Write this JSON data to disk
	var json_string = JSON.stringify(data, "\t")
	file.store_string(json_string)
	file.close()
	
	return true

func write_backend_with_json_string(path: String, json_string: String) -> bool:
	# Ensure the directory 100% exists to avoid issues
	DirAccess.make_dir_absolute(SAVE_DIR)
	
	# Attempt to open new file and print an error if it fails
	var file = FileAccess.open_encrypted_with_pass(path, FileAccess.WRITE, KEY)
	if file == null:
		printerr("FileAccess open error: " + str(FileAccess.get_open_error()))
		return false
	
	# Write this data to disk
	file.store_string(json_string)
	file.close()
	
	return true

func read_backend_by_name(name: String) -> Dictionary:
	return read_backend(SAVE_DIR + name + SAVE_EXTENSION_NAME)

func read_backend(path: String) -> Dictionary:
	# Get the content of the path
	var content = read_backend_raw_data(path)
	if content == null or content.is_empty():
		return {}
	
	# Convert this content into a JSON if possible
	var data: Dictionary = JSON.parse_string(content)
	if data == null:
		printerr("Cannot parse %s as json string, data is null! (%s)" % [path, content])
		return {}
	
	# Print message saying that the dictionary is empty if needed
	if data.is_empty():
		printerr("File at %s was parsed correctly, but contains no data" % [path])
	
	# Return the JSON data to then be converted into a object later
	return data

func read_backend_raw_data(path: String) -> String:
	# Verify the file exists and return early if not
	if not FileAccess.file_exists(path):
		printerr("Cannot open non-existent file at %s" % [path])
		return ""
	
	# Open the file and return if something goes wrong (another program controlling it for example)
	var file = FileAccess.open_encrypted_with_pass(path, FileAccess.READ, KEY)
	if file == null:
		printerr("FileAccess open error: " + str(FileAccess.get_open_error()))
		return ""
	
	# Get the content of the open file
	var content = file.get_as_text()
	file.close()
	
	# Print message saying that the dictionary is empty if needed
	if content.is_empty():
		printerr("File at %s was parsed correctly, but contains no data" % [path])
	
	# Return the JSON data to then be converted into a object later
	return content

# Recursive conversion from object to JSON dictionary

func object_to_dict(obj: Object) -> Dictionary:
	# Create empty dictionary and get all properties from object
	var members = obj.get_property_list()
	var member_index: int = 0
	var dict: Dictionary = {}
	
	# Iterate through all members
	for member in members:
		member_index += 1
		if member_index <= 2:
			continue
		
		# Write the member to dictionary depending on type of member
		match(typeof(obj.get(member.name))):
			TYPE_OBJECT: # Call self and create sub-dictionary for object
				dict[member.name] = object_to_dict(obj.get(member.name))
			TYPE_ARRAY: # Expand the array with function and add to dictionary
				dict[member.name] = expand_array_for_dict(obj.get(member.name))
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

func expand_array_for_dict(list: Array) -> Array:
	# Create empty array
	var new_list: Array = []
	
	# Iterate through all items
	for item in list:
		# Write the member to dictionary depending on type of member
		match(typeof(item)):
			TYPE_OBJECT: # Call object to dict converter for item
				new_list.push_back(object_to_dict(item))
			TYPE_ARRAY: # Create sub array
				new_list.push_back(expand_array_for_dict(item))
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
