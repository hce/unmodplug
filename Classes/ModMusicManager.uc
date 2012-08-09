//=============================================================================
// ModMusicManager.
// Dynamic Music Manager for Deus Ex
// (C) 2011-2012, Hans-Christian Esperer <hc-dx@hcesperer.org>
// Beerware.
//=============================================================================
class ModMusicManager expands ModPlug;

/*
 * Target attack type
 */
enum TargetAttackType
{
	AT_Confront,                        // Target was attacked from the front
	AT_Sneak                            // Target was attacked from a sneak-up
};

var(Tracks) String AmbientTrack;        // Ambient Music File
var(Tracks) String DyingTrack;          // Dying Music File
var(Tracks) String BattleTrack;         // Battle Music File
var(Tracks) String ConversationTrack;   // Conversation Music File
var(Tracks) String OutroTrack;          // Outro Music File

// Distance at which to start fading in the sneak approach channels
var(DynamicMusic) int    sneakBeginDistance;

// Distance at which to start fading in the confrontation
// approach channels
var(DynamicMusic) int    confrontationBeginDistance;

var(DynamicMusic) int lowRangeDistance; // At which distance to unmute the attack music channels
// If set to true, attackTimeoutTime will have no effect.
var(DynamicMusic) bool bAttackMusicOnlyStopsOnLostSight;
var(DynamicMusic) float attackTimeout;  // Seconds to wait after an attack to switch back to ambient music
var transient bool bFirstTick;          // Is this our first tick?
var TrackType currentTrack;             // (Main) Track currently playing
var TrackType nextTrack;                // Track to be played when currentTrack got faded to 0
var float checkdiff;                    // Time since we last did more cpu-intensive checks
var ScriptedPawn targettedPawn;         // The last npc the Player was targetting
var float firstTargetingDistance;       // The distance the player first targetted his latest target at
var TargetAttackType attackType;        // The way we first approached our last target (sneaky, frontattack)
var int targetInitialHealth;            // Health of attackee when first in sight
var float lastTargetted;                // Time since an enemy was last targetted
var float lastTargetingDistance;        // Last known targetting distance
var Inventory lastWieldedWeapon;        // Last weapon player was wielding
var Name lastItemState;                 // Last state of music causing inventory item

/*
 * Keep attack channel volumes
 * do not get quieter, only louder
 * until themes are stopped entirely, only then
 * can they again start quietly for the next opportunity
 */
var float volcache1;
var float volcache2;

var(DynamicMusic) float combatTimeout;  // Stay in combat for combatTimeout seconds
var float lastCombatUpdate;             // Last time we checked for combat in Tick()
var int combatStartHealth;              // The player's health at the beginning of a battle
var bool bCombat;                       // Are we currently in combat?
var String newAmbientTrack;             // Ambient music track to load once the current one has been paused.
var EMusicTransition naTransitionType;  // Transition to use for fading new ambient music in


// Various ambient music related stuff
var bool bReading;
var bool bThirdPersonConvo;
var bool bSneaking;
var float sneakTargetLost;
var int lastTargettingVolume;
var bool bCompletelyTargetted;
var bool bEnemyOnAlert;
var String LastReadingMood;

//native(127) static final function string Mid    ( coerce string S, int i, optional int j );
//native(126) static final function int    InStr  ( coerce string S, coerce string t );

var(Choreography) Name ambientEvents[256]; // Events to trigger for choreographyevents in the ambient music
var(Choreography) Name specialEvents[256]; // Events to trigger for choreographyevents in the special music

var EventCatcher eventCatcher;             // Proxy to channel AI Events to us
var float LastAlarmTriggering;             // Last time we caught an Alarm event
var bool bAlarming;                        // Are we currently playing the Alarm channels?

var MusicZone currentMusicZone;            // Used to restore state after loading a savegame

var bool bAmbientConvo;                    // Ambient Convo Channels faded in?
var Name SavedAmbientConvoChannel;              // Last ambient convo channel

var bool bOnMover;
var bool bInterpolating;

var bool bApproachChannelsPlaying;

var (DynamicMusic) float skilledToolFadeInTime;

var bool bHadAChoice; // convo music stuff

var (SneakingDetectionParameters) bool bInterior;

var Name newAmbientEvents[256]; // Ambient events to set after ambient music change (Used by AmbientMusicTrigger)

