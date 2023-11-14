extends Node

# SaveDataDX plugin by Amethyst-szs
# - SaveHolder -
#
# An autoload singleton storing and allowing access to your current save game
# and the common data shared across all save files. The common data is automatically
# read on startup if it already exists

# Create an empty save data slot and common file
@onready var slot: SaveDataRoot = SaveDataRoot.new()
@onready var common: SaveDataCommon = SaveDataCommon.new()

func _ready():
	# Check if the common save file exists, and then read/create it
	if SaveAccessor.is_common_exist():
		SaveAccessor.read_common()
	else:
		SaveAccessor.write_common()
