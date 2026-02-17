// neura iw8 - modern warfare 2019
// by nyli, 2/17/26

main()
{
    level thread init();
}

init()
{
    level endon("game_ended");

    level thread on_player_connect();

    setup_dvars();
    fix_bots();
}

setup_dvars()
{
    if (isdefined(level.is_setup)) return;
    level.is_setup = true;

    setdvarifuninitialized( "bot_ignore_player", 0 );
    setdvarifuninitialized( "bot_preset", "" );
    setdvarifuninitialized( "bot_outline", "0" );
    setdvarifuninitialized( "addbot", "" );
    setdvarifuninitialized( "kickbot", "" );
    setdvarifuninitialized( "bot_team", "autoassign" );
    setdvarifuninitialized( "bot_difficulty", "" );
    setdvarifuninitialized( "bot_follow_player", 0 );
    setdvarifuninitialized( "bot_follow_distance", 128 );
    setdvarifuninitialized( "bot_follow_sprint", 0 );
    setdvarifuninitialized( "bot_omniscient", 0 );
    setdvarifuninitialized( "bot_aggro_range", 0 );
    setdvarifuninitialized( "nvg", 1 );
    setdvarifuninitialized( "oob", 1 );
    setdvarifuninitialized( "barriers", 1 );
    setdvarifuninitialized( "aimbot", 1 );
    setdvarifuninitialized( "aimbot_range", 750 );
    setdvarifuninitialized( "nohud", 0 );
    setdvarifuninitialized( "vm", "" );
    setdvarifuninitialized( "give_weapon", "" );
    setdvarifuninitialized( "weapon_variant", -1 );
    setdvarifuninitialized( "give_variant", "" );
    setdvarifuninitialized( "add_attachment", "" );
    setdvarifuninitialized( "akimbo", -1 );
    setdvarifuninitialized( "set_execution", "" );
    setdvarifuninitialized( "give_killstreak", "" );
    setdvarifuninitialized( "ks_auto_activate", 0 );
    setdvarifuninitialized( "super", "" );
    setdvarifuninitialized( "camo", "" );
    setdvarifuninitialized( "max_weapons", 2 );
    setdvarifuninitialized( "weapon_switch", 1 );
    setdvarifuninitialized( "godmode", 1 );
    setdvarifuninitialized( "instaswaps", 1 ); // eq swaps
    setdvarifuninitialized( "refillbind", 1 ); // eq swaps
    setdvarifuninitialized( "autoreload", 1 ); // eq swaps
    setdvarifuninitialized( "autoprone", 1 ); // eq swaps
}

on_player_connect()
{
    level endon("game_ended");

    for(;;)
    {
        level waittill("connected", player);

        if (isai(player) || isbot(player))
            player thread on_bot_spawned();
        else if (player ishost()) 
            player thread on_player_spawned();
    }
}

on_player_spawned()
{
    self endon("disconnect");
    level endon("game_ended");

    for(;;)
    {
        self waittill("spawned_player");
        
        if (isdefined(self.init_spawned)) return; // only run once
        self.init_spawned = true;
        self.godmode_active = true;

        self giveachievement("FINISH"); // u kno its tea when u
        self iprintlnbold("^;neura iw8 ^7* ^;@nyli2b");
        self iprintln("ߝ ^;[neura] * heyyy, " + self.name + " :3");
        self iprintln("ߝ ^;[neura] * running on iw8-mod @nyli2b");
        self register_commands();
        self thread create_notify();
        self thread watch_noclip();
        self thread unlimited_eq();
        self thread set_perks();

        self thread save_pos_bind();
        self thread load_pos_bind();

        // watchers
        self thread watch_godmode();
        self thread watch_aimbot();
        self thread watch_instaswaps(); // bo2 instaswaps
        self thread watch_hud(); // nohud
        self thread watch_weapon_camo(); // camo
        self thread watch_attachment(); // add_attachment
        self thread watch_variant(); // add variant
        self thread watch_akimbo(); // akimbo
        self thread watch_night_vision();
        self thread watch_oob();
        self thread watch_viewmodel();
        self thread watch_addbot(); // addbot
        self thread watch_kickbot(); // kickbot
        self thread watch_bot_difficulty();
        self thread watch_bot_behavior();
        self thread watch_bot_outline();
        self thread watch_self_outline();
        self thread watch_give_weapon(); // give_weapon
        self thread watch_barriers(); // fix_barriers
        self thread watch_executions(); // set_execution
        self thread watch_killstreaks(); // give_killstreak
        self thread watch_supers();

        if (self.pers["saved_pos"])
            self load_spawn();
        else   
            self save_spawn();
    }
}

// commands
register_commands()
{
    self thread createcommand("freeze", "freeze all bots", ::botfreeze);
    self thread createcommand("tp",  "teleport all bots to self", ::botmove_b);
    self thread createcommand("tpa", "teleport a bots to self", ::botmove);
    self thread createcommand("ammo", "refill all ammo", ::refill_my_ammo);
}

