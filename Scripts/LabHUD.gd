extends CanvasLayer

const LETTERS: Array = ["A", "B", "C", "D"]

# HUD persistente
var crosshair: Label
var prompt_label: Label
var progress_label: Label

# Painel de quiz
var quiz_root: Control
var quiz_panel: PanelContainer
var panel_title_label: Label
var q_counter_label: Label
var question_label: RichTextLabel
var opts_container: VBoxContainer
var option_buttons: Array = []
var feedback_label: Label
var results_label: Label
var next_btn: Button
var refazer_btn: Button

# Vitória
var victory_root: Control
var victory_label: Label

# Estado do quiz
var current_data: Dictionary = {}
var current_id: String = ""
var current_question_index: int = 0
var answered: bool = false
var session_correct: int = 0
var quiz_open: bool = false
var showing_results: bool = false


func _ready() -> void:
	add_to_group("HUD")
	_build_hud()
	_build_quiz_panel()
	_build_victory()
	GameProgress.updated.connect(_refresh_progress)
	GameProgress.completed.connect(_on_completed)
	_refresh_progress()


# ── Construção da UI ──────────────────────────────────────────────────────────

func _build_hud() -> void:
	crosshair = Label.new()
	crosshair.text = "+"
	crosshair.set_anchors_preset(Control.PRESET_CENTER)
	crosshair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crosshair.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var crs := LabelSettings.new()
	crs.font_size = 26
	crs.font_color = Color(1, 1, 1, 0.75)
	crs.outline_size = 3
	crs.outline_color = Color(0, 0, 0, 0.6)
	crosshair.label_settings = crs
	crosshair.offset_left = -10
	crosshair.offset_right = 10
	crosshair.offset_top = -18
	crosshair.offset_bottom = 18
	add_child(crosshair)

	prompt_label = Label.new()
	prompt_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt_label.offset_top = -120
	prompt_label.offset_bottom = -88
	prompt_label.offset_left = -400
	prompt_label.offset_right = 400
	var prs := LabelSettings.new()
	prs.font_size = 24
	prs.font_color = Color(1, 1, 1, 0.95)
	prs.outline_size = 4
	prs.outline_color = Color(0, 0, 0, 0.85)
	prompt_label.label_settings = prs
	add_child(prompt_label)

	progress_label = Label.new()
	progress_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	progress_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress_label.offset_left = -360
	progress_label.offset_right = -18
	progress_label.offset_top = 16
	progress_label.offset_bottom = 50
	var pgs := LabelSettings.new()
	pgs.font_size = 22
	pgs.font_color = Color(0.7, 0.9, 1.0)
	pgs.outline_size = 4
	pgs.outline_color = Color(0, 0, 0, 0.85)
	progress_label.label_settings = pgs
	add_child(progress_label)


