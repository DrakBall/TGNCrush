@;=                                                               		=
@;=== candy1_secu.s: rutinas para detectar y elimnar secuencias 	  ===
@;=                                                             	  	=
@;=== Programador tarea 1C: eric.riveiro@estudiants.urv.cat			  ===
@;=== Programador tarea 1D: eric.riveiro@estudiants.urv.cat			  ===
@;=== Programador tarea 2Ib: eric.riveiro@estudiants.urv.cat		  ===
@;=                                                           		   	=



.include "../include/candy1_incl.i"

@; Valors immediats per a utilitzar al comparar bits
MASK_BLOC_S = 0x07
MASK_GEL_S_B = 0x08
MASK_GEL_D_B = 0x10

@;-- .bss. variables (globales) no inicializadas ---
.bss
		.align 2
@; n�mero de secuencia: se utiliza para generar n�meros de secuencia �nicos,
@;	(ver rutinas 'marcar_horizontales' y 'marcar_verticales') 
	num_sec:	.space 1
	

@;-- .text. c�digo de las rutinas ---
.text	
		.align 2
		.arm



@;TAREA 1C;
@; hay_secuencia(*matriz): rutina para detectar si existe, por lo menos, una
@;	secuencia de tres elementos iguales consecutivos, en horizontal o en
@;	vertical, incluyendo elementos +en gelatinas simples y dobles.
@;	Restricciones:
@;		* para detectar secuencias se invocar� la rutina 'cuenta_repeticiones'
@;			(ver fichero "candy1_move.s")
@;	Par�metros:
@;		R0 = direcci�n base de la matriz de juego
@;	Resultado:
@;		R0 = 1 si hay una secuencia, 0 en otro caso

@;	Index Registres:
@;		r0 = indicador de si hi ha secu�ncia
@;		r1 = index de fila
@;		r2 = index de columna
@;		r3 = orientaci� per a cridar a cuenta_repeticiones
@; 		r4 = copia dir base matriu
@;		r5 = valor de la casilla(dir vector, despla�ament de posicions)
@;		r6 = despla�ament de posicions
@;		r7 = ;
@;		r8 = COLUMNS
@;		r9 = pen�ltima fila
@;		r10 = pen�ltima columna
@;		r11 = copia n�mero repeticions
@;		r12 = guardem resultat and
	.global hay_secuencia
hay_secuencia:
		push {r1-r6,r8-r12, lr}
		mov r4, r0			@; copia dir base matriu a r4
		mov r6, #0			@; r6 es el despla�ament de posicions
		mov r1, #0			@; r1 �s index de fila
		mov r9, #ROWS-1     @; pen�ltima fila
		mov r8, #COLUMNS	
		sub r10, r8, #1		@; pen�tlima columna
		.L_for1:
			mov r2, #0			@; r2 �s index de columna
			.L_for2:
				mov r0, #0				@; inicialitzem r0 
				mla r6, r1, r8, r2		@; i*NC +j
				ldrb r5, [r4,r6]		@; r5=valor de la casilla(dir vector, despla�ament)
				tst r5, #MASK_BLOC_S	@; mirem si �s espai buit, gelatina simple o doble buida
				beq .Lend_for2
				and r12, r5, #MASK_BLOC_S	@; mirem si �s bloc solid o buit
				cmp r12, #MASK_BLOC_S
				beq .Lend_for2
				.Lif_col:
					cmp r2, r10				@; comprobem si col_actual �s anterior a la pen�ltima per contar repeticions o no
					bhs .Lif_fila			@; si no, comprobem fila
					mov r0, r4				@; preparem direcci� base matriu
					mov r3, #0				@; indiquem orientaci� per cridar cuenta_repeticiones
					bl cuenta_repeticiones
					cmp r0, #3
					bhs .Lfi1		 		@; si hi ha secu�ncia de 3 o + elements, retornem 1
				.Lif_fila:
					cmp r1, #ROWS       	@; comprobem si fil_actual �s anterior a la �ltima per contar repeticions o no
					bhs .Lend_for1			@; si no, incrementem index
					mov r0, r4				@; preparem direcci� base matriu
					mov r3, #1				@; indiquem orientaci� per cridar cuenta_repeticiones
					bl cuenta_repeticiones
					cmp r0, #3
					bhs .Lfi1				@; si hi ha secu�ncia de 3 o + elements, retornem 1		
			.Lend_for2:
				add r2, #1			@; incrementem index columna
				cmp r2, #COLUMNS			@; si �s anterior a la �ltima, continuem amb el bucle
				blo .L_for2
		.Lend_for1:
			add r1, #1				@; incrementem index fila
			cmp r1, #ROWS				@; si �s anterior a la �ltima, continuem amb el bucle
			blo .L_for1
		.Lfi1:
			mov r11, r0				@; fem copia resultat n�mero secu�ncia
			cmp r0, #3				@; si hi ha secu�ncia retornem 1
			movhs r0, #1
			cmp r11, #3				@; si no hi ha secu�ncia retornem 0
			movlo r0, #0
		pop {r1-r6,r8-r12, pc}


