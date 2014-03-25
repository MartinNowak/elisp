;; YODL-fontlock by Azundris and Ayatollah Tatjana von Nuernberg 06/24/00.
;; Subject to the Artistic Licence.  No warrantees of any kind given,
;; no responsibilities taken.  Anything bad happening while or because
;; of this mode is your responsibility, and your responsibility only.

;; * The latest version of this lives on http://www.azundris.com/hacks/
;;
;; * I use this mode with xemacs/mule 21.1 -- it probably does not work
;;   on GNU emacs just yet, sorry.
;;
;; * This mode highlights YODL directives as per YODL 1.31.18, minus those
;;   that are marked depricated in that version's documentation.
;;
;; * Per default, quoted speech is highlighted when occurring as »Speech«.
;;   That's how we like it in Germany (the French do it the other way around).
;;   If that's not what you like, feel free to adjust the mode-syntax-table
;;   below -- preferably from your .emacs using yodl-mode-hook, so your
;;   adjustments will still work with the next version of this mode.
;;
;; * Enjoy!



(defvar yodl-mode-syntax-table nil
  "Syntax table used while in yodl mode.")
(if yodl-mode-syntax-table
    ()
  (setq yodl-mode-syntax-table (make-syntax-table (standard-syntax-table)))
  (modify-syntax-entry ?\( "()" yodl-mode-syntax-table)
  (modify-syntax-entry ?\) ")(" yodl-mode-syntax-table)
  (modify-syntax-entry ?\" "w" yodl-mode-syntax-table)
; (modify-syntax-entry ?» "(«" yodl-mode-syntax-table)
; (modify-syntax-entry ?« ")»" yodl-mode-syntax-table)
  (modify-syntax-entry ?# "<aa" yodl-mode-syntax-table)
  (modify-syntax-entry ?\n ">aa" yodl-mode-syntax-table)
  (modify-syntax-entry ?» "<bb" yodl-mode-syntax-table)
  (modify-syntax-entry ?« ">bb" yodl-mode-syntax-table)
  (modify-syntax-entry ?\+ " " yodl-mode-syntax-table))

(defvar yodl-font-lock-keywords (purecopy
      (list
       ;; quoted speech
;      '("\\<»[^«]+«\\>"
       '("\\<\\(mychapter\\|mypart\\|myssssect\\|mysssect\\|mysubsubsubsect\\|mysubsubsect\\|mysubsect\\|mysect\\|mysubsect\\)\\>"
	 . font-lock-string-face)

       ;; comments
       '("\\<\\(COMMENT\\)\\>"
	 1 font-lock-comment-face)

       ;; stuff affecting the *look*, not the structure (boldface, center etc.)
       '("\\<\\(center\\|em\\|sc\\|tt\\|bf\\|nl\\|sups\\|subs\\|verb\\|startcenter\\|endcenter\\|code\\|file\\|nop\\|starttable\\|endtable\\|table\\|row\\|tcell\\|cells\\|cell\\|columnline\\|rowline\\)\\>"
	 1 font-lock-keyword-face t)

       ;; preprocessor and macro stuff, incl. i18n
       '("\\<\\(metaCOMMENT\\|metalC\\|metaLC\\|setlanguage\\|figure\\|getfigurestring\\|setfigurestring\\|getdatestring\\|setdatestring\\|gettitlestring\\|settitlestring\\|getdtocstring\\|settocstring\\|getchapterstring\\|setchapterstring\\|getpartstring\\|setpartstring\\|getaffilstring\\|setaffilstring\\|getauthorstring\\|setauthorstring\\|DUMMY\\|STARTDEF\\|ENDDEF\\|IFSTREQUAL\\|IFEMPTY\\|IFSTRSUB\\|IFZERO\\|INCLUDELITERAL\\|NOTRANS\\|NOUSERMACRO\\|PARAGRAPH\\|POPCHARTABLE\\|RENAMEMACRO\\|SUBST\\|PUSHCHARTABLE\\|UPPERCASE\\|WARNING\\|TYPEOUT\\|ERROR\\|UNDEFINEMACRO\\|UNDEFINESYMBOL\\|DEFINESYMBOL\\|IFDEF\\|NOEXPAND\\|ATEXIT\\|CHDIR\\|USECOUNTER\\|ADDTOCOUNTER\\|SETCOUNTER\\|NEWCOUNTER\\|COUNTERVALUE\\|DEFINECHARTABLE\\|USECHARTABLE\\ARG\\|redefinemacro\\|redef\\|DEFINEMACRO\\|CHAR\\|INCLUDEFILE\\|notableofcontents\\|notitleclearpage\\|notocclearpage\\|titleclearpage\\|tocclearpage\\|def\\|includefile\\|includeverbatim\\|verbinclude\\|clearpage\\|langle\\|rangle\\)\\>"
	 1 font-lock-preprocessor-face t)

       ;; references
       '("\\<\\(footnote\\|lurl\\|url\\|link\\|[cfkptv]index\\|mailto\\|nemail\\|email\\|ref\\|fig\\|label\\|affiliation\\)\\>"
	 1 font-lock-reference-face t)

       ;; definitions that do not affect the structure of the document (like chapter etc. do)
