extends Node

## SaveDataDX plugin by Amethyst-szs - 
## Stores and allows access to your current save data
## This class is meant to be used an autoload singleton,
## access it via "SaveHolder" in your scritps. 
class_name SaveHolderPlugin

# Load in scripts

## Preload script for save slot
const slot_script = preload("res://addons/savedata-dx/data_slot.gd")
## Preload script for common data
const common_script = preload("res://addons/savedata-dx/data_common.gd")

# Create a new slot and common file using their default values

## Access and modify your save slot
var slot: slot_script = slot_script.new()
## Access and modify your common data
var common: common_script = common_script.new()

func _ready():
	# Check if the common save file exists, and then read/create it
	if SaveAccessor.is_common_exist():
		SaveAccessor.read_common()
	else:
		SaveAccessor.write_common()

## Resets the data in the slot variable to default
func reset_slot():
	SaveAccessor._free_object_and_subobjects([slot])
	slot = slot_script.new()

## Resets the data in the common variable to default
func reset_common():
	SaveAccessor._free_object_and_subobjects([common])
	common = common_script.new()

## Resets the data in the slot and common variable to default. 
## Not recommended unless you're including a full "factory reset" style feature
func reset_all():
	reset_common()
	reset_slot()
