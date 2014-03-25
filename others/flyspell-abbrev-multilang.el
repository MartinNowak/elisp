;;; flyspell-abbrev-multilang.el --- Flyspells abbrev for various languages

;; Copyright (C) 2010 Uwe Brauer

;; Author: Uwe Brauer oub@mat.ucm.es
;; Maintainer: Uwe Brauer oub@mat.ucm.es
;; Created: 15 Jul 2010
;; Version: 1.0
;; Keywords:

 
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 1, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; A copy of the GNU General Public License can be obtained from this
;; program's author (send electronic mail to oub@mat.ucm.es) or from
;; the Free Software Foundation, Inc., 675 Mass Ave, Cambridge, MA
;; 02139, USA.

;; LCD Archive Entry:
;; flyspell-abbrev-multilang|Uwe Brauer|oub@mat.ucm.es
;; |Flyspells abbrev for various languages
;; |$Date: 2010/07/18 19:42:58 $|$Revision: 1.1 $|~/packages/flyspell-abbrev-multilang.el

;;; Commentary:

;;; Change log:
 
;;; Code:

(defconst flyspell-abbrev-multilang-version (concat "1." (substring "$Revision: 1.1 $" 13 14))
	"$Id: flyspell-abbrev-multilang.el,v 1.1 2010/07/18 19:42:58 oub Exp oub $
You have to put this file under some sort of version control. Otherwise, 
when byte  compiling or just loading it, you will get an error!!


Report bugs to: Uwe Brauer oub@mat.ucm.es")

;; Idea: use flyspells abbrev mechanism for various languages.
;;
;; Rationale: The word "version" is written "version" in english
;; but "versión" in Spanish. So the abbrev should distinguish both.
;;
;; Implementation: the following possibilities occur to me:

;; either via a Mayor Mode (derive-mode) or via a minor mode both
;; approaches have their pros and cons. 
;; Mayor Mode: Pros: there is just one mayor mode which can be on or off
;; Mayor Mode: Cons: if you use several language you have to write for
;; each mode its language equivalent.  
;; 
;; Minor Mode: Pros: you can combine it with any mayor mode.
;; Minor Mode: Cons: you have to be very careful to turning of one
;; language mode *before* turning on a another  

;; Generalisations: if you want to add you favourite language, you
;; should 
;; 
;;     -  define and abbrev table
;; 
;;     -  define a minor mode
;; 
;;     -  write a turn on/off function for the minor mode
;; 
;;     -  modify the existing ones!!!


;; define abbrev tables
(define-abbrev-table 'castellano-minor-mode-abbrev-table '(
 ("tx" "texto" nil 0)
     ))

(define-abbrev-table 'american-minor-mode-abbrev-table '(
     ("tx" "text" nil 0)
     ))

(define-abbrev-table 'british-minor-mode-abbrev-table '(
     ("tx" "text" nil 0)
     ))


(define-abbrev-table 'deutsch-minor-mode-abbrev-table '(
     ("tx" "text" nil 0)
     ))

(define-abbrev-table 'francais-minor-mode-abbrev-table '(	 ;Version:1.2
     ("tx" "text" nil 0)
     ))

;;define minor modes

(define-minor-mode american-minor-mode 
    nil nil nil nil
    (setq local-abbrev-table
          (if american-minor-mode
              american-minor-mode-abbrev-table)))



(define-minor-mode british-minor-mode
    nil nil nil nil
    (setq local-abbrev-table
          (if british-minor-mode
              british-minor-mode-abbrev-table)))


(define-minor-mode castellano-minor-mode
    nil nil nil nil
    (setq local-abbrev-table
          (if castellano-minor-mode
              castellano-minor-mode-abbrev-table)))
;;            text-mode-abbrev-table)))



(define-minor-mode francais-minor-mode	;Version:1.2
    nil nil nil nil
    (setq local-abbrev-table
          (if francais-minor-mode
              francais-minor-mode-abbrev-table)))



(define-minor-mode deutsch-minor-mode
    nil nil nil nil
    (setq local-abbrev-table
          (if deutsch-minor-mode
              deutsch-minor-mode-abbrev-table)))





;; variable


(defvar ask-abbrev-table  nil				;Version-1.25
"*Variable to check the local-abbrev-table.")

;; functions for tuning on and off the minor modes. 

