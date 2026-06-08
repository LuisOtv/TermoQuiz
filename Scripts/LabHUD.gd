extends CanvasLayer

const LETTERS: Array = ["A", "B", "C", "D"]

# Paleta — console diegético de laboratório (escuro). O acento vem do objeto.
const COL_ACCENT := Color(0.16, 0.78, 0.7)
const COL_PANEL := Color(0.082, 0.094, 0.125, 0.985)
const COL_BORDER := Color(0.27, 0.31, 0.38)
const COL_TEXT := Color(0.9, 0.93, 0.96)
const COL_MUTED := Color(0.52, 0.57, 0.65)
const COL_OPT := Color(0.137, 0.157, 0.2)
const COL_OPT_HOVER := Color(0.19, 0.22, 0.28)
const COL_OPT_DOWN := Color(0.1, 0.12, 0.16)
const COL_CORRECT := Color(0.3, 0.83, 0.45)
const COL_WRONG := Color(0.95, 0.43, 0.43)
const COL_ANS_OK_BG := Color(0.11, 0.21, 0.15)
const COL_ANS_NO_BG := Color(0.23, 0.12, 0.13)

# Volumes de áudio (em decibéis; 0 = cheio, mais negativo = mais baixo).
const MUSIC_DB := -24.0
const SFX_DB := -13.0

# HUD persistente
var crosshair: Control
var prompt_label: Label
var progress_label: Label
var progress_bar: ProgressBar
var _hover: bool = false

# Painel de quiz
var mono_font: Font
var _accent: Color = COL_ACCENT
var quiz_root: Control
var quiz_panel: PanelContainer
var header_bar: ColorRect
var header_dot: ColorRect
var header_tag: Label
var title_rule: ColorRect
var panel_title_label: Label
var q_counter_label: Label
var question_label: RichTextLabel
var opts_container: VBoxContainer
var option_buttons: Array = []
var feedback_label: Label
var results_label: Label
var next_btn: Button
var refazer_btn: Button
var back_btn: Button

# Vitória
var victory_root: Control
var victory_panel: PanelContainer
var victory_label: Label

# Áudio
var music_player: AudioStreamPlayer
var sfx_right: AudioStreamPlayer
var sfx_wrong: AudioStreamPlayer

# Estado do quiz
var current_data: Dictionary = {}
var session_questions: Array = []
var current_id: String = ""
var current_question_index: int = 0
var answered: bool = false
var session_correct: int = 0
var quiz_open: bool = false
var showing_results: bool = false


func _ready() -> void:
	add_to_group("HUD")
	mono_font = load("res://Fonts/IBMPlexMono-Medium.ttf")
	_build_hud()
	_build_quiz_panel()
	_build_victory()
	_setup_audio()
	GameProgress.updated.connect(_refresh_progress)
	GameProgress.completed.connect(_on_completed)
	_refresh_progress()


# ── Construção da UI ──────────────────────────────────────────────────────────

func _build_hud() -> void:
	# Mira: um ponto circular simples, com contorno escuro para contraste.
	var dot := 7.0
	crosshair = Panel.new()
	crosshair.set_anchors_preset(Control.PRESET_CENTER)
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crosshair.offset_left = -dot * 0.5
	crosshair.offset_right = dot * 0.5
	crosshair.offset_top = -dot * 0.5
	crosshair.offset_bottom = dot * 0.5
	crosshair.pivot_offset = Vector2(dot * 0.5, dot * 0.5)
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(1, 1, 1, 0.92)
	cs.set_corner_radius_all(8)
	cs.border_color = Color(0, 0, 0, 0.55)
	cs.set_border_width_all(1)
	cs.shadow_color = Color(0, 0, 0, 0.45)
	cs.shadow_size = 2
	crosshair.add_theme_stylebox_override("panel", cs)
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
	pgs.font_color = Color(0.92, 0.82, 0.58)
	pgs.outline_size = 4
	pgs.outline_color = Color(0, 0, 0, 0.85)
	progress_label.label_settings = pgs
	add_child(progress_label)

	# Barra de progresso fininha sob o contador (preenche com animação).
	progress_bar = ProgressBar.new()
	progress_bar.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	progress_bar.show_percentage = false
	progress_bar.min_value = 0.0
	progress_bar.max_value = 1.0
	progress_bar.value = 0.0
	progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress_bar.offset_left = -240
	progress_bar.offset_right = -18
	progress_bar.offset_top = 52
	progress_bar.offset_bottom = 60
	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color(0, 0, 0, 0.35)
	bar_bg.set_corner_radius_all(4)
	progress_bar.add_theme_stylebox_override("background", bar_bg)
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = COL_ACCENT
	bar_fill.set_corner_radius_all(4)
	progress_bar.add_theme_stylebox_override("fill", bar_fill)
	add_child(progress_bar)


