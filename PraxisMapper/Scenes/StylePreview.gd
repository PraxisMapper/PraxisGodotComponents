extends Node2D

func _draw() -> void:
	pass
	#Draw the currently loaded entry 4 ways
	#point, square, poly, line
	
	var matchOrder = get_parent().currentMatchOrder
	var bgColor = matchOrder["9999"][0].color
	draw_rect(Rect2(0, 0, 100, 100), bgColor)
	
	#TODO: order these now? or do that automatically?
	for drawop in matchOrder:
		draw_circle(Vector2(20, 20), drawop.sizePx, drawop.color)
		
		draw_rect(Rect2(20, 40, 20, 20), drawop.color)
		
		draw_line(Vector2(20, 60), Vector2(40,80), drawop.color, drawop.sizePx)
		draw_line(Vector2(20, 70), Vector2(40,90), drawop.color, drawop.sizePx, true)
