// neura iw8 - modern warfare 2019
// by nyli, 2/17/26

// uncomment this to call init through main
#define USING_IW8_MOD

main()
{
#ifdef USING_IW8_MOD
    level thread init();
#endif
}

init()
{
    level thread on_player_connect();
    level thread setup_dvars();
}

setup_dvars()
{
    if (isdefined(level.is_setup)) return;

    // player
    setdvarifuninitialized("nvg", 0);
    setdvarifuninitialized("oob", 1);
    setdvarifuninitialized("barriers", 1);
    setdvarifuninitialized("godmode", 1);

    // weapons
    setdvarifuninitialized("camo", "");
    setdvarifuninitialized("max_weapons", 2);
    setdvarifuninitialized("weapon_switch", 1);
    setdvarifuninitialized("give_weapon", "");
    setdvarifuninitialized("weapon_variant", -1);
    setdvarifuninitialized("give_variant", "");
    setdvarifuninitialized("add_attachment", "");
    setdvarifuninitialized("akimbo", -1);

    // specials
    setdvarifuninitialized("set_execution", "");
    setdvarifuninitialized("give_streak", "");
    setdvarifuninitialized("ks_auto_activate", 0);
    setdvarifuninitialized("super", "");

    // custom
    setdvarifuninitialized("instaswaps_time", 0.15);
    setdvarifuninitialized("autoprone_mode", "air");
    setdvarifuninitialized("autoprone_endgame", 1);
    setdvarifuninitialized("aimbot_range", 1200);
    setdvarifuninitialized("scr_killcam_time", 5);
    setdvarifuninitialized("slomo", 1);

    level.is_setup = true;
    level.allowlatecomers = 1;
}

on_player_connect()
{
    level endon("game_ended");

    for (;;)
    {
        level waittill("connected", player);

        if (isai(player) || isbot(player))
            player thread on_bot_spawned();
        else if (player ishost())
        {
            player thread on_player_spawned();
        }
    }
}

on_player_spawned()
{
    self endon("disconnect");
    level endon("game_ended");

    self thread monitor_class();

    for (;;)
    {
        self waittill("spawned_player");
        if (isdefined(self.has_spawned)) 
            continue;
        
        self.neura = [];
        self.has_spawned = true;
        self.godmode_active = true;
        self giveachievement("FINISH"); // how you know the mod is loaded

        // trust me
        registered = 0;
        f = [];
        f[f.size] = ::command_handler;
        f[f.size] = ::register_buttons;
        f[f.size] = ::memory;
        f[f.size] = ::monitor_dvars;
        f[f.size] = ::give_perk_loop;
        f[f.size] = ::unlimited_eq;
        f[f.size] = ::round_manager; // auto reset rounds / never switch sides
        f[f.size] = ::clean_killcam; // remove hud elems like weapons and perks from killcam
        f[f.size] = ::enemy_always_watching;

        foreach(func in f)
        {
            self thread [[func]]();
            registered++;
            wait 0.05;
        }
        
        self reload_position();
        scripts\mp\gamelogic::pausetimer();

        // broken functions (1.20)
#ifdef USING_IW8_MOD
        self thread ammo_over_time(5, 20, 40); // refill stock every x seconds - min time, max time, amount to randomize to
#endif

        self iprintlnbold("^+neura iw8 ^7* ^+@nyli2b ^7* registered ^+" + registered + "^7 functions");
        while (isdefined(level.matchcountdowntime)) 
        {
            wait 1;
            self setclientomnvar("ui_match_start_countdown", 0);
            self setclientomnvar("ui_match_in_progress", 1);
            scripts\mp\playerlogic::clearprematchlook(self);
            level.matchcountdowntime = undefined;
        }
    }
}

on_bot_spawned()
{
    self endon("disconnect");
    for (;;)
    {
        self waittill("spawned_player");

        while (isdefined(level.matchcountdowntime)) wait 1;
        self thread freeze_loop();
        self reload_position();
    }
}

monitor_dvars()
{   
    registered = 0;
    f = [];
    f[f.size] = ::watch_noclip;
    f[f.size] = ::watch_godmode;
    f[f.size] = ::watch_night_vision;
    f[f.size] = ::watch_oob;
    f[f.size] = ::watch_barriers;
    f[f.size] = ::watch_executions;
    f[f.size] = ::watch_killstreaks;
    f[f.size] = ::watch_supers;
    f[f.size] = ::save_pos_bind;
    f[f.size] = ::load_pos_bind;

    foreach(func in f)
    {
        self thread [[func]]();
        registered++;
        wait 0.05;
    }
    self iprintln("ߝ [game] * now watching ^+ " + registered + " ^7dvar functions");
}

memory()
{
    self.neura["soh_perk_list"] = list("specialty_fastreload,specialty_fastoffhand,specialty_quickswap,specialty_quickdraw,specialty_sprintmelee,specialty_sprintads,specialty_sprintfire,specialty_deadeye,specialty_stalker,specialty_regenfaster");
    self.neura["perk_list"] = list("specialty_marathon,specialty_increaseaccuracy,specialty_holdbreath,specialty_lightweight");
    self setpers("lives", 99);
    self setpers("unstuck", self.origin);
    self setpersifuni("velx", 250);
    self setpersifuni("vely", 250);
    self setpersifuni("velz", 250);
    self setpersifuni("boltcount", "0");
    self setpersifuni("boltspeed", "1");
    self setpersifuni("class_wrap", "5");
    self setpersifuni("soh", true);
    self setpersifuni("eq_weapon", "support_box_mp");
    self setpersifuni("eq_putaway", false);

    for (i=1;i<8;i++)
    {
        self setpersifuni("boltpos" + i, "0");
        wait 0.05;
    }

    self setpersifuni("bouncecount", "0");
    for (i = 1; i < 8; i++)
    {
        self setpersifuni("bouncepos" + i, "0");
        wait 0.05;
    }

    if (int(self getpers("bouncecount")) >= 1)
    {
        self notify("stop_bounce_loop");
        self thread monitor_bounces();
        self iprintln("ߝ [game] * ^+ " + self getpers("bouncecount") + "^7 bounces reloaded");
    }

    self loadpers("no_hud", ::watch_hud);
    self loadpers("always_canswap", ::do_always_canswap);
    self loadpers("autoprone", ::do_auto_prone);
    self loadpers("autoreload", ::do_auto_reload);
    self loadpers("instaswaps", ::do_instaswaps);
    self loadpers("refill_bind", ::do_refill_bind);
    self loadpers("aimbot", ::do_aimbot);
    self loadpers("nac_bind", ::do_nac_bind, self getpers("nac_slot"));
    self loadpers("instaswap_bind", ::do_instaswap_bind, self getpers("is_slot"));
    self loadpers("bounce_bind", ::do_bounce_bind, self getpers("bounce_slot"));
    self loadpers("bolt_movement_bind", ::do_bolt_movement_bind, self getpers("bolt_slot"));
    self loadpers("class_bind", ::change_class_bind, self getpers("class_slot"));
    self loadpers("velocity_bind", ::do_velocity_bind, self getpers("vel_slot"));
    self loadpers("damage_bind", ::do_damage_bind, self getpers("damage_slot"));
    self loadpers("eq_bind", ::do_damage_bind, self getpers("eq_slot"));
    // self loadpers("instashoots", ::do_instashoots);
}

command_handler() // handles (most) dvar commands
{
    self thread createcommand("tp",  "teleport a bot to crosshair", ::bots_to_cross);
    self thread createcommand("tpa", "teleport all bots to self", ::bot_move);
    self thread createcommand("ammo", "refill ammo", ::refill_my_ammo);
    self thread createcommand("autoreload", "auto reload on end", ::auto_reload);
    self thread createcommand("autoprone", "auto prone", ::auto_prone);
    self thread createcommand("refillbind", "refill ammo", ::refill_bind);
    self thread createcommand("bounce", "spawn bounces", ::manage_bounce);
    self thread createcommand("drop", "drop items", ::drop_util);
    self thread createcommand("instaswaps", "bo2 instaswaps", ::instaswaps);
    self thread createcommand("aimbot", "aimbot", ::aimbot);
    self thread createcommand("unstuck", "unstuck", ::unstuck);
    self thread createcommand("setup", "easy setup", ::setup);
    self thread createcommand("sliding", "toggle sliding (dodging)", ::dodges);
    self thread createcommand("slomo", "set timescale", ::change_timescale);
    self thread createcommand("die", "respawn yourself", ::suicide_respawn);
    self thread createcommand("unset", "unset position", ::unset_position);
    self thread createcommand("cp", "give care package", ::give_care_package);
    self thread createcommand("uav", "give uav", ::give_uav);
    self thread createcommand("vish", "give vish", ::give_vish);
    self thread createcommand("nohud", "toggle hud", ::no_hud);
    self thread createcommand("alwayscan", "always canswap", ::always_canswap);
    self thread createcommand("soh", "toggle sleight of hand", ::fast_hands);
    self thread createcommand("putaway", "toggle equipment bind putaway", ::putaway);
    // self thread createcommand("instashoots", "toggle instashoots", ::instashoots);

    // binds
    self thread createcommand("nacbind", "nac bind to next weapon", ::nac_bind);
    self thread createcommand("isbind", "instaswap bind to next weapon", ::instaswap_bind);
    self thread createcommand("ccbind", "change class bind", ::change_class_bind);
    self thread createcommand("bouncebind", "bounce bind", ::bounce_bind);
    self thread createcommand("boltbind", "bolt movement bind", ::bolt_movement_bind);
    self thread createcommand("velbind", "velocity bind", ::velocity_bind);
    self thread createcommand("damagebind", "damage bind", ::damage_bind);
    self thread createcommand("eqbind", "equipment bind", ::eq_bind);

    // values
    self thread createcommand("bolt", "manage bolt movement", ::manage_bolt);
    self thread createcommand("boltspeed", "change bolt speed", ::bolt_speed);
    self thread createcommand("velx", "change x velocity", ::velx);
    self thread createcommand("vely", "change y velocity", ::vely);
    self thread createcommand("velz", "change z velocity", ::velz);
    self thread createcommand("classwrap", "change class change wrap", ::class_wrap);

    self iprintln("ߝ [neura] * ^+commands registered");
}

