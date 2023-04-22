extends Node3D

# To keep track of gameplay elements in the current level, like gifts, we use a level script.
# This is NOT an autoload/singleton script because every level should have it's own gift collection.
# Once we switch to a different level, there should be a new collection of these gifts to collect.

const BOY_RESOURCE : PackedScene = preload("res://Objects/boy.tscn")
const GIRL_RESOURCE : PackedScene = preload("res://Objects/girl.tscn")

@onready var spawn_location : Marker3D = $SpawnLocation

var total_gifts : int = 0
var collected_gifts : int = 0

# By using the init function to save the current level in the Global
# autoload/singleton, all the other Nodes can use it in their _ready function.
func _init() -> void:
	Globals.level = self

func _ready() -> void:
	# Do not add another player character if there is already one in the scene.
	if not Globals.player == null: return
	# Check the chosen character type in the Global autoload/singleton that has been set by the character selection script.
	var player_instance = (BOY_RESOURCE if Globals.chosen_character == "boy" else GIRL_RESOURCE).instantiate()
	add_child(player_instance)
	# Position the new character instance on top of the spawn point and make it face the correct direction.
	player_instance.global_transform = spawn_location.global_transform
	# Also set the camera control direction by using the spawn point's rotation.
	player_instance.camera_look_direction.x = -spawn_location.rotation_degrees.y

func AddGift() -> void:
	total_gifts += 1

func GiftCollected() -> void:
	collected_gifts += 1
