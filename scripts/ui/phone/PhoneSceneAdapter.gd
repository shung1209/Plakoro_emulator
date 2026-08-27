extends Control


@export_enum(
	"save", "encounters", "preparation", "enerkoro", "loadout", "battle", "result"
)
var layout_kind: String = "battle"


var source: Control = null
var battle_views: Dictionary = {}
var first_move_prompt_shown: bool = false
var loadout_views: Dictionary = {}
var loadout_apply_button: Button = null
var phone_roll_confirmation_list: VBoxContainer = null


func _ready() -> void:
	source = get_node_or_null("Source") as Control
	if source == null:
		push_error("PhoneSceneAdapter: Source scene is missing.")
		return
	if layout_kind == "loadout":
		_hide("Margin")
	await get_tree().process_frame
	match layout_kind:
		"save":
			_adapt_save_creation()
		"encounters":
			_adapt_encounter_select()
		"preparation":
			_adapt_preparation()
		"enerkoro":
			_adapt_enerkoro_builder()
		"loadout":
			_adapt_battle_loadout()
		"battle":
			_adapt_battle()
		"result":
			_adapt_result()
	LocalizationService.locale_changed.connect(_on_locale_changed)
	_apply_phone_text()


func _process(_delta: float) -> void:
	if layout_kind == "loadout":
		_sync_loadout_apply_state()
		return
	if layout_kind != "battle" or source == null:
		return
	var locked: Variant = source.get("input_locked")
	if locked is not bool:
		return
	if not first_move_prompt_shown and not bool(locked):
		first_move_prompt_shown = true
		_show_battle_view(&"moves")


func _adapt_save_creation() -> void:
	_compact_top_bar("TopBar", "Brand")
	var panel: Control = _control("Center/Panel")
	var center: Control = _control("Center")
	var margin: MarginContainer = _margin("Center/Panel/Margin")
	var content: VBoxContainer = _vbox("Center/Panel/Margin/Content")
	var starters: HBoxContainer = _hbox("Center/Panel/Margin/Content/Starters")
	if panel != null:
		panel.custom_minimum_size = Vector2(440, 760)
	if center != null:
		_set_full_page_offsets(center, 10, 68, 10, 10)
	_set_margins(margin, 18)
	if content != null:
		content.add_theme_constant_override("separation", 12)
	var title: Label = _label("Center/Panel/Margin/Content/TitleLabel")
	if title != null:
		title.add_theme_font_size_override("font_size", 27)
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var subtitle: Label = _label("Center/Panel/Margin/Content/SubtitleLabel")
	if subtitle != null:
		subtitle.add_theme_font_size_override("font_size", 15)
		subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if starters != null and content != null:
		var stack: VBoxContainer = VBoxContainer.new()
		stack.name = "PhoneStarterStack"
		stack.add_theme_constant_override("separation", 10)
		content.add_child(stack)
		content.move_child(stack, starters.get_index())
		for child: Node in starters.get_children():
			if child is Button:
				child.reparent(stack)
				(child as Button).custom_minimum_size = Vector2(0, 82)
		starters.visible = false


func _adapt_encounter_select() -> void:
	_compact_top_bar("TopBar", "Brand")
	var panel: Control = _control("Center/Panel")
	var center: Control = _control("Center")
	if panel != null:
		panel.custom_minimum_size = Vector2(440, 810)
	if center != null:
		_set_full_page_offsets(center, 10, 68, 10, 10)
	_set_margins(_margin("Center/Panel/Margin"), 16)
	var title: Label = _label("Center/Panel/Margin/Content/PageTitle")
	if title != null:
		title.add_theme_font_size_override("font_size", 26)
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var subtitle: Label = _label("Center/Panel/Margin/Content/PageSubtitle")
	if subtitle != null:
		subtitle.add_theme_font_size_override("font_size", 14)
		subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _adapt_preparation() -> void:
	var main: VBoxContainer = _vbox("Margin/Main")
	var content: VBoxContainer = _vbox("Margin/Main/ContentScroll/Content")
	var body: Control = _control("Margin/Main/ContentScroll/Content/Body")
	var title: Label = _label("Margin/Main/Header/Title")
	if title != null:
		title.add_theme_font_size_override("font_size", 23)
	_hide("Margin/Main/Header/LanguageSelector")
	_hide("Margin/Main/Header/LoadoutIdLabel")
	_hide("Margin/Main/Header/ContentStudioButton")
	_hide(
		"Margin/Main/ContentScroll/Content/Body/LeftColumn/TopSummaryRow/"
		+ "BattleReadyPanel/BattleReadyBox/ResolutionModeBox"
	)
	_hide("Margin/Main/ContentScroll/Content/Body/RightColumn/CoveragePanel")
	_hide("Margin/Main/ContentScroll/Content/Body/RightColumn/MoveDraftStatusPanel")
	var refresh_button: Button = source.get_node_or_null("%RefreshButton") as Button
	if refresh_button != null:
		refresh_button.visible = false
	if content == null or body == null:
		return
	var stack: VBoxContainer = VBoxContainer.new()
	stack.name = "PhonePreparationStack"
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 10)
	content.add_child(stack)
	content.move_child(stack, body.get_index())
	var paths: Array[String] = [
		"Margin/Main/ContentScroll/Content/Body/LeftColumn/TopSummaryRow/PokemonPanel",
		"Margin/Main/ContentScroll/Content/Body/LeftColumn/TopSummaryRow/BattleReadyPanel",
		"Margin/Main/ContentScroll/Content/Body/LeftColumn/MovesPanel",
		"Margin/Main/ContentScroll/Content/Body/RightColumn/DicePanel"
	]
	for path: String in paths:
		var panel: Control = _control(path)
		if panel != null:
			panel.reparent(stack)
			panel.custom_minimum_size.x = 0
	body.visible = false
	var move_grid: GridContainer = source.get_node_or_null("%MoveContainer") as GridContainer
	if move_grid != null:
		move_grid.columns = 1
	_stack_phone_dice_previews()
	_adapt_preparation_actions(main)


