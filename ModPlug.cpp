// ModPlug.cpp : Definiert den Einsprungpunkt für die DLL-Anwendung.
//

#include "stdafx.h"


// We define our own DllMain instead!
// IMPLEMENT_PACKAGE(ModPlug);
extern "C" DLL_EXPORT TCHAR GPackage[];
DLL_EXPORT TCHAR GPackage[] = TEXT("ModPlug");

IMPLEMENT_CLASS(AModPlug);

// Package implementation.
extern "C" {
	HINSTANCE hInstance;
}

void initSound(void);
void fillbuffer(void*, Uint8*, int);

BOOLEAN soundInitialised = NULL;
AModPlug* globalModule = NULL;
int global_timing_framespersecond = -1;
FName fMODPLUG(TEXT("ModPlug"));

INT DLL_EXPORT STDCALL DllMain(HINSTANCE hInInstance, DWORD Reason, void* Reserved)
{
	hInstance = hInInstance;
	switch(Reason)
	{
	case DLL_PROCESS_ATTACH:
		if(SDL_Init(SDL_INIT_AUDIO | SDL_INIT_VIDEO)) {
			MessageBox(NULL, TEXT("Fatal: Unable to initialize SDL"),
				TEXT("HC's ModPlug Unreal Plugin"), MB_ICONEXCLAMATION | MB_OK);
			return 0;
		}
		GLog->Logf(NAME_Log, TEXT("HC's <hc@hcesperer.org> libmodplug plugin for DeusEx"));
		GLog->Logf(NAME_Log, TEXT("Based on the absolutely astounding libmodplug library."));
		break;

	case DLL_PROCESS_DETACH:
		SDL_Quit();
		break;
	}
	return 1;
}

void initSound(void)
{
	if (soundInitialised)
		return;
	
	SDL_AudioSpec format, whatwegot;
	format.freq        = 48000;
	format.channels    = 2;
	format.samples     = AUDIO_BUFFER_SIZE;
	format.format      = AUDIO_S16;
	format.userdata    = NULL; /* unused */ // this;
	format.callback    = fillbuffer;

	if (SDL_OpenAudio(&format, &whatwegot)) {
		SDL_CloseAudio();
		if (SDL_OpenAudio(&format, &whatwegot)) {
			GLog->Logf(TEXT("Unable to SDL_OpenAudio!"));
		}
	}
	global_timing_framespersecond = whatwegot.freq * whatwegot.channels * ((whatwegot.format == AUDIO_S16) ? 2 : 1);
	SDL_PauseAudio(0);

	SetMegaBass(whatwegot.freq, TRUE);
	GLog->Logf(TEXT("Setting libmpt playback frequency to %d Hz"), whatwegot.freq);
	soundInitialised = TRUE;
}