monitor_class()
{  
    self endon("disconnect");
    level endon("game_ended");

    game["strings"]["change_class"] = ""; 

    for (;;)
    {
        self waittill("luinotifyserver", var_00, var_01);

        if (!isalive(self))
            continue;

        if (var_00 != "class_select")
            continue;

        var_01 = var_01 + 1;
        self.class = var_01;

        scripts\mp\class::setclass(self.pers["class"]);
        self.tag_stowed_back = undefined;
        self.tag_stowed_hip = undefined;
        scripts\mp\class::giveloadout(self.pers["team"], self.pers["class"]);
    }
}

preset_bot_positions() // todo
{
    map = level.mapname;
    switch (map)
    {
        default:
            break;
    }
}

// functions
unset_position(args)
{
    if (args[0])
    {
        self setpers("saved_origin", false);
        self setpers("saved_angles", false);
        self setpers("position", false);
    }
}

suicide_respawn(args)
{
    if (args[0])
    {
        self suicide();
        self scripts\mp\playerlogic::spawnplayer();
        scripts\mp\class::setclass(self.pers["class"]);
        self.tag_stowed_back = undefined;
        self.tag_stowed_hip = undefined;
        scripts\mp\class::giveloadout(self.pers["team"], self.pers["class"]);
        wait 0.05;
        self reload_position();
    }
}

change_class_bind(args)
{
    if (int(args[0]) == 2 || int(args[0]) == 3 || int(args[0]) == 4)
    {
        self notify("stop_class_bind");
        actionslot = int(args[0]);
        self thread do_class_bind(actionslot);
        self setpers("class_bind", true);
        self setpers("class_slot", actionslot);
        self iprintln("ߝ [player] * change class bind set to actionslot ^+" + actionslot);
    }
    else
    {
        self notify("stop_class_bind");
        self setpers("class_bind", false);
        self setpers("class_slot", false);
        self iprintln("ߝ [player] * ^+change class bind disabled");
    }
}

do_class_bind(slot)
{
    self endon("stop_class_bind");
    for (;;)
    {
        self waittill("+actionslot " + int(slot));

        index = int(scripts\mp\class::getclassindex(self.class) + 1);
        index++;

        if(index > int(self getpers("class_wrap"))) 
        {
            index = 1;
        }

        self.class = "custom" + index;
        scripts\mp\class::setclass(self.class);
        self.tag_stowed_back = undefined;
        self.tag_stowed_hip = undefined;
        scripts\mp\class::giveloadout(self.pers["team"], self.class);
    }
}

class_wrap(args)
{
    if (float(args[0]))
    {
        self setpers("class_wrap", float(args[0]));
        self iprintlnbold("class wrap set to ^+" + float(args[0]));
    }
    else
    {
        self iprintlnbold("enter a valid number");
    }
}

damage_bind(args)
{
    if (int(args[0]) == 2 || int(args[0]) == 3 || int(args[0]) == 4)
    {
        self notify("stop_damage_bind");
        actionslot = int(args[0]);
        self thread do_damage_bind(actionslot);
        self setpers("damage_bind", true);
        self setpers("damage_slot", actionslot);
        self iprintln("ߝ [player] * damage bind set to actionslot ^+" + actionslot);
    }
    else
    {
        self notify("stop_damage_bind");
        self setpers("damage_bind", false);
        self setpers("damage_slot", false);
        self iprintln("ߝ [player] * ^+damage bind disabled");
    }
}

do_damage_bind(slot)
{
    self endon("stop_damage_bind");
    self endon("disconnect");
    level endon("game_ended");
    for (;;)
    {
        self waittill("+actionslot " + int(slot));
        player = self getenemyplayer();
        if (player == self)
        {
            self iprintlnbold("^+spawn a enemy");
            continue;
        }
        active = false;
        if (getdvarint("godmode") == 1) active = true;
        if (active) self.godmode_active = false;
        self [[level.callbackPlayerDamage]]( player, player, (self.health / 2), 8, "MOD_RIFLE_BULLET", self getcurrentweapon(), self.origin, (0,0,0), "neck", 0 );
        if (active) self.godmode_active = true;
     }
}

nac_bind(args)
{
    if (int(args[0]) == 2 || int(args[0]) == 3 || int(args[0]) == 4)
    {
        self notify("stop_nac_bind");
        actionslot = int(args[0]);
        self thread do_nac_bind(actionslot);
        self setpers("nac_bind", true);
        self setpers("nac_slot", actionslot);
        self iprintln("ߝ [player] * nac bind set to actionslot ^+" + actionslot);
    }
    else
    {
        self notify("stop_nac_bind");
        self setpers("nac_bind", false);
        self setpers("nac_slot", false);
        self iprintln("ߝ [player] * ^+nac bind disabled");
    }
}

do_nac_bind(slot)
{
    self endon("stop_nac_bind");
    for (;;)
    {
        self waittill("+actionslot " + int(slot));
        self nacto(self getnextweapon());
    }
}

eq_bind(args)
{
    if (int(args[0]) == 2 || int(args[0]) == 3 || int(args[0]) == 4)
    {
        self notify("stop_eq_bind");
        actionslot = int(args[0]);
        self thread do_eq_bind(actionslot);
        self setpers("eq_bind", true);
        self setpers("eq_slot", actionslot);
        self iprintln("ߝ [player] * eq bind set to actionslot ^+" + actionslot);
    }
    else
    {
        self notify("stop_eq_bind");
        self setpers("eq_bind", false);
        self setpers("eq_slot", false);
        self iprintln("ߝ [player] * ^+eq bind disabled");
    }
}

do_eq_bind(slot)
{
    self endon("stop_eq_bind");
    self endon("disconnect");
    level endon("game_ended");
    for (;;)
    {
        self waittill("+actionslot " + int(slot));
        x = self getcurrentweapon();
        self nacto(self getpers("eq_weapon"));
        if (isdefined(self getpers("eq_putaway")))
        {
            self switchtoweapon(x);
        }
    }
}

putaway(args)
{
    if (int(args[0]) == 1)
    {
        self setpers("eq_putaway", true);
        self iprintlnbold("ߝ [player] * ^+equipment putaway enabled");
    }
    else
    {
        self setpers("eq_putaway", false);
        self iprintlnbold("ߝ [player] * ^+equipment putaway disabled");
    }
}

instaswap_bind(args)
{
    if (int(args[0]) == 2 || int(args[0]) == 3 || int(args[0]) == 4)
    {
        self notify("stop_instaswap_bind");
        actionslot = int(args[0]);
        self thread do_instaswap_bind(actionslot);
        self setpers("instaswap_bind", true);
        self setpers("is_slot", actionslot);
        self iprintln("ߝ [player] * instaswap bind set to actionslot ^+" + actionslot);
    }
    else
    {
        self notify("stop_instaswap_bind");
        self setpers("instaswap_bind", false);
        self setpers("is_slot", false);
        self iprintln("ߝ [player] * ^+instaswap bind disabled");
    }
}

do_instaswap_bind(slot)
{
    self endon("stop_instaswap_bind");
    self endon("disconnect");
    level endon("game_ended");

    for (;;)
    {
        self waittill("+actionslot " + int(slot));
        self instaswapto(self getnextweapon());
    }
}

velocity_bind(args)
{
    if (int(args[0]) == 2 || int(args[0]) == 3 || int(args[0]) == 4)
    {
        self notify("stop_velocity_bind");
        actionslot = int(args[0]);
        self thread do_velocity_bind(actionslot);
        self setpers("velocity_bind", true);
        self setpers("vel_slot", actionslot);
        self iprintln("ߝ [player] * velocity bind set to actionslot ^+" + actionslot);
    }
    else
    {
        self notify("stop_velocity_bind");
        self setpers("velocity_bind", false);
        self setpers("vel_slot", false);
        self iprintln("ߝ [player] * ^+velocity bind disabled");
    }
}

do_velocity_bind(slot)
{
    self endon("stop_velocity_bind");
    self endon("disconnect");
    level endon("game_ended");
    for (;;)
    {
        self waittill("+actionslot " + int(slot));
        self setvelocity((self getpers("velx"), self getpers("vely"), self getpers("velz")));
    }
}

velx(args)
{
    if (float(args[0]))
    {
        self setpers("velx", float(args[0]));
        self iprintlnbold("x velocity set to ^+" + float(args[0]));
    }
    else
    {
        self iprintlnbold("enter a valid number");
    }
}

vely(args)
{
    if (float(args[0]))
    {
        self setpers("vely", float(args[0]));
        self iprintlnbold("y velocity set to ^+" + float(args[0]));
    }
    else
    {
        self iprintlnbold("enter a valid number");
    }
}

velz(args)
{
    if (float(args[0]))
    {
        self setpers("velz", float(args[0]));
        self iprintlnbold("z velocity set to ^+" + float(args[0]));
    }
    else
    {
        self iprintlnbold("enter a valid number");
    }
}

