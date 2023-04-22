extends Node3D

const CAMERA_OFFSET : Vector3 = Vector3(0.0, 0.5, 0.0)
const POSITION_INTERPOLATION_SPEED : float  = 10.0
const CAMERA_ZOOM_INTERPOLATION_SPEED : float = 15.0;

@onready var camera : Camera3D = $Camera3D

var target : Node3D = null
var look : Vector2 = Vector2.ZERO
var target_camera_z : float = 1.0

func _ready() -> void:
	# For setting up the camera control, make sure the camera position is at the target and the zoom level is correct.
	global_position = target.global_position + CAMERA_OFFSET
	camera.position.z = target_camera_z

func _process(delta : float) -> void:
	# The zoom and positional lerping is done separately so they can have different interpolation speeds.
	camera.position.z = lerp(camera.position.z, target_camera_z, delta * CAMERA_ZOOM_INTERPOLATION_SPEED)
	# Rotating the camera pivot should be snappy and responsive, so don't apply any lerping to that.
	rotation_degrees = Vector3(look.y, look.x, 0)
	# Also add a height offset so that the character is nicely framed vertically.
	global_position = lerp(global_position, target.global_position + CAMERA_OFFSET, delta * POSITION_INTERPOLATION_SPEED)