void fillbuffer(void* userdata, Uint8* stream, int len)
{
	//AModPlug* amp = (AModPlug*) userdata;
	AModPlug* amp = globalModule;
	BOOLEAN bFirst = TRUE;
	Uint8 stream2[AUDIO_BUFFER_SIZE * 4];
	UINT byteswritten;
	INT curorder;
	int i;
	int numtrack, numchannel;

	if (amp == NULL)
		return;

	if(sizeof(stream2) < len)
		return;

    guard (fillbuffer);

	for (i = 0; i < 32; i++) {
		INT ptr = amp->hFile[i];
		if ((ptr != 0) && (!amp->bPaused[i])) {
			HMPMODULE mod = (HMPMODULE) ptr;
			if (bFirst) {
				byteswritten = ReadModFile(mod, stream, len);
				bFirst = FALSE;
			} else {
				byteswritten = ReadModFile(mod, stream2, len);
				SDL_MixAudio(stream, stream2, len, SDL_MIX_MAXVOLUME);
			}
			curorder = GetCurrentOrder(mod);

			if (curorder != amp->lastorder[i])
				// queue an order notify event at the next tick
				// in the unlikely case these happen more than once
				// per tick, only the last one during that tick is
				// propagated to US. That is ok.
				amp->ordernotify[i] = curorder;

			// If we're at the end of the track
			// or skipped a pattern, pause the track.
			if ((byteswritten == 0) ||
				(curorder > (amp->lastorder[i] + 1))) {
				amp->bPaused[i] = 1;
				// queue a TrackStopped event that is
				// eventually passed to UnrealScript
				amp->bPendingStopNotifications[i] = 1;
			} else {
				amp->lastorder[i] = curorder;
			}

			// Handle fading
			if (amp->fade_voldiff[i] != 0) {
				if (amp->fade_framesleft[i] > 0) {
					SetMasterVolume(mod, amp->fade_volfrom[i] +
						((amp->fade_framesbeginning[i] - amp->fade_framesleft[i]) *
						amp->fade_voldiff[i] / amp->fade_framesbeginning[i]));
					amp->fade_framesleft[i] -= len;
				} else {
					UINT finalvolume = amp->fade_volfrom[i] + amp->fade_voldiff[i];
					SetMasterVolume(mod, finalvolume);
					if (finalvolume == 0) {
						// If we faded the track out, pause it and
						// notify UnrealScript
						amp->bPaused[i] = 1;
						amp->bPendingPauseNotifications[i] = 1;
					}
					amp->fade_voldiff[i] = 0;
				}
			}
//INT fade_volfrom[32];
    //INT fade_volto[32];
    //INT fade_framesleft[32];
		}
	}


	// Handle fading for single channels
	// A maximum of MAX_CHAN_FADES fades may occur in parallel.
	for (i = 0; i < MAX_CHAN_FADES; ++i) {
		if (amp->chanfade_numchan[i] != -1) {
			numtrack   = amp->chanfade_numchan[i] >> 8;
			numchannel = amp->chanfade_numchan[i] & 0xFF;
			HMPMODULE mod = (HMPMODULE) amp->hFile[numtrack];
			if (mod == NULL) {
				amp->chanfade_numchan[i] = -1;
				continue;
			}
			if (amp->chanfade_framesleft[i] > 0) {
				SetChannelVolume(mod, numchannel,
					amp->chanfade_volfrom[i] +
					((amp->chanfade_framesbeginning[i] - amp->chanfade_framesleft[i]) *
					amp->chanfade_voldiff[i] / amp->chanfade_framesbeginning[i]));
					amp->chanfade_framesleft[i] -= len;
			} else {
				UINT finalvolume = amp->chanfade_volfrom[i] + amp->chanfade_voldiff[i];
				SetChannelVolume(mod, numchannel, finalvolume);
				if (finalvolume < 1) {
					SetChannelFlags(mod, numchannel,
						GetChannelFlags(mod, numchannel) | CHN_MUTE);
				}
				amp->chanfade_numchan[i] = -1; /* Free that slot */
			}
		}
	}

	unguard;
}

void __cdecl choreographyCallback(void *userdata, int command)
{
	INT *destvar = (INT*) userdata;
	*destvar = command;
}

#define ASSERTCHANNEL(channel)\
{\
	if (channel >= 64)\
	{\
		GLog->Logf(TEXT("modplug: Invalid channel number %d, only 64 channels are supported."), channel);\
		*(DWORD*)Result = 0;\
		return;\
	}\
}

//		GLog->Logf(TEXT("modplug: Track number %d is not loaded."), channel);\

#define ASSERTLOADED(file, channel)\
{\
	if (file[channel] == 0)\
	{\
		*(DWORD*)Result = 0;\
		return;\
	}\
}