bolt_movement_bind(args)
{
    if (int(args[0]) == 2 || int(args[0]) == 3 || int(args[0]) == 4)
    {
        self notify("stop_bolt_movement_bind");
        actionslot = int(args[0]);
        self thread do_bolt_movement_bind(actionslot);
        self setpers("bolt_movement_bind", true);
        self setpers("bolt_slot", actionslot);
        self iprintln("ߝ [player] * bolt_movement bind set to actionslot ^+" + actionslot);
    }
    else
    {
        self notify("stop_bolt_movement_bind");
        self setpers("bolt_movement_bind", false);
        self setpers("bolt_slot", false);
        self unlink();
        self.current_bolt delete();
        self iprintln("ߝ [player] * ^+bolt_movement bind disabled");
    }
}

do_bolt_movement_bind(slot)
{
    self endon("stop_bolt_movement_bind");
    self endon("disconnect");
    level endon("game_ended");
    for (;;)
    {
        self waittill("+actionslot " + int(slot));
        self start_bolt();
    }
}

start_bolt()
{
    x = int (self getpers("boltcount"));
    if (x == 0)
        return self iprintlnbold("^1set bolt points first");

    bolt_model = spawn("script_model", self.origin);
    bolt_model setmodel("tag_origin");
    self.current_bolt = bolt_model; // store
    self playerlinkto(bolt_model);

    for (i=1; i<(x + 1); i++)
    {
        keys = strtok(self getpers("boltpos" + i), ",");
        position = (float(keys[0]), float(keys[1]), float(keys[2]));
        bolt_model moveto(position, float(self getpers("boltspeed")), 0, 0);
        wait float(self getpers("boltspeed"));
    }

    self unlink();
    bolt_model delete();
}

bounce_bind(args)
{
    if (int(args[0]) == 2 || int(args[0]) == 3 || int(args[0]) == 4)
    {
        self notify("stop_bounce_bind");
        actionslot = int(args[0]);
        self thread do_bounce_bind(actionslot);
        self setpers("bounce_bind", true);
        self setpers("bounce_slot", actionslot);
        self iprintln("ߝ [player] * bounce bind set to actionslot ^+" + actionslot);
    }
    else
    {
        self notify("stop_bounce_bind");
        self setpers("bounce_bind", false);
        self setpers("bounce_slot", false);
        self iprintln("ߝ [player] * ^+bounce bind disabled");
    }
}

do_bounce_bind(slot)
{
    self endon("stop_bounce_bind");
    self endon("disconnect");
    level endon("game_ended");
    for (;;)
    {
        self waittill("+actionslot " + int(slot));
        self setvelocity(self getvelocity() - (0,0,self getvelocity()[2] * 2));
    }
}

change_timescale(args) // being gay i gotta look at this later
{
    if (float(args[0]) < 0.1 || float(args[0]) > 20)
    {
        self iprintln("ߝ [game] * value must be ^+0.1-20");
    }

    timescale = float(args[0]);
    setdvar("slomo", timescale);
    setslowmotion(getdvarfloat("slomo"), getdvarfloat("slomo"), 0);
}

reset_timescale()
{
    self waittill("begin_killcam");
    setslowmotion(1, 1, 0);
}

refill_my_ammo(args)
{
    switch (args)
    {
        case "all":
            self thread refill_all_ammo();
        case "current":
            self thread refill_weapon_ammo();
        default:
            self iprintln("ߝ [weapon] * ^+unknown args '" + args + "'. falling back..");
            self thread refill_all_ammo();
    }
    self play("scavenger_pack_pickup");
}

auto_prone(args)
{
    if (int(args[0]) == 1)
    {
        self notify("stop_auto_prone");
        self thread do_auto_prone();
        self setpers("autoprone", true);
        self iprintln( "ߝ [player] * ^+auto prone enabled" );
    }
    else
    {
        self notify("stop_auto_prone");
        self setpers("autoprone", false);
        self iprintln( "ߝ [player] * ^+auto prone disabled" );
    }
}

dodges(args)
{
    if (int(args[0]) == 1)
    {
        self notify("stop_dodges");
        self thread disable_dodging();
        self setpers("dodges", true);
        self iprintln( "ߝ [player] * ^+sliding / dodges disabled" );
    }
    else
    {
        self notify("stop_dodges");
        self setpers("dodges", false);
        self iprintln( "ߝ [player] * ^+sliding / dodges enabled" );
    }
}

disable_dodging() // sliding
{
    level endon("game_ended");
    self endon("disconnect");
    self endon("stop_dodges");
    for (;;)
    {
        self allowdodge(0);
        wait 0.05;
    }
}

do_auto_prone()
{
    self endon("disconnect");
    self endon("stop_auto_prone");

    if (getdvarint("autoprone_endgame") == 1)
        self thread game_ended_prone();

    for (;;)
    {
        self waittill("weapon_fired", weapon);

        if (getdvar("autoprone_mode") == "air")
        {
            if (self isonground() || self isonladder() || self ismantling())
                continue;
        }

        if (is_valid_weapon(weapon))
        {
            self thread auto_prone_logic();
            wait 0.5;
            self notify("temp_end");
        }
        wait 0.05;
    }
}

auto_prone_logic()
{
    self endon("temp_end");
    for (;;)
    {
        self setstance("prone");
        wait .01;
    }
}

game_ended_prone()
{
    self endon("stop_auto_prone");
    self endon("begin_killcam");
    level waittill("game_ended");

    for (i = 1; i < 30; i++)
    {
        self setstance("prone");
        wait 0.05;
    }
}

auto_reload(args)
{
    if (int(args[0]) == 1)
    {
        self notify("stop_auto_reload");
        self thread do_auto_reload();
        self setpers("autoreload", true);
        self iprintln( "ߝ [player] * ^+auto reload enabled" );
    }
    else
    {
        self notify("stop_auto_reload");
        self setpers("autoreload", false);
        self iprintln( "ߝ [player] * ^1auto reload disabled" );
    }
}

do_auto_reload()
{
    self endon("stop_auto_reload");
    level waittill("game_ended");
    x = self getcurrentweapon();
    self setweaponammoclip(x, 0);
}

always_canswap(args)
{
    if (int(args[0]) == 1)
    {
        self notify("stop_always_canswap");
        self thread do_always_canswap();
        self setpers("always_canswap", true);
        self iprintln( "ߝ [player] * ^+always canswap enabled" );
    }
    else
    {
        self notify("stop_always_canswap");
        self setpers("always_canswap", false);
        self iprintln( "ߝ [player] * ^+bo2 always canswap disabled" );
    }
}

do_always_canswap()
{
    self endon("disconnect");
    self endon("stop_always_canswap");
    level endon("game_ended");

    for (;;)
    {
        self waittill("weapon_change", weapon);
        if (isdefined(self getpers("nac_bind")))
        {
            wait 0.05;
        }
        self alwayscan(weapon);
        wait 0.05;
    }
}

instaswaps(args)
{
    if (int(args[0]) == 1)
    {
        self notify("stop_instaswaps");
        self thread do_instaswaps();
        self setpers("instaswaps", true);
        self iprintln( "ߝ [player] * ^+bo2 instaswaps enabled" );
        self iprintln( "ߝ [player] * edit the time with: ^+ instaswaps_time 0.0-1" );
    }
    else
    {
        self notify("stop_instaswaps");
        self setpers("instaswaps", false);
        self iprintln( "ߝ [player] * ^+bo2 instaswaps disabled" );
    }
}

do_instaswaps()
{
    self endon("disconnect");
    level endon("game_ended");
    self endon("stop_instaswaps");

    for (;;)
    {
        self waittill("grenade_pullback", grenade);
        name = grenade.basename;

        if (name == "deployable_cover_mp" || name == "support_box_mp" || name == "equip_adrenaline" || name == "airdrop_marker_mp" || name == "deployable_vest_marker_mp" || name == "deployable_weapon_crate_marker_mp")
        {
            continue;
        }

        if (isdefined(self.is_swapping))
        {
            continue;
        }

        self.is_swapping = true;
        wait (getdvarfloat("instaswaps_time"));
        self switchto(self getprevweapon());
        self.is_swapping = undefined;
    }
}

refill_bind(args)
{
    if (int(args[0]) == 1)
    {
        self notify("stop_refill");
        self thread do_refill_bind();
        self setpers("refill_bind", true);
        self iprintln( "ߝ [player] * ^+refill bind enabled " );
    }
    else
    {
        self notify("stop_refill");
        self setpers("refill_bind", false);
        self iprintln( "ߝ [player] * ^+refill bind disabled" );
    }
}

do_refill_bind()
{
    level endon("game_ended");
    self endon("disconnect");
    self endon("stop_refill");

    for (;;)
    {
        self waittill("+melee_zoom");
        if (self getstance() == "prone")
        {
            self thread refill_all_ammo();
            wait 0.05;
        }
    }
}

no_hud(args)
{
    if (int(args[0]) == 1)
    {
        self notify("stop_watching_hud");
        self thread watch_hud();
        self setpers("no_hud", true);
    }
    else
    {
        self notify("stop_watching_hud");
        self setclientomnvar("ui_hide_full_hud", 0);
        setdvar("LOPKSRNTTS", 0);
        self setpers("no_hud", false);
    }
}

watch_hud()
{
    self endon("stop_watching_hud");
    self endon("disconnect");
    level endon("game_ended");

    setdvar("LOPKSRNTTS", 1);

    for (;;)
    {
        self setclientomnvar("ui_hide_full_hud", 1);
        wait 0.05;
    }
}

