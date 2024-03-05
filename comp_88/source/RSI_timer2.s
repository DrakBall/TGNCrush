@;=                                                          	     	=
@;=== RSI_timer2.s: rutinas para animar las gelatinas (metabaldosas)  ===
@;=                                                           	    	=
@;=== Programador tarea 2G: gerard.roman@estudiants.urv.cat			  ===
@;=                                                       	        	=

.include "../include/candy2_incl.i"

TIMER2_DATA = 0x04000108
TIMER2_CR = 0x0400010A

@;-- .data. variables (globales) inicializadas ---
.data
		.align 2
		.global update_gel
	update_gel:	.hword	0			@;1 -> actualizar gelatinas
		.global timer2_on
	timer2_on:	.hword	0 			@;1 -> timer2 en marcha, 0 -> apagado
	divFreq2: .hword	-5237 		@;divisor de frecuencia para timer 2



@;-- .text. c�digo de las rutinas ---
.text	
		.align 2
		.arm


@;TAREA 2Gb;
@;activa_timer2(); rutina para activar el timer 2.
	.global activa_timer2
activa_timer2:
		push {r0-r2,lr}
		
		ldr r0, =timer2_on @;
		mov r1, #1         @; timer2_on = true;
		strh r1, [r0]      @;

		ldr r0, =TIMER2_DATA @; 
		ldr r1, =divFreq2    @; 
		ldrh r1, [r1]        @; TIMER2_DATA = divFreq2 (+13170)
		str r1, [r0]         @; 

		ldr r0, =TIMER2_CR  @; 
		ldrh r1, [r0]       @; 
		orr r1, #0b11000001 @; 
		ldr r2, =0xFFF9     @; TIMER2_CR = 0bxxxxxxxx 1 1 xxx 0 01
		and r1, r2          @; 
		strh r1, [r0]       @; 
		
		pop {r0-r2,pc}


@;TAREA 2Gc;
@;desactiva_timer2(); rutina para desactivar el timer 2.
	.global desactiva_timer2
desactiva_timer2:
		push {r0-r2,lr}
		
		ldr r0, =timer2_on @;
		mov r1, #0         @; timer2_on = false;
		strh r1, [r0]      @;

		ldr r0, =TIMER2_CR @; 
		ldrh r1, [r0]      @; 
		ldr r2, =0xFF7F    @; TIMER2_CR = 0bxxxxxxxxx 0 xxxxxxx
		and r1, r2         @; 
		strh r1, [r0]      @; 
		
		pop {r0-r2,pc}



@;TAREA 2Gd;
@;rsi_timer2(); rutina de Servicio de Interrupciones del timer 2: recorre todas
@;	las posiciones de la matriz mat_gel y, en el caso que el c�digo de
@;	activaci�n (ii) sea mayor o igual a 1, decrementa dicho c�digo en una unidad
@;	y, en el caso que alguna llegue a 0, incrementa su c�digo de metabaldosa y
@;	activa una variable global update_gel para que la RSI de VBlank actualize
@;	la visualizaci�n de dicha metabaldosa.
	.global rsi_timer2
rsi_timer2:
		push {r0-r4,lr}

		ldr r0, =mat_gel-GEL_TAM  @; R0 = dir(mat_gel[0][0])
		mov r3, #0                @; R3 = update_gel ja ha estat modificada?
		ldr r4, =mat_gel+ROWS*COLUMNS*GEL_TAM  @; R4 = max(dir(mat_gel[][]));

	.Ltimer2_gelLoop:
		add r0, #GEL_TAM  @; if (r0 > dir(mat_gel[ROWS][COLUMNS])) {
		cmp r0, r4        @;     fi d'actualitzacio
		bhs .Ltimer2_end  @; }

		ldrb r1, [r0, #GEL_II]  @; if (mat_gel[i][j].ii == -1) {
		cmp r1, #0xFF           @;     seguent element
		beq .Ltimer2_gelLoop    @; }

		cmp r1, #0              @; 
		beq .Ltimer2_skipIImod  @; if (mat_gel[i][j].ii > 0) {
		sub r1, #1              @;     mat_gel[i][j].ii -= 1;
		strb r1, [r0, #GEL_II]  @;     seguent element
		b .Ltimer2_gelLoop      @; }

	.Ltimer2_skipIImod:
		ldrb r1, [r0, #GEL_IM] @; 
		and r2, r1, #0x7       @; 
		and r1, #0x8           @; mat_gel[i][j].im += 1;
		add r2, #1             @; mat_gel[i][j].im % 8;
		and r2, #0x7           @; mat_gel[i][j].im += (doble_gel) ? 8 : 0;
		add r1, r2             @; 
		strb r1, [r0, #GEL_IM] @; 

		cmp r3, #1           @; 
		beq .Ltimer2_gelLoop @; 
		ldr r2, =update_gel  @; update_gel = true;
		mov r1, #1           @; (cal evitar escriure en memoria
		str r1, [r2]         @;  ja que es lenta, per això
		mov r3, #1           @;  afegim un registre de control)

		b .Ltimer2_gelLoop
	
	.Ltimer2_end:
		pop {r0-r4,pc}



.end