func _adapt_enerkoro_builder() -> void:
	_hide("Margin/Main/Header/LanguageSelector")
	_hide("Margin/Main/ContentScroll/Content/ContextPanel/ContextRow/ContextBox")
	_hide("Margin/Main/ContentScroll/Content/BuilderHint")
	_hide("Margin/Main/ContentScroll/Content/RepeatFixedEnergyToggle")
	_hide("Margin/Main/ContentScroll/Content/AdvancedToggle")
	_hide("Margin/Main/ContentScroll/Content/PreviewCoverageRow")
	var content_scroll: ScrollContainer = source.get_node_or_null(
		"Margin/Main/ContentScroll"
	) as ScrollContainer
	var dice_scroll: ScrollContainer = source.get_node_or_null(
		"Margin/Main/ContentScroll/Content/DiceScroll"
	) as ScrollContainer
	var dice_row: HBoxContainer = source.get_node_or_null(
		"%DiceContainer"
	) as HBoxContainer
	if content_scroll != null:
		content_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	if dice_scroll != null:
		dice_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		dice_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		dice_scroll.custom_minimum_size.y = 0
	if dice_row != null and dice_scroll != null:
		var dice_stack: VBoxContainer = VBoxContainer.new()
		dice_stack.name = "PhoneDiceStack"
		dice_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		dice_stack.add_theme_constant_override("separation", 14)
		dice_scroll.add_child(dice_stack)
		for editor: Node in dice_row.get_children():
			if editor is Control:
				editor.reparent(dice_stack)
				(editor as Control).custom_minimum_size.x = 0
				(editor as Control).size_flags_horizontal = Control.SIZE_EXPAND_FILL
		dice_row.queue_free()
	var save_path: LineEdit = source.get_node_or_null("%SavePathEdit") as LineEdit
	if save_path != null:
		save_path.visible = false
	var confirm: Button = source.get_node_or_null("%ConfirmButton") as Button
	if confirm != null:
		confirm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		confirm.custom_minimum_size.y = 58
	var margin: MarginContainer = source.get_node_or_null("Margin") as MarginContainer
	_set_margins(margin, 12)


