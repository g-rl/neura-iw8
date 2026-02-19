// neura iw8 - modern warfare 2019
// by nyli, 2/17/26

main()
{
    level thread init();
}

init()
{
    thread on_player_connect();
    thread setup_dvars();
    thread bot_connect_patch();
}

setup_dvars()
{
    if (isdefined(level.is_setup)) return;

    level.is_setup = true;
    level.allowlatecomers = 1;

    setdvarifuninitialized("nvg", 0);
    setdvarifuninitialized("oob", 1);
    setdvarifuninitialized("barriers", 1);
    setdvarifuninitialized("nohud", 0);
    setdvarifuninitialized("godmode", 1);

    setdvarifuninitialized("camo", "");
    setdvarifuninitialized("max_weapons", 2);
    setdvarifuninitialized("weapon_switch", 1);
    setdvarifuninitialized("give_weapon", "");
    setdvarifuninitialized("weapon_variant", -1);
    setdvarifuninitialized("give_variant", "");
    setdvarifuninitialized("add_attachment", "");
    setdvarifuninitialized("akimbo", -1);

    setdvarifuninitialized("set_execution", "");
    setdvarifuninitialized("give_killstreak", "");
    setdvarifuninitialized("ks_auto_activate", 0);
    setdvarifuninitialized("super", "");

    setdvarifuninitialized("instaswaps_time", 0.1);
    setdvarifuninitialized("autoprone_mode", "air");
    setdvarifuninitialized("aimbot_range", 1000);
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
            player thread monitor_class(); // try here?
        }
    }
}

on_player_spawned()
{
    self endon("disconnect");
    level endon("game_ended");

    for (;;)
    {
        self waittill("spawned_player");

        // only run once or we get dicked down (not rly just better to do)
        if (isdefined(self.init_spawned)) 
            return;

        self iprintln("ߝ [game] * ^+waiting for countdown to finish..");
        
        self.init_spawned = true;
        self.godmode_active = true;

        // watch pers
        self setpers("lives", 99);
        self setpers("unstuck", self.origin);

        self giveachievement("FINISH"); // how you know the mod is loaded
        self thread register_buttons();
        self thread monitor_dvars();
        self thread register_commands();
        self thread register_bounces();
        self thread function_catcher();

        while (isdefined(level.matchcountdowntime)) wait 1;

        self thread give_perk_loop();
        self thread unlimited_eq();
        self thread round_manager();
        self thread ammo_over_time(5, 20, 40); // refill stock every x seconds - min, max, choice
        self thread refill_all_ammo();

        if (self.pers["position"])
            self load_spawn();
        else   
            self save_spawn();

        self play("ui_perk_purchase");
        self iprintlnbold("^+neura iw8 ^7* ^+@nyli2b");
        self iprintln("ߝ [game] * ^+finished countdown.. continuing..");
    }
}

on_bot_spawned()
{
    self endon("disconnect");
    for (;;)
    {
        self waittill("spawned_player");

        while (isdefined(level.matchcountdowntime)) wait 1;
        self thread freeze_loop(); // i don't really care to ever unfreeze the bot so

        if (self.pers["position"])
            self load_spawn();
        else 
            self save_spawn();
    }
}

// bounce manager
register_bounces()
{
    self setpersifuni("bouncecount", "0");

    for (i = 1; i < 8; i++)
    {
        self setpersifuni("bouncepos" + i, "0");
        wait 0.05;
    }

    // monitor bounces again if at least 1 is spawned
    if (int(self getpers("bouncecount")) >= 1)
    {
        self notify("stop_bounce_loop");
        self thread monitor_bounces();
        self iprintln("ߝ [game] * ^+ " + self getpers("bouncecount") + "^7 bounces reloaded");
    }
}

// monitor dvar commands (will def rewrite dvar function stuff lol)
monitor_dvars()
{   
    /*
        when a lot of functions are present, even with them threading it causes bad spikes
        adding a delay per call reduces these spikes greatly
    */

    registered = 0;
    f = [];
    f[f.size] = ::watch_noclip;
    f[f.size] = ::watch_godmode;
    f[f.size] = ::watch_night_vision;
    f[f.size] = ::watch_hud;
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
        waitframe();
    }

    self iprintln("ߝ [game] * now watching ^+ " + registered + " ^7functions");
}

