;tasm /m lab1.asm 
;tlink /x /3 lab1.obj
.386P
.MODEL  LARGE
;Ñòðóêòóðû äàííûõ
S_DESC  struc                                   ;Ñòðóêòóðà ñåãìåíòíîãî äåñêðèïòîðà
    LIMIT       dw 0                            ;Ëèìèò ñåãìåíòà (15:00)    
    BASE_L      dw 0                            ;Àäðåñ áàçû, ìëàäøàÿ ÷àñòü (15:0)
    BASE_M      db 0                            ;Àäðåñ áàçû, ñðåäíÿÿ ÷àñòü (23:16)
    ACCESS      db 0                            ;Áàéò äîñòóïà
    ATTRIBS     db 0                            ;Ëèìèò ñåãìåíòà (19:16) è àòðèáóòû
    BASE_H      db 0                            ;Àäðåñ áàçû, ñòàðøàÿ ÷àñòü
S_DESC  ends        
I_DESC  struc                                   ;Ñòðóêòóðà äåñêðèïòîðà òàáëèöû ïðåðûâàíèé
    OFFS_L      dw 0                            ;Àäðåñ îáðàáîò÷èêà (0:15)
    SEL         dw 0                            ;Ñåëåêòîð êîäà, ñîäåðæàùåãî êîä îáðàáîò÷èêà
    PARAM_CNT   db 0                            ;Ïàðàìåòðû
    ACCESS      db 0                            ;Óðîâåíü äîñòóïà
    OFFS_H      dw 0                            ;Àäðåñ îáðàáîò÷èêà (31:16)
I_DESC  ends        
R_IDTR  struc                                   ;Ñòðóêòóðà IDTR
    LIMIT       dw 0                            
    IDT_L       dw 0                            ;Ñìåùåíèå áèòû (0-15)
    IDT_H       dw 0                            ;Ñìåùåíèå áèòû (31-16)
R_IDTR  ends
;Ôëàãè óðîâíåé äîñòóïà ñåãìåíòîâ
ACS_PRESENT     EQU 10000000B                   ;PXXXXXXX - áèò ïðèñóòñòâèÿ, ñåãìåíò ïðèñóòñòâóåò â îïåðàòèâíîé ïàìÿòè
ACS_CSEG        EQU 00011000B                   ;XXXXIXXX - òèï ñåãìåíòà, äëÿ äàííûõ = 0, äëÿ êîäà 1
ACS_DSEG        EQU 00010000B                   ;XXXSXXXX - áèò ñåãìåíòà, äàííûé îáúåêò ñåãìåíò(ñèñòåìíûå îáúåêòû ìîãóò áûòü íå ñåãìåíòû)
ACS_READ        EQU 00000010B                   ;XXXXXXRX - áèò ÷òåíèÿ, âîçìîæíîñòü ÷òåíèÿ èç äðóãîãî ñåãìåíòà
ACS_WRITE       EQU 00000010B                   ;XXXXXXWX - áèò çàïèñè, äëÿ ñåãìåíòà äàííûõ ðàçåðøàåò çàïèñü
ACS_CODE        =   ACS_PRESENT or ACS_CSEG     ;AR ñåãìåíòà êîäà
ACS_DATA =  ACS_PRESENT or ACS_DSEG or ACS_WRITE;AR ñåãìåíòà äàííûõ
ACS_STACK=  ACS_PRESENT or ACS_DSEG or ACS_WRITE;AR ñåãìåíòà ñòåêà
ACS_INT_GATE    EQU 00001110B
ACS_TRAP_GATE   EQU 00001111B                   ;XXXXSICR - ñåãìåíò, ïîä÷èíåííûé ñåãìåíò êîäà, äîñòóïåí äëÿ ÷òåíèÿ
ACS_IDT         EQU ACS_DATA                    ;AR òàáëèöû IDT    
ACS_INT         EQU ACS_PRESENT or ACS_INT_GATE
ACS_TRAP        EQU ACS_PRESENT or ACS_TRAP_GATE
ACS_DPL_3       EQU 01100000B                   ;X<DPL,DPL>XXXXX - ïðèâåëåãèè äîñòóïà, äîñòóï ìîæåò ïîëó÷èòü ëþáîé êîä
;Ñåãìåíò êîäà ðåàëüíîãî ðåæèìà       
CODE_RM segment para use16
CODE_RM_BEGIN   = $
    assume cs:CODE_RM,DS:DATA,ES:DATA           ;Èíèöèàëèçàöèÿ ðåãèñòðîâ äëÿ àññåìáëèðîâàíèÿ
