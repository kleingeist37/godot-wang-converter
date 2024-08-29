extends TextureButton

@export var tile_type := EditorEnums.TileType.BORDER;

func _on_pressed() -> void:
	EditorSignals.show_texture_file_dialog.emit(tile_type);


func _on_btn_remove_pressed() -> void:
	EditorSignals.remove_texture.emit(tile_type);
