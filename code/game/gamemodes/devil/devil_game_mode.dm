/datum/game_mode/devil
	name = "devil"
	config_tag = "devil"
	report_type = "devil"
	role_preference = /datum/role_preference/antagonist/devil
	antag_datum = /datum/antagonist/devil
	false_report_weight = 1
	protected_jobs = list(JOB_NAME_LAWYER, JOB_NAME_CURATOR, JOB_NAME_CHAPLAIN, JOB_NAME_HEADOFSECURITY, JOB_NAME_CAPTAIN, JOB_NAME_AI, JOB_NAME_CYBORG, JOB_NAME_SECURITYOFFICER, JOB_NAME_WARDEN, JOB_NAME_DETECTIVE)
	required_players = 0
	required_enemies = 1
	recommended_enemies = 4
	reroll_friendly = 1
	title_icon = "devil"

	allowed_special = list(/datum/special_role/traitor)

	var/traitors_possible = 4 //hard limit on devils if scaling is turned off
	var/num_modifier = 0 // Used for gamemodes, that are a child of traitor, that need more than the usual.
	var/objective_count = 2
	var/minimum_devils = 1

	announce_text = "There are devils onboard the station!\n\
		+	<span class='danger'>Devils</span>: Purchase souls and tempt the crew to sin!\n\
		+	<span class='notice'>Crew</span>: Resist the lure of sin and remain pure!"

/datum/game_mode/devil/pre_setup()
	if(CONFIG_GET(flag/protect_roles_from_antagonist))
		restricted_jobs += protected_jobs
	if(CONFIG_GET(flag/protect_assistant_from_antagonist))
		restricted_jobs += JOB_NAME_ASSISTANT
	if(CONFIG_GET(flag/protect_heads_from_antagonist))
		restricted_jobs += GLOB.command_positions

	var/num_devils = 1

	var/tsc = CONFIG_GET(number/traitor_scaling_coeff)
	if(tsc)
		num_devils = max(minimum_devils, min( round(num_players() / (tsc * 3))+ 2 + num_modifier, round(num_players() / (tsc * 1.5)) + num_modifier))
	else
		num_devils = max(minimum_devils, min(num_players(), traitors_possible))

	for(var/j = 0, j < num_devils, j++)
		if (!antag_candidates.len)
			break
		var/datum/mind/devil = antag_pick(antag_candidates, /datum/role_preference/antagonist/devil)
		devils += devil
		devil.special_role = traitor_name
		devil.restricted_roles = restricted_jobs

		log_game("[key_name(devil)] has been selected as a [traitor_name]")
		antag_candidates.Remove(devil)

	if(devils.len < required_enemies)
		setup_error = "Not enough devil candidates"
		return 0
	return 1


/datum/game_mode/devil/post_setup()
	for(var/datum/mind/devil in devils)
		post_setup_finalize(devil)
	..()
	return 1

/datum/game_mode/devil/generate_report()
	return "W pobliżu stacji wykryto piekielne kreatury oferujące załodze wielkie korzyści w zamian za ich dusze. Chcemy uprzejmie przypomnieć, że sprzedaż duszy jest wliczana jako kradzież własności firmy Nanotrasen, wszyscy pracownicy zrzekli się posiadania duszy na rzecz Nanotrasen w umowie o pracę. Jeżeli ktokolwiek przez przypadek sprzeda swoją duszę, proszę skontaktować się z lokalnym prawnikiem, aby unieważnić umowę sprzedaży. Uwaga, piekielne stworzenia po uzyskaniu wystarczającej ilości dusz otworzą drzwi do piekła, zostaliście ostrzeżeni."

/datum/game_mode/devil/proc/post_setup_finalize(datum/mind/devil)
	add_devil(devil.current, ascendable = TRUE) //Devil gamemode devils are ascendable.
	add_devil_objectives(devil,2)

/proc/is_devil(mob/living/M)
	return M?.mind?.has_antag_datum(/datum/antagonist/devil)

/proc/add_devil(mob/living/L, ascendable = FALSE)
	if(!L || !L.mind)
		return FALSE
	var/datum/antagonist/devil/devil_datum = L.mind.add_antag_datum(/datum/antagonist/devil)
	devil_datum.ascendable = ascendable
	return devil_datum

/proc/remove_devil(mob/living/L)
	if(!L || !L.mind)
		return FALSE
	var/datum/antagonist/devil_datum = L.mind.has_antag_datum(/datum/antagonist/devil)
	devil_datum.on_removal()
	return TRUE

/datum/game_mode/devil/generate_credit_text()
	var/list/round_credits = list()
	var/len_before_addition

	round_credits += "<center><h1>Kuszące Diabły:</h1>"
	len_before_addition = round_credits.len
	var/datum/antagonist/devil/devil_info
	for(var/datum/mind/devil in devils)
		devil_info = devil.has_antag_datum(/datum/antagonist/devil)
		if(devil_info) // This should never fail, but better to be sure
			round_credits += "<center><h2>[devil_info.truename] w postaci [devil.name]</h2>"
			devil_info = null
	if(len_before_addition == round_credits.len)
		round_credits += list("<center><h2>Wszystkie diabły zostały kompletnie zniszczone!</h2>", "<center><h2>Miłość kosmicznego Jezusa znowu górą!</h2>")
	round_credits += "<br>"

	round_credits += ..()
	return round_credits