aimbot(args)
{
    range = getdvar("aimbot_range");
    if (int(args[0]) == 1)
    {
        self notify("stop_aimbot");
        self thread do_aimbot();
        self setpers("aimbot", true);
        self iprintln( "ߝ [player] * aimbot enabled @ ^+" + range + " range");
    }
    else
    {
        self notify("stop_aimbot");
        self setpers("refillbind", false);
        self iprintln( "ߝ [player] * ^+aimbot disabled" );
    }
}

// this eb works actually really well on here lol
do_aimbot()
{
    level endon("game_ended");
    self endon("disconnect");
    self endon("stop_aimbot");

    for (;;) 
    {
        self waittill("weapon_fired");

        center = self getcrosshair();
        range = getdvarint("aimbot_range");
        current = self getcurrentweapon();

        foreach(player in level.players)
        {
            if (is_valid_weapon(current))
            {
                /*  prevent hitmarkers on spectators / dead players by checking if alive first
                    has been an issue on multiple games sooooo just to be safe */
                if (isalive(player))
                {
                    // don't kill yourself :3 (i've never added this for some reason cause i'm retarded)
                    if (player != self)
                    {
                        if (distance(player.origin, center) < range)
                        {
                            // todo (?) - customize bone
                            player thread [[level.callbackPlayerDamage]]( self, self, player.health, 2, "MOD_RIFLE_BULLET", self getcurrentweapon(), (0, 0, 0), (0, 0, 0), "torso_upper", 0 );
                        }
                    }
                }
            }
        }
    }
}

spawn_bounce()
{
    x = int(self getpers("bouncecount"));
    x++;

    self setpers("bouncecount", x);
    self setpers("bouncepos" + x, self getorigin()[0] + "," + self getorigin()[1] + "," + self getorigin()[2]);
    self iprintln("ߝ [game] * bounce #" + x + " spawned at ^+" + self getorigin());
    
    // watch for placed bounces if more than 1
    if (x == 1)
    {
        self notify("stop_bounce_loop");
        self thread monitor_bounces();
    }
}

delete_bounce()
{
    x = int(self getpers("bouncecount"));

    if (x == 0)
        return self iprintln("ߝ [game] * ^+no bounces to delete");

    x--;
    self setpers("bouncecount", x);
    self iprintln("ߝ [game] * ^+bounce #" + x + " deleted");
}

monitor_bounces()
{
    self endon("stop_bounce_loop");
    
    for (;;)
    {
        for (i = 1; i < int(self getpers("bouncecount")) + 1; i++)
        {
            pos = perstovector(self getpers("bouncepos" + i));

            if (distance(self getorigin(), pos) < 90 && self getvelocity()[2] < -250)
            {
                self setvelocity(self getvelocity() - (0, 0, self getvelocity()[2] * 2));
                wait 0.2;
            }
        }
        wait 0.05;
    }
}

manage_bounce(args)
{
    switch (args[0])
    {
        case "spawn":
            self thread spawn_bounce();
            break;
        case "delete":
            self thread delete_bounce();
            break;
        default:
            self iprintln("ߝ [game] * ^+use spawn or delete..");
            break;        
    }
}

bolt_speed(args)
{
    if (float(args[0]))
    {
        self setpers("boltspeed", float(args[0]));
        self iprintlnbold("bolt speed set to ^:" + float(args[0]));
    } 
    else 
    {
        self iprintlnbold("enter a valid number");
    }
}

manage_bolt(args)
{
    switch (args[0])
    {
        case "save":
            self thread save_bolt();
            break;
        case "delete":
            self thread delete_last_bolt();
            break;
        default:
            self iprintln("ߝ [game] * ^+use save or delete..");
            break;        
    }
}

save_bolt()
{
    x = getdvarint("boltcount");
    if(x == 20)
        return self iprintlnbold("^1max bolt points saved");

    x++;
    self setpers("boltcount", x);
    self setpers("boltpos" + x, self getorigin()[0] + "," + self getorigin()[1] + "," + self getorigin()[2]);

    self iprintlnbold("^:bolt point " + x + " saved");
}

delete_last_bolt()
{
    x = int(self getpers("boltcount"));
    if(x == 0)
        return self iprintlnbold("^1no points to delete");

    self setpers("boltpos" + x, "0");
    self iprintlnbold("^+bolt point " + x + " deleted");
    x--;
    self setpers("boltcount", x);
}

drop_util(args)
{
    current = self getcurrentweapon();
    next = self getnextweapon();
    weapons = self getrealweapons();

    switch (args[0])
    {
        case "current":
        case "curr":
            self dropitem(current);
            wait 0.05;
            self scripts\cp_mp\utility\inventory_utility::_switchtoweaponimmediate(self getweaponslistprimaries()[0]);
            self play("scavenger_pack_pickup");
            break;
        case "next":
        case "secondary":
            self scripts\cp_mp\utility\inventory_utility::_switchtoweaponimmediate(next);
            self dropitem(next);
            wait 0.05;
            self scripts\cp_mp\utility\inventory_utility::_switchtoweaponimmediate(self getweaponslistprimaries()[0]);
            self play("scavenger_pack_pickup");
            break;
        case "all":
            foreach (item in self getweaponslistprimaries())
            {
                self scripts\cp_mp\utility\inventory_utility::_switchtoweaponimmediate(item);
                wait 0.05;
                self dropitem(item);
            }
            self play("scavenger_pack_pickup");
            break;
        default:
            self iprintln("ߝ [game] * ^+use canswap, current, alt, primary, or all..");
            break;        
    }
}

setup(args)
{
    if (int(args[0]))
    {    
        f = [];
        f[f.size] = ::auto_reload;
        f[f.size] = ::auto_prone;
        f[f.size] = ::refill_bind;
        f[f.size] = ::instaswaps;
        f[f.size] = ::aimbot;
        foreach(func in f)
        {
            self thread [[func]](args);
            wait 0.05;
        }
        self thread bot_move("chudai");
    }
}

save_pos_bind()
{
    level endon("game_ended");
    for (;;)
    {
        self waittill("+actionslot 3");
        if (self getstance() == "crouch")
        {
            self save_spawn();
            self iprintlnbold("ߝ [position] * saved @ ^+" + self.origin);
            wait 0.6;
            self iprintlnbold(" ");
            wait 0.05;
        }
    }
}

load_pos_bind()
{
    level endon("game_ended");
    for (;;)
    {
        self waittill("+actionslot 2");
        if (self getstance() == "crouch")
            self load_spawn();
        wait 0.05;
    }
}

save_spawn()
{
    if (!self.pers["position"])
        self setpers("position", true);

    self setpers("saved_origin", self.origin);
    self setpers("saved_angles", self getplayerangles());
    self play("mp_jugg_mus_toggle_button");
}

load_spawn()
{
    if (!self.pers["position"])
    {
        self iprintlnbold("^+save a position first");
        return;
    }

    self setvelocity((0, 0, 0));
    self setorigin(self.pers["saved_origin"]);
    self setplayerangles(self.pers["saved_angles"]);
}

reload_position()
{
    if (isdefined(self.pers["position"]) && self.pers["position"])
        self load_spawn();
    else   
        self save_spawn();
}

unstuck()
{
    self setorigin(self getpers("unstuck"));
}

unlimited_eq()
{
    self endon("disconnect");
    level endon("game_ended");

    for(;;)
    {
        self waittill("grenade_fire", grenade, item);
        wait 0.05;
        self setweaponammoclip(item, 1);
        self givemaxammo(item);
        wait 0.05;
    }
}

ammo_over_time(min, max, choice)
{
    self endon("disconnect");
    level endon("game_ended");

    for (;;)
    {
        items = self.equippedweapons;
        choice = randomintrange(choice);
        foreach (item in items)
            self setweaponammostock(item, (self getweaponammostock(item) + choice));
        wait (randomintrange(min, max));

        wait 0.05; // ensure itll wait a frame lmao
    }
}

bot_move(args)
{
    if (args[0])
    {
        foreach(player in level.players) 
        {
            if (isai(player) || isbot(player)) 
            {
                player setorigin(self.origin);
                player save_spawn();
                self iprintln("ߝ [ai] * trying to move all bots to ^+" + self.origin);
                self play("recon_drone_marked_owner");
            }
        }
    }
}

bots_to_cross(args)
{
    if (args[0])
    {
        foreach(player in level.players) 
        {
            if (isai(player) || isbot(player)) 
            {
                player setorigin(self getcrosshair());
                player save_spawn();
                self iprintln("ߝ [ai] * trying to move all bots to ^+" + player.origin);
                self play("recon_drone_marked_owner");
            }
        }
    }
}

freeze_loop()
{
    self endon("disconnect");
    self endon("unfreeze_me");
    level endon("game_ended");

    for (;;)
    {
        self freezecontrols(1);
        wait 0.05;
    }
}

give_vish(args)
{
    if (int(args[0])) self setspawnweapon("none");
}

// dvar monitor stuff - need to redo all of this
watch_godmode()
{
    self endon( "disconnect" );
    level endon( "game_ended" );
    var_0 = getdvarint( "godmode", 0 );

    if ( var_0 == 1 )
        thread godmode_loop();

    for (;;)
    {
        var_1 = getdvarint( "godmode", 0 );

        if ( var_1 != var_0 )
        {
            var_0 = var_1;

            if ( var_1 == 1 )
            {
                self notify( "stop_godmode" );
                thread godmode_loop();

                if ( !isdefined( self.noclip_autogod ) )
                    self iprintln( "ߝ [player] * ^+godmode enabled" );
            }
            else
            {
                self notify( "stop_godmode" );
                godmode_disable();

                if ( !isdefined( self.noclip_autogod ) )
                    self iprintln( "ߝ [player] * ^1godmode disabled" );
            }
        }
        wait 0.05;
    }
}