(defun turn-on-american-mode ()
  "Turn American mode on and all others off."
  (interactive)
  (progn
	(american-minor-mode 0)
	(british-minor-mode 0)
	(castellano-minor-mode 0)
	(deutsch-minor-mode 0)
	(francais-minor-mode 0)
	(american-minor-mode 1)
	(message "American mode is on, all others off.")
	(if defining-abbrev-turns-on-abbrev-mode (abbrev-mode 1))
	(if ask-abbrev-table
		(describe-variable 'local-abbrev-table))))

(defun turn-on-british-mode ()
  "Turn British mode on and all others off."
  (interactive)
  (progn
	(american-minor-mode 0)
	(british-minor-mode 0)
	(castellano-minor-mode 0)
	(deutsch-minor-mode 0)
	(francais-minor-mode 0)
	(british-minor-mode 1)
	(message "British mode is on, all others off.")
	(if defining-abbrev-turns-on-abbrev-mode (abbrev-mode 1))
	(if ask-abbrev-table
		(describe-variable 'local-abbrev-table))))



(defun turn-on-castellano-mode ()
  "Turn Castellano mode on and all others off."
  (interactive)
  (progn
	(american-minor-mode 0)
	(british-minor-mode 0)
	(castellano-minor-mode 0)
	(deutsch-minor-mode 0)
	(francais-minor-mode 0)
	(castellano-minor-mode 1)
	(message "Castellano mode is on, all others off.")
	(if defining-abbrev-turns-on-abbrev-mode (abbrev-mode 1))
	(if ask-abbrev-table
		(describe-variable 'local-abbrev-table))))

(defun turn-on-deutsch-mode ()
  "Turn Deutsch mode on and all others off."
  (interactive)
  (progn
	(american-minor-mode 0)
	(british-minor-mode 0)
	(castellano-minor-mode 0)
	(deutsch-minor-mode 0)
	(francais-minor-mode 0)
	(deutsch-minor-mode 1)
	(message "Deutsch mode is on, all others off.")
	(if defining-abbrev-turns-on-abbrev-mode (abbrev-mode 1))
	(if ask-abbrev-table
		(describe-variable 'local-abbrev-table))))


(defun turn-on-francais-mode ()
  "Turn Francais mode on and all others off."
  (interactive)
  (progn
	(american-minor-mode 0)
	(british-minor-mode 0)
	(castellano-minor-mode 0)
	(deutsch-minor-mode 0)
	(francais-minor-mode 0)
	(francais-minor-mode 1)
	(message "Francais mode is on, all others off.")
	(if defining-abbrev-turns-on-abbrev-mode (abbrev-mode 1))
	(if ask-abbrev-table
		(describe-variable 'local-abbrev-table))))

;; toggle functions
(defun my-toggle-american-or-british-dict ()
  (interactive "_")
  (make-repeat-command 'my-toggle-american-or-british-dict
					   '(my-new-set-british my-new-set-american)))




;; combined functions
(defun my-new-set-castellano ()
  (interactive)
  (my-set-ispell-dict-castellano)
  (turn-on-castellano-mode))



(defun my-new-set-francais ()
(interactive)
(progn
  (my-set-ispell-dict-francais)
  (turn-on-francais-mode)))




(defun my-new-set-german () 
(interactive)
  (my-set-ispell-dict-deutsch)			;Version-1.15
  (turn-on-deutsch-mode))
 
(defun my-new-set-british ()			;Version-1.15
(interactive)
  (my-set-ispell-dict-british)
  (turn-on-british-mode))

(defun my-new-set-american ()			;Version-1.15
(interactive)
  (my-set-ispell-dict-american)
  (turn-on-american-mode))
 

;; ispell setting.


(defun my-set-ispell-dict-british ()
"Set the dict to british the others off"
  (interactive)
	(message "Next Ispell command will use the british dictionary")
	(sleep-for 1)
	(ispell-change-dictionary "british" nil))

(defun my-set-ispell-dict-american ()
"Set the dict to american the others off"
  (interactive)
	(message "Next Ispell command will use the american dictionary")
	(sleep-for 1)
	(ispell-change-dictionary "american" nil)) 

(defun my-set-ispell-dict-castellano ()
"Set the dict to deutsch the others off"
  (interactive)
	(message "Next Ispell command will use the castellano dictionary")
	(sleep-for 1)
	(ispell-change-dictionary "castellano8" nil))

(defun my-set-ispell-dict-francais ()
"Set the dict to francais the others off"
  (interactive)
	(message "Next Ispell command will use the francais dictionary")
	(sleep-for 1)
	(ispell-change-dictionary "francais" nil))

(defun my-set-ispell-dict-deutsch ()
"Set the dict to deutsch8 the others off"
  (interactive)
	(message "Next Ispell command will use the deutsch8 dictionary")
	(sleep-for 1)
	(ispell-change-dictionary "deutsch8" nil))



(provide 'flyspell-abbrev-multilang)

;;; FLYSPELL-ABBREV-MULTILANG.EL ends here


