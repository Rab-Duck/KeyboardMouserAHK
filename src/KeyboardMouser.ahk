;
; Keyboard Mouser -- by Rab-Duck rabduck.software@gmail.com
;
; this script is a keyboard-mouse utility
; a key is mapped to a piece of the display, to which you can move the mouse cursor.
; and 4 direction(up,down,left,right) cursor move and cliks by Keyboard are supported.
;
; this script is based on Mouser, On-Screen Keyboard, MouseMove++, WindowPad
;   - Mouser https://github.com/theborg3of5/ahk/blob/master/Mouser.ahk
;   - On-Screen Keyboard http://www.autohotkey.com/docs/scripts/KeyboardOnScreen.ahk
;   - MouseMove+ http://ux.getuploader.com/autohotkeyl/download/19/MouseMove%2B.ahk
;   - WindowPad http://www.autohotkey.com/board/topic/19990-windowpad-window-moving-tool/
;

#NoEnv
#InstallKeybdHook
#SingleInstance force

; #SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

SetWinDelay,0 
SetMouseDelay, 0
SetDefaultMouseSpeed, 0 ; Move the mouse cursor instantly


;
; --------------< Initial Section >--------------
;

; Initialize read inifile, setting init-values...more
Gosub,KmInit

; Make the TrayMenu
Gosub,KmTrayMenu

; HOTkey Setting
HotKey,%km_MainHotKey%,KmStart

; End of the Initial Loading Process
Return


;
; --------------< Main Section >--------------
;

; HotKey Call This
; Show the main window and start to capture user inputs
KmStart:

; Get a current monitor 
CoordMode,Mouse,Screen
MouseGetPos,km_MousePos_X,km_MousePos_Y
CoordMode,Mouse,Relative
km_MonitorNum := KmGetMonitorAt(km_MousePos_X, km_MousePos_Y)

GoSub,KmSetWindowPos

;Create a Main KB Window
GoSub, KmCreateWindow

GoSub,RecoverDragState

; uncomment, if you want to center a mouse cursor at first
;GoSub,KmMoveMouseCursorToCenter

; Capture User Input
Loop
{
	;Check the Input key
	; vkE2(backslash) is for resucue to input a backslash-key
	; (the ErrorLevel of vkE2 is EndKey:\(\=Yen))
	Input, km_UserInput, L1,{vkE2}{Esc}{Enter}{TAB}{SPACE}{Up}{Down}{Left}{Right}{%km_ClickLeft%}{%km_Mouse_up%}{%km_Mouse_left%}{%km_Mouse_down%}{%km_Mouse_right%}{%km_ClickLeft%}{%km_ClickRight%}{%km_ClickMiddle%}{%km_ClickDouble%},%km_KBLineMatchList%
	
	IfInString, ErrorLevel, EndKey:
	{
        ; for debug
        ; MsgBox, ErrorLevel=%ErrorLevel%
    }
	if (ErrorLevel = "Match" and !km_DragMode)
	{
		IfInString km_KBLineAll, %km_UserInput%
		{
			ControlClick, %km_UserInput%, ahk_id %km_ID%
		}
		else{
			; for the rescue
			break
		}
	}
	else IfInString ErrorLevel, EndKey:
	{
        StringReplace, km_UserInput, ErrorLevel, EndKey:
    	If( km_UserInput = "Escape" )
    	{
    		; Cancel this loop
    		break
    	}
		else If(InStr(km_Mouse_up . km_Mouse_down . km_Mouse_left . km_Mouse_right, km_UserInput) > 0
		        or km_UserInput = "Up" or km_UserInput = "Down"
    	        or km_UserInput = "Left" or km_UserInput = "Right")
		{
    		if(km_DragMode or !GetKeyState("Alt", "P")){
    		    KmMoveMouseCursor(km_UserInput)
            }
            else
            {
                ; Move to the Next/Before Display
            	GUI,Destroy
            	if(km_UserInput = km_Mouse_down or km_UserInput = km_Mouse_left 
            	    or km_UserInput = "Left" or km_UserInput = "Down"){
            	    KmMoveNextDisplay(-1)
            	}else{
                    KmMoveNextDisplay(1)
                }
            	
            	GoSub,KmSetWindowPos
            	GoSub,KmCreateWindow
            	GoSub,KmMoveMouseCursorToCenter
            }

    	}
        else if(InStr(km_ClickLeft . km_ClickRight . km_ClickMiddle . km_ClickDouble, km_UserInput) > 0
                or km_UserInput = "Enter")
		{
			KmClickMouse(km_UserInput)
			if(!km_DragMode){
                break
            }
    	}
    	else IfInString, km_UserInput, Tab
    	{
            if(EmulateTabKeyInput()){
                break
            }
    	}
	    else if (km_DragMode)
	    {
            Continue
        }
    	else IfInString, km_UserInput, Space
    	{
    		; push the focused button
    		ControlGetFocus, km_FocusedCtrl, ahk_id %km_ID%
    		ControlClick, %km_FocusedCtrl%, ahk_id %km_ID%
    	}
    }
}
;----
GoSub, RecoverDragState
GUI, Destroy

