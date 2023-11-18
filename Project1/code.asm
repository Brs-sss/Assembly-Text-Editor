.386
.model flat,stdcall
option casemap:none
include windows.inc
include user32.inc
include kernel32.inc
include gdi32.inc
include comdlg32.inc
include shlwapi.inc

includelib user32.lib
includelib kernel32.lib
includelib comdlg32.lib
includelib gdi32.lib
includelib shlwapi.lib

includelib      msvcrt.lib
include         msvcrt.inc

WinMain proto :DWORD,:DWORD,:DWORD,:DWORD

.data                     ; initialized data
ClassName db "SimpleWinClass",0        ; the name of our window class
AppName db "Text Editor",0        ; the name of our window

FileName db "File",0                ; The name of our menu in the resource file.
OpenName db "Open",0
SaveName db "Save",0
SaveAsName db "Save As",0

EditName db "Edit",0
DateName db "Date",0

ViewName db "View",0
FontName db "Font",0
SizeName db "Size",0

szFileName	db	MAX_PATH dup (0)
pBuffer db 4096 dup(0)
szDefExt db "txt",0 ; 设置默认扩展名
szFilter	db	'Text Files(*.txt)',0,'*.txt',0,'All Files(*.*)',0,'*.*',0,0

EditClassName db "EDIT"
clientWidth DWORD 0
clientHeight DWORD 0

open_string db "You're trying to open a file while this fuction is not implemented right now! hhh--",0
save_string db "You're trying to save the file while this fuction is not implemented right now! hhh--",0

curText BYTE "nothing", 1000 DUP(0)
curLen DWORD 7
char WPARAM 20h 

hGlobal    dd 0           ; 全局内存句柄
lpText     dd 0           ; 文本缓冲区指针
strStart   DWORD 0
strEnd     DWORD 0
emptyString db 0

dateBuffer db 64 dup(0)
dateFormat db "%02d:%02d %04d/%02d/%02d ", 0
pathBuffer db 256 dup(0) ; 用于记录当前文件已保存的路径

ChsFont db 20 DUP(?)
ChsStyle db 20 DUP(?)
ChsSize db 20 DUP(?)

temp DWORD 0

.data?                ; 未初始化变量声明区域
hInstance HINSTANCE ?        ; 程序的实例句柄
hMenu HMENU ?
hFileMenu HMENU ?
hEditMenu HMENU ?
hViewMenu HMENU ?
hEdit HWND ?
CommandLine LPSTR ?

hasSaved db, 0
systemtime_buffer SYSTEMTIME <> ; 用于存储系统时间的变量
hasChanged db, 0				; 用于判断

.const
IDM_OPEN equ 1                    ; 菜单ID
IDM_SAVE equ 2
IDM_DATE equ 3
IDM_FONT equ 4
IDM_SIZE equ 5
IDM_SAVEAS equ 6

IDD_SETFONT equ 9                 ; 对话框ID
IDL_SIZE equ 1004
IDL_STYLE equ 1005
IDL_FONT equ 1008
IDC_FONT equ 1011
IDC_STYLE equ 1012
IDC_FSIZE equ 1015

szWarnCaption	db	'错误',0
szCreateWarnMessage	db	'CreateFile错误',0
szReadWarnMessage	db	'ReadFile错误',0

OpFonts db "Calibri", 0			  ; 可选字体、风格和粗细
		db "Kaiti", 0			  ; 请更改支持字体、风格等，此处仅为debug示例
		db "MS YaHei", 0          ; 更改后无需变动其他代码，ChsX..X中就会存储对应内容
		db "Songti", 0
FontEnd equ $

OpStyles db "bold", 0
		 db "light", 0
		 db "regular", 0
StyleEnd equ $

OpSizes db "100", 0
		db "200", 0
		db "300", 0
		db "400", 0
SizeEnd equ $

infoFont db '字体', 0		  ; 提示信息
infoStyle db '粗细', 0
infoSize db '字号', 0

