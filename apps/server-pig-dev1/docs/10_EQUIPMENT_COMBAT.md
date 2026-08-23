# Equipment Combat Pass

## Match Flow

1. A shared three-second countdown freezes every human and CPU player.
2. Six of twelve complete weapon-careers are shuffled and dealt without duplicates, so each match exposes a different tactical field.
3. Left mouse fires the dealt equipment's normal attack. Damage, cadence, projectile count, reach, splash, drain, and preferred range can differ.
4. Right mouse uses the dealt equipment attack when its cooldown is ready.
5. Confirmed normal and equipment hits fill the ultimate meter. Q spends a full meter.
6. Cover blocks both movement and projectiles. CPUs detect blocked sightlines and flank.
7. A core is locked while its owner is active. It becomes exposed only while that hero is downed, cursed, slowed, or staggered by CC.
8. Rail, mortar, and breaker attacks create explicit CC windows for coordinated core focus. Exposed core hits deal 15% bonus damage so a short opening produces visible progress.
9. A downed hero waits ten seconds before returning. The HUD and world view both show the punish window while the core stays exposed.
10. When a long match reaches sudden death, the weakest core owner is repeatedly CC-exposed before collapse. Earlier damage remains meaningful.
11. Projectiles and delayed zones use the same exposed-core gate, so every equipment skill and ultimate can convert a confirmed down or CC opening into core damage.
12. Knockback creates a high-speed launched state instead of teleporting the target. A launched hero can reflect from arena walls or visible cover up to three times, taking 15-36 collision damage at every bounce.
13. A down keeps the fast 2.15-second impact trajectory, but the only centered status copy is `P# CHARACTER님이 쓰러졌습니다.`; core-state instructions are intentionally omitted.
14. No core can be eliminated before 15 seconds; early damage still reduces it to 1 HP and creates a dangerous follow-up state.
15. Four health pickups occupy fixed mirrored contest points at north center (1400, 430), south center (1400, 1270), west lane (760, 850), and east lane (2040, 850). Each restores 30% maximum HP and respawns at the same point after 16 seconds.

## Mobility And Combat Readability

- Space activates one career-specific mobility action: SKIRMISH HOP, SIGHTLINE STEP, BLAST HOP, SHADOW PULL, IRON MARCH, FLASH CUT, SHADOW SHEATH, WEAVE, BLAST ROLL, POLE VAULT, SWING STEP, or BRACE STEP.
- A ready mobility action breaks an active combo, clears hit-stun, and grants a short combo-immunity window. Its cooldown and travel still pay for guard, sustain, damage, or evasion benefits.
- Health pads remain visible while depleted and display their respawn countdown. CPUs seek an available pad according to missing health and distance instead of ignoring the recovery economy.
- Rail shots render as a long bright streak with a white core, explosions darken and saturate before expanding, drain effects spiral inward, and shockwaves use spokes rather than a generic circle.
- The HUD lists both normal and skill reach, the mobility identity/cooldown, and the wall-bounce rule. F1 still cycles compact, full, and hidden HUD modes.

## Camera, Identity, And Spectating

- The live camera adds aim and velocity look-ahead instead of pinning the player to screen center.
- Camera zoom widens automatically when several fighters enter the same local fight and widens further while spectating.
- Shake is attenuated by distance from the viewed fight, so off-screen hits do not disrupt aiming.
- Each equipment maps to a named combatant and role. The roster is REX/BRAWLER, SCOPE/SNIPER, BOMBI/CONTROLLER, NYX/DRAINER, BRICK/VANGUARD, ZIP/HUNTER, AKARI/ASSASSIN, MACK/STRIKER, MIMI/TRICKSTER, ORIN/LANCER, RIVA/TRAPPER, and WARD/GUARDIAN.
- Combatants use twelve weapon-readable world-space silhouettes and always show character, player number, role, and equipment under the body.
- While P1 is downed or eliminated, the camera automatically follows the highest-scoring living opponent. A/D or Tab cycles living targets; Space returns to the current leader.
- Eliminated P1 can keep the followed fight on screen and use the existing click curse from spectator view.

## HUD And Score

- F1 cycles compact HUD, full statistics, and hidden HUD. Compact is the default and occupies only 665 x 104 logical pixels.
- Critical countdown, respawn, spectating, and result information remains visible in every HUD mode.
- The full scoreboard sorts all six players by score and shows character, equipment, downs, deaths, remaining core HP, and live/down/CC/out state.
- Score formula: hero damage + 1.5 x core damage + 120 per down + 300 per core elimination + 500 for winning.

## Balance Contract