func _build_quiz_panel() -> void:
	quiz_root = CenterContainer.new()
	quiz_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	quiz_root.visible = false
	add_child(quiz_root)

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.05, 0.62)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	quiz_root.add_child(dim)

	quiz_panel = PanelContainer.new()
	quiz_panel.custom_minimum_size = Vector2(860, 600)
	quiz_panel.pivot_offset = Vector2(430, 300)
	var ps := StyleBoxFlat.new()
	ps.bg_color = COL_PANEL
	ps.border_color = COL_BORDER
	ps.set_border_width_all(1)
	ps.set_corner_radius_all(5)
	ps.shadow_color = Color(0, 0, 0, 0.5)
	ps.shadow_size = 40
	quiz_panel.add_theme_stylebox_override("panel", ps)
	quiz_root.add_child(quiz_panel)

	# Coluna externa: faixa de acento no topo (titlebar) + corpo com margem.
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 0)
	quiz_panel.add_child(outer)

	header_bar = ColorRect.new()
	header_bar.color = COL_ACCENT
	header_bar.custom_minimum_size = Vector2(0, 4)
	outer.add_child(header_bar)

	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 44)
	pad.add_theme_constant_override("margin_right", 44)
	pad.add_theme_constant_override("margin_top", 30)
	pad.add_theme_constant_override("margin_bottom", 28)
	pad.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(pad)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 11)
	pad.add_child(vbox)

	# Cabeçalho: ponto + rótulo à esquerda, contador à direita.
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 9)
	vbox.add_child(head)

	header_dot = ColorRect.new()
	header_dot.color = COL_ACCENT
	header_dot.custom_minimum_size = Vector2(9, 9)
	header_dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(header_dot)

	header_tag = Label.new()
	header_tag.text = "EQUIPAMENTO"
	var hts := LabelSettings.new()
	hts.font = mono_font
	hts.font_size = 14
	hts.font_color = COL_ACCENT
	header_tag.label_settings = hts
	head.add_child(header_tag)

	var head_sp := Control.new()
	head_sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(head_sp)

	q_counter_label = Label.new()
	var cs := LabelSettings.new()
	cs.font = mono_font
	cs.font_size = 14
	cs.font_color = COL_MUTED
	q_counter_label.label_settings = cs
	head.add_child(q_counter_label)

	panel_title_label = Label.new()
	var ts := LabelSettings.new()
	ts.font = mono_font
	ts.font_size = 31
	ts.font_color = COL_TEXT
	panel_title_label.label_settings = ts
	vbox.add_child(panel_title_label)

	title_rule = ColorRect.new()
	title_rule.color = COL_ACCENT
	title_rule.custom_minimum_size = Vector2(58, 3)
	title_rule.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	vbox.add_child(title_rule)

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(gap)

	question_label = RichTextLabel.new()
	question_label.bbcode_enabled = true
	question_label.fit_content = true
	question_label.scroll_active = false
	question_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	question_label.add_theme_font_size_override("normal_font_size", 23)
	question_label.add_theme_font_size_override("bold_font_size", 23)
	question_label.add_theme_color_override("default_color", COL_TEXT)
	question_label.add_theme_constant_override("line_separation", 7)
	question_label.custom_minimum_size = Vector2(0.0, 66.0)
	vbox.add_child(question_label)

	opts_container = VBoxContainer.new()
	opts_container.add_theme_constant_override("separation", 9)
	vbox.add_child(opts_container)

	for i in 4:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0.0, 52.0)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.pressed.connect(_on_option_pressed.bind(i))
		_style_option(btn)
		opts_container.add_child(btn)
		option_buttons.append(btn)

	feedback_label = Label.new()
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var fs := LabelSettings.new()
	fs.font = mono_font
	fs.font_size = 18
	feedback_label.label_settings = fs
	feedback_label.visible = false
	vbox.add_child(feedback_label)

	results_label = Label.new()
	results_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	results_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	results_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var rs := LabelSettings.new()
	rs.font = mono_font
	rs.font_size = 27
	rs.font_color = COL_TEXT
	results_label.label_settings = rs
	results_label.visible = false
	vbox.add_child(results_label)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	var nav := HBoxContainer.new()
	nav.alignment = BoxContainer.ALIGNMENT_END
	nav.add_theme_constant_override("separation", 12)
	vbox.add_child(nav)

	back_btn = Button.new()
	back_btn.text = "VOLTAR  [ESC]"
	back_btn.custom_minimum_size = Vector2(0.0, 44.0)
	back_btn.pressed.connect(close_quiz)
	_style_nav_button(back_btn, false)
	nav.add_child(back_btn)

	var nav_sp := Control.new()
	nav_sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav.add_child(nav_sp)

	refazer_btn = Button.new()
	refazer_btn.text = "REFAZER"
	refazer_btn.custom_minimum_size = Vector2(150.0, 44.0)
	refazer_btn.visible = false
	refazer_btn.pressed.connect(_restart_quiz)
	_style_nav_button(refazer_btn, true)
	nav.add_child(refazer_btn)

	next_btn = Button.new()
	next_btn.text = "PRÓXIMA  >"
	next_btn.custom_minimum_size = Vector2(160.0, 44.0)
	next_btn.visible = false
	next_btn.pressed.connect(_on_next_pressed)
	_style_nav_button(next_btn, true)
	nav.add_child(next_btn)


