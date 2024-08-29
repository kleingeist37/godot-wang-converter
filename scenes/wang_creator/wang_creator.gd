class_name WangConverter extends Control

enum TileType {
	BORDER,
	INNER_CORNER,
	OUTER_CORNER,
	EDGE_CONNECTOR,
	OVERLAY_FILL,
	UNDERLAY_FILL
}

@onready var file_dialog: FileDialog = $file_dialog;
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



var orig_icons := {
	TileType.BORDER: preload("res://sprites/icon_border.png") as Texture2D,
	TileType.INNER_CORNER: preload("res://sprites/icon_inner_corner.png") as Texture2D,
	TileType.OUTER_CORNER: preload("res://sprites/icon_outer_corner.png") as Texture2D,
	TileType.OVERLAY_FILL: preload("res://sprites/icon_fill.png") as Texture2D,
	TileType.EDGE_CONNECTOR: preload("res://sprites/icon_edge_connector.png") as Texture2D,
	TileType.UNDERLAY_FILL: preload("res://sprites/icon_underlay_fill.png") as Texture2D
};


var placement_dict := {
	TileType.BORDER: {
		Vector2i(1, 0): 0,
		Vector2i(3, 0): 1,
		Vector2i(1, 2): 3,
		Vector2i(3, 2): 2
	},
	TileType.INNER_CORNER: {
		Vector2i(2, 0): 1,
		Vector2i(1, 1): 0,
		Vector2i(3, 1): 2,
		Vector2i(2, 2): 3
	},
	TileType.OUTER_CORNER: {
		Vector2i(0, 0): 0,
		Vector2i(0, 2): 2,
		Vector2i(3, 3): 1,
		Vector2i(1, 3): 3,
	},
	TileType.EDGE_CONNECTOR: {
		Vector2i(0, 1): 0,
		Vector2i(2, 3): 3
	},
	TileType.OVERLAY_FILL: {
		Vector2i(2, 1): 0
	},
	TileType.UNDERLAY_FILL: {
		Vector2i(0, 3): 0
	}
};

const VALID_EXTENSIONS := [
	"png",
	"jpg",
	"webp"
];

var filter_extensions: PackedStringArray;
var regex_pattern;
var save_state := false; 
var current_texture_type: TileType;
var texture_dict := {}; #[TileType]: Texture2D;
var button_dict := {}; #[TileType]: TileTypeButton;
var generated_texture: ImageTexture;
var current_texture: Texture2D;


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
	_init_form();
	
	for valid_extension: String in VALID_EXTENSIONS:
		filter_extensions.append("*.%s ; %s Images" % [valid_extension, valid_extension.to_upper()]);
		
	var pattern = "";
	for i in VALID_EXTENSIONS.size():
		pattern += VALID_EXTENSIONS[i]
		if i < VALID_EXTENSIONS.size() - 1:
			pattern += "|";
	
	regex_pattern = ".+\\.(%s)$" % pattern;
	file_dialog.filters = filter_extensions;


func _import_texture(path):
	var img = Image.load_from_file(path);
	if img.detect_alpha() == Image.AlphaMode.ALPHA_NONE:
		img.convert(Image.FORMAT_RGBA8);
		img.clear_mipmaps();
		
	var texture = ImageTexture.create_from_image(img);
	
	var texture_size := texture.get_size();
	lbl_tile_size.text = "Calculated Tile Size: %s" % texture_size;
	lbl_tile_set_size.text = "Calculated TileSet Size: %s" % (texture_size * 4);
	texture_dict[current_texture_type] = texture;
	button_dict[current_texture_type].texture_normal = texture;
	
	_create_preview_texture();
	
	btn_export.disabled = texture_dict.size() < 1;



func _create_preview_texture():
	var original := _get_current_texture() as ImageTexture;
	var width := original.get_width();
	var height := original.get_height();
	var preview_image := Image.create(width * 4, height * 4, false, Image.FORMAT_RGBA8);
	if texture_dict.has(TileType.UNDERLAY_FILL) \
	&& texture_dict[TileType.UNDERLAY_FILL] != null:
		preview_image = generate_fill_texture(FillMode.UNDERLAY, preview_image, texture_dict[TileType.UNDERLAY_FILL].get_image(), width, height, 4);

	preview_image = generate_border_tiles(preview_image);
	
	if texture_dict.has(TileType.OVERLAY_FILL) \
	&& texture_dict[TileType.OVERLAY_FILL] != null:
		preview_image = generate_fill_texture(FillMode.OVERLAY, preview_image, texture_dict[TileType.OVERLAY_FILL].get_image(), width, height, 4);
	var preview_texture = ImageTexture.create_from_image(preview_image);

	texture_preview.texture = preview_texture;
	generated_texture = preview_texture;

