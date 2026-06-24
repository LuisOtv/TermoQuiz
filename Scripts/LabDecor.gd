extends Node3D

## Espalha props de laboratório (vidrarias, banquetas, geladeira) pela cena,
## extraindo cada peça nomeada do kit GLB low_poly. As peças vêm enfileiradas
## e em unidades grandes; para cada uma normalizamos a base no chão, centralizamos
## em X/Z e aplicamos uma escala que a leva para metros.

const KIT_PATH := "res://Models/low_poly_laboratory_assets.glb"

# Alturas: tampo das bancadas de perímetro (counter em y≈0.93 → superfície ~0.96),
# prateleira superior das estantes (y≈1.85) e o chão.
const BENCH_Y := 0.96
const SHELF_Y := 1.88
const FLOOR_Y := 0.0

# Layout (combina com Scenes/Lab.tscn): 8 mesas-estação em DUAS COLUNAS no meio
# da sala — Oeste (x = -2.3) e Leste (x = +2.3) — com quatro fileiras
# (z = -4.5 / -1.5 / 1.5 / 4.5). Uma CADEIRA fica em frente a cada mesa, do lado do
# corredor central, voltada para a mesa. Os enfeites ficam no PERÍMETRO: vidrarias
# nas bancadas e estantes laterais (x = ±9.3/±9.55) e geladeira/lixeira nos cantos
# do fundo (z ≈ -6.2, junto à parede dos quadros).
# Cada item: nó no kit, posição no mundo, rotação Y (graus) e escala uniforme.
# Escalas calibradas pela medição do AABB de cada peça (tamanho real aproximado):
# béquer ~0,21 m · béquer pequeno ~0,15 m · provetas ~0,28 m · vidro ~0,12 m ·
# geladeira ~1,75 m · banqueta ~0,77 m · lixeira ~0,52 m.
const PLACEMENTS: Array = [
	# ── Vidrarias na bancada de perímetro Oeste (tampo em x ≈ -8.9) ───────────
	{"node": "smallBeaker", "pos": Vector3(-8.9, BENCH_Y, -4.0), "rot": 0.0, "scale": 0.06},
	{"node": "Beaker", "pos": Vector3(-8.9, BENCH_Y, -1.5), "rot": 20.0, "scale": 0.06},
	{"node": "equipment", "pos": Vector3(-8.9, BENCH_Y, 1.5), "rot": 0.0, "scale": 0.11},
	{"node": "glass1", "pos": Vector3(-8.9, BENCH_Y, 4.0), "rot": 0.0, "scale": 0.09},
	# ── Vidrarias na bancada de perímetro Leste (tampo em x ≈ 8.9) ────────────
	{"node": "Beaker", "pos": Vector3(8.9, BENCH_Y, -4.0), "rot": -15.0, "scale": 0.06},
	{"node": "smallBeaker", "pos": Vector3(8.9, BENCH_Y, -1.5), "rot": 0.0, "scale": 0.06},
	{"node": "equipment", "pos": Vector3(8.9, BENCH_Y, 1.5), "rot": 0.0, "scale": 0.11},
	{"node": "glass1", "pos": Vector3(8.9, BENCH_Y, 4.0), "rot": 0.0, "scale": 0.09},

	# ── Béqueres nas estantes (prateleira superior) ───────────────────────────
	{"node": "smallBeaker", "pos": Vector3(-9.4, SHELF_Y, -2.5), "rot": 0.0, "scale": 0.06},
	{"node": "Beaker", "pos": Vector3(-9.4, SHELF_Y, 0.0), "rot": 0.0, "scale": 0.06},
	{"node": "smallBeaker", "pos": Vector3(-9.4, SHELF_Y, 2.5), "rot": 0.0, "scale": 0.06},
	{"node": "Beaker", "pos": Vector3(9.4, SHELF_Y, -2.5), "rot": 0.0, "scale": 0.06},
	{"node": "smallBeaker", "pos": Vector3(9.4, SHELF_Y, 0.0), "rot": 0.0, "scale": 0.06},
	{"node": "Beaker", "pos": Vector3(9.4, SHELF_Y, 2.5), "rot": 0.0, "scale": 0.06},

	# ── Uma cadeira em frente a cada mesa (lado do corredor central) ──────────
	# Coluna Oeste (mesas em x = -2.3): cadeira em x = -1.45 voltada para -X.
	{"node": "chair", "pos": Vector3(-1.45, FLOOR_Y, -4.5), "rot": -90.0, "scale": 0.095},
	{"node": "chair", "pos": Vector3(-1.45, FLOOR_Y, -1.5), "rot": -90.0, "scale": 0.095},
	{"node": "chair", "pos": Vector3(-1.45, FLOOR_Y, 1.5), "rot": -90.0, "scale": 0.095},
	{"node": "chair", "pos": Vector3(-1.45, FLOOR_Y, 4.5), "rot": -90.0, "scale": 0.095},
	# Coluna Leste (mesas em x = 2.3): cadeira em x = 1.45 voltada para +X.
	{"node": "chair", "pos": Vector3(1.45, FLOOR_Y, -4.5), "rot": 90.0, "scale": 0.095},
	{"node": "chair", "pos": Vector3(1.45, FLOOR_Y, -1.5), "rot": 90.0, "scale": 0.095},
	{"node": "chair", "pos": Vector3(1.45, FLOOR_Y, 1.5), "rot": 90.0, "scale": 0.095},
	{"node": "chair", "pos": Vector3(1.45, FLOOR_Y, 4.5), "rot": 90.0, "scale": 0.095},

	# ── Equipamentos de canto, no chão (junto à parede dos quadros) ───────────
	{"node": "fridge", "pos": Vector3(-8.6, FLOOR_Y, -6.2), "rot": 0.0, "scale": 0.22},
	{"node": "round_bin", "pos": Vector3(8.6, FLOOR_Y, -6.2), "rot": 0.0, "scale": 0.14},
]


