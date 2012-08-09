/*===========================================================================
    C++ class definitions exported from UnrealScript.
    This is automatically generated by the tools.
    DO NOT modify this manually! Edit the corresponding .uc files instead!
===========================================================================*/
#if _MSC_VER
#pragma pack (push,4)
#endif

#ifndef MODPLUG_API
#define MODPLUG_API DLL_IMPORT
#endif

#ifndef NAMES_ONLY
#define AUTOGENERATE_NAME(name) extern MODPLUG_API FName MODPLUG_##name;
#define AUTOGENERATE_FUNCTION(cls,idx,name)
#endif

AUTOGENERATE_NAME(TrackStopped)
AUTOGENERATE_NAME(TrackPaused)
AUTOGENERATE_NAME(OrderChanged)
AUTOGENERATE_NAME(ChoreographyEvent)

#ifndef NAMES_ONLY

enum EffectType
{
    EFFECTTYPE_None         =0,
    EFFECTTYPE_Arpeggio     =1,
    EFFECTTYPE_PortamentoUp =2,
    EFFECTTYPE_PortamentoDown=3,
    EFFECTTYPE_TonePortamento=4,
    EFFECTTYPE_Vibrato      =5,
    EFFECTTYPE_TonePortaVol =6,
    EFFECTTYPE_VibratoVol   =7,
    EFFECTTYPE_Tremolo      =8,
    EFFECTTYPE_Panning8     =9,
    EFFECTTYPE_Offset       =10,
    EFFECTTYPE_Volumeslide  =11,
    EFFECTTYPE_MAX          =12,
};
enum TrackType
{
    TRACKTYPE_Ambient       =0,
    TRACKTYPE_Dying         =1,
    TRACKTYPE_Battle        =2,
    TRACKTYPE_Conversation  =3,
    TRACKTYPE_Outro         =4,
    TRACKTYPE_ConversationExtra=5,
    TRACKTYPE_Motives       =6,
    TRACKTYPE_TemporaryAmbient=7,
    TRACKTYPE_Special       =8,
    TRACKTYPE_Undefined     =9,
    TRACKTYPE_MAX           =10,
};

struct AModPlug_eventChoreographyEvent_Parms
{
    BYTE track;
    INT numChoreographyEvent;
};
struct AModPlug_eventOrderChanged_Parms
{
    BYTE track;
    INT newOrder;
};
struct AModPlug_eventTrackPaused_Parms
{
    BYTE track;
};
struct AModPlug_eventTrackStopped_Parms
{
    BYTE track;
};
class MODPLUG_API AModPlug : public AActor
{
public:
    INT hFile[32];
    INT bPaused[32];
    INT lastorder[32];
    INT bPendingStopNotifications[32];
    INT bPendingPauseNotifications[32];
    INT fade_volfrom[32];
    INT fade_voldiff[32];
    INT fade_framesbeginning[32];
    INT fade_framesleft[32];
    INT timing_framespersecond;
    INT ordernotify[32];
    INT pendingChoreographyEvents[32];
    INT channelNames[2048];
    INT chanfade_numchan[64];
    INT chanfade_volfrom[64];
    INT chanfade_voldiff[64];
    INT chanfade_framesbeginning[64];
    INT chanfade_framesleft[64];
    DECLARE_FUNCTION(execSetMegaBass);
    DECLARE_FUNCTION(execClearInstrumentOverride);
    DECLARE_FUNCTION(execEnableInstrumentOverride);
    DECLARE_FUNCTION(execSetChannelsTranspose);
    DECLARE_FUNCTION(execDisableChannelsEffect);
    DECLARE_FUNCTION(execEnableChannelsEffect);
    DECLARE_FUNCTION(execSetChannelsVolume);
    DECLARE_FUNCTION(execClrChannelsFlags);
    DECLARE_FUNCTION(execSetChannelsFlags);
    DECLARE_FUNCTION(execFadeChannelsTo);
    DECLARE_FUNCTION(execFadeChannelTo);
    DECLARE_FUNCTION(execGetChannelOfType);
    DECLARE_FUNCTION(execFadeToTime);
    DECLARE_FUNCTION(execLoopPattern);
    DECLARE_FUNCTION(execSetCurrentOrder);
    DECLARE_FUNCTION(execGetCurrentOrder);
    DECLARE_FUNCTION(execClrChannelFlags);
    DECLARE_FUNCTION(execSetChannelFlags);
    DECLARE_FUNCTION(execGetChannelFlags);
    DECLARE_FUNCTION(execSetChannelVolume);
    DECLARE_FUNCTION(execSetTrackVolume);
    DECLARE_FUNCTION(execGetTrackVolume);
    DECLARE_FUNCTION(execGetNumChannels);
    DECLARE_FUNCTION(execSetPosition);
    DECLARE_FUNCTION(execGetPosition);
    DECLARE_FUNCTION(execPause);
    DECLARE_FUNCTION(execPlay);
    DECLARE_FUNCTION(execOpen);
    void eventChoreographyEvent(BYTE track, INT numChoreographyEvent)
    {
        AModPlug_eventChoreographyEvent_Parms Parms;
        Parms.track=track;
        Parms.numChoreographyEvent=numChoreographyEvent;
        ProcessEvent(FindFunctionChecked(TEXT("ChoreographyEvent")),&Parms);
    }
    void eventOrderChanged(BYTE track, INT newOrder)
    {
        AModPlug_eventOrderChanged_Parms Parms;
        Parms.track=track;
        Parms.newOrder=newOrder;
        ProcessEvent(FindFunctionChecked(TEXT("OrderChanged")),&Parms);
    }
    void eventTrackPaused(BYTE track)
    {
        AModPlug_eventTrackPaused_Parms Parms;
        Parms.track=track;
        ProcessEvent(FindFunctionChecked(TEXT("TrackPaused")),&Parms);
    }
    void eventTrackStopped(BYTE track)
    {
        AModPlug_eventTrackStopped_Parms Parms;
        Parms.track=track;
        ProcessEvent(FindFunctionChecked(TEXT("TrackStopped")),&Parms);
    }
    DECLARE_CLASS(AModPlug,AActor,0)
	AModPlug();
	void Destroy(void);
	UBOOL Tick(FLOAT fTime, ELevelTick TickType);
	DWORD AModPlug::intFadeChannelTo(LPVOID module, INT channel,
					  INT trackchannel, INT destvol,
					  FLOAT numSeconds);
};


