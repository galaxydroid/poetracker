#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
current_version := "0.0.2"
poe_folder := ""
report_hotkey := ""
poe_tracker_url := "https://poetracker.com"
zone_type:=0
Menu,tray, add, Settings,open_settings

LastLines(varFilename,varLines=1) {
	linecount:=0
	file:=FileOpen(varFilename, "r")
	if (not file)
		return 0
	Loop {
		file.Seek(0-A_Index, 2)
		line:=file.Read(1)
		if ((RegExMatch(line,"`n") or RegExMatch(line,"`r")) and not File.AtEOF)
			linecount++
	} until ((RegExMatch(line,"`n") or RegExMatch(line,"`r")) and not File.AtEOF and linecount=varLines)
	Loop {
		output.=file.Readline()
	} until (File.AtEOF)
	file.Close()
	return output
}

PT_LoadSettings() {
	global poe_folder, report_hotkey
	IniRead, poe_folder, %A_ScriptDir%\settings.ini, general, poe_folder
	IniRead, report_hotkey, %A_ScriptDir%\settings.ini, general, report_hotkey
	
	if StrLen(poe_folder) > 0 and StrLen(report_hotkey) > 0
		return True
	else
		return False
}


if PT_LoadSettings() {
	global report_hotkey
	Hotkey, %report_hotkey%,report, On
	return
}
else {
	GoTo open_settings
}

PT_Get_Location(){ 
	global t
	if not FileExist(poe_folder . "\logs\Client.txt")
		PT_Show_Tooltip("Unable to read chat logs. Make sure you have right poe path in settings.")

	l := LastLines(poe_folder . "\logs\Client.txt", 100)

	Loop, Parse, l, `n
	{
		if RegExMatch(A_LoopField, "You have entered (.*)\.") {
			RegExMatch(A_LoopField, "You have entered (.*)\.", sub_pattern)
		}
	  		
	}
	
	return sub_pattern1
}

PT_Is_Valid_Location(location) {
  if (StrLen(location) = 0) {
    return False
  }
	if (RegExMatch(location, "i)hideout|lioneye's watch|the forest encampment|the sarn encampment|highgate|overseer's tower|the bridge encampment|oriath docks|^oriath$")) {
		return False
	}

	return True
}

PT_Draw_GUI(current_location) {
	Gui,Font, s12, Arial
	Gui, Color, White, Blue

	Gui, Add, Text,x5 y5,Your zone: %current_location%
	Gui, Add, Text,x5 y25,If you are not mapping, please select which part:
	Gui, Add, Radio,x5 y55 h30 w75 gCheck1, Part1
	Gui, Add, Radio,x80 y55 h30 w75 gCheck2, Part2
	Gui, Add, Radio,x155 y55 h30 w75 Checked gCheck3 , Maps
	Gui, Add, Button,x5 y90 h30 w110 gbreaches,Breaches	
	Gui, Add, Button,x125 y90	h30 w110 grogues,Rogue Exiles
	Gui, Add, Button,x245 y90 h30 w110 gharbringers,Harbringers
	
	Gui, Add, Button,x5 y125 h30 w110 ginvasion,Invasion
	Gui, Add, Button,x125 y125 h30 w110 gstrongboxes,Strongboxes
	Gui, Add, Button,x245 y125 h30 w110 gspirits,Spirits

	Gui, Show,, PoE Mayhem Tracker - poetracker.com
	
	return
}

Check1:
global zone_type
zone_type = 1
Return
Check2:
global zone_type
zone_type = 2
Return
Check3:
global zone_type
zone_type = 4
Return

PT_Is_Ambiguous_Location(location) {

}

PT_Show_Tooltip(text) {
	Global X, Y
	
	; Get position of mouse cursor
	MouseGetPos, X, Y
	WinGet, PoEWindowHwnd, ID, ahk_group PoEWindowGrp
	RelativeToActiveWindow := true	; default tooltip behaviour 	

	ScreenOffsetY := A_ScreenHeight / 2
	ScreenOffsetX := A_ScreenWidth / 2
	
	XCoord := 0 + ScreenOffsetX
	YCoord := 0 + ScreenOffsetY

		
	Fonts.SetFixedFont()
	ToolTip, %text%, XCoord, YCoord

	

	ToolTipTimeout := 0
	SetTimer, ToolTipTimer, 100
}

PT_Send_Results(location, mod) {
	global poe_tracker_url, zone_type
	url := poe_tracker_url . "/reports?location=" . location . "&mod=" . mod . "&type=" . zone_type . ""
	WinHTTP := ComObjCreate("WinHTTP.WinHttpRequest.5.1")
	WinHTTP.Open("POST", url, False)
	WinHTTP.SetRequestHeader("Content-Type", "application/json")
;	Body := "{""location"": """ . location . """, ""mod"": """ . mod . """}"	
	json_str := ({"location": "testlocation"})
	Body := json_str
	WinHTTP.Send(Body)
	return
}

report:
	current_location := PT_Get_Location()
	if PT_Is_Valid_Location(current_location) {
		PT_Draw_GUI(current_location)	
	} else {
		PT_Show_Tooltip(current_location . " is not a valid location.")
	}
		
	
	return
	
breaches:
	PT_Send_Results(current_location, "breaches")
	Gui Destroy
	return

spirits:
	PT_Send_Results(current_location, "spirits")
	Gui Destroy
	return

rogues:
	PT_Send_Results(current_location, "rogues")
	Gui Destroy
	return
	
harbringers:
	PT_Send_Results(current_location, "harbringers")
	Gui Destroy
	return

invasion:
	PT_Send_Results(current_location, "invasion")
	Gui Destroy
	return

strongboxes:
	PT_Send_Results(current_location, "strongboxes")
	Gui Destroy
	return


GuiClose:
GuiEscape:
	Gui Destroy
	return

open_settings:
	global report_hotkey, poe_folder

	Gui,Font, s10, Arial
	Gui, Add, Text,,Path to the Path of Exile
	Gui, Add, Edit, vFolder
	Gui, Add, Button, gbrowse,Browse
	Gui, Add, Text,, Hotkey for report
	Gui, Add, Hotkey, vHK gLabel
	Gui, Add, Button, gsave,Save
	Gui, Show,, Settings

	GuiControl,, Folder, %poe_folder%
	GuiControl,, HK, %report_hotkey%
	Folder := poe_folder
	HK := report_hotkey
	
	return	

label: 
	global report_hotkey
	If HK in +,^,!,+^,+!,^!,+^!
	  return
	 If (report_hotkey) {
	  Hotkey, %report_hotkey%,report, Off
	  report_hotkey .= " OFF"
	 }
	 If (HK = "") {
	  report_hotkey =                            
	  return
	 }
	 Gui, Submit, NoHide
	 
	 If StrLen(HK) = 1
	  HK := "~" HK
	 Hotkey, %HK%,report, On
	 report_hotkey := HK
	return
	
browse:
	FileSelectFolder, Folder
	GuiControl,, Folder, %Folder%
	; Folder := RegExReplace(Folder, "\\$")
	; FolderPath := Folder
	return

save:
	IniWrite, %HK%, %A_ScriptDir%\settings.ini, general, report_hotkey
	IniWrite, %Folder%, %A_ScriptDir%\settings.ini, general, poe_folder
	poe_folder := Folder
	Gui Destroy
	return

ToolTipTimer:
	MouseGetPos, CurrX, CurrY
	MouseMoved := (CurrX - X) ** 2 + (CurrY - Y) ** 2 > 25 ** 2
	If (MouseMoved)
	{
		ToolTip
	}
	return