// Open a tracker file
// into the specified slot
IMPLEMENT_FUNCTION(AModPlug,-1,execOpen);
void 
AModPlug::execOpen (FFrame& Stack, RESULT_DECL)
{
	P_GET_INT(channel);
	P_GET_STR(filename);
    P_FINISH;

	FString modpath = TEXT("../Music/");

    guard (AhzTest::execOpen);

	ASSERTCHANNEL(channel)

	if (hFile[channel] != 0)
	{
		HMPMODULE oldModule = (HMPMODULE) hFile[channel];
		SDL_LockAudio();
		hFile[channel] = 0;
		SDL_UnlockAudio();
		CloseModFile(&oldModule);
		for (UINT i = 0; i < MAX_CHANS_PER_TRACK; ++i) {
			FName* chanName = (FName*) channelNames[(channel * MAX_CHANS_PER_TRACK) + i];
			if (chanName != NULL)
				delete chanName;
		}
	}


	modpath = modpath + filename;
	HANDLE openfile = CreateFile(
		(LPCWSTR)modpath.GetCharArray().GetData(),
		GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_DELETE |
		FILE_SHARE_WRITE, NULL, OPEN_EXISTING, 0, FALSE);

	if (openfile == INVALID_HANDLE_VALUE)
	{
		GLog->Logf(TEXT("modplug: Unable to open file %s"),
			filename.GetCharArray().GetData());
		*(DWORD*)Result = 0;
		return;
	}
		

	bPaused[channel] = 1;
	HMPMODULE modfile = OpenModFile(openfile);
	hFile[channel] = (INT) modfile;
	
	CloseHandle(openfile);

	if (hFile[0] == NULL) {
		GLog->Logf(TEXT("modplug: Unsuccessfully tried to load file %s"),
			modpath.GetCharArray().GetData());
		*(DWORD*)Result = 0;
		return;
	}

	SetChoreographyCallback(modfile, choreographyCallback,
		&pendingChoreographyEvents[channel]);

	// Retrieve the names of the mod file's channels,
	// convert them to Unreal Names, to allow for fast
	// comparision, and store them.
	const char* channelnames[MAX_CHANS_PER_TRACK];
	unsigned short channelname_t[128];
	unsigned int i, num_channels;

	num_channels = GetChannelNames(modfile, channelnames, MAX_CHANS_PER_TRACK);
	GLog->Logf(TEXT("Loading: %s"), filename, num_channels);
	for(i = 0; i < MAX_CHANS_PER_TRACK; ++i) {
		if (channelnames[i] && *channelnames[i]) {
			MultiByteToWideChar(CP_ACP, 0, channelnames[i], -1,
				channelname_t, 128);
			FName* channelName = new FName(channelname_t);
			channelNames[(channel * MAX_CHANS_PER_TRACK) + i] = (INT)channelName;
		} else {
			channelNames[(channel * MAX_CHANS_PER_TRACK) + i] = 0;
		}
	}

    // return success/failure 
    *(DWORD*)Result = (hFile[channel] == NULL) ? 0 : 1;
    unguardexec; 
} 

IMPLEMENT_FUNCTION(AModPlug,-1,execPlay);
void 
AModPlug::execPlay (FFrame& Stack, RESULT_DECL)
{
    guard (AhzTest::execPlay); 
	P_GET_INT(channel);
    P_FINISH;

	ASSERTCHANNEL(channel);

	bPaused[channel] = 0;

    // return success 
    *(DWORD*)Result = 1;
    unguardexec; 
} 

IMPLEMENT_FUNCTION(AModPlug,-1,execPause);
void 
AModPlug::execPause (FFrame& Stack, RESULT_DECL)
{
    guard (AhzTest::execPause); 
	P_GET_INT(channel)
    P_FINISH;

	ASSERTCHANNEL(channel);

	bPaused[channel] = 1;

    // return success 
    *(DWORD*)Result = 1;
    unguardexec; 
} 

IMPLEMENT_FUNCTION(AModPlug,-1,execGetPosition);
void 
AModPlug::execGetPosition (FFrame& Stack, RESULT_DECL)
{
    guard (AhzTest::execGetPosition); 
	P_GET_INT(channel)
	P_GET_INT(trackchannel)
    P_FINISH;

	ASSERTCHANNEL(channel)
	ASSERTLOADED(hFile, channel)

	HMPMODULE module = (HMPMODULE) hFile[channel];
    *(DWORD*)Result = GetPosition(module);

    unguardexec; 
} 

IMPLEMENT_FUNCTION(AModPlug,-1,execSetPosition);
void 
AModPlug::execSetPosition (FFrame& Stack, RESULT_DECL)
{
    guard (AhzTest::execSetPosition);
	P_GET_INT(channel)
	P_GET_INT(newposition)
    P_FINISH;

	ASSERTCHANNEL(channel)
	ASSERTLOADED(hFile, channel)

	HMPMODULE module = (HMPMODULE) hFile[channel];
    *(DWORD*)Result = SetPosition(module, newposition);
	lastorder[channel] = GetCurrentOrder(module);

    unguardexec; 
} 

IMPLEMENT_FUNCTION(AModPlug,-1,execGetNumChannels);
void 
AModPlug::execGetNumChannels (FFrame& Stack, RESULT_DECL)
{
    guard (AhzTest::execGetNumChannels); 
	P_GET_INT(channel)
    P_FINISH;

	ASSERTCHANNEL(channel)
	ASSERTLOADED(hFile, channel)

	HMPMODULE module = (HMPMODULE) hFile[channel];
    *(DWORD*)Result = GetNumChannels(module);

    unguardexec; 
} 

