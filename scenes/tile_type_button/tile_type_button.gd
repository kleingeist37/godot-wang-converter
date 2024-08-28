extends TextureButton

@export var tile_type := WangConverter.TileType.FILL;

func _on_pressed() -> void:
	EditorSignals.show_texture_file_dialog.emit(tile_type);
