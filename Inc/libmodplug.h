// The following ifdef block is the standard way of creating macros which make exporting 
// from a DLL simpler. All files within this DLL are compiled with the LIBMODPLUG_EXPORTS
// symbol defined on the command line. This symbol should not be defined on any project
// that uses this DLL. This way any other project whose source files include this file see 
// LIBMODPLUG_API functions as being imported from a DLL, whereas this DLL sees symbols
// defined with this macro as being exported.
#ifdef LIBMODPLUG_EXPORTS
#define LIBMODPLUG_API __declspec(dllexport)
#else
#define LIBMODPLUG_API __declspec(dllimport)
#endif

typedef LPVOID HMPMODULE;
typedef LPCVOID HCMPMODULE;

// This class is exported from the libmodplug.dll
class LIBMODPLUG_API Clibmodplug {
public:
	Clibmodplug(void);
	// TODO: add your methods here.
};

// Channel flags:
// Bits 0-7:	Sample Flags
#define CHN_16BIT               0x01
#define CHN_LOOP                0x02
#define CHN_PINGPONGLOOP        0x04
#define CHN_SUSTAINLOOP         0x08
#define CHN_PINGPONGSUSTAIN     0x10
#define CHN_PANNING             0x20
#define CHN_STEREO              0x40
#define CHN_PINGPONGFLAG	0x80
// Bits 8-31:	Channel Flags
#define CHN_MUTE                0x100
#define CHN_KEYOFF              0x200
#define CHN_NOTEFADE		0x400
#define CHN_SURROUND            0x800
#define CHN_NOIDO               0x1000
#define CHN_HQSRC               0x2000
#define CHN_FILTER              0x4000
#define CHN_VOLUMERAMP		0x8000
#define CHN_VIBRATO             0x10000
#define CHN_TREMOLO             0x20000
#define CHN_PANBRELLO		0x40000
#define CHN_PORTAMENTO		0x80000
#define CHN_GLISSANDO		0x100000
#define CHN_VOLENV              0x200000
#define CHN_PANENV              0x400000
#define CHN_PITCHENV		0x800000
#define CHN_FASTVOLRAMP		0x1000000
#define CHN_EXTRALOUD		0x2000000
#define CHN_REVERB              0x4000000
#define CHN_NOREVERB		0x8000000

extern LIBMODPLUG_API int nlibmodplug;

LIBMODPLUG_API int fnlibmodplug(void);

LIBMODPLUG_API HMPMODULE OpenModFile(LPCSTR fileName);
LIBMODPLUG_API HMPMODULE OpenModFile(HANDLE hFile);
LIBMODPLUG_API HMPMODULE OpenModBuffer(LPVOID buf, DWORD len);
LIBMODPLUG_API UINT ReadModFile(HCMPMODULE soundfile,
	LPVOID buffer, UINT bufsize);
LIBMODPLUG_API void CloseModFile(HMPMODULE *soundfile);
LIBMODPLUG_API UINT ReadModFile(HCMPMODULE soundfile,
	LPVOID buffer, UINT bufsize);
LIBMODPLUG_API LONG SetChannelVolume(HCMPMODULE module,
	UINT channel, LONG volume);
LIBMODPLUG_API LONG GetChannelVolume(HCMPMODULE module,  UINT channel);
LIBMODPLUG_API UINT GetNumChannels(HCMPMODULE module);
LIBMODPLUG_API UINT GetPosition(HCMPMODULE module);
LIBMODPLUG_API UINT GetCurrentPattern(HCMPMODULE module);
LIBMODPLUG_API UINT GetCurrentOrder(HCMPMODULE module);
LIBMODPLUG_API UINT SetPosition(HCMPMODULE module, UINT position);
LIBMODPLUG_API UINT GetChannelFlags(HCMPMODULE module, UINT channel);
LIBMODPLUG_API UINT SetChannelFlags(HCMPMODULE module,
	UINT channel, UINT flags);
LIBMODPLUG_API DWORD GetModuleFrequency(HCMPMODULE module);
LIBMODPLUG_API DWORD GetBitsPerSample(HCMPMODULE module);
LIBMODPLUG_API LPCSTR GetModuleTitle(HCMPMODULE module);
LIBMODPLUG_API UINT GetMasterVolume(HCMPMODULE module);
LIBMODPLUG_API UINT SetMasterVolume(HCMPMODULE module, UINT volume);
LIBMODPLUG_API void LoopPattern(HCMPMODULE soundfile, int pattern, int row);
LIBMODPLUG_API void SetCurrentOrder(HCMPMODULE module, UINT order);
LIBMODPLUG_API void SetChoreographyCallback(HCMPMODULE module,
	void (*callbackRoutine)(void *userdata, int choreographyEventNum),
	void* userdata);
LIBMODPLUG_API void (*GetChoreographyCallback(HCMPMODULE module))
	(void *userdata, int choreographyEventNum);
LIBMODPLUG_API UINT GetChannelNames(HCMPMODULE module,
	const char** channelnames, UINT maxChannels);
LIBMODPLUG_API UINT EnableChannelEffect(HCMPMODULE module,
	UINT channel, BYTE command, BYTE parameter);
LIBMODPLUG_API UINT DisableChannelEffect(HCMPMODULE module,
	UINT channel, BYTE command);
LIBMODPLUG_API UINT SetTransposeValue(HCMPMODULE module,
	UINT channel, signed short transposeBY);
LIBMODPLUG_API UINT SetSwapInstruments(HCMPMODULE module,
	UINT channel, BYTE its[MAX_INSTRUMENTS]);
LIBMODPLUG_API UINT ClrSwapInstruments(HCMPMODULE module, UINT channel);
LIBMODPLUG_API UINT SetMegaBass(int frequency, BOOLEAN enable);