class_name UIController extends Control

const TileType = EditorEnums.TileType;
@onready var wang_creator: WangConverter = $"..";

var orig_icons := {
	TileType.BORDER: preload("res://sprites/icon_border.png") as Texture2D,
	TileType.INNER_CORNER: preload("res://sprites/icon_inner_corner.png") as Texture2D,
	TileType.OUTER_CORNER: preload("res://sprites/icon_outer_corner.png") as Texture2D,
	TileType.OVERLAY_FILL: preload("res://sprites/icon_fill.png") as Texture2D,
	TileType.EDGE_CONNECTOR: preload("res://sprites/icon_edge_connector.png") as Texture2D,
	TileType.UNDERLAY_FILL: preload("res://sprites/icon_underlay_fill.png") as Texture2D
};

@onready var file_dialog: FileDialog = %file_dialog;
@onready var tile_type_button_outer_corner: TextureButton = %tile_type_button_outer_corner
@onready var tile_type_button_edge_connector: TextureButton = %tile_type_button_edge_connector
@onready var tile_type_button_inner_corner: TextureButton = %tile_type_button_inner_corner
@onready var tile_type_button_border: TextureButton = %tile_type_button_border
@onready var tile_type_button_overlay_fill: TextureButton = %tile_type_button_overlay_fill
@onready var tile_type_button_underlay_fill: TextureButton = %tile_type_button_underlay_fill
@onready var lbl_tile_size: Label = %lbl_tile_size
@onready var lbl_tile_set_size: Label = %lbl_tile_set_size
@onready var btn_export: Button = %btn_export
@onready var texture_preview: TextureRect = %texture_preview;
@onready var spinbox_white_tolerance: SpinBox = %spinbox_white_tolerance;





var filter_extensions: PackedStringArray;

var save_state := false; 


var button_dict := {}; #[TileType]: TileTypeButton;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	button_dict[TileType.BORDER] = tile_type_button_border;
	button_dict[TileType.INNER_CORNER] = tile_type_button_inner_corner;
	button_dict[TileType.OUTER_CORNER] = tile_type_button_outer_corner;
	button_dict[TileType.OVERLAY_FILL] = tile_type_button_overlay_fill;
	button_dict[TileType.UNDERLAY_FILL] = tile_type_button_underlay_fill;
	button_dict[TileType.EDGE_CONNECTOR] = tile_type_button_edge_connector;
	
	EditorSignals.export_texture.connect(_on_export_texture);
	EditorSignals.new_texture.connect(_on_new_texture);
	EditorSignals.show_texture_file_dialog.connect(_on_show_texture_file_dialog);
	EditorSignals.remove_texture.connect(_on_remove_texture);
	
	#var filter : String;
	#for valid_extension: String in wangVALID_EXTENSIONS:
		#filter += "*.%s ;" % valid_extension;
		##filter_extensions.append("*.%s ; %s Images" % [valid_extension, valid_extension.to_upper()]);
	#
	##file_dialog.filters.append(filter);
	#var pattern = "";
	#for i in VALID_EXTENSIONS.size():
		#pattern += VALID_EXTENSIONS[i]
		#if i < VALID_EXTENSIONS.size() - 1:
			#pattern += "|";
	#
	#regex_pattern = ".+\\.(%s)$" % pattern;

func set_tile_size_label(text: String):
	lbl_tile_size.text = text;

func set_tile_set_size_label(text: String):
	lbl_tile_set_size.text = text;

#region event listener
func _on_new_texture():
	_init_form();

func _on_btn_recreate_texture_pressed() -> void:
	wang_creator.create_preview_texture();


func _show_file_dialog(save_mode: bool):
	save_state = save_mode;
	file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE if save_mode else FileDialog.FILE_MODE_OPEN_FILE;
	file_dialog.title = "Save File" if save_mode else "Select File";
	
	if save_mode:
		file_dialog.current_file = "exported_tile_set.png";
	
	file_dialog.show();
	
func _on_export_texture():
	_show_file_dialog(true);
	

func _on_show_texture_file_dialog(texture_type: TileType):
	wang_creator.current_texture_type = texture_type;
	_show_file_dialog(false);
	
func _on_file_dialog_file_selected(path: String) -> void:
	if save_state:
		wang_creator.export_texture(path);
	else:
		wang_creator.import_texture(path);

func _on_remove_texture(texture_type: TileType):
	button_dict[texture_type].texture_normal = orig_icons[texture_type];
	wang_creator.texture_dict[texture_type] = null;
	wang_creator.create_preview_texture();
#endregion


#region helper
func _init_form() -> void:
	lbl_tile_size.text = "";
	lbl_tile_set_size.text = "";
	
	btn_export.disabled = true;
	for key in orig_icons.keys():
		button_dict[key].texture_normal = orig_icons[key];
		
	texture_preview.texture = null;
	wang_creator.texture_dict.clear();
	wang_creator.generated_texture = null;
	wang_creator.tile_width = 0;
	wang_creator.tile_height = 0;
	
#endregion
