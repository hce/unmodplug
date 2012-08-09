// stdafx.h : Include-Datei für Standard-System-Include-Dateien,
//  oder projektspezifische Include-Dateien, die häufig benutzt, aber
//      in unregelmäßigen Abständen geändert werden.
//

#if !defined(AFX_STDAFX_H__C00771B1_4087_40CA_A3BC_9DF6D8F52126__INCLUDED_)
#define AFX_STDAFX_H__C00771B1_4087_40CA_A3BC_9DF6D8F52126__INCLUDED_

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000

// Fügen Sie hier Ihre Header-Dateien ein
//#define WIN32_LEAN_AND_MEAN		// Selten benutzte Teile der Windows-Header nicht einbinden

#include <windows.h>

// HACK
#define MAX_INSTRUMENTS 128

// ZU ERLEDIGEN: Verweisen Sie hier auf zusätzliche Header-Dateien, die Ihr Programm benötigt
#include "Inc/Engine.h"
#include "Inc/Core.h"
#include "Inc/ModPlugClasses.h"

#include "Inc/SDL.h"
#include "Inc/libmodplug.h"

#include "Inc/IPDrvPrivate.h"

#include "Inc/saveasjpeg.h"

#define AUDIO_BUFFER_SIZE 4096

// Maximum number of channel fadings occurring
// in parallel
// MUST BE AT LEAST THE SIZE OF MAX_CHANS_PER_TRACK or some functions will fail!!
#define MAX_CHAN_FADES 64

// Maximum number of tracks supported per
// channel
#define MAX_CHANS_PER_TRACK 64


//{{AFX_INSERT_LOCATION}}
// Microsoft Visual C++ fügt zusätzliche Deklarationen unmittelbar vor der vorherigen Zeile ein.

#endif // !defined(AFX_STDAFX_H__C00771B1_4087_40CA_A3BC_9DF6D8F52126__INCLUDED_)
