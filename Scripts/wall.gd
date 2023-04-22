extends StaticBody3D

const VIGNETTE_CLOSE_TIME : float = 0.15

var vignette_open_timer : float = 0.0
var vignette_open_amount : float = 0.0
var wall_material : ShaderMaterial = null

func _ready() -> void:
	# Make the material unique to this wall, or else material parameter changes 
	# will be applied to all the walls at the same time.
	wall_material = get_parent().get_surface_override_material(0).duplicate()
	get_parent().set_surface_override_material(0, wall_material)

func AddVignetteOpenTime() -> void:
	# Keep setting the timer to a constant value that will slowly run down if it's not set again for a while.
	vignette_open_timer = VIGNETTE_CLOSE_TIME
	# Allow the process function to handle expanding and shrinking the vignette.
	set_process(true)

func _process(delta : float) -> void:
	vignette_open_timer -= delta
	# Quickly open up the vignette but cap it at 0.6 to keep some wall texture on the edges.
	if(vignette_open_timer > 0.0):
		vignette_open_amount = min(0.6, vignette_open_amount + delta * 2.0)
	else:
		# Close the vignette when the open timer has run out.
		vignette_open_amount = max(0.0, vignette_open_amount - delta * 2.0)
		# Once the vignette is completely closed this script can stop processing.
		if vignette_open_amount <= 0.0:
			set_process(false)
	# Apply an easing function to the vignette amount to make it look a bit smoother.
	wall_material.set_shader_parameter("vignette_open", easeInOutQuad(vignette_open_amount))

func easeInOutQuad(x : float) -> float:
	return 2.0 * x * x if x < 0.5 else 1.0 - pow(-2.0 * x + 2.0, 2.0) / 2.0
