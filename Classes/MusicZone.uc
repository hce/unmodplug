//=============================================================================
// MusicZone.
//=============================================================================
class MusicZone expands ZoneInfo;

var ModMusicManager mmm;


// Channels to fade in when player enters the zone
var () Name fadein[4];

// Channels to fade out when player enters the zone
var () Name fadeout[4];

// Time it takes to fade channels in/out
var () float fadetime;

function PostPostBeginPlay()
{
	local DeusExPlayer dxp;
	
	Super.PostPostBeginPlay();
	
	// Find our ModMusicManager class
	// Assume there *is* one; using MusicZones makes only
	// sense in conjunction with one
	ForEach AllActors(class'ModMusicManager', mmm) break;
	assert(mmm != None);
}

event ActorEntered( actor Other )
{
	local int i;
	
	if (DeusExPlayer(Other) == None)
		return;
		
	for (i = 0; i < 4; i++)
	{
		if (fadein[i] != '')
			mmm.FadeChannelsTo(TRACKTYPE_Ambient, fadein[i], 128, fadetime);
		if (fadeout[i] != '')
			mmm.FadeChannelsTo(TRACKTYPE_Ambient, fadeout[i], 0, fadetime);
	}
	mmm.currentMusicZone = Self;
}

event ActorLeaving( actor Other )
{
	local int i;
	
	if (DeusExPlayer(Other) == None)
		return;

	for (i = 0; i < 4; i++)
	{
		if (fadein[i] != '')
			mmm.FadeChannelsTo(TRACKTYPE_Ambient, fadein[i], 0, fadetime);
		if (fadeout[i] != '')
			mmm.FadeChannelsTo(TRACKTYPE_Ambient, fadeout[i], 128, fadetime);
	}
	if (mmm.currentMusicZone == Self)
		mmm.currentMusicZone = None;
}

defaultproperties
{
}