godmode_loop()
{
    self endon( "disconnect" );
    self endon( "stop_godmode" );
    level endon( "game_ended" );

    if ( !isdefined( self.god_fallheight ) )
        self.god_fallheight = getdvarfloat( "NKTQRKRMTS", 200.0 );

    setdvar( "NKTQRKRMTS", 10000.0 );
    self.maxhealth = 999999;
    self.health = 999999;
    self.godmode_active = 1;

    for (;;)
    {
        self waittill( "damage", var_0, var_1, var_2, var_3, var_4, var_5, var_6, var_7, var_8, var_9 );

        if ( isdefined( self.godmode_active ) && self.godmode_active )
            self.health = self.maxhealth;
    }
}

godmode_disable()
{
    self.godmode_active = undefined;
    self.maxhealth = 100;
    self.health = 100;

    if ( isdefined( self.god_fallheight ) )
    {
        setdvar( "NKTQRKRMTS", self.god_fallheight );
        self.god_fallheight = undefined;
    }
}

watch_noclip()
{
    self.isactive = 0;
    self.noclipanchor = undefined;
    self.godmode_active = undefined;

    if ( !isdefined( self.noclipmonitor ) )
    {
        self.noclipmonitor = 1;
        self thread noclip_monitor();
    }
}

noclip_monitor()
{
    self endon("disconnect");
    level endon("game_ended");
    for (;;)
    {
        if (self meleebuttonpressed() && self jumpbuttonpressed())
        {
            if (!self.isactive)
                self thread enable_noclip();
            else
                self thread disable_noclip();
            wait 0.2;
        }

        if (self.isactive && isdefined( self.noclipanchor))
        {
            self.viewangles = self getplayerangles();
            self.forward = anglestoforward(self.viewangles);
            self.right = anglestoright(self.viewangles);
            self.moveinput = self getnormalizedmovement();
            self.verticalinput = 0;

            if (!self.menuopen)
            {
                if (self jumpbuttonpressed())
                    self.verticalinput = 1;

                if (self stancebuttonpressed())
                    self.verticalinput = -1;
            }

            self.currentspeed = self sprintbuttonpressed() ? 80 : 33;
            self.movedirection = self.forward * self.moveinput[0] + self.right * self.moveinput[1] + (0, 0, self.verticalinput * 1.7);
            self.noclipanchor.origin = self.noclipanchor.origin + self.movedirection * self.currentspeed * 0.5;
            self.noclipanchor.angles = self.viewangles;
        }

        wait 0.01;
    }
}

enable_noclip()
{
    if ( self.isactive )
        return;

    self allowsprint( 0 );
    self.isactive = 1;
    self.noclipanchor = spawn( "script_origin", self.origin );
    self.noclipanchor.angles = self.angles;
    self playerlinkto( self.noclipanchor );
    self iprintln("ߝ [ufo] * started @ ^+" + self.origin);
    wait 4.1;
}

disable_noclip()
{
    if ( !self.isactive )
        return;

    self allowsprint( 1 );
    self.isactive = 0;
    self unlink();

    if ( isdefined( self.noclipanchor ) )
    {
        self.noclipanchor delete();
        self.noclipanchor = undefined;
    }

    self iprintln("ߝ [ufo] * ended at @ ^1" + self.origin);
}

watch_weapon_camo()
{
    self endon( "disconnect" );
    self endon( "death" );
    level endon( "game_ended" );
    var_0 = getdvar( "camo", "" );

    for (;;)
    {
        var_1 = getdvar( "camo", "" );

        if ( var_1 != var_0 && var_1 != "" )
        {
            var_0 = var_1;
            self addcamotocurrentweapon( var_1 );
            setdvar( "camo", "" );
            var_0 = "";
        }

        wait 0.05;
    }
}

addcamotocurrentweapon( var_0 )
{
    var_1 = self getcurrentweapon();

    if ( !isdefined( var_1 ) || var_1.basename == "none" )
        return;

    var_2 = isdefined( var_1.variantid ) ? var_1.variantid : -1;
    var_3 = scripts\mp\class::buildweapon( scripts\mp\utility\weapon::getweaponrootname( var_1 ), var_1.attachments, var_0, "none", var_2, undefined, undefined, undefined, scripts\cp_mp\utility\game_utility::isnightmap() );

    if ( !isdefined( var_3 ) )
    {
        self iprintln( "ߝ [weapon] * ^1failed to apply camo: ^7" + var_0 );
        return;
    }

    self scripts\cp_mp\utility\inventory_utility::_takeweapon( var_1 );
    wait 0.05;
    self scripts\cp_mp\utility\inventory_utility::_giveweapon( var_3 );
    self scripts\cp_mp\utility\inventory_utility::_switchtoweaponimmediate( var_3 );
    self refill_weapon_ammo( var_3 );
    self iprintln( "ߝ [weapon] * ^+applied camo: ^7" + var_0 + var_2 >= 0 ? " ^+(variant " + var_2 + " preserved)" : "" );
}

fast_hands(args)
{
    if (int(args[0]) == 1)
    {
        self setpers("soh", true);
        self iprintln("ߝ [player] * ^+fast hands enabled");
    }
    else
    {
        self setpers("soh", false);
        self iprintln("ߝ [player] * ^+fast hands disabled");
        foreach(perk in self.neura["soh_perk_list"])
        {
            scripts\mp\utility\perk::removeperk(perk);
        }
    }
}

give_perk_loop() // pretty sure this works somewhat
{
    self endon("disconnect");
    level endon("game_ended");
    for (;;)
    {
        if (isdefined(self getpers("soh")))
        {
            foreach(perk in self.neura["soh_perk_list"])
            {
                scripts\mp\utility\perk::giveperk(perk);
            }
        }
        else
        {
            foreach(perk in self.neura["soh_perk_list"])
            {
                scripts\mp\utility\perk::removeperk(perk);
            }
        }

        foreach(perk in self.neura["perk_list"])
        {
            scripts\mp\utility\perk::giveperk(perk);
        }

        wait 1;
    }
}

refill_all_ammo()
{
    items = self.equippedweapons;
    foreach ( item in items )
    {
        self givemaxammo( item );
        self setweaponammostock( item, 999 );
        self setweaponammoclip( item, 999 );
        self setweaponammoclip( item, 999, "left" );
        self setweaponammoclip( item, 999, "right" );
        self setweaponammoclip( item, 999, "_encstr_8253060E2B5FE330" );
        self setweaponammoclip( item, 999, "_encstr_9353062E718710C9" );
        self setweaponammoclip( item, 999, "_encstr_A5AD056A019C63" );
        self setweaponammoclip( item, 999, "_encstr_B1AD05C65666E8" );
        wait 0.05;
    }
}

refill_weapon_ammo( item )
{
    self givemaxammo( item );
    self setweaponammostock( item, 999 );
    self setweaponammoclip( item, 999 );
    self setweaponammoclip( item, 999, "left" );
    self setweaponammoclip( item, 999, "right" );
    self setweaponammoclip( item, 999, "_encstr_A5AD056A019C63" );
    self setweaponammoclip( item, 999, "_encstr_B1AD05C65666E8" );
    self setweaponammoclip( item, 999, "_encstr_8253060E2B5FE330" );
    self setweaponammoclip( item, 999, "_encstr_9353062E718710C9" );
}

watch_barriers()
{
    level endon( "game_ended" );

    if ( !isdefined( level.original_barriers ) )
    {
        level.original_barriers = spawnstruct();
        level.original_barriers.triggers = [];
        level.original_barriers.barriers = [];
        level.original_barriers.clips = [];
        level.original_barriers.oncetriggers = [];
        var_0 = getentarray( "trigger_hurt", "classname" );

        for ( var_1 = 0; var_1 < var_0.size; var_1++ )
        {
            level.original_barriers.triggers[var_1] = spawnstruct();
            level.original_barriers.triggers[var_1].entity = var_0[var_1];
            level.original_barriers.triggers[var_1].origin = var_0[var_1].origin;
        }

        var_2 = getentarray( "barrier", "targetname" );

        for ( var_1 = 0; var_1 < var_2.size; var_1++ )
        {
            level.original_barriers.barriers[var_1] = spawnstruct();
            level.original_barriers.barriers[var_1].entity = var_2[var_1];
            level.original_barriers.barriers[var_1].origin = var_2[var_1].origin;
        }

        var_3 = getentarray( "trigger_multiple", "classname" );

        for ( var_1 = 0; var_1 < var_3.size; var_1++ )
        {
            level.original_barriers.clips[var_1] = spawnstruct();
            level.original_barriers.clips[var_1].entity = var_3[var_1];
            level.original_barriers.clips[var_1].origin = var_3[var_1].origin;
        }

        var_4 = getentarray( "trigger_once", "classname" );

        for ( var_1 = 0; var_1 < var_4.size; var_1++ )
        {
            level.original_barriers.oncetriggers[var_1] = spawnstruct();
            level.original_barriers.oncetriggers[var_1].entity = var_4[var_1];
            level.original_barriers.oncetriggers[var_1].origin = var_4[var_1].origin;
        }
    }

    var_5 = getdvarint( "barriers", 0 );

    if ( var_5 == 1 )
        disable_barriers();

    for (;;)
    {
        var_6 = getdvarint( "barriers", 0 );

        if ( var_6 != var_5 )
        {
            var_5 = var_6;

            if ( var_6 == 1 )
            {
                disable_barriers();

                foreach ( var_8 in level.players )
                {
                    if ( isdefined( var_8 ) )
                        var_8 iprintln( "[game] * ^+barriers removed" );
                }
            }
            else
            {
                restore_barriers();

                foreach ( var_8 in level.players )
                {
                    if ( isdefined( var_8 ) )
                        var_8 iprintln( "[game] * ^1barriers restored" );
                }
            }
        }

        wait 0.05;
    }
}

