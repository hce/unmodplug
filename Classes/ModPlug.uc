//=============================================================================
// ModPlug.
// libmodplug plugin for Unreal/DeusEx
// The library is from libmodplug/libxmms.
// Plugin was done by Hans-Christian Esperer <hc-dx@hcesperer.org>
//=============================================================================

class ModPlug extends Actor
    native;

enum TrackType
{
	TRACKTYPE_Ambient,
	TRACKTYPE_Dying,
	TRACKTYPE_Battle,
	TRACKTYPE_Conversation,
	TRACKTYPE_Outro,
	TRACKTYPE_ConversationExtra,
	TRACKTYPE_Motives,
	TRACKTYPE_TemporaryAmbient,
	TRACKTYPE_Special,
	TRACKTYPE_GreaselCombat,
	TRACKTYPE_Undefined
};

enum EffectType
{
	EFFECTTYPE_None,
	EFFECTTYPE_Arpeggio,
	EFFECTTYPE_PortamentoUp,
	EFFECTTYPE_PortamentoDown,
	EFFECTTYPE_TonePortamento,
	EFFECTTYPE_Vibrato,
	EFFECTTYPE_TonePortaVol,
	EFFECTTYPE_VibratoVol,
	EFFECTTYPE_Tremolo,
	EFFECTTYPE_Panning8,
	EFFECTTYPE_Offset,
	EFFECTTYPE_Volumeslide
};

// These are used by native code only
var native transient private int hFile[32];
var native transient private int bPaused[32];
var native transient private int lastorder[32];
var native transient private int bPendingStopNotifications[32];
var native transient private int bPendingPauseNotifications[32];
var native transient private int fade_volfrom[32];
var native transient private int fade_voldiff[32];
var native transient private int fade_framesbeginning[32]; 
var native transient private int fade_framesleft[32]; 
var native transient private int timing_framespersecond;
var native transient private int ordernotify[32];
var native transient private int pendingChoreographyEvents[32];
var native transient private int channelNames[2048]; // 64 names per track (32 tracks max)
var native transient private int chanfade_numchan[64];
var native transient private int chanfade_volfrom[64];
var native transient private int chanfade_voldiff[64];
var native transient private int chanfade_framesbeginning[64]; 
var native transient private int chanfade_framesleft[64]; 

// Exports, should be used from subclasses only

/** A Word on Channel Types **
    =======================
    
 *  The Impulse Tracker and FastTracker formats allow channels to be named.
 *  This ModPlug plugin reads these names and converts them to Unreal Names
 *  (Unreal Names are almost like strings but can be compared in constant time
      (i.e., very fast))
 *  All Channels with the same name are considered to be of the same "type".
 *  Types can be all kinds of things, for example 'Ambient', 'SneakApproach',
 *  'ReloadingWeapon', 'UsingSkilledTool', you get the idea.
 *
 *  Channels that are not named will be considered to be of no type,
 *  they can not be addressed by bulk functions.
 *
 *  It is recommend to name all channels in your mods. Thus, it is recommended
 *  to use the IT or XM format for modules.
 */

/**
 * Open a module.
 *
 * @param numTrack The "type" of the track: Ambient, Battle, Conversation and so forth.
 * @param fileName The filename of the track, without path.
 * @return 0 on success, nonzero otherwise
 */
native function int Open(TrackType numTrack, String fileName);

/**
 * Play a module
 *
 * Calling this function does not reset the playback position.
 * @param numTrack The "type" of the track: Ambient, Battle, Conversation and so forth.
 */
native function int Play(TrackType numTrack);

/**
 * Pause a module
 *
 * This caused a module to be paused in a very abrupt way.
 * You may with to fade to volume 0 instead.
 * @param numTrack The "type" of the track: Ambient, Battle, Conversation and so forth.
 */
native function int Pause(TrackType numTrack);

/**
 * Get the current playing position.
 *
 * @param numTrack The "type" of the track: Ambient, Battle, Conversation and so forth.
 * @return The current row that is being played, counted
 *     from the first pattern of the module's pattern order.
 */
native function int GetPosition(TrackType numTrack);


/**
 * Set the current playing position.
 *
 * @param numTrack The "type" of the track: Ambient, Battle, Conversation and so forth.
 * @param newPosition The row that should be played next, counted
 *     from the first pattern of the module's pattern order.
 */
native function int SetPosition(TrackType numTrack, int newPosition);

/**
 * Get the number of channels
 *
 * @param numTrack The "type" of the track: Ambient, Battle, Conversation and so forth.
 */