- Equipment defines the complete character tactic: normal attack, equipment attack, preferred range, and ultimate pattern.
- Careers define different maximum HP, movement speed, launch weight, combo damage cap, and passive. The spread ranges from AKARI's fast evade assassin to WARD's slow, high-HP launch-resistant guardian.
- Confirmed hits chain for 1.05 seconds, but launch timing comes from the career's authored normal string rather than a universal third hit. The final beat ends the string with a fast directional launch. One uninterrupted string is capped at 38-50% of the victim's maximum HP, including follow-up wall collisions.
- A full-health fighter cannot die to one combo. Fragile careers normally fall in two clean combos and heavy careers in three, while prior damage can make the next combo lethal.
- Holding RMB cancels normal recovery and charges the career skill for up to 1.15 seconds. Release strength scales its reach, area, damage, control, and launch. Q or Space can cancel normal recovery or an unfinished charge immediately.
- Shotgun, sniper, and dual pistols are the only projectile normal attacks. Every other career pays through direct weapon reach, body commitment, delayed placement, or recovery cadence.
- Ultimate attacks cannot recharge themselves.
- Protected cores absorb projectiles without taking damage or granting ultimate charge.
- No career may win more than 14 of the deterministic 60-match balance sample.
- All twelve careers must win in that sample.
- Every equipment type must land confirmed hits.
- Average completion target: 40 to 105 seconds.
- Earliest elimination target: 12 seconds or later.
- Three-CPU focus target: no longer than seven continuous seconds.

## Normal Attack Identities

- SCATTERGUN: four beats - blast, blast, quick double blast, planted heavy blast.
- RAIL LANCE: three beats - marking shot, settling shot, long-recovery execution shot.
- CLUSTER MORTAR: three direct placements - two quick charges and one larger delayed cluster.
- LEECH CORE: four direct hook lashes ending in a hard inward pull.
- BREACH HAMMER: three committed swings ending in a floor-breaking smash.
- BURST RACK: five alternating pistol beats ending in a three-round finish.
- MOON KATANA: four advancing cuts - left, right, rising, then draw finish.
- BARE KNUCKLES: five rapid body blows followed by one planted finishing punch.
- BOMB SATCHEL: two quick fuses followed by a larger delayed finish.
- SUN SPEAR: four thrusts with increasing reach and a committed impale.
- CHAIN SICKLE: three capture lashes followed by a heavy inward whip.
- TOWER SHIELD: check, drive, then full-body bash.

## Skill And Ultimate Identities

- SCATTERGUN: BACKBLAST recoils away after a cone launch; ROOM CLEARER dashes into a radial knockback burst.
- RAIL LANCE: ANCHOR BREAK pierces and launches a line; DEADLINE warns, then detonates three separated rail strikes.
- CLUSTER MORTAR: SKYFALL creates a readable delayed blast; NO SAFE PLACE overlaps five staggered danger zones.
- LEECH CORE: BLOOD HARPOON pulls one victim and heals; BLOOD AUCTION pulls and drains in three expanding pulses.
- BREACH HAMMER: CRASH ENTRY commits to a dash shockwave; TABLE FLIP has a long tell and the strongest launch in the game.
- BURST RACK: SEEKER SALVO bends three missiles around evasive movement; HUNTER STORM releases twelve homing rockets.
- MOON KATANA: CROSS STEP cuts through a line; THOUSANDTH EDGE layers rapid crossing blade trails.
- BARE KNUCKLES: LIVER SHOT creates a tight confirm; TEN COUNT traps victims in a readable finishing barrage.
- BOMB SATCHEL: STICKY PRESENT marks a delayed blast; CHAIN REACTION links several expanding detonations.
- SUN SPEAR: VAULT IMPALE repositions through a piercing strike; DRAGON LINE controls a long lane.
- CHAIN SICKLE: SNATCH drags one target into combo range; BLACK CAROUSEL sweeps a wide chain vortex.
- TOWER SHIELD: NO PASSAGE bashes and denies a corridor; LAST ONE STANDING creates a durable close-range holdout.
- Every skill and ultimate publishes its name and one-line effect in the HUD. Cast lines, danger zones, hit rings, camera shake, local hit-stop, procedural impact audio, CC rings, pull/launch movement, and down callouts make outcomes readable without external instructions.

## Current Deterministic Sample

- Runs: 60 completed
- Average duration: 104.81 seconds
- Earliest elimination: 19.73 seconds
- Longest three-CPU focus: 1.23 seconds
- Ultimate uses: 528
- Career wins in data order: 6, 8, 5, 6, 2, 5, 2, 5, 2, 8, 3, 8