@;TAREA 1D;
@; elimina_secuencias(*matriz, *marcas): rutina para eliminar todas las
@;	secuencias de 3 o m�s elementos repetidos consecutivamente en horizontal,
@;	vertical o combinaciones, as� como de reducir el nivel de gelatina en caso
@;	de que alguna casilla se encuentre en dicho modo; 
@;	adem�s, la rutina marca todos los conjuntos de secuencias sobre una matriz
@;	de marcas que se pasa por referencia, utilizando un identificador �nico para
@;	cada conjunto de secuencias (el resto de las posiciones se inicializan a 0). 
@;	Par�metros:
@;		R0 = direcci�n base de la matriz de juego
@;		R1 = direcci�n de la matriz de marcas

@;	Index Registres:
@;		r0 = dir base matriu joc
@;		r1 = dir base matriu marques/index fila
@;		r2 = index de columna
@;		r3 = valor amb 0 per quan fem strb (eliminar element)
@; 		r4 = copia dir base matriu joc
@;		r5 = valor de la casilla(dir vector, despla�ament de posicions)
@;		r6 = despla�ament de posicions
@;		r7 = ROWS
@;		r8 = despla�ament posicions/COLUMNS
@;		r9 = copia dir base matriu marques
	.global elimina_secuencias
elimina_secuencias:
		push {r2-r11, lr}
		mov r6, #0
		mov r8, #0				@;R8 es desplazamiento posiciones matriz
	.Lelisec_for0:
		strb r6, [r1, r8]		@;poner matriz de marcas a cero
		add r8, #1
		cmp r8, #ROWS*COLUMNS
		blo .Lelisec_for0
		
		bl marcar_horizontales	@; marquem seq��ncies horitzontals i verticals
		bl marcar_verticales
	.L_eliminar:	
		mov r3, #0					@; registre per utilitzar al eliminar
		mov r4, r0					@; copia dir matriu joc 
		mov r9, r1					@; copia dir matriu marques
		mov r6, #0					@; r6 es el despla�ament de posicions
		mov r1, #0					@; r1 �s index de fila
		mov r7, #ROWS
		mov r8, #COLUMNS
		.L_for3:		
			mov r2, #0				@; r2 �s index de columna
			.L_for4:				
				mla r6, r1, r8, r2		@; i*NC +j
				ldrb r5, [r9,r6]		@; r5=valor de la casella matriu marques (dir vector, despla�ament)
				cmp r5, r3				@; si no hi ha marcada seq��ncia avancem posici�
				beq .Lend_for4
				ldrb r5, [r4,r6]		@; r5=valor de la casella matriu joc (dir vector, despla�ament)
				tst r5, #MASK_GEL_D_B	@; si �s gelatina doble saltem a eliminar-la
				bne .Lelim_gel_d
				tst r5, #MASK_GEL_S_B	@; si és gelatina simple la eliminem
				bne .Lelim_gel_s
				beq .Lelim_elem
			.Lelim_gel_s:
				mov r0, r1
				mov r10, r1
				mov r1, r2				@; preparem param per elimina_gelatina
				bl elimina_gelatina     @; eliminem sprite gelatina simple
				push {r0}
				bl elimina_elemento
				pop {r0}
				mov r2, r1				@; retornem còpia seguretat
				mov r1, r10
				strb r3, [r4,r6]		@; posem a 0 l'element o gelatina simple
				b .Lend_for4
			.Lelim_elem:
				mov r0, r1
				mov r10, r1
				mov r1, r2
				bl elimina_elemento 	@; eliminem sprite element
				mov r2, r1
				mov r1, r10				@; retornem còpia seguretat fila i columna
				strb r3, [r4,r6]		@; posem a 0 l'element o gelatina simple
				b .Lend_for4
				.Lelim_gel_d:
					mov r0, r1
					mov r1, r2						@; preparem param per elimina_gelatina
					bl elimina_gelatina 			@; eliminem sprite gelatina doble
					push {r0}
					bl elimina_elemento
					pop {r0}
					mov r2, r1						@; restaurem fila i columna
					mov r1, r0
					mov r5, #0
					orr r5, r5, #MASK_GEL_S_B		@; deixem activat a 1 solament el bit 3 per tindre gel.s.buida
					strb r5, [r4,r6]				@; efectuem reducci� a gel.s.buida
					
			.Lend_for4:
				add r2, #1							@; incrementem index columna
				cmp r2, #COLUMNS					@; si �s anterior a la �ltima, continuem amb el bucle
				blo .L_for4
		.Lend_for3:
			add r1, #1				@; incrementem index fila
			cmp r1, #ROWS			@; si �s anterior a la �ltima, continuem amb el bucle
			blo .L_for3
		.L_fi2:
		mov r0, r4				
		mov r1, r9				@; retornem direccions matrius
		pop {r2-r11, pc}


	