native function int GetNumChannels(TrackType numTrack);

/**
 * Get the master volume of a track
 *
 * @param numTrack The "type" of the track: Ambient, Battle, Conversation and so forth.
 * @return Master volume, ranging from 0 to 64
 */
native function int GetTrackVolume(TrackType numTrack);

/**
 * Set the master volume of a track
 *
 * @param numTrack The "type" of the track: Ambient, Battle, Conversation and so forth.
 * @param newVolume New matser volume, ranging from 0 to 64
 */
native function int SetTrackVolume(TrackType numTrack, int newVolume);

/**
 * Set the volume of a channel abruptly
 *
 * @param numTrack The "type" of the track: Ambient, Battle, Conversation and so forth.
 * @param numChannel The channel to set the volume for
 */
native function int SetChannelVolume(TrackType numTrack, int numChannel, int newVolume);

/**
 * Get the flags of a channel
 *
 * @param numTrack The "type" of the track: Ambient, Battle, Conversation and so forth.
 * @param numChannel The channel to get the flags for
 * @return The channel's flags. Refer to OpenMPT's sndfile.h for valid flag values.
 */
native function int GetChannelFlags(TrackType numTrack, int numChannel);

/**
 * Set flags for a channel
 *
 * @param numTrack The "type" of the track: Ambient, Battle, Conversation and so forth.
 * @param numChannel The channel to set the flags for
 * @param newFlags Flags to *add* to the currently set flags.
 *     Refer to OpenMPT's sndfile.h for valid flag values.
 */
native function int SetChannelFlags(TrackType numTrack, int numChannel, int newFlags);

/**
 * Get the flags of a channel
 *
 * @param numTrack The "type" of the track: Ambient, Battle, Conversation and so forth.
 * @param numChannel The channel to clear the flags from
 * @param newFlags Flags to *remove* from the currently set flags.
 *     Refer to OpenMPT's sndfile.h for valid flag values.
 */
native function int ClrChannelFlags(TrackType numTrack, int numChannel, int flagsToClear);

/**
 * Get the current position in a track's pattern order list
 *
 * @param numTrack The "type" of the track: Ambient, Battle, Conversation and so forth.
 * @return Current position in the track's pattern order list
 */
native function int GetCurrentOrder(TrackType numTrack);

/**
 * Get the current position in a track's pattern order list
 *
 * @param numTrack The "type" of the track: Ambient, Battle, Conversation and so forth.
 * @param newOrder New position in the track's pattern order list
 */
native function int SetCurrentOrder(TrackType numTrack, int newOrder);

/**
 * Loop a pattern
 *
 * @param numTrack The "type" of the track: Ambient, Battle, Conversation and so forth.
 * @param pattern The pattern to loop. If the pattern is already looped,
 *     it is unlooped instead.
 */
native function int LoopPattern(TrackType numTrack, int pattern);

/**
 * Fade the master volume of a track to a desired value
 *
 * @param numTrack The "type" of the track: Ambient, Battle, Conversation and so forth.
 * @param destVolume The desired volume, ranging from 0 to 64
 * @param numSeconds The number of seconds the fade should take
 */
native function int FadeToTime(TrackType numTrack, int destVolume, float numSeconds);

/**
 * Get a list of all track's channels with a certain name
 *
 * @param numTrack The "type" of the track: Ambient, Battle, Conversation and so forth.
 * @param channelType The "type" of the channel. All channels that are named the same
 *     are returned. See also section "Channel Types"
 * @param channels A list that is filled with matching channels. To indicate
 *     the end of the list, the element after the last matching channel is
 *     set to -1.
 */
native function int GetChannelOfType(TrackType numTrack, Name channelType, out int channels[64]);

/**
 * Fade the volume of one channel to a desired value
 *
 * @param numTrack The "type" of the track: Ambient, Battle, Conversation and so forth.
 * @param numChannel The number of the channel to fade
 * @param destVol The desired volume, ranging from 0 to 128
 * @param numSeconds The number of seconds the fade should take
 */
native function int FadeChannelTo(TrackType numTrack, int numChannel, int destVol, float numSeconds);

/**
 * Fade the volume of one channel type to a desired value
 *
 * @param numTrack The "type" of the track: Ambient, Battle, Conversation and so forth.
 * @param channeltype The channel "type"; Also refer to section "Channel Types"
 * @param destVol The desired volume, ranging from 0 to 128
 * @param numSeconds The number of seconds the fade should take
 */
native function int FadeChannelsTo(TrackType numTrack, Name channelType, int destVol, float numSeconds);

