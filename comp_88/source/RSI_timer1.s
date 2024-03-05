@;=                                                          	     	=
@;=== RSI_timer1.s: rutinas para escalar los elementos (sprites)	  ===
@;=                                                           	    	=
@;=== Programador tarea 2F: eric.riveiro@estudiants.urv.cat				  ===
@;=                                                       	        	=

.include "../include/candy2_incl.i"


@;-- .data. variables (globales) inicializadas ---
.data
		.align 2
		.global timer1_on
	timer1_on:	.hword	0 			@;1 -> timer1 en marcha, 0 -> apagado
	divFreq1: .hword	-5727		@;divisor de frecuencia para timer 1
						@;calcular divFreq1 para conseguir 32 tic en menos de 0,35s
						@; Div_Frec = -(Frec_Entrada / Frec_Salida)
						@; Div_Frec = -(523.655,96875/91,428)
						@; Frec_Salida = 32/0,35= 91,428 Hz

@;-- .bss. variables (globales) no inicializadas ---
.bss
		.align 2
	escSen: .space	2				@;sentido de escalado (0-> dec, 1-> inc)
	escFac: .space	2				@;Factor actual de escalado
	escNum: .space	2				@;n�mero de variaciones del factor


@;-- .text. c�digo de las rutinas ---
.text	
		.align 2
		.arm


@;TAREA 2Fb;
@;activa_timer1(init); rutina para activar el timer 1, inicializando el sentido
@;	de escalado seg�n el par�metro init.
@;	Par�metros:
@;		R0 = init;  valor a trasladar a la variable 'escSen' (0/1)
	.global activa_timer1
activa_timer1:
		push {r0-r2, lr}
		mov r2, #0
		ldr r1, =escNum		@; fijamos variables escNum a 0
		strh r2, [r1]
		ldr r1, =escSen
		strh r0, [r1]		@; copiamos valor par�metro init en la variable escSen
		cmp r0, #0			@; comprobamos si es un ciclo de incremento o decremento de escalado
		bne .L_end			@; si es un ciclo de incremento no llamamos SPR_fijarEscalado() ya que PA y PD contienen �ltimo valor ciclo decremento
		.L_decrement:
			mov r1, #1
			ldr r2, =escFac
			mov r1, r1, lsl #8		@; pasamos 1 a formato coma fija 0.8.8 en r3
			strh r1, [r2]			@; fijamos variable escFac
			mov r2, r1				@; preparamos parametros (factores de escalado e �ndice grupo rotaci�n-escalado) para SPR_fijarEscalado()
			bl SPR_fijarEscalado	@; llamamos SPR_fijarEscalado() y le trasladamos el factor en coma fija y el grupo 0				
		.L_end:
			mov r1, #1
			ldr r0, =timer1_on
			strh r1, [r0]			@; ponemos a 1 variable timer1_on
			ldr r0, =divFreq1
			ldrh r1, [r0]			@; cargamos divFreq1 en r1
			ldr r0, =0x04000104		@; cargamos direcci�n registro datos TIMER1_DATA
			strh r1, [r0]			@; cargamos divisor de frecuencia en reg E/S de datos timer1 para inicializarlo 
			ldr r0, =0x04000106		@; cargamos direcci�n registro control TIMER1_CR
			mov r1, #0xC1			@; activamos timer mediante su registro de control indicando la frecuencia(bits 0..1)
			strh r1, [r0]			@; e activando las interrupciones(bit 6) y poniendo el timer en marcha(bit 7)
		pop {r0-r2, pc}


@;TAREA 2Fc;
@;desactiva_timer1(); rutina para desactivar el timer 1.
	.global desactiva_timer1
desactiva_timer1:
		push {r0-r1, lr}
		mov r0, #0
		ldr r1, =timer1_on		@; desactivamos variable global timer1	
		strh r0, [r1]
		ldr r0, =0x04000106		@; cargamos direcci�n registro control TIMER1_CR
		mov r1, #0x41
		strh r1, [r0]			@; desactivamos bit 7 para parar el timer 
		pop {r0-r1, pc}



@;TAREA 2Fd;
@;rsi_timer1(); rutina de Servicio de Interrupciones del timer 1: incrementa el
@;	n�mero de escalados y, si es inferior a 32, actualiza factor de escalado
@;	actual seg�n el c�digo de la variable 'escSen'. Cuando se llega al m�ximo
@;	se desactivar� el timer1.
	.global rsi_timer1
rsi_timer1:
		push {r0-r4, lr}
		ldr r0, =escNum			
		ldrh r1, [r0]			@; cargamos variable escNum en r1
		add r1, #1				@; incrementamos variable escNum
		strh r1, [r0]			@; guardamos variable incrementada en memoria
		cmp r1, #32
		blhs desactiva_timer1	@; si ha llegado a los 32 tics invocamos desactiva_timer1() para apagar timer1
		bhs .L_endrsi
	.L_no32tics:
		ldr r4, =escFac
		ldrh r2, [r4]			@; cargamos factor actual escalado
		ldr r0, =escSen
		ldrh r1, [r0]			@; cargamos sentido escalado actual
		cmp r1, #0				@; comprobamos sentido de escalado actual
		mov r3, #60
		addeq r2, r3			@; incrementamos factor escalado actual
		subne r2, r3			@; decrementamos factor escalado actual
		@; mov r2, r2, lsl #8	AL INCREMENTAR FACTOR ESCALADO VOLVER A PASAR A COMA FIJA?
		strh r2, [r4]			@; fijamos factor escalado en la variable global
		mov r1, r2
		mov r0, #0				@; preparamos parametros SPR_fijarEscalado() (�ndice grupo 0 y factor escalado actual)
		bl SPR_fijarEscalado
		mov r1, #1
		ldr r0, =update_spr
		strh r1, [r0]			@; activamos variable update_spr para provocar actualizaci�n reg E/S de los sprites en OAM
	.L_endrsi:
		pop {r0-r4, pc}
		
.end
