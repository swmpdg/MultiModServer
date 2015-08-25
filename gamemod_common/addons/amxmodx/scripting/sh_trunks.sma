// Trunks - Armor refills + Equipment Spawn + Stronger Knife

/* CVARS - copy and paste to shconfig.cfg

//Trunks
trunks_level 0
trunks_aps 10
trunks_maxaps 1000
trunks_knifemult 2.0
trunks_knifespeed 300
trunks_cooldown 30
trunks_radius 1000
trunks_maxdamage 100
trunks_blasts_decal 1

*/

/*
Credit goes to:
reaper - armor code, (Steel)
jtp10181 - knife dmg/spd code (Wolverine)
{HOJ} Batman/JTP10181 - swawn weapons (Batman)
sharky - Charge up (Gohan)
buttface / vittu - Blast (Goten) 
AZNdARkEViLdEMON - Blast color suggestion.
*/

/*

1.1 H34D$h0T D3LUX3
- Added a blast

*/

#include <amxmod>
#include <superheromod>

// GLOBAL VARIABLES
new gHeroName[]="Trunks"
new bool:ghasTrunksPowers[SH_MAXSLOTS+1]
new bool:gBlockKeyup[SH_MAXSLOTS+1]
new gLastWeapon[SH_MAXSLOTS+1]
new Beam, Explosion, Smoke
static const burn_decal[3] = {28, 29, 30}
static const burn_decal_big[3] = {46, 47, 48}
//----------------------------------------------------------------------------------------------
public plugin_init()
{
	// Plugin Info
	register_plugin("SUPERHERO Trunks", "1.1", "H34D$H0T!D3LUX3")

	// DO NOT EDIT THIS FILE TO CHANGE CVARS, USE THE SHCONFIG.CFG
	register_cvar("trunks_level", "0")
	register_cvar("trunks_aps", "10")
	register_cvar("trunks_maxaps", "1000")
	register_cvar("trunks_knifespeed", "300")
	register_cvar("trunks_knifemult", "2.0")
	register_cvar("trunks_cooldown", "30")
	register_cvar("trunks_maxdamage", "100")
	register_cvar("trunks_radius", "100")
	register_cvar("trunks_blast_decals", "1")

	// FIRE THE EVENT TO CREATE THIS SUPERHERO!
	shCreateHero(gHeroName, "Armor Refill and Knife Damage", "Gain 10 armor every second, free bombs, and knife damage.", true, "trunks_level")

	// REGISTER EVENTS THIS HERO WILL RESPOND TO! (AND SERVER COMMANDS)
	// INIT
	register_srvcmd("trunks_init", "trunks_init")
	shRegHeroInit(gHeroName, "trunks_init")

	//KEY DOWN
	register_srvcmd("trunks_kd", "trunks_kd")
	shRegKeyDown(gHeroName, "trunks_kd")

	//KEY UP
	register_srvcmd("trunks_ku", "trunks_ku")
	shRegKeyUp(gHeroName, "trunks_ku")

	// KNIFE DAMAGE AND KNIFE SPEED
	shSetMaxSpeed(gHeroName, "trunks_knifespeed", "[29]" )
	register_event("Damage", "trunks_damage", "b", "2!0")

	// HEAL LOOP AND ARMOR LOOP AND RANDOM HITZONE
	set_task(1.0, "trunks_loop", 0, "", 0, "b")
	set_task(1.0, "trunks_armorloop", 0, "", 0, "b")
	set_task(1.0, "trunks_hitzones", 0, "", 0, "b")

	// Let Server know about Armor's Variables
	shSetMaxArmor(gHeroName, "trunks_armor")
}
//----------------------------------------------------------------------------------------------
public trunks_init()
{
	// First Argument is an id
	new temp[6]
	read_argv(1,temp,5)
	new id = str_to_num(temp)

	// 2nd Argument is 0 or 1 depending on whether the id has the hero
	read_argv(2,temp,5)
	new hasPowers = str_to_num(temp)

	//This gets run if they had the power but don't anymore
	if ( !hasPowers && ghasTrunksPowers[id] && is_user_alive(id) ) {
		shRemArmorPower(id)
		shRemSpeedPower(id)
		set_user_hitzones(0, id, 255)
	}

	//Sets this variable to the current status
	ghasTrunksPowers[id] = (hasPowers != 0)
}
//----------------------------------------------------------------------------------------------
public plugin_precache()
{
	Beam = precache_model("sprites/shmod/trunks_trail.spr")
	Explosion = precache_model("sprites/shmod/trunks_explosion.spr")
	Smoke = precache_model("sprites/wall_puff4.spr")
}
//----------------------------------------------------------------------------------------------
public newSpawn(id)
{
	if ( shModActive() && ghasTrunksPowers[id] && is_user_alive(id) ) {
		gPlayerUltimateUsed[id] = false
		set_task(0.1, "trunks_weapons", id)
	}
}
//----------------------------------------------------------------------------------------------
public trunks_weapons(id)
{
	if ( shModActive() && ghasTrunksPowers[id] && is_user_alive(id) ) {
		shGiveWeapon(id, "weapon_hegrenade")
		shGiveWeapon(id, "weapon_flashbang")
		shGiveWeapon(id, "weapon_smokegrenade")
		shGiveWeapon(id, "weapon_nvg")
	}
	// Give CTs a Defuse Kit
	if ( get_user_team(id) == 2 ) shGiveWeapon(id,"item_thighpack")
}
//----------------------------------------------------------------------------------------------
public trunks_loop()
{
	if ( !shModActive() || !hasRoundStarted() ) return

	for ( new id = 1; id <= SH_MAXSLOTS; id++ ) {
		if ( ghasTrunksPowers[id] && is_user_alive(id) ) {
			set_user_armor(id, get_cvar_num("trunks_aps"))
		}
	}
}
//----------------------------------------------------------------------------------------------
public trunks_armorloop()
{
	if ( !shModActive() || !hasRoundStarted() ) return

	for ( new id = 1; id <= SH_MAXSLOTS; id++ ) {
		if ( ghasTrunksPowers[id] && is_user_alive(id) ) {

				new userArmor = get_user_armor(id)
				if ( userArmor < get_cvar_num("trunks_maxaps") ) {
				if (userArmor <= 0) give_item(id, "item_assaultsuit")

				set_user_armor(id, userArmor + get_cvar_num("armor_aps"))
			}
		}
	}
}
//-----------------------------------------------------------------------------------------------
public trunks_hitzones()
{
	if ( !shModActive() || !hasRoundStarted() ) return

	for ( new id = 1; id <= SH_MAXSLOTS; id++ ) {
		if ( ghasTrunksPowers[id] && is_user_alive(id) ) {
			new hitZone
			hitZone = random_num(1, 7)
			switch(hitZone) {
				case 1: set_user_hitzones(0, id, 127)	//remove right leg hitzone
				case 2: set_user_hitzones(0, id, 191)	//remove left leg hitzone
				case 3: set_user_hitzones(0, id, 223)	//remove right arm hitzone
				case 4: set_user_hitzones(0, id, 239)	//remove left arm hitzone
				case 5: set_user_hitzones(0, id, 247)	//remove stomach hitzone
				case 6: set_user_hitzones(0, id, 251)	//remove chest hitzone
				case 7: set_user_hitzones(0, id, 253)	//remove head hitzone
			}
		}
	}
}
//-----------------------------------------------------------------------------------------------
public trunks_damage(id)
{
	if (!shModActive() || !is_user_alive(id)) return PLUGIN_CONTINUE

	new damage = read_data(2)
	new weapon, bodypart, attacker = get_user_attacker(id, weapon, bodypart)
	new headshot = bodypart == 1 ? 1 : 0

	if ( attacker <= 0 || attacker > SH_MAXSLOTS ) return PLUGIN_CONTINUE

	if ( ghasTrunksPowers[attacker] && weapon == CSW_KNIFE && is_user_alive(id) ) {
		// do extra damage
		new extraDamage = floatround(damage * get_cvar_float("trunks_knifemult") - damage)
		if (extraDamage > 0) shExtraDamage( id, attacker, extraDamage, "knife", headshot )
	}
	return PLUGIN_CONTINUE
}
//------------------------------------------------------------------------------------------------
public trunks_kd()
{
	if ( !hasRoundStarted() ) return

	// First Argument is an id
	new temp[6]
	read_argv(1,temp,5)
	new id = str_to_num(temp)

	if ( !is_user_alive(id) || !ghasTrunksPowers[id] ) return

	if ( gPlayerUltimateUsed[id] ) {
		playSoundDenySelect(id)
		gBlockKeyup[id] = true
		return
	}

	gBlockKeyup[id] = false

	// Remember this weapon...
	new clip, ammo, weaponID = get_user_weapon(id, clip, ammo)
	gLastWeapon[id] = weaponID

	// switch to knife
	engclient_cmd(id, "weapon_knife")

	fire_wave(id)

	if (get_cvar_float("trunks_cooldown") > 0.0) ultimateTimer(id, get_cvar_float("trunks_cooldown"))
}
//----------------------------------------------------------------------------------------------
public trunks_ku()
{
	if ( !hasRoundStarted() ) return

	// First Argument is an id
	new temp[6]
	read_argv(1,temp,5)
	new id = str_to_num(temp)

	if ( !is_user_alive(id) || !ghasTrunksPowers[id] || gBlockKeyup[id] ) return

	// Switch back to previous weapon...
	// Use keyup since if called too fast CurWeapon functions may be bypassed
	if (gLastWeapon[id] != CSW_KNIFE) shSwitchWeaponID(id, gLastWeapon[id])
}
//----------------------------------------------------------------------------------------------
public fire_wave(id)
{
	new aimvec[3]
	new FFOn = get_cvar_num("mp_friendlyfire")

	new Float:dRatio, damage, distanceBetween
	new damradius = get_cvar_num("trunks_radius")
	new maxdamage = get_cvar_num("trunks_maxdamage")

	if( !is_user_alive(id) ) return

	get_user_origin(id, aimvec, 3)
	beam_effects(id, aimvec, damradius)

	for(new vic = 1; vic <= SH_MAXSLOTS; vic++)
	{
		if ( is_user_alive(vic) && ( get_user_team(id) != get_user_team(vic) || FFOn || vic == id ) ) {

			new origin[3]
			get_user_origin(vic, origin)
			distanceBetween = get_distance(aimvec, origin)

			if ( distanceBetween < damradius ) {

				dRatio = float(distanceBetween) / float(damradius)
				damage = maxdamage - floatround(maxdamage * dRatio)

				// Lessen damage taken by self
				if (vic == id) damage = floatround(damage / 2.0)

				shExtraDamage(vic, id, damage, "Trunks Blast")
			}
		}
	}
}
//----------------------------------------------------------------------------------------------
public beam_effects(id, aimvec[3], damradius)
{
	new decal_id, beamWidth

	//Change sprite size according to blast radius
	new blastSize = floatround(damradius / 12.0)

	//Change burn decal and beam width size according to blast size
	if (blastSize <= 18) {
		decal_id = burn_decal[random_num(0, 2)]
		beamWidth = 50
	}
	else {
		decal_id = burn_decal_big[random_num(0, 2)]
		beamWidth = 75
	}

	//Beam
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(1)			//TE_BEAMENTPOINTS
	write_short(id)		//ent
	write_coord(aimvec[0])	//position
	write_coord(aimvec[1])
	write_coord(aimvec[2])
	write_short(Beam)	// sprite index
	write_byte(0)		// start frame
	write_byte(35)		// framerate
	write_byte(4)		// life
	write_byte(beamWidth)	// width
	write_byte(0)		// noise
	write_byte(0)	// red (rgb color)
	write_byte(255)	// green (rgb color)
	write_byte(0)	// blue (rgb color)
	write_byte(255)	// brightness
	write_byte(20)		// speed
	message_end()

	//Glow Sprite (explosion)
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(23)			//TE_GLOWSPRITE
	write_coord(aimvec[0])	//position
	write_coord(aimvec[1])
	write_coord(aimvec[2])
	write_short(Explosion)	// model
	write_byte(001)		// life 0.x sec (01 min limit?)
	write_byte(blastSize)	// size
	write_byte(255)		// brightness
	message_end()

	//Explosion (smoke, sound/effects)
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(3)			//TE_EXPLOSION
	write_coord(aimvec[0])	//pos
	write_coord(aimvec[1])
	write_coord(aimvec[2])
	write_short(Smoke)		// model
	write_byte(blastSize+5)	// scale in 0.1's
	write_byte(20)			// framerate
	write_byte(10)			// flags
	message_end()

	//Burn Decals
	if(get_cvar_num("trunks_blast_decals") == 1) {
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(109)		//TE_GUNSHOTDECAL
		write_coord(aimvec[0])	//pos
		write_coord(aimvec[1])
		write_coord(aimvec[2])
		write_short(0)			//?
		write_byte(decal_id)	//decal
		message_end()
	}
}
//----------------------------------------------------------------------------------------------