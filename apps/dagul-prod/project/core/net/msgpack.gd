extends RefCounted
## MsgPack 인코더/디코더 — Colyseus 0.18 room.send/onMessage 서브셋.
## 지원 타입: nil, bool, int(+/-), float32/64, string, array, map, bin.
## Colyseus 바이너리 프레임:
##   클라→서버: [ROOM_DATA(13), msgpack(type_string), msgpack(payload)]
##   서버→클라: [protocol_code, ...payload_bytes]

const ROOM_DATA := 13
const ROOM_DATA_BYTES := 17
const ROOM_STATE := 14
const ROOM_STATE_PATCH := 15
const JOIN_ROOM := 10
const ERROR := 11
const LEAVE_ROOM := 12

# ── encode ──────────────────────────────────────────────────────

static func encode(value: Variant) -> PackedByteArray:
	var buf := PackedByteArray()
	_encode_value(buf, value)
	return buf

static func _encode_value(buf: PackedByteArray, value: Variant) -> void:
	if value == null:
		buf.append(0xc0)
		return
	match typeof(value):
		TYPE_BOOL:
			buf.append(0xc3 if bool(value) else 0xc2)
		TYPE_INT:
			_encode_int(buf, int(value))
		TYPE_FLOAT:
			_encode_float64(buf, float(value))
		TYPE_STRING:
			_encode_string(buf, str(value))
		TYPE_DICTIONARY:
			_encode_map(buf, value as Dictionary)
		TYPE_ARRAY:
			_encode_array(buf, value as Array)
		TYPE_PACKED_BYTE_ARRAY:
			_encode_bin(buf, value as PackedByteArray)
		_:
			_encode_string(buf, str(value))

static func _encode_int(buf: PackedByteArray, v: int) -> void:
	if v >= 0:
		if v < 0x80:
			buf.append(v)
		elif v <= 0xff:
			buf.append(0xcc)
			buf.append(v)
		elif v <= 0xffff:
			buf.append(0xcd)
			buf.append((v >> 8) & 0xff)
			buf.append(v & 0xff)
		elif v <= 0xffffffff:
			buf.append(0xce)
			_append_u32(buf, v)
		else:
			_encode_float64(buf, float(v))
	else:
		if v >= -32:
			buf.append(v & 0xff)
		elif v >= -128:
			buf.append(0xd0)
			buf.append(v & 0xff)
		elif v >= -32768:
			buf.append(0xd1)
			buf.append((v >> 8) & 0xff)
			buf.append(v & 0xff)
		elif v >= -2147483648:
			buf.append(0xd2)
			_append_u32(buf, v)
		else:
			_encode_float64(buf, float(v))

static func _encode_float64(buf: PackedByteArray, v: float) -> void:
	buf.append(0xcb)
	var tmp := PackedFloat64Array([v])
	var bytes := tmp.to_byte_array()
	for i in range(7, -1, -1):
		buf.append(bytes[i])

static func _encode_string(buf: PackedByteArray, s: String) -> void:
	var utf8 := s.to_utf8_buffer()
	var n := utf8.size()
	if n < 32:
		buf.append(0xa0 | n)
	elif n <= 0xff:
		buf.append(0xd9)
		buf.append(n)
	elif n <= 0xffff:
		buf.append(0xda)
		buf.append((n >> 8) & 0xff)
		buf.append(n & 0xff)
	else:
		buf.append(0xdb)
		_append_u32(buf, n)
	buf.append_array(utf8)

static func _encode_map(buf: PackedByteArray, d: Dictionary) -> void:
	var n := d.size()
	if n < 16:
		buf.append(0x80 | n)
	elif n <= 0xffff:
		buf.append(0xde)
		buf.append((n >> 8) & 0xff)
		buf.append(n & 0xff)
	else:
		buf.append(0xdf)
		_append_u32(buf, n)
	for key in d:
		_encode_value(buf, key)
		_encode_value(buf, d[key])

static func _encode_array(buf: PackedByteArray, arr: Array) -> void:
	var n := arr.size()
	if n < 16:
		buf.append(0x90 | n)
	elif n <= 0xffff:
		buf.append(0xdc)
		buf.append((n >> 8) & 0xff)
		buf.append(n & 0xff)
	else:
		buf.append(0xdd)
		_append_u32(buf, n)
	for item in arr:
		_encode_value(buf, item)

