/datum/admin_permissions/debug
	associated_permission = PERMISSIONS_DEBUG
	verbs = list(
		/client/proc/DebugController,
		/client/proc/ForceSwitchGameState,
		/client/proc/SetClientFps,
		/client/proc/ViewClientVars,
		/client/proc/StartViewVars,
		/client/proc/ToggleVarsRefresh,
		/client/proc/CloseVarsWindow,
		/client/proc/ToggleDaemon,
		/client/proc/JoinAsRole,
		/client/proc/TestCircleAlgorithm,
		/client/proc/MassDebugOutfits,
		/client/proc/MassUpdateTurfIcons,
		/client/proc/ViewGlobalVars
		)

/client/proc/ViewGlobalVars()
	set name = "View Global Variables"
	set category = "Debug"

	if(CheckAdminPermission(PERMISSIONS_DEBUG))
		if(!interface) interface = new /interface/viewvars(src)
		ViewVars(_glob)

/client/proc/MassUpdateTurfIcons()

	set name = "Mass Update Turf Icons"
	set desc = "Force-update all icons for turfs."
	set category = "Debug"

	for(var/turf/T in world)
		T.UpdateIcon()

/client/proc/MassDebugOutfits()

	set name = "Mass Debug Outfits"
	set desc = "Don't use this on a live server please."
	set category = "Debug"

	var/last_x = 0
	var/last_y = 0

	var/i = 1
	var/standing = TRUE
	while(i <= _glob.job_datums.len)

		var/mob/H = new(locate(mob.x+last_x,mob.y+last_y,mob.z))
		var/datum/job/job = _glob.job_datums[i]

		if(istype(H))
			H = job.Equip(H)
			if(!standing)
				H.ToggleProne()
				i++
		standing = !standing

		last_x++
		if(last_x > world.view)
			last_x = 0
			last_y++


/client/proc/ToggleDaemon()

	set name = "Toggle Daemon"
	set category = "Debug"

	var/datum/daemon/daemon = input("Toggle which daemon?") as null|anything in _glob.mc.daemons
	if(!istype(daemon))
		return

	daemon.suspend = !daemon.suspend
	if(daemon.suspend)
		Dnotify("Disabled [daemon.name] daemon.")
	else
		Dnotify("Enabled [daemon.name] daemon.")
		daemon.Start()

/client/proc/DevPanel()
	set waitfor = 0
	if(CheckAdminPermission(PERMISSIONS_DEBUG) && winget(src, "devwindow", "is-visible") == "false")
		winset(src, "devwindow", "is-visible=true")
	else
		winset(src, "devwindow", "is-visible=false")

/client/proc/DebugController()

	set name = "Master Controller Status"
	set category = "Debug"

	if(!_glob.mc)
		Dnotify("Master controller doesn't exist.")
		return
	Dnotify("Daemons: [_glob.mc.daemons.len]")
	for(var/datum/daemon/daemon in _glob.mc.daemons)
		Dnotify("[daemon.name]: [daemon.Status()]")

/client/proc/ForceSwitchGameState()

	set name = "Force Game State"
	set category = "Debug"

	var/choice = input("Select a new state.") as null|anything in typesof(/datum/game_state)-/datum/game_state
	if(!choice) return
	to_chat(src, "Previous state path: [_glob.game_state ? _glob.game_state.type : "null"]")
	SwitchGameState(choice)
	to_chat(src, "Forced state change complete.")

/client/proc/SetClientFps()

	set name = "Set Client FPS"
	set category = "Debug"

	fps = min(90, max(10, input("Enter a number between 10 and 90 (going above the world FPS, [world.fps], will result in visual oddities).") as num))

/client/proc/ViewClientVars()

	set name = "View Client Vars"
	set category = "Debug"

	if(CheckAdminPermission(PERMISSIONS_DEBUG))
		ViewVars(src)

//var viewing madness below
/client/proc/StartViewVars()
	set waitfor = 0
	set name = "View Variables"
	set category = "Debug"

	if(CheckAdminPermission(PERMISSIONS_DEBUG))
		var/interface/viewvars/V = new(src)
		interface = V

/client/proc/ViewVars(object)
	if(object)
		var/window_ref = "vars-\ref[object]"
		if(!winexists(src, window_ref))
			winclone(src, "varswindow", window_ref)
		if(winget(src, window_ref, "is-visible") == "false")
			winset(src, window_ref, "is-visible=true")
		winset(src, window_ref, "title=\"View Vars: [object]\"")
		winset(src, "[window_ref]", "on-close=\"CloseVarsWindow [window_ref]\"")
		winset(src, "[window_ref].varsrefresh", "command=\"ToggleVarsRefresh [window_ref]\"")
		src << output(object, "[window_ref].varselected")
		winset(src,"[window_ref].varsgrid","cells=2x0")
		src << output("Name", "[window_ref].varsgrid:1,1")
		src << output("Value", "[window_ref].varsgrid:2,1")
		UpdateViewVars(object)
	interface = new(src)

