@;=                                                               		=
@;=== candy1_combi.s: rutinas para detectar y sugerir combinaciones   ===
@;=                                                               		=
@;=== Programador tarea 1G: hugo.miranda@estudiants.urv.cat			  ===
@;=== Programador tarea 1H: hugo.miranda@estudiants.urv.cat			  ===
@;=                                                             	 	=



.include "../include/candy1_incl.i"

ELEMENT_TYPE = 0b111


@;-- .text. c�digo de las rutinas ---
.text	
		.align 2
		.arm


@;TAREA 1G;
@; hay_combinacion(*matriz): rutina para detectar si existe, por lo menos, una
@;	combinaci�n entre dos elementos (diferentes) consecutivos que provoquen
@;	una secuencia v�lida, incluyendo elementos en gelatinas simples y dobles.
@;	Par�metros:
@;		R0 = direcci�n base de la matriz de juego
@;	Resultado:
@;		R0 = 1 si hay una secuencia, 0 en otro caso
	.global hay_combinacion
hay_combinacion:
		push {r1-r5, r7-r12, lr}
		
		mov r4, r0 				@; r4 = Direcci� base de matriu
		mov r1, #0 				@; r1 = �ndex Files
		mov r2, #0 				@; r2 = �ndex Columnes
		mov r3, #0 				@; r3 = �ndex Despla�ament
		mov r11, #ROWS			@; Dimensi� COLUMNES i FILES:
		mov r12, #COLUMNS		@; 			(9x9)
		
		b .LvalidarActual
		
		.Lwhile:
			add r1, #1
			
			.LvalidarActual:
				ldrb r7, [r4, r3] 		@; r7 = Element actual
				mov r5, r7
				cmp r5, #7				@; Comprovaci� bloc s�lid
				beq .Lendwhile
				cmp r5, #15				@; Comprovaci� hueco
				beq .Lendwhile
				and r5, #ELEMENT_TYPE	@; M�scara filtra els tres bits baixos, per si es 8 o 16, que equivalgui a 0
				cmp r5, #0
				beq .Lendwhile
			.LendvalidarActual:
			
			.LcheckLastCOLUMN:
				sub r9, r12, #1
				cmp r2, r9
				bge .LcheckLastROW
			.LendcheckLastCOLUMN:
			
			.LposteriorIgual_HORITZONTAL:
				add r3, #1					@; Despla�ament relatiu a la casella pr�xima
				ldrb r8, [r4, r3] 			@; r8 = Element casella posterior horizontal (relatiu)
				sub r3, #1
				cmp r7, r8
				beq .LcheckLastROW
			.LendposteriorIgual_HORITZONTAL:
			
			.LvalidarPosterior_HORITZONTAL:
				cmp r8, #0	
				beq .LcheckLastROW
				cmp r8, #7	
				beq .LcheckLastROW
				cmp r8, #8	
				beq .LcheckLastROW
				cmp r8, #15	
				beq .LcheckLastROW
				cmp r8, #16	
				beq .LcheckLastROW
			.LendvalidarPosterior_HORITZONTAL:
			
			@; Intercanvi HORITZONTAL
				strb r8, [r4, r3]
				add r3, #1
				strb r7, [r4, r3]
				sub r3, #1
				
			@; Comprovar elements seguits en 1� casella
				bl detectar_orientacion
				cmp r0, #6
				bne .LelementsSeguitsTrobats_HORITZONTAL
				
			@; Comprovar elements seguits en 2� casella
				add r2, #1
				bl detectar_orientacion
				sub r2, #1
				cmp r0, #6
				bne .LelementsSeguitsTrobats_HORITZONTAL
				
			@; Cancel intercanvi HORITZONTAL
				strb r7, [r4, r3]
				add r3, #1
				strb r8, [r4, r3]
				sub r3, #1
			
			.LcheckLastROW:
				sub r9, r11, #1
				cmp r1, r9
				bge .Lendwhile
			.LendcheckLastROW:
			
			.LposteriorIgual_VERTICAL:
				add r3, r12				@; Posici� inferior (relativa)
				ldrb r10, [r4, r3] 		@; r10 = Element casella posterior vertical
				sub r3, r12
				cmp r7, r10
				beq .Lendwhile
			.LendposteriorIgual_VERTICAL:
			
			.LvalidarPosterior_VERTICAL:
				cmp r10, #0	
				beq .Lendwhile
				cmp r10, #7	
				beq .Lendwhile
				cmp r10, #8	
				beq .Lendwhile
				cmp r10, #15
				beq .Lendwhile
				cmp r10, #16	
				beq .Lendwhile
			.LendvalidarPosterior_VERTICAL:
			
			@; Intercanvi vertical
				strb r10, [r4, r3]
				add r3, r12	
				strb r7, [r4, r3]
				sub r3, r12 			
				
				
			@; Comprovar primera casella
				bl detectar_orientacion
				cmp r0, #6
				bne .LelementsSeguitsTrobats_VERTICAL
				
			@; Comprovar segona casella
				add r1, #1
				bl detectar_orientacion
				sub r1, #1
				cmp r0, #6
				bne .LelementsSeguitsTrobats_VERTICAL
				
			@; Desfer intercanvi vertical
				strb r7, [r4, r3]
				add r3, r12
				strb r10, [r4, r3]
				sub r3, r12
			b .Lendwhile
			
			.LelementsSeguitsTrobats_HORITZONTAL:
				@; Desfer intercanvi horitzontal
				strb r7, [r4, r3]
				add r3, #1
				strb r8, [r4, r3]
				sub r3, #1
				
				mov r0, #1							@; Retorna r0 = 1 (TRUE) si troba combinaci� horitzontal
				b .Lfi
			.LendelementsSeguitsTrobats_HORITZONTAL:
			
			.LelementsSeguitsTrobats_VERTICAL:
				@; Desfer intercanvi vertical
				strb r7, [r4, r3]
				add r3, r12
				strb r10, [r4, r3]
				sub r3, r12
				
				mov r0, #1							@; Retorna r0 = 1 (TRUE) si troba combinaci� vertical
				b .Lfi
			.LendelementsSeguitsTrobats_VERTICAL:
			
		.Lendwhile:
		mov r0, #0
		add r3, #1
		add r2, #1
		
		sub r9, r12, #1	
		cmp r2, r9
		ble .LvalidarActual
		
		mov r2, #0
		
		sub r9, r11, #1
		cmp r1, r9
		blt .Lwhile
		
	.Lfi:
		
		pop {r1-r5, r7-r12, pc}



