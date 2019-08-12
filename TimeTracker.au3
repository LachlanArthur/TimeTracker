#include <FileConstants.au3>
#include <WinAPIProc.au3>
#include <Timers.au3>

Global $activeTitle = ""
Global $idleTimeout = 1000 * 60
Global $frequency   = 1000 * 1

Local $iniPath = "./settings.ini"
Local $iniDefaultsCsvDir = @UserProfileDir & "\Time Log"
If Not FileExists( $iniPath ) Then
	IniWrite( $iniPath, "settings", "csv_dir", $iniDefaultsCsvDir )
EndIf

Global $csvDir    = IniRead( $iniPath, "settings", "csv_dir", $iniDefaultsCsvDir )
Global $csvPath   = Null
Global $csvHandle = Null

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

While 1

	Local $processPath = _WinAPI_GetProcessFileName( WinGetProcess( "[ACTIVE]" ) )
	Local $windowTitle = WinGetTitle( "[ACTIVE]" )

	Local $newTitle = StringFormat(
		"%s,%s",
		QuoteCsv( $processPath ),
		QuoteCsv( $windowTitle )
	)

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
