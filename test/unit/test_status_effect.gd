extends GutTest
## Unit tests for the StatusEffect base resource
## (Assets/Scripts/Status_effects/StatusEffect.gd)


func test_max_stacks_defaults_to_one() -> void:
	var effect := StatusEffect.new()
	assert_eq(effect.max_stacks, 1)