@;TAREA 1H;
@; sugiere_combinacion(*matriz, *sug): rutina para detectar una combinaci�n
@;	entre dos elementos (diferentes) consecutivos que provoquen una secuencia
@;	v�lida, incluyendo elementos en gelatinas simples y dobles, y devolver
@;	las coordenadas de las tres posiciones de la combinaci�n (por referencia).
@;	Restricciones:
@;		* se supone que existe por lo menos una combinaci�n en la matriz
@;			 (se debe verificar antes con la rutina 'hay_combinacion')
@;		* la combinaci�n sugerida tiene que ser escogida aleatoriamente de
@;			 entre todas las posibles, es decir, no tiene que ser siempre
@;			 la primera empezando por el principio de la matriz (o por el final)
@;		* para obtener posiciones aleatorias, se invocar� la rutina 'mod_random'
@;			 (ver fichero "candy1_init.s")
@;	Par�metros:
@;		R0 = direcci�n base de la matriz de juego
@;		R1 = direcci�n del vector de posiciones (char *), donde la rutina
@;				guardar� las coordenadas (x1,y1,x2,y2,x3,y3), consecutivamente.
	.global sugiere_combinacion
sugiere_combinacion:
		push {r0-r12, lr}
		
        mov r11, #COLUMNS
        mov r12, #ROWS	
        mov r10, r0					@; r10 = Back-up auxiliar de la direcci� de la matriu
        mov r0, r12					 
        bl mod_random				@; Cridem mod_random per a que ens retorni una fila actual random entre 0 i 8 
        mov r2, r0					@; r2 cont� la fila actual
        mov r0, r11	 
        bl mod_random				@; Cridem mod_random per a que ens retorni una columna actual random entre 0 i 8
        mov r3, r0					@; r3 cont� la columna actual
        mov r0, r10					@; Retornem la direcci� base de la matriu a r0, facilitats posteriors
        b .Lrecorre_mat
            
        .LsaltarFila:
            mov r3, #0				@; Ens situem a la 1� columna (f, 0)
        .Lrecorre_mat:
            mla r5, r2, r11, r3
            add r4, r0, r5			@; Retorna la posici� random (f, c) dins la matriu
            ldrb r5, [r4]			@; Retorna element dins posici� random anterior
            cmp r5, #7                 
            beq .Lnext_lmn			@; Comprovaci� bloc s�lid
            cmp r5, #15                
            beq .Lnext_lmn			@; Comprovaci� hueco
            and r5, #ELEMENT_TYPE	@; Filtrem el valor amb una m�scara per a que en el cas de ser un 8 o un 16, ens doni 0
            cmp r5, #0                 
            beq .Lnext_lmn			@; Comprovaci� si �s 0
            
        .Lvert:
            sub r12, #1
            cmp r2, r12
            add r12, #1
            beq .Lhorit				@; Si estem a l'�ltima fila, nom�s canviarem en horitzontal
            add r9, r3, r11			@; Incrementa amb +COLUMNES per avan�ar a la posici� inferior
            mla r7, r2, r11, r9		   
            add r6, r0, r7			@; r6 = �ndex Despla�ament de l'element relatiu (f+1,c)
            ldrb r10, [r6]			@; Obtenim l'element a comprovar
            mov r11, r3				@; r11 = columna de (f+1, c)
            add r12, r2, #1			@; r12 = fila de (f+1, c)
            cmp r10, #7                
            beq .Lhorit				@; Si l'element d'abaix �s un bloc s�lid, inamovible, mirem de canviar element horitzontal
            cmp r10, #15               
            beq .Lhorit				@; Si l'element d'abaix �s un forat, inamovible, mirem de canviar element horitzontal
            and r10, #ELEMENT_TYPE	@; Filtrem el valor amb una m�scara per a que en el cas de ser un 8 o un 16, ens doni 0
            cmp r10, #0                
            beq .Lhorit				@; Comprovaci� element ==0
            cmp r5, r10                
            beq .Lhorit				@; Anem a validar seg�ent posici� si l'element actual i el de sota siguin iguals            
            
			mov r5, #0			
            b .Lswitch
        .Lfi_vert:
        
        .Lhorit:
            mov r11, #COLUMNS
            mov r12, #ROWS
            sub r11, #1
            cmp r3, r11
            add r11, #1
            beq .Lnext_lmn			@; Si estem a l'�ltima columna, passarem al seg�ent element
            add r9, r3, #1			@; Incrementa amb 1 les columnes per avan�ar a la posici� seg�ent
            mla r7, r2, r11, r9
            add r6, r0, r7			
            ldrb r10, [r6]			
            mov r11, r9				
            mov r12, r2             
            cmp r10, #7
            beq .Lnext_lmn			
            cmp r10, #15
            beq .Lnext_lmn			
            and r10, #7				
            cmp r10, #0
            beq .Lnext_lmn			
            cmp r5, r10
            beq .Lnext_lmn			
			
            mov r5, #-1				@; Posar r5 a -1 ens permetr� comprovar posteriorment si s'ha intentat fer el canvi en horitzontal o no
        .Lfi_horit:
        
        .Lswitch:
            ldrb r7, [r4]			@;aux1 = element1
            ldrb r8, [r6]			@;aux2 = element2
            strb r8, [r4]			@;element1 = aux2		Intercanviem els valors de les direccions r4<->r6
            strb r7, [r6]			@;element2 = aux1
            mov r4, r0				@;R4 es la direcci� base de la matriu
            mov r7, r1				@;Guardem la direccio base del vector en un registre temporal	
            mov r1, r2				@;R1 es la fila actual
            mov r2, r3				@;R2 es la columna actual
            bl detectar_orientacion	
            mov r9, r0				@;Guardem el resultat en un registre temporal per a la seva posterior comparaci�
            mov r8, r1				@;Guardem la fila actual (R1) en un registre temporal
            mov r1, r12				@;Guardem la fila de l'altre element consecutivo a R1
            mov r12, r2				@;Guardem la columna actual (R2) en un registre temporal
            mov r2, r11				@;Guardem la columna de l'altre consecutivo element a R2
            cmp r9, #6
            bleq detectar_orientacion@;Si no hem detectat orientaci� anteriorment, tornem a cridar detectar_orientacion per a l'altre element, sin� no fa falta
            mov r10, #6				@;Inicialitzem R10 per no agafar valors erronis posteriorment
            cmp r9, #6
            moveq r10, r0			@;Nom�s actualitzem el valor d'R10 si no s'ha trobat cap combinaci� en la invocaci�n de posici�n actual
            mov r0, r4				@;Tornem la direcci� base de la matriu a R0
            mov r12, r1				@;Tornem la fila de l'altre element consecutivo al seu registre original
            mov r1, r7				@;Retornem la direccio base del vector a R1	
            mov r2, r8				@;Retornem la fila de l'element actual a R2
            
            mov r8, #COLUMNS
            mla r7, r2, r8, r3
            add r4, r0, r7			@;Tornem a obtenir la posici� de la matriu on est� l'element actual ja que anteriorment hem matxacat el valor d'R4
            
            ldrb r7, [r6]			@;aux1 = element2
            ldrb r8, [r4]			@;aux2 = element1
            strb r8, [r6]			@;element2 = aux2		Intercanviem els valors r6<->r4 novament per a deixar la matriu tal i com estava
            strb r7, [r4]			@;element1 = aux1
            
            
            cmp r9, #6
            cmpeq r10, #6
            beq .Lx					@;Si no es detecta orientaci� ni a la 1a ni a la 2a posici�, mirem si hem fet el canvi horitzontal
            b .Ly					@;Si es detecta alguna orientaci�, anem a buscar les posicions dels elements que la formen
            
        .Lx:
            cmp r5, #-1
            ldrb r5, [r4] 
            bne .Lhorit				@;Si no s'ha fet el canvi horitzontal, procedim a fer-lo
            beq .Lnext_lmn			@;Si ja s'ha fet el canvi horitzontal i tot i aix� no s'ha trobat cap orientaci�, passem al seg�ent element
            
        .Ly:
            cmp r9, #6
            blo .Lcpiy				@;Si a la 1a posici� comprobada hi ha una orientaci�, saltem a .Lcpiy
            b .Lcpix				@;Si no s'ha trobat orientaci� a la 1a posici�, vol dir que la 2a s� que en t�
        .Lcpiy:
            mov r8, r0				@;
            mov r0, r1				@;
            mov r1, r2				@;Passem els par�metres corresponents a... 
            mov r2, r3				@;...la funci� generar_posiciones()
            mov r3, r9				@;
            cmp r9, #0
            moveq r4, #2			@;Si c.ori indica est, el cpi solament pot ser 2 (vertical amunt)
            beq .Lready				@;Un cop hem passat tots els parametres, anem a fer la crida a al funci�
            cmp r9, #1
            moveq r4, #0			@;Si c.ori indica sud, el cpi solament pot ser 0 (horitzontal esquerra)
            beq .Lready				@;Un cop hem passat tots els parametres, anem a fer la crida a al funci�
            cmp r9, #2
            cmpeq r1, r12
            moveq r4, #0			@;Si c.ori indica oest i els elements x i y estan a la mateixa fila, el cpi ha de ser 0 (horitzontal esquerra)
            movlo r4, #2			@;Si c.ori indica oest i l'element x(circulo) est� una fila per sobre de l'element y(cuadrado), el cpi ha de ser 2 (vertical amunt)
            bls .Lready				@;Un cop hem passat tots els parametres, anem a fer la crida a al funci�
            cmp r9, #4
            moveq r4, #2			@;Si c.ori indica horitzontal, el cpi solament pot ser 2 (vertical amunt)
            beq .Lready				@;Un cop hem passat tots els parametres, anem a fer la crida a al funci�
            cmp r9, #5
            moveq r4, #0			@;Si c.ori indica vertical, el cpi solament pot ser 0 (horitzontal esquerra)
            beq .Lready				@;Un cop hem passat tots els parametres, anem a fer la crida a al funci�
            cmp r9, #3
            cmpeq r2, r11
            moveq r4, #2			@;Si c.ori indica nord i els elements x i y estan a la mateixa columna, el cpi ha de ser 2 (vertical amunt)
            movhi r4, #0			@;Si c.ori indica nord i l'element x est� a la columna anterior de l'element y, el cpi ha de ser 0 (horitzontal esquerra)
            b .Lready				@;Un cop hem passat tots els parametres, anem a fer la crida a al funci�
        .Lcpix:
            mov r8, r0				@;
            mov r0, r1				@;
            mov r1, r12				@;Passem els par�metres corresponents a... 
            mov r6, r2				@;...la funci� generar_posiciones()
            mov r2, r11				@;
            mov r7, r3				@;
            mov r3, r10				@;
            
            cmp r10, #2	
            moveq r4, #3			@;Si c.ori indica oest, el cpi solament pot ser 3 (vertical abaix)
            beq .Lready				@;Un cop hem passat tots els parametres, anem a fer la crida a al funci�
            cmp r10, #3
            moveq r4, #1			@;Si c.ori indica nord, el cpi solament pot ser 1 (horitzontal dreta)
            beq .Lready				@;Un cop hem passat tots els parametres, anem a fer la crida a al funci�
            cmp r10, #4
            moveq r4, #3			@;Si c.ori indica horitzontal, el cpi solament pot ser 3 (vertical abaix)
            beq .Lready				@;Un cop hem passat tots els parametres, anem a fer la crida a al funci�
            cmp r10, #5
            moveq r4, #1			@;Si c.ori indica vertical, el cpi solament pot ser 1 (horitzontal dreta)
            beq .Lready				@;Un cop hem passat tots els parametres, anem a fer la crida a al funci�
            cmp r10, #1
            cmpeq r2, r7
            moveq r4, #3			@;Si c.ori indica sud i els elements x i y estan a la mateixa columna, el cpi ha de ser 3 (vertical abaix)
            movhi r4, #1			@;Si c.ori indica sud i l'element y est� una columna per davant de l'element x, el cpi ha de ser 1 (horitzontal dreta)
            bhs .Lready				@;Un cop hem passat tots els parametres, anem a fer la crida a al funci�
            cmp r10, #0
            cmpeq r1, r6
            moveq r4, #1			@;Si c.ori indica est i els elements x i y estan a la mateixa fila, el cpi ha de ser 1 (horitzontal dreta)
            movhi r4, #3			@;Si c.ori indica est i l'element y est� una fila per sobre de l'element x, el cpi ha de ser 3 (vertical abaix)
        .Lready:
            bl generar_posiciones	@;Un cop hem passat tots els par�metres correctament, ens disposem a buscar les posicions de sugger�ncia
            b .Lfi_recorre_mat		@;Quan tinguem el vector de posicions fet, ja hem acabat el procediment
        .Lfi_switch:
        
        .Lnext_lmn:
            mov r11, #COLUMNS
            mov r12, #ROWS
            add r3, #1				@;Incrementem en 1 les columnes
            cmp r3, r11
            blo .Lrecorre_mat		@;Recorrem totes les columnes
            add r2, #1				@;Incrementem en 1 les files
            cmp r2, r12
            blo .LsaltarFila		@;Recorrem totes les files
            mov r2, #0				@;Si hem arribat al final de la matriu, ens tornem a posicionar...
            mov r3, #0				@;...al principi d'aquesa posant les files i columnes actuals a 0
            b .Lrecorre_mat			@;Tornem al principi de la matriu i seguim buscant una combinaci�
        .Lfi_recorre_mat:
       
		
		pop {r0-r12, pc}