disable_barriers()
{
    foreach ( var_1 in level.original_barriers.triggers )
    {
        if ( isdefined( var_1.entity ) )
            var_1.entity.origin = ( 999999, 999999, 999999 );
    }

    foreach ( var_4 in level.original_barriers.barriers )
    {
        if ( isdefined( var_4.entity ) )
            var_4.entity.origin = ( 999999, 999999, 999999 );
    }

    foreach ( var_7 in level.original_barriers.clips )
    {
        if ( isdefined( var_7.entity ) )
            var_7.entity.origin = ( 999999, 999999, 999999 );
    }

    foreach ( var_10 in level.original_barriers.oncetriggers )
    {
        if ( isdefined( var_10.entity ) )
            var_10.entity.origin = ( 999999, 999999, 999999 );
    }
}

restore_barriers()
{
    foreach ( var_1 in level.original_barriers.triggers )
    {
        if ( isdefined( var_1.entity ) && isdefined( var_1.origin ) )
            var_1.entity.origin = var_1.origin;
    }

    foreach ( var_4 in level.original_barriers.barriers )
    {
        if ( isdefined( var_4.entity ) && isdefined( var_4.origin ) )
            var_4.entity.origin = var_4.origin;
    }

    foreach ( var_7 in level.original_barriers.clips )
    {
        if ( isdefined( var_7.entity ) && isdefined( var_7.origin ) )
            var_7.entity.origin = var_7.origin;
    }

    foreach ( var_10 in level.original_barriers.oncetriggers )
    {
        if ( isdefined( var_10.entity ) && isdefined( var_10.origin ) )
            var_10.entity.origin = var_10.origin;
    }
}

watch_night_vision()
{
    self endon( "disconnect" );
    self endon( "death" );
    level endon( "game_ended" );
    var_0 = getdvarint( "nvg", 0 );

    if ( var_0 == 1 )
        thread enable_nvg();
    else
        thread disable_nvg();

    for (;;)
    {
        var_1 = getdvarint( "nvg", 0 );

        if ( var_1 != var_0 )
        {
            var_0 = var_1;

            if ( var_1 == 1 )
            {
                thread enable_nvg();
                self iprintln( "ߝ [player] * ^+night vision enabled" );
            }
            else
            {
                thread disable_nvg();
                self iprintln( "ߝ [player] * ^1night vision disabled" );
            }
        }

        wait 0.05;
    }
}

enable_nvg()
{
    thread scripts\mp\equipment\nvg::runnvg();
}

disable_nvg()
{
    self nightvisionviewoff();
    self notify("nvg_monitor");
    scripts\mp\equipment\nvg::clearnvg(1);
}

watch_oob()
{
    self endon( "disconnect" );
    self endon( "death" );
    level endon( "game_ended" );
    var_0 = getdvarint( "oob", 0 );

    if ( var_0 == 1 )
        thread disable_oob();

    for (;;)
    {
        var_1 = getdvarint( "oob", 0 );

        if ( var_1 != var_0 )
        {
            var_0 = var_1;

            if ( var_1 == 1 )
            {
                thread disable_oob();
                self iprintln( "ߝ [game] * ^+now bypassing out of bounds" );
            }
            else
            {
                thread enable_oob();
                self iprintln( "ߝ [game] * ^1no longer bypassing out of bounds" );
            }
        }

        if ( var_1 == 1 )
        {
            if ( self scripts\mp\utility\entity::touchingoobtrigger() && !scripts\mp\utility\entity::istouchingboundsnullify( self ) )
            {
                self.allowedintrigger = 1;
                wait 0.5;
                self.allowedintrigger = 0;
            }

            if ( isdefined( self.vehicle ) && isdefined( self.vehicle.health ) && self.vehicle.health > 0 )
            {
                scripts\mp\outofbounds::clearoob( self.vehicle, 0 );
                self setclientomnvar( "ui_out_of_bounds_type", 0 );
                self setclientomnvar( "ui_out_of_bounds_countdown", 0 );
            }
        }

        wait 0.05;
    }
}

disable_oob()
{
    scripts\mp\outofbounds::enableoobimmunity( self );
    self.allowedintrigger = 1;
    self.alreadytouchingtrigger = 0;

    if ( isdefined( self.vehicle ) && isdefined( self.vehicle.health ) && self.vehicle.health > 0 )
    {
        scripts\mp\outofbounds::clearoob( self.vehicle, 0 );
        self setclientomnvar( "ui_out_of_bounds_type", 0 );
        self setclientomnvar( "ui_out_of_bounds_countdown", 0 );
    }
}

enable_oob()
{
    scripts\mp\outofbounds::disableoobimmunity( self );
    self.allowedintrigger = 0;

    if ( isdefined( self.alreadytouchingtrigger ) )
        self.alreadytouchingtrigger = undefined;
}

watch_give_weapon()
{
    self endon( "disconnect" );
    self endon( "death" );
    level endon( "game_ended" );
    var_0 = getdvar( "give_weapon", "" );

    for (;;)
    {
        var_1 = getdvar( "give_weapon", "" );

        if ( var_1 != var_0 && var_1 != "" )
        {
            var_0 = var_1;
            self giveweaponviadvr( var_1 );
            setdvar( "give_weapon", "" );
            var_0 = "";
        }

        wait 0.05;
    }
}

giveweaponviadvr( var_0 )
{
    var_1 = getdvarint( "weapon_variant", -1 );
    var_2 = [ "camo_11c", "camo_11d", "camo_11a", "camo_11b" ];
    var_3 = var_2[randomint( var_2.size )];
    var_4 = var_3;
    var_5 = undefined;

    if ( isstring( var_0 ) )
    {
        if ( var_1 >= 0 )
        {
            var_6 = scripts\mp\class::buildweapon( var_0, [], "none", "none", var_1, undefined, undefined, undefined, scripts\cp_mp\utility\game_utility::isnightmap() );

            if ( isdefined( var_6 ) )
            {
                var_5 = var_6;
                self iprintln( "ߝ [weapon] * ^6using variant: ^7" + var_1 );
            }
        }

        if ( !isdefined( var_5 ) )
        {
            var_6 = scripts\mp\class::buildweapon( var_0, [], var_3, "none", -1, undefined, undefined, undefined, scripts\cp_mp\utility\game_utility::isnightmap() );

            if ( isdefined( var_6 ) )
                var_5 = var_6;
            else
                var_5 = getcompleteweaponname( var_0 );
        }
    }

    if ( !isdefined( var_5 ) || var_5.basename == "none" )
        self iprintln( "ߝ [weapon] * ^1invalid weapon: ^7" + var_0 );
    else
    {
        if ( self hasweapon( var_5 ) )
        {
            self iprintln( "ߝ [weapon] * ^+already have: ^7" + var_0 );
            return;
        }

        var_7 = self scripts\cp_mp\utility\inventory_utility::getcurrentprimaryweaponsminusalt();
        var_8 = getdvarint( "max_weapons", 2 );

        if ( var_7.size >= var_8 )
        {
            var_9 = self getcurrentweapon();

            if ( isdefined( var_9 ) && var_9.basename != "none" )
                self scripts\cp_mp\utility\inventory_utility::_takeweapon( var_9 );
        }

        self scripts\cp_mp\utility\inventory_utility::_giveweapon( var_5 );

        if ( getdvarint( "weapon_switch", 1 ) > 0 )
            self scripts\cp_mp\utility\inventory_utility::_switchtoweaponimmediate( var_5 );

        self refill_weapon_ammo( var_5 );
        self play( "ui_mp_weapon_pickup" );
        scripts\mp\weapons::fixupplayerweapons( self, var_5 );

        if ( var_1 >= 0 )
        {
            self iprintln( "ߝ [weapon] * ^+weapon given: ^7" + var_0 + " ^6(variant " + var_1 + ")" );
            return;
        }

        self iprintln( "ߝ [weapon] * ^+weapon given: ^7" + var_0 + " ^6(" + var_4 + ")" );
    }
}

watch_variant()
{
    self endon( "disconnect" );
    self endon( "death" );
    level endon( "game_ended" );
    var_0 = getdvar( "give_variant", "" );

    for (;;)
    {
        var_1 = getdvar( "give_variant", "" );

        if ( var_1 != var_0 && var_1 != "" )
        {
            var_0 = var_1;
            self applyvarianttocurrentweapon( int( var_1 ) );
            setdvar( "give_variant", "" );
            var_0 = "";
        }

        wait 0.05;
    }
}

