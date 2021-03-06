/obj/structure
	var/list/contains
	var/max_contains_count =       0
	var/max_contains_size_single = 0
	var/max_contains_size_total =  0
	var/open = FALSE
	var/can_open = FALSE

/mob/DraggedOntoThing(var/mob/user, var/atom/thing, var/left_drag, var/right_drag, var/middle_drag)
	. = ..()
	if(!. && user == src)
		var/obj/structure/seat = thing
		for(var/obj/item/grab/grab in src)
			if(grab.grabbed == thing)
				user.DropItem(grab)
		if(istype(seat) && (seat.flags & FLAG_SEATING) && !user.sitting && !user.prone && user.Move(seat.loc))
			user.SetDir(seat.dir)
			user.ToggleSitting(deliberate = TRUE)
			return TRUE

/obj/structure/DraggedOntoThing(var/mob/user, var/atom/thing, var/left_drag, var/right_drag, var/middle_drag)
	. = ..()
	if(!. && contains && istype(user) && user == thing)
		var/slot = user.GetSlotByHandedness(left_drag ? "left" : "right")
		if(slot)
			if(contains.len)
				var/obj/item/removing = pick(contains)
				contains -= removing
				removing.ForceMove(get_turf(src))
				if(user.CollectItem(removing, slot))
					user.NotifyNearby("\The [user] rummages around in \the [src] and pulls out \a [removing].", MESSAGE_VISIBLE)
					ThingTakenOut(removing)
				else
					contains[removing] = TRUE
					removing.ForceMove(src)
			else
				user.NotifyNearby("\The [user] rummages around in \the [src] but comes up empty handed.", MESSAGE_VISIBLE)
			return TRUE

/obj/structure/Initialize()
	if(max_contains_count > 0 && max_contains_size_single > 0 && max_contains_size_total > 0)
		contains = list()
		can_open = TRUE
		open = TRUE
		for(var/obj/item/prop in loc)
			if((prop.flags & FLAG_SIMULATED) && !(prop.flags & FLAG_ANCHORED) && CanAcceptItem(prop))
				StoreItem(prop)
		open = initial(open)
	. = ..()

/obj/structure/ManipulatedBy(var/mob/user, var/slot)
	. = ..()
	if(!. && ToggleOpen(user, slot))
		return TRUE

/obj/structure/proc/ToggleOpen(var/mob/user, var/slot)
	if(!can_open)
		return FALSE
	if(Burn(user, SLOT_HANDS))
		user.Notify("<span class='warning'>\The [src] is far too hot to touch!</span>")
	else
		open = !open
		if(user) user.NotifyNearby("<span class='notice'>\The [user] [open ? "opens" : "closes"] \the [src].</span>", MESSAGE_VISIBLE)
		UpdateIcon()
	return TRUE

/obj/structure/proc/CanAcceptItem(var/obj/item/prop)
	if(!open)
		return FALSE
	if(contains && contains.len == max_contains_count)
		return FALSE
	if(prop.GetAmount() > max_contains_size_single)
		return FALSE
	var/total_size = 0
	for(var/thing in contains)
		var/atom/atom = thing
		if(istype(atom))
			total_size += atom.GetAmount()
	if(total_size + prop.GetAmount() > max_contains_size_total)
		return FALSE
	return TRUE

/obj/structure/proc/StoreItem(var/obj/item/prop)
	contains[prop] = TRUE
	prop.ForceMove(src)
	ThingPutInside(prop)

/obj/structure/AttackedBy(var/mob/user, var/obj/item/prop)
	. = ..()
	if(!.)
		if(contains) // will be null in non-containers, todo: better check
			if(!open)
				user.Notify("\The [src] is closed.")
				return TRUE
			if(!CanAcceptItem(prop))
				user.Notify("\The [prop] will not fit into \the [src].")
				return TRUE
			if(user.DropItem(prop))
				if(prop && !Deleted(prop))
					user.NotifyNearby("\The [user] places \the [prop] into \the [src].", MESSAGE_VISIBLE)
					StoreItem(prop)
					return TRUE

/obj/structure/proc/ThingPutInside(var/obj/item/prop)
	return

/obj/structure/proc/ThingTakenOut(var/obj/item/prop)
	return

/obj/structure/MiddleClickedOn(var/mob/clicker)
	if(IsAdjacentTo(src, clicker))
		if((flags & FLAG_FLAT_SURFACE) || (contains && open))
			new /obj/ui/radial_menu(clicker, src)
			return TRUE
	. = ..()

/obj/structure/GetRadialMenuContents(var/mob/user, var/menu_type, var/args)
	if(menu_type == RADIAL_MENU_DEFAULT)
		if(contains && open)
			return contains.Copy()
		var/turf/turf = get_turf(src)
		if(istype(turf))
			return turf.GetRadialMenuContents(user, menu_type)-src
	return list()

/obj/structure/HandleFireDamage()
	. = ..()
	if(!Deleted(src) && IsOnFire() && fire_intensity && open)
		for(var/thing in contains)
			var/obj/item/prop = thing
			if(!prop.IsOnFire() && prop.IsFlammable() && prop.CanIgnite() && prob(10))
				prop.Ignite()
