#include <FileConstants.au3>
#include <WinAPIProc.au3>
#include <Timers.au3>

Global $activeTitle = ""

Global $csvPath   = Null
Global $csvHandle = Null

Func LoadSettings()

	Local $iniPath = "./settings.ini"

	Local $iniDefaultsCsvDir      = @UserProfileDir & "\Time Log"
	Local $iniDefaultsIdleTimeout = 1000 * 60
	Local $iniDefaultsFrequency   = 1000 * 1

	If Not FileExists( $iniPath ) Then
		IniWrite( $iniPath, "settings", "csv_dir", $iniDefaultsCsvDir )
		IniWrite( $iniPath, "settings", "idle_timeout", $iniDefaultsIdleTimeout )
		IniWrite( $iniPath, "settings", "frequency", $iniDefaultsFrequency )
	EndIf

	Global $csvDir      = IniRead( $iniPath, "settings", "csv_dir", $iniDefaultsCsvDir )
	Global $idleTimeout = IniRead( $iniPath, "settings", "idle_timeout", $iniDefaultsIdleTimeout )
	Global $frequency   = IniRead( $iniPath, "settings", "frequency", $iniDefaultsFrequency )

EndFunc

Func GetFormattedTime()
	Return StringFormat( "%s-%s-%s %s:%s:%s", @YEAR, @MON, @MDAY, @HOUR, @MIN, @SEC )
EndFunc

Func OpenCsvFile()
	$csvHandle = FileOpen( $csvPath, $FO_APPEND + $FO_CREATEPATH + $FO_UTF8 )
EndFunc

Func QuoteCsv( $string )
	Return '"' & StringReplace( $string, '"', '""' ) & '"'
EndFunc

Func UpdateCsv( $cells )

	Local $newPath = StringFormat( "%s\%s-%s-%s.csv", $csvDir, @YEAR, @MON, @MDAY )

	If $csvPath = Null Then
		$csvPath = $newPath
	ElseIf $csvPath <> $newPath And $csvHandle <> Null Then
		FileClose( $csvHandle )
		$csvHandle = Null
		$csvPath = $newPath
	EndIf

	If $csvHandle = Null Then
		OpenCsvFile()
		If $csvHandle = -1 Then
			ConsoleWriteError( "Failed to open file" )
		EndIf
	EndIf

	Local $line = StringFormat( '"%s",%s', GetFormattedTime(), $cells )

	FileWrite( $csvHandle, $line & @LF )
EndFunc

LoadSettings()

While 1

	Local $processPath = _WinAPI_GetProcessFileName( WinGetProcess( "[ACTIVE]" ) )
	Local $windowTitle = WinGetTitle( "[ACTIVE]" )

	Local $newTitle = StringFormat( "%s,%s", QuoteCsv( $processPath ), QuoteCsv( $windowTitle ) )

	If $activeTitle <> $newTitle Then
		$activeTitle = $newTitle
		UpdateCsv( StringFormat( '"Active",%s', $newTitle ) )
	EndIf

	If _Timer_GetIdleTime() > $idleTimeout Then

	$activeTitle = ""

	UpdateCsv( '"Idle","",""' )

	While _Timer_GetIdleTime() > $idleTimeout
		Sleep( $frequency )
	Wend

	EndIf

	Sleep( $frequency )

WEnd
