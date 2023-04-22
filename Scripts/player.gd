extends CharacterBody3D

enum CharacterStates{
	None,
	Idle,
	Walk,
	Pickup
}

enum PickupStages{
	None,
	CameraTransitionIn,
	Opening,
	CameraTransitionOut
}

const ROTATION_INTERPOLATE_SPEED : float = 8.0
const ZOOM_STEP_SIZE : float = 0.2
const MAX_UP_AIM_ANGLE : float = 25.0
const MAX_DOWN_AIM_ANGLE : float = 75.0
const MOUSE_SENSITIVITY : float = 0.10
const CHARACTER_RUN_INTERPOLATION_SPEED : float = 15.0
const MOTION_INTERPOLATION_SPEED : float = 8.0
const PLAYER_CAMERA_RESOURCE = preload("res://Objects/player_camera.tscn")
const SCREEN_EFFECTS_RESOURCE = preload("res://Objects/screen_effects.tscn")

@onready var animation_tree : AnimationTree = $AnimationTree
@onready var footstep : AudioStreamPlayer3D = $Footstep
@onready var pelvis : BoneAttachment3D = find_child("Pelvis")

# The movement speed of the character can be changed to match the animation.
@export var movement_speed : float = 2.0

# Variables used for character movement.
var run_speed : float = 0.0
var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity")
var character_state : CharacterStates = CharacterStates.Idle
var motion : Vector2 = Vector2.ZERO
var gravity_velocity : Vector3 = Vector3.ZERO
var footstep_sound_type : String = "concrete"
# Variables used for camera control and effects.
var camera_control = Node3D
var screen_effects = Node3D
var camera = Camera3D
var camera_look_direction = Vector2.ZERO
# Variables used picking up gifts.
var pickup_stage : PickupStages = PickupStages.None
var target_gift : Gift = null
var transform_from = Transform3D()
var transform_to = Transform3D()
var transition_timer : float = 0.0

func _ready() -> void:
	# The camera setup and screen effects are added in script so that it's not a child
	# of the character but rather a child of the whole scene that moves independently.
	camera_control = PLAYER_CAMERA_RESOURCE.instantiate()
	screen_effects = SCREEN_EFFECTS_RESOURCE.instantiate()
	# The camera centers around the pelvis of the character so that most of the character is in frame.
	camera_control.target = pelvis
	Globals.level.add_child.call_deferred(camera_control)
	Globals.level.add_child.call_deferred(screen_effects)
	# Using call_deferred will make sure the scene is fully loaded before using the vignette and obstruction checker.
	screen_effects.call_deferred("VignetteFadeIn")
	call_deferred("SetupWallObstructionChecker")
	# Find the camera Node inside the camera control asset so that we can make it the current/active camera.
	camera = camera_control.get_node("Camera3D")
	camera.current = true
	# Hide the mouse cursor when this character takes control.
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# Store the player in a variable in the Globals autoload/singleton script so that any script can send messages here.
	Globals.player = self
	footstep.max_distance = 7.0

func SetupWallObstructionChecker():
	Globals.wall_obstruction_checker.center_node = camera_control
	Globals.wall_obstruction_checker.center_weight = 0.65

# Since Nodes don't have a destructor we need to use the notification function/method to know when the character gets deleted.
func _notification(what : int) -> void:
	if what == NOTIFICATION_PREDELETE:
		# Delete the camera setup and screen effects when this character gets deleted
		# because a new instance will create it's own camera and screen effects.
		if is_instance_valid(camera_control):
			camera_control.queue_free()
		if is_instance_valid(screen_effects):
			screen_effects.queue_free()

func _process(delta : float) -> void:
	UpdateCharacterState(delta)
	# This script keeps track of the look direction and passes it along to the camera control.
	camera_control.look = camera_look_direction

func UpdateCharacterState(delta : float) -> void:
	# This character uses a StateMachine to control what a character can and cannot do.
	match character_state:
		CharacterStates.Idle:
			# For example when the character is Idle, the footstep can not be triggered.
			UpdateIdle(delta)
		CharacterStates.Walk:
			UpdateWalk(delta)
		CharacterStates.Pickup:
			# And when picking up a gift, the input is temporarily ignored. 
			UpdatePickup(delta)

func UpdateIdle(_delta : float) -> void:
	# When the character is in the Idle state and the velocity is above a threshold, it switches to Walk.
	if motion.length() > 0.1:
		character_state = CharacterStates.Walk

func UpdateWalk(_delta : float) -> void:
	# While the character is walking and the velocity falls below a threshold, it goes into the Idle state.
	if motion.length() < 0.1:
		character_state = CharacterStates.Idle

