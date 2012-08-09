//=============================================================================
// HokeyPokeyTrigger.
//=============================================================================
class HokeyPokeyTrigger expands Trigger;

enum Direction
{
	SPIN_Left,
	SPIN_Right
};

struct Hokey
{
	var() Name Event;
	var() Direction dir;
};

var() Hokey hokeys[16];

function Trigger(Actor Other, Pawn Instigator)
{
	local ScriptedPawn sp;
	local int i;
	
	for (i = 0; (i < 16) && (hokeys[i].Event != ''); i++)
		ForEach AllActors(class'ScriptedPawn', sp, hokeys[i].Event)
		{
			sp.SetOrders('Dancing', '', True);
			if (hokeys[i].dir == SPIN_Left)
				sp.GotoState('Dancing', 'SpinOnceLeft');
			else if (hokeys[i].dir == SPIN_Right)
				sp.GotoState('Dancing', 'SpinOnceRight');
		}

	if (bTriggerOnceOnly)
		Destroy();
}

singular function Touch(Actor Other)
{
	local ScriptedPawn sp;
	local int i;

	if (!IsRelevant(Other))
		return;
	
	for (i = 0; (i < 16) && (hokeys[i].Event != ''); i++)
		ForEach AllActors(class'ScriptedPawn', sp, hokeys[i].Event)
		{
			sp.SetOrders('Dancing', '', True);
			if (hokeys[i].dir == SPIN_Left)
				sp.GotoState('Dancing', 'SpinOnceLeft');
			else if (hokeys[i].dir == SPIN_Right)
				sp.GotoState('Dancing', 'SpinOnceRight');
		}

	if (bTriggerOnceOnly)
		Destroy();
}

defaultproperties
{
     bCollideActors=False
}