createcommand(command, desc, callback)
{
    setdvarifuninitialized( command, desc );

    for(;;)
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

botfreeze( args )
{
    level.botfreeze = int(args[0]);
    setdvar("freeze", level.botfreeze);
    is_frozen = getdvarint("freeze");

    foreach(player in level.players) 
    {
        if (isbot(player) || isai(player))
            player freezecontrols(is_frozen);
    }
}

on_bot_spawned()
{
    self endon( "disconnect" );

    for(;;)
    {
        self waittill( "spawned_player" );

        while (isdefined(level.matchcountdowntime)) wait 1;

        is_frozen = getdvarint("freeze");
        self freezecontrols(is_frozen);

        if (self.pers["saved_pos"])
            self load_spawn();
        else 
            self save_spawn();
    }
}

unlimited_eq()
{
    self endon("disconnect");
    for(;;)
    {
        self waittill( "grenade_fire", grenade, name );
        waittillframeend;
        self setweaponammoclip( name, 1 );
        self givemaxammo( name );
    }
}

aimbot()
{
    level endon("game_ended");
    self endon("disconnect");
    self endon("stop_aimbot");

    for (;;) 
    {
        self waittill( "weapon_fired" );

        center = self getcrosshair();
        range = getdvarint("aimbot_range");

        foreach( player in level.players )
        {
            if (isalive(player)) // prevent hitmarkers on spectators / when dead
            {
                if (player != self) // dont kill yourself :3
                {
                    if ( distance(player.origin, center) < range)
                        player thread [[level.callbackPlayerDamage]]( self, self, player.health, 2, "MOD_RIFLE_BULLET", self getcurrentweapon(), (0, 0, 0), (0, 0, 0), "torso_upper", 0 );
                }
            }
        }
    }
}

watch_aimbot() 
{
    self endon("disconnect");
    level endon("game_ended");

    var_0 = getdvar( "aimbot", "" );

    for (;;)
    {
        var_1 = getdvarint("aimbot", 0);
        range = getdvarint("aimbot_range");

        if ( var_1 != var_0 )
        {
            var_0 = var_1;

            if ( var_1 == 1 )
            {
                self thread aimbot();
                self iprintln( "[player] * ^;aimbot enabled @ " + range + " range");
                self iprintln( "[player] * ^;mode: all weapons");
            }
            else
            {
                self notify("stop_aimbot");
                self iprintln( "[player] * ^1aimbot disabled" );
            }
        }
    }
}

getcrosshair()
{
    point = scripts\engine\trace::_bullet_trace(self geteye(), self geteye() + anglestoforward(self getplayerangles()) * 1000000, 0, self)["position"];
    return point;
}

save_spawn()
{
    self.pers["saved_origin"] = self.origin;
    self.pers["saved_angles"] = self getplayerangles();
}

load_spawn()
{
    self setorigin( self.pers["saved_origin"] );
    self setplayerangles( self.pers["saved_angles"] );
}

botmove(args)
{
    if (args[0] == "all")
    {
        foreach( player in level.players ) 
        {
            if ( isai( player ) || isbot( player ) ) 
            {
                    player setorigin( self.origin );
                    player save_spawn();
                    self iprintln("[bot] * attemtping to move all bots to ^;" + self.origin );
            }
        }
    }
}

botmove_b(args)
{
    foreach( player in level.players ) 
    {
        if ( issubstr( player.name, args[0] ) ) 
        {
            player setorigin( self.origin );
            player save_spawn();
            self iprintln("[bot] * ^;" + player.name + " ^7moved to ^;" + self.origin );
        }
    }
}

save_pos_bind()
{
    level endon("game_ended");

    for(;;)
    {
        self waittill("+actionslot 3");
        if (self getstance() == "crouch")
        {
            self save_spawn();
            self iprintln("[position] * saved @ ^;" + self.origin);
            self.pers["saved_pos"] = true;
            waittillframeend;
        }
    }
}

load_pos_bind()
{
    level endon("game_ended");

    for(;;)
    {
        self waittill("+actionslot 2");
        if (self getstance() == "crouch")
            self load_spawn();
        
        waittillframeend;
    }
}

create_notify()
{
    foreach (value in strtok("+sprint,+actionslot 1,+actionslot 2,+actionslot 3,+actionslot 4,+frag,+smoke,+melee,+melee_zoom,+stance,+gostand,+switchseat,+usereload", ",")) 
        self notifyonplayercommand(value, value);
}

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
                    self iprintln( "[player] * ^2godmode enabled" );
            }
            else
            {
                self notify( "stop_godmode" );
                godmode_disable();

                if ( !isdefined( self.noclip_autogod ) )
                    self iprintln( "[player] * ^1godmode disabled" );
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
        if (self getstance() == "crouch" && self meleebuttonpressed())
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
    self iprintln("[ufo] * started @ ^;" + self.origin);
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

    self iprintln("[ufo] * ended at @ ^1" + self.origin);
}



watch_instaswaps() 
{
    self endon("disconnect");
    level endon("game_ended");

    var_0 = getdvar( "instaswaps", "" );

    for (;;)
    {
        var_1 = getdvarint( "instaswaps", 0 );

        if ( var_1 != var_0 )
        {
            var_0 = var_1;

            if ( var_1 == 1 )
            {
                self thread instaswaps();
                self iprintln( "[player] * ^;bo2 instaswaps enabled" );
            }
            else
            {
                self notify("stop_instaswaps");
                self iprintln( "[player] * ^1bo2 instaswaps disabled" );
            }
        }
    }
}

instaswaps()
{
    self endon("disconnect");
    level endon("game_ended");
    self endon("stop_instaswaps");

    for(;;)
    {
        self waittill("grenade_pullback");
        wait 0.05;
        self switchto(self previousweapon());
    }
}

set_perks()
{
    self setperk("specialty_falldamage");
    self setperk("specialty_quickswap");
}

binomial(x, y)
{
    return (factorial(y) / (factorial(x) * factorial(y - x)));
}

factorial( x )
{
    c = 1;
    if (x == 0) return 1;
    for(i = 1; i <= x; i++)
        c = c * i;
    return c;
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
        self iprintln( "[weapon] * ^1failed to apply camo: ^7" + var_0 );
        return;
    }

    self scripts\cp_mp\utility\inventory_utility::_takeweapon( var_1 );
    wait 0.05;
    self scripts\cp_mp\utility\inventory_utility::_giveweapon( var_3 );
    self scripts\cp_mp\utility\inventory_utility::_switchtoweaponimmediate( var_3 );
    self refillweaponammo( var_3 );
    self iprintln( "[weapon] * ^;applied camo: ^7" + var_0 + var_2 >= 0 ? " ^;(variant " + var_2 + " preserved)" : "" );
}