@;:::RUTINAS DE SOPORTE:::



@; generar_posiciones(vect_pos,f,c,ori,cpi): genera las posiciones de sugerencia
@;	de combinaci�n, a partir de la posici�n inicial (f,c), el c�digo de
@;	orientaci�n 'ori' y el c�digo de posici�n inicial 'cpi', dejando las
@;	coordenadas en el vector 'vect_pos'.
@;	Restricciones:
@;		* se supone que la posici�n y orientaci�n pasadas por par�metro se
@;			corresponden con una disposici�n de posiciones dentro de los l�mites
@;			de la matriz de juego
@;	Par�metros:
@;		R0 = direcci�n del vector de posiciones 'vect_pos'
@;		R1 = fila inicial 'f'
@;		R2 = columna inicial 'c'
@;		R3 = c�digo de orientaci�n;
@;				inicio de secuencia: 0 -> Este, 1 -> Sur, 2 -> Oeste, 3 -> Norte
@;				en medio de secuencia: 4 -> horizontal, 5 -> vertical
@;		R4 = c�digo de posici�n inicial:
@;				0 -> izquierda, 1 -> derecha, 2 -> arriba, 3 -> abajo
@;	Resultado:
@;		vector de posiciones (x1,y1,x2,y2,x3,y3), devuelto por referencia
generar_posiciones:
		push {r1-r4, r8, lr}
		
		@; SELECCI�N cpi
		cmp r4, #0
		beq .Lcpi0
		
		cmp r4, #1
		beq .Lcpi1
		
		cmp r4, #2
		beq .Lcpi2
		
		cmp r4, #3
		beq .Lcpi3
		
		
		.Lcpi0:
			@; DESPLAZAMIENTO HACIA IZQUIERDA (cpi = 0):
			mov r8, #0				@; r8 = �ndice iterante para el vector de posiciones (vect_pos(i, , , , , ))
			add r2, #1				@; El elemento esta en la misma Filas(r1) pero en Columnas+1(r2)
			strb r2, [r0, r8]		@; Guarda "x1" perteneciente al elemento a mover ->	vect_pos([x1], , , ,)
			add r8, #1				@; i++	>>	( , i, , )
			strb r1, [r0, r8]		@; Guarda "y1" perteneciente al elemento a mover ->	vect_pos(x1,[y1], , , , )
			sub r2, #1
			b .Lcmps_cpi0
			
			.Lcmps_cpi0:
			cmp r3, #1
			beq .LoriSUR
			
			cmp r3, #2
			beq .LoriOESTE
			
			cmp r3, #3
			beq .LoriNORTE
			
			cmp r3, #5
			beq .LoriCENTRO_VERTICAL
			
		.Lcpi1:
			@; DESPLAZAMIENTO HACIA DERECHA (cpi = 1):
			mov r8, #0				@; r8 = �ndice iterante para el vector de posiciones (vect_pos(i, , , , , ))
			sub r2, #1				@; El elemento esta en la misma Filas(r1) pero en Columnas-1(r2)
			strb r2, [r0, r8]		@; Guarda "x1" perteneciente al elemento a mover ->	vect_pos([x1], , , ,)
			add r8, #1				@; i++	>>	( , i, , )
			strb r1, [r0, r8]		@; Guarda "y1" perteneciente al elemento a mover ->	vect_pos(x1,[y1], , , , )
			add r2, #1
			b .Lcmps_cpi1			
			
			.Lcmps_cpi1: 
			cmp r3, #0
			beq .LoriESTE
			
			cmp r3, #1
			beq .LoriSUR
			
			cmp r3, #3
			beq .LoriNORTE
			
			cmp r3, #5
			beq .LoriCENTRO_VERTICAL
			
		.Lcpi2:	
			@; DESPLAZAMIENTO HACIA ARRIBA (cpi = 2):
			mov r8, #0				@; r8 = �ndice iterante para el vector de posiciones (vect_pos(i, , , , , ))
			strb r2, [r0, r8]		@; Guarda "x1" perteneciente al elemento a mover ->	vect_pos([x1], , , ,)
			add r8, #1				@; i++	>>	( , i, , )
			add r1, #1				@; El elemento esta en la misma Columnas(r2) pero en Filas+1(r1)
			strb r1, [r0, r8]		@; Guarda "y1" perteneciente al elemento a mover ->	vect_pos(x1,[y1], , , , )
			sub r1, #1
			b .Lcmps_cpi2
			
			.Lcmps_cpi2:
			cmp r3, #0
			beq .LoriESTE
			
			cmp r3, #2
			beq .LoriOESTE
			
			cmp r3, #3
			beq .LoriNORTE
			
			cmp r3, #4
			beq .LoriCENTRO_HORIZONTAL
			
		.Lcpi3:	
			@; DESPLAZAMIENTO HACIA ABAJO (cpi = 3):
			mov r8, #0				@; r8 = �ndice iterante para el vector de posiciones (vect_pos(i, , , , , ))
			strb r2, [r0, r8]		@; Guarda "x1" perteneciente al elemento a mover ->	vect_pos([x1], , , ,)
			add r8, #1				@; i++	>>	( , i, , )
			sub r1, #1				@; El elemento esta en la misma Columnas(r2) pero en Filas-1(r1)
			strb r1, [r0, r8]		@; Guarda "y1" perteneciente al elemento a mover ->	vect_pos(x1,[y1], , , , )
			add r1, #1
			b .Lcmps_cpi3
			
			.Lcmps_cpi3:
			cmp r3, #0
			beq .LoriESTE
			
			cmp r3, #1
			beq .LoriSUR
			
			cmp r3, #2
			beq .LoriOESTE
			
			cmp r3, #4
			beq .LoriCENTRO_HORIZONTAL
			
		
		@; SELECCI�N ori	
			.LoriESTE:
				@; hacia ESTE (.LcpiN_ori0)
				add r8, #1			@; i++	>>	( , , i, , , )
				add r2, #1
				strb r2, [r0, r8]	@; Guarda "x2"	->	vect_pos(x1, y1, [x2], , , )
				add r8, #1			@; i++	>>	( , , , i, , )
				strb r1, [r0, r8]	@; Guarda "y2"	->	vect_pos(x1, y1, x2, [y2], , )
				add r8, #1			@; i++	>>	( , , , , i, )
				add r2, #1
				strb r2, [r0, r8]	@; Guarda "x3"	->	vect_pos(x1, y1, x2, y2, [x3], )
				add r8, #1			@; i++	>>	( , , , , , i)
				strb r1, [r0, r8]	@; Guarda "y3"	->	vect_pos(x1, y1, x2, y2, x3, [y3])
				b .LreturnVecPos
			
			.LoriSUR:
				@; hacia SUR (.LcpiN_ori1)
				add r8, #1			@; i++	>>	( , , i, , , )
				strb r2, [r0, r8]	@; Guarda "x2"	->	vect_pos(x1, y1, [x2], , , )
				add r8, #1			@; i++	>>	( , , , i, , )
				add r1, #1
				strb r1, [r0, r8]	@; Guarda "y2"	->	vect_pos(x1, y1, x2, [y2], , )
				add r8, #1			@; i++	>>	( , , , , i, )
				strb r2, [r0, r8]	@; Guarda "x3"	->	vect_pos(x1, y1, x2, y2, [x3], )
				add r8, #1			@; i++	>>	( , , , , , i)
				add r1, #1
				strb r1, [r0, r8]	@; Guarda "y3"	->	vect_pos(x1, y1, x2, y2, x3, [y3])
				b .LreturnVecPos
				
			.LoriOESTE:	
				@; hacia OESTE (.LcpiN_ori2)
				add r8, #1			@; i++	>>	( , , i, , , )
				sub r2, #1
				strb r2, [r0, r8]	@; Guarda "x2"	->	vect_pos(x1, y1, [x2], , , )
				add r8, #1			@; i++	>>	( , , , i, , )
				strb r1, [r0, r8]	@; Guarda "y2"	->	vect_pos(x1, y1, x2, [y2], , )
				add r8, #1			@; i++	>>	( , , , , i, )
				sub r2, #1
				strb r2, [r0, r8]	@; Guarda "x3"	->	vect_pos(x1, y1, x2, y2, [x3], )
				add r8, #1			@; i++	>>	( , , , , , i)
				strb r1, [r0, r8]	@; Guarda "y3"	->	vect_pos(x1, y1, x2, y2, x3, [y3])
				b .LreturnVecPos
				
			.LoriNORTE:	
				@; hacia NORTE (.LcpiN_ori3)
				add r8, #1			@; i++	>>	( , , i, , , )
				strb r2, [r0, r8]	@; Guarda "x2"	->	vect_pos(x1, y1, [x2], , , )
				add r8, #1			@; i++	>>	( , , , i, , )
				sub r1, #1
				strb r1, [r0, r8]	@; Guarda "y2"	->	vect_pos(x1, y1, x2, [y2], , )
				add r8, #1			@; i++	>>	( , , , , i, )
				strb r2, [r0, r8]	@; Guarda "x3"	->	vect_pos(x1, y1, x2, y2, [x3], )
				add r8, #1			@; i++	>>	( , , , , , i)
				sub r1, #1
				strb r1, [r0, r8]	@; Guarda "y3"	->	vect_pos(x1, y1, x2, y2, x3, [y3])
				b .LreturnVecPos
				
			.LoriCENTRO_HORIZONTAL:
				@; hacia CENTRO-HORIZONTAL-ARR/ABA (.LcpiN_ori4)
				add r8, #1			@; i++	>>	( , , i, , , )
				sub r2, #1
				strb r2, [r0, r8]	@; Guarda "x2"	->	vect_pos(x1, y1, [x2], , , )
				add r8, #1			@; i++	>>	( , , , i, , )
				strb r1, [r0, r8]	@; Guarda "y2"	->	vect_pos(x1, y1, x2, [y2], , )
				add r8, #1			@; i++	>>	( , , , , i, )
				add r2, #2
				strb r2, [r0, r8]	@; Guarda "x3"	->	vect_pos(x1, y1, x2, y2, [x3], )
				add r8, #1			@; i++	>>	( , , , , , i)
				strb r1, [r0, r8]	@; Guarda "y3"	->	vect_pos(x1, y1, x2, y2, x3, [y3])
				b .LreturnVecPos
				
			.LoriCENTRO_VERTICAL:	
				@; hacia CENTRO-VERTICAL-IZQ/DER (.LcpiN_ori5)
				add r8, #1			@; i++	>>	( , , i, , , )
				strb r2, [r0, r8]	@; Guarda "x2"	->	vect_pos(x1, y1, [x2], , , )
				add r8, #1			@; i++	>>	( , , , i, , )
				sub r1, #1
				strb r1, [r0, r8]	@; Guarda "y2"	->	vect_pos(x1, y1, x2, [y2], , )
				add r8, #1			@; i++	>>	( , , , , i, )
				strb r2, [r0, r8]	@; Guarda "x3"	->	vect_pos(x1, y1, x2, y2, [x3], )
				add r8, #1			@; i++	>>	( , , , , , i)
				add r1, #2			@; Est� dos Filas por abajo
				strb r1, [r0, r8]	@; Guarda "y3"	->	vect_pos(x1, y1, x2, y2, x3, [y3])
				b .LreturnVecPos
				
				
		.LreturnVecPos:

		pop {r1-r4, r8, pc}


