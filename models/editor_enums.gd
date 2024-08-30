class_name EditorEnums

enum TileType {
	BORDER,
	INNER_CORNER,
	OUTER_CORNER,
	EDGE_CONNECTOR,
	OVERLAY_FILL,
	UNDERLAY_FILL
}


enum FillMode { 
	UNDERLAY, 
	OVERLAY
};


enum ErrorType {
	SIZE_NOT_EQUAL,
	DIFFER_SIZES_AMONG_FILES
}


enum ProgressBarType {
	UNDERLAY,
	BORDER,
	OVERLAY,
	TOTAL
}