refill_my_ammo(args)
{
    if (args == "all")
        self thread refill_all_ammo();
    else
        self thread refill_all_ammo();
}

refill_all_ammo()
{
    var_0 = self.equippedweapons;

    foreach ( var_2 in var_0 )
    {
        self givemaxammo( var_2 );
        self setweaponammostock( var_2, 999 );
        self setweaponammoclip( var_2, 999 );
        self setweaponammoclip( var_2, 999, "left" );
        self setweaponammoclip( var_2, 999, "_encstr_A5AD056A019C63" );
        self setweaponammoclip( var_2, 999, "_encstr_B1AD05C65666E8" );
        self setweaponammoclip( var_2, 999, "right" );
        self setweaponammoclip( var_2, 999, "_encstr_8253060E2B5FE330" );
        self setweaponammoclip( var_2, 999, "_encstr_9353062E718710C9" );
    }
}

refillweaponammo( var_0 )
{
    self givemaxammo( var_0 );
    self setweaponammostock( var_0, 999 );
    self setweaponammoclip( var_0, 999 );
    self setweaponammoclip( var_0, 999, "left" );
    self setweaponammoclip( var_0, 999, "_encstr_A5AD056A019C63" );
    self setweaponammoclip( var_0, 999, "_encstr_B1AD05C65666E8" );
    self setweaponammoclip( var_0, 999, "right" );
    self setweaponammoclip( var_0, 999, "_encstr_8253060E2B5FE330" );
    self setweaponammoclip( var_0, 999, "_encstr_9353062E718710C9" );
}

watch_addbot()
{
    self endon( "disconnect" );
    level endon( "game_ended" );

    for (;;)
    {
        var_0 = getdvar( "addbot", "" );

        if ( var_0 != "" )
        {
            setdvar( "addbot", "" );

            var_1 = int( var_0 );
            var_2 = tolower( getdvar( "bot_team", "autoassign" ) );
            var_3 = parse_team_input( var_2, self );
            var_4 = parse_difficulty_input( getdvar( "bot_difficulty", "" ) );

            if ( var_1 < 1 )
                var_1 = 1;

            if ( var_1 > 100 )
                var_1 = 100;

            scripts\mp\bots\bots::spawn_bots( var_1, var_3, undefined, undefined, undefined, var_4 );
            var_5 = "";

            if ( isdefined( var_4 ) )
                var_5 = " ^;at difficulty: ^7" + var_4;

            var_6 = get_team_display_name( var_3, self );
            self iprintln( "[bot] * ^;Spawning ^7" + var_1 + " ^;bot(s) on team: ^7" + var_6 + var_5 );
        }

        wait 0.25;
    }
}

watch_kickbot()
{
    self endon( "disconnect" );
    level endon( "game_ended" );

    for (;;)
    {
        var_0 = getdvar( "kickbot", "" );

        if ( var_0 != "" )
        {
            setdvar( "kickbot", "" );

            if ( !self ishost() )
            {
                self iprintln( "[bot] * ^1Host only" );
                continue;
            }

            var_1 = int( var_0 );
            var_2 = tolower( getdvar( "bot_team", "autoassign" ) );
            var_3 = parse_team_input( var_2, self );
            var_4 = 0;

            if ( var_1 < 1 )
                var_1 = 1;

            foreach ( var_6 in level.players )
            {
                if ( var_4 >= var_1 )
                    break;

                if ( !isbot( var_6 ) )
                    continue;

                if ( var_3 != "autoassign" && var_6.team != var_3 )
                    continue;

                kick( var_6 getentitynumber(), "EXE/PLAYERKICKED" );
                var_4++;
                wait 0.1;
            }

            self iprintln( "[bot] * ^;Kicked ^7" + var_4 + " ^;bot(s)" );
        }

        wait 0.25;
    }
}

watch_bot_difficulty()
{
    self endon( "disconnect" );
    level endon( "game_ended" );

    for (;;)
    {
        var_0 = getdvar( "setbotdifficulty", "" );

        if ( var_0 != "" )
        {
            setdvar( "setbotdifficulty", "" );

            if ( !self ishost() )
            {
                self iprintln( "[bot] * ^1Host only" );
                continue;
            }

            var_1 = parse_difficulty_input( var_0 );

            if ( !isdefined( var_1 ) )
            {
                self iprintln( "[bot] * ^1Invalid difficulty. Use: recruit, regular, hardened, or veteran" );
                continue;
            }

            var_2 = tolower( getdvar( "bot_team", "autoassign" ) );
            var_3 = parse_team_input( var_2, self );
            var_4 = 0;

            foreach ( var_6 in level.players )
            {
                if ( !isbot( var_6 ) )
                    continue;

                if ( var_3 != "autoassign" && var_6.team != var_3 )
                    continue;

                var_6 scripts\mp\bots\bots_util::bot_set_difficulty( var_1 );
                var_6.pers["botDifficulty"] = var_1;
                var_4++;
            }

            self iprintln( "[bot] * ^;Changed difficulty to ^7" + var_1 + " ^;for ^7" + var_4 + " ^;bot(s)" );
        }

        wait 0.25;
    }
}

parse_team_input( var_0, var_1 )
{
    if ( !isdefined( var_1 ) || !isdefined( var_1.team ) )
        return "autoassign";

    var_2 = var_1.team;

    if ( var_0 == "allies" || var_0 == "ally" || var_0 == "friend" || var_0 == "same" )
        return var_2;

    if ( var_0 == "axis" || var_0 == "enemy" || var_0 == "enemies" )
    {
        if ( var_2 == "allies" )
            return "axis";
        else if ( var_2 == "axis" )
            return "allies";
    }

    if ( var_0 == "autoassign" || var_0 == "auto" )
        return "autoassign";

    return "autoassign";
}

