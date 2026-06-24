extends Node3D

# TEMPORÁRIO: utilitário de conferência. Só captura screenshots e encerra o jogo
# quando explicitamente pedido pela linha de comando:  Godot ... -- --shots
# Em execução normal (e ao dar Play no editor) este nó não faz nada, para que o
# jogo seja jogável. Pode ser removido quando a ambientação estiver finalizada.

func _ready() -> void:
	if not OS.get_cmdline_user_args().has("--shots"):
		return
	await get_tree().create_timer(1.2).timeout
	var base: String = ProjectSettings.globalize_path("res://_shots")
	DirAccess.make_dir_recursive_absolute(base)
	var vp: Viewport = get_viewport()

	# 1) Vista do spawn (o que o aluno vê ao nascer).
	vp.get_texture().get_image().save_png(base + "/1_spawn.png")

	var cam := Camera3D.new()
	add_child(cam)
	cam.fov = 78.0
	cam.make_current()

	# 2) Visão geral do alto (canto nordeste, abaixo do teto y=4.1).
	await _shoot(cam, Vector3(8.5, 3.6, 6.2), Vector3(-1.0, 0.6, -2.0), vp, base + "/2_overview.png")

	# 3) Corredor central: as duas colunas de mesas com as estações.
	await _shoot(cam, Vector3(0.0, 1.7, 5.5), Vector3(0.0, 1.0, -4.0), vp, base + "/3_corredor.png")

	# 4) Mesas da coluna oeste em close (estações sobre tampo preto).
	await _shoot(cam, Vector3(-0.4, 1.6, -0.6), Vector3(-3.2, 1.0, -3.0), vp, base + "/4_mesas.png")

	# 5) Perímetro oeste: bancada + estante de reagentes + geladeira ao fundo.
	await _shoot(cam, Vector3(-5.5, 1.9, 4.5), Vector3(-9.2, 1.1, 0.5), vp, base + "/5_perimetro.png")

	get_tree().quit()


func _shoot(cam: Camera3D, pos: Vector3, target: Vector3, vp: Viewport, path: String) -> void:
	cam.global_position = pos
	cam.look_at(target, Vector3.UP)
	await get_tree().process_frame
	await get_tree().create_timer(0.35).timeout
	vp.get_texture().get_image().save_png(path)