Return


;
; --------------< Sub/Function Section >--------------
;

; Initialize process (r/w inifile, set parameters and so on)
KmInit:

    ; Program Default Setting
	km_MainHotKey = ^+m

	km_KBLine1 = 1234
	km_KBLine2 = qwer
	km_KBLine3 = asdf
	km_KBLine4 = zxcv
	km_MaxKBDepth := 2  ; max reflexive count of the Keyboard-Display mapping
	km_StartFontSize = 40

	km_Mouse_up = k
	km_Mouse_down = j
	km_Mouse_left = h
	km_Mouse_right = l
	km_MouseMoveUnit = 1
	km_MouseMoveInterval = 10
    km_MouseMoveAccelerate = 10

	km_ClickLeft = u
	km_ClickRight = o
	km_ClickMiddle = i
	km_ClickDouble = y

	km_Transparency = 150

	IfNotExist,KeyboardMouser.ini 
	{
        ; IfNotExist inifile, make it.
		GoSub, KmWriteInifile
	}

    ; read settings from inifile
	IniRead,km_MainHotKey,KeyboardMouser.ini,Settings,hotkey

	IniRead,km_KBLine1,KeyboardMouser.ini,Settings,KBLine1
	IniRead,km_KBLine2,KeyboardMouser.ini,Settings,KBLine2
	IniRead,km_KBLine3,KeyboardMouser.ini,Settings,KBLine3
	IniRead,km_KBLine4,KeyboardMouser.ini,Settings,KBLine4

	IniRead,km_MaxKBDepth,KeyboardMouser.ini,Settings,MaxKBDepth
	IniRead,km_StartFontSize,KeyboardMouser.ini,Settings,StartFontSize
	
	IniRead,km_Mouse_up,KeyboardMouser.ini,Settings,mousekeyup
	IniRead,km_Mouse_left,KeyboardMouser.ini,Settings,mousekeyleft
	IniRead,km_Mouse_right,KeyboardMouser.ini,Settings,mousekeyright
	IniRead,km_Mouse_down,KeyboardMouser.ini,Settings,mousekeydown

	IniRead,km_MouseMoveUnit,KeyboardMouser.ini,Settings,MouseMoveUnit
	IniRead,km_MouseMoveInterval,KeyboardMouser.ini,Settings,MouseMoveInterval
	IniRead,km_MouseMoveAccelerate,KeyboardMouser.ini,Settings,MouseAccelerate

	IniRead,km_ClickLeft,KeyboardMouser.ini,Settings,leftclick
	IniRead,km_ClickRight,KeyboardMouser.ini,Settings,rightclick
	IniRead,km_ClickDouble,KeyboardMouser.ini,Settings,doubleclick
	IniRead,km_ClickMiddle,KeyboardMouser.ini,Settings,middleclick

	IniRead,km_Transparency,KeyboardMouser.ini,Settings,transparency

    ; join all key-strings
	km_KBLineAll := km_KBLine1 . km_KBLine2 . km_KBLine3 . km_KBLine4

    ; Make "," separated string for Input MatchList
	Loop, 4
	{
		; get keys, contained by each line
		StringSplit,km_SplitWork,km_KBLine%A_Index%
		km_KBLine%A_Index%Size = %km_SplitWork0%
		if(km_KBLine%A_Index%Size > 0)
		{
			km_KBLineNumber += 1
		}
		Loop, %km_SplitWork0%
		{
			if( km_SplitWork%A_Index% = ",")
			{
                ; for cover "," 
				km_KBLineMatchList := ",,," . km_KBLineMatchList
			}
			else
			{
				km_KBLineMatchList .= km_SplitWork%A_Index%
				km_KBLineMatchList .= ","
			}
		}
		; MsgBox,  km_KBLine%A_Index% , km_KBLine%A_Index%Size, %km_SplitWork0%
	}
	StringTrimRight, km_KBLineMatchList, km_KBLineMatchList, 1
	; MsgBox, km_KBLineNumber=%km_KBLineNumber% / km_KBLineAll=%km_KBLineAll%, km_KBLineMatchList=%km_KBLineMatchList%
	

	km_FontName = ; This can be blank to use the system's default font.
	km_FontStyle = Bold    ; Example of an alternative: Italic Underline

    km_DragMode := False
    km_DragButton := ""