START:
    mov ax,DATA                                 ;Èíèöèàëèçèöèÿ ñåãìåíòíûõ ðåãèñòðîâ
    mov ds,ax                                   
    mov es,ax                          
    lea dx,MSG_EXIT
    mov ah,9h
    int 21h
    lea dx,MSG_HELLO
    mov ah,9h
    int 21h
ANSWER:
    mov ah, 8h
    int 21h                                     ;Îæèäàíèå ïîäòâåðæäåíèÿ
    cmp al, 'p'
    je ENABLE_A20
    cmp al, 'e'
    je END_PROG
    jmp ANSWER
ENABLE_A20:                                     ;Îòêðûòü ëèíèþ A20
    in  al,92h                                                                              
    or  al,2                                    ;Óñòàíîâèòü áèò 1 â 1                                                   
    out 92h,al                                                                                                                     
    ;Èëè òàê äëÿ ñòàðûõ êîìïüþòåðîâ                                                                                                      0 LINE
    ;mov    al, 0D1h
    ;out    64h, al
    ;mov    al, 0DFh
    ;out    60h, al
SAVE_MASK:                                      ;Ñîõðàíèòü ìàñêè ïðåðûâàíèé     
    in      al,21h
    mov     INT_MASK_M,al                  
    in      al,0A1h
    mov     INT_MASK_S,al                 
DISABLE_INTERRUPTS:                             ;Çàïðåò ìàñêèðóåìûõ è íåìàñêèðóåìûõ ïðåðûâàíèé        
    cli                                         ;Çàïðåò ìàñêèðóìûõ ïðåðûâàíèé
    in  al,70h	
	or	al,10000000b                            ;Óñòàíîâèòü 7 áèò â 1 äëÿ çàïðåòà íåìàñêèðóåìûõ ïðåðûâàíèé
	out	70h,al
	nop	
LOAD_GDT:                                       ;Çàïîëíèòü ãëîáàëüíóþ òàáëèöó äåñêðèïòîðîâ            
    mov ax,DATA
    mov dl,ah
    xor dh,dh
    shl ax,4
    shr dx,4
    mov si,ax
    mov di,dx
WRITE_GDT:                                      ;Çàïîëíèòü äåñêðèïòîð GDT
    lea bx,GDT_GDT
    mov ax,si
    mov dx,di
    add ax,offset GDT
    adc dx,0
    mov [bx][S_DESC.BASE_L],ax
    mov [bx][S_DESC.BASE_M],dl
    mov [bx][S_DESC.BASE_H],dh
WRITE_CODE_RM:                                  ;Çàïîëíèòü äåñêðèïòîð ñåãìåíòà êîäà ðåàëüíîãî ðåæèìà
    lea bx,GDT_CODE_RM
    mov ax,cs
    xor dh,dh
    mov dl,ah
    shl ax,4
    shr dx,4
    mov [bx][S_DESC.BASE_L],ax
    mov [bx][S_DESC.BASE_M],dl
    mov [bx][S_DESC.BASE_H],dh
WRITE_DATA:                                     ;Çàïèñàòü äåñêðèïòîð ñåãìåíòà äàííûõ
    lea bx,GDT_DATA
    mov ax,si
    mov dx,di
    mov [bx][S_DESC.BASE_L],ax
    mov [bx][S_DESC.BASE_M],dl
    mov [bx][S_DESC.BASE_H],dh
WRITE_STACK:                                    ;Çàïèñàòü äåñêðèïòîð ñåãìåíòà ñòåêà
    lea bx, GDT_STACK
    mov ax,ss
    xor dh,dh
    mov dl,ah
    shl ax,4
    shr dx,4
    mov [bx][S_DESC.BASE_L],ax
    mov [bx][S_DESC.BASE_M],dl
    mov [bx][S_DESC.BASE_H],dh
