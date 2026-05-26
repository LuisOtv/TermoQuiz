extends CharacterBody3D

@export var speed: float = 4.5
@export var mouse_sensitivity: float = 0.0025

@onready var camera: Camera3D = $Camera3D
@onready var interact_ray: RayCast3D = $Camera3D/InteractRay

var pitch: float = 0.0
var hud: Node = null


func _ready() -> void:
	hud = get_tree().get_first_node_in_group("HUD")
	interact_ray.add_exception(self)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _unhandled_input(event: InputEvent) -> void:
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		return

	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		pitch = clamp(pitch - event.relative.y * mouse_sensitivity, -1.4, 1.4)
		camera.rotation.x = pitch
	elif event.is_action_pressed("ui_f"):
		_try_interact()


func _try_interact() -> void:
	if interact_ray.is_colliding():
		var obj: Object = interact_ray.get_collider()
		if obj and obj.is_in_group("Interactable"):
			obj._interact()


func _physics_process(delta: float) -> void:
	# Congela o jogador quando o mouse está liberado (quiz/menu aberto).
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		velocity = Vector3.ZERO
		return

	if not is_on_floor():
		velocity += get_gravity() * delta

	var input_dir: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var dir: Vector3 = (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	if dir:
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed)
		velocity.z = move_toward(velocity.z, 0.0, speed)

	move_and_slide()


func _process(_delta: float) -> void:
	if hud == null:
		return
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		hud.set_prompt("")
		return

	var obj: Object = interact_ray.get_collider() if interact_ray.is_colliding() else null
	if obj and obj.is_in_group("Object"):
		hud.set_prompt_for(obj)
	else:
		hud.set_prompt("")
