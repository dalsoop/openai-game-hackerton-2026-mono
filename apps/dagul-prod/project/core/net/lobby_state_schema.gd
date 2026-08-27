class_name LobbyColyseus
extends RefCounted
## 생성본. 고치지 말 것.
## 정본: web/lib/hub/match-schema/*.ts · lobby-state.ts
## npm run schema:codegen

# 
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY
# DO NOT CHANGE IT MANUALLY UNLESS YOU KNOW WHAT YOU'RE DOING
# 
# GENERATED USING @colyseus/schema 5.0.22
# 

class MatchUntilBuffSchema extends Colyseus.Schema:
	static func definition():
		return [
			Colyseus.Schema.Field.new("atk", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("spd", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("def", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("hp", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("rate", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("range", Colyseus.Schema.FLOAT32),
		]

	func _to_string() -> String:
		return "MatchUntilBuffSchema(__ref_id: %s, atk: %s, spd: %s, def: %s, hp: %s, rate: %s, range: %s)" % [self.__ref_id, self.atk, self.spd, self.def, self.hp, self.rate, self.range]

class MatchTimedBuffSchema extends Colyseus.Schema:
	static func definition():
		return [
			Colyseus.Schema.Field.new("id", Colyseus.Schema.STRING),
			Colyseus.Schema.Field.new("name", Colyseus.Schema.STRING),
			Colyseus.Schema.Field.new("time", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("shield", Colyseus.Schema.FLOAT32),
		]

	func _to_string() -> String:
		return "MatchTimedBuffSchema(__ref_id: %s, id: %s, name: %s, time: %s, shield: %s)" % [self.__ref_id, self.id, self.name, self.time, self.shield]

class MatchCloneSchema extends Colyseus.Schema:
	static func definition():
		return [
			Colyseus.Schema.Field.new("x", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("y", Colyseus.Schema.FLOAT32),
		]

	func _to_string() -> String:
		return "MatchCloneSchema(__ref_id: %s, x: %s, y: %s)" % [self.__ref_id, self.x, self.y]

class MatchHeroHudSchema extends Colyseus.Schema:
	static func definition():
		return [
			Colyseus.Schema.Field.new("reloadFlash", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("respawnLeft", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("sprayIndex", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("rouletteDesc", Colyseus.Schema.STRING),
			Colyseus.Schema.Field.new("hitstunTime", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("comboCaptureTime", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("moveSpeed", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("eliminated", Colyseus.Schema.BOOLEAN),
			Colyseus.Schema.Field.new("medkits", Colyseus.Schema.UINT8),
			Colyseus.Schema.Field.new("mobilityDist", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("untilBuffs", Colyseus.Schema.REF, MatchUntilBuffSchema),
		]

	func _to_string() -> String:
		return "MatchHeroHudSchema(__ref_id: %s, reloadFlash: %s, respawnLeft: %s, sprayIndex: %s, rouletteDesc: %s, hitstunTime: %s, comboCaptureTime: %s, moveSpeed: %s, eliminated: %s, medkits: %s, mobilityDist: %s, untilBuffs: %s)" % [self.__ref_id, self.reloadFlash, self.respawnLeft, self.sprayIndex, self.rouletteDesc, self.hitstunTime, self.comboCaptureTime, self.moveSpeed, self.eliminated, self.medkits, self.mobilityDist, self.untilBuffs]

class MatchHeroSchema extends Colyseus.Schema:
	static func definition():
		return [
			Colyseus.Schema.Field.new("slot", Colyseus.Schema.INT8),
			Colyseus.Schema.Field.new("name", Colyseus.Schema.STRING),
			Colyseus.Schema.Field.new("x", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("y", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("aimX", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("aimY", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("hp", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("maxHp", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("alive", Colyseus.Schema.BOOLEAN),
			Colyseus.Schema.Field.new("mag", Colyseus.Schema.UINT8),
			Colyseus.Schema.Field.new("magMax", Colyseus.Schema.UINT8),
			Colyseus.Schema.Field.new("reloadLeft", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("weapon", Colyseus.Schema.STRING),
			Colyseus.Schema.Field.new("ult", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("ack", Colyseus.Schema.UINT32),
			Colyseus.Schema.Field.new("animal", Colyseus.Schema.INT8),
			Colyseus.Schema.Field.new("characterId", Colyseus.Schema.STRING),
			Colyseus.Schema.Field.new("cpu", Colyseus.Schema.BOOLEAN),
			Colyseus.Schema.Field.new("item", Colyseus.Schema.STRING),
			Colyseus.Schema.Field.new("kills", Colyseus.Schema.UINT32),
			Colyseus.Schema.Field.new("downed", Colyseus.Schema.BOOLEAN),
			Colyseus.Schema.Field.new("downLeft", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("deaths", Colyseus.Schema.UINT32),
			Colyseus.Schema.Field.new("score", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("streak", Colyseus.Schema.UINT32),
			Colyseus.Schema.Field.new("emote", Colyseus.Schema.INT8),
			Colyseus.Schema.Field.new("emoteTime", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("weaponId", Colyseus.Schema.STRING),
			Colyseus.Schema.Field.new("stunTime", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("rootTime", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("ccTime", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("guardTime", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("armorTime", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("spawnProtect", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("launchTime", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("launchVX", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("launchVY", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("charging", Colyseus.Schema.BOOLEAN),
			Colyseus.Schema.Field.new("chargeTime", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("dmgOrbTime", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("downTaken", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("woolTime", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("woolHp", Colyseus.Schema.INT16),
			Colyseus.Schema.Field.new("woolMax", Colyseus.Schema.INT16),
			Colyseus.Schema.Field.new("rouletteTime", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("rouletteRank", Colyseus.Schema.STRING),
			Colyseus.Schema.Field.new("roulettePhase", Colyseus.Schema.STRING),
			Colyseus.Schema.Field.new("rouletteSpin", Colyseus.Schema.STRING),
			Colyseus.Schema.Field.new("rouletteLabel", Colyseus.Schema.STRING),
			Colyseus.Schema.Field.new("action", Colyseus.Schema.STRING),
			Colyseus.Schema.Field.new("heldItem", Colyseus.Schema.STRING),
			Colyseus.Schema.Field.new("springTime", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("slideTime", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("timedBuffs", Colyseus.Schema.ARRAY, MatchTimedBuffSchema),
			Colyseus.Schema.Field.new("clones", Colyseus.Schema.ARRAY, MatchCloneSchema),
			Colyseus.Schema.Field.new("parked", Colyseus.Schema.BOOLEAN),
			Colyseus.Schema.Field.new("pullTime", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("pocketTime", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("hopTime", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("hopMax", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("hopHeight", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("mobilityCd", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("hud", Colyseus.Schema.REF, MatchHeroHudSchema),
		]

	func _to_string() -> String:
		return "MatchHeroSchema(__ref_id: %s, slot: %s, name: %s, x: %s, y: %s, aimX: %s, aimY: %s, hp: %s, maxHp: %s, alive: %s, mag: %s, magMax: %s, reloadLeft: %s, weapon: %s, ult: %s, ack: %s, animal: %s, characterId: %s, cpu: %s, item: %s, kills: %s, downed: %s, downLeft: %s, deaths: %s, score: %s, streak: %s, emote: %s, emoteTime: %s, weaponId: %s, stunTime: %s, rootTime: %s, ccTime: %s, guardTime: %s, armorTime: %s, spawnProtect: %s, launchTime: %s, launchVX: %s, launchVY: %s, charging: %s, chargeTime: %s, dmgOrbTime: %s, downTaken: %s, woolTime: %s, woolHp: %s, woolMax: %s, rouletteTime: %s, rouletteRank: %s, roulettePhase: %s, rouletteSpin: %s, rouletteLabel: %s, action: %s, heldItem: %s, springTime: %s, slideTime: %s, timedBuffs: %s, clones: %s, parked: %s, pullTime: %s, pocketTime: %s, hopTime: %s, hopMax: %s, hopHeight: %s, mobilityCd: %s, hud: %s)" % [self.__ref_id, self.slot, self.name, self.x, self.y, self.aimX, self.aimY, self.hp, self.maxHp, self.alive, self.mag, self.magMax, self.reloadLeft, self.weapon, self.ult, self.ack, self.animal, self.characterId, self.cpu, self.item, self.kills, self.downed, self.downLeft, self.deaths, self.score, self.streak, self.emote, self.emoteTime, self.weaponId, self.stunTime, self.rootTime, self.ccTime, self.guardTime, self.armorTime, self.spawnProtect, self.launchTime, self.launchVX, self.launchVY, self.charging, self.chargeTime, self.dmgOrbTime, self.downTaken, self.woolTime, self.woolHp, self.woolMax, self.rouletteTime, self.rouletteRank, self.roulettePhase, self.rouletteSpin, self.rouletteLabel, self.action, self.heldItem, self.springTime, self.slideTime, self.timedBuffs, self.clones, self.parked, self.pullTime, self.pocketTime, self.hopTime, self.hopMax, self.hopHeight, self.mobilityCd, self.hud]

class MatchBulletSchema extends Colyseus.Schema:
	static func definition():
		return [
			Colyseus.Schema.Field.new("id", Colyseus.Schema.UINT32),
			Colyseus.Schema.Field.new("x", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("y", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("vx", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("vy", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("owner", Colyseus.Schema.INT8),
			Colyseus.Schema.Field.new("kind", Colyseus.Schema.STRING),
			Colyseus.Schema.Field.new("radius", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("arc", Colyseus.Schema.BOOLEAN),
			Colyseus.Schema.Field.new("heavy", Colyseus.Schema.BOOLEAN),
			Colyseus.Schema.Field.new("src", Colyseus.Schema.STRING),
			Colyseus.Schema.Field.new("ttl", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("maxTtl", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("lx", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("ly", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("splash", Colyseus.Schema.FLOAT32),
		]

	func _to_string() -> String:
		return "MatchBulletSchema(__ref_id: %s, id: %s, x: %s, y: %s, vx: %s, vy: %s, owner: %s, kind: %s, radius: %s, arc: %s, heavy: %s, src: %s, ttl: %s, maxTtl: %s, lx: %s, ly: %s, splash: %s)" % [self.__ref_id, self.id, self.x, self.y, self.vx, self.vy, self.owner, self.kind, self.radius, self.arc, self.heavy, self.src, self.ttl, self.maxTtl, self.lx, self.ly, self.splash]

class MatchCoverSchema extends Colyseus.Schema:
	static func definition():
		return [
			Colyseus.Schema.Field.new("x", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("y", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("w", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("h", Colyseus.Schema.FLOAT32),
		]

	func _to_string() -> String:
		return "MatchCoverSchema(__ref_id: %s, x: %s, y: %s, w: %s, h: %s)" % [self.__ref_id, self.x, self.y, self.w, self.h]

class MatchCrateSchema extends Colyseus.Schema:
	static func definition():
		return [
			Colyseus.Schema.Field.new("id", Colyseus.Schema.UINT32),
			Colyseus.Schema.Field.new("x", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("y", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("hp", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("maxHp", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("alive", Colyseus.Schema.BOOLEAN),
		]

	func _to_string() -> String:
		return "MatchCrateSchema(__ref_id: %s, id: %s, x: %s, y: %s, hp: %s, maxHp: %s, alive: %s)" % [self.__ref_id, self.id, self.x, self.y, self.hp, self.maxHp, self.alive]

class MatchCrateOrbSchema extends Colyseus.Schema:
	static func definition():
		return [
			Colyseus.Schema.Field.new("x", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("y", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("red", Colyseus.Schema.BOOLEAN),
			Colyseus.Schema.Field.new("active", Colyseus.Schema.BOOLEAN),
		]

	func _to_string() -> String:
		return "MatchCrateOrbSchema(__ref_id: %s, x: %s, y: %s, red: %s, active: %s)" % [self.__ref_id, self.x, self.y, self.red, self.active]

class MatchMidTowerSchema extends Colyseus.Schema:
	static func definition():
		return [
			Colyseus.Schema.Field.new("alive", Colyseus.Schema.BOOLEAN),
			Colyseus.Schema.Field.new("x", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("y", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("hp", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("maxHp", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("boing", Colyseus.Schema.FLOAT32),
		]

	func _to_string() -> String:
		return "MatchMidTowerSchema(__ref_id: %s, alive: %s, x: %s, y: %s, hp: %s, maxHp: %s, boing: %s)" % [self.__ref_id, self.alive, self.x, self.y, self.hp, self.maxHp, self.boing]

class MatchLootSchema extends Colyseus.Schema:
	static func definition():
		return [
			Colyseus.Schema.Field.new("id", Colyseus.Schema.STRING),
			Colyseus.Schema.Field.new("kind", Colyseus.Schema.STRING),
			Colyseus.Schema.Field.new("x", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("y", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("n", Colyseus.Schema.STRING),
			Colyseus.Schema.Field.new("itemKind", Colyseus.Schema.STRING),
		]

	func _to_string() -> String:
		return "MatchLootSchema(__ref_id: %s, id: %s, kind: %s, x: %s, y: %s, n: %s, itemKind: %s)" % [self.__ref_id, self.id, self.kind, self.x, self.y, self.n, self.itemKind]

class MatchDeployableSchema extends Colyseus.Schema:
	static func definition():
		return [
			Colyseus.Schema.Field.new("type", Colyseus.Schema.STRING),
			Colyseus.Schema.Field.new("owner", Colyseus.Schema.INT8),
			Colyseus.Schema.Field.new("x", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("y", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("dx", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("dy", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("tdx", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("tdy", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("halfLength", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("lifetime", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("maxLifetime", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("armTime", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("armDuration", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("triggered", Colyseus.Schema.BOOLEAN),
			Colyseus.Schema.Field.new("triggerRadius", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("blastRadius", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("fuseTime", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("fuseDuration", Colyseus.Schema.FLOAT32),
		]

	func _to_string() -> String:
		return "MatchDeployableSchema(__ref_id: %s, type: %s, owner: %s, x: %s, y: %s, dx: %s, dy: %s, tdx: %s, tdy: %s, halfLength: %s, lifetime: %s, maxLifetime: %s, armTime: %s, armDuration: %s, triggered: %s, triggerRadius: %s, blastRadius: %s, fuseTime: %s, fuseDuration: %s)" % [self.__ref_id, self.type, self.owner, self.x, self.y, self.dx, self.dy, self.tdx, self.tdy, self.halfLength, self.lifetime, self.maxLifetime, self.armTime, self.armDuration, self.triggered, self.triggerRadius, self.blastRadius, self.fuseTime, self.fuseDuration]

class MatchZoneSchema extends Colyseus.Schema:
	static func definition():
		return [
			Colyseus.Schema.Field.new("x", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("y", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("radius", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("owner", Colyseus.Schema.INT8),
			Colyseus.Schema.Field.new("delay", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("warningDuration", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("color", Colyseus.Schema.STRING),
			Colyseus.Schema.Field.new("effectKind", Colyseus.Schema.STRING),
			Colyseus.Schema.Field.new("label", Colyseus.Schema.STRING),
		]

	func _to_string() -> String:
		return "MatchZoneSchema(__ref_id: %s, x: %s, y: %s, radius: %s, owner: %s, delay: %s, warningDuration: %s, color: %s, effectKind: %s, label: %s)" % [self.__ref_id, self.x, self.y, self.radius, self.owner, self.delay, self.warningDuration, self.color, self.effectKind, self.label]

class MatchKnockoutSchema extends Colyseus.Schema:
	static func definition():
		return [
			Colyseus.Schema.Field.new("slot", Colyseus.Schema.INT8),
			Colyseus.Schema.Field.new("animal", Colyseus.Schema.INT8),
			Colyseus.Schema.Field.new("x", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("y", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("time", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("maxTime", Colyseus.Schema.FLOAT32),
		]

	func _to_string() -> String:
		return "MatchKnockoutSchema(__ref_id: %s, slot: %s, animal: %s, x: %s, y: %s, time: %s, maxTime: %s)" % [self.__ref_id, self.slot, self.animal, self.x, self.y, self.time, self.maxTime]

class MatchFinishCineSchema extends Colyseus.Schema:
	static func definition():
		return [
			Colyseus.Schema.Field.new("on", Colyseus.Schema.BOOLEAN),
			Colyseus.Schema.Field.new("atk", Colyseus.Schema.INT8),
			Colyseus.Schema.Field.new("vic", Colyseus.Schema.INT8),
			Colyseus.Schema.Field.new("t", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("hit", Colyseus.Schema.BOOLEAN),
			Colyseus.Schema.Field.new("hitAge", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("fly", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("vicX", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("vicY", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("vicSpin", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("atkX", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("rush", Colyseus.Schema.BOOLEAN),
			Colyseus.Schema.Field.new("midX", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("midY", Colyseus.Schema.FLOAT32),
		]

	func _to_string() -> String:
		return "MatchFinishCineSchema(__ref_id: %s, on: %s, atk: %s, vic: %s, t: %s, hit: %s, hitAge: %s, fly: %s, vicX: %s, vicY: %s, vicSpin: %s, atkX: %s, rush: %s, midX: %s, midY: %s)" % [self.__ref_id, self.on, self.atk, self.vic, self.t, self.hit, self.hitAge, self.fly, self.vicX, self.vicY, self.vicSpin, self.atkX, self.rush, self.midX, self.midY]

class MatchCoreSchema extends Colyseus.Schema:
	static func definition():
		return [
			Colyseus.Schema.Field.new("slot", Colyseus.Schema.INT8),
			Colyseus.Schema.Field.new("x", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("y", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("hp", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("maxHp", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("alive", Colyseus.Schema.BOOLEAN),
		]

	func _to_string() -> String:
		return "MatchCoreSchema(__ref_id: %s, slot: %s, x: %s, y: %s, hp: %s, maxHp: %s, alive: %s)" % [self.__ref_id, self.slot, self.x, self.y, self.hp, self.maxHp, self.alive]

class MatchEffectSchema extends Colyseus.Schema:
	static func definition():
		return [
			Colyseus.Schema.Field.new("k", Colyseus.Schema.STRING),
			Colyseus.Schema.Field.new("x", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("y", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("r", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("t", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("maxT", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("color", Colyseus.Schema.STRING),
			Colyseus.Schema.Field.new("label", Colyseus.Schema.STRING),
			Colyseus.Schema.Field.new("dx", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("dy", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("follow", Colyseus.Schema.INT8),
			Colyseus.Schema.Field.new("sx", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("sy", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("dep", Colyseus.Schema.BOOLEAN),
		]

	func _to_string() -> String:
		return "MatchEffectSchema(__ref_id: %s, k: %s, x: %s, y: %s, r: %s, t: %s, maxT: %s, color: %s, label: %s, dx: %s, dy: %s, follow: %s, sx: %s, sy: %s, dep: %s)" % [self.__ref_id, self.k, self.x, self.y, self.r, self.t, self.maxT, self.color, self.label, self.dx, self.dy, self.follow, self.sx, self.sy, self.dep]

class MatchEventDataSchema extends Colyseus.Schema:
	static func definition():
		return [
			Colyseus.Schema.Field.new("equipment", Colyseus.Schema.STRING),
			Colyseus.Schema.Field.new("id", Colyseus.Schema.STRING),
			Colyseus.Schema.Field.new("source", Colyseus.Schema.STRING),
			Colyseus.Schema.Field.new("kind", Colyseus.Schema.STRING),
			Colyseus.Schema.Field.new("rank", Colyseus.Schema.STRING),
			Colyseus.Schema.Field.new("reason", Colyseus.Schema.STRING),
			Colyseus.Schema.Field.new("dropped", Colyseus.Schema.STRING),
			Colyseus.Schema.Field.new("x", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("y", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("damage", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("heal", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("amount", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("remaining", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("from", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("to", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("hpRatio", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("coreRatio", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("score", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("clones", Colyseus.Schema.INT32),
			Colyseus.Schema.Field.new("crate", Colyseus.Schema.INT32),
			Colyseus.Schema.Field.new("target", Colyseus.Schema.INT32),
			Colyseus.Schema.Field.new("left", Colyseus.Schema.INT32),
			Colyseus.Schema.Field.new("phase", Colyseus.Schema.INT32),
			Colyseus.Schema.Field.new("standing", Colyseus.Schema.INT32),
			Colyseus.Schema.Field.new("pending", Colyseus.Schema.INT32),
			Colyseus.Schema.Field.new("previousTarget", Colyseus.Schema.INT32),
			Colyseus.Schema.Field.new("predicted", Colyseus.Schema.BOOLEAN),
			Colyseus.Schema.Field.new("executed", Colyseus.Schema.BOOLEAN),
		]

	func _to_string() -> String:
		return "MatchEventDataSchema(__ref_id: %s, equipment: %s, id: %s, source: %s, kind: %s, rank: %s, reason: %s, dropped: %s, x: %s, y: %s, damage: %s, heal: %s, amount: %s, remaining: %s, from: %s, to: %s, hpRatio: %s, coreRatio: %s, score: %s, clones: %s, crate: %s, target: %s, left: %s, phase: %s, standing: %s, pending: %s, previousTarget: %s, predicted: %s, executed: %s)" % [self.__ref_id, self.equipment, self.id, self.source, self.kind, self.rank, self.reason, self.dropped, self.x, self.y, self.damage, self.heal, self.amount, self.remaining, self.from, self.to, self.hpRatio, self.coreRatio, self.score, self.clones, self.crate, self.target, self.left, self.phase, self.standing, self.pending, self.previousTarget, self.predicted, self.executed]

class MatchEventSchema extends Colyseus.Schema:
	static func definition():
		return [
			Colyseus.Schema.Field.new("seq", Colyseus.Schema.UINT32),
			Colyseus.Schema.Field.new("tick", Colyseus.Schema.UINT32),
			Colyseus.Schema.Field.new("kind", Colyseus.Schema.STRING),
			Colyseus.Schema.Field.new("actor", Colyseus.Schema.INT8),
			Colyseus.Schema.Field.new("target", Colyseus.Schema.INT8),
			Colyseus.Schema.Field.new("data", Colyseus.Schema.REF, MatchEventDataSchema),
		]

	func _to_string() -> String:
		return "MatchEventSchema(__ref_id: %s, seq: %s, tick: %s, kind: %s, actor: %s, target: %s, data: %s)" % [self.__ref_id, self.seq, self.tick, self.kind, self.actor, self.target, self.data]

class MatchStateSchema extends Colyseus.Schema:
	static func definition():
		return [
			Colyseus.Schema.Field.new("tick", Colyseus.Schema.UINT32),
			Colyseus.Schema.Field.new("time", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("result", Colyseus.Schema.STRING),
			Colyseus.Schema.Field.new("winner", Colyseus.Schema.INT8),
			Colyseus.Schema.Field.new("zoneR", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("shrinking", Colyseus.Schema.BOOLEAN),
			Colyseus.Schema.Field.new("zoneCX", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("zoneCY", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("zonePhase", Colyseus.Schema.UINT8),
			Colyseus.Schema.Field.new("startCountdown", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("callout", Colyseus.Schema.STRING),
			Colyseus.Schema.Field.new("calloutTicks", Colyseus.Schema.UINT32),
			Colyseus.Schema.Field.new("wantedSlot", Colyseus.Schema.INT8),
			Colyseus.Schema.Field.new("mode", Colyseus.Schema.STRING),
			Colyseus.Schema.Field.new("heroes", Colyseus.Schema.MAP, MatchHeroSchema),
			Colyseus.Schema.Field.new("bullets", Colyseus.Schema.MAP, MatchBulletSchema),
			Colyseus.Schema.Field.new("covers", Colyseus.Schema.ARRAY, MatchCoverSchema),
			Colyseus.Schema.Field.new("crates", Colyseus.Schema.ARRAY, MatchCrateSchema),
			Colyseus.Schema.Field.new("crateOrbs", Colyseus.Schema.ARRAY, MatchCrateOrbSchema),
			Colyseus.Schema.Field.new("midTower", Colyseus.Schema.REF, MatchMidTowerSchema),
			Colyseus.Schema.Field.new("loot", Colyseus.Schema.ARRAY, MatchLootSchema),
			Colyseus.Schema.Field.new("deployables", Colyseus.Schema.ARRAY, MatchDeployableSchema),
			Colyseus.Schema.Field.new("zones", Colyseus.Schema.ARRAY, MatchZoneSchema),
			Colyseus.Schema.Field.new("knockouts", Colyseus.Schema.ARRAY, MatchKnockoutSchema),
			Colyseus.Schema.Field.new("finishCine", Colyseus.Schema.REF, MatchFinishCineSchema),
			Colyseus.Schema.Field.new("cores", Colyseus.Schema.ARRAY, MatchCoreSchema),
			Colyseus.Schema.Field.new("eventSeq", Colyseus.Schema.UINT32),
			Colyseus.Schema.Field.new("events", Colyseus.Schema.MAP, MatchEventSchema),
			Colyseus.Schema.Field.new("streakCallout", Colyseus.Schema.STRING),
			Colyseus.Schema.Field.new("streakSubtitle", Colyseus.Schema.STRING),
			Colyseus.Schema.Field.new("streakCalloutTicks", Colyseus.Schema.UINT32),
			Colyseus.Schema.Field.new("streakCalloutShutdown", Colyseus.Schema.BOOLEAN),
			Colyseus.Schema.Field.new("effects", Colyseus.Schema.ARRAY, MatchEffectSchema),
		]

	func _to_string() -> String:
		return "MatchStateSchema(__ref_id: %s, tick: %s, time: %s, result: %s, winner: %s, zoneR: %s, shrinking: %s, zoneCX: %s, zoneCY: %s, zonePhase: %s, startCountdown: %s, callout: %s, calloutTicks: %s, wantedSlot: %s, mode: %s, heroes: %s, bullets: %s, covers: %s, crates: %s, crateOrbs: %s, midTower: %s, loot: %s, deployables: %s, zones: %s, knockouts: %s, finishCine: %s, cores: %s, eventSeq: %s, events: %s, streakCallout: %s, streakSubtitle: %s, streakCalloutTicks: %s, streakCalloutShutdown: %s, effects: %s)" % [self.__ref_id, self.tick, self.time, self.result, self.winner, self.zoneR, self.shrinking, self.zoneCX, self.zoneCY, self.zonePhase, self.startCountdown, self.callout, self.calloutTicks, self.wantedSlot, self.mode, self.heroes, self.bullets, self.covers, self.crates, self.crateOrbs, self.midTower, self.loot, self.deployables, self.zones, self.knockouts, self.finishCine, self.cores, self.eventSeq, self.events, self.streakCallout, self.streakSubtitle, self.streakCalloutTicks, self.streakCalloutShutdown, self.effects]

class PlayerSchema extends Colyseus.Schema:
	static func definition():
		return [
			Colyseus.Schema.Field.new("slot", Colyseus.Schema.NUMBER),
			Colyseus.Schema.Field.new("sessionId", Colyseus.Schema.STRING),
			Colyseus.Schema.Field.new("name", Colyseus.Schema.STRING),
			Colyseus.Schema.Field.new("connected", Colyseus.Schema.BOOLEAN),
			Colyseus.Schema.Field.new("packPct", Colyseus.Schema.UINT8),
			Colyseus.Schema.Field.new("characterId", Colyseus.Schema.STRING),
			Colyseus.Schema.Field.new("matchReady", Colyseus.Schema.BOOLEAN),
		]

	func _to_string() -> String:
		return "PlayerSchema(__ref_id: %s, slot: %s, sessionId: %s, name: %s, connected: %s, packPct: %s, characterId: %s, matchReady: %s)" % [self.__ref_id, self.slot, self.sessionId, self.name, self.connected, self.packPct, self.characterId, self.matchReady]

class HeroSchema extends Colyseus.Schema:
	static func definition():
		return [
			Colyseus.Schema.Field.new("slot", Colyseus.Schema.INT8),
			Colyseus.Schema.Field.new("x", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("y", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("aimX", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("aimY", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("hp", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("maxHp", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("alive", Colyseus.Schema.BOOLEAN),
			Colyseus.Schema.Field.new("mag", Colyseus.Schema.UINT8),
			Colyseus.Schema.Field.new("magMax", Colyseus.Schema.UINT8),
			Colyseus.Schema.Field.new("ack", Colyseus.Schema.UINT32),
			Colyseus.Schema.Field.new("animal", Colyseus.Schema.INT8),
		]

	func _to_string() -> String:
		return "HeroSchema(__ref_id: %s, slot: %s, x: %s, y: %s, aimX: %s, aimY: %s, hp: %s, maxHp: %s, alive: %s, mag: %s, magMax: %s, ack: %s, animal: %s)" % [self.__ref_id, self.slot, self.x, self.y, self.aimX, self.aimY, self.hp, self.maxHp, self.alive, self.mag, self.magMax, self.ack, self.animal]

class BulletSchema extends Colyseus.Schema:
	static func definition():
		return [
			Colyseus.Schema.Field.new("id", Colyseus.Schema.UINT32),
			Colyseus.Schema.Field.new("x", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("y", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("vx", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("vy", Colyseus.Schema.FLOAT32),
			Colyseus.Schema.Field.new("owner", Colyseus.Schema.INT8),
			Colyseus.Schema.Field.new("kind", Colyseus.Schema.STRING),
		]

	func _to_string() -> String:
		return "BulletSchema(__ref_id: %s, id: %s, x: %s, y: %s, vx: %s, vy: %s, owner: %s, kind: %s)" % [self.__ref_id, self.id, self.x, self.y, self.vx, self.vy, self.owner, self.kind]

class LobbyState extends Colyseus.Schema:
	static func definition():
		return [
			Colyseus.Schema.Field.new("gameId", Colyseus.Schema.STRING),
			Colyseus.Schema.Field.new("open", Colyseus.Schema.BOOLEAN),
			Colyseus.Schema.Field.new("phase", Colyseus.Schema.STRING),
			Colyseus.Schema.Field.new("hostSessionId", Colyseus.Schema.STRING),
			Colyseus.Schema.Field.new("title", Colyseus.Schema.STRING),
			Colyseus.Schema.Field.new("mode", Colyseus.Schema.STRING),
			Colyseus.Schema.Field.new("seed", Colyseus.Schema.NUMBER),
			Colyseus.Schema.Field.new("createdAtMs", Colyseus.Schema.NUMBER),
			Colyseus.Schema.Field.new("idleUntilSec", Colyseus.Schema.UINT32),
			Colyseus.Schema.Field.new("players", Colyseus.Schema.ARRAY, PlayerSchema),
			Colyseus.Schema.Field.new("matchTick", Colyseus.Schema.UINT32),
			Colyseus.Schema.Field.new("heroes", Colyseus.Schema.MAP, HeroSchema),
			Colyseus.Schema.Field.new("bullets", Colyseus.Schema.MAP, BulletSchema),
			Colyseus.Schema.Field.new("match", Colyseus.Schema.REF, MatchStateSchema),
			Colyseus.Schema.Field.new("loadHeld", Colyseus.Schema.BOOLEAN),
		]

	func _to_string() -> String:
		return "LobbyState(__ref_id: %s, gameId: %s, open: %s, phase: %s, hostSessionId: %s, title: %s, mode: %s, seed: %s, createdAtMs: %s, idleUntilSec: %s, players: %s, matchTick: %s, heroes: %s, bullets: %s, match: %s, loadHeld: %s)" % [self.__ref_id, self.gameId, self.open, self.phase, self.hostSessionId, self.title, self.mode, self.seed, self.createdAtMs, self.idleUntilSec, self.players, self.matchTick, self.heroes, self.bullets, self.match, self.loadHeld]