func _ready() -> void:
	var ps: Variant = load(KIT_PATH)
	if ps == null:
		push_warning("LabDecor: kit não encontrado em %s" % KIT_PATH)
		return
	var kit: Node = (ps as PackedScene).instantiate()
	var root: Node = kit.find_child("RootNode", true, false)
	if root == null:
		root = kit

	for p in PLACEMENTS:
		var src: Node = root.find_child(str(p["node"]), false, false)
		if src == null:
			push_warning("LabDecor: peça '%s' não encontrada no kit" % p["node"])
			continue
		_place(src, p)

	kit.free()


## Posiciona a peça preservando a orientação que o kit guarda no transform do
## grupo. Hierarquia: holder (posição/rotação no mundo) → scaler (escala) → peça.
## A peça mantém seu transform original (que a deixa "em pé"); apenas removemos
## o deslocamento da fileira, assentando a base no chão e centralizando em X/Z.
func _place(src: Node, p: Dictionary) -> void:
	var inst: Node = src.duplicate()  # preserva o transform original (orientação)

	var holder := Node3D.new()
	add_child(holder)
	holder.position = p["pos"]
	holder.rotation_degrees = Vector3(0.0, float(p.get("rot", 0.0)), 0.0)

	var scaler := Node3D.new()
	var s: float = float(p.get("scale", 1.0))
	scaler.scale = Vector3(s, s, s)
	holder.add_child(scaler)
	scaler.add_child(inst)

	# Limites no referencial do scaler (já com o transform original da peça).
	var bounds: Array = [Vector3(INF, INF, INF), Vector3(-INF, -INF, -INF)]
	_collect_bounds(inst, Transform3D.IDENTITY, bounds)
	var lo: Vector3 = bounds[0]
	var hi: Vector3 = bounds[1]
	if lo.x == INF:
		return  # peça sem malha visível

	if inst is Node3D:
		# Translação no referencial do scaler: centraliza em X/Z, base em y = 0.
		var cx: float = (lo.x + hi.x) * 0.5
		var cz: float = (lo.z + hi.z) * 0.5
		(inst as Node3D).position += Vector3(-cx, -lo.y, -cz)


func _collect_bounds(node: Node, xform: Transform3D, bounds: Array) -> void:
	var t: Transform3D = xform
	if node is Node3D:
		t = xform * (node as Node3D).transform
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		var aabb: AABB = (node as MeshInstance3D).get_aabb()
		for i in 8:
			var pt: Vector3 = t * aabb.get_endpoint(i)
			bounds[0] = bounds[0].min(pt)
			bounds[1] = bounds[1].max(pt)
	for c in node.get_children():
		_collect_bounds(c, t, bounds)