// ----------------------------------------------------------------------
// CheckMover()
// ----------------------------------------------------------------------
function CheckMover(DeusExPlayer dxp)
{
	local Mover M;
	local int ratio;
	local byte foo[256];
	local int i;
	
	M = Mover(dxp.Base);
	if (M == None)
	{
		if (bOnMover)
		{
			bOnMover = False;
			DisableChannelsEffect(TRACKTYPE_Ambient, 'Ambient', EFFECTTYPE_Vibrato);
			SetChannelsTranspose(TRACKTYPE_Ambient, 'Ambient', 0);
			ClearInstrumentOverride(TRACKTYPE_Ambient, 'Ambient');
		}
		if (bInterpolating)
		{
			SetChannelsTranspose(TRACKTYPE_Ambient, 'Ambient', 0);
			bInterpolating = False;
			DisableChannelsEffect(TRACKTYPE_Ambient, 'Ambient', EFFECTTYPE_PortamentoUp);
			DisableChannelsEffect(TRACKTYPE_Ambient, 'Ambient', EFFECTTYPE_PortamentoDown);
			ClearInstrumentOverride(TRACKTYPE_Ambient, 'Ambient');

			/* Hack so we don't change the music after the mover has reached its destination */
			bOnMover = True;
		}
		return;
	}
	
	if (M.bInterpolating)
	{
		bInterpolating = True;
		if (bOnMover)
			DisableChannelsEffect(TRACKTYPE_Ambient, 'Ambient', EFFECTTYPE_Vibrato);
		bOnMover = False;
		if (M.OldPos.Z > M.Location.Z)
		{
			//SetChannelsTranspose(TRACKTYPE_Ambient, 'Ambient', 2);
			EnableChannelsEffect(TRACKTYPE_Ambient, 'Ambient', EFFECTTYPE_PortamentoDown, 255);
		}
		else
		{
			//SetChannelsTranspose(TRACKTYPE_Ambient, 'Ambient', -2);
			EnableChannelsEffect(TRACKTYPE_Ambient, 'Ambient', EFFECTTYPE_PortamentoUp, 255);
		}
		for (i = 0; i < 256; i++) foo[i] = i;
		foo[3] = 4; /* Turn synth into organ - HACK */
		EnableInstrumentOverride(TRACKTYPE_Ambient, 'Ambient', foo);
	}
	else if (!bOnMover)
	{
		bOnMover = True;
		if (bInterpolating)
		{
			DisableChannelsEffect(TRACKTYPE_Ambient, 'Ambient', EFFECTTYPE_PortamentoUp);
			DisableChannelsEffect(TRACKTYPE_Ambient, 'Ambient', EFFECTTYPE_PortamentoDown);
			bInterpolating = False;
		}
		for (i = 0; i < 256; i++) foo[i] = i;
		foo[3] = 4; /* Turn synth into organ - HACK */
		EnableInstrumentOverride(TRACKTYPE_Ambient, 'Ambient', foo);
		EnableChannelsEffect(TRACKTYPE_Ambient, 'Ambient', EFFECTTYPE_Vibrato, 32);
	}	
}

// ----------------------------------------------------------------------
// PreBeginPlay()
// ----------------------------------------------------------------------

function PreBeginPlay()
{
	Super.PreBeginPlay();
	
	eventCatcher = Spawn(class'eventCatcher');
	eventCatcher.BeginAction(Self);
	
	lastCombatUpdate = combatTimeout;
}

// ----------------------------------------------------------------------
// PostPostBeginPlay()
// ----------------------------------------------------------------------

function PostPostBeginPlay()
{
	Super.PostPostBeginPlay();

	lastTargetted = attackTimeout;
	bFirstTick = True;
}

// ----------------------------------------------------------------------
// PrepareAmbientTrack()
// 
// Mute all channels in the ambient track but the ones of type 'Ambient'
// ----------------------------------------------------------------------

function PrepareAmbientTrack()
{
	local int i;
		
	// Initially silence all channels in the ambient track
	// Then, unsilence all channels with the name 'Ambient'
	for (i = 0; i < 64; ++i)
		SetChannelVolume(TRACKTYPE_Ambient, i, 0);
	FadeChannelsTo(TRACKTYPE_Ambient, 'Ambient', 128, 0.0);
	
	// Sort of a hack to restore channel state
	// after loading a savegame
	if (currentMusicZone != None)
		currentMusicZone.ActorEntered(GetPlayerPawn());
}

// ----------------------------------------------------------------------
// InitSystem()
// 
// Open all tracks and begin playing the ambient track
// ----------------------------------------------------------------------

function InitSystem()
{
	log(SPrintf("Opening ambient: %d", Open(TRACKTYPE_Ambient, AmbientTrack)));
	PrepareAmbientTrack();
	
	Open(TRACKTYPE_Dying, DyingTrack);
	Open(TRACKTYPE_Battle, BattleTrack);
	Open(TRACKTYPE_Conversation, ConversationTrack);
	Open(TRACKTYPE_Outro, OutroTrack);
	
	//Open(TRACKTYPE_Motives, "Motives.it");
	Open(TRACKTYPE_GreaselCombat, "GreaselCombat.salsa");
		
	
	currentTrack = TRACKTYPE_Ambient;
	nextTrack = TRACKTYPE_Undefined;
	Play(TRACKTYPE_Ambient);
}

// ----------------------------------------------------------------------
// Tick()
// 
// Check the game state and modify the music accordingly
// ----------------------------------------------------------------------