@;:::RUTINAS DE SOPORTE:::



@; marcar_horizontales(mat): rutina para marcar todas las secuencias de 3 o m�s
@;	elementos repetidos consecutivamente en horizontal, con un n�mero identifi-
@;	cativo diferente para cada secuencia, que empezar� siempre por 1 y se ir�
@;	incrementando para cada nueva secuencia, y cuyo �ltimo valor se guardar� en
@;	la variable global 'num_sec'; las marcas se guardar�n en la matriz que se
@;	pasa por par�metro 'mat' (por referencia).
@;	Restricciones:
@;		* se supone que la matriz 'mat' est� toda a ceros
@;		* para detectar secuencias se invocar� la rutina 'cuenta_repeticiones'
@;			(ver fichero "candy1_move.s")
@;	Par�metros:
@;		R0 = direcci�n base de la matriz de juego
@;		R1 = direcci�n de la matriz de marcas

@;	Index Registres:
@;		r0 = direcci� matriu joc/ valor repeticions
@;		r1 = index de fila
@;		r2 = index de columna
@;		r3 = orientaci� per a cridar a cuenta_repeticiones
@; 		r4 = copia dir base matriu
@;		r5 = valor de la casilla(dir vector, despla�ament de posicions)
@;		r6 = despla�ament de posicions
@;		r7 = ROWS
@;		r8 = COLUMNS
@;		r9 = copia dir matriu marques 
@;		r10 = identificador seq��ncia
@;		r11 = direcci� num_sec per guardar �ltim identificador
@;		r12 = comptador identificacions
marcar_horizontales:
		push {r2-r12, lr}
		mov r4, r0			@; copia dir matriu joc 
		mov r9, r1			@; copia dir matriu marques
		mov r6, #0			@; r6 es el despla�ament de posicions
		mov r1, #0			@; r1 �s index de fila
		mov r7, #ROWS
		mov r8, #COLUMNS
		mov r10, #1			@; inicialitzem identificador
		.L_for5:		
			mov r2, #0				@; r2 �s index de columna
			.L_for6:				
				mla r6, r1, r8, r2		@; i*NC +j
				ldrb r5, [r4,r6]		@; r5=valor de la casella matriu joc (dir vector, despla�ament)
				tst r5, #MASK_BLOC_S	@; mirem si �s espai buit, gelatina simple o doble buida
				beq .Lend_for6
				and r0, r5, #MASK_BLOC_S	@; mirem si �s bloc solid o buit
				cmp r0, #MASK_BLOC_S
				beq .Lend_for6
				.L_reps:
					mov r0, r4				@; preparem direcci� base matriu joc
					mov r3, #0				@; indiquem orientaci� per cridar cuenta_repeticiones
					bl cuenta_repeticiones
					cmp r0, #3				@; si no hi ha repetici� no cal fer res a matriu marques
					blo .Lend_for6
					mov r12, #0				@; inicialitzem comptador identificacions
					sub r2, #1				@; per evitar aven�os de m�s restem una columna ara i ja dins del bucle es va actualitzant
					.L_marc_ident:
						add r2, #1				@; avancem per marcar seg�ent posici�
						mla r6, r1, r8, r2		@; i*NC +j
						strb r10, [r9, r6]		@; posem identificador a la matriu de marques
						add r12, #1				@; incrementem comptador identificacions
						cmp r12, r0				@; si encara queden m�s caselles per identificar tornem a entrar a L_marc_ident
						blo .L_marc_ident
						add r10, #1				@; actualitzem identificador per a la seg�ent seq
			.Lend_for6:
				add r2, #1			@; incrementem index columna
				cmp r2, #COLUMNS	@; si �s anterior a la �ltima, continuem amb el bucle
				blo .L_for6
		.Lend_for5:
			add r1, #1				@; incrementem index fila
			cmp r1, #ROWS			@; si �s anterior a la �ltima, continuem amb el bucle
			blo .L_for5
		.L_fi3:
		ldrb r11, =num_sec
		strb r10, [r11]			@; guardem a mem�ria l'�ltim identificador de secu�ncia
		mov r0, r4				
		mov r1, r9				@; retornem direccions matrius
		pop {r2-r12, pc}