func _physics_process(delta : float) -> void:
	# Just skip updating the physics process when the media mode is active or the camera isn't ready yet.
	if Globals.media_mode: return
	if not camera.is_inside_tree(): return
	
	# First get the direction of the input before we apply it.
	var input_direction = GetInputDirection()
	motion = motion.lerp(Vector2(input_direction.x, input_direction.z) * movement_speed, MOTION_INTERPOLATION_SPEED * delta)
	var target_movement = Vector3(motion.x, 0.0, motion.y)
	# Keep adding gravity so that it accumulates and the character falls faster and faster.
	gravity_velocity.y -= gravity * delta
	# Add the gravity velocity to the target movement so we can use one Vector3 for the move_and_slide.
	target_movement += gravity_velocity
	
	if not is_zero_approx(target_movement.length()):
		set_velocity(target_movement)
		move_and_slide()
		var travel = get_position_delta() / delta
		
		var result_length = travel.length() / target_movement.length()
		# Reduce the motion amount by how much the motion is blocked.
		if is_on_floor():
			motion = motion * clamp(result_length, 0.1, 1.0)
			# Set the gravity velocity to zero when the character is standing on solid ground.
			gravity_velocity = Vector3.ZERO
	
	# Add some slerping to the animation run speed so that the walking looks smoother when switching between idle and walk.
	run_speed = lerp(run_speed, motion.length(), delta * CHARACTER_RUN_INTERPOLATION_SPEED)
	animation_tree["parameters/RunBlend/blend_position"] = run_speed
	
	# Slowly rotation the character in the direction it's going.
	if not is_zero_approx(Vector2(velocity.x, velocity.z).length()):
		var angle = atan2(velocity.x, velocity.z)
		var target_rotation = Basis(Vector3.UP, angle)
		global_transform.basis = global_transform.basis.orthonormalized().slerp(target_rotation, delta * ROTATION_INTERPOLATE_SPEED)

func GetInputDirection() -> Vector3:
	# Return an empty input direction when picking up a gift and skip getting the input vector.
	if character_state == CharacterStates.Pickup:
		return Vector3.ZERO
	
	# The movement of the character is relative to the camera orientation.
	var right_direction = camera.global_transform.basis.x
	var forward_direction = -camera.global_transform.basis.z
	
	# Make sure the direction is flat and normalized so that the movement is consistent.
	forward_direction.y = 0.0
	forward_direction = forward_direction.normalized()
	
	# When using a controller the vector can also be somewhere between 0.0 - 1.0.
	# So the movement is slower when the controller stick is slightly moved.
	var movement_input = Input.get_vector("right", "left", "down", "up")
	return (-movement_input.x * right_direction) + (movement_input.y * forward_direction)

func _input(event : InputEvent) -> void:
	# Stop listening to input when the media mode is enabled or the character is picking up a gift.
	if Globals.media_mode: return
	if character_state == CharacterStates.Pickup: return
	
	# Pass along the scroll events to the camera control Node so that it can zoom in and out.
	if event.is_action_pressed("scroll_up"):
		# Use the step size as a zoom base value and then make it zoom faster based on distance.
		camera_control.target_camera_z = max(0.5, camera.position.z - ZOOM_STEP_SIZE * camera_control.target_camera_z)
	elif event.is_action_pressed("scroll_down"):
		camera_control.target_camera_z = min(5.0, camera.position.z + ZOOM_STEP_SIZE * camera_control.target_camera_z)
	if event.is_action_pressed("pickup"):
		GiftPickupCheck()
	
	if event is InputEventMouseMotion:
		camera_look_direction.x -= event.relative.x * MOUSE_SENSITIVITY
		camera_look_direction.y -= event.relative.y * MOUSE_SENSITIVITY
		
		# The look direction is stored in degrees so it's easier to limit the angles.
		if camera_look_direction.x > 360:
			camera_look_direction.x = 0
		elif camera_look_direction.x < 0:
			camera_look_direction.x = 360
		if camera_look_direction.y > MAX_UP_AIM_ANGLE:
			camera_look_direction.y = MAX_UP_AIM_ANGLE
		elif camera_look_direction.y < -MAX_DOWN_AIM_ANGLE:
			camera_look_direction.y = -MAX_DOWN_AIM_ANGLE

func PlayFootstep() -> void:
	# Do not allow footsteps to play when the character is Idle.
	if character_state == CharacterStates.Idle: return
	# Pick a random footstep sound and start playing it.
	var number = randi() % 5
	footstep.stream = load("res://Sounds/footstep_" + footstep_sound_type + "_00" + str(number) + ".ogg")
	footstep.play()