IMPLEMENT_FUNCTION(AModPlug,-1,execSetChannelVolume);
void 
AModPlug::execSetChannelVolume (FFrame& Stack, RESULT_DECL)
{
    guard (AhzTest::execSetChannelVolume); 
	P_GET_INT(channel)
	P_GET_INT(trackchannel)
	P_GET_INT(newvolume)
    P_FINISH;

	ASSERTCHANNEL(channel)
	ASSERTLOADED(hFile, channel)

	HMPMODULE module = (HMPMODULE) hFile[channel];

	int numchannels = GetNumChannels(module);
	if (numchannels <= trackchannel) {
		GLog->Logf(TEXT("modplug: Channel %d does not exist in track %d."),
			trackchannel, channel);
		*(DWORD*)Result = -1;
		return;
	}

    *(DWORD*)Result = SetChannelVolume(module, trackchannel, newvolume);
	if (newvolume == 0) {
		SetChannelFlags(module, trackchannel,
			GetChannelFlags(module, trackchannel) | CHN_MUTE);
	} else {
		SetChannelFlags(module, trackchannel,
			GetChannelFlags(module, trackchannel) & ~CHN_MUTE);
	}

    unguardexec; 
} 

IMPLEMENT_FUNCTION(AModPlug,-1,execGetChannelFlags);
void 
AModPlug::execGetChannelFlags (FFrame& Stack, RESULT_DECL)
{
    guard (AhzTest::execGetChannelFlags); 
	P_GET_INT(channel)
	P_GET_INT(trackchannel)
    P_FINISH;

	ASSERTCHANNEL(channel)
	ASSERTLOADED(hFile, channel)

	HMPMODULE module = (HMPMODULE) hFile[channel];
	int numchannels = GetNumChannels(module);
	if (numchannels <= trackchannel) {
		GLog->Logf(TEXT("modplug: Channel %d does not exist in track %d."),
			trackchannel, channel);
		*(DWORD*)Result = -1;
		return;
	}

    *(DWORD*)Result = GetChannelFlags(module, trackchannel);

    unguardexec; 
} 

IMPLEMENT_FUNCTION(AModPlug,-1,execSetChannelFlags);
void 
AModPlug::execSetChannelFlags (FFrame& Stack, RESULT_DECL)
{
    guard (AhzTest::execSetChannelFlags); 
	P_GET_INT(channel)
	P_GET_INT(trackchannel)
	P_GET_INT(flagstoset)
    P_FINISH;

	ASSERTCHANNEL(channel)
	ASSERTLOADED(hFile, channel)

	HMPMODULE module = (HMPMODULE) hFile[channel];
	int numchannels = GetNumChannels(module);
	if (numchannels <= trackchannel) {
		GLog->Logf(TEXT("modplug: Channel %d does not exist in track %d."),
			trackchannel, channel);
		*(DWORD*)Result = -1;
		return;
	}

	UINT channelflags = GetChannelFlags(module, trackchannel);
    *(DWORD*)Result = SetChannelFlags(module,
		trackchannel, channelflags | flagstoset);

    unguardexec; 
} 


IMPLEMENT_FUNCTION(AModPlug,-1,execClrChannelFlags);
void 
AModPlug::execClrChannelFlags (FFrame& Stack, RESULT_DECL)
{
    guard (AhzTest::execClrChannelFlags); 
	P_GET_INT(channel)
	P_GET_INT(trackchannel)
	P_GET_INT(flagstoreset)
    P_FINISH;

	ASSERTCHANNEL(channel)
	ASSERTLOADED(hFile, channel)

	HMPMODULE module = (HMPMODULE) hFile[channel];

	int numchannels = GetNumChannels(module);
	if (numchannels <= trackchannel) {
		GLog->Logf(TEXT("modplug: Channel %d does not exist in track %d."),
			trackchannel, channel);
		*(DWORD*)Result = -1;
		return;
	}

	UINT channelflags = GetChannelFlags(module, trackchannel);
    *(DWORD*)Result = SetChannelFlags(module,
		trackchannel, channelflags & ~flagstoreset);

    unguardexec; 
} 

AModPlug::AModPlug(void)
{
	int i;

	for(i = 0; i < 32; ++i) {
		hFile[i]                      = 0;
		bPaused[i]                    = 1;
		bPendingStopNotifications[i]  = 0;
		bPendingPauseNotifications[i] = 0;
		ordernotify[i]                = -1;
		pendingChoreographyEvents[i]  = -1;
	}

	for(i = 0; i < MAX_CHAN_FADES; ++i) {
		chanfade_numchan[i] = -1;
	}

	initSound();
	globalModule = this;
}


