extends Node


func _on_timer_timeout():
	Database._net_tick()