@; marcar_verticales(mat): rutina para marcar todas las secuencias de 3 o m�s
@;	elementos repetidos consecutivamente en vertical, con un n�mero identifi-
@;	cativo diferente para cada secuencia, que seguir� al �ltimo valor almacenado
@;	en la variable global 'num_sec'; las marcas se guardar�n en la matriz que se
@;	pasa por par�metro 'mat' (por referencia);
@;	sin embargo, habr� que preservar los identificadores de las secuencias
@;	horizontales que intersecten con las secuencias verticales, que se habr�n
@;	almacenado en en la matriz de referencia con la rutina anterior.
@;	Restricciones:
@;		* se supone que la matriz 'mat' est� marcada con los identificadores
@;			de las secuencias horizontales
@;		* la variable 'num_sec' contendr� el siguiente indentificador (>=1)
@;		* para detectar secuencias se invocar� la rutina 'cuenta_repeticiones'
@;			(ver fichero "candy1_move.s")
@;	Par�metros:
@;		R0 = direcci�n base de la matriz de juego
@;		R1 = direcci�n de la matriz de marcas

@;	Index Registres:
@;		r0 = direcci� matriu joc/ valor repeticions
@;		r1 = index de fila
@;		r2 = index de columna
@;		r3 = orientaci� per a cridar a cuenta_repeticiones/ index fila auxiliar per a creuats
@; 		r4 = copia dir base matriu
@;		r5 = valor de la casilla(dir vector, despla�ament de posicions)
@;		r6 = despla�ament de posicions
@;		r7 = ROWS
@;		r8 = COLUMNS
@;		r9 = copia dir matriu marques 
@;		r10 = identificador seq��ncia
@;		r11 = comptador identificador
@;		r12 = identificador creuat
marcar_verticales:
		push {r2-r12, lr}
		mov r4, r0			@; copia dir matriu joc 
		mov r9, r1			@; copia dir matriu marques
		mov r6, #0			@; r6 es el despla�ament de posicions
		mov r2, #0			@; r2 �s index de columna
		mov r7, #ROWS
		mov r8, #COLUMNS
		ldrb r10, =num_sec
		ldrb r10, [r10]			@; inicialitzem identificador 
		.L_for7:		
			mov r1, #0				@; r1 �s index de fila
			.L_for8:				
				mla r6, r1, r8, r2		@; i*NC +j
				ldrb r5, [r4,r6]		@; r5=valor de la casella matriu joc (dir vector, despla�ament)
				tst r5, #MASK_BLOC_S	@; mirem si �s espai buit, gelatina simple o doble buida
				beq .Lend_for8
				and r0, r5, #MASK_BLOC_S	@; mirem si �s bloc solid o buit
				cmp r0, #MASK_BLOC_S
				beq .Lend_for8
				.L_reps_1:
					mov r0, r4				@; preparem direcci� base matriu
					mov r3, #1				@; indiquem orientaci� per cridar cuenta_repeticiones
					bl cuenta_repeticiones
					cmp r0, #3				@; si no hi ha repetici� no cal fer res a matriu marques
					blo .Lend_for8
					mov r11, #0				@; inicialitzem comptador identificacions
					sub r1, #1				@; per evitar aven�os de m�s restem una fila ara i ja dins del bucle es va actualitzant
					.L_marc_ident_1:
						add r1, #1				@; avancem per marcar seg�ent posici�
						mla r6, r1, r8, r2		@; i*NC +j
						ldrb r5, [r9,r6]		@; comprobem si no ens creuem amb sec.horiz
						cmp r5, #0				@; si no �s 0 vol dir que ens hem creuat
						bne .L_marc_ident_creuat
						strb r10, [r9, r6]		@; posem identificador a la matriu de marques
						add r11, #1			
						cmp r11, r0				@; si encara queden m�s caselles per identificar tornem a entrar a .L_marc_ident
						blo .L_marc_ident_1
						add r10, #1				@; actualitzem identificador per a la seg�ent seq
						b .Lend_for8
					.L_marc_ident_creuat:
						mov r12, r5				@; actualitzem identificador creuats 
						mov r11, #1				@; reiniciem comptador identificacions
						mov r3, r1				@; treballem amb copia index files
							.L_sup:
								sub r3, #1					@; restem una fila per evitar aven�os de m�s
								mla r6, r3, r8, r2
								ldrb r5, [r9,r6]			@; si la casella superior a la actual = 0 anem .L_inf
								cmp r5, #0
								beq .L_inf
								sub r12, #1
								cmp r5, r12
								beq .L_inf
								add r12, #1
								strb r12, [r9, r6]			@; posem identificador a la matriu de marques
								add r11, #1					@; actualitzem comptador identificacions
								cmp r0, r11
								beq .Lend_for8				@; si el comptador d'identificacions=repeticions vol dir que ja podem avan�ar posici� a la matriu de joc
								b .L_sup
							.L_inf:
								add r3, #1					@; afegim fila per avan�ar cap baix
								mla r6, r3, r8, r2
								ldrb r5, [r9, r6]			@; si la casella �s creuada tornem a entrar a .L_inf
								add r12, #1
								cmp r5, r12
								beq .L_inf
								strb r12, [r9, r6]			@; posem identificador a la amtriu de marques
								add r11, #1					@; actualitzem comptador identificacions
								cmp r0, r11					@; si el comptador d'identificacions=repeticions vol dir que ja podem avan�ar posici� a la matriu de joc
								beq .Lend_for8
								b .L_inf
			.Lend_for8:		
				add r1, #1			@; incrementem index fil
				cmp r1, #ROWS			@; si �s anterior a la �ltima, continuem amb el bucle
				blo .L_for8
		.Lend_for7:
			add r2, #1				@; incrementem index col
			cmp r2, #COLUMNS				@; si �s anterior a la �ltima, continuem amb el bucle
			blo .L_for7
		.L_fi4:
			mov r0, r4
			mov r1, r9				@; retornem direccions matrius
		pop {r2-r12, pc}
		
.end