event Tick(float deltaTime)
{
	local DeusExPlayer dxp;
	local int dist;
	local Pawn curPawn;
	local ScriptedPawn npc;
	local DeusExLevelInfo info;
	local Actor ConvoPawn;
	local String customConvoTrack;
	local float combatIntensityFactor;
	local InformationDevices idev;
	local DeusExWeapon dxw;
	local int CurTargettingVolume;
	local Actor acquiredTarget;
	local String CurReadingMood;
	local Name AmbientConvoChannel;
	local int vibratoFactor;
	local bool bHasAChoice; /* convo music stuff */
	
	Super.Tick(deltaTime);
	
	/*
	 * If it's the first tick after a game/map load,
	 * we need to call InitSystem() to get the music loaded
	 */
	if (bFirstTick)
	{
		InitSystem();
		bFirstTick = False;
	}
	
	checkdiff += deltaTime;
	
	dxp = DeusExPlayer(GetPlayerPawn());
	if (dxp == None)
		return;
		
	ConvoPawn = dxp.ConversationActor;
	
	// not right now.
	//CheckMover(dxp);
	
	/*
	 * Check for 'UsingSkilledTool' and various easter eggs
	 * such as the Nothung motive.
	 */
	if (dxp.inHand != lastWieldedWeapon)
	{
		if ((dxp.inHand != None) && dxp.inHand.IsA('WeaponNothung'))
		{
			lastWieldedWeapon = dxp.inHand;
			SetPosition(TRACKTYPE_Motives, 0);
			Play(TRACKTYPE_Motives);
			log("Playing Nothung motive.");
			/** 
			 * DO NOT set currentTrack to TRACKTYPE_Motives, as it
			 * plays _along_ the ambient sound
			 */
		}
		else if ((dxp.inHand != None) && dxp.inHand.IsA('SkilledTool')
				 && !dxp.inHand.IsA('NanoKeyRing'))
		{
			if (SkilledTool(dxp.inHand).IsInState('UseIt')) {
				lastWieldedWeapon = dxp.inHand;
				FadeChannelsTo(TRACKTYPE_Ambient, 'UsingSkilledTool', 128, skilledToolFadeInTime);
			}
		}
		else if ((dxp.inHand != None) && dxp.inHand.IsA('DeusExWeapon'))
		{
			lastItemState = '';
			lastWieldedWeapon = dxp.inHand;
		}
		else
		{
			lastWieldedWeapon = dxp.inHand;
			FadeChannelsTo(TRACKTYPE_Ambient, 'UsingSkilledTool', 0, 10.0);
			FadeChannelsTo(TRACKTYPE_Ambient, 'ReloadingWeapon', 0, 4.0);
		}
	}

	if ((dxp.inHand != None) && dxp.inHand.IsA('DeusExWeapon'))	
	{
		if (dxp.inHand.IsInState('Reload') &&
			lastItemState != 'Reload')
		{
			FadeChannelsTo(TRACKTYPE_Ambient, 'ReloadingWeapon', 128, 1.0);
			FadeChannelsTo(TRACKTYPE_Battle, 'ReloadingWeapon', 128, 1.0);
			lastItemState = 'Reload';
		}
		else if (!dxp.inHand.IsInState('Reload') &&
			(lastItemState == 'Reload'))
		{
			FadeChannelsTo(TRACKTYPE_Ambient, 'ReloadingWeapon', 0, 2.5);
			FadeChannelsTo(TRACKTYPE_Battle, 'ReloadingWeapon', 0, 2.5);
			lastItemState = '';
		}
	}
	
	/*
	 * Check for 'Reading'
	 */
	if ((dxp.FrobTarget != None) &&
		dxp.FrobTarget.IsA('InformationDevices'))
	{
		idev = InformationDevices(dxp.FrobTarget);
		if (bReading && idev.aReader != dxp)
		{
			FadeChannelsTo(TRACKTYPE_Ambient, 'Reading', 0, 2.3);
			bReading = False;
		}
		else if (!bReading && idev.aReader == dxp)
		{
			FadeChannelsTo(TRACKTYPE_Ambient, 'Reading', 128, 2.3);
			vibratoFactor = int(idev.GetPropertyText("vibratoFactor"));
			if (vibratoFactor != 0)
				EnableChannelsEffect(TRACKTYPE_Ambient, 'Reading', EFFECTTYPE_Vibrato, vibratoFactor);
			else
				DisableChannelsEffect(TRACKTYPE_Ambient, 'Reading', EFFECTTYPE_Vibrato);
			bReading = True;
		}
	}
	else if (bReading)
	{
		FadeChannelsTo(TRACKTYPE_Ambient, 'Reading', 0, 2.3);
		bReading = False;
	}
	
	
	/*
	 * ReadingMood is for reading E-Mails and bulletins only,
	 * not for InformationDevices like DataLinks!
	 */
	CurReadingMood = dxp.GetPropertyText("CurrentReadingMood"); // avoid errors
	if (CurReadingMood != LastReadingMood)
	{
		if (CurReadingMood == "")
			FadeChannelsTo(TRACKTYPE_Ambient, dxp.rootWindow.StringToName(LastReadingMood), 0, 4.2);
		else
		{
			if (LastReadingMood != "")
				FadeChannelsTo(TRACKTYPE_Ambient, dxp.rootWindow.StringToName(LastReadingMood), 0, 0.42);
			FadeChannelsTo(TRACKTYPE_Ambient, dxp.rootWindow.StringToName(CurReadingMood), 128, 2.3);
		}
		LastReadingMood = CurReadingMood;
	}
	
	/*
	 * Check for 'AmbientConvo'
	 */
	if (!bThirdPersonConvo && IsOverheardConvo(dxp))
	{
		FadeChannelsTo(TRACKTYPE_Ambient, 'AmbientConvo', 128, 2.3);
		bThirdPersonConvo = True;
	}
	else if (bThirdPersonConvo &&
			 ((dxp.conPlay == None) || !dxp.conPlay.con.bNonInteractive))
	{
		FadeChannelsTo(TRACKTYPE_Ambient, 'AmbientConvo', 0, 2.3);
		bThirdPersonConvo = False;
	}
	
	/*
	 * Check for 'Alerted'
	 */
	if (!bEnemyOnAlert && CheckSeeking(dxp))
	{
		FadeChannelsTo(TRACKTYPE_Ambient, 'Alerted', 128, 0.5);
		bEnemyOnAlert = True;
	}
	else if (bEnemyOnAlert && !CheckSeeking(dxp))
	{
		FadeChannelsTo(TRACKTYPE_Ambient, 'Alerted', 0, 4.2);
		bEnemyOnAlert = False;
	}
	
	/*
	 * Check for 'Targetting' and 'Targetted'
	 */
	dxw = DeusExWeapon(dxp.inHand);
	if (dxw != None) acquiredTarget = dxw.AcquireTarget();
	if ((dxw != None) && IsProjectileWeapon(dxw) &&
		(ScriptedPawn(acquiredTarget) != None) &&
		(ScriptedPawn(acquiredTarget).GetPawnAllianceType(dxp) == ALLIANCE_Hostile))
	{
		if (dxw.currentAccuracy <= 0.1)
		{
			if (!bCompletelyTargetted)
			{
				FadeChannelsTo(TRACKTYPE_Ambient, 'Targetted', 128, 0.2);
				bCompletelyTargetted = True;
			}
			CurTargettingVolume = 0;
		}
		else
			CurTargettingVolume = Min(128 * (1.1 - dxw.currentAccuracy), 128);
	}
	else
	{
		CurTargettingVolume = 0;
		if (bCompletelyTargetted)
		{
			FadeChannelsTo(TRACKTYPE_Ambient, 'Targetted', 0, 2.3);
			bCompletelyTargetted = False;
		}
	}
	
	if (lastTargettingVolume != CurTargettingVolume)
	{
		if (Abs(lastTargettingVolume - CurTargettingVolume) > 5)
			FadeChannelsTo(TRACKTYPE_Ambient, 'Targetting', CurTargettingVolume, 1.0);
		else
			SetChannelsVolume(TRACKTYPE_Ambient, 'Targetting', CurTargettingVolume);
		lastTargettingVolume = CurTargettingVolume;
	}
		
	if (bAlarming)
	{
		LastAlarmTriggering += deltaTime;
		if (LastAlarmTriggering > 30)
		{
			FadeChannelsTo(TRACKTYPE_Ambient, 'Alarm', 0.0, 4.2);
			FadeChannelsTo(TRACKTYPE_Battle, 'Alarm', 0.0, 4.2);
			bAlarming = False;
		}
	}
	
	/*
	 * Check for various transition events that justify transitioning
	 * away from/to the Ambient soundtrack 
	 */
	if (dxp.IsInState('Dying'))
    {
        if (currentTrack != TRACKTYPE_Dying)
        {
        	log("Dying!");
        	SetPosition(TRACKTYPE_Dying, 0);
        	nextTrack = TRACKTYPE_Dying;
        	FadeTo(currentTrack, 0, MTRAN_Fade);
        	currentTrack = TRACKTYPE_Dying;
        }
       	return;
    }
	else if (dxp.IsInState('Interpolating'))
    {
        // don't mess with the music on any of the intro maps
        info = dxp.GetLevelInfo();
        if ((info != None) && (info.MissionNumber < 0))
            return;

        if (currentTrack != TRACKTYPE_Outro)
        {
        	SetPosition(TRACKTYPE_Outro, 0);
        	nextTrack = TRACKTYPE_Outro;
        	FadeTo(currentTrack, 0, MTRAN_Fade);
        	currentTrack = TRACKTYPE_Outro;
        }
      	return;
    }
    else if (dxp.IsInState('Conversation'))
    {
        if ((currentTrack != TRACKTYPE_Conversation) &&
            (currentTrack != TRACKTYPE_ConversationExtra) &&
            (!bAmbientConvo) &&
            (ConvoPawn != None))
        {
        	// Rid us of sneaking channels
       		FadeChannelsTo(TRACKTYPE_Ambient, 'Sneaking', 0, 4.2);

        	bHasAChoice = False;
        	// Read these properties via the GetPropertyText method so as to also
        	// work with the unmodified ScriptedPawn class.
        	// In case of an unmodified ScriptedPawn class this method
        	// silently fails and returns an empty string.
        	customConvoTrack    = ConvoPawn.GetPropertyText("customConvoTrack");
        	log(SPrintf("Convopawn %s %s", ConvoPawn, ConvoPawn.GetPropertyText("bStayInAmbient")));
        	if (ConvoPawn.GetPropertyText("bStayInAmbient") == "True")
	        	AmbientConvoChannel = dxp.rootWindow.StringToName(ConvoPawn.GetPropertyText("AmbientChannelToFadeIn"));
	        else
	        	AmbientConvoChannel = '';
	        if ((ConvoPawn != None) && (AmbientConvoChannel != ''))
	        {
	        	FadeChannelsTo(TRACKTYPE_Ambient, AmbientConvoChannel, 128, 2.5);
	        	SavedAmbientConvoChannel = AmbientConvoChannel;
	        	bAmbientConvo = True;
	        }
        	else if ((ConvoPawn != None) && (customConvoTrack != ""))
        	{
        		Open(TRACKTYPE_ConversationExtra, customConvoTrack);
        		SetTrackVolume(TRACKTYPE_ConversationExtra, 0);
        		Play(TRACKTYPE_ConversationExtra);
        		FadeTo(TRACKTYPE_ConversationExtra, 128, MTRAN_Fade);
        		nextTrack = TRACKTYPE_Undefined;
        		FadeTo(currentTrack, 0, MTRAN_Fade);
                currentTrack = TRACKTYPE_ConversationExtra;
        	}
        	else
            {
            	SetPosition(TRACKTYPE_Conversation, 0);
            	nextTrack = TRACKTYPE_Conversation;
	        	FadeTo(currentTrack, 0, MTRAN_Fade);
             	currentTrack = TRACKTYPE_Conversation;
           }
        }

       	bHasAChoice = (ConEventChoice(dxp.conPlay.currentEvent) != None);
       	if (bHasAChoice && !bHadAChoice)
       	{
       		FadeChannelsTo(TRACKTYPE_Ambient, 'Thinking', 128, 2.0);
       		FadeChannelsTo(TRACKTYPE_Conversation, 'Thinking', 128, 2.0);
       		bHadAChoice = True;
       	}
       	else if (!bHasAChoice && bHadAChoice)
       	{
       		FadeChannelsTo(TRACKTYPE_Ambient, 'Thinking', 0, 2.0);
       		FadeChannelsTo(TRACKTYPE_Conversation, 'Thinking', 0, 2.0);
       		bHadAChoice = False;
       	}

        return;
    }
    
    if (bAmbientConvo)
    {
    	FadeChannelsTo(TRACKTYPE_Ambient, SavedAmbientConvoChannel, 0, 2.5);
    	bAmbientConvo = False;
    }
    
    	
	/*
	 * Check for 'Sneaking' only if we are not in an (ambient) convo
	 */
	if (!bSneaking && CheckSneakingStart(dxp))
	{
		FadeChannelsTo(TRACKTYPE_Ambient, 'Sneaking', 128, 4.2);
		bSneaking = True;
	}
	else if (bSneaking && CheckSneakingStop(dxp, deltaTime))
	{
		FadeChannelsTo(TRACKTYPE_Ambient, 'Sneaking', 0, 4.2);
		bSneaking = False;
	}
    
   	/*
	 * Do the combat checks
	 */
    if (bCombat)
    {
    	// 128 is the loudest volume.
    	// 100 is the maximum health difference
     	combatIntensityFactor = Min((combatStartHealth - dxp.HealthTorso - dxp.HealthHead) * 128 / 100, 128);
       	// log(SPrintf("combatIntensityFactor: %d CSH %d CT %d CH %d", combatIntensityFactor, combatStartHealth, dxp.HealthTorso, dxp.HealthHead));
       	// SetMassVolume(TRACKTYPE_Battle, cache_combat1, combatIntensityFactor);
       	FadeChannelsTo(TRACKTYPE_Battle, 'IntenseCombat', combatIntensityFactor, 0.5);
       	FadeChannelsTo(TRACKTYPE_GreaselCombat, 'IntenseCombat', combatIntensityFactor, 0.5);
    }

	if (checkdiff >= 0.25)
	{
		lastCombatUpdate += checkdiff;
		bCombat = False; // reset here because we made bCombat an instance global
		for (CurPawn = Level.PawnList; CurPawn != None; CurPawn = CurPawn.NextPawn)
		{
			npc = ScriptedPawn(CurPawn);
			if ((npc != None) && (VSize(npc.Location - dxp.Location) < (1600 + npc.CollisionRadius)))
			{
				if (((npc.GetStateName() == 'Attacking') && (npc.Enemy == dxp)) ||
					(npc.Alliance == 'SelfMurderAssassin'))
				{
					bCombat = True;
					lastCombatUpdate = 0.0;
					break;
				}
            }
        }
        
        /*
         * If we are not currently in combat but have not yet
         * reached the combat timeout, act exactly as though
         * we were engaged in a combat situation
         */
        if (!bCombat && (lastCombatUpdate < combatTimeout))
        	bCombat = True;
        
        if (bCombat && (currentTrack != TRACKTYPE_Battle) &&
        		(currentTrack != TRACKTYPE_GreaselCombat))
        {
        	log(SPrintf("Combat: %s", npc));
        	if (npc.IsA('Greasel'))
        	{
	        	SetPosition(TRACKTYPE_GreaselCombat, 0);
		       	FadeChannelsTo(TRACKTYPE_GreaselCombat, 'IntenseCombat', 0, 0.0);
		        combatStartHealth = dxp.HealthTorso + dxp.HealthHead;
	        	nextTrack = TRACKTYPE_GreaselCombat;
	        	FadeTo(currentTrack, 0, MTRAN_Fade);
	        	currentTrack = TRACKTYPE_GreaselCombat;
        	}
        	else
        	{
	        	SetPosition(TRACKTYPE_Battle, 0);
		       	FadeChannelsTo(TRACKTYPE_Battle, 'IntenseCombat', 0, 0.0);
		        combatStartHealth = dxp.HealthTorso + dxp.HealthHead;
	        	nextTrack = TRACKTYPE_Battle;
	        	FadeTo(currentTrack, 0, MTRAN_Fade);
	        	currentTrack = TRACKTYPE_Battle;
	        }
        }
        
        if (!bCombat && (currentTrack != TRACKTYPE_Ambient))
        {
        	nextTrack = TRACKTYPE_Ambient;
        	switch(currentTrack) {
        	case TRACKTYPE_Conversation:
        	case TRACKTYPE_ConversationExtra:
	        	FadeToTime(currentTrack, 0, 3);
	        	break;
	        default:
	        	FadeToTime(currentTrack, 0, 12);
	        }
	    	currentTrack = TRACKTYPE_Ambient;
        }
        
        // Depending on the distance to a target, set the volume
        // of the ambient music channels designated as sneak
        // approach channels
        checkApproachVol(checkdiff);
        
		checkdiff = 0;
	}
}

