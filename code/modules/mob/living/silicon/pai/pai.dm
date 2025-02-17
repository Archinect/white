/mob/living/silicon/pai
	name = "пИИ"
	icon = 'icons/mob/pai.dmi'
	icon_state = "repairbot"
	mouse_opacity = MOUSE_OPACITY_ICON
	density = FALSE
	hud_type = /datum/hud/pai
	pass_flags = PASSTABLE | PASSMOB
	mob_size = MOB_SIZE_TINY
	desc = "Обычный миниатюрный карманный ИИ с голографическим проектором. Этот выключен."
	weather_immunities = list(WEATHER_ASH)
	health = 500
	maxHealth = 500
	layer = BELOW_MOB_LAYER
	can_be_held = TRUE
	move_force = 0
	pull_force = 0
	move_resist = 0
	worn_slot_flags = ITEM_SLOT_HEAD
	held_lh = 'icons/mob/pai_item_lh.dmi'
	held_rh = 'icons/mob/pai_item_rh.dmi'
	head_icon = 'icons/mob/pai_item_head.dmi'
	radio = /obj/item/radio/headset/silicon/pai
	can_buckle_to = FALSE
	mobility_flags = MOBILITY_FLAGS_REST_CAPABLE_DEFAULT
	var/network = "ss13"
	var/obj/machinery/camera/current = null

	var/ram = 100	// Used as currency to purchase different abilities
	var/list/software = list()
	var/userDNA		// The DNA string of our assigned user
	var/obj/item/paicard/card	// The card we inhabit
	var/hacking = FALSE		//Are we hacking a door?

	var/speakStatement = "констатирует"
	var/speakExclamation = "объявляет"
	var/speakDoubleExclamation = "тревожит"
	var/speakQuery = "запрашивает"

	var/obj/item/pai_cable/hacking_cable		// The cable we produce when hacking a door

	var/master				// Name of the one who commands us
	var/master_dna			// DNA string for owner verification

// Various software-specific vars

	var/temp				// General error reporting text contained here will typically be shown once and cleared
	var/screen				// Which screen our main window displays
	var/subscreen			// Which specific function of the main screen is being displayed

	var/secHUD = 0			// Toggles whether the Security HUD is active or not
	var/medHUD = 0			// Toggles whether the Medical  HUD is active or not

	var/datum/data/record/medicalActive1		// Datacore record declarations for record software
	var/datum/data/record/medicalActive2

	var/datum/data/record/securityActive1		// Could probably just combine all these into one
	var/datum/data/record/securityActive2

	var/obj/machinery/door/hackdoor		// The airlock being hacked
	var/hackprogress = 0				// Possible values: 0 - 100, >= 100 means the hack is complete and will be reset upon next check

	var/obj/item/assembly/signaler/internal/signaler // AI's signaler

	var/obj/item/instrument/piano_synth/internal_instrument
	var/obj/machinery/newscaster			//pAI Newscaster
	var/obj/item/healthanalyzer/hostscan				//pAI healthanalyzer

	var/encryptmod = FALSE
	var/holoform = FALSE
	var/canholo = TRUE
	var/can_transmit = TRUE
	var/can_receive = TRUE
	var/chassis = "repairbot"
	var/list/possible_chassis = list("cat" = TRUE, "mouse" = TRUE, "monkey" = TRUE, "corgi" = FALSE, "fox" = FALSE, "repairbot" = TRUE, "rabbit" = TRUE, "bat" = FALSE, "butterfly" = FALSE, "hawk" = FALSE, "lizard" = FALSE, "duffel" = TRUE)		//assoc value is whether it can be picked up.

	var/emitterhealth = 20
	var/emittermaxhealth = 20
	var/emitter_regen_per_second = 1.25
	var/emittercd = 50
	var/emitteroverloadcd = 100
	var/emittersemicd = FALSE

	var/overload_ventcrawl = 0
	var/overload_bulletblock = 0	//Why is this a good idea?
	var/overload_maxhealth = 0
	var/silent = FALSE
	var/brightness_power = 5

/mob/living/silicon/pai/add_sensors() //pAIs have to buy their HUDs
	return