func _adapt_battle_loadout() -> void:
	source.call("_prepare_battle_setup_controls")
	var page: MarginContainer = MarginContainer.new()
	page.name = "PhoneLoadoutPage"
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_set_margins(page, 12)
	source.add_child(page)
	var main: VBoxContainer = VBoxContainer.new()
	main.name = "PhoneLoadoutMain"
	main.add_theme_constant_override("separation", 10)
	page.add_child(main)
	var header: HBoxContainer = HBoxContainer.new()
	header.name = "PhoneLoadoutHeader"
	main.add_child(header)
	var title: Label = Label.new()
	title.name = "PhoneLoadoutTitle"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 25)
	header.add_child(title)
	var back: Button = Button.new()
	back.name = "PhoneLoadoutBack"
	back.custom_minimum_size = Vector2(92, 48)
	back.pressed.connect(GameFlow.open_preparation)
	header.add_child(back)
	var status: Label = source.get_node_or_null("%SetupStatusLabel") as Label
	if status != null:
		status.reparent(main)
		status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var tabs: HBoxContainer = HBoxContainer.new()
	tabs.name = "PhoneLoadoutTabs"
	tabs.add_theme_constant_override("separation", 8)
	main.add_child(tabs)
	var host: VBoxContainer = VBoxContainer.new()
	host.name = "PhoneLoadoutHost"
	host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_child(host)
	var player_panel: PanelContainer = source.get_node_or_null(
		"BattleSetupDialog/SetupRoot/SetupColumns/PlayerSetupPanel"
	) as PanelContainer
	var ai_panel: PanelContainer = source.get_node_or_null(
		"BattleSetupDialog/SetupRoot/SetupColumns/AISetupPanel"
	) as PanelContainer
	loadout_views = {&"player": player_panel, &"ai": ai_panel}
	for panel: PanelContainer in [player_panel, ai_panel]:
		if panel != null:
			panel.reparent(host)
			panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for tab_id: StringName in [&"player", &"ai"]:
		var tab: Button = Button.new()
		tab.name = String(tab_id).capitalize() + "LoadoutTab"
		tab.toggle_mode = true
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab.custom_minimum_size.y = 52
		tab.set_meta("phone_loadout_tab", tab_id)
		tab.pressed.connect(_show_loadout_view.bind(tab_id))
		tab.visible = tab_id == &"player" or GameFlow.free_mode
		tabs.add_child(tab)
	var actions: HBoxContainer = HBoxContainer.new()
	actions.name = "PhoneLoadoutActions"
	actions.add_theme_constant_override("separation", 8)
	main.add_child(actions)
	loadout_apply_button = Button.new()
	loadout_apply_button.name = "PhoneLoadoutApply"
	loadout_apply_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	loadout_apply_button.custom_minimum_size.y = 58
	loadout_apply_button.pressed.connect(_apply_phone_loadout)
	actions.add_child(loadout_apply_button)
	var player_scroll: ScrollContainer = source.get_node_or_null(
		"%SetupPlayerMoveScroll"
	) as ScrollContainer
	var ai_scroll: ScrollContainer = source.get_node_or_null(
		"%SetupAIMoveScroll"
	) as ScrollContainer
	for scroll: ScrollContainer in [player_scroll, ai_scroll]:
		if scroll != null:
			scroll.custom_minimum_size.y = 0
			scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_show_loadout_view(&"player")
	_apply_phone_text()


func _show_loadout_view(view_id: StringName) -> void:
	for key: Variant in loadout_views:
		var panel: Control = loadout_views[key] as Control
		if panel != null:
			panel.visible = StringName(key) == view_id
	var tabs: Node = source.get_node_or_null(
		"PhoneLoadoutPage/PhoneLoadoutMain/PhoneLoadoutTabs"
	)
	if tabs != null:
		for tab: Node in tabs.get_children():
			if tab is Button:
				(tab as Button).button_pressed = (
					StringName(tab.get_meta("phone_loadout_tab", &"")) == view_id
				)


func _sync_loadout_apply_state() -> void:
	if source == null or loadout_apply_button == null:
		return
	var dialog: ConfirmationDialog = source.get_node_or_null(
		"%BattleSetupDialog"
	) as ConfirmationDialog
	if dialog != null:
		loadout_apply_button.disabled = dialog.get_ok_button().disabled


func _apply_phone_loadout() -> void:
	var applied: bool = bool(source.call("_apply_battle_setup"))
	if applied:
		GameFlow.open_preparation()


func _stack_phone_dice_previews() -> void:
	var dice_row: HBoxContainer = source.get_node_or_null(
		"%DiceIconSummaryContainer"
	) as HBoxContainer
	if dice_row == null:
		return
	var dice_box: VBoxContainer = dice_row.get_parent() as VBoxContainer
	if dice_box == null:
		return
	var grid: GridContainer = GridContainer.new()
	grid.name = "PhoneDiceGrid"
	grid.columns = 1
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("v_separation", 8)
	dice_box.add_child(grid)
	dice_box.move_child(grid, dice_row.get_index())
	for child: Node in dice_row.get_children():
		if child is HBoxContainer:
			for preview: Node in child.get_children():
				if preview is Control:
					preview.reparent(grid)
					(preview as Control).custom_minimum_size.x = 0
					(preview as Control).size_flags_horizontal = Control.SIZE_EXPAND_FILL
			child.visible = false
		elif child is Control:
			child.reparent(grid)
	dice_row.visible = false


