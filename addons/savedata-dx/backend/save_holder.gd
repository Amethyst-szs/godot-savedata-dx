extends Node

# SaveDataDX plugin by Amethyst-szs
# - SaveHolder -
#
# An autoload singleton storing and allowing access to your current save game
# and the common data shared across all save files. The common data is automatically
# read on startup if it already exists

const slot_script = preload("res://addons/savedata-dx/data_slot.gd")
const common_script = preload("res://addons/savedata-dx/data_common.gd")

# Create an empty save data slot and common file
var slot = slot_script.new()
var common = common_script.new()

func _ready():
	# Check if the common save file exists, and then read/create it
	if SaveAccessor.is_common_exist():
		SaveAccessor.read_common()
	else:
		SaveAccessor.write_common()

# Reset save data to default
func reset_slot():
	slot = slot_script.new()

func reset_common():
	common = common_script.new()

func reset_all():
	reset_common()
	reset_slot()