func _build_victory() -> void:
	victory_root = CenterContainer.new()
	victory_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	victory_root.visible = false
	add_child(victory_root)

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.05, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	victory_root.add_child(dim)

	victory_panel = PanelContainer.new()
	victory_panel.custom_minimum_size = Vector2(660, 330)
	victory_panel.pivot_offset = Vector2(330, 165)
	var vs := StyleBoxFlat.new()
	vs.bg_color = COL_PANEL
	vs.border_color = COL_ACCENT
	vs.set_border_width_all(1)
	vs.set_corner_radius_all(5)
	vs.shadow_color = Color(0, 0, 0, 0.5)
	vs.shadow_size = 40
	victory_panel.add_theme_stylebox_override("panel", vs)
	victory_root.add_child(victory_panel)

	var vouter := VBoxContainer.new()
	vouter.add_theme_constant_override("separation", 0)
	victory_panel.add_child(vouter)

	var vbar := ColorRect.new()
	vbar.color = COL_ACCENT
	vbar.custom_minimum_size = Vector2(0, 4)
	vouter.add_child(vbar)

	var vpad := MarginContainer.new()
	vpad.add_theme_constant_override("margin_left", 48)
	vpad.add_theme_constant_override("margin_right", 48)
	vpad.add_theme_constant_override("margin_top", 40)
	vpad.add_theme_constant_override("margin_bottom", 36)
	vpad.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vouter.add_child(vpad)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vpad.add_child(vbox)

	var v_over := Label.new()
	v_over.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v_over.text = "[ LABORATÓRIO CONCLUÍDO ]"
	var vos := LabelSettings.new()
	vos.font = mono_font
	vos.font_size = 15
	vos.font_color = COL_ACCENT
	v_over.label_settings = vos
	vbox.add_child(v_over)

	victory_label = Label.new()
	victory_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	victory_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var ls := LabelSettings.new()
	ls.font = mono_font
	ls.font_size = 30
	ls.font_color = COL_TEXT
	victory_label.label_settings = ls
	vbox.add_child(victory_label)

	var vgap := Control.new()
	vgap.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(vgap)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	vbox.add_child(row)

	var restart := Button.new()
	restart.text = "RECOMEÇAR"
	restart.custom_minimum_size = Vector2(180.0, 46.0)
	restart.pressed.connect(_on_victory_restart)
	_style_nav_button(restart, false)
	row.add_child(restart)

	var close_v := Button.new()
	close_v.text = "CONTINUAR EXPLORANDO"
	close_v.custom_minimum_size = Vector2(240.0, 46.0)
	close_v.pressed.connect(_close_victory)
	_style_nav_button(close_v, true)
	row.add_child(close_v)