IMPLEMENT_FUNCTION(AModPlug,-1,execSetTrackVolume);
void 
AModPlug::execSetTrackVolume (FFrame& Stack, RESULT_DECL)
{
    guard (AhzTest::execSetTrackVolume);
	P_GET_INT(channel)
	P_GET_INT(newvolume)
    P_FINISH;

	ASSERTCHANNEL(channel)
	ASSERTLOADED(hFile, channel)

	HMPMODULE module = (HMPMODULE) hFile[channel];
    *(DWORD*)Result = SetMasterVolume(module, newvolume);

    unguardexec; 
} 

IMPLEMENT_FUNCTION(AModPlug,-1,execGetTrackVolume);
void 
AModPlug::execGetTrackVolume (FFrame& Stack, RESULT_DECL)
{
    guard (AhzTest::execGetTrackVolume);
	P_GET_INT(channel)
    P_FINISH;

	ASSERTCHANNEL(channel)
	ASSERTLOADED(hFile, channel)

	HMPMODULE module = (HMPMODULE) hFile[channel];
    *(DWORD*)Result = GetMasterVolume(module);

    unguardexec; 
} 

IMPLEMENT_FUNCTION(AModPlug,-1,execLoopPattern);
void 
AModPlug::execLoopPattern (FFrame& Stack, RESULT_DECL)
{
    guard (AhzTest::execLoopPattern);
	P_GET_INT(channel)
	P_GET_INT(pattern)
    P_FINISH;

	ASSERTCHANNEL(channel)
	ASSERTLOADED(hFile, channel)

	HMPMODULE module = (HMPMODULE) hFile[channel];
	LoopPattern(module, pattern, 0);

	// return success
	*(DWORD*)Result = 1;

	unguardexec;
}
IMPLEMENT_FUNCTION(AModPlug,-1,execSetCurrentOrder);
void 
AModPlug::execSetCurrentOrder (FFrame& Stack, RESULT_DECL)
{
    guard (AhzTest::execSetCurrentOrder);
	P_GET_INT(channel)
	P_GET_INT(order)
    P_FINISH;

	ASSERTCHANNEL(channel)
	ASSERTLOADED(hFile, channel)
	
	HMPMODULE module = (HMPMODULE) hFile[channel];
	SetCurrentOrder(module, order);
	lastorder[channel] = order;

	// return success
	*(DWORD*)Result = 1;

	unguardexec;
}
IMPLEMENT_FUNCTION(AModPlug,-1,execGetCurrentOrder);
void 
AModPlug::execGetCurrentOrder (FFrame& Stack, RESULT_DECL)
{
    guard (AhzTest::execGetTrackVolume);
	P_GET_INT(channel)
    P_FINISH;

	ASSERTCHANNEL(channel)
	ASSERTLOADED(hFile, channel)

	HMPMODULE module = (HMPMODULE) hFile[channel];
	*(DWORD*)Result = GetCurrentOrder(module);

	unguardexec;
}

IMPLEMENT_FUNCTION(AModPlug,-1,execFadeToTime);
void 
AModPlug::execFadeToTime (FFrame& Stack, RESULT_DECL)
{
    guard (AhzTest::execFadeToTime);
	P_GET_INT(channel)
	P_GET_INT(destvol)
	P_GET_FLOAT(numSeconds)
    P_FINISH;

	ASSERTCHANNEL(channel)
	ASSERTLOADED(hFile, channel)

	HMPMODULE module = (HMPMODULE) hFile[channel];
	UINT currentVolume = GetMasterVolume(module);

	fade_volfrom[channel] = currentVolume;
	fade_voldiff[channel] = destvol - currentVolume;
	fade_framesbeginning[channel] = fade_framesleft[channel] = global_timing_framespersecond * numSeconds;

	// return success
	*(DWORD*)Result = 1;

	unguardexec;
}

IMPLEMENT_FUNCTION(AModPlug,-1,execGetChannelOfType);
void 
AModPlug::execGetChannelOfType (FFrame& Stack, RESULT_DECL)
{
    guard (AhzTest::execGetChannelOfType);
	P_GET_INT(channel);
	P_GET_NAME(channelName);
	P_GET_ARRAY_REF(INT, channels);
    P_FINISH;

	ASSERTCHANNEL(channel)
	ASSERTLOADED(hFile, channel)

	int i, j = 0;
	FName* chanName;

	for(i = 0; i < MAX_CHANS_PER_TRACK; ++i) {
		chanName = (FName*) channelNames[(channel * MAX_CHANS_PER_TRACK) + i];
		if (chanName && *chanName == channelName) {
			channels[j++] = i;
		}
		if (j >= MAX_CHANS_PER_TRACK)
			break;
	}
	if (j < (MAX_CHANS_PER_TRACK - 1))
		channels[j] = -1;

	*(DWORD*) Result = j;

	unguardexec;
}