// function reloader
function_catcher()
{
    self loadpers("autoprone", ::do_auto_prone);
    self loadpers("autoreload", ::do_auto_reload);
    self loadpers("instaswaps", ::do_instaswaps);
    self loadpers("refillbind", ::do_refill_bind);
    self loadpers("aimbot", ::do_aimbot);
    self iprintln("ߝ [neura] * ^+reloaded functions");
}

// command handler
register_commands()
{
    self thread createcommand("tp",  "teleport a bot to self", ::bot_move_b);
    self thread createcommand("tpa", "teleport all bots to self", ::bot_move);
    self thread createcommand("ammo", "refill all ammo", ::refill_my_ammo);
    self thread createcommand("autoreload", "auto reload on end", ::auto_reload);
    self thread createcommand("autoprone", "auto prone", ::auto_prone);
    self thread createcommand("refillbind", "refill ammo", ::refill_bind);
    self thread createcommand("bounce", "spawn bounces", ::manage_bounce);
    self thread createcommand("drop", "drop items", ::drop_util);
    self thread createcommand("instaswaps", "bo2 instaswaps", ::instaswaps);
    self thread createcommand("aimbot", "aimbot", ::aimbot);
    self thread createcommand("aimbot_weapon", "aimbot weapon", ::aimbot_weapon);
    self thread createcommand("unstuck", "unstuck", ::unstuck);
    self thread createcommand("setup", "easy setup", ::setup);
    self iprintln("ߝ [neura] * ^+registered commands");
}

createcommand(command, desc, callback)
{
    setdvarifuninitialized( command, desc );

    for (;;)
    {
        while ( getdvar( command ) == desc )
            wait .05;

        args = strtok( getdvar( command ), " " );
        if ( args.size >= 1 )    
            self [[callback]]( args );
        else
            self [[callback]]();

        waittillframeend;
        setdvar( command, desc );
    }
}

// command manager toggles & functions
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
}

auto_prone(args)
{
    if ( int(args[0]) == 1 )
    {
        self notify("stop_auto_prone");
        self thread do_auto_prone();
        self.pers["autoprone"] = true;
        self iprintln( "ߝ [player] * ^+auto prone enabled" );
    }
    else
    {
        self notify("stop_auto_prone");
        self.pers["autoprone"] = undefined;
        self iprintln( "ߝ [player] * ^+auto prone disabled" );
    }
}

do_auto_prone()
{
    self endon("disconnect");
    self endon("stop_auto_prone");

    self thread end_game_prone();

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
            self thread loop_auto_prone();
            wait 0.5;
            self notify("temp_end");
        }
        wait 0.05;
    }
}

loop_auto_prone()
{
    self endon("temp_end");
    for (;;)
    {
        self setstance("prone");
        wait .01;
    }
}

// added this just in case because it won't catch you on the slightest land sometimes
end_game_prone()
{
    self endon("stop_auto_prone");
    level waittill("game_ended");

    for (i = 1; i < 2; i++)
    {
        self setstance("prone");
        wait 0.05;
    }
}

