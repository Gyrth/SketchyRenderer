extends Node

# Since these resources don't change, we can use constant values to store the assets.
const MEDIA_MODE_CAMERA_RESOURCE : PackedScene = preload("res://Objects/media_mode_camera.tscn")
const BOY_RESOURCE : PackedScene = preload("res://Objects/boy.tscn")
const GIRL_RESOURCE : PackedScene = preload("res://Objects/girl.tscn")
const MAN_RESOURCE : PackedScene = preload("res://Objects/man.tscn")

# The collision layers are used to control which objects can collide and in which order.
# For example the CHARACTER layer can push around object in the LOOSE layer, but not the other way around.
const ENVIRONMENT_LAYER = 0
const CHARACTER_LAYER = 1
const GIFT_LAYER = 2
const LOOSE_LAYER = 3
const WALL_LAYER = 4

# A flying camera can be added the scene to inspect the scene or record videos.
var media_mode_camera : Camera3D = null
# The player script will stop reacting to input when the media mode is active.
var media_mode : bool = false
# Store the Node at the top level of the scene, and use that as the main level Node.
var level : Node = null
# Keep a reference to the previous camera so that we can return to it when media mode is turned off.
var previous_camera : Camera3D = null
# This script has some debug keys to switch to a different character model.
# So keep a reference to the current player model that can be removed once switching is requested.
var player : CharacterBody3D = null
var wall_obstruction_checker : Node3D = null
# This value is set in the character selection scene and read by the level script to spawn the correct character model.
var chosen_character : String = "boy"

# Using a signal in this autoload/singleton script means that both settings UI and the screen effect script can quickly send
# and receive setting events. This will also work when there are multiple settings UI's or screen effects in the scene.
signal settings_event

func _ready() -> void:
	# Keep updating this script even if the scene is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event : InputEvent) -> void:
	# If the level is not ready yet, then skip checking the input.
	if level == null: return
	
	# The media mode button is bound to F5 currently.
	if event.is_action_pressed("media_mode"):
		ToggleMediaMode()
	# Do not allow character switching when the scene is paused.
	if get_tree().paused: return
	# These numbers are used to switch to a different character model for debug purposes.
	elif event.is_action_pressed("1"):
		SwitchToCharacter(BOY_RESOURCE)
	elif event.is_action_pressed("2"):
		SwitchToCharacter(GIRL_RESOURCE)
	elif event.is_action_pressed("3"):
		SwitchToCharacter(MAN_RESOURCE)

func SwitchToCharacter(resource : PackedScene) -> void:
	# Make sure the player is inside the scene before trying to delete it.
	if not is_instance_valid(player): return
	var old_transform = player.global_transform
	var old_camera_look_direction = player.camera_look_direction
	var old_target_camera_z = player.camera_control.target_camera_z
	# Add the new character instance to the scene and delete the old one.
	var player_instance = resource.instantiate()
	player.queue_free()
	level.add_child(player_instance)
	# Use the same global transform of the old character so it's at the same position and rotation.
	player_instance.global_transform = old_transform
	player_instance.camera_look_direction = old_camera_look_direction
	player_instance.camera_control.target_camera_z = old_target_camera_z

func ToggleMediaMode() -> void:
	# Flip the boolean to make it toggle the media mode.
	media_mode = !media_mode
	
	if media_mode:
		# By enabling the media mode we first need to get the current camera transform.
		previous_camera = get_viewport().get_camera_3d()
		var previous_camera_transform = previous_camera.global_transform
		# Then create a new instance of the flying camera.
		media_mode_camera = MEDIA_MODE_CAMERA_RESOURCE.instantiate()
		# And add it to the scene as a child of the level Node.
		level.add_child(media_mode_camera)
		# Set the flying camera transform to be the same as the player camera.
		media_mode_camera.global_transform = previous_camera_transform
		# Then switch from the player camera to the media mode camera.
		previous_camera.current = false
		media_mode_camera.current = true
	else:
		# When disabling the media mode we just delete the flying camera first.
		media_mode_camera.queue_free()
		# Check if there was a camera BEFORE the flying camera that was active.
		if previous_camera:
			# Make that the active camera and clear the variable, done.
			previous_camera.current = true
			previous_camera = null