func _adapt_preparation_actions(main: VBoxContainer) -> void:
	var actions: HBoxContainer = _hbox("Margin/Main/Actions")
	if main == null or actions == null:
		return
	var start_battle_button: Button = source.get_node_or_null(
		"%StartBattleButton"
	) as Button
	var grid: GridContainer = GridContainer.new()
	grid.name = "PhoneActions"
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	main.add_child(grid)
	main.move_child(grid, actions.get_index())
	for child: Node in actions.get_children():
		if child is Button and child != start_battle_button:
			child.reparent(grid)
			(child as Button).custom_minimum_size = Vector2(0, 52)
			(child as Button).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if start_battle_button != null:
		start_battle_button.reparent(main)
		main.move_child(start_battle_button, grid.get_index() + 1)
		start_battle_button.custom_minimum_size = Vector2(0, 60)
		start_battle_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.visible = false


func _adapt_setup_dialog() -> void:
	var root: VBoxContainer = source.get_node_or_null("BattleSetupDialog/SetupRoot") as VBoxContainer
	var columns: HBoxContainer = source.get_node_or_null(
		"BattleSetupDialog/SetupRoot/SetupColumns"
	) as HBoxContainer
	if root == null or columns == null:
		return
	var stack: VBoxContainer = VBoxContainer.new()
	stack.name = "PhoneSetupStack"
	stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 8)
	root.add_child(stack)
	root.move_child(stack, columns.get_index())
	for child: Node in columns.get_children():
		if child is PanelContainer:
			child.reparent(stack)
	columns.visible = false
	_fit_setup_dialog()


func _fit_setup_dialog_deferred() -> void:
	call_deferred("_fit_setup_dialog")


func _fit_setup_dialog() -> void:
	var dialog: ConfirmationDialog = source.get_node_or_null("BattleSetupDialog") as ConfirmationDialog
	if dialog == null:
		return
	dialog.unresizable = false
	dialog.min_size = Vector2i(410, 680)
	dialog.max_size = Vector2i(460, 850)
	dialog.size = Vector2i(430, 780)
	var player_scroll: ScrollContainer = source.get_node_or_null("%SetupPlayerMoveScroll") as ScrollContainer
	var ai_scroll: ScrollContainer = source.get_node_or_null("%SetupAIMoveScroll") as ScrollContainer
	if player_scroll != null:
		player_scroll.custom_minimum_size.y = 260
	if ai_scroll != null:
		ai_scroll.custom_minimum_size.y = 220