// ----------------------------------------------------------------------
// checkApproachVol()
// 
// Calculate the volume of an approach track depending on the distance
// of the player from their enemy
// ----------------------------------------------------------------------

function checkApproachVol(float deltaTime)
{
	local Actor target;
	local ScriptedPawn sp;
	local DeusExPlayer dxp;
	local float distance;
	local bool bConfrontation;
	local bool bValidTarget;
	local bool bValidDistance;
	local float approachVolFactor;
	local float attackVolFactor;
	
	dxp = DeusExPlayer(GetPlayerPawn());
	if (dxp == None)
		return;
	
	bValidTarget = True;
	
	// Ignore approach if we're not currently holding a weapon.
	if ((dxp.inHand == None) || (DeusExWeapon(dxp.inHand) == None))
		bValidTarget = False;
	
	// We care only about close combat weapons
	if (bValidTarget &&
		!dxp.inHand.IsA('WeaponCombatKnife') &&
		!dxp.inHand.IsA('WeaponCrowbar') && 
		!dxp.inHand.IsA('WeaponProd') && 
		!dxp.inHand.IsA('WeaponBaton'))
		bValidTarget = False;

	target = GetTargettedActor(dxp, Max(sneakBeginDistance, confrontationBeginDistance));
	if (target != None)
		sp = ScriptedPawn(target);
	
	if (bValidTarget && (sp != None) &&
		(sp.GetPawnAllianceType(dxp) == ALLIANCE_Hostile) &&
		(sp.Health > 0))
	{
		distance = VSize(sp.Location - dxp.Location) - sp.CollisionRadius;
		bConfrontation = sp.AICanSee(dxp, dxp.CalculatePlayerVisibility(sp), true, true, true, true) > 0;
		bValidDistance = False;
		if (bConfrontation && (distance <= confrontationBeginDistance))
			bValidDistance = True;
		else if (!bConfrontation && (distance <= sneakBeginDistance))
			bValidDistance = True;
			
		if (bValidDistance)
		{
			if (targettedPawn != sp)
			{
				targetInitialHealth = sp.Health;
				if (bConfrontation)
					attackType = AT_Confront;
				else
					attackType = AT_Sneak;
				firstTargetingDistance = distance + sp.CollisionRadius / 2;
				targettedPawn = sp;
			}
			lastTargetted = 0.0;
			lastTargetingDistance = distance;
		}
	}

	// If player is not currently targetting a hostile actor,
	// but if he had done so just a few moments ago,
	// and if the player can still see that hostile actor,
	// and if the hostile actor is still in range,
	// then act as though the player is still approaching
	// the target.
	if (bAttackMusicOnlyStopsOnLostSight)
	{
		if ((lastTargetted > 0.0) && (targettedPawn != None) &&
			targettedPawn.PlayerCanSeeMe())
		{
			distance = VSize(targettedPawn.Location - dxp.Location) - targettedPawn.CollisionRadius;
			if (((attackType == AT_Confront) && (distance <= confrontationBeginDistance)) ||
				((attackType == AT_Sneak)    && (distance <= sneakBeginDistance)))
			{
				lastTargetted = 0.0;
			}
		}
	}	
	
	lastTargetted += deltaTime;
	if (lastTargetted < attackTimeout)
	{
		// log(SPrintf("%s %s %s %s", targettedPawn, targettedPawn.unfamiliarname, targettedpawn.familiarname, targettedpawn.health));
		if ((targettedPawn == None) || (targettedPawn.Health <= 0))
		{
			// Target is dead/unconscious, presumably killed by the player
			//log("Playing death motive");
			//SetCurrentOrder(TRACKTYPE_Motives, 3);
			//Play(TRACKTYPE_Motives);
			lastTargetted = attackTimeout;
			targettedPawn = None;
		}
		else
		{
			approachVolFactor = FMax(FMin((firstTargetingDistance - lastTargetingDistance) / firstTargetingDistance, 1.0), 0.0);
			// Player drew blood
			if (targetInitialHealth > targettedPawn.Health)
				attackVolFactor = FMax(FMin((targettedPawn.default.Health - targettedPawn.MinHealth) / targettedPawn.Health, 1.0), 0.0);
			else
			{
				if (lastTargetingDistance < lowRangeDistance)
					attackVolFactor = 0.5;
			}
			
			approachVolFactor = FMax(approachVolFactor, volcache1);
			volcache1 = approachVolFactor;
			attackVolFactor = FMax(attackVolFactor, volcache2);
			volcache2 = attackVolFactor;
			switch(attackType)
			{
			case AT_Confront:
				//SetMassVolume(TRACKTYPE_Ambient, cache_confr1, approachVolFactor * 128);
				//SetMassVolume(TRACKTYPE_Ambient, cache_confr2, attackVolFactor * 128);
				FadeChannelsTo(TRACKTYPE_Ambient, 'ConfrontApproach', attackVolFactor * 128, 0.5);
				FadeChannelsTo(TRACKTYPE_Ambient, 'ConfrontAttack', attackVolFactor * 128, 0.5);
				break;
			case AT_Sneak:
				//SetMassVolume(TRACKTYPE_Ambient, cache_sneak1, approachVolFactor * 128);
				//SetMassVolume(TRACKTYPE_Ambient, cache_sneak2, attackVolFactor * 128);
				FadeChannelsTo(TRACKTYPE_Ambient, 'SneakApproach', approachVolFactor * 128, 0.5);
				FadeChannelsTo(TRACKTYPE_Ambient, 'SneakAttack', attackVolFactor * 128, 0.5);
				break;
			}
		}
		bApproachChannelsPlaying = True;
	}
	else
	{
	
		// Silence all combat channels in the ambient track
		if (bApproachChannelsPlaying)
		{
			FadeChannelsTo(TRACKTYPE_Ambient, 'ConfrontApproach', 0, 2.0);
			FadeChannelsTo(TRACKTYPE_Ambient, 'ConfrontAttack', 0, 2.0);
			FadeChannelsTo(TRACKTYPE_Ambient, 'SneakApproach', 0, 2.0);
			FadeChannelsTo(TRACKTYPE_Ambient, 'SneakAttack', 0, 2.0);
			bApproachChannelsPlaying = False;
		}
		targettedPawn = None;
		
		volcache1 = 0.0;
		volcache2 = 0.0;
	}
}

