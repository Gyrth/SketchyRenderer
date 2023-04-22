extends Node3D

class_name Gift

@onready var animation_player : AnimationPlayer = $AnimationPlayer
@onready var camera : Camera3D = $CameraPivot/Camera3D
@onready var camera_pivot : Node3D = $CameraPivot
@onready var collected_text : MeshInstance3D = $CollectedText

var can_be_picked_up : bool = true

func _ready() -> void:
	# Tell the levelscript to add one gift to the total amount of gifts.
	Globals.level.call_deferred("AddGift")

# The player character script will call this function to make the gift camera pivot be in line with the player camera.
func SetCameraPivotDirection(direction : Vector3) -> void:
	var flat_direction = Vector3(direction.x, 0.0, direction.z).normalized()
	camera_pivot.look_at(global_position + flat_direction)

# This function is called by the player to start picking up this gift.
func StartPickup() -> void:
	# Set the can_be_picked_up variable to false so that the pickup won't get triggered twice.
	can_be_picked_up = false
	# The level script keeps track of all the gifts in the scene and how many are already collected.
	Globals.level.GiftCollected()
	# Change the text of the mesh BEFORE triggering the animation that shows it.
	collected_text.mesh.text = "Collected\n" + str(Globals.level.collected_gifts) + "/" + str(Globals.level.total_gifts)
	animation_player.play("Open")

# The player script also triggers an animation to make this gift dissapear by scaling it down to zero.
func StartDeleteGift() -> void:
	animation_player.play("Disappear")

# Once the Dissapear animation is finished, it will call this function to remove the gift from the scene.
func DeleteGift() -> void:
	queue_free()