func _adapt_battle() -> void:
	if source.has_method("_set_layout_prototype_enabled"):
		source.call("_set_layout_prototype_enabled", false)
	_hide("Margin/Main/Header/Title")
	_hide("Margin/Main/Header/LanguageSelector")
	_hide("Margin/Main/SetupSourceLabel")
	var timeline: Control = source.get("timeline_panel") as Control
	if timeline != null:
		timeline.visible = false
	var legacy_energy_state: Control = source.get("energy_state_panel") as Control
	var legacy_charakoro_state: Control = source.get(
		"charakoro_feedback_panel"
	) as Control
	if legacy_energy_state != null:
		legacy_energy_state.visible = false
	if legacy_charakoro_state != null:
		legacy_charakoro_state.visible = false
	var back: Button = source.get_node_or_null("%BackToPreparationButton") as Button
	var restart: Button = source.get_node_or_null("%RestartButton") as Button
	for button: Button in [back, restart]:
		if button != null:
			button.custom_minimum_size = Vector2(0, 42)
			button.add_theme_font_size_override("font_size", 13)
	var main: VBoxContainer = _vbox("Margin/Main")
	var body: HSplitContainer = source.get("body") as HSplitContainer
	var battle_scroll: ScrollContainer = source.get("battle_scroll") as ScrollContainer
	if main == null or body == null or battle_scroll == null:
		return
	var column: VBoxContainer = battle_scroll.get_node_or_null("BattleColumn") as VBoxContainer
	if column == null:
		return
	body.split_offset = 460
	battle_scroll.visible = true
	battle_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.custom_minimum_size.x = 0
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var tabs: HBoxContainer = HBoxContainer.new()
	tabs.name = "PhoneBattleTabs"
	tabs.add_theme_constant_override("separation", 6)
	main.add_child(tabs)
	main.move_child(tabs, body.get_index())
	for tab_id: StringName in [&"arena", &"moves", &"roll"]:
		var button: Button = Button.new()
		button.name = String(tab_id).capitalize() + "Tab"
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(0, 48)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.set_meta("phone_tab_id", tab_id)
		button.pressed.connect(_show_battle_view.bind(tab_id))
		tabs.add_child(button)
	var arena: VBoxContainer = _make_battle_view("PhoneArenaView", column)
	var moves: VBoxContainer = _make_battle_view("PhoneMovesView", column)
	var roll: VBoxContainer = _make_battle_view("PhoneRollView", column)
	battle_views = {&"arena": arena, &"moves": moves, &"roll": roll}
	for property: String in [
		"turn_banner_panel", "enemy_panel", "player_panel", "message_panel", "result_panel"
	]:
		var panel: Control = source.get(property) as Control
		if panel != null:
			panel.reparent(arena)
	var arena_message_panel: Control = source.get("message_panel") as Control
	if arena_message_panel != null:
		# Phone battle details belong with the dice sequence in the ROLL tab.
		# Keeping the legacy message panel in ARENA duplicates the result and
		# pushes both combatant cards below the fold.
		arena_message_panel.visible = false
	var moves_panel: Control = source.get("moves_panel") as Control
	var roll_panel: Control = source.get("roll_result_panel") as Control
	if moves_panel != null:
		moves_panel.reparent(moves)
		moves_panel.custom_minimum_size = Vector2.ZERO
	if roll_panel != null:
		roll_panel.reparent(roll)
		roll_panel.custom_minimum_size = Vector2(0, 380)
		roll_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		roll_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		var dice_presenter: Control = source.get_node_or_null(
			"%BattleDiceRollPresenter"
		) as Control
		if dice_presenter != null and dice_presenter.has_method("set_compact_mode"):
			dice_presenter.call("set_compact_mode", true)
		var confirmation_panel: PanelContainer = PanelContainer.new()
		confirmation_panel.name = "PhoneRollConfirmationPanel"
		confirmation_panel.custom_minimum_size = Vector2(0, 210)
		roll.add_child(confirmation_panel)
		var confirmation_margin: MarginContainer = MarginContainer.new()
		for margin_key: String in [
			"margin_left", "margin_top", "margin_right", "margin_bottom"
		]:
			confirmation_margin.add_theme_constant_override(margin_key, 14)
		confirmation_panel.add_child(confirmation_margin)
		phone_roll_confirmation_list = VBoxContainer.new()
		phone_roll_confirmation_list.name = "PhoneRollConfirmationList"
		phone_roll_confirmation_list.add_theme_constant_override("separation", 9)
		confirmation_margin.add_child(phone_roll_confirmation_list)
	var action_row: Control = source.get("action_row") as Control
	var combatants: Control = source.get("combatants") as Control
	var enemy_charakoro_button: Button = (
		source.get("enemy_charakoro_button") as Button
	)
	if action_row != null:
		action_row.visible = false
	if combatants != null:
		combatants.visible = false
	if enemy_charakoro_button != null:
		enemy_charakoro_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		enemy_charakoro_button.tooltip_text = ""
	var move_grid: GridContainer = source.get("move_button_container") as GridContainer
	if move_grid != null:
		move_grid.columns = 1
	var move_buttons_value: Variant = source.get("move_buttons")
	if move_buttons_value is Array:
		for button: Variant in move_buttons_value:
			if button is Button:
				var phone_card_height: float = 150.0
				if (button as Button).has_method(
					"get_phone_recommended_height"
				):
					phone_card_height = float(
						(button as Button).call(
							"get_phone_recommended_height"
						)
					)
				(button as Button).custom_minimum_size = Vector2(
					0,
					phone_card_height
				)
				(button as Button).pressed.connect(_on_phone_move_pressed)
	if source.has_signal("battle_phase_changed"):
		source.connect("battle_phase_changed", _on_battle_phase_changed)
	if source.has_signal("phone_roll_confirmation_changed"):
		source.connect(
			"phone_roll_confirmation_changed",
			_on_phone_roll_confirmation_changed
		)
	if source.has_signal("phone_attack_animation_requested"):
		source.connect(
			"phone_attack_animation_requested",
			_on_phone_attack_animation_requested
		)
	_fit_phone_popup("%CoinTossWindow", Vector2i(430, 410))
	_fit_phone_popup("%EnemyMoveWindow", Vector2i(440, 790))
	var viewport: Viewport = source.get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(
		_on_phone_battle_viewport_size_changed
	):
		viewport.size_changed.connect(_on_phone_battle_viewport_size_changed)
	_update_phone_battle_responsive_layout.call_deferred()
	_show_battle_view(&"arena")


func _make_battle_view(name_value: String, parent: VBoxContainer) -> VBoxContainer:
	var view: VBoxContainer = VBoxContainer.new()
	view.name = name_value
	view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	view.add_theme_constant_override("separation", 8)
	parent.add_child(view)
	return view