// ----------------------------------------------------------------------
// GetTargettedActor()
//
// return the object the player is looking at
// copied from DeusExPlayer and modified
// ----------------------------------------------------------------------

function Actor GetTargettedActor(DeusExPlayer dxp, float maxDistance)
{
	local Actor target, smallestTarget;
	local Vector HitLoc, HitNormal, StartTrace, EndTrace;
	local DeusExRootWindow root;
	local float minSize;
	local bool bFirstTarget;

	if (dxp.IsInState('Dying'))
		return None;

	root = DeusExRootWindow(dxp.rootWindow);

	// figure out how far ahead we should trace
	StartTrace = dxp.Location;
	EndTrace = dxp.Location + (Vector(dxp.ViewRotation) * maxDistance);

	// adjust for the eye height
	StartTrace.Z += dxp.BaseEyeHeight;
	EndTrace.Z += dxp.BaseEyeHeight;

	smallestTarget = None;
	minSize = 99999;
	bFirstTarget = True;

	// find the object that we are looking at
	// make sure we don't select the object that we're carrying
	// use the last traced object as the target...this will handle
	// smaller items under larger items for example
	// ScriptedPawns always have precedence, though
	foreach dxp.TraceActors(class'Actor', target, HitLoc, HitNormal, EndTrace, StartTrace)
	{
		if (dxp.IsFrobbable(target) && (target != dxp.CarriedDecoration))
		{
			if (target.IsA('ScriptedPawn'))
			{
				smallestTarget = target;
				break;
			}
			else if (target.IsA('Mover') && bFirstTarget)
			{
				smallestTarget = target;
				break;
			}
			else if (target.CollisionRadius < minSize)
			{
				minSize = target.CollisionRadius;
				smallestTarget = target;
				bFirstTarget = False;
			}
		}
	}

	return smallestTarget;
}

