;;; spanish.el is free software
;;; the vocab and other useful tools from my spanish class

;;----------------------------------------
;; todo:
;;		review estar
;;		prepositions


;;; Commentary:
;; 


;;; History:
;; 

;;; Code:
(defvar sessionFailedQuestions nil
  "The list of questions that have been answered incorrectly for a particular session.")

(defvar globalFailedQuestions nil
  "The list of questions that have been answered incorrectly across all sessions.")

(defconst greetingPhrases '(
				( "como te llamas?" "how are you called?" )
				( "de donde eres?" "where are you from?" )
				( "donde vives?" "where do you live?" )
				( "cuantos a�os tienes?" "how many years do you have?" )
				)
	  )

(defconst expressionsOfCourtesy '(
							  ( "con permiso." "Pardon me.")
							  ( "Lo siento." "I'm sorry.")
							  ( "No hay de qu�" "You're welcome.")
							  )
	  )

(defconst daysOfWeek '(
				   ("el lunes" "monday")
				   ("el martes" "tuesday")
				   ("el mi�rcoles" "wednesday")
				   ("el jueves" "thursday")
				   ("el viernes" "friday")
				   ("el s�bado" "saturday")
				   ("el domingo" "sunday")
				   )
	  )
(defconst vocab '(
			  ( "el pasajero"  "passenger")
			  ( "el pa�s"  "country")
			  ( "el jugador"  "player")
			  ( "la playa"  "beach")
			  ( "la cosa"  "thing")
			  ( "la maleta"  "suitcase")
			  ( "el l�piz"  "pencil")
			  ( "la grabadora"  "tape recorder")
			  ( "la mujer"  "woman")
			  ( "la palabra" "word")
			  ( "el mapa" "map")
			  ( "la mano" "hand")
			  ( "el l�piz" "pencil")
			  ( "la conversaci�n" "conversation")
			  ( "la biblioteca" "library")
			  ("el lunes" "monday")
			  ("el martes" "tuesday")
			  ("el mi�rcoles" "wednesday")
			  ("el viernes" "friday")
			  ("el s�bado" "saturday")
			  ("el domingo" "sunday")
 			  ("el jueves" "thursday")
			  ( "el estadio" "stadium")
			  ( "el horario" "schedule")
			  ( "las ciencias" "sciences")
			  ( "el periodismo" "journalism")
			  ( "la pluma" "pen")
			  ( "el escritorio" "desk")
			  ( "la mochilla" "backpack")
			  ( "el borrador" "eraser")
			  ( "la tiza" "chalk")
			  ( "la semana" "week")
			  ( "la prueba" "test")
			  ( "la tarea" "homework")
			  ( "el juego" "game")
			  ( "la empresa" "company; firm")
			  ( "la cuarto" "room")
			  ( "el extranjero" "foreigner")
			  ( "el abuelo" "grandfather")
			  ( "el cu�ado" "brother-in-law")
			  ( "la familia" "family")
			  ( "el hermanastro" "stepbrother")
			  ( "el hermano" "brother")
			  ( "el hijastro" "stepson")
			  ( "el hijo" "son")
			  ( "la madrastra" "stepmother")
			  ( "el medio hermano" "half-brother")
			  ( "el nieto" "grandson")
			  ( "la nuera" "daughter-in-law")
			  ( "el padrastro" "stepfather")
			  ( "los parientes" "relatives")
			  ( "el primo" "cousin")
			  ( "el sobrino" "nephew")
			  ( "el suegro" "father-in-law")
			  ( "el tio" "uncle")
			  ( "el yerno" "son-in-law")
			  ( "la gente" "people")
			  ( "el muchacho" "boy")
			  ( "el ni�o" "child")
			  ( "el novio" "boyfriend")
			  ( "el m�dico" "doctor")
			  ( "el ingeniero" "engineer")
			  ( "el periodista" "journalist")
			  ( "el programador" "programmer")
			  ( "alto" "tall")
			  
			  ( "antip�tico" "unpleasant")
			  ( "bajo" "short")
			  ( "bonito" "pretty")
			  ( "bueno" "good")
			  ( "delgado" "slender")
			  ( "dif�cil" "difficult")
			  ( "f�cil" "easy")
			  ( "feo" "ugly")
			  ( "gordo" "fat")
			  ( "grande" "big")
			  ( "joven" "young")
			  ( "malo" "bad")
			  ( "mismo" "same")
			  ( "moreno" "brunette")
			  ( "pelirrojo" "redhead")
			  ( "peque�o" "small")
			  ( "rubio" "blond")
			  ( "simp�tico" "nice")
			  ( "tonto" "silly")
			  ( "viejo" "old")
			  ( "alem�n" "german")
			  ( "canadiense" "canadian")
			  ( "chino" "chinese")
			  ( "ecuatoriano" "ecuadorian")
			  ( "ruso" "russian")
			  
			  ;;chap. 4
			  ("pasear" "walk")
			  ("patinar" "skate")
			  ("nadar" "swim")
			  ("escalar" "climb" "escalar monta�as" "climb mountains")
			  ("cada" "each" "cada d�a" "each day")
			  ("partido" "game")
			  ("esquiar" "ski")
			  ("nataci�n" "swimming")
			  ("bucear" "dive")
			  ("rato" "while" "ratos libres" "spare time")
			  ("aficionado" "fan")
			  
			  ;;stem verbs
			  ("empezar" "begin")
			  ("volver" "return")
			  ("pedir" "ask for")
			  ("cerrar" "to close")
			  ("poder" "to be able to; can")
			  ("pensar" "think; intend to" "pienso llamarle ma�ana" "I intend to call him tommorow")
			  ("entender" "understand")

			  ;;chap 4
			  ( "Nunca" "never")
("bucear" "scuba dive")
("escalar monta�as" "climb mountains")
("escribir una carta" "write a letter")
("escribir un mensaje electr�nico" "write email message")
("escribir una postal" "write postcard")
("esquiar" "ski")
("ganar" "win")
("ir de excursi�n" "go for a hike")
("leer correo electr�nico" "read email")
("pasar tiempo" "spend time")
("pasear" "stroll")
("pasear en bicicleta" "ride a bike")
("patinar" "skate")
("practicar deportes" "play sports")
("ser aficionado" "be a fan" "yo aficionado de futbol" "I'm a fan of football")
("tomar el sol" "sunbathe")
("ver pel�culas" "see movies")
("la diversi�n" "diversion")
("el excursionista" "hiker")
("el fin de semana" "weekend")
("el pasatiempo" "pastime")
("los ratos libres" "spare time")
("el tiempo libre" "free time")
			  )
	  )