get_team_display_name( var_0, var_1 )
{
    if ( !isdefined( var_1 ) || !isdefined( var_1.team ) )
        return var_0;

    if ( var_0 == var_1.team )
        return var_0 + " (Allies/Same Team)";
    else if ( var_0 == "autoassign" )
        return "Autoassign";
    else
        return var_0 + " (Enemies/Opposite Team)";
}

parse_difficulty_input( var_0 )
{
    var_0 = tolower( var_0 );

    if ( var_0 == "recruit" || var_0 == "easy" || var_0 == "1" )
        return "recruit";

    if ( var_0 == "regular" || var_0 == "normal" || var_0 == "2" )
        return "regular";

    if ( var_0 == "hardened" || var_0 == "hard" || var_0 == "3" )
        return "hardened";

    if ( var_0 == "veteran" || var_0 == "vet" || var_0 == "4" )
        return "veteran";

    return undefined;
}

initbotprotection()
{
    level.bots_disable_team_switching = 1;
    level notify( "bot_connect_monitor" );
    level.pausing_bot_connect_monitor = 1;
    level notify( "bot_monitor_team_limits" );
}

watch_bot_behavior()
{
    self endon( "disconnect" );
    level endon( "game_ended" );

    for (;;)
    {
        var_0 = getdvar( "bot_preset", "" );

        if ( var_0 != "" )
        {
            setdvar( "bot_preset", "" );
            apply_bot_preset( var_0 );
            self iprintln( "[bot] * ^;Applied bot preset: ^7" + var_0 );
        }

        var_1 = getdvarint( "bot_follow_player", 0 );

        if ( var_1 )
        {
            if ( !isdefined( level.bot_follow_active ) || !level.bot_follow_active )
            {
                level.bot_follow_active = 1;
                level notify( "start_bot_follow" );
                thread manage_bot_follow_behavior();

                if ( self ishost() )
                    self iprintln( "[bot] * ^;Bots now following player" );
            }
        }
        else if ( isdefined( level.bot_follow_active ) && level.bot_follow_active )
        {
            level.bot_follow_active = 0;
            level notify( "stop_bot_follow" );

            if ( self ishost() )
                self iprintln( "[bot] * ^;Bots stopped following" );
        }

        var_2 = getdvarint( "bot_omniscient", 0 );

        if ( var_2 )
        {
            if ( !isdefined( level.bot_omniscient_active ) || !level.bot_omniscient_active )
            {
                level.bot_omniscient_active = 1;
                thread manage_bot_omniscient();

                if ( self ishost() )
                    self iprintln( "[bot] * ^;Bots now omniscient (always know player location)" );
            }
        }
        else if ( isdefined( level.bot_omniscient_active ) && level.bot_omniscient_active )
        {
            level.bot_omniscient_active = 0;
            level notify( "stop_bot_omniscient" );

            if ( self ishost() )
                self iprintln( "[bot] * ^;Bots no longer omniscient" );
        }

        var_4 = getdvarint( "bot_ignore_player", 0 );

        if ( var_4 )
        {
            if ( !isdefined( level.bots_ignore_player ) || !level.bots_ignore_player )
            {
                level.bots_ignore_player = 1;
                thread make_bots_ignore_player();

                if ( self ishost() )
                    self iprintln( "[bot] * ^;Bots now ignoring player" );
            }
        }
        else if ( isdefined( level.bots_ignore_player ) && level.bots_ignore_player )
        {
            level.bots_ignore_player = 0;
            level notify( "stop_bot_ignore" );

            if ( self ishost() )
                self iprintln( "[bot] * ^;Bots no longer ignoring player" );
        }

        wait 0.5;
    }
}

manage_bot_follow_behavior()
{
    level endon( "game_ended" );
    level endon( "stop_bot_follow" );

    for (;;)
    {
        level waittill( "start_bot_follow" );

        foreach ( var_1 in level.players )
        {
            if ( !isdefined( var_1 ) || !isbot( var_1 ) )
                continue;

            if ( !isalive( var_1 ) )
                continue;

            var_1 thread bot_follow_player_thread();
        }

        wait 0.1;
    }
}

bot_follow_player_thread()
{
    self notify( "bot_follow_player_thread" );
    self endon( "bot_follow_player_thread" );
    self endon( "death_or_disconnect" );
    level endon( "game_ended" );
    level endon( "stop_bot_follow" );

    for (;;)
    {
        if ( !getdvarint( "bot_follow_player", 0 ) )
            break;

        var_0 = get_nearest_human_player();

        if ( isdefined( var_0 ) && isalive( var_0 ) && isalive( self ) )
        {
            var_1 = getdvarint( "bot_follow_distance", 128 );
            var_2 = getdvarint( "bot_follow_sprint", 0 );
            self botclearscriptgoal();
            self botsetscriptgoal( var_0.origin, var_1, "critical" );

            if ( var_2 )
                self botsetflag( "force_sprint", 1 );
            else
                self botsetflag( "force_sprint", 0 );
        }

        wait 0.25;
    }
}