WRITE_CODE_PM:                                  ;Çàïèñàòü äåñêðèïòîð êîäà çàùèùåííîãî ðåæèìà
    lea bx,GDT_CODE_PM
    mov ax,CODE_PM
    xor dh,dh
    mov dl,ah
    shl ax,4
    shr dx,4
    mov [bx][S_DESC.BASE_L],ax
    mov [bx][S_DESC.BASE_M],dl
    mov [bx][S_DESC.BASE_H],dh        
    or  [bx][S_DESC.ATTRIBS],40h
WRITE_IDT:                                      ;Çàïèñàòü äåñêðèïòîð IDT
    lea bx,GDT_IDT
    mov ax,si
    mov dx,di
    add ax,OFFSET IDT
    adc dx,0
    mov [bx][S_DESC.BASE_L],ax
    mov [bx][S_DESC.BASE_M],dl
    mov [bx][S_DESC.BASE_H],dh        
    mov IDTR.IDT_L,ax
    mov IDTR.IDT_H,dx
FILL_IDT:                                       ;Çàïîëíèòü òàáëèöó äåñêðèïòîðîâ øëþçîâ ïðåðûâàíèé
    irpc    N, 0123456789ABCDEF                 ;Çàïîëíèòü øëþçû 00-0F èñêëþ÷åíèÿìè
        lea eax, EXC_0&N
        mov IDT_0&N.OFFS_L,ax
        shr eax, 16
        mov IDT_0&N.OFFS_H,ax
    endm
    irpc    N, 0123456789ABCDEF                 ;Çàïîëíèòü øëþçû 10-1F èñêëþ÷åíèÿìè
        lea eax, EXC_1&N
        mov IDT_1&N.OFFS_L,ax
        shr eax, 16
        mov IDT_1&N.OFFS_H,ax
    endm
    lea eax, KEYBOARD_HANDLER                   ;Ïîìåñòèòü îáðàáîò÷èê ïðåðûâàíèÿ êëàâèàòóðû íà 21 øëþç
    mov IDT_KEYBOARD.OFFS_L,ax
    shr eax, 16
    mov IDT_KEYBOARD.OFFS_H,ax
    irpc    N, 0234567                           ;Çàïîëíèòü âåêòîðà 20, 22-27 çàãëóøêàìè
        lea eax,DUMMY_IRQ_MASTER
        mov IDT_2&N.OFFS_L, AX
        shr eax,16
        mov IDT_2&N.OFFS_H, AX
    endm
    irpc    N, 89ABCDEF                         ;Çàïîëíèòü âåêòîðà 28-2F çàãëóøêàìè
        lea eax,DUMMY_IRQ_SLAVE
        mov IDT_2&N.OFFS_L,ax
        shr eax,16
        mov IDT_2&N.OFFS_H,ax
    endm
    lgdt fword ptr GDT_GDT                      ;Çàãðóçèòü ðåãèñòð GDTR
    lidt fword ptr IDTR                         ;Çàãðóçèòü ðåãèñòð IDTR
    mov eax,cr0                                 ;Ïîëó÷èòü óïðàâëÿþùèé ðåãèñòð cr0
    or  al,00000001b                            ;Óñòàíîâèòü áèò PE â 1
    mov cr0,eax                                 ;Çàïèñàòü èçìåíåííûé cr0 è òåì ñàìûì âêëþ÷èòü çàùèùåííûé ðåæèì
OVERLOAD_CS:                                    ;Ïåðåçàãðóçèòü ñåãìåíò êîäà íà åãî äåñêðèïòîð
    db  0EAH
    dw  $+4
    dw  CODE_RM_DESC        
OVERLOAD_SEGMENT_REGISTERS:                     ;Ïåðåèíèöèàëèçèðîâàòü îñòàëüíûå ñåãìåíòíûå ðåãèñòðû íà äåñêðèïòîðû
    mov ax,DATA_DESC
    mov ds,ax                         
    mov es,ax                         
    mov ax,STACK_DESC
    mov ss,ax                         
    xor ax,ax
    mov fs,ax                                   ;Îáíóëèòü ðåãèñòð fs
    mov gs,ax                                   ;Îáíóëèòü ðåãèñòð gs
    lldt ax                                     ;Îáíóëèòü ðåãèñòð LDTR - íå èñïîëüçîâàòü òàáëèöû ëîêàëüíûõ äåñêðèïòîðîâ
