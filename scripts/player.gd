extends CharacterBody3D

@export var red: ColorRect
@export var white: ColorRect

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY := 0.002
const PITCH_LIMIT := deg_to_rad(70.0)

var pitch := 0.0
var cam_yaw := 0.0
var jump_amt = 10.0
var default_size: Vector2
var inventory = ["gun", "launcher"]
var actions = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
var selected_item = 2

func _ready() -> void:
	default_size = red.size
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		cam_yaw = wrapf(cam_yaw - event.relative.x * MOUSE_SENSITIVITY, -PI, PI)
		pitch = clampf(pitch + event.relative.y * MOUSE_SENSITIVITY, -PITCH_LIMIT, PITCH_LIMIT)
		rotation = Vector3(0.0, cam_yaw, pitch)

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("esc"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE else Input.MOUSE_MODE_VISIBLE
	
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("space") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir := Input.get_vector("w", "s", "d", "a")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	white.size.x = (default_size.x/10) * jump_amt
	
	if jump_amt < 10.0:
		jump_amt += 2*delta
	
	var idx = 0
	for action in actions:
		if Input.is_action_just_pressed(action):
			selected_item = idx
		idx += 1
	
	if Input.is_action_just_pressed("click"):
		var mouse_pos = get_viewport().get_window().size / 2.0
		var ray_origin = $Camera3D.project_ray_origin(mouse_pos)
		var ray_end = ray_origin + $Camera3D.project_ray_normal(mouse_pos) * 100.0
		var space_state = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end, 1)
		var result = space_state.intersect_ray(query)
		
		if selected_item == 1:
			if result.collider is CharacterBody3D:
				result.collider.queue_free()
		elif selected_item == 2:
			if result.size() > 1 and not self in result and jump_amt >= 5.0:
				velocity = (global_position - result.position).normalized() * 30.0
				velocity.y += 1.0
				jump_amt -= 5.0

	move_and_slide()
