class_name WangCreator extends Control

const TileType = EditorEnums.TileType;
const FillMode = EditorEnums.FillMode;
const ErrorType = EditorEnums.ErrorType;


@onready var ui_controller: UIController = %ui_controller
@onready var error_panel: ErrorPanel = %error_panel

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

const TILE_SET_FACTOR := 4;
const VALID_EXTENSIONS := [
	"png",
	"jpg",
	"webp"
];

var regex_pattern;
var texture_dict := {}; #[TileType]: Texture2D;
var generated_texture: ImageTexture;
var current_texture: Texture2D;
var current_texture_type: TileType;

var tile_size := 0;
var max_size := tile_size * TILE_SET_FACTOR;

func _ready() -> void:
	var pattern = "";
	for i in VALID_EXTENSIONS.size():
		pattern += VALID_EXTENSIONS[i]
		if i < VALID_EXTENSIONS.size() - 1:
			pattern += "|";
	
	regex_pattern = ".+\\.(%s)$" % pattern;


func import_texture(path):
	var img = Image.load_from_file(path);
	if img.detect_alpha() == Image.AlphaMode.ALPHA_NONE:
		img.convert(Image.FORMAT_RGBA8);
		img.clear_mipmaps();
		
	var texture = ImageTexture.create_from_image(img);
	
	var texture_size := texture.get_size();
	ui_controller.set_tile_size_label("Calculated Tile Size: %s" % texture_size);
	ui_controller.set_tile_set_size_label("Calculated TileSet Size: %s" % (texture_size * TILE_SET_FACTOR));

	texture_dict[current_texture_type] = texture;
	ui_controller.button_dict[current_texture_type].texture_normal = texture;
	
	create_preview_texture();
	
	ui_controller.btn_export.disabled = texture_dict.size() < 1;


func create_preview_texture():
	var original := _get_current_texture() as ImageTexture;
	
	if original == null:
		ui_controller.texture_preview.texture = null;
		_check_textures();
		return;
	
	if original.get_width() != original.get_height():
		error_panel.set_message(ErrorType.SIZE_NOT_EQUAL);
		error_panel.show();
		return;
	
	if tile_size == 0:
		tile_size = original.get_width();

		
	if tile_size != 0 and original.get_width() != tile_size:
		error_panel.set_message(ErrorType.DIFFER_SIZES_AMONG_FILES);
		error_panel.show();
		return;
		
	if tile_size != 0 and original.get_height() != tile_size:
		error_panel.set_message(ErrorType.DIFFER_SIZES_AMONG_FILES);
		error_panel.show();
		return;
	
	
	var preview_image := Image.create(tile_size * TILE_SET_FACTOR, tile_size * TILE_SET_FACTOR, false, Image.FORMAT_RGBA8);
	if texture_dict.has(TileType.UNDERLAY_FILL) \
	and texture_dict[TileType.UNDERLAY_FILL] != null:
		preview_image = _generate_fill_texture(FillMode.UNDERLAY, preview_image, texture_dict[TileType.UNDERLAY_FILL].get_image());

	preview_image = _generate_border_tiles(preview_image);
	
	if texture_dict.has(TileType.OVERLAY_FILL) \
	and texture_dict[TileType.OVERLAY_FILL] != null:
		preview_image = _generate_fill_texture(FillMode.OVERLAY, preview_image, texture_dict[TileType.OVERLAY_FILL].get_image());
	var preview_texture := ImageTexture.create_from_image(preview_image);

	ui_controller.texture_preview.texture = preview_texture;
	generated_texture = preview_texture;

func _generate_border_tiles(preview_image: Image) -> Image:
	for tile_type: TileType in texture_dict.keys():
		var texture := _get_texture(tile_type) as ImageTexture;
		if texture == null:
			continue;
		
		for tile_pos: Vector2i in placement_dict[tile_type].keys():
			var rotated_image := texture.get_image();
			var rotations := placement_dict[tile_type][tile_pos] as int;

			#it doesn't work with looping.
			match(rotations):
				0:
					pass;
					
				1:
					rotated_image.rotate_90(CLOCKWISE);
					
				2: 
					rotated_image.rotate_90(CLOCKWISE);
					rotated_image.rotate_90(CLOCKWISE);
					
				3:
					rotated_image.rotate_90(COUNTERCLOCKWISE);
			
			var start_pos_x := tile_pos.x * tile_size;
			var max_range_x := start_pos_x + tile_size;
			
			var start_pos_y := tile_pos.y * tile_size;
			var max_range_y := start_pos_y + tile_size;
			for x  in range(start_pos_x, max_range_x ):
				for y in range(start_pos_y, max_range_y):
					var source_pixel = rotated_image.get_pixel(x % tile_size, y % tile_size);
					if source_pixel.a != 0:
						var base_pixel := preview_image.get_pixel(x, y);
						var mixed_pixel := _mix_colors(base_pixel, source_pixel);
						preview_image.set_pixel(x,y, mixed_pixel);
	
	return preview_image;



func _generate_fill_texture(fill_mode: FillMode , target_image: Image, source_image: Image) -> Image:
	
	
	for y in max_size:
		for x in max_size:
			var source_pos_x := x % tile_size as int;
			var source_pos_y := y % tile_size as int;
			var target_color := target_image.get_pixel(x, y);
			var source_pixel := source_image.get_pixel(source_pos_x, source_pos_y);
			
			match fill_mode:
				FillMode.UNDERLAY:
					target_image.set_pixel(x, y, source_pixel);
				
				FillMode.OVERLAY:
					if _is_near_white(target_color, ui_controller.spinbox_white_tolerance.value):
						var mixed_pixel := _mix_colors(target_color, source_pixel);
						target_image.set_pixel(x,y, mixed_pixel);

	return target_image;


func export_texture(path: String):
	var image := generated_texture.get_image();
	if !_has_valid_extension(path):
		image.save_png(path + ".png");
		return;
	
	var split := path.split(".");
	var ending := split[split.size() - 1];
	match ending:
		"webp":
			image.save_webp(path, false, 1);
		"jpg":
			image.save_jpg(path, 1);
		_:
			image.save_png(path);


#region helper
func _get_current_texture():
	return _get_texture(current_texture_type);

func _get_texture(tile_type: TileType):
	if texture_dict.has(tile_type):
		return texture_dict[tile_type];


func _mix_colors(base_color: Color, overlay_color: Color) -> Color:
	var alpha_overlay := overlay_color.a;
	var alpha_base := base_color.a * (1.0 - alpha_overlay);
	var final_alpha := alpha_overlay + alpha_base;
	var final_color := overlay_color * alpha_overlay + base_color * alpha_base;
	
	if final_alpha > 0:
		final_color /= final_alpha;
	
	final_color.a = final_alpha;
	return final_color;


func _is_near_white(color: Color, tolerance: float) -> bool:
	return abs(color.r - 1.0) <= tolerance  \
		and abs(color.g - 1.0) <= tolerance \
		and abs(color.b - 1.0) <= tolerance \
		and color.a == 1.0


func _check_textures():
	for key: TileType in texture_dict.keys():
		var curr_texture := texture_dict[key] as ImageTexture;
		if curr_texture != null:
			tile_size = current_texture.get_width();
			current_texture_type = key;
			create_preview_texture();
			return;


func _has_valid_extension(file_name: String) -> bool:
	var regex := RegEx.new();
	var error := regex.compile(regex_pattern);
	if error != OK:
		return false;
		
	return regex.search(file_name.to_lower()) != null;
#endregion
