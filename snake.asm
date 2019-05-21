;Author:
;	Dongyao Liang (1775353)
;	Heng Tan (1634661)


INCLUDE Irvine32.inc

;minumun 12
;maximum ...hmm depends on your output console size...
MAP_LENGTH_CONSTANT=40

.data
str1 byte " *"
MAP_LENGTH dword MAP_LENGTH_CONSTANT
MAP byte MAP_LENGTH_CONSTANT*MAP_LENGTH_CONSTANT dup(0)
_DELAY dword 150
_BLUE dword 10h
_RED dword 40h
BODY_INDEX dword MAP_LENGTH_CONSTANT dup(0)
BODY_LENGTH dword 0
HEAD_INDEX dword 0
DIRECTION dword 2

STR_START byte "Press any key to start!", 0
STR_END byte "Your final score is: ", 0
str2 byte "Current score: ", 0
str3 byte "Current delay: ", 0


; body_array:
; <- <- <- <- head <- tail <- <- <- <- 

; direction:
;	-2
; -1   1
;	 2


.code

;*******************************************************************************************************************
main PROC
	mov edx, offset STR_START
	call WriteString
	call ReadChar
	call Randomize
	call INIT_MAP
	call INIT_SNAKE
	call GENERATE_FOOD
	;40h = red background
	;10h = blue background
	;7 = clean color

INFINITE_MOVE:
	mov eax, _DELAY
	call DELAY
	;mov eax, 0
	;xor ah, ah
	call ReadKey
	;in al, 60h
	cmp al, 'w'
	jne NOT_W
	cmp DIRECTION, 2
	je CALL_MOVE
	mov DIRECTION, -2
	jmp CALL_MOVE
NOT_W:
	cmp al, 'a'
	jne NOT_A
	cmp DIRECTION, 1
	je CALL_MOVE
	mov DIRECTION, -1
	jmp CALL_MOVE
NOT_A:
	cmp al, 's'
	jne NOT_S
	cmp DIRECTION, -2
	je CALL_MOVE
	mov DIRECTION, 2
	jmp CALL_MOVE
NOT_S:
	cmp al, 'd'
	jne WRONG_KEY
	cmp DIRECTION, -1
	je CALL_MOVE
	mov DIRECTION,1
	jmp CALL_MOVE
WRONG_KEY:
	
CALL_MOVE:
	call MOVE_SNAKE
	jmp INFINITE_MOVE
main ENDP
;*******************************************************************************************************************




;*******************************************************************************************************************
INIT_MAP PROC uses ecx eax edi ebx edx esi
	mov ecx, MAP_LENGTH
	mov ebx, 0
	mov edi, offset MAP
	mov edx, 1

INIT_MAP_L2:
	mov [edi+ebx], dl
	inc ebx
	loop INIT_MAP_L2

	mov esi, MAP_LENGTH
	sub esi, 2
	mov ecx, esi
INIT_MAP_L3:
	push ecx
	mov [edi+ebx], dl
	inc ebx
	mov edx, 0
	mov ecx, esi
INIT_MAP_L4:
	mov [edi+ebx], dl
	inc ebx
	loop INIT_MAP_L4
	pop ecx
	mov edx, 1
	mov [edi+ebx], dl
	inc ebx
	loop INIT_MAP_L3

	mov ecx, MAP_LENGTH
INIT_MAP_L5:
	mov [edi+ebx], dl
	inc ebx
	loop INIT_MAP_L5

	mov edx, 0
	call Gotoxy
	mov ecx, MAP_LENGTH
	mov eax, 0
	mov edi, 0
	mov ebx, offset MAP
	mov edx, offset str1
INIT_L0:
	push ecx
	mov ecx, MAP_LENGTH

