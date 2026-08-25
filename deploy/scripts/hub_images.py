"""허브 이미지 ref ↔ 슬롯 폴더. Helm 은 심은 태그가 클러스터에 있어야 한다."""


def folder_from_hub_ref(ref: str) -> str:
    return ref.rsplit("/", 1)[-1].split(":")[0]


def missing_hub_refs(refs: list[str], listed: str) -> list[str]:
    return [ref for ref in refs if ref not in listed]