@; detectar_orientacion(f,c,mat): devuelve el c�digo de la primera orientaci�n
@;	en la que detecta una secuencia de 3 o m�s repeticiones del elemento de la
@;	matriz situado en la posici�n (f,c).
@;	Restricciones:
@;		* para proporcionar aleatoriedad a la detecci�n de orientaciones en las
@;			que se detectan secuencias, se invocar� la rutina 'mod_random'
@;			(ver fichero "candy1_init.s")
@;		* para detectar secuencias se invocar� la rutina 'cuenta_repeticiones'
@;			(ver fichero "candy1_move.s")
@;		* s�lo se tendr�n en cuenta los 3 bits de menor peso de los c�digos
@;			almacenados en las posiciones de la matriz, de modo que se ignorar�n
@;			las marcas de gelatina (+8, +16)
@;	Par�metros:
@;		R1 = fila 'f'
@;		R2 = columna 'c'
@;		R4 = direcci�n base de la matriz
@;	Resultado:
@;		R0 = c�digo de orientaci�n;
@;				inicio de secuencia: 0 -> Este, 1 -> Sur, 2 -> Oeste, 3 -> Norte
@;				en medio de secuencia: 4 -> horizontal, 5 -> vertical
@;				sin secuencia: 6 
detectar_orientacion:
push {r3, r5, lr}
		
		mov r5, #0				@;R5 = �ndice bucle de orientaciones
		mov r0, #4
		bl mod_random
		mov r3, r0				@;R3 = orientaci�n aleatoria (0..3)
	.Ldetori_for:
		mov r0, r4
		bl cuenta_repeticiones
		cmp r0, #1
		beq .Ldetori_cont		@;no hay inicio de secuencia
		cmp r0, #3
		bhs .Ldetori_fin		@;hay inicio de secuencia
		add r3, #2
		and r3, #3				@;R3 = salta dos orientaciones (m�dulo 4)
		mov r0, r4
		bl cuenta_repeticiones
		add r3, #2
		and r3, #3				@;restituye orientaci�n (m�dulo 4)
		cmp r0, #1
		beq .Ldetori_cont		@;no hay continuaci�n de secuencia
		tst r3, #1
		bne .Ldetori_vert
		mov r3, #4				@;detecci�n secuencia horizontal
		b .Ldetori_fin
	.Ldetori_vert:
		mov r3, #5				@;detecci�n secuencia vertical
		b .Ldetori_fin
	.Ldetori_cont:
		add r3, #1
		and r3, #3				@;R3 = siguiente orientaci�n (m�dulo 4)
		add r5, #1
		cmp r5, #4
		blo .Ldetori_for		@;repetir 4 veces
		
		mov r3, #6				@;marca de no encontrada
		
	.Ldetori_fin:
		mov r0, r3				@;devuelve orientaci�n o marca de no encontrada
		
		pop {r3, r5, pc}



.end