func _build_quiz_panel() -> void:
	quiz_root = CenterContainer.new()
	quiz_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	quiz_root.visible = false
	add_child(quiz_root)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	quiz_root.add_child(dim)

	quiz_panel = PanelContainer.new()
	quiz_panel.custom_minimum_size = Vector2(880, 600)
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.05, 0.06, 0.13, 0.98)
	ps.border_color = Color(0.30, 0.55, 0.95, 0.85)
	ps.set_border_width_all(2)
	ps.set_corner_radius_all(16)
	ps.set_content_margin_all(34.0)
	ps.shadow_color = Color(0, 0, 0, 0.5)
	ps.shadow_size = 18
	quiz_panel.add_theme_stylebox_override("panel", ps)
	quiz_root.add_child(quiz_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	quiz_panel.add_child(vbox)

	panel_title_label = Label.new()
	panel_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var ts := LabelSettings.new()
	ts.font_size = 32
	ts.font_color = Color(0.48, 0.8, 1.0)
	panel_title_label.label_settings = ts
	vbox.add_child(panel_title_label)

	q_counter_label = Label.new()
	q_counter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var cs := LabelSettings.new()
	cs.font_size = 16
	cs.font_color = Color(0.58, 0.58, 0.68)
	q_counter_label.label_settings = cs
	vbox.add_child(q_counter_label)

	vbox.add_child(HSeparator.new())

	question_label = RichTextLabel.new()
	question_label.bbcode_enabled = true
	question_label.fit_content = true
	question_label.scroll_active = false
	question_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	question_label.add_theme_font_size_override("normal_font_size", 24)
	question_label.add_theme_font_size_override("bold_font_size", 24)
	question_label.add_theme_color_override("default_color", Color(0.96, 0.96, 0.96))
	question_label.add_theme_constant_override("line_separation", 6)
	question_label.custom_minimum_size = Vector2(0.0, 70.0)
	vbox.add_child(question_label)

	opts_container = VBoxContainer.new()
	opts_container.add_theme_constant_override("separation", 10)
	vbox.add_child(opts_container)

	for i in 4:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0.0, 52.0)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.pressed.connect(_on_option_pressed.bind(i))
		btn.add_theme_stylebox_override("normal", _make_btn_style(Color(0.08, 0.10, 0.22)))
		btn.add_theme_stylebox_override("hover", _make_btn_style(Color(0.13, 0.17, 0.36)))
		btn.add_theme_stylebox_override("pressed", _make_btn_style(Color(0.10, 0.14, 0.30)))
		btn.add_theme_font_size_override("font_size", 20)
		opts_container.add_child(btn)
		option_buttons.append(btn)

	feedback_label = Label.new()
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var fs := LabelSettings.new()
	fs.font_size = 21
	fs.outline_size = 3
	fs.outline_color = Color(0, 0, 0, 0.6)
	feedback_label.label_settings = fs
	feedback_label.visible = false
	vbox.add_child(feedback_label)

	results_label = Label.new()
	results_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	results_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	results_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var rs := LabelSettings.new()
	rs.font_size = 30
	rs.font_color = Color(0.9, 0.95, 1.0)
	results_label.label_settings = rs
	results_label.visible = false
	vbox.add_child(results_label)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	var nav := HBoxContainer.new()
	nav.alignment = BoxContainer.ALIGNMENT_CENTER
	nav.add_theme_constant_override("separation", 16)
	vbox.add_child(nav)

	next_btn = Button.new()
	next_btn.text = "Próxima →"
	next_btn.custom_minimum_size = Vector2(150.0, 44.0)
	next_btn.visible = false
	next_btn.pressed.connect(_on_next_pressed)
	nav.add_child(next_btn)

	refazer_btn = Button.new()
	refazer_btn.text = "↻ Refazer"
	refazer_btn.custom_minimum_size = Vector2(150.0, 44.0)
	refazer_btn.visible = false
	refazer_btn.pressed.connect(_restart_quiz)
	nav.add_child(refazer_btn)

	var back_btn := Button.new()
	back_btn.text = "Voltar  [Esc]"
	back_btn.custom_minimum_size = Vector2(140.0, 44.0)
	back_btn.pressed.connect(close_quiz)
	nav.add_child(back_btn)


func _build_victory() -> void:
	victory_root = CenterContainer.new()
	victory_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	victory_root.visible = false
	add_child(victory_root)

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.04, 0.08, 0.85)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	victory_root.add_child(dim)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(640, 320)
	var vs := StyleBoxFlat.new()
	vs.bg_color = Color(0.06, 0.10, 0.08, 0.98)
	vs.border_color = Color(0.3, 0.95, 0.45, 0.9)
	vs.set_border_width_all(3)
	vs.set_corner_radius_all(18)
	vs.set_content_margin_all(36.0)
	panel.add_theme_stylebox_override("panel", vs)
	victory_root.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 24)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)

	victory_label = Label.new()
	victory_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	victory_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var ls := LabelSettings.new()
	ls.font_size = 34
	ls.font_color = Color(0.7, 1.0, 0.75)
	victory_label.label_settings = ls
	vbox.add_child(victory_label)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	vbox.add_child(row)

	var restart := Button.new()
	restart.text = "↻ Recomeçar"
	restart.custom_minimum_size = Vector2(170.0, 46.0)
	restart.pressed.connect(_on_victory_restart)
	row.add_child(restart)

	var close_v := Button.new()
	close_v.text = "Continuar explorando"
	close_v.custom_minimum_size = Vector2(220.0, 46.0)
	close_v.pressed.connect(_close_victory)
	row.add_child(close_v)