Return

; write ini file
KmWriteInifile:
	IniWrite,%km_MainHotKey%,KeyboardMouser.ini,Settings,hotkey
	IniWrite,%km_KBLine1%,KeyboardMouser.ini,Settings,KBLine1
	IniWrite,%km_KBLine2%,KeyboardMouser.ini,Settings,KBLine2
	IniWrite,%km_KBLine3%,KeyboardMouser.ini,Settings,KBLine3
	IniWrite,%km_KBLine4%,KeyboardMouser.ini,Settings,KBLine4
	IniWrite,%km_MaxKBDepth%,KeyboardMouser.ini,Settings,MaxKBDepth
	IniWrite,%km_StartFontSize%,KeyboardMouser.ini,Settings,StartFontSize
	IniWrite,%km_Mouse_up%,KeyboardMouser.ini,Settings,mousekeyup
	IniWrite,%km_Mouse_down%,KeyboardMouser.ini,Settings,mousekeydown
	IniWrite,%km_Mouse_left%,KeyboardMouser.ini,Settings,mousekeyleft
	IniWrite,%km_Mouse_right%,KeyboardMouser.ini,Settings,mousekeyright
	IniWrite,%km_MouseMoveUnit%,KeyboardMouser.ini,Settings,MouseMoveUnit
	IniWrite,%km_MouseMoveInterval%,KeyboardMouser.ini,Settings,MouseMoveInterval
	IniWrite,%km_MouseMoveAccelerate%,KeyboardMouser.ini,Settings,MouseAccelerate
	IniWrite,%km_ClickLeft%,KeyboardMouser.ini,Settings,leftclick
	IniWrite,%km_ClickRight%,KeyboardMouser.ini,Settings,rightclick
	IniWrite,%km_ClickMiddle%,KeyboardMouser.ini,Settings,middleclick
	IniWrite,%km_ClickDouble%,KeyboardMouser.ini,Settings,doubleclick
	IniWrite,%km_Transparency%,KeyboardMouser.ini,Settings,transparency
Return

; set tray menu
KmTrayMenu:
	Menu,Tray,Add,&KM Settings...,KmSettings
	Menu,Tray,Tip,Keyboard Mouser
Return

; Setting First Windows Potision
KmSetWindowPos:
	; Calculate window's size
	SysGet, km_WorkArea, Monitor,%km_MonitorNum%  ; MonitorWorkArea

	km_WindowWidth = %km_WorkAreaRight%
	km_WindowWidth -= %km_WorkAreaLeft%  ; Now km_WindowX contains the width of this monitor

	km_WindowHeight = %km_WorkAreaBottom%
	km_WindowHeight -= %km_WorkAreaTop%  ; Now km_WindowX contains the heigth of this monitor

    ; set window settings
	km_KBSizeW := km_WindowWidth
	km_KBSizeH := km_WindowHeight
	km_WinPosX := km_WorkAreaLeft
	km_WinPosY := km_WorkAreaTop
	km_WinCentorPosX := km_WorkAreaLeft +  km_WindowWidth/2
	km_WinCentorPosY := km_WorkAreaTop + km_WindowHeight/2
	km_FontSize := km_StartFontSize
	km_KBDepth := 0
Return