# When the player presses E a check is done to see if there are gifts nearby that can be picked up.
func GiftPickupCheck() -> void:
	# Do not allow another gift pickup check when we are already picking one up.
	if character_state == CharacterStates.Pickup: return
	# Use a sphere collider to check for nearby gifts.
	var space_state = get_world_3d().get_direct_space_state()
	var params = PhysicsShapeQueryParameters3D.new()
	var sphere = SphereShape3D.new()
	
	sphere.radius = 1.0
	params.set_shape(sphere)
	params.transform.origin = global_transform.origin
	# Limit the amount of colliders that need to be checked by the engine, by only using the GIFT layer.
	var layers = pow(2, Globals.GIFT_LAYER)
	params.collision_mask = layers
	var results = space_state.intersect_shape(params)
	var closest_gift = null
	var closest_gift_distance = 0.0
	
	# If there are multiple gifts within the collision sphere, then we need to see which one is closest.
	for result in results:
		var collider = result.collider
		# Only gifts that are able to be picked up are candidates.
		if collider.can_be_picked_up:
			var gift_distance = global_position.distance_to(collider.global_position)
			# If this is the first gift that's found OR the distance is smaller than this is a winner.
			if closest_gift == null or gift_distance < closest_gift_distance:
				closest_gift = collider
				# Store the distance as well to compare with the next gift.
				closest_gift_distance = gift_distance
	
	# When a valid gift is found, switch character state to Pickup and let that handle all the stages.
	if closest_gift != null:
		target_gift = closest_gift
		character_state = CharacterStates.Pickup

func UpdatePickup(delta : float) -> void:
	# Picking up a gift goes through a couple of stages in order which can be timed and synced with animations.
	match pickup_stage:
		# When first entering the Pickup state, we need to setup some values.
		PickupStages.None:
			# Set the camera pivot of the gift into the correct direction of the player camera.
			target_gift.SetCameraPivotDirection(-camera.global_transform.basis.z)
			# Make the obstruction checker use the text mesh as the center Node so that walls don't hide it.
			Globals.wall_obstruction_checker.center_node = target_gift.collected_text
			Globals.wall_obstruction_checker.center_weight = 0.0
			# The transition from the player camera to the gift camera uses these transforms.
			transform_from = camera.global_transform
			transform_to = target_gift.camera.global_transform
			# The timer is used to go from 0.0 - 1.0.
			transition_timer = 0.0
			# Position the camera at the start position.
			target_gift.camera.global_transform = transform_from
			# Set the current/active camera to the one inside the gift scene.
			target_gift.camera.current = true
			camera.current = false
			# Move to the next stage of picking up the gift.
			pickup_stage = PickupStages.CameraTransitionIn
			# Also make the character start animating using a pickup character animation.
			animation_tree["parameters/Pickup/request"] = 1
		PickupStages.CameraTransitionIn:
			# Applying the delta * 2.0 result in a transition of 0.5 seconds.
			transition_timer += delta * 2.0
			# Slowly interpolate the camera transform from the start to end with a easing function to make it even smoother.
			target_gift.camera.global_transform = transform_from.interpolate_with(transform_to, easeInOutQuad(transition_timer))
			# Make the character rotate into the direction of the gift, so they are facing it.
			var target_direction = (target_gift.global_position - global_position).normalized()
			var angle = atan2(target_direction.x, target_direction.z)
			var target_rotation = Basis(Vector3.UP, angle)
			global_transform.basis = global_transform.basis.orthonormalized().slerp(target_rotation, delta * ROTATION_INTERPOLATE_SPEED)
			# Once the timer reached 1.0 it will trigger the pickup animation of the gift that stretches and opens the box.
			if transition_timer >= 1.0:
				target_gift.StartPickup()
				# Reset the timer so that it can be used in the next stage.
				transition_timer = 0.0
				pickup_stage = PickupStages.Opening
		PickupStages.Opening:
			transition_timer += delta
			# The gift will animate around 3 seconds en open up, so wait for that to finish.
			if transition_timer >= 3.0:
				# To transition the camera back to the player we use the global transform in reverse.
				transform_from = target_gift.camera.global_transform
				transform_to = camera.global_transform
				transition_timer = 0.0
				pickup_stage = PickupStages.CameraTransitionOut
				# The gift can delete itself when it's picked up by animating it shrinking and using queue_free at the end.
				target_gift.StartDeleteGift()
				Globals.wall_obstruction_checker.center_node = camera_control
				Globals.wall_obstruction_checker.center_weight = 0.65
		PickupStages.CameraTransitionOut:
			transition_timer += delta
			# Now the camera transform interpolation is used to go back to the player camera.
			target_gift.camera.global_transform = transform_from.interpolate_with(transform_to, easeInOutQuad(transition_timer))
			# Once it reaches the end of the interpolation, switch back to the player camera and make the character controllable again with an Idle state.
			if transition_timer >= 1.0:
				camera.current = true
				target_gift.camera.current = false
				pickup_stage = PickupStages.None
				character_state = CharacterStates.Idle

# This easing function is used to smoothly transition from the player camera to the gift camera and back.
func easeInOutQuad(x : float) -> float:
	return 2.0 * x * x if x < 0.5 else 1.0 - pow(-2.0 * x + 2.0, 2.0) / 2.0