(defconst tieredVocab
  '(
	;;tier 1
	(( "la gente" "people" )
	 ( "el extranjero" "foreigner" )
	 ( "el cu�ado" "brother-in-law" )
	 ( "el yerno" "son-in-law" )
	 ( "el hijastro" "stepson" )
	 ( "el abuelo" "grandfather" )
	 ( "joven" "young" )
	 ( "la nuera" "daughter-in-law" )
	 ( "el juego" "game" )
	 ( "la grabadora" "tape recorder" )
	 ( "mismo" "same" )
	 ( "los parientes" "relatives" )
	 ( "el sobrino" "nephew" )
	 ( "delgado" "slender" )
	 ( "el novio" "boyfriend" )
	 ( "el suegro" "father-in-law" )
	 ( "el periodismo" "journalism" )
	 ( "viejo" "old" )
	 ( "la madrastra" "stepmother" )
	 ( "la prueba" "test" )
	 ( "la maleta" "suitcase" )
	 )
	;;tier 2
	(( "el sobrino" "nephew" )
	 ( "el juego" "game" )
	 ( "el pa�s" "country" )
	 ( "delgado" "slender" )
	 ( "el abuelo" "grandfather" )
	 ( "el cu�ado" "brother-in-law" )
	 ( "el suegro" "father-in-law" )
	 ( "la prueba" "test" )
	 ( "la nuera" "daughter-in-law" )
	 ( "el periodista" "journalist" )
	 ( "chino" "chinese" )
	 )
	
	;;tier 3
	(( "la maleta" "suitcase" )
	 ( "moreno" "brunette" )
	 ( "el nieto" "grandson" )
	 ( "ecuatoriano" "ecuadorian" )
	 ( "la conversaci�n" "conversation" )
	 ( "simp�tico" "nice" )
	 ( "la grabadora" "tape recorder" )
	 ( "peque�o" "small" )
	 ( "la empresa" "company; firm" )
	 ( "el muchacho" "boy" )
	 ( "el ni�o" "child" )
	 ( "la palabra" "word" )
	 ( "mismo" "same" )
	 ( "la nuera" "daughter-in-law" )
	 ( "malo" "bad" )
	 ( "el padrastro" "stepfather" )
	 ( "ruso" "russian" )
	 ( "grande" "big" )
	 ( "el yerno" "son-in-law" )
	 ( "la empresa" "company; firm" )
	 ( "la nuera" "daughter-in-law" )
	 ( "peque�o" "small" )
	 )
	
	;;tier 4
	(
	 ( "tener sed" "to be thirsty" )
	 ( "tener raz�n" "to be right" )
	 ( "no tener raz�n" "to be wrong" )
	 ( "tener miedo" "to be scared" )
	 ( "tener prisa" "to be in a hurry" )
	 ( "tener cuidado" "to be careful" )
	 ( "tener suerte" "to be lucky" )
	 ( "tener que estudiar" "to have to study")
	 ( "tener ganas de comer" "to feel like eating" "ellos tienen ganas de mirar la televisi�n" "they want to watch the television")
	 ( "el mapa" "map" )
	 ( "peque�o" "small" )
	 ( "el nieto" "grandson" )
	 ( "la nuera" "daughter-in-law" )
	 ( "la biblioteca" "library" )
	 ( "f�cil" "easy" )
	 ( "el ingeniero" "engineer" )
	 ( "las ciencias" "sciences" )
	 ( "el cuarto" "room" )
	 ( "el periodista" "journalist" )
	 ( "antip�tico" "unpleasant" )
	 ( "dif�cil" "difficult" )
	 ( "la conversaci�n" "conversation" )
	 )
	
	;;tier 5
	(
	 ( "el borrador" "eraser" )
	 ( "el yerno" "son-in-law" )
	 ( "entender" "understand" )
	 ( "la prueba" "test" )
	 ( "el suegro" "father-in-law" )
	 ( "los ratos libres" "spare time" )
	 ( "rato" "while" "ratos libres" "spare time" )
	 ( "partido" "game" )
	 ( "cada" "each" "cada d�a" "each day" )
	 ( "nataci�n" "swimming" )
	 ( "el jugador" "player" )
	 ( "el sobrino" "nephew" )
	 ( "el hijastro" "stepson" )
	 ( "el pa�s" "country" )
	 ( "volver" "return" )
	 ( "la madrastra" "stepmother" )
	 ( "bucear" "dive" )
	 ( "patinar" "skate" )
	 ( "simp�tico" "nice" )
	 ( "la semana" "week" )
	 ( "la tarea" "homework" )
	 ( "pasear" "walk" )
	 ( "el juego" "game" )
	 ( "el nieto" "grandson" )
	 ( "poder" "can" )
	 ( "empezar" "begin" )
	 ( "pienso llamarle ma�ana" "I intend to call him tommorow" )
	 ( "pensar" "think; intend to" "pienso llamarle ma�ana" "I intend to call him tommorow" )
	 ( "nadar" "swim" )
	 ( "la gente" "people" )
	 )
	
	;;tier 6
	(
	 ( "el nieto" "grandson" )
	 ( "poder" "can" )
	 ( "detr�s de" "behind" )
	 ( "entre" "between" )
	 ( "a la izquierda de" "to the left of" "Rita est� a la izquierda de Julio" )
	 ( "El estadio est� lejos de las residencias." "The stadium is far from the residences" )
	 ( "lejos de" "far from" "El estadio est� lejos de las residencias." "The stadium is far from the residences." )
	 )
	
	;;tier 7
	(
	 ( "llegar" "to arrive" )
	 ( "esperar" "to wait for; to hope" )
	 ( "descansar" "to rest" )
	 ( "necesitar" "to need" )
	 ( "llevar" "to carry" )
	 ( "necesitar" "to need" )
	 ( "regresar" "to return" )
	 ( "caminar" "to walk" )
	 ( "descansar" "to rest" )
	 ( "comprar" "to buy" "el compra libros en la librer�a" "he buys books in the bookstore")
	 ( "desear" "to want" )
	 ( "ense�ar" "to teach" )
	 ( "contestar" "to answer" )
	 ( "preparar" "to prepare" )
	 ( "dibujar" "to draw" "yo dibujo un reloj en la pizarra" "I draw a clock on the chalkboard" )
	 )
	
	;;tier 8
	(
	 ( "they(fam) ask for" "vosotros ped�s" )
	 ( "we sleep" "nosotros dormimos" )
	 ( "she sleeps" "ella duerme" )
	 ( "entender" "to understand" "entiendo" "I understand" )
	 ( "they begin" "Ellos empiezan" )
	 ( "they(fam) begin" "vosotros empez�is" )
	 ( "you(form.) begin" "Ud. empieza" )
	 )
	
	;;tier 9
	(
	 ( "cada d�a" "each day" )
	 ( "nataci�n" "swimming" )
	 ( "nadar" "swim" )
	 ( "ratos libres" "spare time" )
	 ( "entender" "understand" )
	 ( "el suegro" "father-in-law" )
	 ( "cada" "each" "cada d�a" "each day" )
	 ( "empezar" "begin" )
	 ( "rato" "a while" "ratos libres" "spare time" "espera un rato" "wait a while")
	 )
	;; irreg yo forms
	;;tier 10
	(
	 ("yo hago" "I do")
	 ("yo pongo" "I put" "pongo mi mochilla" "put down my backback")
	 ("yo salgo" "I leave" "Nunca salgo a correr" "I never run" )
	 ("yo supongo" "I suppose")
	 ("yo traigo" "I bring")
	 ("yo oigo" "I hear")
	 ("yo veo" "I see")
	 )
	;;tier 11
	(
	 ("bucear" "scuba dive")
	 ("escalar monta�as" "climb mountains")
	 ("escribir una carta" "write a letter")
	 ("escribir un mensaje electr�nico" "write email message")
	 ("escribir una postal" "write postcard")
	 ("esquiar" "ski")
	 ("ganar" "win")
	 ("ir de excursi�n" "go for a hike")
	 ("leer correo electr�nico" "read email")
	 ("pasar tiempo" "spend time")
	 )
	
	;;tier 12
	(
	 ( "escribir una carta" "write a letter" )
	 ( "ir de excursi�n" "go for a hike" )
	 ( "leer correo electr�nico" "read email" )
	 ( "pasar tiempo" "spend time" )
	 ( "escribir una postal" "write postcard" )
	 ( "ganar" "win" )
	 ( "bucear" "scuba dive" )
	 ( "ir de excursi�n" "go for a hike" )
	 )
	
	;;tier 13
	(
	 ( "cuando" "when" "cuando estoy triste, canto" "when I'm sad, I sing" )
	 ( "hacer" "to do" "hacer amigos" "to make friends" )
	 ( "deber" "should" "debemos regresar al autob�s" "we should return to the bus" )
	 ("conmigo" "with me")
	 ("por eso" "that's why")
	 ("tanto" "so much" "No as para tonto" "it's no big deal" )
	 ("equipo" "team")
	 ("el partido" "game; match")y
	 ("revista" "magazine")
	 ("lugar" "place" )
	 )
	
	;;tier 14
	(
	 ("entender" "to understand")
	 ("poder" "to be able to; can")
	 ("empezar" "to begin")
	 ("volver" "to return")
	 ("pensar" "to think about")
	 ("seguir" "to continue")
	 )
	
	;;tier 15
	(
	 ("la agente de viajes" "travel agent")
	 ("el hu�sped" "guest")
	 ("el estaci�n" "station; season")
	 ("la caba�a" "cabin")
	 ("la cama" "bed")
	 ("el campo" "countryside")
	 ("el equipaje" "luggage")
	 ("la llegada" "arrival")
	 ("el paisaje" "landscape")
	 ("el pasaje" "ticket")
	 ("la pensi�n" "boarding house")
	 ("el piso" "floor")
	 ("la planta baja" "ground floor")
	 ("la salida" "departure; exit")
	 ("la tienda de campa�a" "tent")
	 ("el botones" "bellboy")
	 ("el viajero" "treveler")
	 ("la aduana" "customs")
	 ("el empleado" "employee")
	 ("el ascensor" "elevator")
	 ("hacer turismo" "go sightseeing")
	 
	 ("mostrar" "show")
	 
	 ;;("acampar" "to go camping")
	 )
	;;tier 16
	(
	 ("el invierno" "winter")
	 ("la primavera" "spring")
	 ("el verano" "summer")
	 ("el oto�o" "autumn")
	 )
	
	;;tier 17
	(
	 ("el aeropuerto" "airport")
	 ("saca fotos" "take pictures")
	 ("llamar" "to call")
	 ("gana" "desire (adv.)")
	 ("venir" "to come")
	 )
	
	;;tier 18
	(
	 ("abierto" "open")
	 ("cerrado" "closed")
	 ("aburrido" "bored; boring")
	 
	 ("alegre" "happy")
	 ("triste" "sad")
	 
	 ("desordenado" "disorderly")
	 ("ordenado" "orderly")
	 
	 ("avergonzado" "embarrassed")
	 ("cansado" "tired")
	 
	 ("c�modo" "comfortable")
	 )
	
	;;tier 19
	(
	 ("contento" "happy; content")
	 
	 ("enamorado" "in love")
	 ("enojado" "mad")
	 ("equivocado" "wrong")
	 ("feliz" "happy")
	 ("limpio" "clean")
	 ("sucio" "dirty")
	 
	 ("nervioso" "nervous")
	 ("ocupado" "busy")
	 ("preocupado" "worried")
	 ("seguro" "sure")
	 
	 ("respueste" "answer")
	 ("nieve" "snow")
	 ("lejos" "far")
	 )
	
	;;tier 20
	(
	 ("barco" "ship")
	 ("ir de excursi�n" "go for a hike")
	 ("ir de compras" "to go shopping")
	 ;;	 ("recorrer" "tour around an area")
	 ("la habitaci�n" "room")
	 ("deber" "should" "tu deber es esperer aqu�")
	 ("enero" "january")
	 ( "tener sue�o" "to be sleepy" )
	 ( "No estoy seguro" "I don't know")
	 ( "ellos est�n jugando al f�tbol" "they are playing football")
	 ( "Estoy tomando el sol" "I am sunbathing")
	 ("poder" "to be able; can" "yo puedo" "I to be able; can" "t� puedes" "you to be able; can" "�l puede" "he to be able; cans" "nos. podemos" "we to be able; can" "vos. podeis" "they(fam) to be able; can" "ellos pueden" "they to be able; can" )
	 ("salir" "to leave" "yo salgo" "I leave" "Nunca salgo a correr" "I never run" "salgo a caminar con un amigo" "I go for a walk with a friend" )
	 )
	
	;;tier 21
	(
	 ("poder" "to be able to; can" "yo puedo" "I can")
	 ("seguir" "follow" "yo sigo" "I follow" "t� sigues" "you follow" "�l sigue" "he follows" "nos. seguimos" "we follow" "vos. seguiis" "they(fam) follow" "ellos siguen" "they follow" )
	 ( "llevar" "to carry" )
	 ("llamar" "to call")
	 ("nos" "us")
	 ("llegar" "to arrive")
	 ("te" "you")
	 ( "tener miedo" "to be scared" )
	 ("entender" "to understand" "entiendo" "I understand")
	 ("ves" "you see")
	 ("�l est� buscando" "he is looking")
	 ("ellos est�n comendo" "they are eating")
	 ("estoy empezando" "I am beginning")
	 ("ellos est�n viviendo" "they are living")
	 ("ellos est�n teniendo" "they are having")
	 ("�l est� abriendo" "he is opening")
	 ("�l est� leyendo" "he is reading")
	 ("�l est� paseando en bicicleta" "he is riding a bike")
	 )
	
	;;tier 22
	(
	 ("revista" "magazine")
	 ("equipo" "team")
	 ("ganar" "win")
	 ("perder" "lose" "yo pierdo" "I lose" "t� pierdes" "you lose" "�l pierde" "he loses" "nos. perdemos" "we lose" "vos. perdeis" "they(fam) lose" "ellos pierden" "they lose" )
	 ("En Teruel est� despejado" "In teruel it is clear")
	 ("ella pone el ventilador" "she turns on a fan")
	 ("salir" "to leave" "yo salgo" "I leave" "Nunca salgo a correr" "I never run" "salgo a caminar con un amigo" "I go for a walk with a friend" )
	 ("traer" "to bring" "yo traigo" "I bring")
	 ("poner" "to put" "yo pongo" "I put" "pongo mis libros en su lugar" "I put my books in your place" )
	 ("volver" "return")
	 ("ciudad" "city")
	 )
	
	;;tier 23
	(
	 ("nieto" "grandson")
	 ("poner" "to put; turn on" "voy a poner la radio" "I'm going to turn on the radio")
	 ("traer" "to bring" "yo traigo" "I bring")
	 ( "el sobrino" "nephew" )
	 ("llegar" "to arrive")
	 ( "deber" "should" "debemos regresar al autob�s" "we should return to the bus" )
	 ( "aprenden" "learn")
	 ("ganar" "win")
	 ( "La clase de contabilidad es a las doce menos cuarto de la ma�ana" "the accounting class is at 11:45")
	 ( "review when things are at." "")
	 )
	;;(insertVocabList sessionFailedQuestions)
	)
  )