PREPARE_TO_RETURN:
    push cs                                     ;Ñåãìåíò êîäà
    push offset BACK_TO_RM                      ;Ñìåùåíèå òî÷êè âîçâðàòà
    lea  edi,ENTER_PM                           ;Ïîëó÷èòü òî÷êó âõîäà â çàùèùåííûé ðåæèì
    mov  eax,CODE_PM_DESC                       ;Ïîëó÷èòü äåñêðèïòîð êîäà çàùèùåííîãî ðåæèìà
    push eax                                    ;Çàíåñòè èõ â ñòåê
    push edi                                    
REINITIALIAZE_CONTROLLER_FOR_PM:                ;Ïåðåèíèöèàëèçèðîâàòü êîíòðîëëåð ïðåðûâàíèé íà âåêòîðà 20h, 28h
    mov al,00010001b                            ;ICW1 - ïåðåèíèöèàëèçàöèÿ êîíòðîëëåðà ïðåðûâàíèé
    out 20h,al                                  ;Ïåðåèíèöèàëèçèðóåì âåäóùèé êîíòðîëëåð
    out 0A0h,al                                 ;Ïåðåèíèöèàëèçèðóåì âåäîìûé êîíòðîëëåð
    mov al,20h                                  ;ICW2 - íîìåð áàçîâîãî âåêòîðà ïðåðûâàíèé
    out 21h,al                                  ;âåäóùåãî êîíòðîëëåðà
    mov al,28h                                  ;ICW2 - íîìåð áàçîâîãî âåêòîðà ïðåðûâàíèé
    out 0A1h,al                                 ;âåäîìîãî êîíòðîëëåðà
    mov al,04h                                  ;ICW3 - âåäóùèé êîíòðîëëåð ïîäêëþ÷åí ê 3 ëèíèè
    out 21h,al       
    mov al,02h                                  ;ICW3 - âåäîìûé êîíòðîëëåð ïîäêëþ÷åí ê 3 ëèíèè
    out 0A1h,al      
    mov al,11h                                  ;ICW4 - ðåæèì ñïåöèàëüíîé ïîëíîé âëîæåííîñòè äëÿ âåäóùåãî êîíòðîëëåðà
    out 21h,al        
    mov al,01h                                  ;ICW4 - ðåæèì îáû÷íîé ïîëíîé âëîæåííîñòè äëÿ âåäîìîãî êîíòðîëëåðà
    out 0A1h,al       
    mov al, 0                                   ;Ðàçìàñêèðîâàòü ïðåðûâàíèÿ
    out 21h,al                                  ;Âåäóùåãî êîíòðîëëåðà
    out 0A1h,al                                 ;Âåäîìîãî êîíòðîëëåðà
ENABLE_INTERRUPTS_0:                            ;Ðàçðåøèòü ìàñêèðóåìûå è íåìàñêèðóåìûå ïðåðûâàíèÿ
    in  al,70h	
	and	al,01111111b                            ;Óñòàíîâèòü 7 áèò â 0 äëÿ çàïðåòà íåìàñêèðóåìûõ ïðåðûâàíèé
	out	70h,al
	nop
    sti                                         ;Ðàçðåøèòü ìàñêèðóåìûå ïðåðûâàíèÿ
GO_TO_CODE_PM:                                  ;Ïåðåõîä ê ñåãìåíòó êîäà çàùèùåííîãî ðåæèìà
    db 66h                                      
    retf
BACK_TO_RM:                                     ;Òî÷êà âîçâðàòà â ðåàëüíûé ðåæèì
    cli                                         ;Çàïðåò ìàñêèðóåìûõ ïðåðûâàíèé
    in  al,70h	                                ;È íå ìàñêèðóåìûõ ïðåðûâàíèé
	or	AL,10000000b                            ;Óñòàíîâèòü 7 áèò â 1 äëÿ çàïðåòà íåìàñêèðóåìûõ ïðåðûâàíèé
	out	70h,AL
	nop
