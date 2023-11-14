# Godot SaveData DX Plugin
*A plugin for Godot adding a simple, convenient, and secure save data system*  
  
![Banner](https://github.com/Amethyst-szs/godot-savedata-dx/assets/62185604/096e49b6-a26b-4283-8ac6-555dfb7ffb5b)

## Explanation
This plugin was created to avoid the issues with the usual JSON or Resource saving methods used by Godot developers. Working with JSON can prove clunky and waste a lot of development time on bugs and
annoying copy-paste work, and using Resources has a major security vulnerability allowing arbitrary code execution.  
  
This plugin attempts to be the best of both worlds, combining the convience of the resource method with the safety and security of the JSON method. On top of that, it provides some additonal tools
to make managing your game's save files easier.

## Usage
### What is Common vs. Slot
There are two types of save file, common and slot.  
  
**Common** is automatically read when launching the program and should be shared between all save files. This is useful for things like settings, controller config, and other global changes.  
  
**Slot** is the info specific to this save slot, things related to game progression would go here. This lets the player have seperate playthroughs of the game. There is no limit to the max amount of slots you can create.

  
### Writing/Reading/Accessing save data
The plugin has two autoloaded singletons that can be accessed from your scripts, `SaveAccessor` and `SaveHolder`.  
  
`SaveAccessor` features a bunch of methods for saving, loading, and checking various save data. 
  
`SaveHolder` contains the active save slot data and the common save file data and can be access from anywhere in your godot project.  

  
### Adding properties to save
To add more content to your save files, open `res://addons/savedata-dx/` and navigate to either `common` or `slot`. These contain scripts that you can add properties to. These can be accessed from anywhere
in your code and are automatically saved by the plugin, no extra work required!  

To further organize your additonal properties, you can make new resources as additonal scripts and add them into your save data! Just remember to declare the `START` variable at the beginning of your script
so the plugin is able to find all of properties.

## Installation

1. Download a copy of the repo
2. Copy the `addons/savedata-dx` directory into your project's `res://addons/` directory
3. Enable under Project Settings -> Plugins
![image](https://github.com/Amethyst-szs/godot-savedata-dx/assets/62185604/11b57f7d-dcdc-4f93-a595-5612df1bf188)
