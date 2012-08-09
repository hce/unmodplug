//=============================================================================
// DelayedDataLinkTrigger.
//=============================================================================
class DelayedDataLinkTrigger expands DataLinkTrigger;

//
// Triggers a DataLink event when touched with a configurable delay
// Fades specified music track in at the beginning of the delay,
// fades it out after DataLink has ended
//
// Copied from DeusEx.DataLink and modified
//
// * datalinkTag is matched to the conversation file which has all of
//   the DataLink events in it.
//
// We might possibly need to monitor a flag and trigger a DataLink event
// when that flag changes during the mission.  This could be done in the
// individual mission's script file update loop.
//

var() name MusicTrack;
var() float DataLinkDelay;
var() float FadeTime;
var String dataLinkName;
var bool bActive;
var float tempDelay;
var bool bSvt;

var ModMusicManager mmm;


// ----------------------------------------------------------------------
// BeginPlay()
// ----------------------------------------------------------------------

function BeginPlay()
{
	Super.BeginPlay();

	// Hack so we can destroy all DataLinks with the same DL_
	Tag = dataLinkTag;	
}

// ----------------------------------------------------------------------
// PostPostBeginPlay()
// ----------------------------------------------------------------------

function PostPostBeginPlay()
{
	Super.PostPostBeginPlay();
	
	ForEach AllActors(class'ModMusicManager', mmm) break;
	assert(mmm != None);
}

// ----------------------------------------------------------------------
// Timer()
// ----------------------------------------------------------------------

function Timer()
{
	if ((bCheckFlagTimer) && (EvaluateFlag()) && (player != None))
		BeginDataLink(String(datalinkTag), False);
}

// ----------------------------------------------------------------------
// BeginDataLink()
// ----------------------------------------------------------------------

function BeginDataLink(String dln, bool svt)
{
	player.SetPropertyText("bForbidSavingMomentarily", "True");
	dataLinkName = dln;
	tempDelay = DataLinkDelay;
	bActive = True;
	bSvt = svt;
	mmm.FadeChannelsTo(TRACKTYPE_Ambient, MusicTrack, 128, FadeTime);
}

// ----------------------------------------------------------------------
// Tick()
// ----------------------------------------------------------------------

function Tick(float deltaTime)
{
	Super.Tick(deltaTime);
	
	if (!bActive)
		return;
	tempDelay -= deltaTime;
	if (tempDelay <= 0)
	{
		if (player == None)
			player = DeusExPlayer(GetPlayerPawn());
		if (player == None) {
			log("Unable to get PlayerPawn in ModPlug.DelayedDataLinkTrigger.Tick!");
			return;
		}
		if(player.StartDataLinkTransmission(String(datalinkTag), Self))
		{
			bStartedViaTrigger = bSvt;
			bStartedViaTouch   = !bSvt;
		}
		bActive = False;
	} 
}

// ----------------------------------------------------------------------
// Trigger()
// ----------------------------------------------------------------------

singular function Trigger(Actor Other, Pawn Instigator)
{
	// Only set the player if the player isn't already set and 
	// the "bCheckFlagTimer" variable is false
	if ((player == None) || ((player != None) && (bCheckFlagTimer == False)))
		player = DeusExPlayer(Instigator);

	// only works for DeusExPlayers
	if (player == None)
		return;

	if (EvaluateFlag())
	{
		BeginDataLink(string(dataLinkTag), True);
		triggerOther       = Other;
		triggerInstigator  = Instigator;
	}
	else if (checkFlag != '')
	{
		bStartedViaTrigger = True;
		triggerOther       = Other;
		triggerInstigator  = Instigator;
	}
}

// ----------------------------------------------------------------------
// Touch()
// ----------------------------------------------------------------------

singular function Touch(Actor Other)
{
	// Only set the player if the player isn't already set and 
	// the "bCheckFlagTimer" variable is false
	if ((player == None) || ((player != None) && (bCheckFlagTimer == False)))
		player = DeusExPlayer(Other);

	// only works for DeusExPlayers
	if (player == None)
		return;

	if (EvaluateFlag())
	{
		BeginDataLink(String(datalinkTag), False);
		triggerOther     = Other;
	}
	else if (checkFlag != '')
	{
		bStartedViaTouch   = True;
		triggerOther       = Other;
	}
}

// ----------------------------------------------------------------------
// UnTouch()
// 
// Used to monitor the state of the "checkFlag" variable if it's set.
// This is so a player can be sitting inside the radius of a trigger
// and if the "checkFlag" suddenly is valid, the trigger will play.
// ----------------------------------------------------------------------

function UnTouch( actor Other )
{
	bCheckFlagTimer = False;
	Super.UnTouch(Other);
}

// ----------------------------------------------------------------------
// EvaluateFlag()
// ----------------------------------------------------------------------

function bool EvaluateFlag()
{
	local bool bSuccess;

	if (checkFlag != '')
	{
		if ((player != None) && (player.flagBase != None))
		{
			if (!player.flagBase.GetBool(checkFlag))
				bSuccess = bCheckFalse;
			else
				bSuccess = !bCheckFalse;

			// If the flag check fails, then make sure the Tick() event 
			// is active so we can continue to check the flag while 
			// the player is inside the radius of the trigger.

			if (!bSuccess)
			{
				bCheckFlagTimer = True;
				SetTimer(checkFlagTimer, False);
			}
		}
		else
		{
			bSuccess = False;
		}
	}
	else
	{
		bSuccess = True;
	}

	return bSuccess;
}

// ----------------------------------------------------------------------
// DatalinkFinished()
// ----------------------------------------------------------------------

function DatalinkFinished()
{
	local DelayedDataLinkTrigger ddlt;
	
	mmm.FadeChannelsTo(TRACKTYPE_Ambient, MusicTrack, 0, FadeTime);
	player.SetPropertyText("bForbidSavingMomentarily", "False");
	// Destroy all with the same dataLinkTag, because we cannot easily
	// and elegantly check if a certain DL has already been played
	// and thus would inadvertently fade in the music track
	ForEach AllActors(class'DelayedDataLinkTrigger', ddlt, dataLinkTag)
		ddlt.Destroy();
	
	if (bStartedViaTrigger)
		Super.Trigger(triggerOther, triggerInstigator);
	else if (bStartedViaTouch)
		Super.Touch(triggerOther);
}

// ----------------------------------------------------------------------
// ----------------------------------------------------------------------

defaultproperties
{
}