(defun genStemChangingVerbConjugations (word english type)
"A good, but not 100% accurate stem verb conjugation generator.
Argument WORD the spanish word.
Argument ENGLISH the english word.
Argument TYPE ie,ue, or i verb."
  (interactive "sverbo:
sEnglish:
cType (e):ie, (o):ue e:(i):")
  (let
 	  (
 	   (stem)
 	   (ending)
 	   )
	(progn
	  (require 'cl)
	  (string-match "\\(.*\\)\\([aie]\\)r" word)
	  (setq stem (match-string 1 word))
	  (setq ending (match-string 2 word))
	  (setq vosEnding ending)
	  
	  (if (equal ending "i")
		  (setq ending "e")
		)
	  
	  (case type
		(?e
		 (setq newStem (string-replace-match "\\([^e]+\\)e\\(.*\\)"
											 stem "\\1ie\\2"))
		 )
		(?o
		 (setq newStem (string-replace-match "\\([^e]+\\)o\\(.*\\)"
											 stem "\\1ue\\2"))
		 )
		(?i
		 (setq  newStem (string-replace-match "\\([^r][^e]*\\)e\\(.*\\)"
											  stem "\\1i\\2"))
		 )
		)
	  (list
	   word english
	   (concat "yo " newStem "o") (concat "I " english)
	   (concat "t� " newStem ending "s") (concat "you " english)
	   (concat "�l " newStem ending) (concat "he " english "s")
	   (concat "nos. " stem vosEnding "mos") (concat "we " english)
	   (concat "vos. " stem vosEnding "is")  (concat "they(fam) " english)
	   (concat "ellos " newStem ending "n") (concat "they " english)
	   )
	  )
	)
  )

(defun insertSpacedStringsFromList (strList)
  (loop for i in strList do
		(insert "\"" i "\"")
		(insert " ")
		)
  )
	
(defun insertStemChangingVerb (verbo english type)
  ".
Argument VERBO the spanish verb.
Argument ENGLISH The english verb.
Argument TYPE (e):ie, (o):ue e:(i)."(interactive "sverbo:
sEnglish:
cType (e):ie, (o):ue e:(i):")
  (insertSpacedStringsFromList (genStemChangingVerbConjugations verbo english type))
)

;; (while 1   (insert "(")   (call-interactively 'insertStemChangingVerb)   (insert ")\n") )

   
(defconst stemChangingVerbs
  '(
	("cerrar" "close" "ellos cierran" "they close" "T� cierras" "you(fam) close" "nosotros cerramos" "we close" "Ella cierra" "she closes" "yo cierro" "I close" )
	;; ("comenzar"
	("empezar" "begin" "yo empiezo" "I begin" "t� empiezas" "you(fam) begin" "Ud. empieza" "you(form.) begin" "nosotros empezamos" "we begin" "vosotros empez�is" "they(fam) begin" "Ellos empiezan" "they begin")
	("pedir" "ask for" "yo pido" "I ask for" "t� pides" "you(fam) ask for" "Ud. pide" "you(form) ask for" "nosotros pedimos" "we ask for" "vosotros ped�s" "they(fam) ask for" "ellos piden" "they ask for")
	
	("dormir" "sleep" "ella duerme" "she sleeps" "yo duermo" "I sleep" "t� duermes" "you(fam) sleep" "ellos duermen" "they sleep" "nosotros dormimos" "we sleep" )
	("repetir" "repeat" "yo repito" "I repeat" "nosotros repetimos" "we repeat" "�l repite" "he repeats" "ellos repiten" "they repeat")
	("jugar" "play" "ellos juegan" "they play" )
	("entender" "to understand" "entiendo" "I understand")
	("comenzar" "begin" "yo comienzo" "I begin" "t� comienzas" "you begin" "�l comienza" "he begins" "nos. comenzamos" "we begin" "vos. comenzais" "they(fam) begin" "ellos comienzan" "they begin" )
	("pensar" "think" "yo pienso" "I think" "t� piensas" "you think" "�l piensa" "he thinks" "nos. pensamos" "we think" "vos. pensais" "they(fam) think" "ellos piensan" "they think" )
	("perder" "lose" "yo pierdo" "I lose" "t� pierdes" "you lose" "�l pierde" "he loses" "nos. perdemos" "we lose" "vos. perdeis" "they(fam) lose" "ellos pierden" "they lose" )
	("preferir" "prefer" "yo priefero" "I prefer" "t� prieferes" "you prefer" "�l priefere" "he prefers" "nos. preferimos" "we prefer" "vos. preferiis" "they(fam) prefer" "ellos prieferen" "they prefer" )
	("querer" "want" "yo quiero" "I want" "t� quieres" "you want" "�l quiere" "he wants" "nos. queremos" "we want" "vos. quereis" "they(fam) want" "ellos quieren" "they want" )
	("encontrar" "find" "yo encuentro" "I find" "t� encuentras" "you find" "�l encuentra" "he finds" "nos. encontramos" "we find" "vos. encontrais" "they(fam) find" "ellos encuentran" "they find" )
	("mostrar" "show" "yo muestro" "I show" "t� muestras" "you show" "�l muestra" "he shows" "nos. mostramos" "we show" "vos. mostrais" "they(fam) show" "ellos muestran" "they show" )
	("poder" "to be able; can" "yo puedo" "I to be able; can" "t� puedes" "you to be able; can" "�l puede" "he to be able; cans" "nos. podemos" "we to be able; can" "vos. podeis" "they(fam) to be able; can" "ellos pueden" "they to be able; can" )
	("recordar" "remember" "yo recuerdo" "I remember" "t� recuerdas" "you remember" "�l recuerda" "he remembers" "nos. recordamos" "we remember" "vos. recordais" "they(fam) remember" "ellos recuerdan" "they remember" )
	("volver" "return" "yo vuelvo" "I return" "t� vuelves" "you(fam) return" "Ud. vuelve" "you(form) return" "nosotros volvemos" "we return" "vosotros volve�s" "they(fam) return" "ellos vuelven" "they return")
	("conseguir" "get" "yo consigo" "I get" "t� consigues" "you get" "�l consigue" "he gets" "nos. conseguimos" "we get" "vos. conseguiis" "they(fam) get" "ellos consiguen" "they get" )
	("repetir" "repeat" "yo repito" "I repeat" "t� repites" "you repeat" "�l repite" "he repeats" "nos. repetimos" "we repeat" "vos. repetiis" "they(fam) repeat" "ellos repiten" "they repeat" )
	("seguir" "follow" "yo sigo" "I follow" "t� sigues" "you follow" "�l sigue" "he follows" "nos. seguimos" "we follow" "vos. seguiis" "they(fam) follow" "ellos siguen" "they follow" )
	)
  )
  
(defun insertVocabList (vocabList)
  (loop for voc in vocabList do
		(insert "( ")
		(loop for i in voc do
			  (insert "\"" i "\" ")
			  )
		(insert ")")
		(indent-according-to-mode)
		(insert "\n")
		)
  )

(defun getVocabTier (tierNum)
  "Gets a vocab tier:
<0 top tier
   0 is all vocab
   1 tier 1, etc.
Argument TIERNUM the level of vocab to test oneself on."
  (interactive "nEnter tier (<0 for from the end):")
  (if (< tierNum 0)
	  (setq tierNum (+ tierNum (length tieredVocab)))
	)
  (nth tierNum tieredVocab)
  )
  

(defconst arVerbos '(
					 ("bailar" "to dance")
					 ("buscar" "to look for")
					 ("caminar" "to walk")
					 ("cantar" "to sing")
					 ("comprar" "to buy" "el compra libros en la librer�a")
					 ("contestar" "to answer")
					 ("conversar" "to converse")
					 ("descansar" "to rest")
					 ("desear" "to want")
					 ("dibujar" "to draw" "you dibujo un reloj en la pizarra")
					 ("ense�ar" "to teach")
					 ("escuchar" "to listen")
					 ("esperar" "to wait for; to hope")
					 ("estudiar" "to study")
					 ("explicar" "to explain")
					 ("hablar" "to talk")
					 ("llegar" "to arrive")
					 ("llebar" "to carry")
					 ("mirar" "to look at; to watch")
					 ("necesitar" "to need")
					 ("practicar" "to practice")
					 ("preguntar" "to ask")
					 ("preparar" "to prepare")
					 ("regresar" "to return")
					 ("terminar" "to end")
					 ("tomar" "to take; to drink")
					 ("trabajar" "to work")
					 ("viajar" "to travel")
					 
					 )
  "Ar verbs in spanish."
  )

(defconst erVerbos
  '(
	)
  )

(defconst irVerbos
  '(
	("ir" "to go" "yo voy" "t� vas" "you(fam) go)" "�l va" "he goes" "nos. vamos" "we go" "vos. vais" "uds. van")
	)
  )

(defconst irregYoVerbos
  '(
	("hacer" "to do" "yo hago" "I do" "hago muchas cosas los domingos" "I do many things on sundays")
	("poner" "to put" "yo pongo" "I put" "pongo mis libros en su lugar" "I put my books in your place" )
	("salir" "to leave" "yo salgo" "I leave" "Nunca salgo a correr" "I never run" "salgo a caminar con un amigo" "I go for a walk with a friend" )
	("suponer" "to suppose" "yo supongo" "I suppose")
	("traer" "to bring" "yo traigo" "I bring")
	( "o�r" "to hear" "yo oigo" "I hear" "tu oyes" "you(fam) hear" "ella oye" "she hears" "nosotros o�mos" "we hear" "vos. o�s" "you(pl.fam) hear" "ellos oyen" "they hear")
	("ver" "to see" "yo veo" "I see")
	)
  "Verbs that have irregular 'yo' forms."
  )