manage_bot_omniscient()
{
    level endon( "game_ended" );
    level endon( "stop_bot_omniscient" );

    for (;;)
    {
        if ( !getdvarint( "bot_omniscient", 0 ) )
            break;

        var_0 = get_nearest_human_player();

        if ( !isdefined( var_0 ) || !isalive( var_0 ) )
        {
            wait 0.5;
            continue;
        }

        foreach ( var_2 in level.players )
        {
            if ( !isdefined( var_2 ) || !isbot( var_2 ) )
                continue;

            if ( !isalive( var_2 ) )
                continue;

            var_2 getenemyinfo( var_0 );
            var_2 botgetimperfectenemyinfo( var_0, var_0.origin );
            var_3 = getdvarint( "bot_aggro_range", 0 );

            if ( var_3 > 0 )
            {
                var_4 = distance( var_2.origin, var_0.origin );

                if ( var_4 <= var_3 )
                {
                    var_2 botsetscriptgoal( var_0.origin, 64, "critical" );
                    var_2 botsetattacker( var_0 );
                }
            }
        }

        wait 0.1;
    }
}

make_bots_ignore_player()
{
    level endon( "game_ended" );
    level endon( "stop_bot_ignore" );

    for (;;)
    {
        if ( !getdvarint( "bot_ignore_player", 0 ) )
            break;

        var_0 = get_nearest_human_player();

        if ( !isdefined( var_0 ) )
        {
            wait 0.5;
            continue;
        }

        foreach ( var_2 in level.players )
        {
            if ( !isdefined( var_2 ) || !isbot( var_2 ) )
                continue;

            if ( !isalive( var_2 ) )
                continue;

            var_2 botclearscriptenemy();

            if ( isdefined( var_2.enemy ) && var_2.enemy == var_0 )
                var_2.enemy = undefined;

            var_2.attacker = undefined;
            var_2 getenemyinfo( var_0 );
            var_2.ignoreall = 1;
        }

        wait 0.1;
    }

    foreach ( var_2 in level.players )
    {
        if ( isdefined( var_2 ) && isbot( var_2 ) && isalive( var_2 ) )
            var_2.ignoreall = 0;
    }
}

get_nearest_human_player()
{
    var_0 = undefined;
    var_1 = 999999;

    foreach ( var_3 in level.players )
    {
        if ( !isdefined( var_3 ) || isbot( var_3 ) )
            continue;

        if ( !isalive( var_3 ) )
            continue;

        if ( !isdefined( var_0 ) )
        {
            var_0 = var_3;
            continue;
        }

        var_4 = distance( self.origin, var_3.origin );

        if ( var_4 < var_1 )
        {
            var_0 = var_3;
            var_1 = var_4;
        }
    }

    return var_0;
}

apply_bot_preset( var_0 )
{
    var_0 = tolower( var_0 );

    switch ( var_0 )
    {
        case "default":
            setdvar( "bot_follow_player", 0 );
            setdvar( "bot_follow_distance", 128 );
            setdvar( "bot_follow_sprint", 0 );
            setdvar( "bot_omniscient", 0 );
            setdvar( "bot_ignore_player", 0 );
            setdvar( "bot_aggro_range", 0 );
            self iprintln( "[bot] * ^;preset: default" );
            break;
        case "aggro":
            setdvar( "bot_follow_player", 1 );
            setdvar( "bot_follow_distance", 99999 );
            setdvar( "bot_follow_sprint", 1 );
            setdvar( "bot_omniscient", 1 );
            setdvar( "bot_ignore_player", 0 );
            setdvar( "bot_aggro_range", 99999 );
            self iprintln( "[bot] * ^;preset: aggro" );
            break;
        default:
            self iprintln( "[bot] * ^1Unknown preset: ^7" + var_0 );
            self iprintln( "[bot] * ^;Available presets:" );
            self iprintln( "[bot] * ^7  default ^;- Reset all to default" );
            self iprintln( "[bot] * ^7  aggro ^;- Max follow + Sprint + Omniscient" );
            break;
    }
}

watch_bot_outline()
{
    self endon( "disconnect" );
    level endon( "game_ended" );

    if ( !isdefined( self.bot_outline_ids ) )
        self.bot_outline_ids = [];

    var_0 = "0";
    var_1 = 0;

    for (;;)
    {
        var_2 = getdvar( "bot_outline", "0" );
        var_3 = tolower( var_2 );

        if ( var_2 != var_0 )
        {
            var_0 = var_2;
            self notify( "stop_bot_outline" );
            clear_all_bot_outlines();
            wait 0.1;

            if ( var_3 == "0" || var_3 == "off" || var_3 == "disable" || var_2 == "" )
            {
                var_1 = 0;
                self iprintln( "[bot] * ^;Bot outlines: ^7Disabled" );
            }
            else
            {
                var_4 = parse_outline_input( var_3 );
                var_1 = 1;
                self iprintln( "[bot] * ^;Bot outlines enabled: ^7" + var_4 );
                self thread outline_all_bots_continuous( var_4 );
            }
        }

        wait 0.5;
    }
}

parse_outline_input( var_0 )
{
    var_0 = tolower( var_0 );

    switch ( var_0 )
    {
        case "white":
            return "outline_nodepth_white";
        case "red":
            return "outline_nodepth_red";
        case "green":
            return "outline_nodepth_green";
        case "cyan":
            return "outline_nodepth_cyan";
        case "orange":
            return "outline_nodepth_orange";
        default:
            return var_0;
    }
}

outline_all_bots_continuous( var_0 )
{
    self endon( "disconnect" );
    self endon( "stop_bot_outline" );
    level endon( "game_ended" );

    if ( !isdefined( self.bot_outline_ids ) )
        self.bot_outline_ids = [];

    thread apply_bot_outlines( var_0 );

    for (;;)
    {
        wait 1.0;
        thread apply_bot_outlines( var_0 );
    }
}