// ----------------------------------------------------------------------
// SwapAmbientTrack()
//
// - deprecated -
// 
// Swap the current ambient track to the temporary ambient track
// interrupt and unload the ambient track, play the temporary
// ambient track where playback went off (seamless transition)
// ----------------------------------------------------------------------

function SwapAmbientTrack()
{
	local int trackvol;
	
	Open(TRACKTYPE_TemporaryAmbient, ambientTrack);
	SetCurrentOrder(TRACKTYPE_TemporaryAmbient, GetCurrentOrder(TRACKTYPE_Ambient));
	SetPosition(TRACKTYPE_TemporaryAmbient, GetPosition(TRACKTYPE_Ambient));
	trackvol = GetTrackVolume(TRACKTYPE_Ambient);
	log(SPrintf("Swapping ambient to temporaryambient with volume %d", trackvol));
	SetTrackVolume(TRACKTYPE_TemporaryAmbient, trackvol);
	Play(TRACKTYPE_TemporaryAmbient);
	Pause(TRACKTYPE_Ambient);
	ambientTrack = "";
}

// ----------------------------------------------------------------------
// TrackStopped()
// 
// Called when a track was played to the end.
// ----------------------------------------------------------------------

event TrackStopped(TrackType tracknum)
{
	switch(tracknum)
	{
	case TRACKTYPE_Ambient:
	case TRACKTYPE_Battle:
	case TRACKTYPE_Conversation:
	case TRACKTYPE_Outro:
	case TRACKTYPE_ConversationExtra:
		SetPosition(tracknum, 0);
		Play(tracknum);
		break;
	case TRACKTYPE_Motives:
		break;
	default:
	}
}


