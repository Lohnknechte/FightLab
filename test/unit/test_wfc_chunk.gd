extends GutTest
## Unit tests for wfc_chunk.gd.
##
## Adjacency is derived from the drawn pattern, so socket extraction and
## mirroring are what keep the generated levels seamless.

var _chunk: WFCChunk


func before_each() -> void:
	_chunk = WFCChunk.new()
	_chunk.id = &"ledge"
	_chunk.pattern = "....\n.GGG\n.DDD\n...."


func test_rows_ignore_blank_lines_and_indentation() -> void:
	_chunk.pattern = "\n\t....\n  GGGG  \n\nDDDD\n....\n"

	assert_eq(_chunk.get_rows(), PackedStringArray(["....", "GGGG", "DDDD", "...."]))


func test_size_matches_a_square_pattern() -> void:
	assert_eq(_chunk.get_size(), 4)
	assert_true(_chunk.is_valid(4))


func test_non_square_pattern_is_rejected() -> void:
	_chunk.pattern = "...\nGGG"

	assert_eq(_chunk.get_size(), 0)
	assert_false(_chunk.is_valid(4))


func test_sockets_read_along_each_edge() -> void:
	var rows := _chunk.get_rows()

	assert_eq(WFCChunk.build_socket(rows, WFCChunk.Side.NORTH), "....")
	assert_eq(WFCChunk.build_socket(rows, WFCChunk.Side.SOUTH), "....")
	assert_eq(WFCChunk.build_socket(rows, WFCChunk.Side.WEST), "....")
	assert_eq(WFCChunk.build_socket(rows, WFCChunk.Side.EAST), ".GD.")


func test_mirroring_swaps_the_horizontal_sockets() -> void:
	var mirrored := WFCChunk.mirror_rows(_chunk.get_rows())

	assert_eq(WFCChunk.build_socket(mirrored, WFCChunk.Side.WEST), ".GD.")
	assert_eq(WFCChunk.build_socket(mirrored, WFCChunk.Side.EAST), "....")


func test_mirroring_reverses_the_vertical_sockets() -> void:
	_chunk.pattern = "GG..\n....\n....\n..DD"

	var mirrored := WFCChunk.mirror_rows(_chunk.get_rows())

	assert_eq(WFCChunk.build_socket(mirrored, WFCChunk.Side.NORTH), "..GG")
	assert_eq(WFCChunk.build_socket(mirrored, WFCChunk.Side.SOUTH), "DD..")


func test_socket_emptiness() -> void:
	assert_true(WFCChunk.is_socket_empty("...."))
	assert_false(WFCChunk.is_socket_empty("..G."))