func _setup_audio() -> void:
	# Música de fundo em loop, bem baixinha.
	music_player = AudioStreamPlayer.new()
	var m: AudioStream = load("res://Audios/bgmusic.mp3")
	if m is AudioStreamMP3:
		m.loop = true
	music_player.stream = m
	music_player.volume_db = MUSIC_DB
	add_child(music_player)
	music_player.play()

	# Efeitos de acerto/erro, em volume baixo.
	sfx_right = AudioStreamPlayer.new()
	sfx_right.stream = load("res://Audios/right.mp3")
	sfx_right.volume_db = SFX_DB
	add_child(sfx_right)

	sfx_wrong = AudioStreamPlayer.new()
	sfx_wrong.stream = load("res://Audios/wrong.mp3")
	sfx_wrong.volume_db = SFX_DB
	add_child(sfx_wrong)


# Item de lista de console: fundo escuro plano + barra de acento à esquerda.
func _make_option_style(bg: Color, tab: Color, tab_w: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(4)
	s.content_margin_left = 20.0
	s.content_margin_right = 16.0
	s.content_margin_top = 12.0
	s.content_margin_bottom = 12.0
	s.border_color = tab
	s.border_width_left = tab_w
	s.border_width_top = 0
	s.border_width_right = 0
	s.border_width_bottom = 0
	return s


func _style_option(btn: Button) -> void:
	var dim := Color(_accent.r, _accent.g, _accent.b, 0.5)
	btn.add_theme_stylebox_override("normal", _make_option_style(COL_OPT, dim, 3))
	btn.add_theme_stylebox_override("hover", _make_option_style(COL_OPT_HOVER, _accent, 4))
	btn.add_theme_stylebox_override("focus", _make_option_style(COL_OPT_HOVER, _accent, 4))
	btn.add_theme_stylebox_override("pressed", _make_option_style(COL_OPT_DOWN, _accent, 4))
	btn.add_theme_color_override("font_color", COL_TEXT)
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	btn.add_theme_color_override("font_focus_color", Color(1, 1, 1))
	btn.add_theme_font_size_override("font_size", 19)


func _make_answer_style(bg: Color, tab: Color) -> StyleBoxFlat:
	return _make_option_style(bg, tab, 4)


func _style_nav_button(btn: Button, primary: bool) -> void:
	btn.add_theme_font_override("font", mono_font)
	btn.add_theme_font_size_override("font_size", 15)
	var fg: Color
	for state in ["normal", "hover", "pressed", "focus"]:
		var s := StyleBoxFlat.new()
		s.set_corner_radius_all(4)
		s.content_margin_left = 22.0
		s.content_margin_right = 22.0
		s.content_margin_top = 12.0
		s.content_margin_bottom = 12.0
		var lit: bool = state == "hover" or state == "focus"
		if primary:
			s.bg_color = _accent.lightened(0.12) if lit else _accent
			if state == "pressed":
				s.bg_color = _accent.darkened(0.12)
		else:
			# Secundário: contorno em acento, fundo translúcido.
			s.bg_color = Color(_accent.r, _accent.g, _accent.b, 0.14 if lit else 0.0)
			s.border_color = Color(_accent.r, _accent.g, _accent.b, 0.7)
			s.set_border_width_all(1)
		btn.add_theme_stylebox_override(state, s)
	fg = Color(0.04, 0.05, 0.07) if primary else _accent
	btn.add_theme_color_override("font_color", fg)
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 1) if primary else _accent.lightened(0.2))
	btn.add_theme_color_override("font_focus_color", fg)
	btn.add_theme_color_override("font_pressed_color", fg)


## Recolore os elementos de destaque com a cor do objeto interagido.
func _apply_accent(c: Color) -> void:
	_accent = c
	header_bar.color = c
	header_dot.color = c
	header_tag.label_settings.font_color = c
	title_rule.color = c
	var ps: StyleBoxFlat = quiz_panel.get_theme_stylebox("panel")
	ps.border_color = Color(c.r, c.g, c.b, 0.55)
	for btn in option_buttons:
		_style_option(btn)
	_style_nav_button(next_btn, true)
	_style_nav_button(refazer_btn, true)
	_style_nav_button(back_btn, false)


# ── Prompt / progresso (chamado pelo Player e por sinais) ──────────────────────

func set_prompt(text: String) -> void:
	if prompt_label:
		prompt_label.text = text
	_set_hover(false)


func set_prompt_for(obj: Object) -> void:
	var nm: String = str(obj.get("objectName"))
	if nm == "" or nm == "<null>":
		nm = "Objeto"
	if GameProgress.is_passed(nm):
		if prompt_label:
			prompt_label.text = "%s   ·   concluído      [F] refazer" % nm
	else:
		if prompt_label:
			prompt_label.text = "[F]    %s" % nm
	_set_hover(true)


