extends Node3D

const MAIN_LEVEL_RESOURCE : PackedScene = preload("res://Scenes/main_level.tscn")

@onready var spotlight : SpotLight3D = $SpotLight3D
@onready var screen_effects : Node3D = $ScreenEffects
@onready var choose_fighter : MeshInstance3D = $ChooseFighter
@onready var control : Control = $Control

# Start off by turning the screen black and revealing the scene with a vignette.
func _ready() -> void:
	screen_effects.VignetteFadeIn()

func _process(_delta : float) -> void:
	# Get the mouse position over the Control Node and convert it to an x and y value that goes from 0.0 to 1.0.
	var relative_position = control.get_local_mouse_position() / control.size
	# Next we split up the mouse x value to get a value from -1.0 to 1.0.
	var spotlight_position = (relative_position.x * 2.0) - 1.0
	# The spotlight moves in the x axis to highlight the chosen character.
	spotlight.position.x = spotlight_position * 2.0
	
	# Once the user presses the left mouse button we can go to the next scene.
	if(Input.is_action_just_pressed("attack")):
		# Save the selected choice to the autoload/singleton script so that the level script can use it in the next scene.
		# If the spotlight position is negative then the left side of the screen has been clicked.
		Globals.chosen_character = "girl" if spotlight_position < 0.0 else "boy"
		# Start the fading out with the vignette effect.
		screen_effects.VignetteFadeOut()
		# Stop updating this script since we are about to leave the scene.
		set_process(false)
		# Wait a small amount of time for the vignette to close all the way.
		await get_tree().create_timer(2.0).timeout
		# Switch to the main level which will automatically clear the current scene.
		get_tree().change_scene_to_packed(MAIN_LEVEL_RESOURCE)