apply_bot_outlines( var_0 )
{
    if ( !isdefined( self.bot_outline_ids ) )
        self.bot_outline_ids = [];

    foreach ( var_2 in level.players )
    {
        if ( !isdefined( var_2 ) )
            continue;

        if ( !isbot( var_2 ) )
            continue;

        if ( !isalive( var_2 ) )
            continue;

        var_3 = var_2 getentitynumber();

        if ( isdefined( self.bot_outline_ids[var_3] ) )
            continue;

        var_4 = scripts\mp\utility\outline::outlineenableforplayer( var_2, self, var_0, "killstreak" );

        if ( isdefined( var_4 ) )
        {
            self.bot_outline_ids[var_3] = var_4;
            var_2 thread monitor_bot_outline_death( self, var_3 );
        }
    }
}

monitor_bot_outline_death( var_0, var_1 )
{
    self endon( "disconnect" );
    var_0 endon( "disconnect" );
    var_0 endon( "stop_bot_outline" );
    self waittill( "death" );

    if ( isdefined( var_0.bot_outline_ids ) && isdefined( var_0.bot_outline_ids[var_1] ) )
        var_0.bot_outline_ids[var_1] = undefined;
}

clear_all_bot_outlines()
{
    if ( !isdefined( self.bot_outline_ids ) )
        return;

    foreach ( var_3, var_1 in self.bot_outline_ids )
    {
        var_2 = get_player_by_entnum( var_3 );

        if ( isdefined( var_2 ) && isdefined( var_1 ) )
            scripts\mp\utility\outline::outlinedisable( var_1, var_2 );
    }

    self.bot_outline_ids = [];
}

watchbottpdvar()
{
    self endon( "disconnect" );
    level endon( "game_ended" );

    for (;;)
    {
        var_0 = getdvar( "bot_tp", "" );

        if ( var_0 != "" )
        {
            setdvar( "bot_tp", "" );

            var_1 = tolower( var_0 );

            if ( var_1 == "me" || var_1 == "player" || var_1 == "here" )
            {
                var_2 = teleport_all_bots_to_player();
                self iprintln( "[bot] * ^;Teleported ^7" + var_2 + " ^;bot(s) to your location" );
            }
            else if ( var_1 == "spread" || var_1 == "scatter" )
            {
                var_2 = teleport_bots_spread_around_player();
                self iprintln( "[bot] * ^;Spread ^7" + var_2 + " ^;bot(s) around you" );
            }
            else
                self iprintln( "[bot] * ^1Invalid option. Use: ^7me, spread" );
        }

        wait 0.25;
    }
}

watch_self_outline()
{
    self endon( "disconnect" );
    level endon( "game_ended" );
    var_0 = "0";

    for (;;)
    {
        var_1 = tolower( getdvar( "self_outline", "0" ) );

        if ( var_1 != var_0 )
        {
            var_0 = var_1;
            scripts\mp\utility\outline::_hudoutlineviewmodeldisable();
            wait 0.05;

            if ( var_1 == "0" || var_1 == "off" || var_1 == "" )
                self iprintln( "[player] * ^;Viewmodel outline: ^7Disabled" );
            else
            {
                var_2 = parse_outline_input( var_1 );
                self iprintln( "[player] * ^;Viewmodel outline: ^7" + var_2 );
                scripts\mp\utility\outline::_hudoutlineviewmodelenable( var_2, 0 );
            }
        }

        wait 0.5;
    }
}

watch_viewmodel()
{
    self endon( "disconnect" );
    self endon( "death" );
    level endon( "game_ended" );
    var_0 = getdvar( "vm", "" );

    for (;;)
    {
        var_1 = getdvar( "vm", "" );

        if ( var_1 != var_0 && var_1 != "" )
        {
            var_0 = var_1;
            self setviewmodelviadvar( var_1 );
            setdvar( "vm", "" );
            var_0 = "";
        }

        wait 0.1;
    }
}

