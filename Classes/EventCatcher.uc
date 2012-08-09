//=============================================================================
// EventCatcher.
//=============================================================================
class EventCatcher expands Actor;

var ModMusicManager mmm;
var transient DeusExPlayer ourplayer;

function PreBeginPlay()
{
	Super.PreBeginPlay();
}

function Tick(float deltaTime)
{
	if (ourplayer == None)
	{
		ourplayer = DeusExPlayer(GetPlayerPawn());
		if (ourplayer != None)
		{
			SetLocation(ourplayer.Location);
			SetBase(ourplayer);
		}
	}
}

function BeginAction(ModMusicManager newmmm)
{
	mmm = newmmm;
	AISetEventCallback('Alarm', 'HandleAlarm');
}

function HandleAlarm(Name event, EAIEventState state, XAIParams params)
{
	mmm.HandleAlarm(event, state, params);
}

defaultproperties
{
     bHidden=True
}
