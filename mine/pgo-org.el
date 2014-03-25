;;; pgo-org.el --- Setup Org and its Extensions.
;; Author: Per Nordlöw

;;; org-assoc-tags.el
;; You can define a key-tag and list of associated tags.
;; Every time you set a key-tag to the item, associated tags
;; assign automatically.
(when (eload 'org-assoc-tags)
  )

(when (eload 'org-install)
  )

;; This will result in the following replacements:
;; S-RET → C-S-RET
;; S-up → M-p
;; S-down → M-n
;; S-left → M--
;; S-right → M-+
(setq org-CUA-compatible t)

;; Dragging URLs: http://www.emacswiki.org/emacs-en/OrgMode#toc9
(defadvice dnd-insert-text (around org-mouse-dnd-insert-text activate)
  (if (eq major-mode 'org-mode)
      (progn
	(cond
	 ;; if this is the end of the line then just insert text here
	 ((eolp)
	  (skip-chars-backward " \t")
	  (kill-region (point) (point-at-eol))
	  (unless (looking-back ":") (insert ":"))
	  (insert " "))

	 ;; if this is the beginning of the line then insert before
	 ((and (looking-at " \\|\t")
	       (save-excursion
		 (skip-chars-backward " \t") (bolp)))
	  (beginning-of-line)
	  (looking-at "[ \t]*")
	  (open-line 1)
	  (indent-to (- (match-end 0) (match-beginning 0)))
	  (insert "+ "))

	 ;; if this is a middle of the line, then insert after
	 (t
	  (end-of-line)
	  (newline t)
	  (indent-relative)
	  (insert "+ ")))
	(insert text)
	(beginning-of-line))
    ad-do-it))
(ad-activate 'dnd-insert-text)

;;; org-export-latex.el --- LaTeX exporter for org-mode
(when (eload 'org-export-latex)
  )

;;; org-toc.el --- Table of contents for Org-mode buffer
(when (eload 'org-toc)
  )

;;; org-registry.el --- a registry for Org links
(when (eload 'org-registry)
  (org-registry-initialize)
  ;; If you want to update the registry with newly inserted links in the
  ;; current buffer: M-x org-registry-update
  ;; If you want this job to be done each time you save an Org buffer,
  ;; hook 'org-registry-update to the local 'after-save-hook in org-mode:
  ;; (org-registry-insinuate)
  )

;;; org-annotation-helper.el --- start remember from a web browser
(when (eload 'org-annotation-helper)
  )

;;; bibtex-utils.el --- utilities for BibTeX
(when (eload 'bibtex-utilsn)
  )

;;; org-expiry.el --- expiry mechanism for Org entries
(when (eload 'org-expiry)
  )

;;; org-export.el --- Export engine for Org
(when (eload 'org-export)
  )

;;; org-export-latex.el --- LaTeX exporter for org-mode
(when (eload 'org-export-latex)
  )

;;; org-iswitchb.el --- use iswitchb to select Org buffer
(when (eload 'org-iswitchb)
  )

;;; org-org.el --- Org links to Org entries
(when (eload 'org-org)
  )

;;; org2rem.el --- Convert org appointments into reminders
(when (eload 'org2rem)
  )

;;; bzg-org.el --- Additional functions for Org
(when (eload 'bzg-org)
  )

;;; screencast.el --- functions to help making Emacs screencasts
;;(when (eload 'screencast t)
;;  )

;;; org-mairix.el - Support for hooking mairix search into Org for
;;; different MUAs
(when (eload 'org-mairix)
  )

;;; org-extension.el --- Some extensions for Org mode
(when (eload 'org-extension)
  )

;;; org-pua.el --- Org pop-up annotation
(when (eload 'org-pua)
  ;;     (global-set-key [(control c) f1] 'org-pua-annotate)
  ;;     (global-set-key [(control c) (control f1)] 'org-pua-toggle-buttons)
  ;; To change the location of the annotation file:
  ;;     (setq org-pua-annotations-file "~/annotated.org")
  )

;;; org-mumamo.el --- MuMaMo in org-mode.
(when (eload 'org-mumamo)
  )

(provide 'pgo-org)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; pgo-org.el ends here
