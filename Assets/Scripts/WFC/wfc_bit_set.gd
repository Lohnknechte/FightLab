class_name WFCBitSet
extends RefCounted
## Fixed-size bit set backed by a [PackedInt32Array] of 31 bit words.
##
## The Wave Function Collapse solver keeps one of these per grid cell to track
## which chunk variants are still possible. Packed arrays are passed by
## reference in Godot, so every mutating helper edits [param bits] in place and
## reports whether anything actually changed - that flag is what drives the
## propagation queue.

## Only 31 bits per word are used so a shifted mask never reaches the sign bit
## of the int32 slots backing [PackedInt32Array].
const WORD_BITS := 31


static func word_count(bit_count: int) -> int:
	return int(ceil(float(bit_count) / float(WORD_BITS)))


## Returns a set with the lowest [param bit_count] bits enabled.
static func create_full(bit_count: int) -> PackedInt32Array:
	var bits := PackedInt32Array()
	bits.resize(word_count(bit_count))
	bits.fill(0)
	for index in bit_count:
		enable(bits, index)
	return bits


static func create_empty(bit_count: int) -> PackedInt32Array:
	var bits := PackedInt32Array()
	bits.resize(word_count(bit_count))
	bits.fill(0)
	return bits


static func has(bits: PackedInt32Array, index: int) -> bool:
	var word := index / WORD_BITS
	if word < 0 or word >= bits.size():
		return false
	return (bits[word] & (1 << (index % WORD_BITS))) != 0


## Enables a bit. Returns [code]true[/code] when the bit was previously unset.
static func enable(bits: PackedInt32Array, index: int) -> bool:
	var word := index / WORD_BITS
	var mask := 1 << (index % WORD_BITS)
	if (bits[word] & mask) != 0:
		return false
	bits[word] |= mask
	return true


## Disables a bit. Returns [code]true[/code] when the bit was previously set.
static func disable(bits: PackedInt32Array, index: int) -> bool:
	var word := index / WORD_BITS
	var mask := 1 << (index % WORD_BITS)
	if (bits[word] & mask) == 0:
		return false
	bits[word] &= ~mask
	return true


## Keeps only the bits that are also present in [param mask].
## Returns [code]true[/code] when [param bits] shrank.
static func intersect(bits: PackedInt32Array, mask: PackedInt32Array) -> bool:
	var changed := false
	for word in bits.size():
		var merged: int = bits[word] & mask[word]
		if merged != bits[word]:
			bits[word] = merged
			changed = true
	return changed


## Adds every bit of [param other] to [param bits].
static func unite(bits: PackedInt32Array, other: PackedInt32Array) -> void:
	for word in bits.size():
		bits[word] |= other[word]


static func is_empty(bits: PackedInt32Array) -> bool:
	for word in bits.size():
		if bits[word] != 0:
			return false
	return true


static func count(bits: PackedInt32Array) -> int:
	var total := 0
	for word in bits.size():
		var value: int = bits[word]
		while value != 0:
			value &= value - 1
			total += 1
	return total


## Index of the lowest enabled bit, or [code]-1[/code] for an empty set.
static func first(bits: PackedInt32Array) -> int:
	for word in bits.size():
		if bits[word] == 0:
			continue
		for bit in WORD_BITS:
			if (bits[word] & (1 << bit)) != 0:
				return word * WORD_BITS + bit
	return -1


static func to_indices(bits: PackedInt32Array) -> PackedInt32Array:
	var indices := PackedInt32Array()
	for word in bits.size():
		if bits[word] == 0:
			continue
		for bit in WORD_BITS:
			if (bits[word] & (1 << bit)) != 0:
				indices.append(word * WORD_BITS + bit)
	return indices
