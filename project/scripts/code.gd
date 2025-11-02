extends Node

@onready var choose_map = $"../Map"
@onready var choose_skin = $"../Skin"

func _ready():
	$BLUR.modulate.a = 0.0
	$ChooseWindow.scale = Vector2(0.0,0.0)

func _on_button_pressed():
	if choose_map.get_node("Button").is_pressed():
		makeChoice(1)
	if choose_skin.get_node("Button").is_pressed():
		makeChoice(0)
	if $Button.is_pressed() and opened:
		$Button.set_mouse_filter(Control.MOUSE_FILTER_IGNORE)
		opened = false
		moveBLUR(0)

var tweenChoice: Tween
func makeChoice(where = 0, end = 0):
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
