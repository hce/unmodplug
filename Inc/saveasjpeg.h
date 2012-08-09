// The following ifdef block is the standard way of creating macros which make exporting 
// from a DLL simpler. All files within this DLL are compiled with the SAVEASJPEG_EXPORTS
// symbol defined on the command line. This symbol should not be defined on any project
// that uses this DLL. This way any other project whose source files include this file see 
// SAVEASJPEG_API functions as being imported from a DLL, whereas this DLL sees symbols
// defined with this macro as being exported.
#ifdef SAVEASJPEG_EXPORTS
#define SAVEASJPEG_API __declspec(dllexport)
#else
#define SAVEASJPEG_API __declspec(dllimport)
#endif

SAVEASJPEG_API HGLOBAL fnsaveasjpeg(HDC hdc, HBITMAP hbmp,
	unsigned char** outbuffer, unsigned long* outsize);