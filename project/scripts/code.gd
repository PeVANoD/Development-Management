extends Node

@onready var choose_map = $"../Map"
@onready var choose_skin = $"../Skin"

func _ready():
	$BLUR.modulate.a = 0.0
	$ChooseWindow.scale = Vector2(0.0,0.0)
	$"../Skin/Slot/Head".animation = G.chosen_skin

func _on_button_pressed():
	if choose_map.get_node("Button").is_pressed():
		makeChoice(1)
	if choose_skin.get_node("Button").is_pressed():
		makeChoice(0)
		$"../Skin/Slot/Head/Eyes".set_process(false)
		$"../Skin/Slot/Head/Eyes/1/pupil".position = Vector2.ZERO
		$"../Skin/Slot/Head/Eyes/2/pupil".position = Vector2.ZERO
		var nodes = $ChooseWindow/SKIN/H.get_children()
		for i in nodes:
			i.get_node("Sprite/Head/Eyes").set_process(true)
	if $Button.is_pressed() and opened:
		close_choose()

func close_choose():
	$"../Skin/Slot/Head/Eyes".set_process(true)
	var nodes = $ChooseWindow/SKIN/H.get_children()
	for i in nodes:
		i.get_node("Sprite/Head/Eyes").set_process(false)
	$Button.set_mouse_filter(Control.MOUSE_FILTER_IGNORE)
	opened = false
	moveBLUR(0)

var tweenChoice: Tween
func makeChoice(where = 0, _end = 0):
	moveBLUR(1)
	tweenChoice = create_tween()
	tweenChoice.set_ease(Tween.EASE_OUT)
	tweenChoice.set_trans(Tween.TRANS_CUBIC)
	tweenChoice.tween_property($ChooseWindow, "scale", Vector2(1.0,1.0), 0.3)
	if where:
		$ChooseWindow/MAP.visible = true
		$ChooseWindow/SKIN.visible = false
	else:
		$ChooseWindow/MAP.visible = false
		$ChooseWindow/SKIN.visible = true

var tweenBLUR: Tween
var opened = false
func moveBLUR(how = 0):
	tweenBLUR = create_tween()
	tweenBLUR.set_ease(Tween.EASE_OUT)
	tweenBLUR.set_trans(Tween.TRANS_CUBIC)
	if !how:
		tweenBLUR.tween_property($BLUR, "modulate:a", 0.0, 0.3)
		$Button.set_mouse_filter(Control.MOUSE_FILTER_IGNORE)
		tweenChoice = create_tween()
		tweenChoice.set_ease(Tween.EASE_IN)
		tweenChoice.set_trans(Tween.TRANS_CUBIC)
		tweenChoice.tween_property($ChooseWindow, "scale", Vector2(0.0,0.0), 0.1)
		opened = false
	else:
		$Button.set_mouse_filter(Control.MOUSE_FILTER_STOP)
		opened = true
		tweenBLUR.tween_property($BLUR, "modulate:a", 1.0, 0.3)

var colors = [
	"60ff6f",
	"ff96a2",
	"6fd6ff"
]

func _on_choose_pressed():
	close_choose()
	if $"ChooseWindow/MAP/H/1/Button".is_pressed():
		$"../Map/Slot/Sprite".animation = "0"
	if $"ChooseWindow/MAP/H/2/Button".is_pressed():
		$"../Map/Slot/Sprite".animation = "1"
	if $"ChooseWindow/MAP/H/3/Button".is_pressed():
		$"../Map/Slot/Sprite".animation = "2"
	if $"ChooseWindow/SKIN/H/1/Button".is_pressed():
		$"../Skin/Slot/Head".animation = "1"
		G.chosen_skin = "1"
	if $"ChooseWindow/SKIN/H/2/Button".is_pressed():
		$"../Skin/Slot/Head".animation = "2"
		G.chosen_skin = "2"
	if $"ChooseWindow/SKIN/H/3/Button".is_pressed():
		$"../Skin/Slot/Head".animation = "3"
		G.chosen_skin = "3"
