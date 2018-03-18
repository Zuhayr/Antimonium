// These are included in Debug verbs for the sake of not making a whole new category. Tick
// this file only if you want to use the procs, there's zero reason to use it on a live server.

/datum/admin_permissions/debug/New()
	verbs |= /client/proc/ProduceSkinTones
	verbs |= /client/proc/ProduceColouredStates
	..()

var/list/clothing_colour_maps = list(
	"template" = list(
		DARK_GREY,
		PALE_GREY,
		GREY_BLUE,
		PALE_BLUE
		),
	"steel" = list(
		NAVY_BLUE,
		DARK_PURPLE,
		PALE_GREY,
		GREY_BLUE
	),
	"yellow" = list(
		GREEN_BROWN,
		PALE_BROWN,
		BRIGHT_ORANGE,
		BRIGHT_YELLOW
	),
	"black" = list(
		NAVY_BLUE,
		DARK_BLUE_GREY,
		DARK_GREY,
		PALE_GREY
	),
	"grey" = list(
		DARK_GREY,
		PALE_GREY,
		LIGHT_GREY,
		GREY_BLUE
	),
	"green" = list(
		DARK_BLUE_GREY,
		GREEN_BROWN,
		DARK_GREEN,
		BLUE_GREEN
	),
	"brown" = list(
		DARK_PURPLE,
		GREEN_BROWN,
		DARK_BROWN,
		PALE_BROWN
	),
	"red" = list(
		DARK_PURPLE,
		DARK_RED,
		PALE_RED,
		PINK
	),
	"purple" = list(
		NAVY_BLUE,
		DARK_PURPLE,
		INDIGO,
		PURPLE
	),
	"blue" = list(
		DARK_BLUE_GREY,
		INDIGO,
		BLUE,
		LIGHT_BLUE
	)
)

/client/proc/ProduceColouredStates()

	set name = "Produce Coloured Icon States"
	set category = "Utility"

	var/list/icon_choices = list(
		/obj/item/clothing/shirt,
		/obj/item/clothing/pants,
		/obj/item/clothing/shorts,
		/obj/item/clothing/boots,
		/obj/item/clothing/gloves,
		/obj/item/clothing/gloves/fingerless,
		/obj/item/clothing/over/robes,
		/obj/item/clothing/over/apron,
		"All",
		"Done"
		)

	var/list/icons_to_compile = list()
	var/choice = input("Which path(s) do you wish to compile icons for?") as null|anything in icon_choices
	while(choice)
		if(choice == "All")
			icons_to_compile |= icon_choices
			icons_to_compile -= "All"
			icons_to_compile -= "Done"
			break
		else if(choice == "Done")
			break
		else
			icons_to_compile |= choice
			choice = input("Which path(s) do you wish to compile icons for?") as null|anything in icon_choices

	if(!icons_to_compile || !icons_to_compile.len)
		return

	Dnotify("Compiling icon recolours.")

	for(var/upath in icons_to_compile)
		var/atom/_atom = upath
		var/dumpname = replacetext(replacetext(initial(_atom.name), " ", "_"),"'", "")
		var/icon/_icon_static = icon(icon = initial(_atom.icon), moving = FALSE)
		var/icon/_icon_moving = icon(icon = initial(_atom.icon), moving = TRUE)

		for(var/ident in clothing_colour_maps)
			if(ident == "template") continue
			var/list/template_colours = clothing_colour_maps["template"]
			var/list/map_colours = clothing_colour_maps[ident]
			var/icon/compiled_icon = icon()

			for(var/_icon_state in icon_states(_icon_static))
				var/icon/new_icon = icon(icon = _icon_static, icon_state = _icon_state)
				for(var/i = 1;i<=template_colours.len;i++)
					new_icon.SwapColor(template_colours[i], map_colours[i])
				compiled_icon.Insert(new_icon, _icon_state)

			for(var/_icon_state in icon_states(_icon_moving))
				var/icon/new_icon = icon(icon = _icon_moving, icon_state = _icon_state)
				for(var/i = 1;i<=template_colours.len;i++)
					new_icon.SwapColor(template_colours[i], map_colours[i])
				compiled_icon.Insert(new_icon, _icon_state, moving = TRUE)

			var/dumpstr = "dump\\[dumpname]\\[dumpname]_[ident].dmi"
			Dnotify("State recolour for [dumpname] complete, dumped to [dumpstr].")
			fcopy(compiled_icon, dumpstr)


/client/proc/ProduceSkinTones()

	set name = "Produce Skin Tones"
	set category = "Utility"
