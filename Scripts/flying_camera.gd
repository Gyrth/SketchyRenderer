extends Camera3D

const DELTA_OVERRIDE : float = 0.0168
const MAX_UP_AIM_ANGLE : float = 80.0
const MAX_DOWN_AIM_ANGLE : float = 80.0
const MOUSE_SENSITIVITY : float = 0.10
const VELOCITY_DAMP : float = 0.95
const LOOK_ACCELERATION : float = 0.1
const MOVEMENT_ACCELERATION : float = 0.1

var movement_velocity : Vector3 = Vector3()
var look_velocity : Vector3 = Vector3()
var mouse_down : bool = false

func _ready() -> void:
	# Hide the mouse cursor when the flying camera is added to the scene.
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# Make the obstruction checker use the Node in front of the flying camera to make it work while inspecting the scene.
	Globals.wall_obstruction_checker.center_node = $ObstructionCheckCenter
	Globals.wall_obstruction_checker.center_weight = 0.65
	# Keep updating this camera controller even if the scene is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS

func _notification(what : int) -> void:
	if what == NOTIFICATION_PREDELETE:
		# Once this flying camera has been deleted, return the obstruction check back to the player.
		Globals.wall_obstruction_checker.center_node = Globals.player.camera_control
		Globals.wall_obstruction_checker.center_weight = 0.65

func _process(_delta : float) -> void:
	var forward_direction = -global_transform.basis.z
	var right_direction = global_transform.basis.x
	var up_direction = global_transform.basis.y
	
	# When you press Shift, change the forward and backward direction to up and down.
	if Input.is_action_pressed("crouch"):
		forward_direction = up_direction
	
	# By using get_vector, multiple inputs can be combined into a single vector for movement direction.
	var movement_input = Input.get_vector("right", "left", "down", "up")
	# Use a consistent delta so that camera movement stays the same even if Engine.time_scale is not 1.0. (slowmotion)
	movement_velocity += (-movement_input.x * right_direction) * DELTA_OVERRIDE * MOVEMENT_ACCELERATION
	movement_velocity += (movement_input.y * forward_direction) * DELTA_OVERRIDE * MOVEMENT_ACCELERATION
	
	# Multiply the movement velocity of the camera by a value more than one when the spacebar is pressed to speed it up.
	if Input.is_action_pressed("jump"):
		movement_velocity *= 1.05
	# Multiply by a value of less than one to make it slow down.
	elif Input.is_action_pressed("slow_walk"):
		movement_velocity *= 0.75
	# Continuesly check if the mouse is currently pressed.
	mouse_down = Input.is_action_pressed("attack")
	
	# Finally apply the movement to the camera.
	global_transform.origin += movement_velocity
	rotation_degrees += look_velocity
	
	# Make sure the rotation of the camera is in between the maximum values.
	if rotation_degrees.x > MAX_UP_AIM_ANGLE:
		rotation_degrees.x = MAX_UP_AIM_ANGLE
	elif rotation_degrees.x < -MAX_DOWN_AIM_ANGLE:
		rotation_degrees.x = -MAX_DOWN_AIM_ANGLE
	
	# Slowly reduce the amount of velocity so that the camera movements are smooth.
	movement_velocity = movement_velocity * VELOCITY_DAMP
	look_velocity = look_velocity * VELOCITY_DAMP

func _input(event : InputEvent) -> void:
	# The mouse movement needs to be checked in the _input function while button presses can be check in _process.
	if event is InputEventMouseMotion:
		# The camera can only look around when the left mouse button is pressed.
		if mouse_down:
			look_velocity.y -= event.relative.x * MOUSE_SENSITIVITY * LOOK_ACCELERATION
			look_velocity.x -= event.relative.y * MOUSE_SENSITIVITY * LOOK_ACCELERATION