/client/proc/UpdateViewVars(object, win_ref)
	set waitfor = 0
	set background = 1

	var/datum/O = object
	if(!istype(O))
		if(win_ref)
			winset(src, win_ref, "title=\"View Vars: (Deleted)\"")
		return

	var/window_ref = "vars-\ref[O]"
	var/list/keylist = SortListKeys(O.vars)

	var/first_run = TRUE
	while(O && winexists(src, window_ref) && (winget(src, "[window_ref].varsrefresh", "is-checked") == "true" || first_run))
		var/i = 2
		for(var/k in keylist)
			src << output("<a href='?function=varedit;var=[k];ref=\ref[O]'>[k]</a>" , "[window_ref].varsgrid:1,[i]")
			var/value = O.vars[k]
			if(isnull(value))
				src << output("null", "[window_ref].varsgrid:2,[i++]")
			else if(istype(value, /list))
				var/list/olist = value
				var/list_string = "/list = [olist.len]"
				if(k != "vars" && olist.len < 20) // grid elements wont scroll down a long cell
					for(var/o in olist)
						list_string = "[list_string]\n   - [o]"
				src << output(list_string, "[window_ref].varsgrid:2,[i++]")
			else if(istype(value, /atom))
				src << output(value, "[window_ref].varsgrid:2,[i++]")
			else if(istype(value, /datum))
				var/datum/d = value
				src << output("[d.type] ([d])", "[window_ref].varsgrid:2,[i++]")
			else if(k == "appearance")
				src << output("/appearance", "[window_ref].varsgrid:2,[i++]")
			else if(k == "blend_mode")
				src << output("mode: [__blend_mode_flags["[value]"]]", "[window_ref].varsgrid:2,[i++]")
			else if(isnum(value) && k in list("flags", "sight", "appearance_flags"))
				src << output(FlagsToBits(value, k), "[window_ref].varsgrid:2,[i++]")
			else
				src << output("[value]", "[window_ref].varsgrid:2,[i++]")
		first_run = FALSE
		WAIT_1S

	if(!O)
		winset(src, window_ref, "title=\"View Vars: (Deleted)\"")

/proc/FlagsToBits(flags, var_name)
	var/list/flag_lookup
	switch(var_name)
		if("flags")
			flag_lookup = __atom_flags
		if("sight")
			flag_lookup = __sight_flags
		if("appearance_flags")
			flag_lookup = __appearance_flags
		else
			flag_lookup = __default_flags
	var/flag_list = "bitflags: [flags]"
	var/bit = 1
	for(var/i = 1 to 16)
		if(flags & bit)
			if(flag_lookup)
				flag_list = "[flag_list]\n   [flag_lookup["[bit]"]]"
			else
				flag_list = "[flag_list]\n   [bit]"
		bit = bit<<1
	return flag_list

/client/proc/ToggleVarsRefresh(string as text)
	set hidden = 1
	var/datum/d = locate(copytext(string, 6))
	UpdateViewVars(d, string)

/client/proc/CloseVarsWindow(string as text)
	set hidden = 1
	winset(src, string, "parent=none")

//Var editing madness below
/client/Topic(href,href_list[],hsrc)
	if(href_list["function"] == "varedit")
		if(CheckAdminPermission(PERMISSIONS_DEBUG))
			ModifyVar(src, href_list)
	else
		return ..()

/proc/ModifyVar(client/C, list/href_list)
	var/datum/D = locate(href_list["ref"])
	if(!istype(D))
		return
	var/V = D.vars[href_list["var"]]
	if(V in list("type", "parent_type", "vars") || istype(D, /atom) && V in list("locs"))
		C.Dnotify("variable \"[V]\" is read-only")
	else
		var/var_name = null
		//there are only a couple of cases we need to know the var name
		if(href_list["var"] == "appearance" || (istype(D, /atom) && (href_list["var"] in list("contents", "flags", "appearance_flags", "sight", "blend_mode"))))
			var_name = href_list["var"]
		D.vars[href_list["var"]] = ChangeVar(C, V, var_name)

