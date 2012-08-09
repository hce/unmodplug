//=============================================================================
// RandomTrigger.
//=============================================================================
class RandomTrigger expands Trigger;

var() name OutEvents[16]; // Events to generate.

var int count;

function BeginPlay()
{
	local int i;
	
	Super.BeginPlay();
	
	count = 16;
	for (i = 0; i < 16; i++)
	{
		if (OutEvents[i] == '')
		{
			count = i;
			break;
		}
	}
}

function Trigger(Actor Other, Pawn Instigator)
{
	local Actor A;
	local Name at;
	
	at = OutEvents[Rand(count)];
	
	if (FRand() < 0.5)
	{
		ForEach AllActors(class'Actor', A, at)
			A.Trigger(Other, Instigator);
	}
	else
	{
		ForEach AllActors(class'Actor', A, at)
			A.UnTrigger(Other, Instigator);
	}
}

defaultproperties
{
}
