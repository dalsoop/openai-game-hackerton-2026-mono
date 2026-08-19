shader_type canvas_item;

// N x M 그리드 스프라이트 시트에서 인덱스 하나로 셀 한 칸만 잘라 보여주는 셰이더.
// Sprite2D / TextureRect 등 이 노드의 texture(atlas 이미지)에 적용한다.
// 셀 순서는 왼쪽 위부터 가로 우선(row-major) — 0번이 1행 1열, columns번이 2행 1열.

uniform int columns = 4; // N: 아틀라스 가로 셀 수
uniform int rows = 3;    // M: 아틀라스 세로 셀 수

// instance uniform: 이 머티리얼 리소스 하나를 여러 스프라이트가 공유해도
// 노드마다 set_instance_shader_parameter()로 자기만의 프레임 인덱스를 가질 수 있다.
// (총알/이펙트를 스폰할 때마다 ShaderMaterial을 새로 만들 필요가 없음)
instance uniform int frame_index = 0;

void fragment() {
	int col = frame_index % columns;
	int row = frame_index / columns;

	vec2 cell_size = vec2(1.0 / float(columns), 1.0 / float(rows));
	vec2 cell_origin = vec2(float(col), float(row)) * cell_size;

	vec2 atlas_uv = cell_origin + UV * cell_size;

	COLOR = texture(TEXTURE, atlas_uv);
}