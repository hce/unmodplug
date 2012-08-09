//=============================================================================
// AmbientMusicTrigger.
// (C) 2011-2012, Hans-Christian Esprer <hc-dx@hcesperer.org>
//=============================================================================
class AmbientMusicTrigger expands Trigger;

//
// Set a new ambient music
//

var() float fadeTime;
var() String newAmbientTrack;
var() int    newSneakBeginDistance;
var() int    newConfrontationBeginDistance;
var() int newLowRangeDistance;
var() EMusicTransition transitionType;
var() Name ambientEvents[256]; // Events to trigger for choreographyevents in the ambient music


function Trigger(Actor Other, Pawn Instigator)
{
	if (SetMusic())
	{
		Super.Trigger(Other, Instigator);
		if (bTriggerOnceOnly)
			Destroy();
	}
}

singular function Touch(Actor Other)
{
	if (!IsRelevant(Other))
		return;

	if (SetMusic())
		if (bTriggerOnceOnly)
			Destroy();
			
	if (bTriggerOnceOnly)
		Destroy();
}

function bool SetMusic()
{
	local ModMusicManager mmm;
	local int i;
	foreach AllActors(class'ModMusicManager', mmm) break;
	if (mmm == None)
		return false;
	DeusExPlayer(GetPlayerPawn()).SetPropertyText("bForbidSavingMomentarily", "True");
		
	mmm.naTransitionType = transitionType;
	mmm.newAmbientTrack = newAmbientTrack;
	mmm.sneakBeginDistance = newSneakBeginDistance;
	mmm.confrontationBeginDistance = newConfrontationBeginDistance;
	mmm.lowRangeDistance = newLowRangeDistance;
	
	for (i = 0; i < 256; i++)
		mmm.SetNewAmbientEvent(i, ambientEvents[i]);
	
	mmm.FadeTo(TRACKTYPE_Ambient, 0, transitionType);
	
	return true;
}

defaultproperties
{
     transitionType=MTRAN_SlowFade
}