/mob/living/silicon/pai/handle_atom_del(atom/A)
	if(A == hacking_cable)
		hacking_cable = null
		if(!QDELETED(card))
			card.update_icon()
	if(A == internal_instrument)
		internal_instrument = null
	if(A == newscaster)
		newscaster = null
	if(A == signaler)
		signaler = null
	if(A == hostscan)
		hostscan = null
	return ..()

/mob/living/silicon/pai/Destroy()
	QDEL_NULL(internal_instrument)
	QDEL_NULL(hacking_cable)
	QDEL_NULL(newscaster)
	QDEL_NULL(signaler)
	QDEL_NULL(hostscan)
	if(!QDELETED(card) && loc != card)
		card.forceMove(drop_location())
		card.pai = null //these are otherwise handled by paicard/handle_atom_del()
		card.emotion_icon = initial(card.emotion_icon)
		card.update_icon()
	GLOB.pai_list -= src
	return ..()

/mob/living/silicon/pai/Initialize()
	var/obj/item/paicard/P = loc
	START_PROCESSING(SSfastprocess, src)
	GLOB.pai_list += src
	make_laws()
	if(!istype(P)) //when manually spawning a pai, we create a card to put it into.
		var/newcardloc = P
		P = new /obj/item/paicard(newcardloc)
		P.setPersonality(src)
	forceMove(P)
	card = P
	job = "Personal AI"
	signaler = new /obj/item/assembly/signaler/internal(src)
	hostscan = new /obj/item/healthanalyzer(src)
	newscaster = new /obj/machinery/newscaster(src)
	if(!aicamera)
		aicamera = new /obj/item/camera/siliconcam/ai_camera(src)
		aicamera.flash_enabled = TRUE

	addtimer(CALLBACK(src, .proc/pdaconfig), 5)

	. = ..()

	emittersemicd = TRUE
	addtimer(CALLBACK(src, .proc/emittercool), 600)

	if(!holoform)
		ADD_TRAIT(src, TRAIT_IMMOBILIZED, PAI_FOLDED)
		ADD_TRAIT(src, TRAIT_HANDS_BLOCKED, PAI_FOLDED)


/mob/living/silicon/pai/proc/pdaconfig()
	//PDA
	aiPDA = new/obj/item/pda/ai(src)
	aiPDA.owner = real_name
	aiPDA.ownjob = "Мессенджер пИИ"
	aiPDA.name = real_name + " (" + aiPDA.ownjob + ")"

/mob/living/silicon/pai/proc/process_hack(delta_time, times_fired)


	if(hacking_cable && hacking_cable.machine && istype(hacking_cable.machine, /obj/machinery/door) && hacking_cable.machine == hackdoor && get_dist(src, hackdoor) <= 1)
		hackprogress = clamp(hackprogress + (2 * delta_time), 0, 100)
	else
		temp = "Взломщик дверей: Соединение с шлюзом потеряно. Взлом прерван."
		hackprogress = 0
		hacking = FALSE
		hackdoor = null
		QDEL_NULL(hacking_cable)
		if(!QDELETED(card))
			card.update_icon()
		return
	if(screen == "doorjack" && subscreen == 0) // Update our view, if appropriate
		paiInterface()
	if(hackprogress >= 100)
		hackprogress = 0
		var/obj/machinery/door/D = hacking_cable.machine
		D.open()
		hacking = FALSE

/mob/living/silicon/pai/make_laws()
	laws = new /datum/ai_laws/pai()
	return TRUE

/mob/living/silicon/pai/Login()
	. = ..()
	if(!. || !client)
		return FALSE

	client.perspective = EYE_PERSPECTIVE
	if(holoform)
		client.eye = src
	else
		client.eye = card

/mob/living/silicon/pai/get_status_tab_items()
	. += ..()
	if(!stat)
		. += text("Состояние проектора: [emitterhealth * (100/emittermaxhealth)]")
	else
		. += text("Системы деактивированы")


// See software.dm for Topic()

/mob/living/silicon/pai/canUseTopic(atom/movable/M, be_close=FALSE, no_dexterity=FALSE, no_tk=FALSE, need_hands = FALSE, floor_okay=FALSE)
	return TRUE

/mob/proc/makePAI(delold)
	var/obj/item/paicard/card = new /obj/item/paicard(get_turf(src))
	var/mob/living/silicon/pai/pai = new /mob/living/silicon/pai(card)
	pai.key = key
	pai.name = name
	card.setPersonality(pai)
	if(delold)
		qdel(src)

