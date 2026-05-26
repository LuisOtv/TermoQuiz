extends StaticBody3D

@export var objectName: String = "Objeto"
@export var data_file: String = ""
@export var tint: Color = Color(0.6, 0.62, 0.65)

@onready var mesh: MeshInstance3D = $MeshInstance3D

var _mat: StandardMaterial3D


func _ready() -> void:
	add_to_group("Object")
	add_to_group("Interactable")
	GameProgress.register(objectName)

	# Material próprio por instância (evita compartilhar emissão entre estações).
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = tint
	_mat.metallic = 0.2
	_mat.roughness = 0.5
	mesh.set_surface_override_material(0, _mat)

	GameProgress.updated.connect(_refresh_visual)
	_refresh_visual()


func _interact() -> void:
	var hud: Node = get_tree().get_first_node_in_group("HUD")
	if hud:
		hud.open_quiz(data_file, objectName)


func _refresh_visual() -> void:
	if _mat == null:
		return
	if GameProgress.is_passed(objectName):
		_mat.emission_enabled = true
		_mat.emission = Color(0.2, 1.0, 0.35)
		_mat.emission_energy_multiplier = 0.7
	else:
		_mat.emission_enabled = false
		_mat.albedo_color = tint