static func _encode_bin(buf: PackedByteArray, data: PackedByteArray) -> void:
	var n := data.size()
	if n <= 0xff:
		buf.append(0xc4)
		buf.append(n)
	elif n <= 0xffff:
		buf.append(0xc5)
		buf.append((n >> 8) & 0xff)
		buf.append(n & 0xff)
	else:
		buf.append(0xc6)
		_append_u32(buf, n)
	buf.append_array(data)

static func _append_u32(buf: PackedByteArray, v: int) -> void:
	buf.append((v >> 24) & 0xff)
	buf.append((v >> 16) & 0xff)
	buf.append((v >> 8) & 0xff)
	buf.append(v & 0xff)

# ── decode ──────────────────────────────────────────────────────

## [value, bytes_consumed] 를 반환한다.
static func decode(bytes: PackedByteArray, offset: int = 0) -> Array:
	if offset >= bytes.size():
		return [null, 0]
	var b: int = bytes[offset]
	if b <= 0x7f:
		return [b, 1]
	if b >= 0xe0:
		return [b - 256, 1]
	if (b & 0xf0) == 0x80:
		return _decode_map(bytes, offset, b & 0x0f)
	if (b & 0xf0) == 0x90:
		return _decode_array(bytes, offset, b & 0x0f)
	if (b & 0xe0) == 0xa0:
		return _decode_str(bytes, offset + 1, b & 0x1f)
	match b:
		0xc0: return [null, 1]
		0xc2: return [false, 1]
		0xc3: return [true, 1]
		0xc4: return _decode_bin(bytes, offset + 1, bytes[offset + 1])
		0xc5: return _decode_bin(bytes, offset + 1, _read_u16(bytes, offset + 1))
		0xc6: return _decode_bin(bytes, offset + 1, _read_u32(bytes, offset + 1))
		0xca: return [_read_f32(bytes, offset + 1), 5]
		0xcb: return [_read_f64(bytes, offset + 1), 9]
		0xcc: return [bytes[offset + 1], 2]
		0xcd: return [_read_u16(bytes, offset + 1), 3]
		0xce: return [_read_u32(bytes, offset + 1), 5]
		0xcf: return [_read_u64(bytes, offset + 1), 9]
		0xd0: return [_read_i8(bytes, offset + 1), 2]
		0xd1: return [_read_i16(bytes, offset + 1), 3]
		0xd2: return [_read_i32(bytes, offset + 1), 5]
		0xd3: return [_read_i64(bytes, offset + 1), 9]
		0xd9: return _decode_str(bytes, offset + 2, bytes[offset + 1])
		0xda: return _decode_str(bytes, offset + 3, _read_u16(bytes, offset + 1))
		0xdb: return _decode_str(bytes, offset + 5, _read_u32(bytes, offset + 1))
		0xdc: return _decode_array(bytes, offset, _read_u16(bytes, offset + 1))
		0xdd: return _decode_array(bytes, offset, _read_u32(bytes, offset + 1))
		0xde: return _decode_map(bytes, offset, _read_u16(bytes, offset + 1))
		0xdf: return _decode_map(bytes, offset, _read_u32(bytes, offset + 1))
	return [null, 1]

static func _decode_str(bytes: PackedByteArray, start: int, length: int) -> Array:
	var s := bytes.slice(start, start + length).get_string_from_utf8()
	return [s, start + length - (start - _header_size_for_str(length))]

static func _header_size_for_str(length: int) -> int:
	if length < 32: return 1
	if length <= 0xff: return 2
	if length <= 0xffff: return 3
	return 5

static func _decode_bin(bytes: PackedByteArray, header_end: int, length: int) -> Array:
	var hdr: int = header_end - (header_end - 1)
	var data_start: int
	if length <= 0xff:
		data_start = header_end + 1
		return [bytes.slice(data_start, data_start + length), 2 + length]
	if length <= 0xffff:
		data_start = header_end + 2
		return [bytes.slice(data_start, data_start + length), 3 + length]
	data_start = header_end + 4
	return [bytes.slice(data_start, data_start + length), 5 + length]