func _show_battle_view(view_id: StringName) -> void:
	if battle_views.is_empty():
		return
	for key: Variant in battle_views:
		(battle_views[key] as Control).visible = StringName(key) == view_id
	var tabs: Node = source.get_node_or_null("Margin/Main/PhoneBattleTabs")
	if tabs != null:
		for tab: Node in tabs.get_children():
			if tab is Button:
				(tab as Button).button_pressed = (
					StringName(tab.get_meta("phone_tab_id", &"")) == view_id
				)
	var scroll: ScrollContainer = source.get("battle_scroll") as ScrollContainer
	if scroll != null:
		scroll.scroll_vertical = 0
		if view_id == &"arena":
			_update_phone_battle_responsive_layout.call_deferred()
		else:
			_update_phone_battle_scroll.call_deferred()


func _update_phone_battle_scroll() -> void:
	if source == null:
		return
	var scroll: ScrollContainer = source.get("battle_scroll") as ScrollContainer
	if scroll == null:
		return
	var column: VBoxContainer = scroll.get_node_or_null("BattleColumn") as VBoxContainer
	if column == null:
		return
	var needs_vertical_scroll: bool = (
		column.get_combined_minimum_size().y > scroll.size.y + 1.0
	)
	scroll.vertical_scroll_mode = (
		ScrollContainer.SCROLL_MODE_AUTO
		if needs_vertical_scroll
		else ScrollContainer.SCROLL_MODE_DISABLED
	)


func _on_phone_battle_viewport_size_changed() -> void:
	_update_phone_battle_responsive_layout.call_deferred()


func _update_phone_battle_responsive_layout() -> void:
	if source == null or layout_kind != "battle":
		return
	var scroll: ScrollContainer = source.get("battle_scroll") as ScrollContainer
	if scroll == null or scroll.size.y <= 0.0:
		return
	# Keep both combatant cards and their icon identity rows visible without
	# creating a scrollbar on common portrait phone heights.
	var portrait_size: float = clampf(scroll.size.y * 0.16, 104.0, 164.0)
	var player_hero: VBoxContainer = source.get_node_or_null(
		"%PlayerHeroContainer"
	) as VBoxContainer
	var enemy_button: Button = source.get_node_or_null(
		"%EnemyCharakoroButton"
	) as Button
	var enemy_hero: VBoxContainer = source.get_node_or_null(
		"%EnemyHeroContainer"
	) as VBoxContainer
	if player_hero != null:
		player_hero.custom_minimum_size.y = portrait_size
		_resize_phone_portraits(player_hero, portrait_size)
	if enemy_button != null:
		enemy_button.custom_minimum_size.y = portrait_size
	if enemy_hero != null:
		_resize_phone_portraits(enemy_hero, portrait_size)
	_update_phone_battle_scroll.call_deferred()


func _resize_phone_portraits(root: Control, portrait_size: float) -> void:
	var content_size: float = maxf(80.0, portrait_size - 24.0)
	for child: Node in root.get_children():
		if not child is Control:
			continue
		var control: Control = child as Control
		control.custom_minimum_size = Vector2(portrait_size, portrait_size)
		control.clip_contents = true
		_fit_phone_portrait_content(control, content_size)


func _fit_phone_portrait_content(root: Control, content_size: float) -> void:
	for child: Node in root.get_children():
		if not child is Control:
			continue
		var control: Control = child as Control
		control.clip_contents = true
		if control is TextureRect or control is Label:
			control.custom_minimum_size = Vector2(content_size, content_size)
		else:
			# Containers should follow the outer frame without forcing their
			# original 200 px minimum size back into the phone layout.
			control.custom_minimum_size = Vector2.ZERO
		_fit_phone_portrait_content(control, content_size)


func _on_phone_move_pressed() -> void:
	_show_battle_view(&"roll")


func _on_phone_attack_animation_requested() -> void:
	_show_battle_view(&"arena")


func _on_battle_phase_changed(phase: StringName) -> void:
	match phase:
		&"choose_move":
			first_move_prompt_shown = true
			_clear_phone_roll_confirmations()
			_show_battle_view(&"moves")
		&"rolling", &"ai_rolling", &"select_target":
			if phase != &"select_target":
				_clear_phone_roll_confirmations()
			_show_battle_view(&"roll")
		&"resolving", &"ai_resolving":
			_show_battle_view(&"roll")
		&"ai_thinking":
			# Waiting for the opponent to choose is still an arena state.
			# Switch to ROLL only when their resolved dice event arrives and
			# BattleGameUI emits ai_rolling.
			_show_battle_view(&"arena")
		&"battle_finished":
			_show_battle_view(&"arena")