func generate_border_tiles(preview_image: Image) -> Image:
	for tile_type: TileType in texture_dict.keys():
		var texture = _get_texture(tile_type) as ImageTexture;
		if texture == null:
			continue;
		
		for tile_pos: Vector2i in placement_dict[tile_type].keys():
			var rotator := texture.get_image();
			var rotations := placement_dict[tile_type][tile_pos] as int;

			#it doesn't fucking work with looping.
			match(rotations):
				0:
					pass;
				1:
					rotator.rotate_90(CLOCKWISE);

				2: 
					rotator.rotate_90(CLOCKWISE);
					rotator.rotate_90(CLOCKWISE);

				3:
					rotator.rotate_90(COUNTERCLOCKWISE);
				
			var start_pos_x := tile_pos.x * rotator.get_width();
			var max_range_x := start_pos_x + rotator.get_width();
			
			var start_pos_y := tile_pos.y * rotator.get_height();
			var max_range_y := start_pos_y + rotator.get_height();
			for x  in range(start_pos_x, max_range_x ):
				for y in range(start_pos_y, max_range_y):
					var source_pixel = rotator.get_pixel(x % rotator.get_width(), y % rotator.get_height());
					if source_pixel.a != 0:
						preview_image.set_pixel(x,y, source_pixel);

			
	return preview_image;


enum FillMode { UNDERLAY, OVERLAY};
func generate_fill_texture(fill_mode: FillMode , target_image: Image, source_image: Image, tile_width: int, tile_height: int, factor: int = 4) -> Image:
	
	var counter = 0;
	var target_width = tile_width * factor
	var target_height = tile_height * factor
			
	
	for y in target_height:
		for x in target_width:
			var pos_x := x % tile_width as int;
			var pos_y := y % tile_height as int;
			var target_color = target_image.get_pixel(x, y);
			var source_pixel := source_image.get_pixel(pos_x, pos_y);
			
			match fill_mode:
				FillMode.UNDERLAY:
					target_image.set_pixel(x, y, source_pixel);
				
				FillMode.OVERLAY:
					if target_color == Color(1, 1, 1, 1):
						target_image.set_pixel(x, y, source_pixel);

		counter += 1;
	return target_image;
		

#func generate_border_tiles(preview_image: Image, width: int, height: int) -> Image:
	#for tile_type: TileType in texture_dict.keys():
		#var texture = _get_texture(tile_type) as ImageTexture;
		#if texture == null:
			#continue;
		#
		#for tile_pos: Vector2i in placement_dict[tile_type].keys():
			#var rotator := texture.get_image();
			#var rotations := placement_dict[tile_type][tile_pos] as int;
#
			##it doesn't fucking work with looping.
			#match(rotations):
				#0:
					#pass;
				#1:
					#rotator.rotate_90(CLOCKWISE);
#
				#2: 
					#rotator.rotate_90(CLOCKWISE);
					#rotator.rotate_90(CLOCKWISE);
#
				#3:
					#rotator.rotate_90(COUNTERCLOCKWISE);
#
			#preview_image.blit_rect(rotator, Rect2i(0,0, width, height), tile_pos * width)
		#
	#return preview_image;
	

func _export_texture(path: String):
	var image = generated_texture.get_image();
	if !_has_valid_extension(path):
		image.save_png(path);
		return;
	
	var split = path.split(".");
	var ending = split[split.size() - 1];
	match ending:
		"webp":
			image.save_webp(path, false, 1);
		"jpg":
			image.save_jpg(path, 1);
		_:
			image.save_png(path);


#region event listener

func _on_new_texture():
	_init_form();


func _on_export_texture():
	_show_file_dialog(true);
	

func _on_show_texture_file_dialog(texture_type: TileType):
	current_texture_type = texture_type;
	_show_file_dialog(false);	
	

func _show_file_dialog(save_mode: bool):
	save_state = save_mode;
	file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE if save_mode else FileDialog.FILE_MODE_OPEN_FILE;
	file_dialog.title = "Save File" if save_mode else "Select File";
	
	if save_mode:
		file_dialog.current_file = "exported_tile_set.png";
	
	file_dialog.show();


func _on_file_dialog_file_selected(path: String) -> void:
	if save_state:
		_export_texture(path);
	else:
		_import_texture(path);
		
#endregion


#region helper
func _init_form() -> void:
	lbl_tile_size.text = "";
	lbl_tile_set_size.text = "";
	texture_dict.clear();
	btn_export.disabled = true;
	for key in orig_icons.keys():
		button_dict[key].texture_normal = orig_icons[key];
		
	texture_preview.texture = null;
	generated_texture = null;


func _get_current_texture():
	return _get_texture(current_texture_type);

func _get_texture(tile_type: TileType):
	if texture_dict.has(tile_type):
		return texture_dict[tile_type];


func _has_valid_extension(file_name: String) -> bool:
	var regex = RegEx.new();
	var error = regex.compile(regex_pattern);
	if error != OK:
		return false;
		
	return regex.search(file_name.to_lower()) != null;
#endregion
