extends Control

@onready var main_window : Control = $MainWindow
@onready var background : ColorRect = $MainWindow/Background
@onready var window_mode : OptionButton = $MainWindow/SettingsWindow/VBoxContainer/WindowMode/OptionButton
@onready var screen_effect : OptionButton = $MainWindow/SettingsWindow/VBoxContainer/ScreenEffect/OptionButton
@onready var noise_offset : HSlider = $MainWindow/SettingsWindow/VBoxContainer/NoiseOffset/Value
@onready var black_threshold : HSlider = $MainWindow/SettingsWindow/VBoxContainer/BlackThreshold/Value
@onready var white_threshold : HSlider = $MainWindow/SettingsWindow/VBoxContainer/WhiteThreshold/Value
@onready var grain_amount : HSlider = $MainWindow/SettingsWindow/VBoxContainer/GrainAmount/Value
@onready var line_size : HSlider = $MainWindow/SettingsWindow/VBoxContainer/LineSize/Value
@onready var color_passthrough : CheckBox = $MainWindow/SettingsWindow/VBoxContainer/ColorPassthrough/CheckBox
@onready var depth_check : CheckBox = $MainWindow/SettingsWindow/VBoxContainer/DepthCheck/CheckBox
@onready var normal_check : CheckBox = $MainWindow/SettingsWindow/VBoxContainer/NormalCheck/CheckBox
@onready var tint_color : ColorPicker = $MainWindow/SettingsWindow/VBoxContainer/TintColor/Color
@onready var continue_button : Button = $MainWindow/SettingsWindow/HBoxContainer/Continue
@onready var quit_button : Button = $MainWindow/SettingsWindow/HBoxContainer/Quit

var tween : Tween = null
var show_settings : bool = false
var mouse_over : bool = false
var background_alpha : float = 0.0

func _ready() -> void:
	# When the settings UI is shown the scene is paused, so keep processing this 
	# Node even if the scene tree is paused. This will make the UI keep responding to input.
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Hide the settings UI by default.
	main_window.scale = Vector2(0.0, 0.0)
	# Connect all the signals that are emitted by the UI elements to the correct function.
	window_mode.connect("item_selected", Callable(self, "WindowModeChanged"))
	screen_effect.connect("item_selected", Callable(self, "ScreenEffectChanged"))
	noise_offset.connect("value_changed", Callable(self, "NoiseOffsetChanged"))
	black_threshold.connect("value_changed", Callable(self, "BlackThresholdChanged"))
	white_threshold.connect("value_changed", Callable(self, "WhiteThresholdChanged"))
	grain_amount.connect("value_changed", Callable(self, "GrainAmountChanged"))
	line_size.connect("value_changed", Callable(self, "LineSizeChanged"))
	color_passthrough.connect("toggled", Callable(self, "ColorPassthroughChanged"))
	depth_check.connect("toggled", Callable(self, "DepthCheckChanged"))
	normal_check.connect("toggled", Callable(self, "NormalCheckChanged"))
	tint_color.connect("color_changed", Callable(self, "TintColorChanged"))
	continue_button.connect("pressed", Callable(self, "ContinuePressed"))
	quit_button.connect("pressed", Callable(self, "QuitPressed"))

func _notification(what : int) -> void:
	# If this screen effect is removed before the Tween is done, then just kill it to prevent Tweens fighting over shader parameters.
	if what == NOTIFICATION_PREDELETE:
		KillTween()

func KillTween() -> void:
	# Before starting a new Tween, kill any running Tween so that the shader parameters are set correctly.
	if tween != null and tween.is_running():
		tween.kill()

func _process(delta : float) -> void:
	var rect = background.get_global_rect()
	var mouse_position = background.get_global_mouse_position()
	mouse_over = rect.has_point(mouse_position)
	
	background_alpha = lerp(background_alpha, 0.8 if mouse_over and show_settings else 0.05, delta * 10.0)
	main_window.modulate.a = background_alpha
	
	# Toggle between showing and hiding the settings UI when pressing escape.
	if Input.is_action_just_pressed("escape"):
		if show_settings:
			HideSettings()
		else:
			ShowSettings()

func ContinuePressed() -> void:
	HideSettings()

func QuitPressed() -> void:
	get_tree().quit()

func ShowSettings() -> void:
	get_tree().paused = true
	show_settings = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	main_window.process_mode = Node.PROCESS_MODE_INHERIT
	
	KillTween()
	tween = get_tree().create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(main_window, "scale", Vector2(1.0, 1.0), 0.25).from(Vector2(0.0, 0.0))

func HideSettings() -> void:
	get_tree().paused = false
	show_settings = false
	# Change the mouse mode to show the curser when it's needed.
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	main_window.process_mode = Node.PROCESS_MODE_DISABLED
	
	KillTween()
	tween = get_tree().create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(main_window, "scale", Vector2(0.0, 0.0), 0.25).from(Vector2(1.0, 1.0))

func WindowModeChanged(value : int) -> void:
	if window_mode.get_item_text(value) == "Windowed":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
	elif window_mode.get_item_text(value) == "Borderless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	elif window_mode.get_item_text(value) == "Fullscreen":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)

func ScreenEffectChanged(value : float) -> void:
	Globals.emit_signal("settings_event", {"setting" : "screen_effect", "value" : value})

func NoiseOffsetChanged(value : float) -> void:
	# Convert the signal value into a setting event by putting it into a Dictionary.
	Globals.emit_signal("settings_event", {"setting" : "noise_offset", "value" : value})

func BlackThresholdChanged(value : float) -> void:
	# The screen effects Node will listen to this signal and apply the setting to the sketchy material.
	Globals.emit_signal("settings_event", {"setting" : "black_threshold", "value" : value})

func WhiteThresholdChanged(value : float) -> void:
	Globals.emit_signal("settings_event", {"setting" : "white_threshold", "value" : value})

func GrainAmountChanged(value : float) -> void:
	Globals.emit_signal("settings_event", {"setting" : "grain_amount", "value" : value})

func ColorPassthroughChanged(value : float) -> void:
	Globals.emit_signal("settings_event", {"setting" : "color_passthrough", "value" : value})

func DepthCheckChanged(value : float) -> void:
	Globals.emit_signal("settings_event", {"setting" : "depth_check", "value" : value})

func NormalCheckChanged(value : float) -> void:
	Globals.emit_signal("settings_event", {"setting" : "normal_check", "value" : value})

func LineSizeChanged(value : float) -> void:
	Globals.emit_signal("settings_event", {"setting" : "line_size", "value" : value})

func TintColorChanged(color : Color) -> void:
	Globals.emit_signal("settings_event", {"setting" : "tint_color", "color" : color})
