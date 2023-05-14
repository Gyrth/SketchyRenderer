extends Node3D

@onready var vignette : ColorRect = $Vignette
@onready var sketchy_mesh : MeshInstance3D = $Sketchy
@onready var sobel_mesh : MeshInstance3D = $Sobel
@onready var sketchy_material : ShaderMaterial = sketchy_mesh.get_surface_override_material(0)
@onready var sobel_material : ShaderMaterial = sobel_mesh.get_surface_override_material(0)

var tween : Tween = null

func _ready() -> void:
	# Start receiving settings changes from the signal in the Globals autoload/singleton.
	Globals.connect("settings_event", Callable(self, "SettingsChanged"))

func _notification(what : int) -> void:
	# If this screen effect is removed before the Tween is done, then just kill it to prevent Tweens fighting over shader parameters.
	if what == NOTIFICATION_PREDELETE:
		KillTween()

func KillTween() -> void:
	# Before starting a new Tween, kill any running Tween so that the shader parameters are set correctly.
	if tween != null and tween.is_running():
		tween.kill()

func VignetteFadeIn() -> void:
	KillTween()
	# Before starting to fade in, make the whole screen black by setting the shader parameter directly.
	vignette.material.set_shader_parameter("vignette_open", 0.0)
	tween = get_tree().create_tween()
	# Do not allow this Tween to be paused by pressed Escape while fading in for example.
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	# Add some easing to make the transition a bit smoother.
	tween.set_trans(Tween.TRANS_QUINT)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(vignette.material, "shader_parameter/vignette_open", 1.0, 2.0).from(0.0).set_delay(0.25)

func VignetteFadeOut() -> void:
	KillTween()
	tween = get_tree().create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_trans(Tween.TRANS_QUINT)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(vignette.material, "shader_parameter/vignette_open", 0.0, 1.0).from(1.0)

func _process(_delta : float) -> void:
	# Move the whole screen effects setup in the view of the current camera.
	# It doesn't matter is it's the player camera, flying camera or camera inside the gift.
	var camera = get_viewport().get_camera_3d()
	global_transform = camera.global_transform

func SettingsChanged(parameters : Dictionary) -> void:
	# The settings change parameter uses a Dictionary to store the values so that any variable type can be used.
	if parameters.setting == "noise_offset":
		# Get the value out of the Dictionary and apply it to the material that's shown on screen.
		sketchy_material.set_shader_parameter("noise_offset_multiplier", parameters.value)
		sobel_material.set_shader_parameter("noise_offset_multiplier", parameters.value)
	elif parameters.setting == "black_threshold":
		sketchy_material.set_shader_parameter("black_threshold", parameters.value)
		sobel_material.set_shader_parameter("black_threshold", parameters.value)
	elif parameters.setting == "white_threshold":
		sketchy_material.set_shader_parameter("white_threshold", parameters.value)
		sobel_material.set_shader_parameter("white_threshold", parameters.value)
	elif parameters.setting == "grain_amount":
		sketchy_material.set_shader_parameter("grain_amount", parameters.value)
		sobel_material.set_shader_parameter("grain_amount", parameters.value)
	elif parameters.setting == "line_size":
		sketchy_material.set_shader_parameter("line_size", parameters.value)
		sobel_material.set_shader_parameter("line_size", parameters.value)
	elif parameters.setting == "color_passthrough":
		sketchy_material.set_shader_parameter("color_passthrough", parameters.value)
		sobel_material.set_shader_parameter("color_passthrough", parameters.value)
	elif parameters.setting == "depth_check":
		sketchy_material.set_shader_parameter("depth_check", parameters.value)
		sobel_material.set_shader_parameter("depth_check", parameters.value)
	elif parameters.setting == "normal_check":
		sketchy_material.set_shader_parameter("normal_check", parameters.value)
		sobel_material.set_shader_parameter("normal_check", parameters.value)
	elif parameters.setting == "tint_color":
		sketchy_material.set_shader_parameter("tint_color", parameters.color)
		sobel_material.set_shader_parameter("tint_color", parameters.color)
	elif parameters.setting == "screen_effect":
		sketchy_mesh.visible = true if parameters.value == 0 else false
		sobel_mesh.visible = true if parameters.value == 1 else false
