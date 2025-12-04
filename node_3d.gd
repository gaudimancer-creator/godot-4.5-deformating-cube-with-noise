extends Node3D

@export var N = 30
@export var cube_size = 3.0 * N
@export var subdivisions = 5 * N
@export var z_rotation = 5
@export var y_rotation = 5
@export var anim_speed = 0.0025

@onready var mesh_instance = $MeshInstance3D
@onready var shader_material = $MeshInstance3D.material_override
@export var time_accum: float = 0.0

var player_camera: Camera3D
@export var yaw: float = 0.0    
@export var pitch: float = 0.0    
@export var mouse_sens := 0.15   
@export var move_speed := 90.0 
@export var fast := 2.5

func _ready():
	setup_environment()
	create_deforming_cube()
	setup_lighting()

func _process(delta):
	time_accum += delta * 1000.0 * anim_speed
	var t_sec = time_accum / 1000.0
	mesh_instance.rotate_z(z_rotation * sin(t_sec / 30.0) * 0.1) 
	mesh_instance.rotate_y( t_sec / y_rotation)
	var deform_time = (time_accum / 2.0 + sin(time_accum / 2.0))
	shader_material.set_shader_parameter("u_time", deform_time)
	if player_camera and is_instance_valid(player_camera):
		_update_camera_movement(delta)

func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		yaw -= deg_to_rad(event.relative.x * mouse_sens)
		pitch -= deg_to_rad(event.relative.y * mouse_sens)
		pitch = clamp(pitch, deg_to_rad(-89.0), deg_to_rad(89.0))
		player_camera.rotation = Vector3(pitch, yaw, 0.0)
	if event is InputEventMouseButton and event.button_index == MouseButton.MOUSE_BUTTON_LEFT and event.pressed:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if event is InputEventKey and event.pressed and event.keycode == Key.KEY_ESCAPE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _update_camera_movement(delta: float) -> void:
	var speed := move_speed
	if Input.is_key_pressed(Key.KEY_SHIFT): speed *= fast

	var dir := Vector3.ZERO
	var forward := -player_camera.global_transform.basis.z
	var right := player_camera.global_transform.basis.x
	forward.y = 0
	right.y = 0
	forward = forward.normalized()
	right = right.normalized()

	if Input.is_action_pressed("forward"):
		dir += forward
	if Input.is_action_pressed("backward"):
		dir -= forward
	if Input.is_action_pressed("right"):
		dir += right
	if Input.is_action_pressed("left"):
		dir -= right
	if Input.is_action_pressed("ui_select"):
		dir += Vector3.UP
	if Input.is_action_pressed("ctrl"):
		dir -= Vector3.UP
	if dir != Vector3.ZERO:
		dir = dir.normalized()
		var move_vec = dir * speed * delta
		player_camera.global_translate(move_vec)

func setup_environment():
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color.WHITE
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.WHITE * 0.2
	
	var world_env = WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)
	player_camera = $Camera3D
	player_camera.position = Vector3(0, 3 * N, 12 * N)
	player_camera.look_at(Vector3.ZERO)
	player_camera.fov = 30

func setup_lighting():
	var light1 = $DirectionalLight3D
	light1.light_color = Color.AZURE
	light1.light_energy = 2.0
	light1.position = Vector3(2 * N, 1 * N, N / 2.0)
	light1.look_at(Vector3.ZERO)
	light1.shadow_enabled = true
	light1.shadow_bias = 0.02
	var light2 = $DirectionalLight3D2
	light2.light_color = Color.ANTIQUE_WHITE
	light2.light_energy = 0.5
	light2.position = Vector3(-4 * N, -N, N / 2.0)
	light2.look_at(Vector3.ZERO)
	var light3 = $DirectionalLight3D3
	light3.light_color = Color.CORNSILK
	light3.light_energy = 0.5
	light3.position = Vector3(1 * N, -N, 5 * N)
	light3.look_at(Vector3.ZERO)

func create_deforming_cube():
	var mesh = BoxMesh.new()
	mesh.size = Vector3(cube_size, cube_size, cube_size)
	mesh.subdivide_width = subdivisions
	mesh.subdivide_height = subdivisions
	mesh.subdivide_depth = subdivisions
	$MeshInstance3D.mesh = mesh
	shader_material.set_shader_parameter("u_cube_size", cube_size)
	shader_material.set_shader_parameter("u_N", float(N))