REINITIALISE_CONTROLLER:                        ;Ïåðåèíèöàëèçàöèÿ êîíòðîëëåðà ïðåðûâàíèé               
    mov al,00010001b                            ;ICW1 - ïåðåèíèöèàëèçàöèÿ êîíòðîëëåðà ïðåðûâàíèé
    out 20h,al                                  ;Ïåðåèíèöèàëèçèðóåì âåäóùèé êîíòðîëëåð
    out 0A0h,al                                 ;Ïåðåèíèöèàëèçèðóåì âåäîìûé êîíòðîëëåð
    mov al,8h                                   ;ICW2 - íîìåð áàçîâîãî âåêòîðà ïðåðûâàíèé
    out 21h,al                                  ;âåäóùåãî êîíòðîëëåðà
    mov al,70h                                  ;ICW2 - íîìåð áàçîâîãî âåêòîðà ïðåðûâàíèé
    out 0A1h,al                                 ;âåäîìîãî êîíòðîëëåðà
    mov al,04h                                  ;ICW3 - âåäóùèé êîíòðîëëåð ïîäêëþ÷åí ê 3 ëèíèè
    out 21h,al       
    mov al,02h                                  ;ICW3 - âåäîìûé êîíòðîëëåð ïîäêëþ÷åí ê 3 ëèíèè
    out 0A1h,al      
    mov al,11h                                  ;ICW4 - ðåæèì ñïåöèàëüíîé ïîëíîé âëîæåííîñòè äëÿ âåäóùåãî êîíòðîëëåðà
    out 21h,al        
    mov al,01h                                  ;ICW4 - ðåæèì îáû÷íîé ïîëíîé âëîæåííîñòè äëÿ âåäîìîãî êîíòðîëëåðà
    out 0A1h,al
PREPARE_SEGMENTS:                               ;Ïîäãîòîâêà ñåãìåíòíûõ ðåãèñòðîâ äëÿ âîçâðàòà â ðåàëüíûé ðåæèì          
    mov GDT_CODE_RM.LIMIT,0FFFFh                ;Óñòàíîâêà ëèìèòà ñåãìåíòà êîäà â 64KB
    mov GDT_DATA.LIMIT,0FFFFh                   ;Óñòàíîâêà ëèìèòà ñåãìåíòà äàííûõ â 64KB
    mov GDT_STACK.LIMIT,0FFFFh                  ;Óñòàíîâêà ëèìèòà ñåãìåíòà ñòåêà â 64KB
    db  0EAH                                    ;Ïåðåçàãðóçèòü ðåãèñòð cs
    dw  $+4
    dw  CODE_RM_DESC                            ;Íà ñåãìåíò êîäà ðåàëüíîãî ðåæèìà
    mov ax,DATA_DESC                            ;Çàãðóçèì ñåãìåíòíûå ðåãèñòðû äåñêðèïòîðîì ñåãìåíòà äàííûõ
    mov ds,ax                                   
    mov es,ax                                   
    mov fs,ax                                   
    mov gs,ax                                   
    mov ax,STACK_DESC
    mov ss,ax                                   ;Çàãðóçèì ðåãèñòð ñòåêà äåñêðèïòîðîì ñòåêà
ENABLE_REAL_MODE:                               ;Âêëþ÷èì ðåàëüíûé ðåæèì
    mov eax,cr0
    and al,11111110b                            ;Îáíóëèì 0 áèò ðåãèñòðà cr0
    mov cr0,eax                        
    db  0EAH
    dw  $+4
    dw  CODE_RM                                 ;Ïåðåçàãðóçèì ðåãèñòð êîäà
    mov ax,STACK_A
    mov ss,ax                      
    mov ax,DATA
    mov ds,ax                      
    mov es,ax
    xor ax,ax
    mov fs,ax
    mov gs,ax
    mov IDTR.LIMIT, 3FFH                
    mov dword ptr  IDTR+2, 0            
    lidt fword ptr IDTR                 
REPEAIR_MASK:                                   ;Âîññòàíîâèòü ìàñêè ïðåðûâàíèé
    mov al,INT_MASK_M
    out 21h,al                                  ;Âåäóùåãî êîíòðîëëåðà
    mov al,INT_MASK_S
    out 0A1h,al                                 ;Âåäîìîãî êîíòðîëëåðà
ENABLE_INTERRUPTS:                              ;Ðàçðåøèòü ìàñêèðóåìûå è íåìàñêèðóåìûå ïðåðûâàíèÿ
    in  al,70h	
	and	al,01111111b                            ;Óñòàíîâèòü 7 áèò â 0 äëÿ ðàçðåøåíèÿ íåìàñêèðóåìûõ ïðåðûâàíèé
	out	70h,al
    nop
    sti                                         ;Ðàçðåøèòü ìàñêèðóåìûå ïðåðûâàíèÿ