; Create Main Window
;   Full Size or adjust the size of a button
KmCreateWindow:
	;---- Create a GUI window for the on-screen keyboard:
	Gui, Font, s%km_FontSize% %km_FontStyle%, %km_FontName%
	Gui, -Caption -SysMenu +lastfound +ToolWindow +AlwaysOnTop 
	km_ID:=WinExist()

	km_KeyHeight := Ceil(km_KBSizeH/km_KBLineNumber)
	;MsgBox, %km_KeyHeight%
	
	; Make all buttons for the position of mouse-move
	Loop, 4
	{
		km_A_Index = %A_Index%
		StringSplit, km_KBLine_, km_KBLine%km_A_Index%

		km_KeyWidth := Ceil(km_KBSizeW/km_KBLine_0)
		km_KeySize = w%km_KeyWidth% h%km_KeyHeight%
		km_Position = x+0 %km_KeySize%
		; MsgBox, k_KBLine%km_A_Index%, %km_KBLine_0%
		Loop, %km_KBLine_0%
		{
			km_KeyLabel := km_KBLine_%A_Index%
			if( A_Index = 1){
				Gui, Add, Button,x0 y+0 %km_KeySize% gKmClickButton, %km_KeyLabel%
			}
			else{
				Gui, Add, Button, %km_Position% gKmClickButton, %km_KeyLabel%
			}
			;MsgBox, %km_Position%, %km_KeyLabel%
		}
	}
	km_WinPosX := km_WinCentorPosX - km_KBSizeW/2
	km_WinPosY := km_WinCentorPosY - km_KBSizeH/2
	Gui, Show, Minimize X%km_WinPosX% Y%km_WinPosY% W%km_KBSizeW% H%km_KBSizeH%
	WinSet, Transparent, %km_Transparency%, ahk_id %km_ID%
	Gui, Show, Restore


Return

; Click Button Callback 
KmClickButton:
	; MsgBox km_UserInput=%km_UserInput%
	ControlGetFocus, km_FocusedCtrl, ahk_id %km_ID%
	; MsgBox, Control with focus = %km_FocusedCtrl%
	ControlGetText, km_UserInput, %km_FocusedCtrl%, ahk_id %km_ID%

	; User Input 
	GoSub, KmInputKBLine

	; window destroy
	GUI, Destroy

	; Get the next Window size
	GoSub, KmChangeKBSize

	; Create the next window
	GoSub, KmCreateWindow
	
	; Centering the mouse cursor
	GoSub, KmMoveMouseCursorToCenter

Return

; scan keys and call keypress process
KmInputKBLine:
	Loop, 4
	{
		;MsgBox, %A_Index% : %km_UserInput%, km_KBLine%A_Index%
		IfInString, km_KBLine%A_Index%, %km_UserInput%
		{
            ; take a key count of the line for the next window-size calculate
			km_KBLineSize := km_KBLine%A_Index%Size

			; Process according the user input key
			KmKeyPress(km_UserInput)
			Return
		}
	}
	
	Exit

Return

; Calculate next widow size
KmChangeKBSize:
	if(km_KBDepth < km_MaxKBDepth)
	{
    	;Calculate a new Window size
		km_KBSizeW := Ceil(km_KBSizeW / km_KBLineSize)
		km_KBSizeH := Ceil(km_KBSizeH/km_KBLineNumber)
		km_FontSize := Ceil(km_FontSize / km_KBLineSize)
		; MsgBox, NewWinSize %km_KBSizeW%,%km_KBSizeH%,%km_FontSize%
		km_KBDepth += 1
	}
Return


; Get the center pos of the user-selected key area
; that is the next position of the cursor
KmKeyPress(km_UserInput)
{
	global km_ID, km_WinPosX, km_WinPosY, km_WinCentorPosX, km_WinCentorPosY
	;MsgBox, KmKeyPress
	SetTitleMatchMode, 3  ; Prevents the T and B keys from being confused with Tab and Backspace.
	
	; MouseMove to the center of the key-button
	ControlGetPos, mouseMoveX, mouseMoveY, mouseMoveW, mouseMoveH, %km_UserInput%, ahk_id %km_ID%
	;
	km_WinCentorPosX := km_WinPosX + (mouseMoveX + mouseMoveW/2)
	km_WinCentorPosY := km_WinPosY + (mouseMoveY + mouseMoveH/2)

	return
}

KmMoveMouseCursorToCenter:
	CoordMode,Mouse,Screen
	MouseMove, km_WinCentorPosX, km_WinCentorPosY
	CoordMode,Mouse,Relative
Return

RecoverDragState:
    if(km_DragMode){
        SendEvent {Click %km_DragButton% Up}
        ; MsgBox, RecoverDragState=%km_DragButton%
        km_DragMode := False
        km_DragButton := ""
    }
Return