(defconst weatherPhrases
  '(
	("hace sol" "Its sunny")
	("hace calor" "its hot")
	("hace viento" "its windy")
	("hace fr�o" "its cold")
	("hace fresco" "its cool")
	("llueve" "its raining")
	("nieva" "its snowing")
	("est� nublado" "its cloudy")
	("est� despejado" "its clear")
	("hay niebla" "its foggy")
	("hay contaminaci�n" "its smoggy")
	)
  "Verbs regarding weather."
)

(defconst interrogatives '(
						   ( "�Cu�ndo?" "when?" "�Cu�ndo terminas?" "When do you finish?")
						   ( "�Ad�nde?" "where?")
						   ( "�Cu�l?" "which one?; what?" "�Cu�l te gusta mas?" "which one do you like best?" "�Cu�l es la fecha de hoy?" "What is today's date?" "�Cu�les?" "which ones?")
						   ;( "�Querer?" "to want; to love")
						   ( "�C�mo?" "How?" )
						   ( "�Qu�?" "What?" )
						   ( "�D�nde?" "where?" )
						   ( "�De d�nde?" "from where?" )
						   ( "�Por qu�?" "why?" )
						   ( "�Cu�nto?" "how much?" "�Cu�nto cuesta?" "How much does it cost?" "�Cu�ntos a�os tienes?" "how old are you?" "�Cu�ntos?" "how many?")
						   ( "�Qui�n?" "who?" "�Qui�n es la mujer?" "Who is the woman?" "�Qu�en habla?" "who is speaking?" )
						   ( "�Qui�nes?" "who(pl)?" )
						   )
  )