;       '("\\<\\( \\)\\>"
;	 1 font-lock-variable-name-face)

       ;; mode-specific commands
       '("\\<\\(setlatexfigureext\\|sethtmlfigureext\\|sethtmlfigurealign\\|htmlbodyopt\\|htmlcommand\\|htmltag\\|mancommand\\mscommand\\|roffcmd\\|sgmlcommand\\|sgmltag\\|txtcommand\\|latexcommand\\|latexdocumentformat\\|latexdocumentclass\\|latexpackage\\|latexoptions\\|latexlayoutcmds\\|nosloppyhfuzz\\|whenlatex\\|whenhtml\\|whenman\\|whenms\\|whentxt\\|whensgml\\|htmlnewfile\\|noxlatin\\|standardlayout\\|manpagename\\|manpagesynopsis\\|manpagedescription\\|manpageoptions\\|manpagefiles\\|manpageseealso\\|manpagediagnostics\\|manpagebugs\\|manpageauthor\\|setlatexverbchar\\|setrofftableoptions\\|makeindex\\|LaTeX\\|TeX\\|mbox\\|nodename\\|nodeprefix\\|texinfocommand\\)\\>"
	 1 font-lock-doc-string-face)

       ;; misc
       '("\\<\\(lambda\\|bind\\|ellipsis\\)\\>"
	 1 font-lock-function-name-face t)

       ;; logical break-down
       '("\\<\\(abstract\\|appendix\\|book\\|article\\|report\\|manpage\\|plainhtml\\|[n]?part\\|[nl]?chapter\\|[ln]?subsubsubsect\\|[ln]?subsubsect\\|[ln]?subsect\\|[ln]?sect\\|startdit\\|enddit\\|dit\\|description\\|enumerate\\|eit\\|starteit\\|endeit\\|startit\\|endit\\|itemize\\|it\\|quote\\|paragraph\\|cite\\)\\>"
	 1 font-lock-type-face t)

       ;; security and warnings
       '("\\<\\(PIPETHROUGH\\|SYSTEM\\|verbpipe\\|gagmacrowarning\\|###\\)\\>"
	 1 font-lock-warning-face t)))
       "Expressions to font-lock in yodl-mode.")
(put 'yodl-mode 'font-lock-defaults '(yodl-font-lock-keywords))


(provide 'yodl)


(defun yodl-mode ()
  "Major mode for editing YODL code."
  (interactive)
  (kill-all-local-variables)
  (setq major-mode 'yodl-mode)
  (setq mode-name "YODL")
  (set-syntax-table yodl-mode-syntax-table)
  (run-hooks 'yodl-mode-hook))

;; ends
