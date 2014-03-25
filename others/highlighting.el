;;faces

(make-face 'font-lock-number-face)
(set-face-foreground 'font-lock-number-face "#ff9999")

(make-face 'font-lock-math-face)
(set-face-foreground 'font-lock-math-face "#aa66cc")

(make-face 'bufperlface)
(set-face-foreground 'bufperlface "#ee4444")

(make-face 'bufemacslispface)
(set-face-foreground 'bufemacslispface "#ee4400")

(make-face 'bufshellscriptface)
(set-face-foreground 'bufshellscriptface "#ee4488")

(make-face 'buftextface)
(set-face-foreground 'buftextface "#ee8888")

(make-face 'buflatexface)
(set-face-foreground 'buflatexface "#ee0088")

(make-face 'bufbibtexface)
(set-face-foreground 'bufbibtexface "#ee0044")

(make-face 'bufmakefileface)
(set-face-foreground 'bufmakefileface "#eebbbb")

(make-face 'bufcface)
(set-face-foreground 'bufcface "#eebb88")

(make-face 'bufforface)
(set-face-foreground 'bufforface "#eebbff")

(make-face 'bufremoteface)
(set-face-foreground 'bufremoteface "#88bbff")

(make-face 'remote-face1)
(set-face-foreground 'remote-face1 "#667744")

(make-face 'datafileface)
(set-face-foreground 'datafileface "#aa6677")

(make-face 'remote-face2)
(set-face-foreground 'remote-face2 "#aa22ff")

(make-face 'remote-face3)
(set-face-foreground 'remote-face3 "#eebb44")


;;functions

;;for regexps see -- eg
;;http://dp.iit.bme.hu/mosml/doc/telepites-emacs-sml.txt and
;;http://www.emacswiki.org/cgi-bin/wiki.pl?AddKeywords


;;can use . font-lock-number-face)))) instead of (0 font-lo...., but this seems to negate the affect of comments
(defun add-fixme-highlighting ()
  "Turn on extra highlighting for 'FIXME' and the like."
  (interactive)
  (font-lock-add-buffer-keywords
   '(("\\<\\(\\(FIXME\\|TODO\\|WARNING\\|XXX+\\):.*\\)" 0 font-lock-warning-face))))   ; fortran-mode seems broken for the time being - it
;used to let me put a prepend there, so it would work in comments, but not disable the colouring of the rest of the comment, but it seems broken now
;  (font-lock-add-buffer-keywords
;   '(("\\<\\(FIXME\\):" 1 font-lock-warning-face prepend)
;     ("\\<\\(and\\|or\\|not\\)\\>" . font-lock-keyword-face))))

(defun add-math-highlighting ()
  "Turn on extra highlighting for 'COS()' and the like."
  (interactive)
  (font-lock-add-buffer-keywords
   '(("\\<\\(d\\|c\\)?a?\\(cos\\|sin\\|tan\\|tan\\|tan2\\|sqrt\\|exp\\|abs\\|int\\|min\\|max\\|sign\\|log\\|log10\\)h?\\>" 0 font-lock-math-face
                                                      prepend))))


; (1 font-lock-warning-face prepend) (2 font-lock-warning-face prepend)

;  (font-lock-add-buffer-keywords
;   '(("\\<\\(FIXME\\):" 1 font-lock-warning-face prepend)
;     ("\\<\\(and\\|or\\|not\\)\\>" . font-lock-keyword-face))))


(defun add-number-highlighting ()
  "Turn on extra highlighting for numbers."
  (interactive)
  (font-lock-add-buffer-keywords
                                        ;                                                            __fortran 0.6d0 format
   '(("\\<\\(\\(0[xX][0-9a-fA-F]+[lL]?\\|[0-9]+\\.?[0-9]*\\([eEdD][-+]?[0-9]+\\)?\\([lL]\\|[fF]\\|[dD]\\)?0?\\)\\|M_PI\\)\\>" 0 font-lock-number-face
      prepend))))




;(defun pretty-lambdas ()x
;  (interactive)
;;;makify lambda's pretty :)
;  (font-lock-add-buffer-keywords
;   '(("\\<lambda\\>"
;          (1 (progn (compose-region (match-beginning 0) (match-end 0)
;                                    ,(make-char 'greek-iso8859-7 107))
;                    nil))))))



;(add-hook 'c-mode-common-hook 'add-fixme-highlighting)
(add-hook 'find-file-hooks '(lambda ()
                              (setq-default font-lock-keywords-case-fold-search t)) t)
(add-hook 'find-file-hooks 'add-fixme-highlighting t)
(add-hook 'find-file-hooks 'add-math-highlighting t)
(add-hook 'find-file-hooks 'add-number-highlighting)
(add-hook 'find-file-hooks 'font-lock-fontify-buffer) ;;need to fontify again, since it seems to be already formatted by the time we get here


;;c-mode-common-hook?
;(add-hook 'c-mode-common-hook 'add-number-highlighting)
;(add-hook 'emacs-lisp-mode-hook 'pretty-lambdas)
(add-hook 'shell-mode-hook 'ansi-color-for-comint-mode-on)




;;Get c-x c-b to do funky colors.

(defconst Electric-buffer-menu-mode-font-lock-keywords
  (purecopy
   (list
    '("^ MR Buffer.*"                 . font-lock-preprocessor-face) ;hdr 1
    '("^ -- ------.*"              . font-lock-preprocessor-face) ;hdr 2
;       '("/.*@.*"                     . bufremoteface) ; remote connections file
    '("/\\[.*astronomy.swin.edu.au\\]"  . remote-face1)
    '("/\\[.*puzzling.org\\]"           . remote-face2)
    '("/\\[.*hexane.*\\]"               . remote-face3)
    '("^\\(....Man: .*\\)"         1 font-lock-variable-name-face t) ;Manpg (new)
    '("^[. ][*][^%].[^*].*"        . font-lock-comment-face) ;Mod x temp
    '("^....[*]Buffer List[*].*"   . font-lock-doc-string-face) ;Buffer list
    '("^\\(....[*]shell.*\\)"      1 font-lock-reference-face t) ;shell buff
    '("^....[*].*"                 . font-lock-string-face) ;Temp buffer
    '("^....[+].*"                 . font-lock-keyword-face) ;Mail buffer
    '("^....[A-Za-z0-9/]*[-][+].*" . font-lock-keyword-face) ;Mail buffer
    '(".*Dired"                    . font-lock-function-name-face)
    '(".*CPerl"                    . bufperlface) ; Perl source file
    '(".*Emacs[^ ]*"               . bufemacslispface) ; Emacs Lisp source file
    '(".*Shell[^ ]*"               . bufshellscriptface) ; 
    '(".*Text"                     . buftextface) ; 
    '(".*LaTeX"                    . buflatexface) ; 
    '(".*BibTeX"                   . bufbibtexface) ; 
    '(".*C "                       . bufcface) ; 
    '(".*Fortran"                  . bufforface) ; 
    '(".*[^ ]  Makefile"           . bufmakefileface) ; 
    '(".*\\.par.*"           . datafileface) ; 
    )))

; This hook run after buffer formatted, so it is necessary to re-fontify it...
(add-hook 'electric-buffer-menu-mode-hook
          '(lambda ()
             (font-lock-mode 1)
             (font-lock-fontify-buffer)))