DISABLE_A20:                                    ;Çàêðûòü âåíòèëü A20
    in  al,92h
    and al,11111101b                            ;Îáíóëèòü 1 áèò - çàïðåòèòü ëèíèþ A20
    out 92h, al
EXIT:                                           ;Âûõîä èç ïðîãðàììû
    mov ax,3h
    int 10H                                     ;Î÷èñòèòü âèäåî-ðåæèì    
    lea dx,MSG_HELLO_RM
    mov ah,9h
    int 21h                                     ;Âûâåñòè ñîîáùåíèå
    jmp START
END_PROG:
    mov ax,4C00h
    int 21H                                     ;Âûõîä â dos
SIZE_CODE_RM    = ($ - CODE_RM_BEGIN)           ;Ëèìèò ñåãìåíòà êîäà
CODE_RM ends
;Ñåãìåíò êîäà ðåàëüíîãî ðåæèìà
CODE_PM  segment para use32
CODE_PM_BEGIN   = $
    assume cs:CODE_PM,ds:DATA,es:DATA           ;Óêàçàíèå ñåãìåíòîâ äëÿ êîìïèëÿöèè
ENTER_PM:                                       ;Òî÷êà âõîäà â çàùèùåííûé ðåæèì
    call CLRSCR                                 ;Ïðîöåäóðà î÷èñòêè ýêðàíà
    xor  edi,edi                                ;Â edi ñìåùåíèå íà ýêðàíå
    lea  esi,MSG_HELLO_PM                       ;Â esi àäðåñ áóôåðà
    call BUFFER_OUTPUT                          ;Âûâåñòè ñòðîêó-ïðèâåòñòâèå â çàùèùåííîì ðåæèìå
    add  edi,160                                ;Ïåðåâåñòè êóðñîð íà ñëåäóþùóþ ñòðîêó
    lea  esi,MSG_KEYBOARD
    call BUFFER_OUTPUT                          ;Âûâåñòè ïîëå äëÿ âûâîäà ñêàí-êîäà êëàâèàòóðû
WAITING_ESC:                                    ;Îæèäàíèå íàæàòèÿ êíîïêè âûõîäà èç çàùèùåííîãî ðåæèìà
    jmp  WAITING_ESC                            ;Åñëè áûë íàæàò íå ESC
EXIT_PM:                                        ;Òî÷êà âûõîäà èç 32-áèòíîãî ñåãìåíòà êîäà    
    db 66H
    retf                                        ;Ïåðåõîä â 16-áèòíûé ñåãìåíò êîäà
EXIT_FROM_INTERRUPT:                            ;Òî÷êà âûõîäà äëÿ âûõîäà íàïðÿìóþ èç îáðàáîò÷èêà ïðåðûâàíèé
    popad
    pop es
    pop ds
    pop eax                                     ;Ñíÿòü ñî ñòåêà ñòàðûé EIP
    pop eax                                     ;CS  
    pop eax                                     ;È EFLAGS
    sti                                         ;Îáÿçàòåëüíî, áåç ýòîãî îáðàáîòêà àïïàðàòíûõ ïðåðûâàíèé îòêëþ÷åíà
    db 66H
    retf                                        ;Ïåðåõîä â 16-áèòíûé ñåãìåíò êîäà    
M = 0                           
IRPC N, 0123456789ABCDEF
EXC_0&N label word                              ;Îáðàáîò÷èêè èñêëþ÷åíèé
    cli 
    jmp EXC_HANDLER
endm
M = 010H
IRPC N, 0123456789ABCDEF                        ;Îáðàáîò÷èêè èñêëþ÷åíèé
EXC_1&N label word                          
    cli
    jmp EXC_HANDLER
endm
EXC_HANDLER proc near                           ;Ïðîöåäóðà âûâîäà îáðàáîòêè èñêëþ÷åíèé
    call CLRSCR                                 ;Î÷èñòêà ýêðàíà
    lea  esi, MSG_EXC
    mov  edi, 40*2
    call BUFFER_OUTPUT                          ;Âûâîä ïðåäóïðåæäåíèÿ
    pop eax                                     ;Ñíÿòü ñî ñòåêà ñòàðûé EIP
    pop eax                                     ;CS  
    pop eax                                     ;È EFLAGS
    sti                                         ;Îáÿçàòåëüíî, áåç ýòîãî îáðàáîòêà àïïàðàòíûõ ïðåðûâàíèé îòêëþ÷åíà
    db 66H
    retf                                        ;Ïåðåõîä â 16-áèòíûé ñåãìåíò êîäà    