; move mouse cursor by 4 direction keys
KmMoveMouseCursor(km_UserInput)
{
	global km_Mouse_up,km_Mouse_down,km_Mouse_left,km_Mouse_right,km_MouseMoveUnit, km_MouseMoveInterval,km_MouseMoveAccelerate
	; MsgBox, KmMoveMouseCursor
	SetMouseDelay, %km_MouseMoveInterval%
    BlockInput, On
	Loop
	{
		MoveX := 0, MoveY := 0, Accel := 1

		; Check Keystate, if accelerate or not
		Accel *= GetKeyState("Shift", "P") ? km_MouseMoveAccelerate : 1

		; Check KeyState if move or not
		MoveY -= GetKeyState(km_Mouse_up, "P") ? km_MouseMoveUnit*Accel : 0
		MoveY += GetKeyState(km_Mouse_down, "P") ? km_MouseMoveUnit*Accel : 0
		MoveX += GetKeyState(km_Mouse_right, "P") ? km_MouseMoveUnit*Accel : 0
		MoveX -= GetKeyState(km_Mouse_left, "P") ? km_MouseMoveUnit*Accel : 0
		;MsgBox MoveX,MoveY= %MoveX%, %MoveY%, %km_MouseMoveUnit%
		If (MoveX = 0) & (MoveY = 0)
		{
    		MoveY -= GetKeyState("Up", "P") ? km_MouseMoveUnit*Accel : 0
    		MoveY += GetKeyState("Down", "P") ? km_MouseMoveUnit*Accel : 0
    		MoveX += GetKeyState("Right", "P") ? km_MouseMoveUnit*Accel : 0
    		MoveX -= GetKeyState("Left", "P") ? km_MouseMoveUnit*Accel : 0
    		If (MoveX = 0) & (MoveY = 0)
    		{
			    Break
			}
		}
		MouseMove, MoveX, MoveY, 0, R
	}
    BlockInput, Off
	SetMouseDelay, 0
	return
}

; Click 
KmClickMouse(km_UserInput)
{
	global km_ClickLeft,km_ClickRight,km_ClickMiddle,km_ClickDouble,km_DragMode,km_DragButton
	GUI Destroy

	;MsgBox km_UserInput=%km_UserInput%

	ClickCount = 1

    km_UserInput := KmGetClickKey(km_UserInput)
	if( km_UserInput = km_ClickLeft){
		WhichButton = LEFT
	}
	else if( km_UserInput = km_ClickRight){
		 WhichButton = RIGHT
	}
	else if( km_UserInput = km_ClickMiddle){
		WhichButton = MIDDLE
	}
	else if( km_UserInput = km_ClickDouble){
		WhichButton = LEFT
		ClickCount = 2
	}
	else{
		MsgBox, MouseClick Error:[%km_UserInput%], key=%km_ClickLeft%,%km_ClickRight%,%km_ClickMiddle%,%km_ClickDouble%
	}
	
	if(!km_DragMode and km_UserInput != km_ClickDouble and GetKeyState("Alt","P"))
	{
        km_DragMode := True
        km_DragButton := WhichButton
        SendEvent {Click %km_DragButton% Down}
    }
    else{
        if(!km_DragMode){
            Click,%WhichButton%,,,%ClickCount%
        }
        else{
            ; if DragMode=true, force up event
            GoSub,RecoverDragState
        }
    }
	;MsgBox MouseClick, %WhichButton%, ,, %ClickCount%
	
	
	return
}

KmGetClickKey(km_UserInput)
{
    global km_ClickRight, km_ClickDouble, km_ClickLeft, km_ClickMiddle
    if( km_UserInput != "Enter" ){
        return km_UserInput
    }
    
    ; Check * + Enter
	if(GetKeyState("Shift","P")){
		km_UserInput := km_ClickRight
	}
	else if(GetKeyState("Ctrl","P")){
		km_UserInput := km_ClickMiddle
    }
	else if(GetKeyState("Alt","P")){
        km_UserInput := km_ClickDouble
	}
	else{
		km_UserInput := km_ClickLeft
	}
	
	return km_UserInput
}


; Get the index of the monitor containing the specified x and y co-ordinates.
KmGetMonitorAt(x, y)
{
    SysGet, m, MonitorCount
    ; Iterate through all monitors.
    Loop, %m%
    {   ; Check if the window is on this monitor.
        SysGet, Mon, Monitor, %A_Index%
        if (x >= MonLeft && x <= MonRight && y >= MonTop && y <= MonBottom)
            return A_Index
    }

    return 1
}