func _on_phone_roll_confirmation_changed(
	step: StringName,
	succeeded: bool,
	detail: String,
	amount: int
) -> void:
	var key: String = ""
	var fallback: String = ""
	var values: Dictionary = {}
	match step:
		&"move":
			key = "phone_mode.roll_move"
			fallback = "{actor} used {move}"
			values = {
				"actor": detail.get_slice("\n", 0),
				"move": detail.get_slice("\n", 1)
			}
		&"enerkoro":
			key = (
				"phone_mode.roll_enerkoro_damage"
					if succeeded
					else "phone_mode.roll_enerkoro_failed"
			)
			fallback = (
				"ENERKORO energy confirmed  +{damage}"
					if succeeded
					else "ENERKORO ENERGY FAILED"
			)
			values = {"damage": amount}
		&"charakoro":
			key = "phone_mode.roll_charakoro_damage"
			fallback = "CHARAKORO result confirmed  +{damage}"
			values = {"damage": amount}
		&"weakness":
			key = "phone_mode.roll_weakness_damage"
			fallback = "Weakness  +{damage}"
			values = {"damage": amount}
		&"attack":
			key = (
				"phone_mode.roll_attack_damage"
					if succeeded
					else "phone_mode.roll_attack_failed"
			)
			fallback = (
				"Attack succeeded  •  {damage} damage"
					if succeeded
					else "ATTACK FAILED!"
			)
			values = {"damage": amount}
	var message: String = LocalizationService.tr_format(
		key,
		values,
		fallback
	)
	var tone: StringName = &"neutral" if step == &"move" else (
		&"success" if succeeded else &"danger"
	)
	_append_phone_roll_confirmation(
		message,
		tone
	)


func _clear_phone_roll_confirmations() -> void:
	if phone_roll_confirmation_list == null:
		return
	for child: Node in phone_roll_confirmation_list.get_children():
		child.queue_free()
	_update_phone_battle_scroll.call_deferred()


func _append_phone_roll_confirmation(
	text_value: String,
	tone: StringName = &"neutral"
) -> void:
	if phone_roll_confirmation_list == null:
		return
	var line: Label = Label.new()
	var prefix: String = "▶  "
	if tone == &"success":
		prefix = "✓  "
	elif tone == &"danger":
		prefix = "X  "
	line.text = prefix + text_value
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.add_theme_font_size_override("font_size", 18)
	phone_roll_confirmation_list.add_child(line)
	match tone:
		&"success":
			line.modulate = Color(0.38, 0.9, 0.58, 1.0)
		&"danger":
			line.modulate = Color(1.0, 0.42, 0.42, 1.0)
		_:
			line.modulate = Color(0.95, 0.78, 0.3, 1.0)
	_update_phone_battle_scroll.call_deferred()


func _fit_phone_popup(path: String, target_size: Vector2i) -> void:
	var popup: Popup = source.get_node_or_null(path) as Popup
	if popup != null:
		popup.visibility_changed.connect(
			_on_phone_popup_visibility_changed.bind(popup, target_size)
		)


func _on_phone_popup_visibility_changed(popup: Popup, target_size: Vector2i) -> void:
	if popup.visible:
		popup.size = target_size
		var viewport_size: Vector2 = source.get_viewport_rect().size
		popup.position = Vector2i(
			int((viewport_size.x - target_size.x) * 0.5),
			int((viewport_size.y - target_size.y) * 0.5)
		)


func _adapt_result() -> void:
	_compact_top_bar("TopBar", "ReportBrand")
	var panel: Control = _control("Center/ResultPanel")
	var center: Control = _control("Center")
	var margin: MarginContainer = _margin("Center/ResultPanel/Margin")
	var content: VBoxContainer = _vbox("Center/ResultPanel/Margin/Content")
	if panel != null:
		panel.custom_minimum_size = Vector2(440, 810)
	if center != null:
		_set_full_page_offsets(center, 10, 68, 10, 10)
	_set_margins(margin, 14)
	if content != null:
		content.add_theme_constant_override("separation", 8)
	var title: Label = _label("Center/ResultPanel/Margin/Content/ResultTitle")
	if title != null:
		title.add_theme_font_size_override("font_size", 38)
	var matchup: Label = _label("Center/ResultPanel/Margin/Content/MatchupLabel")
	if matchup != null:
		matchup.add_theme_font_size_override("font_size", 17)
	var stats: HBoxContainer = _hbox("Center/ResultPanel/Margin/Content/Stats")
	if stats != null:
		stats.custom_minimum_size.y = 105
		stats.add_theme_constant_override("separation", 6)
	_adapt_result_actions(content)


