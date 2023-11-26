# Godot SaveData DX Plugin  
*A plugin for Godot adding a simple, convenient, and secure save data system*  
![graphic](https://github.com/Amethyst-szs/godot-savedata-dx/assets/62185604/f162738a-72ee-49b7-b96c-5fa0dbad7394)  

## Explanation
This plugin was created to avoid the issues with the usual JSON or Resource saving methods used by Godot developers. Working with JSON can prove clunky and waste a lot of development time on bugs and
annoying copy-paste work, and using Resources has a major security vulnerability allowing arbitrary code execution.  

![image](https://github.com/Amethyst-szs/godot-savedata-dx/assets/62185604/aff7cde3-61be-471d-842a-462f2b907b58)

This plugin attempts to be the best of both worlds, combining the convience of the resource method with the safety and security of the JSON method. On top of that, it provides some additonal tools
to make managing your game's save files easier.

![image](https://github.com/Amethyst-szs/godot-savedata-dx/assets/62185604/cd7918e5-556f-4f30-8089-3dbc3c946b7d)

## Installation
1. Download a copy of the repo
2. Copy the `addons/savedata-dx` directory into your project's `res://addons/` directory
3. Enable under Project Settings -> Plugins
![image](https://github.com/Amethyst-szs/godot-savedata-dx/assets/62185604/11b57f7d-dcdc-4f93-a595-5612df1bf188)


## [Docs](https://github.com/Amethyst-szs/godot-savedata-dx/wiki/)
- [Core Concepts & FAQ](https://github.com/Amethyst-szs/godot-savedata-dx/wiki/Core-concepts-&-FAQ)
- [General usage](https://github.com/Amethyst-szs/godot-savedata-dx/wiki/General-Usage)
  - [Installing Plugin](https://github.com/Amethyst-szs/godot-savedata-dx/wiki/General-Usage#installing-plugin)
  - [Using SaveData menu](https://github.com/Amethyst-szs/godot-savedata-dx/wiki/General-Usage#using-savedata-menu)
    - [Inspector Mode](https://github.com/Amethyst-szs/godot-savedata-dx/wiki/General-Usage#inspector-mode)
    - [Slot Mode](https://github.com/Amethyst-szs/godot-savedata-dx/wiki/General-Usage#slot-mode)
    - [Common Mode](https://github.com/Amethyst-szs/godot-savedata-dx/wiki/General-Usage#common-mode)
- [SaveAccessor](https://github.com/Amethyst-szs/godot-savedata-dx/wiki/SaveAccessor)
  - [Active Save Slot](https://github.com/Amethyst-szs/godot-savedata-dx/wiki/SaveAccessor#active-save-slot)
  - [Writing to Disk](https://github.com/Amethyst-szs/godot-savedata-dx/wiki/SaveAccessor#writing-to-disk)
  - [Reading from Disk](https://github.com/Amethyst-szs/godot-savedata-dx/wiki/SaveAccessor#reading-from-disk)
  - [Checking for saves on Disk](https://github.com/Amethyst-szs/godot-savedata-dx/wiki/SaveAccessor#checking-for-saves-on-disk)
  - [Signals](https://github.com/Amethyst-szs/godot-savedata-dx/wiki/SaveAccessor#signals)
- [SaveHolder](https://github.com/Amethyst-szs/godot-savedata-dx/wiki/SaveHolder)
  - [Accessing Slot & Common](https://github.com/Amethyst-szs/godot-savedata-dx/wiki/SaveHolder#accessing-slot--common)
  - [Reset Functions](https://github.com/Amethyst-szs/godot-savedata-dx/wiki/SaveHolder#reset-functions)
