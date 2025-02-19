/datum/surgery/advanced/bioware/muscled_veins
	name = "Мышечное усилиние вен"
	desc = "Хирургическая процедура которая добавляет к кровеносным сосудам мышечные мембраны, позволяя им перекачивать кровь без участия сердца."
	steps = list(/datum/surgery_step/incise,
				/datum/surgery_step/retract_skin,
				/datum/surgery_step/clamp_bleeders,
				/datum/surgery_step/incise,
				/datum/surgery_step/incise,
				/datum/surgery_step/muscled_veins,
				/datum/surgery_step/close)
	possible_locs = list(BODY_ZONE_CHEST)
	bioware_target = BIOWARE_CIRCULATION

/datum/surgery_step/muscled_veins
	name = "формирование венозных мышц"
	accept_hand = TRUE
	time = 125

/datum/surgery_step/muscled_veins/preop(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	display_results(user, target, span_notice("Начинаю накручивать мышцы вокруг кровеносной системы [target].") ,
		span_notice("[user] начал накручивать мышцы вокруг кровеносной системы [target].") ,
		span_notice("[user] начал работать с кровеносной системой [target]."))

/datum/surgery_step/muscled_veins/success(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery, default_display_results = FALSE)
	display_results(user, target, span_notice("Изменил кровеносную систему [target], добавив мышечные мембраны!") ,
		span_notice("[user] изменил кровеносную систему [target], добавив мышечные мембраны!") ,
		span_notice("[user] закончил работать с кровеносной системой [target]."))
	new /datum/bioware/muscled_veins(target)
	return ..()

/datum/bioware/muscled_veins
	name = "Сплетенные Вены"
	desc = "Кровеносная система переплетена, что значительно снижает количество теряемой крови при ранении."
	mod_type = BIOWARE_CIRCULATION

/datum/bioware/muscled_veins/on_gain()
	..()
	ADD_TRAIT(owner, TRAIT_STABLEHEART, "muscled_veins")

/datum/bioware/muscled_veins/on_lose()
	..()
	REMOVE_TRAIT(owner, TRAIT_STABLEHEART, "muscled_veins")