debugFont db 'Enter font', 0
debugStyle db 'Enter style', 0
debugSize db 'Enter size', 0

saveCaption db '错误',0
saveMessage db '是否要保存当前文件', 0

editId WORD 101

.code                ; Here begins our code
start:
invoke GetModuleHandle, NULL            ; 获取程序的实例句柄

mov hInstance,eax
invoke GetCommandLine                        ; 获取命令行参数

mov CommandLine,eax
invoke WinMain, hInstance,NULL,CommandLine, SW_SHOWDEFAULT        ; 调用WinMain函数
invoke ExitProcess, eax                           ; 退出程序

SaveFile proc fileName:DWORD, nameLength:DWORD, dwBytesWritten:DWORD, hFile:HANDLE
	; Try to open file
	invoke CreateFile, fileName, GENERIC_WRITE, 0, 0, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0
	mov hFile, eax
	.if hFile != INVALID_HANDLE_VALUE
		; 修改保存信息
		mov ecx, nameLength
		mov esi, fileName
		mov edi, offset pathBuffer
		rep movsb
		mov hasSaved, 1

		; 选择编辑框中的所有文本
		invoke SendMessage, hEdit, EM_SETSEL, 0, -1

		; 获取选中文本的起始和结束位置
		invoke SendMessage, hEdit, EM_GETSEL, addr strStart, addr strEnd

		; 计算选中文本的长度
		mov eax, strEnd
		sub eax, strStart

		; 分配足够的内存来存储选中文本
		inc eax
		invoke GlobalAlloc, GMEM_ZEROINIT, eax
		mov hGlobal, eax

		; 锁定全局内存并获取其指针
		invoke GlobalLock, hGlobal
		mov lpText, eax

		; 获取选中文本
		mov eax, strEnd
		sub eax, strStart
		inc eax
		invoke GetWindowText, hEdit, lpText, eax

		; 解锁全局内存
		invoke GlobalUnlock, hGlobal

		; 保存
		mov ecx, strEnd
		sub ecx, strStart
		invoke WriteFile, hFile, lpText, ecx, addr dwBytesWritten, 0

		; 释放全局内存
		invoke GlobalFree, hGlobal
					
		; 关闭文件句柄
		invoke CloseHandle, hFile

		; 将光标移动到末尾
		invoke SendMessage, hEdit, EM_SETSEL, -1, -1

		; 设置焦点
		invoke SetFocus, hEdit
		.else
			invoke MessageBox, 0, addr szCreateWarnMessage, addr szWarnCaption, MB_ICONERROR or MB_OK
		.endif
		ret
SaveFile endp

CheckFileNameExtension proc lpFileName:DWORD, lpDefExt:DWORD
    ; 寻找文件名中的最后一个反斜杠
    invoke StrRChr, lpFileName, 0, '\\'
    mov ecx, eax

    ; 如果找到反斜杠，移动到下一个字符
    .if ecx != 0
        inc ecx
    .else
        mov ecx, lpFileName
    .endif

    ; 寻找文件名中的最后一个点号
    invoke StrRChr, ecx, 0, '.'
    .if eax == 0
        ; 如果没有点号，检查是否存在同名文件夹
        invoke PathIsDirectory, lpFileName
        .if eax == FALSE
            ; 如果不是文件夹，追加默认扩展名
            invoke lstrcat, lpFileName, lpDefExt
        .endif
    .endif

    ret
CheckFileNameExtension endp

