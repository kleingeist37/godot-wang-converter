extends HBoxContainer

func _on_btn_close_pressed() -> void:
	get_tree().quit();


func _on_btn_new_pressed() -> void:
	EditorSignals.new_texture.emit();


func _on_btn_export_pressed() -> void:
	EditorSignals.export_texture.emit();