## Mira cresce e ganha cor de acento ao mirar num objeto interagível.
func _set_hover(on: bool) -> void:
	if on == _hover or crosshair == null:
		return
	_hover = on
	var tw := create_tween().set_parallel(true)
	if on:
		tw.tween_property(crosshair, "scale", Vector2(1.6, 1.6), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(crosshair, "modulate", Color(0.35, 1.0, 0.9), 0.16)
	else:
		tw.tween_property(crosshair, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_SINE)
		tw.tween_property(crosshair, "modulate", Color.WHITE, 0.16)


func _refresh_progress() -> void:
	var done: int = GameProgress.passed_count()
	var total: int = GameProgress.total_count()
	if progress_label:
		progress_label.text = "Concluídos: %d / %d" % [done, total]
	if progress_bar and total > 0:
		var target: float = float(done) / float(total)
		create_tween().tween_property(progress_bar, "value", target, 0.5) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


# ── Fluxo do quiz ──────────────────────────────────────────────────────────────

func open_quiz(data_file: String, id: String, accent: Color = COL_ACCENT) -> void:
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
	_prepare_session()

	_apply_accent(accent)
	q_counter_label.visible = true
	question_label.visible = true
	opts_container.visible = true
	results_label.visible = false
	refazer_btn.visible = false
	panel_title_label.text = str(data.get("name", id)).to_upper()

	crosshair.visible = false
	set_prompt("")
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	quiz_root.visible = true
	_pop_in(quiz_panel)
	_update_question_display()


func close_quiz() -> void:
	quiz_open = false
	showing_results = false
	quiz_root.visible = false
	crosshair.visible = true
	if not victory_root.visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _questions() -> Array:
	return session_questions


## Monta a sessão: embaralha a ordem das perguntas e, em cada pergunta,
## embaralha a posição das alternativas (recalculando o índice correto).
func _prepare_session() -> void:
	var src: Array = current_data.get("questions", [])
	var work: Array = src.duplicate()
	work.shuffle()
	session_questions = []
	for q in work:
		session_questions.append(_shuffle_options(q))


func _shuffle_options(q: Dictionary) -> Dictionary:
	var opts: Array = (q.get("options", []) as Array).duplicate()
	var correct: int = clampi(int(q.get("correct", 0)), 0, maxi(opts.size() - 1, 0))
	var correct_value: Variant = opts[correct] if correct < opts.size() else null
	opts.shuffle()
	var new_correct: int = opts.find(correct_value)
	if new_correct < 0:
		new_correct = 0
	return {"q": q.get("q", ""), "options": opts, "correct": new_correct}


func _update_question_display() -> void:
	var questions := _questions()
	var total: int = questions.size()
	var q: Dictionary = questions[current_question_index]

	q_counter_label.text = "Q.%02d / %02d" % [current_question_index + 1, total]
	question_label.text = "[b]%s[/b]" % str(q.get("q", ""))

	var opts: Array = q.get("options", [])
	for i in 4:
		var btn: Button = option_buttons[i]
		var label_text: String = str(opts[i]) if i < opts.size() else ""
		btn.text = "%s     %s" % [LETTERS[i], label_text]
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
		var bg: Color
		var tab: Color
		var font_color: Color
		if i == correct:
			bg = COL_ANS_OK_BG
			tab = COL_CORRECT
			font_color = Color(0.82, 1.0, 0.86)
		elif i == opt_idx:
			bg = COL_ANS_NO_BG
			tab = COL_WRONG
			font_color = Color(1.0, 0.85, 0.85)
		else:
			bg = COL_OPT_DOWN
			tab = Color(1, 1, 1, 0.08)
			font_color = COL_MUTED
		btn.add_theme_stylebox_override("disabled", _make_answer_style(bg, tab))
		btn.add_theme_color_override("font_disabled_color", font_color)

	var fs: LabelSettings = feedback_label.label_settings
	if is_right:
		session_correct += 1
		feedback_label.text = "✓  CORRETO"
		fs.font_color = COL_CORRECT
		if sfx_right:
			sfx_right.play()
	else:
		feedback_label.text = "RESPOSTA CERTA:  %s)  %s" % [LETTERS[correct], str(opts[correct])]
		fs.font_color = COL_WRONG
		if sfx_wrong:
			sfx_wrong.play()
	feedback_label.visible = true
	_fade_in(feedback_label)

	# A alternativa correta "salta" para chamar a atenção.
	_pop_scale(option_buttons[correct])
	if not is_right:
		_shake(option_buttons[opt_idx])

	var total: int = _questions().size()
	next_btn.text = "Ver resultado" if current_question_index == total - 1 else "Próxima"
	next_btn.visible = true
	_fade_in(next_btn)


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
		results_label.text = "APROVADO\n\n%d / %d acertos  ·  %d%%" % [session_correct, total, pct]
		results_label.label_settings.font_color = COL_CORRECT
	else:
		results_label.text = "QUASE LÁ\n\n%d / %d acertos  ·  %d%%\nmínimo p/ aprovar: %d%%" % [session_correct, total, pct, min_pct]
		results_label.label_settings.font_color = COL_WRONG
	results_label.visible = true
	refazer_btn.visible = true
	_pop_scale(results_label, 1.12)
	if passed:
		_spawn_confetti(40)


func _restart_quiz() -> void:
	showing_results = false
	results_label.visible = false
	refazer_btn.visible = false
	q_counter_label.visible = true
	question_label.visible = true
	opts_container.visible = true
	current_question_index = 0
	session_correct = 0
	_prepare_session()
	_update_question_display()


# ── Vitória ─────────────────────────────────────────────────────────────────

func _on_completed() -> void:
	quiz_open = false
	quiz_root.visible = false
	crosshair.visible = false
	set_prompt("")
	victory_label.text = "Você dominou todos os\n%d objetos do laboratório" % GameProgress.total_count()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	victory_root.visible = true
	_pop_in(victory_panel)
	_spawn_confetti(90)


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


# ── Animações da interface ──────────────────────────────────────────────────

## Aparição com leve crescimento + fade (efeito "pop").
func _pop_in(ctrl: Control) -> void:
	if ctrl == null:
		return
	ctrl.scale = Vector2(0.9, 0.9)
	ctrl.modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(ctrl, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(ctrl, "modulate:a", 1.0, 0.22)


## Pulso rápido de escala (chama atenção sem deslocar o layout).
func _pop_scale(ctrl: Control, peak: float = 1.06) -> void:
	if ctrl == null:
		return
	ctrl.pivot_offset = ctrl.size * 0.5
	ctrl.scale = Vector2.ONE
	var tw := create_tween()
	tw.tween_property(ctrl, "scale", Vector2(peak, peak), 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(ctrl, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


## Pequeno tremor horizontal — usado na alternativa errada.
func _shake(ctrl: Control) -> void:
	if ctrl == null:
		return
	ctrl.pivot_offset = ctrl.size * 0.5
	var base := ctrl.position
	var tw := create_tween()
	for ox in [10.0, -8.0, 6.0, -4.0, 0.0]:
		tw.tween_property(ctrl, "position:x", base.x + ox, 0.05)
	tw.tween_callback(func() -> void: ctrl.position = base)


## Fade-in simples de um Control.
func _fade_in(ctrl: Control) -> void:
	if ctrl == null:
		return
	ctrl.modulate.a = 0.0
	create_tween().tween_property(ctrl, "modulate:a", 1.0, 0.25)


## Chuva de confete colorido (papeizinhos que caem girando).
func _spawn_confetti(count: int) -> void:
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var palette: Array = [
		COL_ACCENT, COL_CORRECT, Color(0.95, 0.78, 0.3),
		Color(0.95, 0.45, 0.55), Color(0.4, 0.6, 0.95), Color(0.7, 0.5, 0.9),
	]
	for i in count:
		var r := ColorRect.new()
		r.color = palette[randi() % palette.size()]
		var s := Vector2(randf_range(7, 13), randf_range(10, 18))
		r.size = s
		r.pivot_offset = s * 0.5
		r.position = Vector2(randf() * vp.x, randf_range(-60.0, -10.0))
		r.rotation = randf() * TAU
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(r)
		var dur := randf_range(1.6, 3.2)
		var tw := create_tween().set_parallel(true)
		tw.tween_property(r, "position:y", vp.y + 40.0, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(r, "position:x", r.position.x + randf_range(-90.0, 90.0), dur)
		tw.tween_property(r, "rotation", r.rotation + randf_range(-8.0, 8.0), dur)
		tw.chain().tween_callback(r.queue_free)