func _make_btn_style(bg: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = Color(0.28, 0.45, 0.85, 0.75)
	s.set_border_width_all(1)
	s.set_corner_radius_all(8)
	s.content_margin_left = 16.0
	s.content_margin_right = 16.0
	s.content_margin_top = 8.0
	s.content_margin_bottom = 8.0
	return s


func _make_answer_style(bg: Color) -> StyleBoxFlat:
	var s := _make_btn_style(bg)
	s.border_color = bg.lightened(0.2)
	return s


# ── Prompt / progresso (chamado pelo Player e por sinais) ──────────────────────

func set_prompt(text: String) -> void:
	if prompt_label:
		prompt_label.text = text


func set_prompt_for(obj: Object) -> void:
	var nm: String = str(obj.get("objectName"))
	if nm == "" or nm == "<null>":
		nm = "Objeto"
	if GameProgress.is_passed(nm):
		set_prompt("✓  %s — concluído     [F] refazer" % nm)
	else:
		set_prompt("[F]   %s" % nm)


func _refresh_progress() -> void:
	if progress_label:
		progress_label.text = "Concluídos: %d / %d" % [GameProgress.passed_count(), GameProgress.total_count()]
	# Atualiza o painel de resultado se estiver visível ao reabrir.


# ── Fluxo do quiz ──────────────────────────────────────────────────────────────

func open_quiz(data_file: String, id: String) -> void:
	var data: Dictionary = _load_item_data(data_file)
	if (data.get("questions", []) as Array).is_empty():
		return
	current_data = data
	current_id = id
	current_question_index = 0
	session_correct = 0
	answered = false
	showing_results = false
	quiz_open = true

	q_counter_label.visible = true
	question_label.visible = true
	opts_container.visible = true
	results_label.visible = false
	refazer_btn.visible = false
	panel_title_label.text = str(data.get("name", id))

	crosshair.visible = false
	set_prompt("")
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	quiz_root.visible = true
	_update_question_display()


func close_quiz() -> void:
	quiz_open = false
	showing_results = false
	quiz_root.visible = false
	crosshair.visible = true
	if not victory_root.visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _questions() -> Array:
	return current_data.get("questions", [])


func _update_question_display() -> void:
	var questions := _questions()
	var total: int = questions.size()
	var q: Dictionary = questions[current_question_index]

	q_counter_label.text = "Pergunta  %d  de  %d" % [current_question_index + 1, total]
	question_label.text = "[b]%s[/b]" % str(q.get("q", ""))

	var opts: Array = q.get("options", [])
	for i in 4:
		var btn: Button = option_buttons[i]
		var label_text: String = str(opts[i]) if i < opts.size() else ""
		btn.text = "  %s)   %s" % [LETTERS[i], label_text]
		btn.disabled = false
		btn.remove_theme_stylebox_override("disabled")
		btn.remove_theme_color_override("font_disabled_color")

	feedback_label.visible = false
	next_btn.visible = false
	answered = false


func _on_option_pressed(opt_idx: int) -> void:
	if answered or showing_results:
		return
	answered = true

	var q: Dictionary = _questions()[current_question_index]
	var opts: Array = q.get("options", [])
	var correct: int = clampi(int(q.get("correct", 0)), 0, 3)
	var is_right: bool = (opt_idx == correct)

	for i in 4:
		var btn: Button = option_buttons[i]
		btn.disabled = true
		var style_color: Color
		var font_color := Color(1, 1, 1)
		if i == correct:
			style_color = Color(0.16, 0.45, 0.22)
		elif i == opt_idx:
			style_color = Color(0.5, 0.15, 0.15)
		else:
			style_color = Color(0.07, 0.08, 0.16)
			font_color = Color(0.55, 0.55, 0.6)
		btn.add_theme_stylebox_override("disabled", _make_answer_style(style_color))
		btn.add_theme_color_override("font_disabled_color", font_color)

	var fs: LabelSettings = feedback_label.label_settings
	if is_right:
		session_correct += 1
		feedback_label.text = "✓   Correto!"
		fs.font_color = Color(0.35, 1.0, 0.45)
	else:
		feedback_label.text = "✗   Errado!   Resposta correta: %s) %s" % [LETTERS[correct], str(opts[correct])]
		fs.font_color = Color(1.0, 0.38, 0.38)
	feedback_label.visible = true

	var total: int = _questions().size()
	next_btn.text = "Ver resultado" if current_question_index == total - 1 else "Próxima →"
	next_btn.visible = true


func _on_next_pressed() -> void:
	var total: int = _questions().size()
	if current_question_index == total - 1:
		_show_results()
	else:
		current_question_index += 1
		_update_question_display()


func _show_results() -> void:
	showing_results = true
	var total: int = _questions().size()
	q_counter_label.visible = false
	question_label.visible = false
	opts_container.visible = false
	feedback_label.visible = false
	next_btn.visible = false

	GameProgress.set_result(current_id, session_correct, total)

	var pct: int = int(round(100.0 * session_correct / float(total)))
	var min_pct: int = int(round(100.0 * GameProgress.PASS_PERCENT))
	var passed: bool = float(session_correct) / float(total) >= GameProgress.PASS_PERCENT
	if passed:
		results_label.text = "APROVADO!\n\n%d de %d  (%d%%)" % [session_correct, total, pct]
		results_label.label_settings.font_color = Color(0.4, 1.0, 0.5)
	else:
		results_label.text = "Não passou ainda\n\n%d de %d  (%d%%)\nMínimo para aprovar: %d%%" % [session_correct, total, pct, min_pct]
		results_label.label_settings.font_color = Color(1.0, 0.55, 0.45)
	results_label.visible = true
	refazer_btn.visible = true


func _restart_quiz() -> void:
	showing_results = false
	results_label.visible = false
	refazer_btn.visible = false
	q_counter_label.visible = true
	question_label.visible = true
	opts_container.visible = true
	current_question_index = 0
	session_correct = 0
	_update_question_display()


# ── Vitória ─────────────────────────────────────────────────────────────────

func _on_completed() -> void:
	quiz_open = false
	quiz_root.visible = false
	crosshair.visible = false
	set_prompt("")
	victory_label.text = "Parabéns!\nVocê concluiu o laboratório\n(%d de %d objetos)" % [GameProgress.passed_count(), GameProgress.total_count()]
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	victory_root.visible = true


func _on_victory_restart() -> void:
	GameProgress.reset()
	_close_victory()


func _close_victory() -> void:
	victory_root.visible = false
	crosshair.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


# ── Input ─────────────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if victory_root.visible:
		_close_victory()
	elif quiz_open:
		close_quiz()


# ── Dados ───────────────────────────────────────────────────────────────────

func _load_item_data(path: String) -> Dictionary:
	if path.is_empty() or not FileAccess.file_exists(path):
		push_error("Arquivo de perguntas não encontrado: %s" % path)
		return {"name": "???", "questions": []}
	var text := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("JSON inválido em: %s" % path)
		return {"name": "???", "questions": []}
	return parsed