//yes, this is a badass recursive-capable var editing proc
/proc/ChangeVar(client/C, V = null, var_name = null)
	set background = 1

	var/type
	//beware the conditional chain - its in a debug call chain so thats my excuse for using one
	if(isnull(V))
		type = "null"
	else if(istext(V))
		type = "text"
	else if(var_name in list("flags", "sight", "appearance_flags"))
		type = "bitfield"
	else if(var_name == "blend_mode")
		type = "blend_mode"
	else if(isnum(V))
		type = "number"
	else if(ispath(V))
		type = "path"
	else if(isfile(V))
		type = "file"
	else if(istype(V, /list))
		type = "list"
	else if(istype(V, /matrix))
		type = "matrix"
	else if(var_name == "appearance") // appearances are special snowflakes
		type = "appearance"
	else if(istype(V, /datum))
		var/choice = alert(C, "View or edit var?", null, "View", "Edit", "Cancel")
		switch(choice)
			if("View")
				C.ViewVars(V)
				return V
			if("Edit")
				type = "datum"
			if("Cancel")
				return V
	else if(!V)
		//nothing - shouldn't ever get this far
		return null

	var/new_type = input(C, "Select type", null, type) in list("null", "bitfield", "blend_mode", "number", "text", "path", "file", "list", "matrix", "appearance", "datum")
	switch(new_type)
		if("null")
			return null
		if("blend_mode")
			var/choice = input(C, "Select blend mode to switch to:", "Var Edit") in __blend_mode_flag_names
			return __blend_mode_flag_names[choice]
		if("bitfield")
			var/list/flag_lookup
			switch(var_name)
				if("flags")
					flag_lookup = __atom_flag_names
				if("sight")
					flag_lookup = __sight_flag_names
				if("appearance_flags")
					flag_lookup = __appearance_flag_names
				else
					flag_lookup = __default_flags
			var/choice = input(C, "Select bitflag to toggle:", "Var Edit") in flag_lookup
			if(V & flag_lookup[choice])
				V &= ~flag_lookup[choice]
			else
				V |= flag_lookup[choice]
			return V
		if("number")
			return input(C, "Enter number:", "Var Edit", V) as num|null
		if("text")
			return input(C, "Enter text:", "Var Edit", V) as text|null
		if("path")
			var/new_path = input(C, "Enter path:", "Var Edit", V) as text|null
			var/path = text2path(new_path)
			if(!path)
				var/selection = alert(C, "Path doesn't exist, do you want to set it to null?",null,"Yes","No")
				switch(selection)
					if("Yes")
						return null
					if("No")
						return V
			return path
		if("file")
			var/new_path = input(C, "Enter file path:", "Var Edit", V) as text|null
			var/new_file = file(new_path)
			if(!isfile(new_file))
				var/selection = alert(C, "Could not find file, do you want to set it to null?",null,"Yes","No")
				switch(selection)
					if("Yes")
						return null
					if("No")
						return V
			return new_file
		if("list")
			var/list/return_list = list()
			if(istype(V, /list))
				return_list = V
			var/list_entity = input(C, "Select list entity:", "List Edit") in return_list + list(" + new entry", "    wipe list", "    cancel")
			if(list_entity == " + new entry")
				var/more = "Yes"
				while(more == "Yes")
					var/new_entry = ChangeVar(C)
					if(!isnull(new_entry) && (var_name != "contents" || istype(new_entry, /mob) || istype(new_entry, /obj))) // can only put mobs and objects in contents
						return_list.Add(new_entry)
					else
						C.Dnotify("only mobs and objects can be added to an atoms contents list.")
					more = alert(C, "Add another entry?", null, "Yes", "No")
			else if(list_entity == "    cancel")
				return return_list
			else if(list_entity == "    wipe list")
				return list()
			else
				var/selection = alert(C, "How do you want to change this var?",null,"Edit","Remove")
				switch(selection)
					if("Edit")
						var/index = return_list.Find(list_entity)
						var/new_var = ChangeVar(C, list_entity)
						return_list[index] = new_var
					if("Remove")
						return_list.Remove(list_entity)
			return return_list
		if("matrix")
			C.Dnotify("matrix editing not implemented yet")
			return V
		if("appearance")
			C.Dnotify("appearance editing not implemented yet")
			return V
		if("datum")
			C.Dnotify("datum editing not implemented yet")
			return V


/client/proc/JoinAsRole()

	set name = "Join As Role"
	set category = "Debug"

	if(!istype(mob, /mob/abstract/new_player))
		Dnotify("You must be at the lobby to use this verb.")
		return

	var/mob/abstract/new_player/player = mob
	switch(_glob.game_state.ident)
		if(GAME_SETTING_UP, GAME_STARTING, GAME_LOBBY_WAITING)
			Dnotify("<span class='warning'>The game has not started yet!</span>")
			return
		if(GAME_OVER)
			Dnotify("<span class='warning'>The game is over!</span>")
			return

	var/datum/job/selected_role = input("Select a job.") as null|anything in _glob.job_datums

	if(!selected_role || !istype(mob, /mob/abstract/new_player) || (_glob.game_state.ident in list(GAME_SETTING_UP, GAME_STARTING, GAME_LOBBY_WAITING,GAME_OVER)))
		return

	screen -= player.title_image
	EndLobbyMusic(src)

	var/mob/new_mob = selected_role.Equip(player)
	selected_role.Welcome(new_mob)
	selected_role.Place(new_mob)
	QDel(player, "role join complete")

/client/proc/TestCircleAlgorithm()

	set name = "Test Explosions"
	set category = "Debug"

	DoExplosion(mob)