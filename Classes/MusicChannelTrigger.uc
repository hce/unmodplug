//=============================================================================
// MusicChannelTrigger.
//
// Switch Music Channels on/off
//
// Hans-Christian Esperer <hc-dx@hcesperer.org> (C) 2012
//=============================================================================
class MusicChannelTrigger expands Trigger;

var() Name Channel;
var() float fadeTime;
var() Name checkFlag;
var() bool flagValue;
var ModMusicManager mmm;
var(ActionAndMusic) float timeToAction;
var(ActionAndMusic) float fadeOutAfterActionTime;

var Actor trigger_actor;
var Pawn trigger_instigator;

var transient bool bIsOn;

function PostPostBeginPlay()
{
	Super.PostPostBeginPlay();
	
	ForEach AllActors(class'ModMusicManager', mmm) break;
	assert(mmm != None);
	
	bIsOn = False;
}

function bool CheckConditions()
{
	local DeusExPlayer player;
	
	player = DeusExPlayer(GetPlayerPawn());
	
	if (checkFlag != '')
	{
		if (player.flagbase.GetBool(checkFlag) != flagValue)
			return false;
	}
	
	if (bTriggerOnceOnly)
	{
		Tag = '';
		SetCollision(False, False, False);
	}
	
	return true;
}

state() TriggerTogglesVolume
{
	function Trigger(Actor Other, Pawn Instigator)
	{
		Super.Trigger(Other, Instigator);
		
		if (!CheckConditions())
			return;
		
		if (bIsOn)
			mmm.FadeChannelsTo(TRACKTYPE_Ambient, Channel, 0, fadeTime);
		else		
			mmm.FadeChannelsTo(TRACKTYPE_Ambient, Channel, 128, fadeTime);
		bIsOn = !bIsOn;
		
		if (bTriggerOnceOnly)
			Destroy();
	}
	
	singular function Touch(Actor Other)
	{
		if (!IsRelevant(Other))
			return;
			
		if (!CheckConditions())
			return;

		if (bIsOn)
			mmm.FadeChannelsTo(TRACKTYPE_Ambient, Channel, 0, fadeTime);
		else		
			mmm.FadeChannelsTo(TRACKTYPE_Ambient, Channel, 128, fadeTime);
		bIsOn = !bIsOn;
	
		if (bTriggerOnceOnly)
			Destroy();
	}
}

state() TriggerFadesIn
{
	function Trigger(Actor Other, Pawn Instigator)
	{
		Super.Trigger(Other, Instigator);
		
		if (!CheckConditions())
			return;
		
		mmm.FadeChannelsTo(TRACKTYPE_Ambient, Channel, 128, fadeTime);
		
		if (bTriggerOnceOnly)
			Destroy();
	}
	
	singular function Touch(Actor Other)
	{
		if (!IsRelevant(Other))
			return;
			
		if (!CheckConditions())
			return;

		mmm.FadeChannelsTo(TRACKTYPE_Ambient, Channel, 128, fadeTime);
	
		if (bTriggerOnceOnly)
			Destroy();
	}
}

state() TriggerFadesOut
{
	function Trigger(Actor Other, Pawn Instigator)
	{
		Super.Trigger(Other, Instigator);
		
		if (!CheckConditions())
			return;

		mmm.FadeChannelsTo(TRACKTYPE_Ambient, Channel, 0, fadeTime);
		
		if (bTriggerOnceOnly)
			Destroy();
	}
	
	singular function Touch(Actor Other)
	{
		if (!IsRelevant(Other))
			return;
			
		if (!CheckConditions())
			return;

		mmm.FadeChannelsTo(TRACKTYPE_Ambient, Channel, 0, fadeTime);
	
		if (bTriggerOnceOnly)
			Destroy();
	}
}

state() TriggerControlsMusic
{
	function Trigger(Actor Other, Pawn Instigator)
	{
		Super.Trigger(Other, Instigator);

		if (!CheckConditions())
			return;
		
		mmm.FadeChannelsTo(TRACKTYPE_Ambient, Channel, 128, fadeTime);
	}
	
	singular function Touch(Actor Other)
	{
		if (!IsRelevant(Other))
			return;
			
		if (!CheckConditions())
			return;

		mmm.FadeChannelsTo(TRACKTYPE_Ambient, Channel, 128, fadeTime);
	}
	
	function UnTouch(Actor Other)
	{
		if (!IsRelevant(Other))
			return;
			
		if (!CheckConditions())
			return;

		mmm.FadeChannelsTo(TRACKTYPE_Ambient, Channel, 0, fadeTime);
		
		if (bTriggerOnceOnly)
			Destroy();
	}

	function UnTrigger(Actor Other, Pawn Instigator)
	{
		Super.UnTrigger(Other, Instigator);
		
		if (!CheckConditions())
			return;

		mmm.FadeChannelsTo(TRACKTYPE_Ambient, Channel, 0, fadeTime);

		if (bTriggerOnceOnly)
			Destroy();
	}
}


state() TriggerTriggersAndPlaysMusic
{
	function Trigger(Actor Other, Pawn Instigator)
	{
		Super.Trigger(Other, Instigator);

		if (!CheckConditions())
			return;
		
		trigger_actor = Other; trigger_instigator = Instigator;
		GotoState('TriggerTriggersAndPlaysMusic', 'BeginAction');
	}
	
	singular function Touch(Actor Other)
	{
		if (!IsRelevant(Other))
			return;
			
		if (!CheckConditions())
			return;

		trigger_actor = Other; trigger_instigator = Pawn(Other);
		GotoState('TriggerTriggersAndPlaysMusic', 'BeginAction');
	}
	
	function DoTheTriggering()
	{
		local Actor A;
		
		if (Event == '')
			return;
			
		ForEach AllActors(class'Actor', A, Event)
			A.Trigger(trigger_actor, trigger_instigator);
	}

BeginAction:
	Disable('Trigger');
	Disable('Touch');
		
	mmm.FadeChannelsTo(TRACKTYPE_Ambient, Channel, 128, fadeTime);
	Sleep(timeToAction);
	DoTheTriggering();
	mmm.FadeChannelsTo(TRACKTYPE_Ambient, Channel, 0, fadeOutAfterActionTime);

	Enable('Trigger');
	Enable('Touch');
}

defaultproperties
{
     InitialState=TriggerFadesIn
}