DWORD AModPlug::intFadeChannelTo(LPVOID module, INT channel,
					  INT trackchannel, INT destvol,
					  FLOAT numSeconds)
{
	int i;
	int freeslot = -1;
	bool bUpdating = false;
	int chan_and_track;
	int currentVolume;

	chan_and_track = (channel << 8) | trackchannel;
	// Find a free fade slot
	for (i = 0; i < MAX_CHAN_FADES; ++i) {
		if (chanfade_numchan[i] == -1) {
			freeslot = i;
		} else if (chanfade_numchan[i] == chan_and_track) {
			// If the specified track and channel are already in a fading
			// process, use the already reserved slot and update its
			// values.
			freeslot = i;
			bUpdating = true;
			break;
		}
	}

	if (freeslot == -1) {
		GLog->Logf(TEXT("Warning: Too many fade actions at the same time!"));
		return -2;
	}


	currentVolume = GetChannelVolume(module, trackchannel);

	chanfade_numchan[freeslot] = chan_and_track;
	chanfade_volfrom[freeslot] = currentVolume;
	chanfade_voldiff[freeslot] = destvol - currentVolume;
	chanfade_framesbeginning[freeslot] = chanfade_framesleft[freeslot] = global_timing_framespersecond * numSeconds;

	SetChannelFlags(module, trackchannel,
		GetChannelFlags(module, trackchannel) & ~CHN_MUTE);

	return 0;
}

IMPLEMENT_FUNCTION(AModPlug,-1,execFadeChannelTo);
void
AModPlug::execFadeChannelTo (FFrame& Stack, RESULT_DECL)
{
	guard (AhzTest::execFadeChannelTo);
	P_GET_INT(channel);
	P_GET_INT(trackchannel);
	P_GET_INT(destvol);
	P_GET_FLOAT(numSeconds);
	P_FINISH;


	ASSERTCHANNEL(channel)
	ASSERTLOADED(hFile, channel)

	HMPMODULE module = (HMPMODULE) hFile[channel];

	int numchannels = GetNumChannels(module);
	if (numchannels <= trackchannel) {
		GLog->Logf(TEXT("modplug: Channel %d does not exist in track %d."),
			trackchannel, channel);
		*(DWORD*)Result = -1;
		return;
	}
	*(DWORD*)Result = intFadeChannelTo(module, channel,
		trackchannel, destvol, numSeconds);
	unguardexec;
}

IMPLEMENT_FUNCTION(AModPlug,-1,execFadeChannelsTo);
void
AModPlug::execFadeChannelsTo (FFrame& Stack, RESULT_DECL)
{
	guard (AhzTest::execFadeChannelsTo);
	P_GET_INT(channel);
	P_GET_NAME(trackchannelname);
	P_GET_INT(destvol);
	P_GET_FLOAT(numSeconds);
	P_FINISH;

	ASSERTCHANNEL(channel)
	ASSERTLOADED(hFile, channel)

	HMPMODULE module = (HMPMODULE) hFile[channel];

	int offset = channel * MAX_CHANS_PER_TRACK;
	int i;

	for (i = 0; i < MAX_CHANS_PER_TRACK; ++i) {
		if (channelNames[i + offset] &&
			(*(FName*)channelNames[i + offset] == trackchannelname)) {
			intFadeChannelTo(module, channel, i, destvol, numSeconds);
		}
	}

	ASSERTCHANNEL(channel)
	ASSERTLOADED(hFile, channel)

	unguardexec;

}

IMPLEMENT_FUNCTION(AModPlug,-1,execSetChannelsFlags);
void
AModPlug::execSetChannelsFlags (FFrame& Stack, RESULT_DECL)
{
	guard (AhzTest::execSetChannelsFlags);
	P_GET_INT(channel);
	P_GET_NAME(trackchannelname);
	P_GET_INT(flagstoset);
	P_FINISH;

	ASSERTCHANNEL(channel)
	ASSERTLOADED(hFile, channel)

	HMPMODULE module = (HMPMODULE) hFile[channel];

	int offset = channel * MAX_CHANS_PER_TRACK;
	int i;
	for (i = 0; i < MAX_CHANS_PER_TRACK; ++i) {
		if (channelNames[i + offset] &&
			(*(FName*)channelNames[i + offset] == trackchannelname)) {
			UINT channelflags = GetChannelFlags(module, i);
			SetChannelFlags(module,
				i, channelflags | flagstoset);
		}
	}

	unguardexec;
}

