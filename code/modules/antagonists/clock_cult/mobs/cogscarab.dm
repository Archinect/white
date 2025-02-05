GLOBAL_LIST_INIT(cogscarabs, list())

//====Cogscarab====

/mob/living/simple_animal/drone/cogscarab
	name = "Cogscarab"
	desc = "A mechanical device, filled with twisting cogs and mechanical parts, built to maintain Reebe."
	icon_state = "drone_clock"
	icon_living = "drone_clock"
	icon_dead = "drone_clock_dead"
	health = 30
	maxHealth = 30
	faction = list("neutral", "silicon", "turret", "ratvar")
	default_storage = /obj/item/storage/belt/utility/servant/drone
	visualAppearance = "drone_clock"
	bubble_icon = "clock"
	picked = TRUE
	flavortext = "<span class=brass>You are a cogscarab, an intricate machine that has been granted sentient by Rat'var.<br>\
		After a long and destructive conflict, Reebe has been left mostly empty; you and the other cogscarabs like you were bought into existence to construct Reebe into the image of Rat'var.<br>\
		Construct defences, traps and forgeries, for opening the Ark requires an unimaginable amount of power which is bound to get the attention of selfish lifeforms interested only in their own self-preservation.</span>"
	laws = "You are have been granted the gift of sentience from Rat'var.<br>\
		You are not bound by any laws, do whatever you must to serve Rat'var!"
	chat_color = LIGHT_COLOR_CLOCKWORK
	speech_span = "brassmobsay"
	initial_language_holder = /datum/language_holder/clockmob
	discovery_points = 2000

//No you can't go weilding guns like that.
/mob/living/simple_animal/drone/cogscarab/Initialize()
	. = ..()
	ADD_TRAIT(src, TRAIT_NOGUNS, "cogscarab")
	GLOB.cogscarabs += src

/mob/living/simple_animal/drone/cogscarab/death(gibbed)
	GLOB.cogscarabs -= src
	. = ..()

/mob/living/simple_animal/drone/cogscarab/Life(seconds, times_fired)
	if(!is_reebe(z) && !GLOB.ratvar_risen)
		var/turf/T = get_turf(pick(GLOB.servant_spawns))
		try_warp_servant(src, T, FALSE)
	. = ..()

//====Shell====

/obj/effect/mob_spawn/drone/cogscarab
	name = "cogscarab construct"
	desc = "The shell of an ancient construction drone, loyal to Ratvar."
	icon_state = "drone_clock_hat"
	mob_type = /mob/living/simple_animal/drone/cogscarab

/obj/effect/mob_spawn/drone/cogscarab/attack_ghost(mob/user)
	if(is_banned_from(user.ckey, ROLE_SERVANT_OF_RATVAR) || QDELETED(src) || QDELETED(user))
		return
	if(CONFIG_GET(flag/use_age_restriction_for_jobs))
		if(!isnum(user.client.player_age)) //apparently what happens when there's no DB connected. just don't let anybody be a drone without admin intervention
			if(user.client.player_age < 14)
				to_chat(user, span_danger("You're too new to play as a drone! Please try again in [14 - user.client.player_age] days."))
				return
	if(!SSticker.mode)
		to_chat(user, "Can't become a cogscarab before the game has started.")
		return
	var/be_drone = tgui_alert(usr, "Become a cogscarab? (Warning, You can no longer be cloned!)",,"Yes","No")
	if(be_drone == "No" || QDELETED(src) || !isobserver(user))
		return
	var/mob/living/simple_animal/drone/D = new mob_type(get_turf(loc))
	D.flags_1 |= (flags_1 & ADMIN_SPAWNED_1)
	D.key = user.key
	add_servant_of_ratvar(D, silent=TRUE)
	message_admins("[ADMIN_LOOKUPFLW(user)] has taken possession of \a [src] in [AREACOORD(src)].")
	log_game("[key_name(user)] has taken possession of \a [src] in [AREACOORD(src)].")
	qdel(src)