// ----------------------------------------------------------------------
// TrackPaused()
// 
// Used to circumvent a bug in UnrealScript that requires arrays
// referenced/accessed from another file to be <= 256 bytes total
// ----------------------------------------------------------------------

function SetNewAmbientEvent(int num, Name newEvent)
{
	newAmbientEvents[num] = newEvent;
}

// ----------------------------------------------------------------------
// TrackPaused()
// 
// Called when a track was faded to volume zero.
// ----------------------------------------------------------------------

event TrackPaused(TrackType tracknum)
{
	local int i;
	
	switch(tracknum)
	{
	case TRACKTYPE_Ambient:
		if (newAmbientTrack != "") {
			Open(TRACKTYPE_Ambient, newAmbientTrack);
			PrepareAmbientTrack();
			for (i = 0; i < 256; i++)
			{
				ambientEvents[i] = newAmbientEvents[i];
				newAmbientEvents[i] = '';
			}
			ambientTrack = newAmbientTrack; newAmbientTrack = "";
			SetTrackVolume(TRACKTYPE_Ambient, 0);
			if (currentTrack == TRACKTYPE_Ambient) {
				Play(TRACKTYPE_Ambient);
				FadeTo(TRACKTYPE_Ambient, 128, naTransitionType);
			}
			DeusExPlayer(GetPlayerPawn()).SetPropertyText("bForbidSavingMomentarily", "False");
		}
		break;
	default:
	}
	
	 if (nextTrack != TRACKTYPE_Undefined) {
		SetTrackVolume(nextTrack, 0);
		Play(nextTrack);
		FadeTo(nextTrack, 128, MTRAN_Fade);
		currentTrack = nextTrack; nextTrack = TRACKTYPE_Undefined;
	}
}

function bool IsOverheardConvo(DeusExPlayer dxp)
{
	local ConEvent event;
	local ConEventSpeech eventSpeech;
	
	// Is a conversation going on at all?
	if (dxp.conPlay == None)
		return false;
		
	// Is it non-interactive?
	if (!dxp.conPlay.con.bNonInteractive)
		return false;
		
	// Is there any speech event where the player is addressed?
	if (dxp.conPlay.con.IsSpeakingActor(dxp))
		return false;

	return true;
}

// ----------------------------------------------------------------------
// CheckSneakingStart()
// 
// Return true if player is currently sneaking
// ----------------------------------------------------------------------

function bool CheckSneakingStart(DeusExPlayer dxp)
{
	local ScriptedPawn sp;
	local float pv;
	local bool bCanSee1, bCanSee;
	local Vector v;
	local Vector hl, hn;
	local Actor ta;
	local Rotator rot;
	local int i;
	
	ForEach dxp.RadiusActors(class'ScriptedPawn', sp, 1024)
	{
		if ((sp.GetPawnAllianceType(dxp) == ALLIANCE_Hostile) &&
			(sp.GetStateName() != 'Fleeing') &&
			(!sp.IsA('Animal')) &&
			(!sp.IsA('Robot')))
		{
			pv = dxp.CalculatePlayerVisibility(sp);
			bCanSee = (sp.AICanSee(dxp, pv, true, false, true, true) > 0);
			bCanSee1 = (sp.AICanSee(dxp, 1.0, true, false, true, true) > 0);
			// If enemy can see us without, but not with armor/aug, consider it sneaking
			if (bCanSee1 && !bCanSee)
				return true;
				
			// If enemy can not see us, but a direct line of sight between 512 units
			// above us and the pawn does exist, consider it sneaking
			if (!bCanSee1)
			{
				v = dxp.Location;
				v.z += 512;
				ta = Trace(hl, hn, sp.Location, v, true);
				if (ta == sp)
					return true;
			}
			
			// If we're not on an "inside" map, stop here
			if (!bInterior)
				return false;
				
			// If enemy can not see us, but a direct line of sight between 64/128/256 units
			// besides us and the pawn exists, consider it sneaking
			if (!bCanSee1)
			{
				rot.Yaw = 0;
				rot.Pitch = 0;
				rot.Roll = 0;
				for (i = 0; i < 4; ++i)
				{
					v = dxp.Location;
					v += Vector(rot) * 64;
					ta = Trace(hl, hn, sp.Location, v, true);
					if (ta == sp)
						return true;
					v += Vector(rot) * 64;
					ta = Trace(hl, hn, sp.Location, v, true);
					if (ta == sp)
						return true;
					v += Vector(rot) * 128;
					ta = Trace(hl, hn, sp.Location, v, true);
					if (ta == sp)
						return true;
					rot.Yaw += 16384; /* Rotate by 90 degrees right */
				}
			}
		}
	}
	return false;
}

