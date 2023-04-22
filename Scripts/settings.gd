extends Control

@onready var main_window : Control = $MainWindow
@onready var window_mode_option : OptionButton = $MainWindow/VBoxContainer/WindowMode/OptionButton
@onready var screen_effect_option : OptionButton = $MainWindow/VBoxContainer/ScreenEffect/OptionButton
@onready var noise_offset_slider : HSlider = $MainWindow/VBoxContainer/NoiseOffset/Value
@onready var shadow_amount_slider : HSlider = $MainWindow/VBoxContainer/ShadowAmount/Value
@onready var grain_amount_slider : HSlider = $MainWindow/VBoxContainer/GrainAmount/Value
@onready var line_size_slider : HSlider = $MainWindow/VBoxContainer/LineSize/Value
@onready var tint_color_picker : ColorPicker = $MainWindow/VBoxContainer/TintColor/Color

func _ready() -> void:
	# When the settings UI is shown the scene is paused, so keep processing this 
	# Node even if the scene tree is paused. This will make the UI keep responding to input.
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Hide the settings UI by default.
	main_window.visible = false
	# Connect all the signals that are emitted by the UI elements to the correct function.
	window_mode_option.connect("item_selected", Callable(self, "WindowModeChanged"))
	screen_effect_option.connect("item_selected", Callable(self, "ScreenEffectChanged"))
	noise_offset_slider.connect("value_changed", Callable(self, "NoiseOffsetChanged"))
	shadow_amount_slider.connect("value_changed", Callable(self, "ShadowAmountChanged"))
	grain_amount_slider.connect("value_changed", Callable(self, "GrainAmountChanged"))
	line_size_slider.connect("value_changed", Callable(self, "LineSizeChanged"))
	tint_color_picker.connect("color_changed", Callable(self, "TintColorChanged"))

func _process(_delta : float) -> void:
	# Toggle between showing and hiding the settings UI when pressing escape.
	if Input.is_action_just_pressed("escape"):
		if main_window.visible:
			get_tree().paused = false
			main_window.visible = false
			# Change the mouse mode to show the curser when it's needed.
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			get_tree().paused = true
			main_window.visible = true
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func NoiseOffsetChanged(value : float) -> void:
	# Convert the signal value into a setting event by putting it into a Dictionary.
	Globals.emit_signal("settings_event", {"setting" : "noise_offset", "value" : value})

func ShadowAmountChanged(value : float) -> void:
	# The screen effects Node will listen to this signal and apply the setting to the sketchy material.
	Globals.emit_signal("settings_event", {"setting" : "shadow_amount", "value" : value})

func ScreenEffectChanged(value : float) -> void:
	Globals.emit_signal("settings_event", {"setting" : "screen_effect", "value" : value})

func WindowModeChanged(value : int) -> void:
	if window_mode_option.get_item_text(value) == "Windowed":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
	elif window_mode_option.get_item_text(value) == "Borderless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	elif window_mode_option.get_item_text(value) == "Fullscreen":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)

func GrainAmountChanged(value : float) -> void:
	Globals.emit_signal("settings_event", {"setting" : "grain_amount", "value" : value})

func LineSizeChanged(value : float) -> void:
	Globals.emit_signal("settings_event", {"setting" : "line_size", "value" : value})

func TintColorChanged(color : Color) -> void:
	Globals.emit_signal("settings_event", {"setting" : "tint_color", "color" : color})