IMPLEMENT_FUNCTION(AModPlug,-1,execClrChannelsFlags);
void
AModPlug::execClrChannelsFlags (FFrame& Stack, RESULT_DECL)
{
	guard (AhzTest::execClrChannelsFlags);
	P_GET_INT(channel);
	P_GET_NAME(trackchannelname);
	P_GET_INT(flagstoreset);
	P_FINISH;

	ASSERTCHANNEL(channel)
	ASSERTLOADED(hFile, channel)

	HMPMODULE module = (HMPMODULE) hFile[channel];

	int offset = channel * MAX_CHANS_PER_TRACK;
	int i;

	for (i = 0; i < MAX_CHANS_PER_TRACK; ++i) {
		if (channelNames[i + offset] &&
			(*(FName*)channelNames[i + offset] == trackchannelname)) {
			UINT channelflags = GetChannelFlags(module, i);
			SetChannelFlags(module,
				i, channelflags & ~flagstoreset);
		}
	}

	unguardexec;
}


IMPLEMENT_FUNCTION(AModPlug,-1,execSetChannelsVolume);
void
AModPlug::execSetChannelsVolume (FFrame& Stack, RESULT_DECL)
{
	guard (AhzTest::execSetChannelsVolume);
	P_GET_INT(channel);
	P_GET_NAME(trackchannelname);
	P_GET_INT(newvolume);
	P_FINISH;

	ASSERTCHANNEL(channel)
	ASSERTLOADED(hFile, channel)

	HMPMODULE module = (HMPMODULE) hFile[channel];

	int offset = channel * MAX_CHANS_PER_TRACK;
	int i;
	for (i = 0; i < MAX_CHANS_PER_TRACK; ++i) {
		if (channelNames[i + offset] &&
			(*(FName*)channelNames[i + offset] == trackchannelname)) {
			SetChannelVolume(module, i, newvolume);
			if (newvolume == 0) {
				SetChannelFlags(module, i,
					GetChannelFlags(module, i) | CHN_MUTE);
			} else {
				SetChannelFlags(module, i,
					GetChannelFlags(module, i) & ~CHN_MUTE);
			}
		}
	}

	unguardexec;
}

IMPLEMENT_FUNCTION(AModPlug,-1,execEnableChannelsEffect);
void
AModPlug::execEnableChannelsEffect (FFrame& Stack, RESULT_DECL)
{
	guard (AhzTest::execEnableChannelsEffect);
	P_GET_INT(channel);
	P_GET_NAME(trackchannelname);
	P_GET_INT(effect);
	P_GET_INT(effectparam);
	P_FINISH;

	ASSERTCHANNEL(channel)
	ASSERTLOADED(hFile, channel)

	HMPMODULE module = (HMPMODULE) hFile[channel];

	int offset = channel * MAX_CHANS_PER_TRACK;
	int i;
	for (i = 0; i < MAX_CHANS_PER_TRACK; ++i) {
		if (channelNames[i + offset] &&
			(*(FName*)channelNames[i + offset] == trackchannelname)) {
			EnableChannelEffect(module, i, effect, effectparam);
		}
	}

	unguardexec;
}


IMPLEMENT_FUNCTION(AModPlug,-1,execDisableChannelsEffect);
void
AModPlug::execDisableChannelsEffect (FFrame& Stack, RESULT_DECL)
{
	guard (AhzTest::execDisableChannelsEffect);
	P_GET_INT(channel);
	P_GET_NAME(trackchannelname);
	P_GET_INT(effect);
	P_FINISH;

	ASSERTCHANNEL(channel)
	ASSERTLOADED(hFile, channel)

	HMPMODULE module = (HMPMODULE) hFile[channel];

	int offset = channel * MAX_CHANS_PER_TRACK;
	int i;
	for (i = 0; i < MAX_CHANS_PER_TRACK; ++i) {
		if (channelNames[i + offset] &&
			(*(FName*)channelNames[i + offset] == trackchannelname)) {
			DisableChannelEffect(module, i, effect);
		}
	}

	unguardexec;
}