(defconst estar '(
				  ("yo estoy" "I am")
				  ("t� est�s" "you are")
				  ("Ud./�l/ella est�" "you are; he/she is")
				  ("nosotros/as estamos" "we are")
				  ("vosotros/as est�is" "you (fam.) are")
				  ("Uds./ellos/ellas ext�n" "you(form.)/they are")
				  )
  )

(defun resetVocab ()
  "Set the vocab array back to a full vocab."

  (interactive)
  (setq globalQuestionsList (copy-list vocab))
  )

;; (defun setVocabMode ( c )
;; "sets the question asking mode to spanish or english."
;; (interactive "cvocab mode (s,e):")
;; (case c
;;   (?s (setq askSpanishp t))
;;   (t (setq askSpanishp nil))
;;   )
;; )

(defun initQuestions ()
"Set the global variables for asking vocab."
  (interactive)
  (progn
	(setq askSpanishp (y-or-n-p "Ask spanish? "))
	(setq sessionFailedQuestions nil)
	(setq globalQuestionsList
		  (case (read-char "questions: (v)ocab, p(h)rases, ver(b)os, (i)nterrogatives, (p)repositions (g)lobal failed (e)star")
			(?v (case (read-char "(a)ll vocab (t)iered")
					  (?a vocab)
					  (?t (call-interactively 'getVocabTier)))
				)
			(?h (case (read-char "(g)reetings (w)eather")
				  (?g greetingPhrases)
				  (?w weatherPhrases)
				  )
				)
			(?b (case (read-char "(a)r, (s)tem changing, irreg (y)o")
				  (?a arVerbos)
				  (?s stemChangingVerbs)
				  (?y irregYoVerbos)
				  )
				)
			(?i interrogatives)
			(?p prepositions)
			(?g (copy-list globalFailedQuestions))
			(?e estar)
			)
		  )
	)
  )

;(initQuestions)
(defun askQuestion (question answer)
  "Asks a QUESTION string and nlp's the ANSWER."
  (let
	  (
	   (answerStr)
	   )
	(progn
	  (setq answerStr (read-from-minibuffer question))
	  (if (equal (downcase answerStr) (downcase answer))
		  (progn
			(message (concat "correct: '" answer "' '" question "'"))
			t ;  return true if equal
			)
		;; else ask the user if the answer was right or wrong
		(case (read-char
			   (concat "answer: " answer "\n"
					   " typed: " answerStr "\n"
					   "apparently wrong answer (a)ccept, (i)gnore, (r)etry"))
		  (?a nil)
		  (?i t)
		  (?r (askQuestion question answer))
		  )
		)
	  )
	)
  )

(defun askAndRemoveQuestions (&optional numQuestions)
  "Asks a question from the current global list.
Optional argument NUMQUESTIONS the number of questions to ask."
  (interactive "p" )
  (let
	  (
	   (elem)
	   (question)
	   (answer)
	   (qList)
	   (aList)
	   )
	(progn
	  (if (not numQuestions)
		  (setq numQuestions 1)
		)
	  (loop for i from 1 to numQuestions do
			(setq elem (nth (random (length globalQuestionsList)) globalQuestionsList))
			(if elem
				(progn
				  (if askSpanishp
					  (progn
						(setq qList elem)
						(setq aList (cdr elem))
						)
					(progn
					  (setq qList (cdr elem))
					  (setq aList elem)
					  )
					)
				  ;; set the question and the answer
				  (setq answer (car aList))
				  (setq question (car qList))

				  ;;--------------------
				  ;; ask the question
				  (if (askQuestion (concat "translate: '"question"':")
								   answer )
					  (setq globalQuestionsList
							(remove elem globalQuestionsList))
					;;--------------------
					;; wrong answer. add the question to the failed questions.
					(progn
					  ;; save failed question for this sessions
					  (add-to-list 'sessionFailedQuestions elem)

					  ;; save failed question globally
					  (add-to-list 'globalFailedQuestions elem)

					  ;;--------------------
					  ;; ask extra questions, if wrong
					  (if t ;;nil - if no extra questions
						  (loop for question in (cddr qList) by 'cddr
								for answer in (cddr aList) by 'cddr do
								(if (not (askQuestion question answer))
									;;--------------------
									;; add the failed ones to the list
									(add-to-list 'sessionFailedQuestions
												 (list question answer))
								  )
								)
						)
					  )
					)
				  )
			  ;; out of questions
			  (progn
				(case (read-char (concat "out of questions. "
										 "(r)etry failed, "
										 "(i)nit questions. "))
				  (?r (progn
						(setq globalQuestionsList sessionFailedQuestions)
						(setq sessionFailedQuestions nil)
						)
					  )
				  (?i (initQuestions))
				  )
				)
			  )
			)
	  )
	)
  )


(defconst prepositions '(
						 ( "al lado de" "next to; beside" "La puerta est� al lado de la ventana." )
						 ( "a la derecho de" "to the right of" "El reloj est� a la derecha de la ventana")
						 ( "a la izquierda de" "to the left of" "Rita est� a la izquierda de Julio")
						 ( "en" "in; on" "T� est�s en la clase de psicolog�a" "You're in the psychology class.")
						 ( "cerca de" "near" "Los libros est�n cerca del escritorio.")
						 ( "debajo de" "below" "La mochila est� debajo de la pizzara.")
						 ( "delante de" "in front of" )
						 ( "detr�s de" "behind" )
						 ( "encima de" "on top of" )
						 ( "entre" "between" )
						 ( "lejos de" "far from" "El estadio est� lejos de las residencias." "The stadium is far from the residences")
						 ( "sobre" "on; over" "Los l�pices est�n sobre el cuaderno")
						 )
  )

(defconst mistakes '(
					 ("spanish prepositions")
					 ("when conjugating 'ir + inf', remember to use infinitive: voy a leer el periodico" "I am going TO READ the newspaper" )
					 ( "cerrar is conjugated to cierra not cierre" "to close")
					 ( "seguir -is followed by 'a'" "" "sigue al invierno" "after winter")
					 ( "venir -to come" "I don't know this very well")
					 )
  )

(defconst months '(
				   ("enero" "january")
				   ("febrero" "february")
				   ("marzo" "march")
				   ("abril" "april")
				   ("mayo" "may")
				   ("junio" "june")
				   ("julio" "july")
				   ("agosto" "august")
				   ("septiembre" "september")
				   ("octubre" "october")
				   ("noviembre" "november")
				   ("diciembre" "december")
				   )
  )

(defconst seasons
  '(
	("el invierno" "winter")
	("la primavera" "spring")
	("el verano" "summer")
	("el oto�o" "autumn")
	)
  )

(defun addVocab (span eng)
  "Add vocab to the list.
Argument SPAN the spanish word.
Argument ENG the english word."
  (interactive "sspanish:
senglish:")
  (save-window-excursion
	(beginning-of-buffer)
	(re-search-forward "^(setq vocab '")
	(setq start (point))
	(setq end (save-excursion (forward-sexp) (point)))
	(if (re-search-forward (concat "\"\\(" span "\\|" eng "\\)\"") end t)
		(message (concat "'" span "' or '" eng "' already in vocab"))
	  (progn
		(goto-char end)
		(beginning-of-line)
		(insert "( \"" span "\" \"" eng "\")\n")
		(indentRegion start (point))
		
										;eval the var
		(goto-char start)
		(forward-sexp)
		(forward-line)
		(end-of-line)
		(call-interactively 'eval-last-sexp)
		)
	  )
	)
  )

(defconst usesOfSerorEstar
  '(
	"Uses of ser
a. Nationality and place of origin
b. Profession or occupation
c. Characteristics of people and things
d. Generalizations
e. Possession
f. What something is made of
g. Time and date
h. Where or when an event takes place
"
	"Uses of estar
i. Location or spatial relationships
j. Health
k. Physical states or conditions
l. Emotional states
m.Certain weather expressions
n. Ongoing actions (progressive
")
  )
(provide 'spanish)

;;; spanish.el ends here
