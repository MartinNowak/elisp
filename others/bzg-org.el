;;; bzg-org.el --- Additionnal functions for Org
;;
;; Copyright 2007 2008 Bastien Guerry
;;
;; Author: Bastien.Guerry@ens.fr
;; Version: $Id: bzg-org.el,v 0.2 2007/08/07 12:51:25 guerry Exp guerry $
;; Keywords: Org Appointment
;; X-URL: http://www.cognition.ens.fr/~guerry/u/bzg-org.el
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
;;
;;; Commentary:
;;
;; Here are a few functions i'm often using with `org-mode'. 
;;
;; Put this file into your load-path and the following into your ~/.emacs:
;;   (require 'bzg-org)
;;
;;; Code:

(eval-when-compile
  (require 'cl))
(provide 'bzg-org)

;; ;; Make appt aware of appointments from the agenda
;; (defun bzg-org-agenda-to-appt ()
;;   "Activate appointments found in `org-agenda-files'."
;;   (interactive)
;;   (require 'org)
;;   (let* ((today (org-date-to-gregorian
;; 		 (time-to-days (current-time))))
;; 	 (files org-agenda-files) entries file)
;;     (while (setq file (pop files))
;;       (setq entries (append entries (org-agenda-get-day-entries
;; 				     file today :timestamp))))
;;     (setq entries (delq nil entries))
;;     (mapc (lambda(x)
;; 	    (let* ((event (org-trim (get-text-property 1 'txt x)))
;; 		   (time-of-day (get-text-property 1 'time-of-day x)) tod)
;; 	      (when time-of-day
;; 		(setq tod (number-to-string time-of-day)
;; 		      tod (when (string-match 
;; 				  "\\([0-9]\\{1,2\\}\\)\\([0-9]\\{2\\}\\)" tod)
;; 			     (concat (match-string 1 tod) ":" 
;; 				     (match-string 2 tod))))
;; 		(if tod (appt-add tod event))))) entries)))

;; List timestamped entries found in `org-agenda-files'. Restrict the
;; results to entries matching MATCH. You can use this function inside
;; `org-agenda-custom-commands'

;;; Extensions
;; (define-key global-map "\C-ci" 'bzg-step-time-report-initialize)
;; (define-key org-mode-map "\C-cn" 'bzg-step-time-report-add-step)
;; (define-key org-mode-map "\C-co" 'bzg-step-time-report-finish)
;; (define-key org-agenda-mode-map "\C-n" 'next-line)
;; (define-key org-agenda-keymap "\C-n" 'next-line)
;; (define-key org-agenda-mode-map "\C-p" 'previous-line)
;; (define-key org-agenda-keymap "\C-p" 'previous-line)

;;; FIXME

;; (defun org-convert-items-to-entries (&optional level)
;;   "Convert the list items at point into entries.
;; If LEVEL is nil, entries are one level under the entry above."
;;   (interactive "P")
;;   (let* ((odd org-odd-levels-only)
;; 	 (l0 (if level (prefix-numeric-value level)
;; 	       (save-excursion
;; 		 (org-back-to-heading)
;; 		 (looking-at org-complex-heading-regexp)
;; 		 (1+ (length (match-string 1))))))
;; 	 (l odd (1- (/ (1+ asters) 2)) (1- asters))
;; )
;;     (org-preserve-lc
;;      (org-beginning-of-item-list)
;;      (org-at-item-p)
;;      (replace-match (make-string l ?*) t t nil 1))))


;; FIXME: Delete clock with appt-delete when clocking out?
;; Make sure you have a sensible value for `appt-message-warning-time'
(defun my-org-appt-add (&optional n)
  "Add an appointment for the Org entry at point in N minutes."
  (interactive)
  (save-excursion
    (org-back-to-heading t)
    (looking-at org-complex-heading-regexp)
    (let* ((msg (concat (match-string-no-properties 4) 
			" *GAME OVER*"))
	   (ct-time (decode-time))
	   (appt-min (+ (cadr ct-time) (or n 27)))
	   (appt-time ; define the time for the appointment
	    (progn (setf (cadr ct-time) appt-min) ct-time)))
      (appt-add (format-time-string  
		 "%H:%M" (apply 'encode-time appt-time)) msg)
      (if (interactive-p) (message "New appointment for %s" msg)))))

(defadvice org-clock-in (after org-appt-add-after-clock-in activate)
  "Add an appointment after clocking in a task."
  (my-org-appt-add))

(defun bzg-org-agenda-list (&optional number)
  (interactive "P")
  (org-agenda-list nil nil (or number 30)))

(defun bzg-print-agenda ()
  "htmlize org-mode's agenda"
  (interactive)
  (save-window-excursion
    (let ((todo-buffer "*Org Agenda*"))
      (org-todo-list "NEXT")
      (set-buffer (htmlize-buffer))
      (write-file "~/public_html/org/homepage/next.html")
      (kill-this-buffer)
      (kill-buffer todo-buffer))))

(defun bzg-org-abbrev-linkify-region (beg end)
  "Convert the selected region into an abbreviated link."
  (interactive "r")
  (let ((abbrev
	 (completing-read 
	  "Abbrev: " 
	  (mapcar (lambda (x) (list (concat (car x) ":")))
		  (append org-link-abbrev-alist-local 
			  org-link-abbrev-alist))))
	(reg (buffer-substring beg end)))
    (delete-region beg end)
    (insert (org-make-link-string (concat abbrev reg) reg))))

(defun bzg-org-googlify-region (beg end)
  "Convert the selected region into a google search.
This require that \"google\" is an abbreviated link for
http://www.google.com/search?q=%s"
  (interactive "r")
  (let ((query (buffer-substring beg end)))
    (delete-region beg end)
    (insert (org-make-link-string (concat "google:" query) query))))

(defun bzg-org-convert-to-plain-list (beg end)
  "Convert each line in the region into a plain list."
  (interactive "r")
  (string-rectangle beg end "- "))

(defun bzg-org-convert-to-headings (beg end)
  "Convert each line in the region into subheadings."
  (interactive "r")
  (let ((stars (save-excursion
		 (re-search-backward org-complex-heading-regexp nil t)
		 (or (match-string 1) "*")))
	(add-stars (if org-odd-levels-only "**" "*")))
    (string-rectangle beg end (concat add-stars stars " "))))

(define-key org-mode-map (kbd "C-c C--") 'bzg-org-convert-to-list)
(define-key org-mode-map (kbd "C-c C-*") 'bzg-org-convert-to-headings)

(setq org-todo-list-buffer "~/org/bzg.org")
(setq org-email-todo-tree-header "** Email TODOS")
(setq org-swish-todo-tree-header "** Swish TODOS")
(setq org-url-todo-tree-header "** URL TODOS")

(defun org-insert-email-as-current-todo (&optional kw)
  "Save a Gnus email into `org-todo-list-buffer' as a headline.
If prefix is non-nil, ask for a specific state."
  (interactive "P")
  (let ((link (org-store-link nil)))
    (save-window-excursion
      (find-file org-todo-list-buffer)
      (goto-char (point-min))
      (let ((state (if kw (completing-read "State: " 
					   (mapcar (lambda(x) (list x))
						   org-not-done-keywords)
					   nil t "TODO") "TODO"))
	    (point (re-search-forward 
		    (regexp-quote org-email-todo-tree-header)
		    (point-max) nil)))
	(org-end-of-subtree t)
	(insert "\n*** " state " " link))))
  (message "Email saved in %s" org-todo-list-buffer))

(defun org-insert-slashdot-entry-as-current-todo (&optional kw)
  "Save a slashdot email entry `org-todo-list-buffer' as a headline.
If prefix is non-nil, ask for a specific state."
  (interactive "P")
  (let ((url (save-excursion
	       (re-search-forward org-plain-link-re nil t)
	       (match-string 0)))
	(desc (save-excursion
		(backward-paragraph)
		(re-search-forward "^.+$" nil t)
		(match-string 0))))
    ;;		(aref gnus-current-headers 3)
    (save-window-excursion
      (find-file org-todo-list-buffer)
      (goto-char (point-min))
      (let ((state (if kw (completing-read "State: " 
					   (mapcar (lambda(x) (list x))
						   org-not-done-keywords)
					   nil t "TODO") "TODO"))
	    (point (re-search-forward
		    (regexp-quote org-url-todo-tree-header)
		    (point-max) nil)))
	(org-end-of-subtree t)
	(insert "\n*** " state " [[" url "][" desc "]]"))))
  (message "URL saved in %s" org-todo-list-buffer))

(defun bzg-insert-url-as-current-todo (&optional kw)
  "Save a w3m buffer into `org-todo-list-buffer' as a headline.
If prefix is non-nil, ask for a specific state."
  (interactive "P")
  (let ((url (format "[[%s][%s]]" w3m-current-url 
		     (or w3m-current-title w3m-current-url))))
    (save-window-excursion
      (find-file org-todo-list-buffer)
      (goto-char (point-min))
      (let ((state (if kw (completing-read "State: " 
					   (mapcar (lambda(x) (list x))
						   org-not-done-keywords)
					   nil t "TODO") "TODO"))
	    (point (re-search-forward
		    (regexp-quote org-url-todo-tree-header)
		    (point-max) nil)))
	(org-end-of-subtree t)
	(insert "\n*** " state " " url))))
  (message "URL saved in %s" org-todo-list-buffer))

;; (defun bzg-imagerotator-make-playlist-from-buffer nil
;;   "Make a playlist for imagerotator from buffer."
;;   (interactive)
;;   (let* ((relative-dir "u/") ; where uploaded files go
;; 	 (filename (file-name-nondirectory 
;; 		    (file-name-sans-extension (buffer-file-name))))
;; 	 (html-filename (concat filename ".html"))
;; 	 (playlist-filename (concat filename "_images.xml"))
;; 	 playlist entry)
;;     (save-excursion
;;       (goto-char (point-min))
;;       (while (re-search-forward org-bracket-link-analytic-regexp nil t)
;; 	(let ((type (match-string 2))
;; 	      (file (match-string 3)))
;; 	  (if (and (equal type "file") 
;; 		   (string-match (image-file-name-regexp) file))
;; 	      (add-to-list 'playlist file t))))
;;       (find-file (concat relative-dir playlist-filename))
;;       (erase-buffer)
;;       (insert "<playlist version=\"1\" xmlns=\"http://xspf.org/ns/0/\">\n")
;;       (insert "  <trackList>\n")
;;       (when playlist
;; 	(mapc (lambda(x) (insert (format bzg-image-rotator-entry-format
;; 					 x user-full-name x html-filename)))
;; 	      playlist))
;;       (insert "  </trackList>\n</playlist>")
;;       (write-file playlist-filename nil)
;;       (kill-buffer (current-buffer)))))

;; image rotator
;; (defvar bzg-image-rotator-entry-format
;;   "    <track>
;;       <title>%s</title>
;;       <creator>%s</creator>
;;       <location>%s</location>
;;       <info>%s</info>
;;     </track>\n"
;;   "The format of an imagerotator entry")

;; (defun org-dblock-write:imagerotator (params)
;;   "Insert an imagerotator block in org."
;;   (let* ((float (plist-get params :float))
;; 	 (dir (plist-get params :dir))
;; 	 (playlist (concat dir (plist-get params :filename))))
;;     (insert 
;;      (format "<div style=\"float: %s; margin: 1.4em 0em 0em 0em;\">
;; <script type=\"text/javascript\" src=\"https://media.dreamhost.com/ufo.js\"></script>
;; <p id=\"%s\">
;; <a href=\"http://www.macromedia.com/go/getflashplayer\">
;; Get the Flash Player</a> to see this player.</p>
;; <script type=\"text/javascript\">
;; var FO = { movie:\"%simagerotator.swf\",width:\"300\",height:\"157\",majorversion:\"7\",build:\"0\",bgcolor:\"#000000\",
;; flashvars:\"file=%s&amp;transition=random\" };
;; UFO.create(FO,\"%s\");
;; </script>
;; </div>" float playlist dir playlist playlist))))

(defun bzg-dewslider-make-playlist-from-buffer nil
  "Make a playlist for dewslider from buffer."
  (interactive)
  (let* ((relative-dir "u/") ; where uploaded files go
	 (filename (file-name-nondirectory 
		    (file-name-sans-extension (buffer-file-name))))
	 (html-filename (concat filename ".html"))
	 (playlist-filename (concat filename "_images.xml"))
	 playlist entry)
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward org-bracket-link-analytic-regexp nil t)
	(let ((type (match-string 2))
	      (file (match-string 3)))
	  (if (and (equal type "file") 
		   (string-match (image-file-name-regexp) file))
	      (add-to-list 'playlist file t))))
      (find-file (concat relative-dir playlist-filename))
      (erase-buffer)
      (insert "<?xml version=\"1.0\" ?>
<album
showbuttons=\"yes\"
showtitles=\"yes\"
randomstart=\"yes\"
timer=\"5\"
aligntitles=\"bottom\"
alignbuttons=\"bottom\" >\n")
      (when playlist
	(mapc (lambda(x) 
		(insert (format "  <img src=\"%s\" title=\"%s\" />\n" x x)))
	      playlist))
      (insert "</album>")
      (write-file playlist-filename nil)
      (kill-buffer (current-buffer)))))

(defun org-dblock-write:insert-file (params)
  "Insert a header from a file."
  (let ((file (plist-get params :file)))
    (if (file-exists-p file)
	(insert-file-contents file)
      (error "File %s cannot be found" file))))

(defun org-dblock-write:dewslider (params)
  "Insert an dewslider block in org."
  (let* ((dir (plist-get params :dir))
	 (playlist (concat dir (plist-get params :filename)))
	 (width (plist-get params :width))
	 (float (plist-get params :float))
	 (height (plist-get params :height)))
    (insert 
     (format 
"<div style=\"float: %s;\">\n<object type=\"application/x-shockwave-flash\" data=\"%sdewslider4.swf?xml=%s\" width=\"%s\" height=\"%s\">
<param name=\"movie\" value=\"%sdewslider4.swf?xml=%s\" />
</object>\n</div>" float dir playlist width height dir playlist))))

;; (defun bzg-org-agenda-timestamp (match)
;;   "List timestamped entries found in `org-agenda-files'.
;; Restrict the results to entries matching MATCH."
;;   (interactive)
;;   (let* ((today (org-date-to-gregorian (time-to-days (current-time))))
;; 	 (files org-agenda-files) entries file pos)
;;     (while (setq file (pop files))
;;       (let ((entry (mapcar '(lambda(e) (when (string-match match e) e))
;; 			    (org-agenda-get-day-entries
;; 			     file today :timestamp))))
;; 	(setq entry (delq nil entry))
;; 	(setq entries (append entries entry))))
;;     (setq entries (delq nil entries))
;;     (org-prepare-agenda "TIMESTAMPS")
;;     (setq pos (point))
;;     (insert (format "Time-stamped entries matching: \"%s\"\n" match))
;;     (add-text-properties pos (1- (point)) (list 'face 'org-agenda-structure))
;;     (insert (org-finalize-agenda-entries entries))
;;     (org-finalize-agenda)))

;; A dynamic blocks to insert infos about author, date, etc.
(defun org-dblock-write:intro (params)
  (let* ((options (org-infile-export-plist))
	 (email (or (plist-get params :email) 
		    (plist-get options :email)))
	 (author (or (plist-get params :author) 
		     (plist-get options :author)))
	 (subtitle (or (plist-get params :subtitle) 
		       (plist-get options :text)))
	 (ts-format (or (plist-get params :ts-format)
			(car org-time-stamp-formats)))
	 (timestamp (format-time-string ts-format)))
    (insert (format "%s @<br/>\nBy [[mailto:%s][%s]] - %s"
		    subtitle email author timestamp))))

;; Insert a digg iframe
(defun org-dblock-write:digg (params)
  "Insert a digg iframe."
  (let* ((float (plist-get params :float))
	 (abs-url (plist-get params :url))
	 (div-beg (if float (format "<div style=\"float: %s;\">\n" float) ""))
	 (div-end (if float "</div>" "")))
    (insert div-beg "<iframe src=\"http://digg.com/api/diggthis.php?u=")
    (insert abs-url "\" frameborder=\"0\" height=\"82\" scrolling=\"no\" width=\"55\"></iframe>\n")
    (insert div-end)))

;; Insert social bookmarking stuff - requires blorg
;; http://www.cognition.ens.fr/~guerry/u/blorg.el
;; (defvar blorg-echos-alist nil) ; dynamically scoped
(defun org-dblock-write:echoes (params)
  "Insert social bookmarking links."
  (if (require 'blorg)
    (let* ((options (org-infile-export-plist))
	   (tags (mapconcat (lambda(x) (car x)) org-tag-alist " "))
	   (post-abs-url (plist-get params :url))
	   (blorgv-post-title 
	    (or (plist-get params :title)
		(plist-get options :title)))
	   (post-tags (or (plist-get params :tags) tags)))
      (mapc (lambda(x) 
	      (setq x (mapcar (lambda(a) (unless (stringp a)) (eval a)) x))
	      (insert (apply 'format x) "\n"))
	  blorg-echos-alist))))

;; Insert a timestamp
(defun org-dblock-write:timestamp (params)
  "Insert a simple timestamp.
Params are: string (like \"Updated: \"
            format (the formatting string)"
  (let ((string (or (plist-get params :string) "Updated: "))
	(time-format (or (plist-get params :format)
			 (car org-time-stamp-formats))))
    (insert string (format-time-string time-format))))

;; Insert a timestamp
(defun org-dblock-write:timestampfr (params)
  "Insert a simple timestamp in french.
Params are: string (like \"Updated: \"
            format (the formatting string)"
  (let ((string (or (plist-get params :string)
		    "Dernière mise à jour: "))
	(time-format (or (plist-get params :format)
			 (car org-time-stamp-formats))))
    (insert string (format-time-string time-format))))

;; Make reports with steps
(defvar bzg-step-time-report-time nil)

(defun bzg-step-time-report-initialize (project)
  "Insert a 1st-level project at point."
  (interactive "sProject name: ")
  (insert "* " project)
  (org-insert-property-drawer)
  (org-entry-put (point) "COLUMNS" "%25ITEM %5Elapsed_time(Elapsed Time){:}")
  (next-line 2)
  (setq bzg-step-time-report-time (current-time)))

(defun bzg-step-time-report-add-step (&optional step)
  "Update elapsed time for previous step and insert the next one."
  (interactive "P")
  (let ((elapsed-time
	 (format-time-string 
	  "%H:%M" (time-since bzg-step-time-report-time)))
	(step-name (when step (read-from-minibuffer "Step name: "))))
    (org-entry-put (point) "Elapsed_time" elapsed-time)
    (insert "** " (or step-name "Step"))
    (org-insert-property-drawer)
    (org-entry-put (point) "Elapsed_time" nil)
    (next-line 2)
    (setq bzg-step-time-report-time (current-time))))

(defun bzg-step-time-report-finish ()
  "Update elapsed time for previous step."
  (interactive)
  (let ((elapsed-time
	 (format-time-string 
	  "%H:%M" (time-since bzg-step-time-report-time) t)))
    (org-entry-put (point) "Elapsed_time" elapsed-time)))

(defun bzg-org-agenda-skip-if-below-level ()
  "Function that can be used in `org-agenda-skip-function',
to skip entries that are below a level 1 and 2."
  (let (beg end)
    (org-back-to-heading t)
    (setq beg (point))         ; beginning of headline
    (outline-next-heading)
    (setq end (point))         ; end of entry below heading
    (goto-char beg)
    (while (eq (get-text-property (point) 'face) 'org-hide)
      (forward-char))
    (if (not (member (get-text-property (point) 'face)
		     '(org-level-1 org-level-2)))
        (1- end)   ; skip, and continue search after END
      nil     ; Don't skip, use this entry.
      )))

;; (defun org-merge-clocks nil
;;   "Sum clocking information for the current subtree and store it
;; as a :Clock: property."
;;   (interactive)
;;   (org-clock-sum)
;;   (save-excursion
;;     (org-back-to-heading)
;;     (while (re-search-forward 
;; 	    (concat "^[ \t]*" org-clock-string ".*$")
;; 	    (save-excursion (outline-next-heading) (point)) t)
;;       (replace-match ""))
;;     (org-back-to-heading)
;;     (let ((minutes (get-text-property (point) :org-clock-minutes))
;; 	  (elapsed (string-to-number (org-entry-get (point) "Clock"))))
;;       (org-entry-put (point) "Clock" 
;; 		     (number-to-string (+ minutes elapsed))))))

;; johnw
(defvar org-my-archive-expiry-days 7
  "The number of days after which a completed task should be auto-archived.
This can be 0 for immediate, or a floating point value.")

(defun org-my-archive-done-tasks ()
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (let ((done-regexp
           (concat "\\* \\(" (regexp-opt org-done-keywords) "\\) "))
          (state-regexp
           (concat "- State \"\\(" (regexp-opt org-done-keywords)
                   "\\)\"\\s-*\\[\\([^]\n]+\\)\\]")))
      (while (re-search-forward done-regexp nil t)
        (let ((end (save-excursion
                     (outline-next-heading)
                     (point)))
              begin)
          (goto-char (line-beginning-position))
          (setq begin (point))
          (if (re-search-forward state-regexp end t)
              (let* ((time-string (match-string 2))
                     (when-closed (org-parse-time-string time-string)))
                (if (>= (time-to-number-of-days
                         (time-subtract (current-time)
                                        (apply #'encode-time when-closed)))
                        org-my-archive-expiry-days)
                    (org-archive-subtree)))
            (goto-char end)))))
    (save-buffer)))

;; (setq safe-local-variable-values
;;       (quote ((after-save-hook archive-done-tasks))))

(defalias 'archive-done-tasks 'org-my-archive-done-tasks)

;; (defun org-clock-out-maybe (&optional silently)
;;   "If there a clock is running, ask for clocking it out.
;; Maybe do it SILENTLY."
;;   (interactive)
;;   (if (not (equal org-clock-heading ""))
;;       (if (and (not silently)
;; 	       (y-or-n-p 
;; 		(format "A clock is running for %s - clock it out? "
;; 			org-clock-heading)))
;; 	  (org-clock-out)
;; 	(org-clock-out))))

(defun org-check-running-clock-any-buffer ()
  "Check if any Org buffer contains a running clock.
If yes, offer to stop it and to save the buffer with the changes."
  (interactive)
  (let ((buf (marker-buffer org-clock-marker))
	(wcf (current-window-configuration)))
    (when 
	(and buf
	     (y-or-n-p 
	      (format "Clock-out in buffer %s before killing it? " buf)))
      (switch-to-buffer buf)
      (org-clock-out)
      (when (y-or-n-p "Save changed buffer? ")
	(save-buffer))
      (set-window-configuration wcf))))

(defadvice save-buffers-kill-emacs
  (before org-check-running-clock activate)
  "Check for a running clock before quitting."
  (org-check-running-clock-any-buffer))

;; (defadvice org-insert-property-drawer (after add-time-property)
;;   "Add a :Time: property after inserting a property drawer."
;;   (let ((pos (point)))
;;     (org-entry-put (point) "Time" "10m")
;;     (goto-char pos)))

;; (ad-activate 'org-insert-property-drawer)

;; (defadvice org-insert-heading (after add-custom-time-property)
;;   "Add a custom :Time: property after heading insertion."
;;   (let ((pos (point)))
;;     (org-insert-property-drawer)
;;     (org-entry-put (point) "time" "10m")
;;     (goto-char pos)))

;; (ad-activate 'org-insert-heading)


;;;;##########################################################################
;;;;  User Options, Variables
;;;;##########################################################################





;;; bzg-org.el ends here