KmMoveNextDisplay(pos)
{
	global km_MonitorNum
	
	km_MonitorNum += pos
	;MsgBox, km_MonitorNum=%km_MonitorNum%

    SysGet, m, MonitorCount
    ; Iterate through all monitors.
	if (km_MonitorNum < 1 )
	{
		km_MonitorNum = %m%
	}
	else if(km_MonitorNum > m)
	{
		km_MonitorNum = 1
	}
	;MsgBox, km_MonitorNum=%km_MonitorNum%

	return
}

EmulateTabKeyInput()
{
    global km_DragMode
	if(GetKeyState("Alt", "P") or GetKeyState("LWin", "P") or GetKeyState("RWin", "P"))
	{
        ; if DragMode=true, recover before SendEvent
        GoSub,RecoverDragState

        ; emulate task-change-key input
		if(GetKeyState("Alt", "P")){
            SendEvent, {Blind}!{TAB}
        }
        else{
            SendEvent, {Blind}#{TAB}
        }
		return True
	}
	else if(!km_DragMode)
	{
    	; emulate tab stops
    	if(GetKeyState("Shift", "P")){
    		SendInput, +{TAB}
    	}
    	else{
    		SendInput, {TAB}
    	}
    }
	return False
}


;
; --------------< Setting Section >--------------
;

; Show Setting GUI
KmSettings:
	HotKey,%km_MainHotKey%,Off
	SendEvent,{Escape}
	
	Gui,8: Destroy
	
	; Hotkey
	Gui,8: Add,GroupBox,xm ym w350 h70,&Hotkey
	Gui,8: Add,Edit,xp+10 yp+20 w100 R1 vshotkey, %km_MainHotKey%
	Gui,8: Add,Text, x+10 ,Current hotkey: %km_MainHotKey%
	Gui,8: Add, Text, xm+10 y+15, Set AHK HotKey-Style String: +=Shift, ^=Ctrl, !=Alt, #=Win

    ; Display Area Keys
	Gui,8: Add,GroupBox,xm y+20 w350 h140,&Display area keys
	Gui,8: Add, Text, xm+10 yp+20, Key Line 1:
	Gui,8: Add, Edit,x+5 w100 R1 vsline1, %km_KBLine1%
	Gui,8: Add, Text, xm+10 y+3, Key Line 2:
	Gui,8: Add, Edit,x+5  w100 R1 vsline2, %km_KBLine2%
	Gui,8: Add, Text, xm+10 y+3, Key Line 3:
	Gui,8: Add, Edit,x+5  w100 R1 vsline3, %km_KBLine3%
	Gui,8: Add, Text, xm+10 y+3, Key Line 4:
	Gui,8: Add, Edit,x+5  w100 R1 vsline4, %km_KBLine4%
	Gui,8: Add, Text, xm+10 y+3, Max KB Depth:
	Gui,8: Add, Edit,x+5  w25 R1 Number Limit1 vsmaxkbdepth, %km_MaxKBDepth%
	Gui,8: Add, Text, xm+150 yp , Font Size:
	Gui,8: Add, Edit,xm+210 yp  w30 R1 Number Limit3 vsstartfontsize, %km_StartFontSize%


    ; Mouse movement keys
	Gui,8: Add,GroupBox,xm y+20 w350 h125,&Mouse movement keys

	; Hotkey UP
	Gui,8: Add, Text,xm+10 yp+20,Up:
	Gui,8: Add,Edit,xm+40 yp w80 R1 vsmousekeyup, %km_Mouse_up%

	; Hotkey DOWN
	Gui,8: Add, Text,xm+150 yp,Down:
	Gui,8: Add,Edit,xm+190 yp w80 R1 vsmousekeydown, %km_Mouse_down%

	; Hotkey LEFT
	Gui,8: Add, Text,xm+10 y+5,Left:
	Gui,8: Add,Edit,xm+40 yp w80 R1 vsmousekeyleft, %km_Mouse_left%

	; Hotkey RIGHT
	Gui,8: Add, Text,xm+150 yp,Right:
	Gui,8: Add,Edit,xm+190 yp W80 R1 vsmousekeyright, %km_Mouse_right%

	; mouse move Size
	Gui,8: Add, Text, xm+10 y+5,Move Size:
	Gui,8: Add,Edit,x+10 w30 R1 Number Limit2 vsmousemoveunit, %km_MouseMoveUnit%

    ; mouse move Interval
	Gui,8: Add,Text,xm+125 yp,Move Interval:
	Gui,8: Add,Edit,xm+210 yp w40 R1 Number Limit3 vsmousemoveinterval, %km_MouseMoveInterval%
	Gui,8: Add,Text,x+5,ms

    ; mouse move Accelerate
	Gui,8: Add, Text, xm+10 y+15,Move Accelerate:
	Gui,8: Add,Edit,x+10 w30 R1 Number Limit3 vsmousemoveaccelerate, %km_MouseMoveAccelerate%

    ; Mouse clicks
	Gui,8: Add,GroupBox,xm y+20 w350 h70,&Mouse clicks

	; Hotkey LEFTCLICK
	Gui,8: Add, Text, xm+10 yp+20, Left:
	Gui,8: Add, Edit, xm+50 yp w80 R1 vsclickleft, %km_ClickLeft%

	; Hotkey RIGHTCLICK
	Gui,8: Add, Text, xm+150 yp, Right:
	Gui,8: Add, Edit, xm+195 yp w80 R1 vsclickright, %km_ClickRight%

	; Hotkey MIDDLECLICK
	Gui,8: Add, Text, xm+10 yp+20, Middle:
	Gui,8: Add, Edit, xm+50 yp w80 R1 vsclickmiddle, %km_ClickMiddle%

	; Hotkey DOUBLECLICK
	Gui,8: Add, Text, xm+150 yp, Double:
	Gui,8: Add, Edit,xm+195 yp w80 R1 vsclickdouble, %km_ClickDouble%


    ; Visualization Transparency
	Gui,8: Add,GroupBox,xm y+20 w350 h60,&Visualization Transparency (25 to 250; currently:%km_Transparency%):
	Gui,8: Add, Slider, xp+10 yp+20 w330 vstransparency Range25-250 ToolTipRight TickInterval25, %km_Transparency%


    ; OK,Cancel Buttons
	Gui,8: Add,Button,xm y+30 w75 gKmGettingsOk,&OK
	Gui,8: Add,Button,x+5 w75 gKmGettingCancel,&Cancel

    ; Show Setting Dialog
	Gui,8: Show,,Keyboard Mouser Settings