static func _decode_array(bytes: PackedByteArray, offset: int, count: int) -> Array:
	var b: int = bytes[offset]
	var pos: int
	if (b & 0xf0) == 0x90:
		pos = offset + 1
	elif b == 0xdc:
		pos = offset + 3
	else:
		pos = offset + 5
	var result: Array = []
	for _i in count:
		var item := decode(bytes, pos)
		result.append(item[0])
		pos += int(item[1])
	return [result, pos - offset]

static func _decode_map(bytes: PackedByteArray, offset: int, count: int) -> Array:
	var b: int = bytes[offset]
	var pos: int
	if (b & 0xf0) == 0x80:
		pos = offset + 1
	elif b == 0xde:
		pos = offset + 3
	else:
		pos = offset + 5
	var result := {}
	for _i in count:
		var k := decode(bytes, pos)
		pos += int(k[1])
		var v := decode(bytes, pos)
		pos += int(v[1])
		result[k[0]] = v[0]
	return [result, pos - offset]

# ── number readers (big-endian) ─────────────────────────────────

static func _read_u16(b: PackedByteArray, o: int) -> int:
	return (b[o] << 8) | b[o + 1]

static func _read_u32(b: PackedByteArray, o: int) -> int:
	return (b[o] << 24) | (b[o + 1] << 16) | (b[o + 2] << 8) | b[o + 3]

static func _read_u64(b: PackedByteArray, o: int) -> int:
	return (_read_u32(b, o) << 32) | _read_u32(b, o + 4)

static func _read_i8(b: PackedByteArray, o: int) -> int:
	var v := b[o]
	return v - 256 if v >= 128 else v

static func _read_i16(b: PackedByteArray, o: int) -> int:
	var v := _read_u16(b, o)
	return v - 65536 if v >= 32768 else v

static func _read_i32(b: PackedByteArray, o: int) -> int:
	var v := _read_u32(b, o)
	return v - 4294967296 if v >= 2147483648 else v

static func _read_i64(b: PackedByteArray, o: int) -> int:
	var v := _read_u64(b, o)
	return v

static func _read_f32(b: PackedByteArray, o: int) -> float:
	var tmp := PackedByteArray([b[o + 3], b[o + 2], b[o + 1], b[o]])
	return tmp.decode_float(0)

static func _read_f64(b: PackedByteArray, o: int) -> float:
	var tmp := PackedByteArray([b[o+7], b[o+6], b[o+5], b[o+4], b[o+3], b[o+2], b[o+1], b[o]])
	return tmp.decode_double(0)

# ── Colyseus 프레임 헬퍼 ────────────────────────────────────────

## Colyseus room.send(type, payload) 프레임을 만든다.
## 반환: [ROOM_DATA, msgpack(type), msgpack(payload)]
static func encode_room_data(type: String, payload: Variant = null) -> PackedByteArray:
	var buf := PackedByteArray()
	buf.append(ROOM_DATA)
	_encode_string(buf, type)
	if payload != null:
		_encode_value(buf, payload)
	return buf

## 서버에서 온 바이너리 프레임을 파싱한다.
## 반환: {"code": int, "type": Variant, "payload": Variant} 또는 null.
static func decode_server_frame(bytes: PackedByteArray) -> Variant:
	if bytes.is_empty():
		return null
	var code: int = bytes[0]
	if code == ROOM_DATA:
		return _decode_room_data(bytes)
	if code == ROOM_DATA_BYTES:
		return {"code": code, "type": null, "payload": bytes.slice(1)}
	return {"code": code, "type": null, "payload": bytes.slice(1)}

static func _decode_room_data(bytes: PackedByteArray) -> Variant:
	if bytes.size() < 2:
		return {"code": ROOM_DATA, "type": null, "payload": null}
	var t := decode(bytes, 1)
	var msg_type: Variant = t[0]
	var consumed: int = int(t[1])
	var pos := 1 + consumed
	var payload: Variant = null
	if pos < bytes.size():
		var p := decode(bytes, pos)
		payload = p[0]
	return {"code": ROOM_DATA, "type": msg_type, "payload": payload}