HandleUnsaved proc hWnd:HWND, bytesRead:DWORD, hFile:HANDLE, dwBytesWritten:DWORD, ofn:OPENFILENAME
	invoke	RtlZeroMemory, addr ofn, sizeof ofn
	.if hasSaved==0
		mov	ofn.lStructSize,sizeof ofn
		push	hWnd
		pop	ofn.hwndOwner
		mov	ofn.lpstrFilter, offset szFilter
		mov	ofn.lpstrFile, offset szFileName
		mov ofn.lpstrDefExt, offset szDefExt
		mov	ofn.nMaxFile, MAX_PATH
		mov ofn.Flags, OFN_OVERWRITEPROMPT
		invoke	GetSaveFileName, addr ofn
		.if	eax
			invoke CheckFileNameExtension, addr szFileName, offset szDefExt
			mov eax, ofn.lpstrFile
			mov esi, eax
			xor ecx, ecx
			.while byte ptr [esi] != 0 ;Get the name of file to be open
				mov al, byte ptr [esi]
				mov byte ptr [szFileName + ecx], al
				inc esi
				inc ecx
			.endw
			invoke SaveFile, addr szFileName, LENGTHOF szFileName, dwBytesWritten, hFile
		.endif
	.else
		invoke SaveFile, addr pathBuffer, LENGTHOF szFileName, dwBytesWritten, hFile
	.endif
	mov hasChanged, 0
	ret
HandleUnsaved endp

WinMain proc hInst:HINSTANCE, hPrevInst:HINSTANCE, CmdLine:LPSTR, CmdShow:DWORD
    LOCAL wc:WNDCLASSEX                                            ; 创建stack上的初始变量
    LOCAL msg:MSG
    LOCAL hwnd:HWND
	LOCAL rect:RECT

    mov   wc.cbSize,SIZEOF WNDCLASSEX                   ; 为wc成员变量设置初始值
    mov   wc.style, CS_HREDRAW or CS_VREDRAW
    mov   wc.lpfnWndProc, OFFSET WndProc
    mov   wc.cbClsExtra,NULL
    mov   wc.cbWndExtra,NULL
    push  hInstance
    pop   wc.hInstance
    mov   wc.hbrBackground,COLOR_WINDOW+1
	mov   wc.lpszMenuName,OFFSET FileName
    mov   wc.lpszClassName,OFFSET ClassName
    invoke LoadIcon,NULL,IDI_APPLICATION
    mov   wc.hIcon,eax
    mov   wc.hIconSm,eax
    invoke LoadCursor,NULL,IDC_ARROW
    mov   wc.hCursor,eax

	;菜单栏
	invoke CreateMenu
    mov hMenu, eax

	invoke CreatePopupMenu
    mov hFileMenu, eax ; 文件菜单
    invoke AppendMenu, hFileMenu, MF_STRING, IDM_OPEN, OFFSET OpenName
    invoke AppendMenu, hFileMenu, MF_STRING, IDM_SAVE, OFFSET SaveName
	invoke AppendMenu, hFileMenu, MF_STRING, IDM_SAVE, OFFSET SaveAsName
	invoke AppendMenu, hMenu, MF_POPUP, hFileMenu, OFFSET FileName

	invoke CreatePopupMenu
    mov hEditMenu, eax ; 编辑菜单
    invoke AppendMenu, hEditMenu, MF_STRING, IDM_DATE, OFFSET DateName
    invoke AppendMenu, hMenu, MF_POPUP, hEditMenu, OFFSET EditName

	invoke CreatePopupMenu
	mov hViewMenu, eax ; 视图菜单
    invoke AppendMenu, hViewMenu, MF_STRING, IDM_FONT, OFFSET FontName
    invoke AppendMenu, hMenu, MF_POPUP, hViewMenu, OFFSET ViewName

    invoke RegisterClassEx, addr wc                       ; 注册窗口类
    invoke CreateWindowEx,NULL,\
                ADDR ClassName,\
                ADDR AppName,\
                WS_OVERLAPPEDWINDOW,\
                CW_USEDEFAULT,\
                CW_USEDEFAULT,\
                CW_USEDEFAULT,\
                CW_USEDEFAULT,\
                NULL,\
                hMenu,\
                hInst,\
                NULL
    mov   hwnd,eax
	invoke SetMenu, hwnd, hMenu
	
	; 设置edit控件
	invoke GetClientRect, hwnd, ADDR rect
	push rect.bottom
	pop clientHeight
	push rect.right
	pop clientWidth
	invoke CreateWindowEx, NULL,\
				ADDR EditName, \
				NULL, \
				WS_CHILD or WS_VISIBLE or WS_VSCROLL or ES_LEFT or ES_MULTILINE or ES_AUTOVSCROLL, \
				0, 0, \
				clientWidth, clientHeight, \
				hwnd, 
				editId, 
				hInstance, 
				NULL
	mov hEdit, eax

    invoke ShowWindow, hwnd, CmdShow               ; 显示窗口
    invoke UpdateWindow, hwnd                      ; 刷新窗口

    .WHILE TRUE                                                       ; 消息循环
                invoke GetMessage, ADDR msg,NULL,0,0
                .BREAK .IF (!eax)
                invoke TranslateMessage, ADDR msg
                invoke DispatchMessage, ADDR msg
   .ENDW
    mov     eax,msg.wParam                                            ; 返回值储存在eax中
    ret