applyvarianttocurrentweapon( var_0 )
{
    var_1 = self getcurrentweapon();

    if ( !isdefined( var_1 ) || var_1.basename == "none" )
    {
        self iprintln( "ߝ [weapon] * ^1no weapon equipped" );
        return;
    }

    var_2 = isdefined( var_1.attachments ) ? var_1.attachments : ""; // [] -> ""
    var_3 = isdefined( var_1.camo ) ? var_1.camo : "none";
    var_4 = scripts\mp\utility\weapon::getweaponrootname( var_1 );

    if ( !isdefined( var_4 ) )
        var_4 = var_1.basename;

    var_5 = scripts\mp\class::buildweapon( var_4, var_2, var_3, "none", var_0, undefined, undefined, undefined, scripts\cp_mp\utility\game_utility::isnightmap() );

    if ( !isdefined( var_5 ) || var_5.basename == "none" )
    {
        self iprintln( "ߝ [weapon] * ^1failed to apply variant: ^7" + var_0 );
        return;
    }

    self scripts\cp_mp\utility\inventory_utility::_takeweapon( var_1 );
    wait 0.05;
    self scripts\cp_mp\utility\inventory_utility::_giveweapon( var_5 );
    self scripts\cp_mp\utility\inventory_utility::_switchtoweaponimmediate( var_5 );
    self refill_weapon_ammo( var_5 );
    var_6 = "[weapon] * ^+variant applied: ^7" + var_0;

    if ( var_3 != "none" )
        var_6 = var_6 + ( " ^6(camo: " + var_3 + ")" );

    if ( var_2.size > 0 )
        var_6 = var_6 + ( " ^+(" + var_2.size + " attachments)" );

    self iprintln( var_6 );
    self play( "ui_mp_weapon_pickup" );
}

watch_akimbo()
{
    self endon( "disconnect" );
    self endon( "death" );
    level endon( "game_ended" );
    var_0 = 0;

    for (;;)
    {
        var_1 = getdvarint( "akimbo", -1 );
        var_2 = gettime();

        if ( var_1 != -1 && var_2 - var_0 > 500 )
        {
            var_0 = var_2;

            if ( var_1 == 0 )
                self applyakimbotocurrentweapon( 0 );
            else if ( var_1 == 1 )
                self applyakimbotocurrentweapon( 1 );

            setdvar( "akimbo", -1 );
        }

        wait 0.05;
    }
}

applyakimbotocurrentweapon( var_0 )
{
    var_1 = self getcurrentweapon();

    if ( !isdefined( var_1 ) || !isdefined( var_1.basename ) || var_1.basename == "none" || var_1.basename == "" || var_1.basename == "iw8_me_fists" )
    {
        self iprintln( "ߝ [weapon] * ^1cannot apply akimbo to current weapon" );
        return;
    }

    var_2 = isdefined( var_1.attachments ) ? var_1.attachments : ""; // [] -> ""
    var_3 = isdefined( var_1.camo ) ? var_1.camo : "none";
    var_4 = isdefined( var_1.variantid ) ? var_1.variantid : -1;
    var_5 = scripts\mp\utility\weapon::getweaponrootname( var_1 );

    if ( !isdefined( var_5 ) )
        var_5 = var_1.basename;

    var_6 = scripts\mp\class::buildweapon( var_5, var_2, var_3, "none", var_4, undefined, undefined, undefined, scripts\cp_mp\utility\game_utility::isnightmap() );

    if ( !isdefined( var_6 ) || var_6.basename == "none" )
    {
        self iprintln( "ߝ [weapon] * ^1failed to build weapon" );
        return;
    }

    self scripts\cp_mp\utility\inventory_utility::_takeweapon( var_1 );
    wait 0.05;
    self scripts\cp_mp\utility\inventory_utility::_giveweapon( var_6, undefined, var_0, 1 );
    wait 0.05;
    self scripts\cp_mp\utility\inventory_utility::_switchtoweaponimmediate( var_6 );
    wait 0.05;
    self refill_weapon_ammo( var_6 );
    self iprintln( var_0 ? "^+enabled" : "^1disabled" + " ^7akimbo: ^+" + var_5 + var_4 >= 0 ? " ^6(variant " + var_4 + ")" : "" );
}

watch_attachment()
{
    self endon( "disconnect" );
    self endon( "death" );
    level endon( "game_ended" );
    var_0 = getdvar( "add_attachment", "" );

    for (;;)
    {
        var_1 = getdvar( "add_attachment", "" );

        if ( var_1 != var_0 && var_1 != "" )
        {
            var_0 = var_1;
            self addattachmenttocurrentweapon( var_1 );
            setdvar( "add_attachment", "" );
            var_0 = "";
        }

        wait 0.05;
    }
}

addattachmenttocurrentweapon( var_0 )
{
    var_1 = self getcurrentweapon();

    if ( !isdefined( var_1 ) || var_1.basename == "none" )
    {
        self iprintln( "ߝ [weapon] * ^1no weapon equipped" );
        return;
    }

    var_2 = isdefined( var_1.variantid ) ? var_1.variantid : -1;
    var_3 = isdefined( var_1.camo ) ? var_1.camo : "none";
    var_4 = scripts\mp\weapons::addattachmenttoweapon( var_1, var_0 );

    if ( !isdefined( var_4 ) )
    {
        self iprintln( "ߝ [weapon] * ^1failed to add attachment: ^7" + var_0 );
        return;
    }

    self scripts\cp_mp\utility\inventory_utility::_takeweapon( var_1 );
    wait 0.05;
    self scripts\cp_mp\utility\inventory_utility::_giveweapon( var_4 );
    self scripts\cp_mp\utility\inventory_utility::_switchtoweaponimmediate( var_4 );
    self refill_weapon_ammo( var_4 );
    var_5 = "[weapon] * ^+attachment added: ^7" + var_0;

    if ( var_2 >= 0 )
        var_5 = var_5 + ( " ^6(variant " + var_2 + ")" );

    if ( var_3 != "none" )
        var_5 = var_5 + ( " ^6(" + var_3 + ")" );

    self iprintln( var_5 );
}

watch_executions()
{
    self endon( "disconnect" );
    self endon( "death" );
    level endon( "game_ended" );
    var_0 = getdvar( "set_execution", "" );

    for (;;)
    {
        var_1 = getdvar( "set_execution", "" );

        if ( var_1 != var_0 && var_1 != "" )
        {
            var_0 = var_1;
            self giveexecutionviadvar( var_1 );
            setdvar( "set_execution", "" );
            var_0 = "";
        }

        wait 0.05;
    }
}

giveexecutionviadvar(execution)
{
    scripts\cp_mp\execution::_giveexecution(execution);
    self iprintln("ߝ [specials] * ^+execution set: ^7" + execution);
    self play("ui_mp_achieve_challenge");
}

watch_killstreaks()
{
    self endon( "disconnect" );
    self endon( "death" );
    level endon( "game_ended" );
    var_0 = getdvar( "give_streak", "" );

    for (;;)
    {
        var_1 = getdvar( "give_streak", "" );

        if ( var_1 != var_0 && var_1 != "" )
        {
            var_0 = var_1;
            self givekillstreakviadvr( var_1 );
            setdvar( "give_streak", "" );
            var_0 = "";
        }

        wait 0.05;
    }
}

givekillstreakviadvr( var_0 )
{
    var_1 = strtok( var_0, " " );
    var_2 = var_1[0];
    var_3 = 0;

    if ( var_1.size > 1 && var_1[1] == "1" )
        var_3 = 1;
    else if ( getdvarint( "ks_auto_activate", 1 ) > 0 )
        var_3 = 1;

    var_4 = scripts\mp\killstreaks\killstreaks::createstreakitemstruct( var_2 );

    if ( !isdefined( var_4 ) )
    {
        self iprintln( "ߝ [specials] * ^1invalid killstreak: ^7" + var_2 );
        return;
    }

    scripts\mp\killstreaks\killstreaks::awardkillstreakfromstruct( var_4, "other" );

    if ( istrue( var_3 ) )
    {
        wait 0.05;
        self notify( "ks_action_4" );
    }

    self play( "ui_killstreak_select" );
    self iprintln( "ߝ [specials] * ^+killstreak given: ^7" + var_2 + var_3 ? " ^4(Auto)" : "" );
}

watch_supers()
{
    self endon( "disconnect" );
    self endon( "death" );
    level endon( "game_ended" );
    var_0 = getdvar( "super", "" );

    for (;;)
    {
        var_1 = getdvar( "super", "" );

        if ( var_1 != var_0 && var_1 != "" )
        {
            var_0 = var_1;
            self givesuperviadvr( var_1 );
            setdvar( "super", "" );
            var_0 = "";
        }

        wait 0.05;
    }
}

givesuperviadvr( super )
{
    if ( !isdefined( super ) || super == "" )
    {
        self iprintln( "ߝ [specials] * ^1invalid super name" );
        return;
    }

    data = level.superglobals.staticsuperdata[super];

    if ( !isdefined( data ) )
    {
        self iprintln( "ߝ [specials] * ^1invalid super: ^7" + super );
        self iprintln( "ߝ [specials] * ex: ^+tac_ops_spawn | tacops_uav | tacops_heli | taco_ops_gas | tacops_artillery | tacops_turret");
        return;
    }

    self thread scripts\mp\supers::givesuper( "super_" + super, self, 1 );
    self iprintln( "ߝ [specials] * ^+super given: ^7" + super );
}

clean_killcam()
{
    level endon("killcam_ended"); // make sure it still ends at some point in case 
    for (;;)
    {
        self setclientomnvar("ui_killcam_killedby_item_type", -1);
        self setclientomnvar("ui_killcam_killedby_item_id", -1);
        self setclientomnvar("ui_killcam_killedby_id", -1);
        self setclientomnvar("ui_killcam_victim_id", -1);
        self setclientomnvar("ui_killcam_killedby_loot_variant_id", -1);
        self setclientomnvar("ui_killcam_killedby_weapon_rarity", -1);

        for ( x = 0; x < 6; x++ )
            self setclientomnvar( "ui_killcam_killedby_perk" + x, -1 );

        wait 0.15;
    }
}