// ----------------------------------------------------------------------
// CheckSneakingStop()
// 
// Return true if player is not sneaking anymore.
// This function must only be called after CheckSneakingStart() returned
// true, and it must not be called after it has returned true once.
// (This allows for optimisations later to be implemented in this
// function)
// ----------------------------------------------------------------------

function bool CheckSneakingStop(DeusExPlayer dxp, float deltaTime)
{
	// TODO: maybe do some optimisations later
	if (CheckSneakingStart(dxp)) {
		sneakTargetLost = 0.0;
		return false;
	}
	if (sneakTargetLost > 2.3)
		return true;
	sneakTargetLost += deltaTime;
}

// ----------------------------------------------------------------------
// CheckSeeking()
// 
// Check if there is currently a pawn in our vicinity that was alerted
// to our presence and now actively looking out for enemies
// ----------------------------------------------------------------------

function bool CheckSeeking(DeusExPlayer dxp)
{
	local ScriptedPawn sp;
	
	ForEach dxp.RadiusActors(class'ScriptedPawn', sp, 1024)
	{
		if ((sp.GetPawnAllianceType(dxp) == ALLIANCE_Hostile) &&
			(sp.GetStateName() == 'Seeking'))
			return true;
	}
	return false;
}

// ----------------------------------------------------------------------
// IsProjectileWeapon()
// 
// Manually kept list of projectile weapons, returns true if passed
// Weapon is indeed a projectile weapon, false otherwise
// ----------------------------------------------------------------------

function bool IsProjectileWeapon(DeusExWeapon dxw)
{
	return dxw.IsA('WeaponAssaultGun') ||
			dxw.IsA('WeaponAssaultShotgun') ||
			dxw.IsA('WeaponPistol') ||
			dxw.IsA('WeaponMiniCrossbow') ||
			dxw.IsA('WeaponStealthPistol') ||
			dxw.IsA('WeaponSawedOffShotgun') ||
			dxw.IsA('WeaponRifle') ||
			dxw.IsA('WeaponPlasmaRifle');
}

// ----------------------------------------------------------------------
// OrderChanges()
// 
// Called by the ModPlug subsystem when a new pattern in the track's
// pattern order list began to play
// ----------------------------------------------------------------------

event OrderChanged(TrackType tracknum, int neworder)
{
}

// ----------------------------------------------------------------------
// ChoreographyEvent()
// 
// Called by the ModPlug subsystem when a choreographyevent was hit
// in a currently playing track.
// We use this to trigger ChoreographyEvents.
// ----------------------------------------------------------------------

event ChoreographyEvent(TrackType tracknum, int callbacknum)
{
	local Actor a;
	
	switch(tracknum)
	{
	case TRACKTYPE_Ambient:
		if (ambientEvents[callbacknum] == '') {
			DeusExPlayer(GetPlayerPawn()).ClientMessage(SPrintf("No event defined for ambient choreography event #%d", callbacknum));
			return;
		}
		log(SPrintf("ChoreographyEvent %s called", ambientEvents[callbacknum]));
		ForEach AllActors(class'Actor', a, ambientEvents[callbacknum])
			a.Trigger(Self, None);
		break;
	case TRACKTYPE_Special:
		if (specialEvents[callbacknum] == '') {
			DeusExPlayer(GetPlayerPawn()).ClientMessage(SPrintf("No event defined for special choreography event #%d", callbacknum));
			return;
		}
		ForEach AllActors(class'Actor', a, specialEvents[callbacknum])
			a.Trigger(Self, None);
		break;
	}
}

// ----------------------------------------------------------------------
// HandleAlarm()
// 
// Called by the Deus Ex AI subsystem when an event normally handled by
// AIs has occurred
// ----------------------------------------------------------------------

function HandleAlarm(Name event, EAIEventState state, XAIParams params)
{
	switch (state)
	{
	case EAISTATE_Begin:
	case EAISTATE_Pulse:
		FadeChannelsTo(TRACKTYPE_Ambient, 'Alarm', 128, 1.2);
		FadeChannelsTo(TRACKTYPE_Battle, 'Alarm', 128, 1.2);
		LastAlarmTriggering = 0.0;
		bAlarming = True;
		break;
	
	case EAISTATE_End:
		FadeChannelsTo(TRACKTYPE_Ambient, 'Alarm', 0, 4.2);
		FadeChannelsTo(TRACKTYPE_Battle, 'Alarm', 0, 4.2);
		bAlarming = False;
		break;
	}
}

defaultproperties
{
     sneakBeginDistance=768
     confrontationBeginDistance=1024
     lowRangeDistance=192
     attackTimeout=5.000000
     skilledToolFadeInTime=1.000000
}
