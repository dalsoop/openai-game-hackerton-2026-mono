class_name LobbyColyseus
extends RefCounted
## 허브 LobbyState + MatchStateSchema 의 GD 거울. 필드 순서는 서버 @type 선언과 같다.

static func f(name: String, type: String, child = null) -> Colyseus.Schema.Field:
	return Colyseus.Schema.Field.new(name, type, child)

class PlayerRow extends Colyseus.Schema:
	static func definition() -> Array:
		return [
			LobbyColyseus.f("slot", Colyseus.Schema.NUMBER),
			LobbyColyseus.f("sessionId", Colyseus.Schema.STRING),
			LobbyColyseus.f("name", Colyseus.Schema.STRING),
			LobbyColyseus.f("connected", Colyseus.Schema.BOOLEAN),
			LobbyColyseus.f("packPct", Colyseus.Schema.UINT8),
			LobbyColyseus.f("characterId", Colyseus.Schema.STRING),
			LobbyColyseus.f("matchReady", Colyseus.Schema.BOOLEAN),
		]

class LobbyHero extends Colyseus.Schema:
	static func definition() -> Array:
		return [
			LobbyColyseus.f("slot", Colyseus.Schema.INT8),
			LobbyColyseus.f("x", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("y", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("aimX", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("aimY", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("hp", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("maxHp", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("alive", Colyseus.Schema.BOOLEAN),
			LobbyColyseus.f("mag", Colyseus.Schema.UINT8),
			LobbyColyseus.f("magMax", Colyseus.Schema.UINT8),
			LobbyColyseus.f("ack", Colyseus.Schema.UINT32),
			LobbyColyseus.f("animal", Colyseus.Schema.INT8),
		]

class LobbyBullet extends Colyseus.Schema:
	static func definition() -> Array:
		return [
			LobbyColyseus.f("id", Colyseus.Schema.UINT32),
			LobbyColyseus.f("x", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("y", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("vx", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("vy", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("owner", Colyseus.Schema.INT8),
			LobbyColyseus.f("kind", Colyseus.Schema.STRING),
		]

class MatchHeroHud extends Colyseus.Schema:
	static func definition() -> Array:
		return [
			LobbyColyseus.f("reloadFlash", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("respawnLeft", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("sprayIndex", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("rouDesc", Colyseus.Schema.STRING),
			LobbyColyseus.f("hitstunT", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("comboCaptureT", Colyseus.Schema.FLOAT32),
		]

class MatchHero extends Colyseus.Schema:
	static func definition() -> Array:
		return [
			LobbyColyseus.f("slot", Colyseus.Schema.INT8),
			LobbyColyseus.f("name", Colyseus.Schema.STRING),
			LobbyColyseus.f("x", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("y", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("aimX", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("aimY", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("hp", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("maxHp", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("alive", Colyseus.Schema.BOOLEAN),
			LobbyColyseus.f("mag", Colyseus.Schema.UINT8),
			LobbyColyseus.f("magMax", Colyseus.Schema.UINT8),
			LobbyColyseus.f("reloadLeft", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("weapon", Colyseus.Schema.STRING),
			LobbyColyseus.f("ult", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("ack", Colyseus.Schema.UINT32),
			LobbyColyseus.f("animal", Colyseus.Schema.INT8),
			LobbyColyseus.f("characterId", Colyseus.Schema.STRING),
			LobbyColyseus.f("cpu", Colyseus.Schema.BOOLEAN),
			LobbyColyseus.f("item", Colyseus.Schema.STRING),
			LobbyColyseus.f("kills", Colyseus.Schema.UINT32),
			LobbyColyseus.f("downed", Colyseus.Schema.BOOLEAN),
			LobbyColyseus.f("downLeft", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("deaths", Colyseus.Schema.UINT32),
			LobbyColyseus.f("score", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("streak", Colyseus.Schema.UINT32),
			LobbyColyseus.f("emote", Colyseus.Schema.INT8),
			LobbyColyseus.f("emoteTime", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("weaponId", Colyseus.Schema.STRING),
			LobbyColyseus.f("stunT", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("rootT", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("ccT", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("guardT", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("armorT", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("spawnT", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("launchT", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("launchVX", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("launchVY", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("charging", Colyseus.Schema.BOOLEAN),
			LobbyColyseus.f("chargeT", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("dmgOrbT", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("downTaken", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("woolT", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("woolHp", Colyseus.Schema.INT16),
			LobbyColyseus.f("woolMax", Colyseus.Schema.INT16),
			LobbyColyseus.f("rouT", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("rouRank", Colyseus.Schema.STRING),
			LobbyColyseus.f("rouPhase", Colyseus.Schema.STRING),
			LobbyColyseus.f("rouSpin", Colyseus.Schema.STRING),
			LobbyColyseus.f("rouLabel", Colyseus.Schema.STRING),
			LobbyColyseus.f("action", Colyseus.Schema.STRING),
			LobbyColyseus.f("heldItem", Colyseus.Schema.STRING),
			LobbyColyseus.f("springT", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("slideT", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("rlTimed", Colyseus.Schema.STRING),
			LobbyColyseus.f("ultClones", Colyseus.Schema.STRING),
			LobbyColyseus.f("parked", Colyseus.Schema.BOOLEAN),
			# 서버 match-schema.ts 62-69행과 순서 일치 필수 — 인덱스 기반 디코드.
			LobbyColyseus.f("pullT", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("pocketT", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("hopT", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("hopMax", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("hopHeight", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("mobCd", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("mvSpd", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("elim", Colyseus.Schema.BOOLEAN),
			LobbyColyseus.f("hud", Colyseus.Schema.REF, LobbyColyseus.MatchHeroHud),
		]

class MatchBullet extends Colyseus.Schema:
	static func definition() -> Array:
		return [
			LobbyColyseus.f("id", Colyseus.Schema.UINT32),
			LobbyColyseus.f("x", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("y", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("vx", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("vy", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("owner", Colyseus.Schema.INT8),
			LobbyColyseus.f("kind", Colyseus.Schema.STRING),
			LobbyColyseus.f("radius", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("arc", Colyseus.Schema.BOOLEAN),
			LobbyColyseus.f("heavy", Colyseus.Schema.BOOLEAN),
			LobbyColyseus.f("src", Colyseus.Schema.STRING),
			LobbyColyseus.f("ttl", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("maxTtl", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("lx", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("ly", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("splash", Colyseus.Schema.FLOAT32),
		]

class MatchCover extends Colyseus.Schema:
	static func definition() -> Array:
		return [
			LobbyColyseus.f("x", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("y", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("w", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("h", Colyseus.Schema.FLOAT32),
		]

class MatchCrate extends Colyseus.Schema:
	static func definition() -> Array:
		return [
			LobbyColyseus.f("id", Colyseus.Schema.UINT32),
			LobbyColyseus.f("x", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("y", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("hp", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("maxHp", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("alive", Colyseus.Schema.BOOLEAN),
		]

class MatchCrateOrb extends Colyseus.Schema:
	static func definition() -> Array:
		return [
			LobbyColyseus.f("x", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("y", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("red", Colyseus.Schema.BOOLEAN),
			LobbyColyseus.f("active", Colyseus.Schema.BOOLEAN),
		]

class MatchMidTower extends Colyseus.Schema:
	static func definition() -> Array:
		return [
			LobbyColyseus.f("alive", Colyseus.Schema.BOOLEAN),
			LobbyColyseus.f("x", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("y", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("hp", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("maxHp", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("boing", Colyseus.Schema.FLOAT32),
		]

class MatchLoot extends Colyseus.Schema:
	static func definition() -> Array:
		return [
			LobbyColyseus.f("id", Colyseus.Schema.STRING),
			LobbyColyseus.f("kind", Colyseus.Schema.STRING),
			LobbyColyseus.f("x", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("y", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("n", Colyseus.Schema.STRING),
		]

class MatchDeployable extends Colyseus.Schema:
	static func definition() -> Array:
		return [
			LobbyColyseus.f("type", Colyseus.Schema.STRING),
			LobbyColyseus.f("owner", Colyseus.Schema.INT8),
			LobbyColyseus.f("x", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("y", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("dx", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("dy", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("tdx", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("tdy", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("halfLength", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("lifetime", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("maxLifetime", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("armTime", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("armDuration", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("triggered", Colyseus.Schema.BOOLEAN),
			LobbyColyseus.f("triggerRadius", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("blastRadius", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("fuseTime", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("fuseDuration", Colyseus.Schema.FLOAT32),
		]

class MatchZone extends Colyseus.Schema:
	static func definition() -> Array:
		return [
			LobbyColyseus.f("x", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("y", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("radius", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("owner", Colyseus.Schema.INT8),
			LobbyColyseus.f("delay", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("warningDuration", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("color", Colyseus.Schema.STRING),
			LobbyColyseus.f("effectKind", Colyseus.Schema.STRING),
			LobbyColyseus.f("label", Colyseus.Schema.STRING),
		]

class MatchKnockout extends Colyseus.Schema:
	static func definition() -> Array:
		return [
			LobbyColyseus.f("slot", Colyseus.Schema.INT8),
			LobbyColyseus.f("animal", Colyseus.Schema.INT8),
			LobbyColyseus.f("x", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("y", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("time", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("maxTime", Colyseus.Schema.FLOAT32),
		]

class MatchFinishCine extends Colyseus.Schema:
	static func definition() -> Array:
		return [
			LobbyColyseus.f("on", Colyseus.Schema.BOOLEAN),
			LobbyColyseus.f("atk", Colyseus.Schema.INT8),
			LobbyColyseus.f("vic", Colyseus.Schema.INT8),
			LobbyColyseus.f("t", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("hit", Colyseus.Schema.BOOLEAN),
			LobbyColyseus.f("hitAge", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("fly", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("vicX", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("vicY", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("vicSpin", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("atkX", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("rush", Colyseus.Schema.BOOLEAN),
			LobbyColyseus.f("midX", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("midY", Colyseus.Schema.FLOAT32),
		]

class MatchCore extends Colyseus.Schema:
	static func definition() -> Array:
		return [
			LobbyColyseus.f("slot", Colyseus.Schema.INT8),
			LobbyColyseus.f("x", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("y", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("hp", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("maxHp", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("alive", Colyseus.Schema.BOOLEAN),
		]

class MatchEffect extends Colyseus.Schema:
	static func definition() -> Array:
		return [
			LobbyColyseus.f("k", Colyseus.Schema.STRING),
			LobbyColyseus.f("x", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("y", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("r", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("t", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("maxT", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("color", Colyseus.Schema.STRING),
			LobbyColyseus.f("label", Colyseus.Schema.STRING),
			LobbyColyseus.f("dx", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("dy", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("follow", Colyseus.Schema.INT8),
			LobbyColyseus.f("sx", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("sy", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("dep", Colyseus.Schema.BOOLEAN),
		]

class MatchEvent extends Colyseus.Schema:
	static func definition() -> Array:
		return [
			LobbyColyseus.f("seq", Colyseus.Schema.UINT32),
			LobbyColyseus.f("t", Colyseus.Schema.UINT32),
			LobbyColyseus.f("k", Colyseus.Schema.STRING),
			LobbyColyseus.f("a", Colyseus.Schema.INT8),
			LobbyColyseus.f("b", Colyseus.Schema.INT8),
			LobbyColyseus.f("d", Colyseus.Schema.STRING),
		]

class MatchState extends Colyseus.Schema:
	static func definition() -> Array:
		return [
			LobbyColyseus.f("tick", Colyseus.Schema.UINT32),
			LobbyColyseus.f("time", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("result", Colyseus.Schema.STRING),
			LobbyColyseus.f("winner", Colyseus.Schema.INT8),
			LobbyColyseus.f("zoneR", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("shrinking", Colyseus.Schema.BOOLEAN),
			LobbyColyseus.f("zoneCX", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("zoneCY", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("zonePhase", Colyseus.Schema.UINT8),
			LobbyColyseus.f("startCountdown", Colyseus.Schema.FLOAT32),
			LobbyColyseus.f("callout", Colyseus.Schema.STRING),
			LobbyColyseus.f("calloutTicks", Colyseus.Schema.UINT32),
			LobbyColyseus.f("wantedSlot", Colyseus.Schema.INT8),
			LobbyColyseus.f("mode", Colyseus.Schema.STRING),
			LobbyColyseus.f("heroes", Colyseus.Schema.MAP, LobbyColyseus.MatchHero),
			LobbyColyseus.f("bullets", Colyseus.Schema.MAP, LobbyColyseus.MatchBullet),
			LobbyColyseus.f("covers", Colyseus.Schema.ARRAY, LobbyColyseus.MatchCover),
			LobbyColyseus.f("crates", Colyseus.Schema.ARRAY, LobbyColyseus.MatchCrate),
			LobbyColyseus.f("crateOrbs", Colyseus.Schema.ARRAY, LobbyColyseus.MatchCrateOrb),
			LobbyColyseus.f("midTower", Colyseus.Schema.REF, LobbyColyseus.MatchMidTower),
			LobbyColyseus.f("loot", Colyseus.Schema.ARRAY, LobbyColyseus.MatchLoot),
			LobbyColyseus.f("deployables", Colyseus.Schema.ARRAY, LobbyColyseus.MatchDeployable),
			LobbyColyseus.f("zones", Colyseus.Schema.ARRAY, LobbyColyseus.MatchZone),
			LobbyColyseus.f("knockouts", Colyseus.Schema.ARRAY, LobbyColyseus.MatchKnockout),
			LobbyColyseus.f("finishCine", Colyseus.Schema.REF, LobbyColyseus.MatchFinishCine),
			LobbyColyseus.f("cores", Colyseus.Schema.ARRAY, LobbyColyseus.MatchCore),
			LobbyColyseus.f("eventSeq", Colyseus.Schema.UINT32),
			LobbyColyseus.f("events", Colyseus.Schema.MAP, LobbyColyseus.MatchEvent),
			LobbyColyseus.f("streakCallout", Colyseus.Schema.STRING),
			LobbyColyseus.f("streakSubtitle", Colyseus.Schema.STRING),
			LobbyColyseus.f("streakCalloutTicks", Colyseus.Schema.UINT32),
			LobbyColyseus.f("streakCalloutShutdown", Colyseus.Schema.BOOLEAN),
			LobbyColyseus.f("effects", Colyseus.Schema.ARRAY, LobbyColyseus.MatchEffect),
		]

class LobbyState extends Colyseus.Schema:
	static func definition() -> Array:
		return [
			LobbyColyseus.f("gameId", Colyseus.Schema.STRING),
			LobbyColyseus.f("open", Colyseus.Schema.BOOLEAN),
			LobbyColyseus.f("phase", Colyseus.Schema.STRING),
			LobbyColyseus.f("hostSessionId", Colyseus.Schema.STRING),
			LobbyColyseus.f("title", Colyseus.Schema.STRING),
			LobbyColyseus.f("mode", Colyseus.Schema.STRING),
			LobbyColyseus.f("seed", Colyseus.Schema.NUMBER),
			LobbyColyseus.f("createdAtMs", Colyseus.Schema.NUMBER),
			LobbyColyseus.f("idleUntilSec", Colyseus.Schema.UINT32),
			LobbyColyseus.f("players", Colyseus.Schema.ARRAY, LobbyColyseus.PlayerRow),
			LobbyColyseus.f("matchTick", Colyseus.Schema.UINT32),
			LobbyColyseus.f("heroes", Colyseus.Schema.MAP, LobbyColyseus.LobbyHero),
			LobbyColyseus.f("bullets", Colyseus.Schema.MAP, LobbyColyseus.LobbyBullet),
			LobbyColyseus.f("match", Colyseus.Schema.REF, LobbyColyseus.MatchState),
			LobbyColyseus.f("loadHeld", Colyseus.Schema.BOOLEAN),
		]
