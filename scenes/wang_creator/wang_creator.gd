class_name WangCreator extends Control

const TileType = EditorEnums.TileType;
const FillMode = EditorEnums.FillMode;
const ErrorType = EditorEnums.ErrorType;
const ProgessBarType = EditorEnums.ProgressBarType;
const TILE_SET_FACTOR := 4;
const VALID_EXTENSIONS := [
	"png",
	"jpg",
	"webp"
];

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

var regex_pattern;
var texture_dict := {}; #[TileType]: Texture2D;
var generated_texture: ImageTexture;
var current_texture: Texture2D;
var current_texture_type: TileType;
var tile_size := 0;


func _ready() -> void:
	var pattern = "";
	for i in VALID_EXTENSIONS.size():
		pattern += VALID_EXTENSIONS[i]
		if i < VALID_EXTENSIONS.size() - 1:
			pattern += "|";
	
	regex_pattern = ".+\\.(%s)$" % pattern;


#region texture generation and export

func import_texture(path) -> void:
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
	
	ui_controller.toggle_preview_texture(true);
	ui_controller.toggle_export_button(texture_dict.size() < 1);


func create_preview_texture() -> void:
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
		set_tile_size(original.get_width());

		
	if tile_size != 0 and original.get_width() != tile_size \
	or tile_size != 0 and original.get_height() != tile_size:
		error_panel.set_message(ErrorType.DIFFER_SIZES_AMONG_FILES);
		error_panel.show();
		return;
	
	ui_controller.init_all_progress_bars();
	
	var preview_image := Image.create(tile_size * TILE_SET_FACTOR, tile_size * TILE_SET_FACTOR, false, Image.FORMAT_RGBA8);
	if !!texture_dict.get(TileType.UNDERLAY_FILL):
		preview_image = await _generate_fill_texture(FillMode.UNDERLAY, preview_image, texture_dict[TileType.UNDERLAY_FILL].get_image());
	else:
		ui_controller.set_progress_bar_value(ProgessBarType.UNDERLAY, 100);
	
	preview_image = await _generate_border_tiles(preview_image);
	
	if !!texture_dict.get(TileType.OVERLAY_FILL):
		preview_image = await _generate_fill_texture(FillMode.OVERLAY, preview_image, texture_dict[TileType.OVERLAY_FILL].get_image());
	else:
		ui_controller.set_progress_bar_value(ProgessBarType.OVERLAY, 100);

		
	var preview_texture := ImageTexture.create_from_image(preview_image);

	ui_controller.set_preview_texture(preview_texture);
	set_generated_texture(preview_texture);
	ui_controller.toggle_preview_texture(false);


func _generate_border_tiles(preview_image: Image) -> Image:
	var step := 0;
	var step_size := floori(texture_dict.size() / 100);
	ui_controller.init_progress_bar(ProgessBarType.BORDER);
	
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
		
			step += step_size;
			ui_controller.set_progress_bar_value(ProgessBarType.BORDER, step);
			await get_tree().process_frame
	
	
	ui_controller.set_progress_bar_value(ProgessBarType.BORDER, 100);
	return preview_image;


func _generate_fill_texture(fill_mode: FillMode , target_image: Image, source_image: Image) -> Image:
	var max_size := tile_size * TILE_SET_FACTOR
	
	var step:= 0;
	var update_frequency := floori(max_size / 50);  
	var pb_type := ProgessBarType.UNDERLAY if fill_mode == FillMode.UNDERLAY else ProgessBarType.OVERLAY;
	ui_controller.init_progress_bar(pb_type);
	
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
		step += 1;
		
		ui_controller.set_progress_bar_value(pb_type, floori((step / max_size) * 100))
		
		if step % update_frequency == 0:
			await get_tree().process_frame;
	
	return target_image;


func export_texture(path: String) -> void:
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

#endregion

#region get/set properties

func remove_tile_from_texture_dict(type: TileType) -> void:
	texture_dict[type] = null;
	texture_dict.erase(type);


func get_texture_dict_count() -> int:
	return texture_dict.size();


func set_current_texture_type(type: TileType) -> void:
	current_texture_type = type;


func set_tile_size(value: int) -> void:
	tile_size = value;


func set_generated_texture(texture: Texture2D) -> void:
	generated_texture = texture;


func reset_texture_data():
	generated_texture = null;
	tile_size = 0;
	texture_dict.clear();

#endregion

#region helper

func _get_current_texture() -> ImageTexture:
	return _get_texture(current_texture_type);


func _get_texture(tile_type: TileType) -> ImageTexture:
	return texture_dict.get(tile_type);


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


func _check_textures() -> void:
	for key: TileType in texture_dict.keys():
		var curr_texture := texture_dict[key] as ImageTexture;
		if curr_texture != null:
			var img := texture_dict[key].get_image() as Image;
			tile_size = img.get_width();
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