EXC_HANDLER     ENDP
DUMMY_IRQ_MASTER proc near                      ;Çàãëóøêà äëÿ àïïàðàòíûõ ïðåðûâàíèé âåäóùåãî êîíòðîëëåðà
    push eax
    mov  al,20h
    out  20h,al
    pop  eax
    iretd
DUMMY_IRQ_MASTER endp
DUMMY_IRQ_SLAVE  proc near                      ;Çàãëóøêà äëÿ àïïàðàòíûõ ïðåðûâàíèé âåäîìîãî êîíòðîëëåðà
    push eax
    mov  al,20h
    out  20h,al
    out  0A0h,al
    pop  eax
    iretd
DUMMY_IRQ_SLAVE  endp
KEYBOARD_HANDLER proc near                      ;Îáðàáîò÷èê ïðåðûâàíèÿ êëàâèàòóðû
    push ds
    push es
    pushad                                      ;Ñîõðàíèòü ðàñøèðåííûå ðåãèñòðû îáùåãî íàçíà÷åíèÿ
    in   al,60h                                 ;Ñ÷èòàòü ñêàí êîä ïîñëåäíåé íàæàòîé êëàâèøè                                ;
    cmp  al, 1                                  ;Åñëè áûë íàæàò 'ESC'
    jne   KEYBOARD_RETURN                        
    mov  al,20h                                 ;Òîãäà íà âûõîä èç çàùèùåííîãî ðåæèìà   
    out  20h,al
    db 0eah
    dd OFFSET EXIT_FROM_INTERRUPT 
    dw CODE_PM_DESC  
KEYBOARD_RETURN:
    mov  al,20h
    out  20h,al                                 ;Îòïàðâêà ñèãíàëà êîíòðîëëåðó ïðåðûâàíèé
    popad                                       ;Âîññòàíîâèòü çíà÷åíèÿ ðåãèñòðîâ
    pop es
    pop ds
    iretd                                       ;Âûõîä èç ïðåðûâàíèÿ
KEYBOARD_HANDLER endp
CLRSCR  proc near                               ;Ïðîöåäóðà î÷èñòêè êîíñîëè
    push es
    pushad
    mov  ax,TEXT_DESC                           ;Ïîìåñòèòü â ax äåñêðèïòîð òåêñòà
    mov  es,ax
    xor  edi,edi
    mov  ecx,80*25                              ;Êîëè÷åñòâî ñèìâîëîâ â îêíå
    mov  ax,700h
    rep  stosw
    popad
    pop  es
    ret
CLRSCR  endp
BUFFER_OUTPUT proc near                         ;Ïðîöåäóðà âûâîäà òåêñòîâîãî áóôåðà, îêàí÷èâàþùåãîñÿ 0
    push es
    pushad
    mov  ax,TEXT_DESC                           ;Ïîìåñòèòü â es ñåëåêòîð òåêñòà
    mov  es,ax
OUTPUT_LOOP:                                    ;Öèêë ïî âûâîäó áóôåðà
    lodsb                                       
    or   al,al
    jz   OUTPUT_EXIT                            ;Åñëè äîøëî äî 0, òî êîíåö âûõîäà
    stosb
    inc  edi
    jmp  OUTPUT_LOOP
OUTPUT_EXIT:                                    ;Âûõîä èç ïðîöåäóðû âûâîäà
    popad
    pop  es
    ret
