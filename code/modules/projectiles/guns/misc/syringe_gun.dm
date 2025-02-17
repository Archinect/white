/obj/item/gun/syringe
	name = "шприцевой пистолет"
	desc = "Пружинное оружие сконструированное для заряда шприцов, используется для выведения неуправляемых пациентов на расстоянии."
	icon_state = "syringegun"
	inhand_icon_state = "syringegun"
	w_class = WEIGHT_CLASS_NORMAL
	throw_speed = 3
	throw_range = 7
	force = 4
	custom_materials = list(/datum/material/iron=2000)
	clumsy_check = FALSE
	fire_sound = 'sound/items/syringeproj.ogg'
	var/load_sound = 'sound/weapons/gun/shotgun/insert_shell.ogg'
	var/list/syringes = list()
	var/max_syringes = 1 ///The number of syringes it can store.
	var/has_syringe_overlay = TRUE ///If it has an overlay for inserted syringes. If true, the overlay is determined by the number of syringes inserted into it.

/obj/item/gun/syringe/Initialize()
	. = ..()
	chambered = new /obj/item/ammo_casing/syringegun(src)
	recharge_newshot()

/obj/item/gun/syringe/handle_atom_del(atom/A)
	. = ..()
	if(A in syringes)
		syringes.Remove(A)

/obj/item/gun/syringe/recharge_newshot()
	if(!syringes.len)
		return
	chambered.newshot()

/obj/item/gun/syringe/can_shoot()
	return syringes.len

/obj/item/gun/syringe/process_chamber()
	if(chambered && !chambered.BB) //we just fired
		recharge_newshot()
	update_icon()

/obj/item/gun/syringe/examine(mob/user)
	. = ..()
	. += "<hr>Can hold [max_syringes] syringe\s. Has [syringes.len] syringe\s remaining."

/obj/item/gun/syringe/attack_self(mob/living/user)
	if(!syringes.len)
		to_chat(user, span_warning("[capitalize(src.name)] пуст!"))
		return FALSE

	var/obj/item/reagent_containers/syringe/S = syringes[syringes.len]

	if(!S)
		return FALSE
	user.put_in_hands(S)

	syringes.Remove(S)
	to_chat(user, span_notice("Вытащил [S] из <b>[src.name]</b>."))
	update_icon()

	return TRUE

/obj/item/gun/syringe/attackby(obj/item/A, mob/user, params, show_msg = TRUE)
	if(istype(A, /obj/item/reagent_containers/syringe/bluespace))
		to_chat(user, span_notice("[A] слишком большой и не помещается в [src]."))
		return TRUE
	if(istype(A, /obj/item/reagent_containers/syringe))
		if(syringes.len < max_syringes)
			if(!user.transferItemToLoc(A, src))
				return FALSE
			to_chat(user, span_notice("Зарядил [A] в <b>[src.name]</b>."))
			syringes += A
			recharge_newshot()
			update_icon()
			playsound(loc, load_sound, 40)
			return TRUE
		else
			to_chat(user, span_warning("В [capitalize(src.name)] не поместятся еще шприцы!"))
	return FALSE

/obj/item/gun/syringe/update_overlays()
	. = ..()
	if(!has_syringe_overlay)
		return
	var/syringe_count = syringes.len
	. += "[initial(icon_state)]_[syringe_count ? clamp(syringe_count, 1, initial(max_syringes)) : "empty"]"

/obj/item/gun/syringe/rapidsyringe
	name = "многозарядный шприцевой пистолет"
	desc = "Модификация шприцевого пистолета с использованием вращающегося барабана, способного вместить до шести шприцов."
	icon_state = "rapidsyringegun"
	max_syringes = 6

/obj/item/gun/syringe/syndicate
	name = "дротикомет"
	desc = "Небольшой пружинный пистолет, по принципу работы идентичный шприцевому пистолету."
	icon_state = "syringe_pistol"
	inhand_icon_state = "gun" //Smaller inhand
	w_class = WEIGHT_CLASS_SMALL
	force = 2 //Also very weak because it's smaller
	suppressed = TRUE //Softer fire sound
	can_unsuppress = FALSE //Permanently silenced
	syringes = list(new /obj/item/reagent_containers/syringe())

/obj/item/gun/syringe/dna
	name = "модифицированный шприцевой пистолет"
	desc = "Шприцевой пистолет модифицированный для использования инжекторов ДНК, вместо обычных шприцов."

/obj/item/gun/syringe/dna/Initialize()
	. = ..()
	chambered = new /obj/item/ammo_casing/dnainjector(src)

/obj/item/gun/syringe/dna/attackby(obj/item/A, mob/user, params, show_msg = TRUE)
	if(istype(A, /obj/item/dnainjector))
		var/obj/item/dnainjector/D = A
		if(D.used)
			to_chat(user, span_warning("Данный инжектор израсходован!"))
			return
		if(syringes.len < max_syringes)
			if(!user.transferItemToLoc(D, src))
				return FALSE
			to_chat(user, span_notice("Зарядил [D] в <b>[src.name]</b>."))
			syringes += D
			recharge_newshot()
			return TRUE
		else
			to_chat(user, span_warning("[capitalize(src.name)] не вместит больше шприцов!"))
	return FALSE

/obj/item/gun/syringe/blowgun
	name = "blowgun"
	desc = "Стреляет шприцами на небольшой дистанции."
	icon_state = "blowgun"
	inhand_icon_state = "blowgun"
	has_syringe_overlay = FALSE
	fire_sound = 'sound/items/syringeproj.ogg'

/obj/item/gun/syringe/blowgun/process_fire(atom/target, mob/living/user, message = TRUE, params = null, zone_override = "", bonus_spread = 0)
	visible_message(span_danger("[user] прицеливается своим blowgun!"))
	if(do_after(user, 25, target = src))
		user.adjustStaminaLoss(20)
		user.adjustOxyLoss(20)
		return ..()