/datum/action/innate/pai
	name = "Действия пИИ"
	icon_icon = 'icons/mob/actions/actions_silicon.dmi'
	var/mob/living/silicon/pai/P

/datum/action/innate/pai/Trigger()
	if(!ispAI(owner))
		return 0
	P = owner

/datum/action/innate/pai/software
	name = "Программный Интерфейс"
	button_icon_state = "pai"
	background_icon_state = "bg_tech"

/datum/action/innate/pai/software/Trigger()
	..()
	P.paiInterface()

/datum/action/innate/pai/shell
	name = "Переключить Голоформу"
	button_icon_state = "pai_holoform"
	background_icon_state = "bg_tech"

/datum/action/innate/pai/shell/Trigger()
	..()
	if(P.holoform)
		P.fold_in(0)
	else
		P.fold_out()

/datum/action/innate/pai/chassis
	name = "Изменить композицию голограммы"
	button_icon_state = "pai_chassis"
	background_icon_state = "bg_tech"

/datum/action/innate/pai/chassis/Trigger()
	..()
	P.choose_chassis()

/datum/action/innate/pai/rest
	name = "Лежать"
	button_icon_state = "pai_rest"
	background_icon_state = "bg_tech"

/datum/action/innate/pai/rest/Trigger()
	..()
	P.toggle_resting()

/datum/action/innate/pai/light
	name = "Переключить фонарик"
	icon_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "emp"
	background_icon_state = "bg_tech"

/datum/action/innate/pai/light/Trigger()
	..()
	P.toggle_integrated_light()

/mob/living/silicon/pai/Process_Spacemove(movement_dir = 0)
	. = ..()
	if(!.)
		add_movespeed_modifier(/datum/movespeed_modifier/pai_spacewalk)
		return TRUE
	remove_movespeed_modifier(/datum/movespeed_modifier/pai_spacewalk)
	return TRUE

/mob/living/silicon/pai/examine(mob/user)
	. = ..()
	. += "<hr>Персональный ИИ в голографической проекции. ID мастера указывает на [master]."

/mob/living/silicon/pai/Life(delta_time = SSMOBS_DT, times_fired)
	. = ..()
	if(QDELETED(src) || stat == DEAD)
		return
	if(hacking_cable)
		if(get_dist(src, hacking_cable) > 1)
			var/turf/T = get_turf(src)
			T.visible_message(span_warning("[hacking_cable] быстро втягивается обратно.") , span_hear("Слышу щелчок и быстрое сворачивание кабеля."))
			QDEL_NULL(hacking_cable)
			if(!QDELETED(card))
				card.update_icon()
		else if(hacking)
			process_hack(delta_time, times_fired)
	silent = max(silent - (0.5 * delta_time), 0)

/mob/living/silicon/pai/updatehealth()
	if(status_flags & GODMODE)
		return
	set_health(maxHealth - getBruteLoss() - getFireLoss())
	update_stat()

/mob/living/silicon/pai/process(delta_time)
	emitterhealth = clamp((emitterhealth + (emitter_regen_per_second * delta_time)), -50, emittermaxhealth)

/mob/living/silicon/pai/can_interact_with(atom/A)
	if(A == signaler) // Bypass for signaler
		return TRUE

	return ..()

/obj/item/paicard/attackby(obj/item/used, mob/user, params)
	if(pai && (istype(used, /obj/item/encryptionkey) || used.tool_behaviour == TOOL_SCREWDRIVER))
		if(!pai.encryptmod)
			to_chat(user, span_alert("Порт ключей шифрования не настроен."))
			return
		user.set_machine(src)
		pai.radio.attackby(used, user, params)
		to_chat(user, span_notice("You insert [used] into the [src]."))
		return

	return ..()

/obj/item/paicard/emag_act(mob/user) // Emag to wipe the master DNA and supplemental directive
	if(!pai)
		return
	to_chat(user, "<span class='notice'>You override [pai]'s directive system, clearing its master string and supplied directive.</span>")
	to_chat(pai, "<span class='danger'>Warning: System override detected, check directive sub-system for any changes.'</span>")
	log_game("[key_name(user)] emagged [key_name(pai)], wiping their master DNA and supplemental directive.")
	pai.master = null
	pai.master_dna = null
	pai.laws.supplied[1] = "None." // Sets supplemental directive to this