INIT_L1:
	mov al, byte ptr [ebx]
	mov al, byte ptr [edx+eax]
	call WriteChar
	call WriteChar
	inc ebx
	loop INIT_L1
	pop ecx
	call crlf
	loop INIT_L0

	mov edx, MAP_LENGTH
	mov dh, dl
	mov dl, 0
	call Gotoxy
	mov edx, offset str2
	call WriteString
	mov edx, MAP_LENGTH
	mov dh, dl
	mov dl, 30
	call Gotoxy
	mov eax, BODY_LENGTH
	call WriteDec
	
	mov edx, MAP_LENGTH
	mov dh, dl
	inc dh
	mov dl, 0
	call Gotoxy
	mov edx, offset str3
	call WriteString 
	mov edx, MAP_LENGTH
	mov dh, dl
	inc dh
	mov dl, 30
	call Gotoxy
	mov eax, _DELAY
	call WriteDec

	ret
INIT_MAP ENDP
;*******************************************************************************************************************




;*******************************************************************************************************************
INIT_SNAKE PROC uses edx ecx edi esi eax ebx
	mov edi, offset BODY_INDEX
	mov ecx, 8
	mov HEAD_INDEX, ecx
	dec HEAD_INDEX
	mov bl, 2 ; snake body constant
INIT_SNAKE_L0:
	mov eax, MAP_LENGTH
	add eax, ecx
	mov [edi+ecx*4-4], eax
	;change the map
	mov edx, offset MAP
	mov [edx+eax], bl
	inc BODY_LENGTH
	loop INIT_SNAKE_L0
	call DRAW_SNAKE
	ret
INIT_SNAKE ENDP
;*******************************************************************************************************************




;*******************************************************************************************************************
DRAW_SNAKE PROC uses ecx eax edx ebx esi edi
	mov eax, _BLUE
	call SetTextColor
	mov ecx, BODY_LENGTH
	mov ebx, 0
	mov esi, offset BODY_INDEX

DRAW_SNAKE_L0:
	mov eax, [esi+ebx*4]
	mov edx, 0
	div MAP_LENGTH
	mov dh, al
	add dl, dl
	call Gotoxy
	mov al, str1
	call WriteChar
	call WriteChar
	inc ebx
	LOOP DRAW_SNAKE_L0
	ret
DRAW_SNAKE ENDP
;*******************************************************************************************************************



;*******************************************************************************************************************
MOVE_SNAKE PROC uses eax edx esi edi ecx ebx
	mov eax, DIRECTION
	mov edx, 0
	test eax, eax
	jg POSITIVE_DIRECTION
	not edx
POSITIVE_DIRECTION:
	mov esi, 2
	idiv esi
	;eax: quotient, row movement
	;edx: remainder, column movement 
	imul eax, MAP_LENGTH
	add eax, edx ;eax have the total movement now
	mov esi, offset BODY_INDEX
	mov edi, offset MAP
	mov ecx, HEAD_INDEX
	mov ebx, [esi+ecx*4]
	add ebx, eax ;ebx = next location
	
	;now check if the next location is empty
	movzx esi, byte ptr [edi+ebx]
	test esi, esi
	jz VALID_MOVE
	cmp esi, 3
	je EAT_FOOD
	call GAME_OVER

VALID_MOVE:
	;change BODY_INDEX array, HEAD_INDEX->tail index, and MAP... Then redraw tail and head
	mov eax, HEAD_INDEX
	inc eax
	mov edx, 0
	div BODY_LENGTH
	mov HEAD_INDEX, edx
	mov esi, offset BODY_INDEX
	;get tail index and delete tail on map
	mov ecx, [esi+edx*4]
	push eax
	mov eax, 0
	mov [edi+ecx], al
	pop eax
	mov [esi+edx*4], ebx
	;change MAP
	push ecx
	mov ecx, 2
	mov [edi+ebx], cl
	pop ecx

	;redraw tail and head
	mov eax, 7
	call SetTextColor
	mov eax, ecx
	mov edx, 0
	div MAP_LENGTH
	mov dh, al
	add dl, dl
	call Gotoxy
	mov al, str1
	call WriteChar
	call WriteChar
	
	mov eax, _BLUE
	call SetTextColor
	mov eax, ebx
	mov edx, 0
	div MAP_LENGTH
	mov dh, al
	add dl, dl
	call Gotoxy
	mov al, str1
	call WriteChar
	call WriteChar
	ret

