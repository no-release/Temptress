extends Control
# =============================================================================
# Home.gd — Phase 4 upgrades
# =============================================================================

@onready var body: Label = $Margin/VBox/Body
@onready var list: VBoxContainer = $Margin/VBox/UpgradeList
@onready var back_button: Button = $Margin/VBox/Back

func _ready() -> void:
	MusicDirector.play("home")
	back_button.pressed.connect(func():
		SoundGen.play_ui_click()
		get_tree().change_scene_to_file("res://scenes/Town.tscn")
	)
	_rebuild()

func _rebuild() -> void:
	body.text = "Home — spend banked gold on permanent training.\nBanked gold: %d" % MetaSave.banked_gold
	for child in list.get_children():
		child.queue_free()
	for id in UpgradeCatalog.UPGRADES.keys():
		var def: Dictionary = UpgradeCatalog.UPGRADES[id]
		var rank := MetaSave.upgrade_rank(id)
		var max_rank := int(def["max_rank"])
		var row := HBoxContainer.new()
		var label := Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if rank >= max_rank:
			label.text = "%s (MAX) — %s" % [def["name"], def["description"]]
		else:
			label.text = "%s [%d/%d] — %s" % [def["name"], rank, max_rank, def["description"]]
		row.add_child(label)
		var btn := Button.new()
		if rank >= max_rank:
			btn.text = "MAX"
			btn.disabled = true
		else:
			var cost := UpgradeCatalog.cost_for(id)
			btn.text = "Buy (%d)" % cost
			var upgrade_id := String(id)
			btn.pressed.connect(func(): _buy(upgrade_id))
		row.add_child(btn)
		list.add_child(row)

func _buy(id: String) -> void:
	SoundGen.play_ui_click()
	if MetaSave.try_buy_upgrade(id):
		_rebuild()
	else:
		body.text = "Not enough gold (or maxed).\nBanked gold: %d" % MetaSave.banked_gold
