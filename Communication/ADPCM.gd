extends RefCounted
## Standard IMA ADPCM, independent 40 ms mono packets at 16 kHz. No native dependency.
const STEPS := [7,8,9,10,11,12,13,14,16,17,19,21,23,25,28,31,34,37,41,45,50,55,60,66,73,80,88,97,107,118,130,143,157,173,190,209,230,253,279,307,337,371,408,449,494,544,598,658,724,796,876,963,1060,1166,1282,1411,1552,1707,1878,2066,2272,2499,2749,3024,3327,3660,4026,4428,4871,5358,5894,6484,7132,7845,8630,9493,10442,11487,12635,13899,15289,16818,18500,20350,22385,24623,27086,29794,32767]
const INDEX := [-1,-1,-1,-1,2,4,6,8]
static func encode(samples: PackedFloat32Array) -> PackedByteArray:
	var count := samples.size()
	if count < 2 or count > 640:
		return PackedByteArray()
	var bytes := PackedByteArray()
	bytes.resize(5 + ceili(float(count - 1) / 2))
	bytes.encode_u16(0, count)
	var prediction := clampi(roundi(samples[0] * 32767), -32768, 32767)
	bytes.encode_s16(2, prediction)
	bytes[4] = 0
	var index := 0
	for i in range(1, count):
		var step: int = STEPS[index]
		var difference := clampi(roundi(samples[i] * 32767), -32768, 32767) - prediction
		var code := 8 if difference < 0 else 0
		difference = absi(difference)
		var change := step >> 3
		for bit in [4, 2, 1]:
			if difference >= step:
				code |= bit
				difference -= step
				change += step
			step >>= 1
		prediction = clampi(prediction + (-change if code & 8 else change), -32768, 32767)
		index = clampi(index + INDEX[code & 7], 0, 88)
		var position := 5 + (i - 1) / 2
		bytes[position] |= code << (4 if (i - 1) % 2 else 0)
	return bytes
static func decode(bytes: PackedByteArray) -> PackedVector2Array:
	if bytes.size() < 6 or bytes.size() > 325:
		return PackedVector2Array()
	var count := bytes.decode_u16(0)
	if count < 2 or count > 640 or bytes.size() != 5 + ceili(float(count - 1) / 2) or bytes[4] > 88:
		return PackedVector2Array()
	var result := PackedVector2Array()
	result.resize(count)
	var prediction := bytes.decode_s16(2)
	var index := int(bytes[4])
	result[0] = Vector2.ONE * (prediction / 32768.0)
	for i in range(1, count):
		var code: int = (bytes[5 + (i - 1) / 2] >> (4 if (i - 1) % 2 else 0)) & 15
		var step: int = STEPS[index]
		var change := (step >> 3) + (step if code & 4 else 0) + ((step >> 1) if code & 2 else 0) + ((step >> 2) if code & 1 else 0)
		prediction = clampi(prediction + (-change if code & 8 else change), -32768, 32767)
		index = clampi(index + INDEX[code & 7], 0, 88)
		result[i] = Vector2.ONE * (prediction / 32768.0)
	return result