EAT_FOOD:
	inc HEAD_INDEX
	mov ecx, BODY_LENGTH
	mov eax, HEAD_INDEX
	sub ecx, eax
	mov esi, offset BODY_INDEX
	test ecx, ecx
	jz EAT_FOOD_BEST_CASE ;best case happens when the last entry of BODY_INDEX is the head,
	;when not the best case, we need to shift the array to right by 1 start from new HEAD_INDEX, ecx = count
	;BODY_INDEX[HEAD_INDEX+ecx] = BODY_INDEX[HEAD_INDEX+ecx-1]
	push edx
	push ebx
SHIFT_RIGHT:
	mov ebx, eax
	add ebx, ecx
	mov edx, [esi+ebx*4-4]
	mov [esi+ebx*4], edx
	loop SHIFT_RIGHT
	pop ebx
	pop edx

EAT_FOOD_BEST_CASE:
	;HEAD_INDEX increased already, add the new head to array, change the map and ddraw the head, tail remian the same, increase BODY_LENGTH
	;add new head to array
	mov [esi+eax*4], ebx
	;change the map
	mov ecx, 2
	mov [edi+ebx], cl
	inc BODY_LENGTH

	;draw new head
	mov eax, _BLUE
	call SetTextColor
	mov eax, ebx
	mov edx, 0
	div MAP_LENGTH
	mov dh, al
	add dl, dl
	call Gotoxy
	mov al, str1
	call WriteChar
	call WriteChar
	call GENERATE_FOOD

	;change delay
	mov eax, BODY_LENGTH
	sub eax, 8
	mov edx, 0
	mov edi, 5
	div edi
	test edx, edx
	jne KEEP_DELAY
	mov eax, _DELAY
	mov edi, 3
	mul edi
	mov edx, 0
	mov edi, 4
	div edi
	mov _DELAY, eax
KEEP_DELAY:

	;display score and delay
	mov eax, 7
	call SetTextColor
	mov edx, MAP_LENGTH
	mov dh, dl
	mov dl, 30
	call Gotoxy
	mov eax, BODY_LENGTH
	sub eax, 8
	call WriteDec
	
	mov edx, MAP_LENGTH
	mov dh, dl
	inc dh
	mov dl, 30
	call Gotoxy
	mov eax, _DELAY
	call WriteDec
	mov al, str1
	call WriteChar
	call WriteChar
	ret
MOVE_SNAKE ENDP
;*******************************************************************************************************************



;*******************************************************************************************************************
GENERATE_FOOD PROC uses eax ebx ecx edx esi edi
	;generate a random number between 0 to MAP_LENGTH^2-1, check map availability and determind to regenerate
	;change map and draw
	mov edi, offset MAP
REGEN:
	mov eax, MAP_LENGTH
	mul MAP_LENGTH
	call RandomRange
	mov ebx, [edi+eax]
	test ebx, ebx
	jnz REGEN

	mov ecx, 3
	mov [edi+eax], cl
	mov edx, 0
	div MAP_LENGTH
	mov dh, al
	add dl, dl
	call Gotoxy
	mov eax, _RED
	call SetTextColor
	mov al, str1
	call WriteChar
	call WriteChar
	ret
GENERATE_FOOD ENDP

;*******************************************************************************************************************


;*******************************************************************************************************************
GAME_OVER PROC

	mov eax, 7
	call SetTextColor
	mov edx, MAP_LENGTH
	mov dh, dl
	add dh, 4
	mov dl, 0
	call Gotoxy

	mov edx, offset STR_END
	call WriteString
	mov eax, BODY_LENGTH
	sub eax, 8
	call WriteDec
	call crlf
	exit
GAME_OVER ENDP
;*******************************************************************************************************************

END main