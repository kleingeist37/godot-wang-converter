class_name UIController extends Control

const TileType = EditorEnums.TileType;
const ProgressBarType = EditorEnums.ProgressBarType;

@onready var wang_creator: WangCreator = $"..";
@onready var file_dialog: FileDialog = %file_dialog;
@onready var tile_type_button_outer_corner: TextureButton = %tile_type_button_outer_corner;
@onready var tile_type_button_edge_connector: TextureButton = %tile_type_button_edge_connector;
@onready var tile_type_button_inner_corner: TextureButton = %tile_type_button_inner_corner;
@onready var tile_type_button_border: TextureButton = %tile_type_button_border;
@onready var tile_type_button_overlay_fill: TextureButton = %tile_type_button_overlay_fill;
@onready var tile_type_button_underlay_fill: TextureButton = %tile_type_button_underlay_fill;
@onready var lbl_tile_size: Label = %lbl_tile_size;
@onready var lbl_tile_set_size: Label = %lbl_tile_set_size;
@onready var btn_export: Button = %btn_export;
@onready var texture_preview: TextureRect = %texture_preview;
@onready var spinbox_white_tolerance: SpinBox = %spinbox_white_tolerance;
@onready var error_panel: ErrorPanel = %error_panel;

@onready var progress_bar_underlay: ProgressBar = %progress_bar_underlay;
@onready var progress_bar_border: ProgressBar = %progress_bar_border;
@onready var progress_bar_overlay: ProgressBar = %progress_bar_overlay;

@onready var sc_preview_texture: ScrollContainer = %sc_preview_texture
@onready var lbl_loading: Label = %lbl_loading


var orig_icons := {
	TileType.BORDER: preload("res://sprites/icon_border.png") as Texture2D,
	TileType.INNER_CORNER: preload("res://sprites/icon_inner_corner.png") as Texture2D,
	TileType.OUTER_CORNER: preload("res://sprites/icon_outer_corner.png") as Texture2D,
	TileType.OVERLAY_FILL: preload("res://sprites/icon_fill.png") as Texture2D,
	TileType.EDGE_CONNECTOR: preload("res://sprites/icon_edge_connector.png") as Texture2D,
	TileType.UNDERLAY_FILL: preload("res://sprites/icon_underlay_fill.png") as Texture2D
};

var filter_extensions: PackedStringArray;
var save_state := false; 
var button_dict := {}; #[TileType]: TileTypeButton;
var _progress_bars := {};

func _ready() -> void:
	button_dict[TileType.BORDER] = tile_type_button_border;
	button_dict[TileType.INNER_CORNER] = tile_type_button_inner_corner;
	button_dict[TileType.OUTER_CORNER] = tile_type_button_outer_corner;
	button_dict[TileType.OVERLAY_FILL] = tile_type_button_overlay_fill;
	button_dict[TileType.UNDERLAY_FILL] = tile_type_button_underlay_fill;
	button_dict[TileType.EDGE_CONNECTOR] = tile_type_button_edge_connector;
	
	_progress_bars[ProgressBarType.UNDERLAY] = progress_bar_underlay;
	_progress_bars[ProgressBarType.OVERLAY] = progress_bar_overlay;
	_progress_bars[ProgressBarType.BORDER] = progress_bar_border;
	
	EditorSignals.export_texture.connect(_on_export_texture);
	EditorSignals.new_texture.connect(_on_new_texture);
	EditorSignals.show_texture_file_dialog.connect(_on_show_texture_file_dialog);
	EditorSignals.remove_texture.connect(_on_remove_texture);
	error_panel.hidden.connect(_on_error_panel_hidden);
	
	_init_form();


#region set properties

func set_tile_size_label(text: String) -> void:
	lbl_tile_size.text = text;


func set_tile_set_size_label(text: String) -> void:
	lbl_tile_set_size.text = text;


func toggle_export_button(disabled: bool) -> void:
	btn_export.disabled = disabled;


func set_preview_texture(texture: Texture2D) -> void:
	texture_preview.texture = texture;


func init_progress_bar(type: ProgressBarType) -> void:
	var pb := _progress_bars.get(type) as ProgressBar;
	
	if pb == null:
		return;
	
	pb.max_value = 100;
	pb.min_value = 0;
	pb.value = 0;


func set_progress_bar_value(type: ProgressBarType, value: int) -> void:
	_progress_bars[type].value = value;


func init_all_progress_bars() -> void:
	for pb_key in _progress_bars.keys():
		init_progress_bar(pb_key);


func toggle_preview_texture(show_loading_text: bool) -> void:
	lbl_loading.visible = show_loading_text;
	sc_preview_texture.visible = !show_loading_text;
	
#endregion

#region event listener

func _on_new_texture() -> void:
	_init_form();


func _on_error_panel_hidden() -> void:
	EditorSignals.new_texture.emit();


func _on_btn_recreate_texture_pressed() -> void:
	wang_creator.create_preview_texture();


func _show_file_dialog(save_mode: bool) -> void:
	save_state = save_mode;
	file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE if save_mode else FileDialog.FILE_MODE_OPEN_FILE;
	file_dialog.title = "Save File" if save_mode else "Select File";
	
	if save_mode:
		file_dialog.current_file = "exported_tile_set.png";
	
	file_dialog.show();


func _on_export_texture() -> void:
	_show_file_dialog(true);
	

func _on_show_texture_file_dialog(texture_type: TileType) -> void:
	wang_creator.set_current_texture_type(texture_type);
	_show_file_dialog(false);


func _on_file_dialog_file_selected(path: String) -> void:
	if save_state:
		wang_creator.export_texture(path);
	else:
		wang_creator.import_texture(path);


func _on_remove_texture(texture_type: TileType) -> void:
	button_dict[texture_type].texture_normal = orig_icons[texture_type];
	wang_creator.remove_tile_from_texture_dict(texture_type);
	wang_creator.create_preview_texture();
	toggle_export_button(wang_creator.get_texture_dict_count() < 1);
	
#endregion


#region helper
func _init_form() -> void:
	set_tile_size_label("");
	set_tile_set_size_label("");
	
	toggle_export_button(true);
	for key in orig_icons.keys():
		button_dict[key].texture_normal = orig_icons[key];
	
	set_preview_texture(null);
	wang_creator.reset_texture_data();
	
	init_all_progress_bars();
	
#endregion