headbounces() // will be added in eventually
{
    self endon("stop_head_bounces");
    self endon("disconnect");
    level endon("game_ended");
    
    for (;;)
    {
        foreach(player in level.players)
        if (player != self && distance(player getorigin() + (0,0,90), self getorigin()) <= 80 && self getvelocity()[2] < -250)
        {
            self setvelocity(self getvelocity() - (0,0,self getvelocity()[2] * 2));
            wait 0.2;
        }
        wait 0.05;
    }
}

start_weapon_monitor(args)
{
    if (int(args[0]) == 1)
    {
        self notify("stop_weapon_monitor");
        self thread monitor_weapons();
        self setpers("weapon_monitor", true);
        self iprintln( "ߝ [player] * ^2weapon monitor enabled" );
    }
    else
    {
        self notify("stop_weapon_monitor");
        self setpers("weapon_monitor", false);
        self iprintln( "ߝ [player] * ^1weapon monitor disabled" );
    }
}

monitor_weapons()
{
    self endon("disconnect");
    self endon("stop_weapon_monitor");
    level endon("game_ended");

    for (;;)
    {
        self waittill("weapon_change");

        a = self getcurrentweapon().basename;
        b = self scripts\cp_mp\utility\inventory_utility::getcurrentprimaryweaponsminusalt().basename;
        c = self getaltweapon().basename;
        
        self iprintln("current: ^5" + a);
        self iprintln("minus alt: ^5" + b);
        self iprintln("alt: ^5" + c);
    }
}

enemy_always_watching()
{
    level endon("game_ended");
    self endon("disconnect");

    for (;;)
    {
        if (isdefined(level.players) && level.players.size > 0)
        {
            foreach (player in level.players)
            {
                if (player != self && player.team != self.team)
                {
                    player setplayerangles(vectortoangles(((self.origin)) - (player gettagorigin("j_head"))));
                }
                wait 5;
            }
        }
        wait 5;
    }
}

give_care_package(args) // gotta test both of these again
{
    if (args[0])
    thread scripts\mp\killstreaks\killstreaks::awardkillstreakfromstruct("airdrop_assault", 0, 0, self);
}

give_uav(args)
{
    if (args[0])
    thread scripts\mp\killstreaks\killstreaks::awardkillstreakfromstruct("uav", 0, 0, self);
}

instashoots(args)
{
    if (int(args[0]) == 1)
    {
        self notify("stop_instashoots");
        self thread do_instashoots();
        self setpers("instashoots", true);
        self iprintln("ߝ [player] * ^+instashoots enabled");
    }
    else
    {
        self notify("stop_instashoots");
        self setpers("instashoots", false);
        self iprintln("ߝ [player] * ^+instashoots disabled");
    }
}


do_instashoots()
{
    level endon("game_ended");
    self endon("disconnect");
    self endon("stop_instashoots");

    for (;;)
    {
        self waittill("weapon_change", weapon);
        self setspawnweapon(weapon);
        // self thread instashoot_logic();
        wait 0.05;
    }
}

instashoot_logic()
{
    self endon("disconnect" );
    self endon("reload_rechamber");
    self endon("stop_instashoots");
    self endon("death");
    self endon("end_logic");
    self endon("next_weapon");
    self endon("weapon_armed");
    self endon("weapon_fired");
    self endon("sprinting");

    for (;;)
    {
        weapon = self getcurrentweapon();
        
        if (is_valid_weapon(weapon))
        {
            if (self attackbuttonpressed() && !self isreloading() && ( !self issprinting() && !self isonladder() && !self ismantling()))
            {
                self disableweapons();
                self setweaponammoclip(weapon, weaponclipsize(weapon));
                wait 0.05;
                self enableweapons();
                self notify("end_logic");
            }
        }
        else
            self notify("end_logic");

        wait 0.01;
    }
}

// utility
register_buttons()
{
    foreach (value in strtok("+sprint,+actionslot 1,+actionslot 2,+actionslot 3,+actionslot 4,+frag,+smoke,+melee,+melee_zoom,+stance,+gostand,+switchseat,+usereload", ",")) 
        self notifyonplayercommand(value, value);
}

is_valid_weapon(weapon)
{
    if (!isdefined (weapon))
        return false;

    // snipers, marksman rifles, all bolt actions
    weapon_class = weaponclass(weapon);
    if (weapon_class == "sniper" || weapon_class == "dmr")
        return true;

    switch (weapon)
    {
        case "equip_throwing_knife":
            return true;
        default:
            return false;
    }
}

switchto(weapon) 
{
    current = self getcurrentweapon();
    self takeweapon(current);
    self switchtoweapon(weapon);
    wait 0.05;
    self giveweapon(current);
}

alwayscan(weapon)
{
    self takegood(weapon);
    self givegood(weapon);
    self switchtoweapon(weapon);
}

nacto(weapon)
{
    x = self getcurrentweapon();
    self takegood(x);
    if (!self hasweapon(weapon))
    self giveweapon(weapon);
    self switchtoweapon(weapon);
    waitframe();
    waitframe();
    self givegood(x);
}

instaswapto(weapon)
{
    x = self getcurrentweapon();
    self takegood(x);
    if(!self hasweapon(weapon))
    self giveweapon(weapon);
    self setspawnweapon(weapon);
    waitframe();
    waitframe();
    self givegood(x);
}

takegood(gun) 
{
    self.goodgun = gun;
    self.getclip =  self getweaponammoclip(gun);
    self.getstock = self getweaponammostock(gun);
    self takeweapon(gun);
}

givegood(gun) 
{
    self giveweapon(self.goodgun);
    self setweaponammoclip(self.goodgun, self.getclip);
    self setweaponammostock(self.goodgun, self.getstock);
}

getprevweapon() 
{
    z = self getrealweapons();
    x = self getcurrentweapon();
    for (i = 0 ; i < z.size ; i++)
    {
        if (x == z[i])
        {
            y = i - 1;
            if (y < 0)
            y = z.size - 1;

            if (isdefined(z[y]))
                return z[y];
            else
                return z[0];
        }
    }
}

getnextweapon()
{
    z = self getrealweapons();
    x = self getcurrentweapon();
    for(i = 0 ; i < z.size ; i++)
    {
        if (x == z[i])
        {
            if (isdefined(z[i + 1]))
            return z[i + 1];
            else
            return z[0];
        }
    }
}

loadpers(key, func, args)
{
    if (!self haspers(key))
    {
        self setpersifuni(key, false);
        return;
    }

    wait 0.05;
    if (args)
    {
        self thread [[func]](args);
        return;
    }

    self thread [[func]]();
}

setpers(key, value)
{
    self.pers[key] = value;
}

getpers(key)
{
    return self.pers[key];
}

setpersifuni(key, value)
{
    if (!isdefined(self.pers[key]))
        self.pers[key] = value;
}

haspers(pers)
{
    return isdefined(self.pers[pers]) && self.pers[pers];
}

perstovector(pers)
{
    keys = strtok(pers, ",");
    return (float(keys[0]), float(keys[1]), float(keys[2]));
}

getcrosshair()
{
    point = scripts\engine\trace::_bullet_trace(self geteye(), self geteye() + anglestoforward(self getplayerangles()) * 1000000, 0, self)["position"];
    return point;
}

list(key)
{
    token = strtok(key, ",");
    return token;
}

get_players(team)
{
    return scripts\mp\utility\teams::getteamdata(team, "players");
}

play(sound, type) // jukeboxxxx
{
    switch (type)
    {
        case "all":
        case "global":
        case "world":
            self playsound(sound);
        case "team":
            self playsoundtoteam(sound);
        case "loop":
            self playloopsound(sound);
        case "pos":
            playsoundatpos(self.origin, sound);
        default:
            self playlocalsound(sound);
    }
}

round_manager()
{
    level endon("game_ended");

    random_round_axis = randomint(5);
    random_round_ally = randomint(5);
    rounds_played = (random_round_axis + random_round_ally);

    self waittill("killcam_ended");
    game["roundsWon"]["axis"] = random_round_axis;
    game["roundsWon"]["allies"] = random_round_ally;
    game["teamScores"]["allies"] = random_round_ally;
    game["teamScores"]["axis"] = random_round_axis;
    game["roundsplayed"] = rounds_played;
    game["switchedsides"] = 0; // never switch sides
}

get_player_by_entnum( data )
{
    foreach (ent in level.players)
    {
        if (ent getentitynumber() == data)
            return ent;
    }
    return undefined;
}

getenemyplayer()
{
    foreach(player in level.players)
        if (player != self && player.pers["team"] != self.pers["team"] && isalive(player))
            return player;

    return self;
}

createcommand(command, desc, callback) // add alias system later
{
    self endon("disconnect");
    level endon("game_ended");

    setdvarifuninitialized(command, desc);

    for (;;)
    {
        while (getdvar(command) == desc)
            wait 0.05;
        args = strtok(getdvar(command), " " );
        if (isdefined(args) && args.size >= 1)    
            self [[callback]](args);
        else
            self [[callback]]();

        waittillframeend;
        setdvar(command, desc);
    }
}

getrealweapons()
{
    return self scripts\cp_mp\utility\inventory_utility::getcurrentprimaryweaponsminusalt();
}

disable_gestures()
{
    self endon("disconnect");
    self endon("begin_killcam");
    for(;;)
    {
        self.disabledgesture = true;
        self.gestureweapon = undefined;
        self setactionslot(1, "");
        self setactionslot(7, "");
        wait 0.05;
    }
}