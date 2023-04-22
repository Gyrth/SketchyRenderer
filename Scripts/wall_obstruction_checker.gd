extends Node3D

const OBSTRUCTION_CHECK_CONE_RESOURCE = preload("res://Models/obstruction_check_cone.tres")

@onready var mesh_instance : MeshInstance3D = $MeshInstance3D

var center_node : Node3D = self
var center_weight : float = 0.65
var convex_shape : ConvexPolygonShape3D = null

func _ready():
	# Register this obstruction checker in the Global autoload/singleton so that any script can use it.
	Globals.wall_obstruction_checker = self
	# To generate a cone shaped CollisionShape start with a MeshInstance cut off CylinderMesh.
	mesh_instance.create_convex_collision(false, false)
	# This will also create a StaticBody, so save a reference to the ConvexShape.
	convex_shape = mesh_instance.find_child("CollisionShape3D").shape
	# And delete the rest of the Nodes, since these are no longer needed.
	mesh_instance.queue_free()

func _process(_delta : float) -> void:
	# This can also be called between intervals to save on performance.
	CheckObstructingWall()

func CheckObstructingWall():
	# Use the active camera instead of the player camera so that obstruction checking works with any active camera.
	var active_camera = get_viewport().get_camera_3d()
	var start = center_node.global_position
	var end = active_camera.global_position
	var space_state = get_world_3d().get_direct_space_state()
	var params = PhysicsShapeQueryParameters3D.new()
	# Only check in the WALL Collision layer so every result is valid.
	var layers = pow(2, Globals.WALL_LAYER)
	var shape_transform = Transform3D()
	
	var camera_position = active_camera.global_transform.origin
	var forward_direction = (start - camera_position).normalized()
	var up_direction = active_camera.global_transform.basis.y
	
	# The shape transform is the global transform of the cone in between the center and the camera.
	shape_transform = shape_transform.looking_at(up_direction, forward_direction)
	# Shift the position of the cone in between based on a weight. This makes the cone stick out forward when needed.
	shape_transform.origin = lerp(start, camera_position, center_weight)
	# Stretch the cone vertically based on how far the center is to the camera.
	shape_transform.basis.y = shape_transform.basis.y.normalized() * start.distance_to(end) / 2.0
	params.transform = shape_transform
	params.set_shape(convex_shape)
	params.collision_mask = layers
	
	var results = space_state.intersect_shape(params, 32)
	
	for result in results:
		result.collider.AddVignetteOpenTime()