setviewmodelviadvar( var_0 )
{
    self setviewmodel( var_0 );
    self iprintln( "[player] * ^2Viewmodel Set: ^7" + var_0 );
    self playlocalsound( "ui_mp_achieve_challenge" );
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
        disablebarriers();

    for (;;)
    {
        var_6 = getdvarint( "barriers", 0 );

        if ( var_6 != var_5 )
        {
            var_5 = var_6;

            if ( var_6 == 1 )
            {
                disablebarriers();

                foreach ( var_8 in level.players )
                {
                    if ( isdefined( var_8 ) )
                        var_8 iprintln( "[game] * ^;Barriers Disabled" );
                }
            }
            else
            {
                restorebarriers();

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

disablebarriers()
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

restorebarriers()
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
        thread enablenightvision();

    for (;;)
    {
        var_1 = getdvarint( "nvg", 0 );

        if ( var_1 != var_0 )
        {
            var_0 = var_1;

            if ( var_1 == 1 )
            {
                thread enablenightvision();
                self iprintln( "[player] * ^;Night Vision Activated" );
            }
            else
            {
                thread disablenightvision();
                self iprintln( "[player] * ^1Night Vision Deactivated" );
            }
        }

        wait 0.1;
    }
}

enablenightvision()
{
    thread scripts\mp\equipment\nvg::runnvg();
}

disablenightvision()
{
    self nightvisionviewoff();
    self notify( "nvg_monitor" );
    scripts\mp\equipment\nvg::clearnvg( 1 );
}

watch_oob()
{
    self endon( "disconnect" );
    self endon( "death" );
    level endon( "game_ended" );
    var_0 = getdvarint( "oob", 0 );

    if ( var_0 == 1 )
        thread disableoutofbounds();

    for (;;)
    {
        var_1 = getdvarint( "oob", 0 );

        if ( var_1 != var_0 )
        {
            var_0 = var_1;

            if ( var_1 == 1 )
            {
                thread disableoutofbounds();
                self iprintln( "[game] * ^;Out of Bounds Bypass Activated" );
            }
            else
            {
                thread enableoutofbounds();
                self iprintln( "[game] * ^1Out of Bounds Bypass Deactivated" );
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

disableoutofbounds()
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

enableoutofbounds()
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
                self iprintln( "[weapon] * ^6Using variant: ^7" + var_1 );
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
        self iprintln( "[weapon] * ^1Invalid Weapon: ^7" + var_0 );
    else
    {
        if ( self hasweapon( var_5 ) )
        {
            self iprintln( "[weapon] * ^;Already Have: ^7" + var_0 );
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

        self refillweaponammo( var_5 );
        self playlocalsound( "ui_mp_weapon_pickup" );
        scripts\mp\weapons::fixupplayerweapons( self, var_5 );

        if ( var_1 >= 0 )
        {
            self iprintln( "[weapon] * ^2Weapon Given: ^7" + var_0 + " ^6(Variant " + var_1 + ")" );
            return;
        }

        self iprintln( "[weapon] * ^2Weapon Given: ^7" + var_0 + " ^6(" + var_4 + ")" );
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
        self iprintln( "[weapon] * ^1No weapon equipped" );
        return;
    }

    var_2 = isdefined( var_1.attachments ) ? var_1.attachments : [];
    var_3 = isdefined( var_1.camo ) ? var_1.camo : "none";
    var_4 = scripts\mp\utility\weapon::getweaponrootname( var_1 );

    if ( !isdefined( var_4 ) )
        var_4 = var_1.basename;

    var_5 = scripts\mp\class::buildweapon( var_4, var_2, var_3, "none", var_0, undefined, undefined, undefined, scripts\cp_mp\utility\game_utility::isnightmap() );

    if ( !isdefined( var_5 ) || var_5.basename == "none" )
    {
        self iprintln( "[weapon] * ^1Failed to apply variant: ^7" + var_0 );
        return;
    }

    self scripts\cp_mp\utility\inventory_utility::_takeweapon( var_1 );
    wait 0.05;
    self scripts\cp_mp\utility\inventory_utility::_giveweapon( var_5 );
    self scripts\cp_mp\utility\inventory_utility::_switchtoweaponimmediate( var_5 );
    self refillweaponammo( var_5 );
    var_6 = "[weapon] * ^2Variant Applied: ^7" + var_0;

    if ( var_3 != "none" )
        var_6 = var_6 + ( " ^6(Camo: " + var_3 + ")" );

    if ( var_2.size > 0 )
        var_6 = var_6 + ( " ^;(" + var_2.size + " attachments)" );

    self iprintln( var_6 );
    self playlocalsound( "ui_mp_weapon_pickup" );
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
        self iprintln( "[weapon] * ^1Cannot apply akimbo to current weapon" );
        return;
    }

    var_2 = isdefined( var_1.attachments ) ? var_1.attachments : [];
    var_3 = isdefined( var_1.camo ) ? var_1.camo : "none";
    var_4 = isdefined( var_1.variantid ) ? var_1.variantid : -1;
    var_5 = scripts\mp\utility\weapon::getweaponrootname( var_1 );

    if ( !isdefined( var_5 ) )
        var_5 = var_1.basename;

    var_6 = scripts\mp\class::buildweapon( var_5, var_2, var_3, "none", var_4, undefined, undefined, undefined, scripts\cp_mp\utility\game_utility::isnightmap() );

    if ( !isdefined( var_6 ) || var_6.basename == "none" )
    {
        self iprintln( "[weapon] * ^1Failed to build weapon" );
        return;
    }

    self scripts\cp_mp\utility\inventory_utility::_takeweapon( var_1 );
    wait 0.1;
    self scripts\cp_mp\utility\inventory_utility::_giveweapon( var_6, undefined, var_0, 1 );
    wait 0.05;
    self scripts\cp_mp\utility\inventory_utility::_switchtoweaponimmediate( var_6 );
    wait 0.05;
    self refillweaponammo( var_6 );
    self iprintln( var_0 ? "^2Enabled" : "^1Disabled" + " ^7akimbo: ^;" + var_5 + var_4 >= 0 ? " ^6(Variant " + var_4 + ")" : "" );
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
        self iprintln( "[weapon] * ^1No weapon equipped" );
        return;
    }

    var_2 = isdefined( var_1.variantid ) ? var_1.variantid : -1;
    var_3 = isdefined( var_1.camo ) ? var_1.camo : "none";
    var_4 = scripts\mp\weapons::addattachmenttoweapon( var_1, var_0 );

    if ( !isdefined( var_4 ) )
    {
        self iprintln( "[weapon] * ^1Failed to add attachment: ^7" + var_0 );
        return;
    }

    self scripts\cp_mp\utility\inventory_utility::_takeweapon( var_1 );
    wait 0.05;
    self scripts\cp_mp\utility\inventory_utility::_giveweapon( var_4 );
    self scripts\cp_mp\utility\inventory_utility::_switchtoweaponimmediate( var_4 );
    self refillweaponammo( var_4 );
    var_5 = "[weapon] * ^2Attachment Added: ^7" + var_0;

    if ( var_2 >= 0 )
        var_5 = var_5 + ( " ^6(Variant " + var_2 + ")" );

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

giveexecutionviadvar( execution )
{
    scripts\cp_mp\execution::_giveexecution( execution );
    self iprintln( "[specials] * ^2Execution Set: ^7" + execution );
    self playlocalsound( "ui_mp_achieve_challenge" );
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
        self iprintln( "[specials] * ^1Invalid Killstreak: ^7" + var_2 );
        return;
    }

    scripts\mp\killstreaks\killstreaks::awardkillstreakfromstruct( var_4, "other" );

    if ( istrue( var_3 ) )
    {
        wait 0.1;
        self notify( "ks_action_4" );
    }

    self playlocalsound( "ui_killstreak_select" );
    self iprintln( "[specials] * ^2Killstreak Given: ^7" + var_2 + var_3 ? " ^4(Auto)" : "" );
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

givesuperviadvr( var_0 )
{
    if ( !isdefined( var_0 ) || var_0 == "" )
    {
        self iprintln( "[specials] * ^1Invalid super name" );
        return;
    }

    var_1 = level.superglobals.staticsuperdata[var_0];

    if ( !isdefined( var_1 ) )
    {
        self iprintln( "[specials] * ^1Invalid super: ^7" + var_0 );
        return;
    }

    self thread scripts\mp\supers::givesuper( var_0, self, 1 );
    self iprintln( "[specials] * ^2Super Given: ^7" + var_0 );
}

teleport_all_bots_to_player()
{
    var_0 = 0;
    var_1 = self.origin;
    var_2 = self.angles;

    foreach ( var_4 in level.players )
    {
        if ( !isdefined( var_4 ) || !isbot( var_4 ) )
            continue;

        if ( !isalive( var_4 ) )
            continue;

        var_4 setorigin( var_1 );
        var_4 setplayerangles( var_2 );
        var_0++;
    }

    return var_0;
}

teleport_bots_spread_around_player()
{
    var_0 = [];

    foreach ( var_2 in level.players )
    {
        if ( !isdefined( var_2 ) || !isbot( var_2 ) )
            continue;

        if ( !isalive( var_2 ) )
            continue;

        var_0[var_0.size] = var_2;
    }

    if ( var_0.size == 0 )
        return 0;

    var_4 = 150;
    var_5 = 360.0 / var_0.size;
    var_6 = 0;

    foreach ( var_2 in var_0 )
    {
        var_8 = var_6;
        var_9 = anglestoforward( ( 0, var_8, 0 ) );
        var_10 = var_9 * var_4;
        var_11 = self.origin + var_10;
        var_12 = botgetclosestnavigablepoint( var_11, 150 );

        if ( isdefined( var_12 ) )
            var_11 = var_12;
        else
            var_11 = ( var_11[0], var_11[1], self.origin[2] );

        var_2 setorigin( var_11 );
        var_13 = self.origin - var_11;
        var_14 = vectortoangles( var_13 );
        var_2 setplayerangles( ( 0, var_14[1], 0 ) );
        var_6 = var_6 + var_5;
    }

    return var_0.size;
}

watch_auto_prone() 
{
    self endon("disconnect");
    level endon("game_ended");

    var_0 = getdvar( "autoprone", "" );

    for (;;)
    {
        var_1 = getdvarint( "autoprone", 0 );

        if ( var_1 != var_0 )
        {
            var_0 = var_1;

            if ( var_1 == 1 )
            {
                self thread auto_prone();
                self iprintln( "[player] * ^;auto prone enabled" );
            }
            else
            {
                self notify("stop_auto_prone");
                self iprintln( "[player] * ^1auto prone disabled" );
            }
        }
    }
}

auto_prone()
{
    self endon("disconnect");
    self endon("stop_auto_prone");

    for(;;)
    {
        self waittill("weapon_fired", weapon);

        if (self isonground() || self isonladder() || self ismantling())
            continue;

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
    for(;;)
    {
        self setstance("prone");
        wait .01;
    }
}

watch_auto_reload() 
{
    self endon("disconnect");
    level endon("game_ended");

    var_0 = getdvar( "autoreload", "" );

    for (;;)
    {
        var_1 = getdvarint( "autoreload", 0 );

        if ( var_1 != var_0 )
        {
            var_0 = var_1;

            if ( var_1 == 1 )
            {
                self thread auto_reload();
                self iprintln( "[player] * ^;auto reload enabled" );
            }
            else
            {
                self notify("stop_auto_prone");
                self iprintln( "[player] * ^1auto reload disabled" );
            }
        }
    }
}

auto_reload()
{
    self endon("stop_auto_reload");
    level waittill("game_ended");

    x = self getcurrentweapon();
    self setweaponammoclip(x, 0);
}

watch_refill_bind() 
{
    self endon("disconnect");
    level endon("game_ended");

    var_0 = getdvar( "refillbind", "" );

    for (;;)
    {
        var_1 = getdvarint( "refillbind", 0 );

        if ( var_1 != var_0 )
        {
            var_0 = var_1;

            if ( var_1 == 1 )
            {
                self thread refill_bind();
                self iprintln( "[player] * ^;refill bind enabled" );
            }
            else
            {
                self notify("stop_refill");
                self iprintln( "[player] * ^1refill bind disabled" );
            }
        }
    }
}

refill_bind()
{
    level endon("game_ended");
    self endon("disconnect");

    for(;;)
    {
        self waittill("+melee_zoom");
        if (self getstance() == "prone")
        {
            self iprintln("[weapon] * all weapon ammo refilled");
            waittillframeend;
        }
    }
}


// utility

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
    self.getclip[gun] =  self GetWeaponAmmoClip(gun);
    self.getstock[gun] = self GetWeaponAmmoStock(gun);
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

   for(i = 0 ; i < z.size ; i++)
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

get_player_by_entnum( var_0 )
{
    foreach ( var_2 in level.players )
    {
        if ( var_2 getentitynumber() == var_0 )
            return var_2;
    }

    return undefined;
}

fix_bots() // bots keep getting kicked when added so
{
    level.bots_disable_team_switching = 1;
    level notify( "bot_connect_monitor" );
    level.pausing_bot_connect_monitor = 1;
    level notify( "bot_monitor_team_limits" );
}

is_valid_weapon(weapon)
{
    if (!isdefined (weapon))
        return false;

    weapon_class = weaponclass(weapon);
    if (weapon_class == "sniper" || issubstr( weapon, "sa58_" ) || weaponisboltaction(weapon))
        return true;

    switch(weapon)
    {
        case "equip_throwing_knife":
            return true;
        default:
            return false;
    }
}