BUFFER_OUTPUT ENDP
SIZE_CODE_PM     =       ($ - CODE_PM_BEGIN)
CODE_PM  ENDS
;Ñåãìåíò äàííûõ ðåàëüíîãî/çàùèùåííîãî ðåæèìà
DATA    segment para use16                      ;Ñåãìåíò äàííûõ ðåàëüíîãî/çàùèùåííîãî ðåæèìà
DATA_BEGIN      = $
    ;GDT - ãëîáàëüíàÿ òàáëèöà äåñêðèïòîðîâ
    GDT_BEGIN   = $
    GDT label   word                            ;Ìåòêà íà÷àëà GDT (GDT: íå ðàáîòàåò)
    GDT_0       S_DESC <0,0,0,0,0,0>                              
    GDT_GDT     S_DESC <GDT_SIZE-1,,,ACS_DATA,0,>                 
    GDT_CODE_RM S_DESC <SIZE_CODE_RM-1,,,ACS_CODE,0,>             
    GDT_DATA    S_DESC <SIZE_DATA-1,,,ACS_DATA+ACS_DPL_3,0,>      
    GDT_STACK   S_DESC <1000h-1,,,ACS_DATA,0,>                    
    GDT_TEXT    S_DESC <2000h-1,8000h,0Bh,ACS_DATA+ACS_DPL_3,0,0> 
    GDT_CODE_PM S_DESC <SIZE_CODE_PM-1,,,ACS_CODE+ACS_READ,0,>    
    GDT_IDT     S_DESC <SIZE_IDT-1,,,ACS_IDT,0,>                  
    GDT_SIZE    = ($ - GDT_BEGIN)               ;Ðàçìåð GDT
    ;Ñåëëåêòîðû ñåãìåíòîâ
    CODE_RM_DESC = (GDT_CODE_RM - GDT_0)
    DATA_DESC    = (GDT_DATA - GDT_0)      
    STACK_DESC   = (GDT_STACK - GDT_0)
    TEXT_DESC    = (GDT_TEXT - GDT_0)  
    CODE_PM_DESC = (GDT_CODE_PM - GDT_0)
    IDT_DESC     = (GDT_IDT - GDT_0)
    ;IDT - òàáëèöà äåñêðèïòîðîâ ïðåðûâàíèé
    IDTR    R_IDTR  <SIZE_IDT,0,0>              ;Ôîðìàò ðåãèñòðà ITDR   
    IDT label   word                            ;Ìåòêà íà÷àëà IDT
    IDT_BEGIN   = $
    IRPC    N, 0123456789ABCDEF
        IDT_0&N I_DESC <0, CODE_PM_DESC,0,ACS_TRAP,0>            ; 00...0F
    ENDM
    IRPC    N, 0123456789ABCDEF
        IDT_1&N I_DESC <0, CODE_PM_DESC, 0, ACS_TRAP, 0>         ; 10...1F
    ENDM
    IDT_20    I_DESC <0,CODE_PM_DESC,0,ACS_INT,0>
    IDT_KEYBOARD I_DESC <0,CODE_PM_DESC,0,ACS_INT,0>             ;IRQ 1 - ïðåðûâàíèå êëàâèàòóðû
    IRPC    N, 23456789ABCDEF
        IDT_2&N         I_DESC <0, CODE_PM_DESC, 0, ACS_INT, 0>  ; 22...2F
    ENDM
    SIZE_IDT        =       ($ - IDT_BEGIN)
    MSG_HELLO           db "press 'p' to go to the protected mode",13,10,"$"
    MSG_HELLO_PM        db "Botvinnikov, wellcome in protected mode",0
    MSG_HELLO_RM        db "Botvinnikov, wellcome back to real mode",13,10,"$"
    MSG_KEYBOARD        db "press 'ESC' to come back to the real mode",0
    MSG_EXC             db "exception: XX",0
    MSG_EXIT            db "press 'e' to exit",13,10,"$"
    MSG_ERROR           db "incorrect error$"
    HEX_TAB             db "0123456789ABCDEF"   ;Òàáëèöà íîìåðîâ èñêëþ÷åíèé
    ESP32               dd  1 dup(?)            ;Óêàçàòåëü íà âåðøèíó ñòåêà
    INT_MASK_M          db  1 dup(?)            ;Çíà÷åíèå ðåãèñòðà ìàñîê âåäóùåãî êîíòðîëëåðà
    INT_MASK_S          db  1 dup(?)            ;Çíà÷åíèå ðåãèñòðà ìàñîê âåäîìîãî êîíòðîëëåðà 
    
SIZE_DATA   = ($ - DATA_BEGIN)                  ;Ðàçìåð ñåãìåíòà äàííûõ
DATA    ends
;Ñåãìåíò ñòåêà ðåàëüíîãî/çàùèùåííîãî ðåæèìà
STACK_A segment para stack
    db  1000h dup(?)
STACK_A  ends
end START