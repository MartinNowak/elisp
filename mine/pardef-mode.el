;;; pardef-mode.el --- GNU Emacs major mode for editing TVA SP PARDEF-files

;;; Code:

(defgroup pardef-mode nil
  "Pardef mode."
  :group 'wp
  :prefix "pardef-")

(defvar pardef-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map "\es" 'center-line)
    map)
  "Major mode keymap for `pardef-mode'.")

(defvar pardef-mode-syntax-table
  (let ((st (copy-syntax-table text-mode-syntax-table)))
    ;; " isn't given string quote syntax in text-mode but it
    ;; (arguably) should be for use round pardef arguments (with ` and
    ;; ' used otherwise).
    ;;(modify-syntax-entry ?\" "\"  2" st)
    ;; Comments are delimited by \" and newline.
    ;;(modify-syntax-entry ?\\ "\\  1" st)
    ;;(modify-syntax-entry ?\n ">  1" st)
    st)
  "Syntax table used while in `pardef-mode'.")

(defconst pardef-keywords
  (list "Select" "Bblock" "Fblock" "Antenn" "Master" "Slav" "Period" "Strategi"
	"Delband" "Profil" "Bber" "Mstider" "Autotrosk" "Filslut")
  "Keywords to highlight in Pardef mode.")

(defconst pardef-variables
  (list "orient" "missv" "konv"
	"lat" "lon" "ip" 
	"flag" "flag2" 
	"gtid" "gbaring" "gamplitud" 
	"gkorrtal" "uantal" 
	"maxhtid" "maxstid" 
	"shnr" "nhnr" "fhnr"
	"logkod" 
	"itid" "ibar" "iamp" 
	"vtid" "vbar" "vamp" "vpri"
	"valder" "malder"
	"rakn" 
	"barsek1" "barsek2" 
	"antfix" "anthop" 
	"msdelay" "msmax"
	"active" "lowb" "highb" "lowlim" "highlim")
  "Variables to highlight in Pardef mode.")

(defconst pardef-comment-start "#"
  "Start pattern for comments")

;; NOTE: The one in 1 'font-lock-comment-face means that the regular expression ;; is actually a function that returns one 1 category 
(defconst pardef-font-lock-keywords
  (progn
    (require 'font-lock)
    (list
     ;; Comments
     (list (concat "\\([ \t]*" pardef-comment-start ".*\\)$") 
	   1 'font-lock-comment-face)
     ;; Keywords
     (list (concat
	    "\\<\\("
	    (mapconcat 'identity
		       pardef-keywords
		       "\\|")
	    "\\)\\>")
	   1 font-lock-keyword-face)
     ;; Variables
     (list (concat
	    "\\<\\("
	    (mapconcat 'identity
		       pardef-variables
		       "\\|")
	    "\\)\\>")
	   1 font-lock-variable-name-face)
     ;; String Literals
     (list "\\(\".*\"\\)" 1 font-lock-string-face)
     ;; Dotted quads
     (list (mapconcat 'identity
		      (make-list 4 "[0-9]+")
		      "\\.")
	   0 font-lock-variable-name-face)
     ))
  "Expressions to font-lock in Pardef mode.")

(defcustom pardef-mode-hook nil
  "Hook run by function `pardef-mode'."
  :type 'hook
  :group 'pardef-mode)

;;;###autoload
(define-derived-mode pardef-mode text-mode "FOI SP Parametrar"
  "Major mode for editing text intended for Pardef to format.
\\{pardef-mode-map}
Turning on Pardef mode runs `text-mode-hook', then `pardef-mode-hook'."
  (set
   (make-local-variable 'font-lock-defaults)
   '((pardef-font-lock-keywords)))
  (set (make-local-variable 'comment-start) "# ")
  (set (make-local-variable 'comment-start-skip) "\\\\\"[ \t]*")
  (set (make-local-variable 'comment-column) 40)
  )

(provide 'pardef-mode)

;;; pardef-mode.el ends here