WinMain endp

; 对话框消息循环函数
DialogProc PROC hWinDlg:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	LOCAL hList:HANDLE
	LOCAL bytesRead:DWORD
	LOCAL hFile:HANDLE
	LOCAL dwBytesWritten:DWORD
	LOCAL ofn:OPENFILENAME

    .IF uMsg == WM_INITDIALOG
        ; 添加List内容
		mov esi, OFFSET OpFonts
		addFont:
			mov ebx, esi
			invoke SendDlgItemMessage, hWinDlg, IDL_FONT, LB_ADDSTRING, 0, ebx
			invoke crt_strlen, ebx
			add esi, eax
			inc esi
			cmp esi, FontEnd
			jne addFont

		mov esi, OFFSET OpStyles
		addStyle:
			mov ebx, esi
			invoke SendDlgItemMessage, hWinDlg, IDL_STYLE, LB_ADDSTRING, 0, ebx
			invoke crt_strlen, ebx
			add esi, eax
			inc esi
			cmp esi, StyleEnd
			jne addStyle

		mov esi, OFFSET OpSizes
		addSize:
			mov ebx, esi
			invoke SendDlgItemMessage, hWinDlg, IDL_SIZE, LB_ADDSTRING, 0, ebx
			invoke crt_strlen, ebx
			add esi, eax
			inc esi
			cmp esi, SizeEnd
			jne addSize

		; 设置提示文本内容
		invoke GetDlgItem, hWinDlg, IDC_FONT
		invoke SetWindowText, eax, OFFSET infoFont

		invoke GetDlgItem, hWinDlg, IDC_STYLE
		invoke SetWindowText, eax, OFFSET infoStyle

		invoke GetDlgItem, hWinDlg, IDC_FSIZE
		invoke SetWindowText, eax, OFFSET infoSize

		mov eax, 1
    .ELSEIF uMsg == WM_COMMAND
        .IF wParam == IDOK
			; TODO: 更改edit控价字体
			; 当前选定的内容已经在ChsX...X中保存，只需调用Edit的接口即可，句柄为hEdit
            invoke EndDialog, hWinDlg, 0
		.ELSEIF wParam == IDCANCEL
			invoke EndDialog, hWinDlg, 0
		.ELSE
			mov ebx, wParam
			mov ecx, wParam
			shr ecx, 16 
			.IF bx == IDL_FONT && cx == LBN_SELCHANGE
				invoke GetDlgItem, hWinDlg, IDL_FONT				; 获取list句柄
				mov hList, eax
				invoke SendMessage, hList, LB_GETCURSEL, 0, 0		; 获取选中元素项数
				invoke SendMessage, hList, LB_GETTEXT, eax, ADDR ChsFont
			.ELSEIF bx == IDL_STYLE && cx == LBN_SELCHANGE
				invoke GetDlgItem, hWinDlg, IDL_STYLE				
				mov hList, eax
				invoke SendMessage, hList, LB_GETCURSEL, 0, 0
				invoke SendMessage, hList, LB_GETTEXT, eax, ADDR ChsStyle
			.ELSEIF bx == IDL_SIZE && cx == LBN_SELCHANGE
				invoke GetDlgItem, hWinDlg, IDL_SIZE				
				mov hList, eax
				invoke SendMessage, hList, LB_GETCURSEL, 0, 0
				invoke SendMessage, hList, LB_GETTEXT, eax, ADDR ChsSize
			.ENDIF
        .ENDIF
	.ELSEIF uMsg == WM_CLOSE
		invoke EndDialog, hWinDlg, 0
	; TODO: 响应表单记录时间
    .ENDIF
    xor eax, eax
    ret
