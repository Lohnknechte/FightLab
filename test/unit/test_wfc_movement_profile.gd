extends GutTest
## Unit tests for wfc_movement_profile.gd.
##
## The defaults must keep matching character.gd, because every reachability
## decision in the generator is derived from them. With a 500 px/s jump against
## 980 px/s^2 gravity a jump peaks at just under 128 px - half a pixel short of
## four tiles - so a four tile climb is genuinely impossible and the generator
## has to know that.

var _profile: WFCMovementProfile


func before_each() -> void:
	_profile = WFCMovementProfile.new()


func test_defaults_match_the_character() -> void:
	assert_eq(_profile.move_speed, 200.0)
	assert_eq(_profile.jump_velocity, 500.0)
	assert_eq(_profile.gravity, 980.0)
	assert_eq(_profile.tile_size, 32)


func test_peak_height_falls_just_short_of_four_tiles() -> void:
	assert_almost_eq(_profile.get_peak_height(), 127.55, 0.01)
	assert_lt(_profile.get_peak_height(), 4.0 * _profile.tile_size)


func test_max_rise_is_three_tiles() -> void:
	assert_eq(_profile.get_max_rise_tiles(), 3)


func test_a_four_tile_climb_is_rejected() -> void:
	assert_true(_profile.can_traverse(Vector2i(1, -3)), "three tiles up is fine")
	assert_false(_profile.can_traverse(Vector2i(1, -4)), "four tiles up is not")


func test_reach_shrinks_as_the_jump_climbs() -> void:
	var flat := _profile.get_reach(0.0)
	var climbing := _profile.get_reach(-3.0 * _profile.tile_size)
	var falling := _profile.get_reach(4.0 * _profile.tile_size)

	assert_gt(flat, climbing, "climbing costs horizontal distance")
	assert_gt(falling, flat, "falling buys horizontal distance")


func test_a_step_that_is_too_wide_is_rejected() -> void:
	assert_true(_profile.can_traverse(Vector2i(5, 0)))
	assert_false(_profile.can_traverse(Vector2i(8, 0)))


func test_standing_still_is_not_a_step() -> void:
	assert_false(_profile.can_traverse(Vector2i.ZERO))


func test_a_slower_character_cannot_cross_as_much() -> void:
	_profile.move_speed = 80.0

	assert_false(_profile.can_traverse(Vector2i(5, 0)))


func test_the_safety_margin_tightens_the_limits() -> void:
	_profile.safety_margin = 1.0
	var generous := _profile.get_reach(0.0)
	_profile.safety_margin = 0.5

	assert_lt(_profile.get_reach(0.0), generous)
	assert_eq(_profile.get_max_rise_tiles(), 1)
