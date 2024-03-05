@;=                                                          	     	=
@;=== RSI_timer0.s: rutinas para mover los elementos (sprites)		  ===
@;=                                                           	    	=
@;=== Programador tarea 2E: oriol.algar@estudiants.urv.cat			  ===
@;=== Programador tarea 2G: gerard.roman@estudiants.urv.cat			  ===
@;=== Programador tarea 2H: hugo.miranda@estudiants.urv.cat			  ===
@;=                                                       	        	=

.include "../include/candy2_incl.i"

BKG1_MAP_DIR = 0x06000000

@;-- .data. variables (globales) inicializadas ---
.data
		.align 2
		.global update_spr
	update_spr:	.hword	0			@;1 -> actualizar sprites
		.global timer0_on
	timer0_on:	.hword	0 			@;1 -> timer0 en marcha, 0 -> apagado
	divFreq0: .hword	-5727		@;divisor de frecuencia inicial para timer 0
									@; Div_Frec = -(Frec_entrada/Frec_sortida) = -(523.655,96875Hz/(32tics/0,35s))= -(523.655,9875Hz/91,42857Hz)

@;-- .bss. variables (globales) no inicializadas ---
.bss
		.align 2
	divF0: .space	2				@;divisor de frecuencia actual


@;-- .text. c�digo de las rutinas ---
.text	
		.align 2
		.arm

@;TAREAS 2Ea,2Ga,2Ha;
@;rsi_vblank(void); Rutina de Servicio de Interrupciones del retrazado vertical;
@;Tareas 2E,2F: actualiza la posici�n y forma de todos los sprites
@;Tarea 2G: actualiza las metabaldosas de todas las gelatinas
@;Tarea 2H: actualiza el desplazamiento del fondo 3
	.global rsi_vblank
rsi_vblank:
		push {r0-r9,lr}
		
@;Tareas 2Ea
		ldr r3, =update_spr
		ldrh r2, [r3]
		cmp r2, #1 @;mirem si update_spr es 1, si es el cas vol dir que hem d'actualitzar els sprites
		bne .Lfin
		mov r0, #0x07000000 @;li passem la direccio de la OAM del processador de grafics principal
		ldr r1, =n_sprites @;li passem el nombre de sprites totals
		ldr r1, [r1]
		bl SPR_actualizarSprites
		mov r0, #0 @;actualitzem update_spr per indicar que no hi han sprites per actualitzar de moment
		strh r0, [r3]
	
	.Lfin:

@;Tarea 2Ga
		ldr r4, =update_gel @; 
		ldrh r4, [r4]       @; if (update_gel == 0) {
		cmp r4, #0          @;     no cal fer res
		beq .Lend2Ga        @; }

		ldr r0, =BKG1_MAP_DIR     @; R0 = dir(matriu de joc)
		mov r1, #0-1              @; R1 = ID Rows = -1 (al bucle es sumara +1 per fer 0)
		mov r6, #COLUMNS          @; R6 serveix per fer dir(x, y) = dir_base + (y*COLUMNS + x) * gel_tam
		mov r7, #GEL_TAM          @; R7 serveix per fer dir(x, y) = dir_base + (y*COLUMNS + x) * gel_tam
		mov r8, #10               @; R8 = 10 (usat per desar mat_gel[r1][r2].ii = 10)
		ldr r9, =mat_gel          @; R9 = dir(mat_gel[0][0])

	.LgelLoop_y:
		mov r2, #0-1   @; R2 = ID Columns = 0

		add r1, #1       @; if (ID_rows > ROWS) {
		cmp r1, #ROWS    @;     fi tasca 2Ga
		bhs .Lpreend2Ga  @; }

	.LgelLoop_x:
		add r2, #1       @; if (ID_columns > COLUMNS) {
		cmp r2, #COLUMNS @;     seguent fila
		bhs .LgelLoop_y  @; }

		mla r4, r1, r6, r2 @; 
		mul r4, r7         @; r4 = dir(mat_gel[i][j])
		add r4, r9         @; 

		ldrb r5, [r4, #GEL_II] @; if (mat_gel[i][j].ii != 0) {
		cmp r5, #0             @;     seguent de la fila
		bne .LgelLoop_x        @; }
		
		ldrb r3, [r4, #GEL_IM] @; 
		bl fija_metabaldosa    @; mat_gel[r1][r2].ii = 10;
		strb r8, [r4, #GEL_II] @; fija_metabaldosa(matrix, ID_rows (r1), ID_columns (r2), mat_gel[r1][r2].im);

		b .LgelLoop_x

	.Lpreend2Ga:
		mov r0, #0          @;
		ldr r1, =update_gel @; update_gel = 0;
		strh r0, [r1]       @;

	.Lend2Ga:


@;Tarea 2Ha
		ldr r1, =update_bg3
		ldrh r0, [r1]
		cmp r0, #0
		beq .Lfinal_vBlank3
	
		ldr r2, =offsetBG3X
		ldrh r0, [r2]
		mov r0, r0, lsl #8
		ldr r2, =0x04000038			@; REG_BG3X
		str r0, [r2]
		mov r0, #0
		strh r0, [r1]
		
	.Lfinal_vBlank3:
		
		pop {r0-r9,pc}

  


@;TAREA 2Eb;
@;activa_timer0(init); rutina para activar el timer 0, inicializando o no el
@;	divisor de frecuencia seg�n el par�metro init.
@;	Par�metros:
@;		R0 = init; si 1, restablecer divisor de frecuencia original divFreq0
	.global activa_timer0
activa_timer0:
		push {r0-r1, lr}
		
		cmp r0, #0 @;si r0 es 0 que vagi directament a activar el timer
		beq .Lactivartimer0
		ldr r0, =divFreq0 @;copiem el contingut de divFreq0 dins de la variable divF0 i de la variable de E/S del timer0
		ldrh r0, [r0]
		ldr r1, =divF0
		strh r0, [r1]
		ldr r1, =0x04000100 @;carreguem a r0 la direccio de la variable de dades del registre E/S del timer0 (TIMER0_DATA)
		strh r0, [r1]
	
	.Lactivartimer0:
		ldr r0, =timer0_on @;amb aquesta variable indicarem que el timer0 est� activat
		mov r1, #1
		strh r1, [r0]
		ldr r0, =0x04000102	@;carreguem a r0 la direccio de la variable de control del registre E/S del timer0 (TIMER0_CR)
		mov r1, #0b11000001
		strh r1, [r0] @;bit 7 -> timer0 en martxa; bit 6 -> interrupcions habilitades; bits 1 i 0 -> freq�encia d'entrada F/64 on F=33513982(base10) HZ
		
		pop {r0-r1, pc}


@;TAREA 2Ec;
@;desactiva_timer0(); rutina para desactivar el timer 0.
	.global desactiva_timer0
desactiva_timer0:
		push {r0-r1, lr}
		
		ldr r0, =0x04000102 @;carreguem a r0 la direccio de la variablede control del registre E/S del timer0 (TIMER0_CR)
		mov r1, #0b01000001
		strh r1, [r0] @;desactivem el timer0 posant el bit 7 a 0
		
		ldr r0, =timer0_on	@;indiquem que el timer0 s'ha parat
		mov r1, #0
		strh r1, [r0]
		
		pop {r0-r1, pc}



@;TAREA 2Ed;
@;rsi_timer0(); rutina de Servicio de Interrupciones del timer 0: recorre todas
@;	las posiciones del vector vect_elem y, en el caso que el c�digo de
@;	activaci�n (ii) sea mayor o igual a 0, decrementa dicho c�digo y actualiza
@;	la posici�n del elemento (px, py) de acuerdo con su velocidad (vx,vy),
@;	adem�s de mover el sprite correspondiente a las nuevas coordenadas.
@;	Si no se ha movido ning�n elemento, se desactivar� el timer 0. En caso
@;	contrario, el valor del divisor de frecuencia se reducir� para simular
@;  el efecto de aceleraci�n (con un l�mite).
	.global rsi_timer0
rsi_timer0:
		push {r0- r10, lr}
		
		mov r0, #0	@;i=0
		mov r10, #0	@;bool moviment = false
		ldr r3, =n_sprites 
		ldr r4, [r3]
		ldr r3, =vect_elem
		
	.Lwhile:
		cmp r0, r4	@;i<n_sprites (condicio perk entri al bucle)
		bhs .Lfiwhile
		ldrh r5, [r3, #ELE_II] @;carreguem variable .ii de l'estruct
		cmp r5, #0x8000       @; 
		bhs .Lseg�entPosicio @; si no hi han interrupcions o estan desactivades canvia de posici�
		cmp r5, #0            @; Com r5 conte una hword, els negatius son [0x8000 - 0xFFFF]
		beq .Lseg�entPosicio @; 
		sub r5, #1	@;disminueix el nombre d'interrupcions restant
		strh r5, [r3]
		ldrh r6, [r3, #ELE_PX]	@;carreguem els altres elements de l'estruct
		ldrh r7, [r3, #ELE_PY]
		ldrh r8, [r3, #ELE_VX]
		ldrh r9, [r3, #ELE_VY]
		
		cmp r8, #0 @;mirem que hi hagi velocitat (si n'hi ha vol dir que s'ha mogut en l'eix de les x)
		beq .LnomogutX
		add r6, r8	@;px=px+vx (actualitzem posicio segons velocitat)
		mov r10, #1 @;bool moviment = true
		strh r6, [r3, #ELE_PX]
	.LnomogutX:
		
		cmp r9, #0 @;mirem que hi hagi velocitat (si n'hi ha vol dir que s'ha mogut en l'eix de les y)
		beq .LnomogutY
		add r7, r9 @;py=py+vy
		mov r10, #1 @;bool moviment = true
		strh r7, [r3, #ELE_PY]
	.LnomogutY:
		
		mov r1, r6
		mov r2, r7
		bl SPR_moverSprite @;r0 index del sprite que s'ha de moure, r1 = px , r2 = py
	.Lseg�entPosicio:
	
		add r3, #ELE_TAM @;cambiem de posici� del vector vect_elem
		add r0, #1	@; incrementem l'index
		b .Lwhile
	.Lfiwhile:
		
		cmp r10, #0 @;si no hi ha mes moviment desactivem el timer0
		bleq desactiva_timer0
	
		ldr r0, =update_spr @;indiquem amb la variable que s'han d'actualitzar els sprites a la pantalla
		mov r1, #1
		strh r1, [r0]
		ldr r0, =divF0 @;carreguem divisor de freq��ncia actual
		ldrh r1, [r0]
		cmp r1, #-300	@;quan arribi en aquest punt(escollit per mi amb div sortida 1745.519896) deixa d'augmentar el divisor
		addle r1, #256
		strh r1, [r0]
	
		pop {r0-r10, pc}



.end