func _adapt_result_actions(content: VBoxContainer) -> void:
	var actions: HBoxContainer = _hbox("Center/ResultPanel/Margin/Content/Actions")
	if actions == null or content == null:
		return
	var grid: GridContainer = GridContainer.new()
	grid.name = "PhoneResultActions"
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 7)
	grid.add_theme_constant_override("v_separation", 7)
	content.add_child(grid)
	content.move_child(grid, actions.get_index())
	for child: Node in actions.get_children():
		if child is Button:
			child.reparent(grid)
			(child as Button).custom_minimum_size = Vector2(0, 54)
	actions.visible = false


func _compact_top_bar(path: String, brand_name: String) -> void:
	var top_bar: HBoxContainer = _hbox(path)
	if top_bar == null:
		return
	top_bar.offset_left = 10
	top_bar.offset_top = 10
	top_bar.offset_right = -10
	top_bar.offset_bottom = 58
	var brand: Control = source.get_node_or_null(path + "/" + brand_name) as Control
	if brand != null:
		brand.visible = false


func _set_full_page_offsets(
	control: Control,
	left: float,
	top: float,
	right: float,
	bottom: float
) -> void:
	control.offset_left = left
	control.offset_top = top
	control.offset_right = -right
	control.offset_bottom = -bottom


func _set_margins(margin: MarginContainer, amount: int) -> void:
	if margin == null:
		return
	for key: String in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(key, amount)


func _hide(path: String) -> void:
	var control: Control = source.get_node_or_null(path) as Control
	if control != null:
		control.visible = false


func _control(path: String) -> Control:
	return source.get_node_or_null(path) as Control


func _label(path: String) -> Label:
	return source.get_node_or_null(path) as Label


func _margin(path: String) -> MarginContainer:
	return source.get_node_or_null(path) as MarginContainer


func _vbox(path: String) -> VBoxContainer:
	return source.get_node_or_null(path) as VBoxContainer


func _hbox(path: String) -> HBoxContainer:
	return source.get_node_or_null(path) as HBoxContainer


func _apply_phone_text() -> void:
	if source == null:
		return
	if layout_kind == "enerkoro":
		var save_button: Button = source.get_node_or_null("%ConfirmButton") as Button
		if save_button != null:
			save_button.text = LocalizationService.tr_key("common.save", "Save")
		return
	if layout_kind == "loadout":
		var title: Label = source.get_node_or_null(
			"PhoneLoadoutPage/PhoneLoadoutMain/PhoneLoadoutHeader/PhoneLoadoutTitle"
		) as Label
		var back: Button = source.get_node_or_null(
			"PhoneLoadoutPage/PhoneLoadoutMain/PhoneLoadoutHeader/PhoneLoadoutBack"
		) as Button
		if title != null:
			title.text = LocalizationService.tr_key(
				"phone_mode.loadout_title", "BATTLE LOADOUT"
			)
		if back != null:
			back.text = LocalizationService.tr_key("common.back", "Back")
		if loadout_apply_button != null:
			loadout_apply_button.text = LocalizationService.tr_key(
				"phone_mode.loadout_apply", "SAVE & USE"
			)
		var loadout_tabs: Node = source.get_node_or_null(
			"PhoneLoadoutPage/PhoneLoadoutMain/PhoneLoadoutTabs"
		)
		if loadout_tabs != null:
			for tab: Node in loadout_tabs.get_children():
				if tab is Button:
					var tab_id: StringName = StringName(
						tab.get_meta("phone_loadout_tab", &"")
					)
					(tab as Button).text = LocalizationService.tr_key(
						"phone_mode.loadout_%s" % String(tab_id),
						String(tab_id).to_upper()
					)
		return
	if layout_kind != "battle":
		return
	var tabs: Node = source.get_node_or_null("Margin/Main/PhoneBattleTabs")
	if tabs == null:
		return
	var keys: Dictionary = {
		&"arena": ["phone_mode.tab_arena", "ARENA"],
		&"moves": ["phone_mode.tab_moves", "MOVES"],
		&"roll": ["phone_mode.tab_roll", "ROLL"]
	}
	for child: Node in tabs.get_children():
		if child is Button:
			var tab_id: StringName = StringName(child.get_meta("phone_tab_id", &""))
			var entry: Array = keys.get(tab_id, ["", String(tab_id).to_upper()])
			(child as Button).text = LocalizationService.tr_key(entry[0], entry[1])


func _on_locale_changed(_locale: String) -> void:
	_apply_phone_text()