IMPLEMENT_FUNCTION(AModPlug,-1,execSetChannelsTranspose);
void
AModPlug::execSetChannelsTranspose (FFrame& Stack, RESULT_DECL)
{
	guard (AhzTest::execSetChannelsTranspose);
	P_GET_INT(channel);
	P_GET_NAME(trackchannelname);
	P_GET_INT(transposeby);
	P_FINISH;

	ASSERTCHANNEL(channel)
	ASSERTLOADED(hFile, channel)

	HMPMODULE module = (HMPMODULE) hFile[channel];

	int offset = channel * MAX_CHANS_PER_TRACK;
	int i;
	for (i = 0; i < MAX_CHANS_PER_TRACK; ++i) {
		if (channelNames[i + offset] &&
			(*(FName*)channelNames[i + offset] == trackchannelname)) {
			SetTransposeValue(module, i, transposeby);
		}
	}

	unguardexec;
}


IMPLEMENT_FUNCTION(AModPlug,-1,execEnableInstrumentOverride);
void
AModPlug::execEnableInstrumentOverride (FFrame& Stack, RESULT_DECL)
{
	guard (AhzTest::execEnableInstrumentOverride);
	P_GET_INT(channel);
	P_GET_NAME(trackchannelname);
	P_GET_ARRAY_REF(byte, overrides);
	P_FINISH;

	ASSERTCHANNEL(channel)
	ASSERTLOADED(hFile, channel)

	HMPMODULE module = (HMPMODULE) hFile[channel];

	int offset = channel * MAX_CHANS_PER_TRACK;
	int i;
	for (i = 0; i < MAX_CHANS_PER_TRACK; ++i) {
		if (channelNames[i + offset] &&
			(*(FName*)channelNames[i + offset] == trackchannelname)) {
			SetSwapInstruments(module, i, overrides);
		}
	}

	unguardexec;
}

IMPLEMENT_FUNCTION(AModPlug,-1,execClearInstrumentOverride);
void
AModPlug::execClearInstrumentOverride (FFrame& Stack, RESULT_DECL)
{
	guard (AhzTest::execClearInstrumentOverride);
	P_GET_INT(channel);
	P_GET_NAME(trackchannelname);
	P_FINISH;

	ASSERTCHANNEL(channel)
	ASSERTLOADED(hFile, channel)

	HMPMODULE module = (HMPMODULE) hFile[channel];

	int offset = channel * MAX_CHANS_PER_TRACK;
	int i;
	for (i = 0; i < MAX_CHANS_PER_TRACK; ++i) {
		if (channelNames[i + offset] &&
			(*(FName*)channelNames[i + offset] == trackchannelname)) {
			ClrSwapInstruments(module, i);
		}
	}

	unguardexec;
}


IMPLEMENT_FUNCTION(AModPlug,-1,execSetMegaBass);
void
AModPlug::execSetMegaBass (FFrame& Stack, RESULT_DECL)
{
	guard (AhzTest::execSetMegaBass);
	P_GET_INT(basson);
	P_FINISH;

	SetMegaBass(NULL, basson);

	unguardexec;
}



void 
AModPlug::Destroy(void)
{
	int i;
	// SDL_CloseAudio();

	if (globalModule == this)
		globalModule = NULL;

	for (i = 0; i < 32; i++) {
		HMPMODULE mod = (HMPMODULE) hFile[i];
		if (mod != NULL) {
			CloseModFile(&mod);
			hFile[i] = 0;
		}
	}

	for (i = 0; i < MAX_CHANS_PER_TRACK * 32; ++i) {
		FName* chanName = (FName*) channelNames[i];
		if (chanName != NULL)
			delete chanName;
	}

	GLog->Logf(TEXT("Audio files closed."));

	Super::Destroy();
}

UBOOL AModPlug::Tick(FLOAT fTime, ELevelTick TickType)
{
    UBOOL ret;

    ret = Super::Tick(fTime, TickType);

	for (int i = 0; i < 32; ++i) {
		if (bPendingStopNotifications[i]) {
			eventTrackStopped(i);
			bPendingStopNotifications[i] = 0;
		}
		if (bPendingPauseNotifications[i]) {
			eventTrackPaused(i);
			bPendingPauseNotifications[i] = 0;
		}
		if (ordernotify[i] != -1) {
			eventOrderChanged(i, ordernotify[i]);
			ordernotify[i] = -1;
		}
		if (pendingChoreographyEvents[i] != -1) {
			eventChoreographyEvent(i, pendingChoreographyEvents[i]);
			pendingChoreographyEvents[i] = -1;
		}
	}

	return ret;
}