/**
 * Add flags to the currently set ones for all channels of a specific "type"
 *
 * @param numTrack The "type" of the track: Ambient, Battle, Conversation and so forth.
 * @param channeltype The channel "type"; Also refer to section "Channel Types"
 * @param newFlags flags to *add* to the currently set ones.
 *     Refer to OpenMPT's sndfile.h for valid flag values
 */
native function int SetChannelsFlags(TrackType numTrack, Name channelType, int newFlags);

/**
 * Remove flags from the currently set ones for all channels of a specific "type"
 *
 * @param numTrack The "type" of the track: Ambient, Battle, Conversation and so forth.
 * @param channeltype The channel "type"; Also refer to section "Channel Types"
 * @param flagsToClear flags to *remove* from the currently set ones.
 *     Refer to OpenMPT's sndfile.h for valid flag values
 */
native function int ClrChannelsFlags(TrackType numTrack, Name channelType, int flagsToClear);

/**
 * Instantly set the volume of one channel type to a desired value
 *
 * @param numTrack The "type" of the track: Ambient, Battle, Conversation and so forth.
 * @param channeltype The channel "type"; Also refer to section "Channel Types"
 * @param destVol The desired volume, ranging from 0 to 128
 */
native function int SetChannelsVolume(TrackType numTrack, Name channelType, int destVol);

/**
 * Enable an effect for every note for a certain class of channel
 *
 * @param numTrack The "type" of the track: Ambient, Battle, COnversation and so forth.
 * @param channeltype The channel "type"; Also refer to section "Channel Types"
 * @param effectType The desired effect
 * @param param The parameter to be passed to the chosen effect
 */
native function int EnableChannelsEffect(TrackType numTrack, Name channelType, EffectType effectType, int param);

/**
 * Disable an effect for every note for a certain class of channel
 *
 * @param numTrack The "type" of the track: Ambient, Battle, COnversation and so forth.
 * @param channeltype The channel "type"; Also refer to section "Channel Types"
 * @param effectType The desired effect
 */
native function int DisableChannelsEffect(TrackType numTrack, Name channelType, EffectType effectType);

/**
 * Transpose every played note of every channel of type channelType
 *
 * @param numTrack The "type" of the track: Ambient, Battle, COnversation and so forth.
 * @param channeltype The channel "type"; Also refer to section "Channel Types"
 * @param transposeBy The amount to transpose every note by (can be negative). 0 to disable.
 */
native function int SetChannelsTranspose(TrackType numTrack, Name channelType, int transposeBy);

/**
 * Swap instruments for a certain channel type
 *
 * @param numTrack The "type" of the track: Ambient, Battle, COnversation and so forth.
 * @param channeltype The channel "type"; Also refer to section "Channel Types"
 * @param instrumentsToUse Instruments to use instead of the original ones
 */
native function int EnableInstrumentOverride(TrackType numTrack, Name channelType, byte instrumentsToUse[256]);

/**
 * Disable instrument swapping for a certain channel type
 *
 * @param numTrack The "type" of the track: Ambient, Battle, COnversation and so forth.
 * @param channeltype The channel "type"; Also refer to section "Channel Types"
 */
native function int ClearInstrumentOverride(TrackType numTrack, Name channelType);

/**
 * Enable or disable libmodplug's "Mega Bass" feature
 *
 * @param bassOn If the mega bass feature is to be turned on (else off)
 */
native function int SetMegaBass(int bassOn);


function FadeTo(TrackType numTrack, int destVolume, EMusicTransition transitionType)
{
	switch(transitionType)
	{
	case MTRAN_NONE:
	case MTRAN_Instant:
		SetTrackVolume(numTrack, destVolume);
		break;
	case MTRAN_Segue:
	case MTRAN_Fade:
		FadeToTime(numTrack, destVolume, 2.0);
		break;
	case MTRAN_FastFade:
		FadeToTime(numTrack, destVolume, 0.5);
		break;
	case MTRAN_SlowFade:
		FadeToTime(numTrack, destVolume, 5.0);
		break;
	}
}

// Fired when a track reached its end
event TrackStopped(TrackType track);

// Fired when a track was paused either
// by calling Pause() or by fading it to
// volume 0
event TrackPaused(TrackType track);

// Fired when the next pattern in a track's
// order list started to play
event OrderChanged(TrackType track, int newOrder);

// Fired when a choreography event command is found in
// the played module
event ChoreographyEvent(TrackType track, int numChoreographyEvent);

defaultproperties
{
     bHidden=True
     Sprite=Texture'Engine.S_Corpse'
}
