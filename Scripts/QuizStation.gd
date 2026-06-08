extends StaticBody3D

@export var objectName: String = "Objeto"
@export var data_file: String = ""
@export var tint: Color = Color(0.6, 0.62, 0.65)
@export var icon: Texture2D

## Altura aproximada (em metros) do billboard no mundo.
const ICON_HEIGHT := 1.3
const PASS_COLOR := Color(0.22, 0.95, 0.45)

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var sprite: Sprite3D = $Icon
@onready var pedestal: MeshInstance3D = $Pedestal
@onready var ring: MeshInstance3D = $Ring
@onready var glow: OmniLight3D = $Glow
@onready var burst: CPUParticles3D = $Burst

var _mat: StandardMaterial3D
var _ped_mat: StandardMaterial3D
var _ring_mat: StandardMaterial3D
var _beam_mat: StandardMaterial3D
var _passed: bool = false
var _icon_base_y: float = 0.78
var _t: float = 0.0
var _phase: float = 0.0


func _ready() -> void:
	add_to_group("Object")
	add_to_group("Interactable")
	GameProgress.register(objectName)

	# Fase aleatória para que as estações não pulsem em uníssono (cara de IA).
	_phase = randf() * TAU
	_icon_base_y = sprite.position.y

	# Material próprio por instância (evita compartilhar emissão entre estações).
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = tint
	_mat.metallic = 0.2
	_mat.roughness = 0.5
	mesh.set_surface_override_material(0, _mat)

	# Pedestal escuro, levemente metálico — base de "projetor".
	_ped_mat = StandardMaterial3D.new()
	_ped_mat.albedo_color = Color(0.13, 0.14, 0.17)
	_ped_mat.metallic = 0.7
	_ped_mat.roughness = 0.3
	pedestal.set_surface_override_material(0, _ped_mat)

	# Anel luminoso na cor do objeto.
	_ring_mat = StandardMaterial3D.new()
	_ring_mat.albedo_color = tint
	_ring_mat.emission_enabled = true
	_ring_mat.emission = tint
	_ring_mat.emission_energy_multiplier = 2.0
	ring.set_surface_override_material(0, _ring_mat)

	# Feixe holográfico translúcido entre o pedestal e o ícone flutuante.
	_beam_mat = StandardMaterial3D.new()
	_beam_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_beam_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_beam_mat.albedo_color = Color(tint.r, tint.g, tint.b, 0.12)
	_beam_mat.emission_enabled = true
	_beam_mat.emission = tint
	_beam_mat.emission_energy_multiplier = 0.7

	glow.light_color = tint

	# Se houver imagem, ela substitui o placeholder em forma de caixa.
	if icon:
		sprite.texture = icon
		sprite.pixel_size = ICON_HEIGHT / float(icon.get_height())
		mesh.visible = false
	else:
		sprite.visible = false

	GameProgress.updated.connect(_refresh_visual)
	_refresh_visual()


func _process(delta: float) -> void:
	_t += delta

	# Ícone flutuando suavemente.
	var bob: float = sin(_t * 1.8 + _phase)
	sprite.position.y = _icon_base_y + bob * 0.05

	# Pulso de "convite" enquanto o objeto não foi concluído.
	if not _passed:
		var pulse: float = 0.5 + 0.5 * sin(_t * 2.6 + _phase)
		_ring_mat.emission_energy_multiplier = 1.3 + pulse * 1.6
		glow.light_energy = 0.9 + pulse * 0.9
		_beam_mat.emission_energy_multiplier = 0.5 + pulse * 0.5


func _interact() -> void:
	var hud: Node = get_tree().get_first_node_in_group("HUD")
	if hud:
		hud.open_quiz(data_file, objectName, tint)


func _refresh_visual() -> void:
	if _ring_mat == null:
		return
	var passed: bool = GameProgress.is_passed(objectName)
	var newly_passed: bool = passed and not _passed
	_passed = passed

	if passed:
		# Tudo fica verde, estável e brilhante.
		_mat.emission_enabled = true
		_mat.emission = PASS_COLOR
		_mat.emission_energy_multiplier = 0.7
		_ring_mat.albedo_color = PASS_COLOR
		_ring_mat.emission = PASS_COLOR
		_ring_mat.emission_energy_multiplier = 3.0
		_beam_mat.albedo_color = Color(PASS_COLOR.r, PASS_COLOR.g, PASS_COLOR.b, 0.18)
		_beam_mat.emission = PASS_COLOR
		_beam_mat.emission_energy_multiplier = 1.0
		glow.light_color = PASS_COLOR
		glow.light_energy = 2.2
		if icon:
			sprite.modulate = Color(0.6, 1.0, 0.65)
		if newly_passed:
			_celebrate()
	else:
		_mat.emission_enabled = false
		_mat.albedo_color = tint
		_ring_mat.albedo_color = tint
		_ring_mat.emission = tint
		_beam_mat.albedo_color = Color(tint.r, tint.g, tint.b, 0.12)
		_beam_mat.emission = tint
		glow.light_color = tint
		if icon:
			sprite.modulate = Color.WHITE


## Pequena comemoração ao concluir: jorro de partículas + pulo do anel + flash.
func _celebrate() -> void:
	burst.restart()
	burst.emitting = true

	var tw := create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	ring.scale = Vector3(0.6, 0.6, 0.6)
	tw.tween_property(ring, "scale", Vector3.ONE, 0.8)

	var ft := create_tween()
	glow.light_energy = 6.0
	ft.tween_property(glow, "light_energy", 2.2, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