class MODPLUG_API AMiscFunctions : public AActor
{
public:
    DECLARE_FUNCTION(execScreenshotToTCP);
    DECLARE_CLASS(AMiscFunctions,AActor,0)
    NO_DEFAULT_CONSTRUCTOR(AMiscFunctions)
};

#endif

AUTOGENERATE_FUNCTION(AModPlug,-1,execClearInstrumentOverride);
AUTOGENERATE_FUNCTION(AModPlug,-1,execEnableInstrumentOverride);
AUTOGENERATE_FUNCTION(AModPlug,-1,execSetChannelsTranspose);
AUTOGENERATE_FUNCTION(AModPlug,-1,execDisableChannelsEffect);
AUTOGENERATE_FUNCTION(AModPlug,-1,execEnableChannelsEffect);
AUTOGENERATE_FUNCTION(AModPlug,-1,execSetChannelsVolume);
AUTOGENERATE_FUNCTION(AModPlug,-1,execClrChannelsFlags);
AUTOGENERATE_FUNCTION(AModPlug,-1,execSetChannelsFlags);
AUTOGENERATE_FUNCTION(AModPlug,-1,execFadeChannelsTo);
AUTOGENERATE_FUNCTION(AModPlug,-1,execFadeChannelTo);
AUTOGENERATE_FUNCTION(AModPlug,-1,execGetChannelOfType);
AUTOGENERATE_FUNCTION(AModPlug,-1,execFadeToTime);
AUTOGENERATE_FUNCTION(AModPlug,-1,execLoopPattern);
AUTOGENERATE_FUNCTION(AModPlug,-1,execSetCurrentOrder);
AUTOGENERATE_FUNCTION(AModPlug,-1,execGetCurrentOrder);
AUTOGENERATE_FUNCTION(AModPlug,-1,execClrChannelFlags);
AUTOGENERATE_FUNCTION(AModPlug,-1,execSetChannelFlags);
AUTOGENERATE_FUNCTION(AModPlug,-1,execGetChannelFlags);
AUTOGENERATE_FUNCTION(AModPlug,-1,execSetChannelVolume);
AUTOGENERATE_FUNCTION(AModPlug,-1,execSetTrackVolume);
AUTOGENERATE_FUNCTION(AModPlug,-1,execGetTrackVolume);
AUTOGENERATE_FUNCTION(AModPlug,-1,execGetNumChannels);
AUTOGENERATE_FUNCTION(AModPlug,-1,execSetPosition);
AUTOGENERATE_FUNCTION(AModPlug,-1,execGetPosition);
AUTOGENERATE_FUNCTION(AModPlug,-1,execPause);
AUTOGENERATE_FUNCTION(AModPlug,-1,execPlay);
AUTOGENERATE_FUNCTION(AModPlug,-1,execOpen);
AUTOGENERATE_FUNCTION(AMiscFunctions,-1,execScreenshotToTCP);

#ifndef NAMES_ONLY
#undef AUTOGENERATE_NAME
#undef AUTOGENERATE_FUNCTION
#endif NAMES_ONLY

#if _MSC_VER
#pragma pack (pop)
#endif