Return

KmGettingsOk:

	Gui,8: Submit
	If shotkey<>
	{
	  km_MainHotKey:=shotkey
	  HotKey,%km_MainHotKey%,KmStart
	}

	km_KBLine1 := sline1
	km_KBLine2 := sline2
	km_KBLine3 := sline3
	km_KBLine4 := sline4

	If smaxkbdepth<>
	{
	  km_MaxKBDepth := smaxkbdepth
	}
	If sstartfontsize<>
	{
	  km_StartFontSize := sstartfontsize
	}
	If smousekeyup<>
	{
	  km_Mouse_up := smousekeyup
	}
	If smousekeyleft<>
	{
	  km_Mouse_left := smousekeyleft
	}
	If smousekeyright<>
	{
	  km_Mouse_right := smousekeyright
	}
	If smousekeydown<>
	{
	  km_Mouse_down := smousekeydown
	}
	If smousemoveunit<>
	{
	  km_MouseMoveUnit := smousemoveunit
	}
	If smousemoveinterval<>
	{
		km_MouseMoveInterval := smousemoveinterval
	}
	if smousemoveaccelerate<>
	{
        km_MouseMoveAccelerate := smousemoveaccelerate
    }
	If sclickleft<>
	{
	  km_ClickLeft := sclickleft
	}
	If sclickright<>
	{
	  km_ClickRight := sclickright
	}
	If sclickdouble <>
	{
	  km_ClickDouble := sclickdouble
	}
	If sclickmiddle <>
	{
	  km_ClickMiddle := sclickmiddle
	}


	HotKey,%km_MainHotKey%,On
	If stransparency<>
	  km_Transparency:=stransparency
	  
	
	GoSub, KmWriteInifile

	Gui, 8: Destroy
	Reload
	Sleep, 1000
Return

KmGettingCancel:
	HotKey,%km_MainHotKey%,KmStart,On
	HotKey,%km_MainHotKey%,On
	Gui,8: Destroy
Return