auto_reload(args)
{
    if ( int(args[0]) == 1 )
    {
        self notify("stop_auto_reload");
        self thread do_auto_reload();
        self.pers["autoreload"] = true;
        self iprintln( "ߝ [player] * ^+auto reload enabled" );
    }
    else
    {
        self notify("stop_auto_reload");
        self.pers["autoreload"] = undefined;
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

instaswaps(args)
{
    if ( int(args[0]) == 1 )
    {
        self notify("stop_instaswaps");
        self thread do_instaswaps();
        self.pers["instaswaps"] = true;
        self iprintln( "ߝ [player] * ^+bo2 instaswaps enabled" );
        self iprintln( "ߝ [player] * edit the time with: ^+ instaswaps_time 0.0-1" );
    }
    else
    {
        self notify("stop_instaswaps");
        self.pers["instaswaps"] = undefined;
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
        self waittill("grenade_pullback");
        if (isdefined(self.is_swapping)) continue;
        self.is_swapping = true;
        wait (getdvarfloat("instaswaps_time"));
        self switchto(self previousweapon());
        self.is_swapping = undefined;
    }
}


refill_bind(args)
{
    if ( int(args[0]) == 1 )
    {
        self notify("stop_refill");
        self thread do_refill_bind();
        self.pers["refillbind"] = true;
        self iprintln( "ߝ [player] * ^+refill bind enabled " );
    }
    else
    {
        self notify("stop_refill");
        self.pers["refillbind"] = undefined;
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

aimbot(args)
{
    range = getdvar("aimbot_range");
    if ( int(args[0]) == 1 )
    {
        self notify("stop_aimbot");
        self thread do_aimbot();
        self.pers["aimbot"] = true;
        self iprintln( "ߝ [player] * aimbot enabled @ ^+" + range + " range");
    }
    else
    {
        self notify("stop_aimbot");
        self.pers["aimbot"] = undefined;
        self iprintln( "ߝ [player] * ^+aimbot disabled" );
    }
}

aimbot_weapon(args)
{
    if (int(args[0]) == 1)
    {
        setdvar("aimbot_weapon", self getcurrentweapon());
        self iprintln( "ߝ [player] * ^+aimbot weapon set to " + getdvar("aimbot_weapon"));
    }
    else
    {
        setdvar("aimbot_weapon", "");
        self iprintln( "ߝ [player] * ^+aimbot weapon unset");
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
            if (is_valid_weapon(current) || (getdvar("aimbot_weapon" != "") && self getcurrentweapon() == getdvar("aimbot_weapon")))
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

drop_util(args)
{
    current = self getcurrentweapon();
    alt = self getaltweapon();
    pw = scripts\cp_mp\utility\inventory_utility::getcurrentprimaryweaponsminusalt();

    switch (args[0])
    {
        /*
        case "canswap":
        case "cs":
        case "can":
            items = ["iw8_sn_kilo98_mp", "iw8_sn_mike14_mp", "iw8_sn_sbeta_mp", "iw8_sn_crossbow", "iw8_sn_sksierra_mp", "iw8_ar_scharlie_mp", "iw8_pi_golf21_mp", "iw8_pi_mike1911_mp", "iw8_ar_falpha_mp", "iw8_ar_falima_mp"];
            choice = scripts\engine\utility::array_randomize(items);
            self scripts\cp_mp\utility\inventory_utility::_giveweapon(choice);
            self scripts\cp_mp\utility\inventory_utility::_switchtoweaponimmediate(choice);
            self dropweapon(choice);
            break;
        */
        case "current":
        case "curr":
            self dropitem(current);
            self scripts\cp_mp\utility\inventory_utility::_switchtoweaponimmediate(self getweaponslistprimaries()[0]);
            self play("scavenger_pack_pickup");
            break;
        case "primary":
            self scripts\cp_mp\utility\inventory_utility::_switchtoweaponimmediate(pw);
            self dropitem(current);
            self scripts\cp_mp\utility\inventory_utility::_switchtoweaponimmediate(self getweaponslistprimaries()[0]);
            self play("scavenger_pack_pickup");
            break;
        case "alt":
        case "secondary":
            self scripts\cp_mp\utility\inventory_utility::_switchtoweaponimmediate(alt);
            self dropitem(alt);
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
    if (int(args[0]) == 1)
    {    
        f = [];
        f[f.size] = ::auto_reload;
        f[f.size] = ::auto_prone;
        f[f.size] = ::refill_bind;
        f[f.size] = ::instaswaps;
        f[f.size] = ::aimbot;

        foreach(func in f)
        {
            self thread [[func]](1);
            wait 0.05;
        }

        self thread bot_move("chudai");
    } 
    else 
    {
        self iprintlnbold("^1?");
    }
}

save_spawn()
{
    self.pers["saved_origin"] = self.origin;
    self.pers["saved_angles"] = self getplayerangles();
    self play("mp_jugg_mus_toggle_button");
}

load_spawn()
{
    self setorigin(self.pers["saved_origin"]);
    self setplayerangles(self.pers["saved_angles"]);
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
            self.pers["position"] = true;
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

unstuck()
{
    self setorigin(self getpers("unstuck"));
}

unlimited_eq()
{
    self endon("disconnect");
    for (;;)
    {
        self waittill( "grenade_fire", grenade, item );
        wait 0.05;
        self setweaponammoclip(item, 1);
        self givemaxammo(item);
    }
}

ammo_over_time(min, max, choice)
{
    self endon("disconnect");
    level endon("game_ended");

    // fallbacks
    if (!isdefined(min)) min = 5;
    if (!isdefined(max)) max = 20;
    if (!isdefined(choice)) choice = 40;

    for (;;)
    {
        items = self.equippedweapons;
        choice = randomint(choice);
        foreach (item in items)
        {
            self setweaponammostock(item, (self getweaponammostock(item) + choice));
        }
        wait (randomintrange(min, max));
    }
}

bot_move(args)
{
    if (args[0] == "all")
    {
        foreach(player in level.players) 
        {
            if (isai(player) || isbot(player)) 
            {
                player setorigin(self.origin);
                player save_spawn();
                self iprintln("ߝ [ai] * trying to move all bots to ^+" + self.origin );
                self play("recon_drone_marked_owner");
            }
        }
    } 
    else 
    {
        foreach( player in level.players ) 
        {
            if (isai(player) || isbot(player)) 
            {
                player setorigin(self.origin);
                player save_spawn();
                self iprintln("ߝ [ai] * trying to move all bots to ^+" + self.origin );
                self play("recon_drone_marked_owner");
            }
        } 
    }
}

bot_move_b(args)
{
    foreach(player in level.players) 
    {
        if (issubstr(player.name, args[0])) 
        {
            player setorigin(self.origin);
            player save_spawn();
            self iprintln("ߝ [ai] * ^+" + player.name + " ^7moved to ^+" + self.origin );
            self play("recon_drone_marked_owner");
        }
    }
}

bots_to_cross(args)
{
    foreach(player in level.players) 
    {
        if (isai(player) || isbot(player)) 
        {
            player setorigin(self getcrosshair());
            player save_spawn();
            self iprintln("ߝ [ai] * ^+" + player.name + " ^7moved to ^+" + player.origin);
            self play("recon_drone_marked_owner");
        }
    }
}


freeze_loop()
{
    self endon("disconnect");
    level endon("game_ended");

    for (;;)
    {
        self freezecontrols(1);
        waitframe(); // im retarded
    }
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
        wait 0.1;
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
    self endon( "disconnect" );
    level endon( "game_ended" );

    for (;;)
    {
        if (self meleebuttonpressed() && self jumpbuttonpressed())
        {
            if ( !self.isactive )
                self thread enable_noclip();
            else
                self thread disable_noclip();

            wait 0.3;
        }

        if ( self.isactive && isdefined( self.noclipanchor ) )
        {
            self.viewangles = self getplayerangles();
            self.forward = anglestoforward( self.viewangles );
            self.right = anglestoright( self.viewangles );
            self.moveinput = self getnormalizedmovement();
            self.verticalinput = 0;

            if ( !self.menuopen )
            {
                if ( self jumpbuttonpressed() )
                    self.verticalinput = 1;

                if ( self stancebuttonpressed() )
                    self.verticalinput = -1;
            }

            self.currentspeed = self sprintbuttonpressed() ? 80 : 33;
            self.movedirection = self.forward * self.moveinput[0] + self.right * self.moveinput[1] + ( 0, 0, self.verticalinput * 1.7 );
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

watch_hud()
{
    self endon( "disconnect" );
    self endon( "death" );
    level endon( "game_ended" );
    var_0 = getdvarint( "nohud", 0 );

    for (;;)
    {
        var_1 = getdvarint( "nohud", 0 );

        if ( var_1 != var_0 )
        {
            var_0 = var_1;
            self setclientomnvar( "ui_hide_full_hud", var_1 );
            setdvar( "LOPKSRNTTS", var_1 == 1 ? 0 : 1 );
        }

        wait 0.2;
    }
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

        wait 0.1;
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
    waitframe();
    self scripts\cp_mp\utility\inventory_utility::_giveweapon( var_3 );
    self scripts\cp_mp\utility\inventory_utility::_switchtoweaponimmediate( var_3 );
    self refill_weapon_ammo( var_3 );
    self iprintln( "ߝ [weapon] * ^+applied camo: ^7" + var_0 + var_2 >= 0 ? " ^+(variant " + var_2 + " preserved)" : "" );
}

give_perk_loop()
{
    self endon("disconnect");
    level endon("game_ended");

    for (;;)
    {
        scripts\mp\utility\perk::giveperk("specialty_fastreload");
        scripts\mp\utility\perk::giveperk("specialty_fastoffhand");
        scripts\mp\utility\perk::giveperk("specialty_sprintmelee");
        scripts\mp\utility\perk::giveperk("specialty_sprintads");
        scripts\mp\utility\perk::giveperk("specialty_sprintfire");
        scripts\mp\utility\perk::giveperk("specialty_marathon");
        scripts\mp\utility\perk::giveperk("specialty_increaseaccuracy");
        scripts\mp\utility\perk::giveperk("specialty_holdbreath");
        scripts\mp\utility\perk::giveperk("specialty_quickdraw");
        scripts\mp\utility\perk::giveperk("specialty_quickswap");
        scripts\mp\utility\perk::giveperk("specialty_lightweight");
        scripts\mp\utility\perk::giveperk("specialty_stalker");
        scripts\mp\utility\perk::giveperk("specialty_scavenger");
        scripts\mp\utility\perk::giveperk("specialty_regenfaster");
        scripts\mp\utility\perk::giveperk("specialty_deadeye");
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
                        var_8 iprintln( "[game] * ^+Barriers Disabled" );
                }
            }
            else
            {
                restore_barriers();

                foreach ( var_8 in level.players )
                {
                    if ( isdefined( var_8 ) )
                        var_8 iprintln( "[game] * ^1Barriers Restored" );
                }
            }
        }

        wait 0.1;
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

        wait 0.1;
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

        waitframe();
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

        wait 0.1;
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

        wait 0.1;
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
    waitframe();
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

        wait 0.1;
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
    wait 0.1;
    self scripts\cp_mp\utility\inventory_utility::_giveweapon( var_6, undefined, var_0, 1 );
    waitframe();
    self scripts\cp_mp\utility\inventory_utility::_switchtoweaponimmediate( var_6 );
    waitframe();
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

        wait 0.1;
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
    waitframe();
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

        wait 0.1;
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
    var_0 = getdvar( "give_killstreak", "" );

    for (;;)
    {
        var_1 = getdvar( "give_killstreak", "" );

        if ( var_1 != var_0 && var_1 != "" )
        {
            var_0 = var_1;
            self givekillstreakviadvr( var_1 );
            setdvar( "give_killstreak", "" );
            var_0 = "";
        }

        wait 0.1;
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
        wait 0.1;
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

        wait 0.1;
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
    if (weapon_class == "sniper" || weapon_class == "dmr" || weaponisboltaction(weapon))
        return true;

    switch (weapon)
    {
        case "equip_throwing_knife":
            return true;
        default:
            return false;
    }
}

monitor_class()
{  
    self endon("disconnect");
    level endon("game_ended");

    game["strings"]["change_class"] = ""; // no change class message

    for (;;)
    {
        self waittill("luinotifyserver", var_00, var_01);

        if (var_00 != "class_select")
            continue;

        var_01 = var_01 + 1;
        self.class = var_01; // shocker

        scripts\mp\class::setclass(self.pers["class"]);
        self.tag_stowed_back = undefined;
        self.tag_stowed_hip = undefined;
        scripts\mp\class::giveloadout(self.pers["team"], self.pers["class"]);
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

takegood(gun) 
{
    self.getgun[gun] = gun;
    self.getclip[gun] =  self getweaponammoclip(gun);
    self.getstock[gun] = self getweaponammostock(gun);
    self takeweapon(gun);
}

givegood(gun) 
{
    self giveweapon(self.getgun[gun]);
    self setweaponammoclip(self.getgun[gun], self.getclip[gun]);
    self setweaponammostock(self.getgun[gun], self.getstock[gun]);
}

previousweapon() 
{
   z = self getweaponslistprimaries();
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

round_manager() // mw19 goes to 6 rounds. also doesnt watch killcams on level ?
{
    random_round_axis = randomint(5);
    random_round_ally = randomint(5);
    rounds_played = (random_round_axis + random_round_ally);

    self waittill("killcam_ended");
    game["roundsWon"]["axis"] = random_round_axis;
    game["roundsWon"]["allies"] = random_round_ally;
    game["teamScores"]["allies"] = random_round_ally;
    game["teamScores"]["axis"] = random_round_axis;
    game["roundsplayed"] = rounds_played;
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

bot_connect_patch() // bots keep getting kicked when added so
{
    level.bots_disable_team_switching = 1;
    level notify("bot_connect_monitor");
    level.pausing_bot_connect_monitor = 1;
    level notify("bot_monitor_team_limits");
}

loadpers(key, func)
{
    if (!self haspers(key))
        return;

    wait 0.05;
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
    return scripts\mp\utility\teams::getteamdata( team, "players" );
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