DialogProc ENDP

WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    LOCAL hdc:HDC
    LOCAL ps:PAINTSTRUCT
    LOCAL rect:RECT
	LOCAL bytesRead:DWORD
	LOCAL hFile:HANDLE
	LOCAL dwBytesWritten:DWORD
	LOCAL ofn:OPENFILENAME

    .IF uMsg==WM_DESTROY
        invoke PostQuitMessage,NULL

	.ELSEIF uMsg==WM_CLOSE
		.if hasChanged==1
			invoke MessageBox, 0, addr saveMessage, addr saveCaption, MB_YESNOCANCEL
			.if eax == IDYES
				invoke HandleUnsaved, hWnd, bytesRead, hFile, dwBytesWritten, ofn
			.elseif eax == IDCANCEL
				ret
			.endif
		.endif
		invoke DestroyWindow, hWnd

	; 调整子窗口大小
	.ELSEIF uMsg==WM_SIZE
		mov eax, lParam
		and eax, 0000FFFFh
		mov clientWidth, eax
		mov eax, lParam
		shr eax, 16
		mov clientHeight, eax

		; 重新设置Edit控件大小
		invoke MoveWindow, hEdit, 0, 0, clientWidth, clientHeight, TRUE

	; 菜单栏响应
	.ELSEIF uMsg==WM_COMMAND
        mov eax,wParam
        .IF ax==IDM_OPEN
			.if hasChanged==1
				invoke MessageBox, 0, addr saveMessage, addr saveCaption, MB_YESNOCANCEL
				.if eax == IDYES
					invoke HandleUnsaved, hWnd, bytesRead, hFile, dwBytesWritten, ofn
				.elseif eax == IDCANCEL
					ret
				.endif
			.endif
			invoke	RtlZeroMemory, addr ofn, sizeof ofn
			mov	ofn.lStructSize,sizeof ofn
			push	hWnd
			pop	ofn.hwndOwner
			mov	ofn.lpstrFilter, offset szFilter
			mov	ofn.lpstrFile, offset szFileName
			mov	ofn.nMaxFile, MAX_PATH
			mov	ofn.Flags, OFN_FILEMUSTEXIST or OFN_PATHMUSTEXIST
			invoke	GetOpenFileName, addr ofn
			.if	eax
				mov eax, ofn.lpstrFile
					mov esi, eax
					xor ecx, ecx
				.while byte ptr [esi] != 0 ; 获取要打开文件的文件名
					mov al, byte ptr [esi]
					mov byte ptr [szFileName + ecx], al
					inc esi
					inc ecx
				.endw

				; Try to open file
				invoke CreateFile, addr szFileName, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
				mov hFile, eax

				.if hFile != INVALID_HANDLE_VALUE
					; 设置保存相关信息
					mov hasSaved, 1
					mov ecx, LENGTHOF szFileName
					mov esi, offset szFileName
					mov edi, offset pathBuffer
					rep movsb
					mov eax, offset szFileName

					invoke ReadFile, hFile, addr pBuffer, 4096, addr bytesRead, NULL
					.if eax != 0 
						mov esi, offset curText
						mov ecx, 0
			ClearLoop:
						mov al, [esi + ecx]				; 读取字符串中的一个字符
						cmp al, 0						; 检查字符是否为null（字符串结束符）
						je EndClear						; 如果是null，结束清除
						mov byte ptr [esi + ecx], 0		; 否则，将字符设置为null
						inc ecx							; 增加计数器
						jmp ClearLoop					; 继续处理下一个字符
			EndClear:
						mov ecx, bytesRead
						mov curLen, ecx
						mov	esi, 0;
			CopyLoop:	mov al, byte ptr [pBuffer + esi]
						mov	byte ptr [curText + esi], al
						inc esi
						loop CopyLoop
						; 把文件里的内容显示到edit控件中

						; 选中编辑框中的所有内容
						invoke SendMessage, hEdit, EM_SETSEL, 0, -1

						; 替换为文件内容
						invoke SendMessage, hEdit, EM_REPLACESEL, TRUE, addr curText

						invoke SetFocus, hEdit
					.else
						invoke MessageBox, 0, addr szReadWarnMessage, addr szWarnCaption, MB_ICONERROR or MB_OK
					.endif

					invoke CloseHandle, hFile
					invoke InvalidateRect, hWnd,NULL,TRUE
				.else
					invoke MessageBox, 0, addr szCreateWarnMessage, addr szWarnCaption, MB_ICONERROR or MB_OK
				.endif
			.endif
		.ELSEIF ax==IDM_SAVE
			invoke HandleUnsaved, hWnd, bytesRead, hFile, dwBytesWritten, ofn
		.ELSEIF ax==IDM_SAVEAS
			invoke	RtlZeroMemory, addr ofn, sizeof ofn
			.if hasSaved==0
				mov	ofn.lStructSize,sizeof ofn
				push	hWnd
				pop	ofn.hwndOwner
				mov	ofn.lpstrFilter, offset szFilter
				mov	ofn.lpstrFile, offset szFileName
				mov ofn.lpstrDefExt, offset szDefExt
				mov	ofn.nMaxFile, MAX_PATH
				mov ofn.Flags, OFN_OVERWRITEPROMPT
				invoke	GetSaveFileName, addr ofn
				.if	eax
					invoke CheckFileNameExtension, addr szFileName, offset szDefExt
					mov eax, ofn.lpstrFile
						mov esi, eax
						xor ecx, ecx
					.while byte ptr [esi] != 0 ;Get the name of file to be open
						mov al, byte ptr [esi]
						mov byte ptr [szFileName + ecx], al
						inc esi
						inc ecx
					.endw
					invoke SaveFile, addr szFileName, LENGTHOF szFileName, dwBytesWritten, hFile
				.endif
			.else
				invoke SaveFile, addr pathBuffer, LENGTHOF szFileName, dwBytesWritten, hFile
			.endif
			mov hasChanged, 0
		.ELSEIF ax==IDM_DATE
			invoke GetLocalTime, addr systemtime_buffer

			; 将时间格式化为字符串
			invoke wsprintf, addr dateBuffer, addr dateFormat, systemtime_buffer.wHour, systemtime_buffer.wMinute, systemtime_buffer.wYear, systemtime_buffer.wMonth, systemtime_buffer.wDay
			; 获取Edit控件的当前文本长度
			invoke SendMessage, hEdit, WM_GETTEXTLENGTH, 0, 0
			mov edx, eax  ; edx保存当前文本长度

			mov esi, offset dateBuffer

			; 分配足够的内存来存储当前文本和要插入的新文本
			add edx, 17  ;
			invoke GlobalAlloc, GMEM_ZEROINIT, edx
			mov edi, eax

			invoke SendMessage, hEdit, WM_GETTEXT, edx, edi

			invoke lstrcat, edi, esi

			; 将新文本写入Edit控件
			invoke SendMessage, hEdit, EM_REPLACESEL, TRUE, edi

			; 释放新分配的内存
			invoke GlobalFree, edi
			.ELSEIF ax==IDM_FONT
				invoke DialogBoxParam, hInstance, IDD_SETFONT, NULL, ADDR DialogProc, 0
		.ELSEIF ax==editId
			shr eax, 16 
			.if ax==EN_CHANGE
				mov hasChanged, 1
			.endif
        .ENDIF
    .ELSE
        invoke DefWindowProc,hWnd,uMsg,wParam,lParam
        ret
    .ENDIF
    xor   eax, eax
    ret
WndProc endp

end start