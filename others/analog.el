;;; analog.el --- monitor lists of files or command output

;;; Copyright (C) 2000, 2001, 2002, 2003, 2004 Matthew P. Hodges

;; Author: Matthew P. Hodges <MPHodges@member.fsf.org>
;; Version: $Id: analog.el,v 1.42 2004/01/29 15:50:05 matt Exp $

;; analog.el is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published
;; by the Free Software Foundation; either version 2, or (at your
;; option) any later version.

;; analog.el is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;; General Public License for more details.

;;; Commentary:
;;
;; Package to keep track of a list of specified files or the output of
;; specified commands. The principal variable to modify is
;; analog-entry-list, which should be set to a list of entries.
;;
;; Each element of analog-entry-list is a list where the car is a file
;; (or command) and the cdr is an association list of properties.
;;
;; By default, entries are files, but commands can also be specified.
;; Each entry can have a list of attributes describing whether the
;; head or the tail of the output is wanted, how many lines should be
;; kept, a list of regexps to keep or flush etc. Entries can be
;; collected into named groups.

;; Here is an example:
;;
;; (setq analog-entry-list
;;       '(
;;         ;; files in the WWW group
;;         ("/var/log/apache/referer.log"
;;          (group . "WWW")
;;          (lines . 10))                  ; show 10 lines
;;         ("/var/log/apache/combined.log"
;;          (group . "WWW")
;;          (lines . 10))
;;         ;; files in the Mail group
;;         ("/var/log/exim/mainlog"
;;          (group . "Mail")
;;          (hide . ("queue" "completed"))) ; hide lines matching queue/completed
;;         ;; commands in the Commands group
;;         ("df -h"
;;          (group . "Commands")
;;          (type . command)               ; commands must be identified
;;          (lines . all))                 ; keep all lines
;;         ("last"
;;          (group . "Commands")
;;          (type . command)
;;          (position . head)              ; monitor the head of the output
;;          (lines . 6))
;;         ("ps aux"
;;          (group . "Commands")
;;          (type . command)
;;          (keep . "matt")                ; keep lines matching matt
;;          (hide . ("bash" "ssh" "rxvt")) ; hide/keep can be lists
;;          (lines . all))
;;         ;; files in the System group
;;         ("/var/log/syslog"
;;          (group . "System")
;;          (hide . ("CRON" "MARK")))
;;         ))

;;; Code:

(require 'dired)
(require 'pp)

(defvar analog-entry-list nil
  "*This is a list of analog entries and their associated properties.
If properties are undeclared, defaults will be used.")

;; Customizable variables

(defgroup analog nil
  "Monitor lists of files or command output"
  :group 'tools
  :link '(url-link "http://www.tc.bham.ac.uk/~matt/AnalogEl.html"))

(defcustom analog-default-no-lines 4
  "*The default number of lines to display."
  :group 'analog
  :type 'integer)

(defcustom analog-default-position 'tail
  "*The default position of the file to display.
This can be 'head or 'tail."
  :group 'analog
  :type '(choice (const head)
                 (const tail)))

(defcustom analog-use-timer nil
  "*If t, the *analog* buffer will periodically be updated.
The frequency of updates is controlled by `analog-timer-period'."
  :group 'analog
  :type 'boolean)

(defcustom analog-timer-period 60
  "*The number of seconds between updates of the *analog* buffer.
Only relevant if timers are being used; see `analog-timer'."
  :group 'analog
  :type 'integer)

(defcustom analog-emit-update-messages nil
  "*If t, analog will print a message to the echo area after each update."
  :group 'analog
  :type 'boolean)

(defcustom analog-entry-string "#   Entry: "
  "String indicating entry name in *analog* buffer."
  :group 'analog
  :type 'string)

(defcustom analog-group-string "# Group: "
  "String indicating group name in *analog* buffer."
  :group 'analog
  :type 'string)

(defcustom analog-entries-file "~/.analog.el"
  "File containing saved analog entries."
  :group 'analog
  :type 'file)

;; Faces

(defface analog-group-header-face
  '((((class color) (background light))(:foreground "green4"))
    (((class color) (background dark)) (:foreground "green")))
  "Face used for group headings."
  :group 'analog)

(defface analog-entry-header-face
  '((((class color) (background light)) (:foreground "blue" :family "helv"))
    (((class color) (background dark)) (:foreground "yellow" :family "helv")))
  "Face used for entry headings."
  :group 'analog)

(defface analog-entry-face
  '((((class color) (background light)) (:foreground "black"))
    (((class color) (background dark)) (:foreground "white")))
  "Face used for entries."
  :group 'analog)

(defface analog-error-face
  '((((class color) (background light)) (:foreground "red"))
    (((class color) (background dark)) (:foreground "red")))
  "Face used for error messages."
  :group 'analog)

(defface analog-highlight-face
  '((((class color) (background light)) (:background "yellow" :foreground "blue"))
    (((class color) (background dark)) (:background "yellow" :foreground "blue")))
  "Face used for highlighted lines."
  :group 'analog)

;; Internal variables

(defvar analog-timer nil
  "Timer object controlling updates of the *analog* buffer.
Updates occur if `analog-use-timer' is t. The frequency of updates is
controlled by `analog-timer-period'.")

(defvar analog-default-type 'file
  "*The default type of entry.
Unless otherwise specified, an entry is taken to be a file.")

(defvar analog-entries nil
  "A list of entries inferred from `analog-entry-list'.")

(defvar analog-group-list nil
  "A list of filesets inferred from `analog-entry-list'.
If any entries are not associated with a named group, this list will
contain nil.")

(defvar analog-current-group nil
  "The group of entries currently active.")

(defvar analog-entries-in-current-group nil
  "A list of entries associated with the current group.")

;; XEmacs support

(defconst analog-xemacs-p
  (or (featurep 'xemacs)
      (string-match "XEmacs\\|Lucid" (emacs-version)))
  "True if we are using analog under XEmacs.")

(if analog-xemacs-p
    (progn
      (defalias 'analog-line-beginning-position 'point-at-bol)
      (defalias 'analog-line-end-position 'point-at-eol))
  (defalias 'analog-line-beginning-position 'line-beginning-position)
  (defalias 'analog-line-end-position 'line-end-position))

;; Entry point

;;;###autoload
(defun analog ()
  "Start analog mode.
Also update and select the *analog* buffer."
  (interactive)
  (if (not (buffer-live-p (get-buffer "*analog*")))
      ;; Initialize internal variables
      (analog-init))
  (analog-refresh-display-buffer)
  (show-buffer (selected-window) "*analog*"))

;; Internal functions

(defun analog-get-entry-property (entry property)
  "Return for entry ENTRY the associated property PROPERTY."
  (cdr (assoc property
              (cdr (assoc entry analog-entry-list)))))

(defun analog-get-entry-lines (entry)
  "Get the number of lines associated with ENTRY."
  (or (analog-get-entry-property entry 'lines)
      analog-default-no-lines))

(defun analog-get-entry-type (entry)
  "Get the type of ENTRY.
Currently this can be 'file or command."
  (or (analog-get-entry-property entry 'type)
      analog-default-type))

(defun analog-get-entry-hide (entry)
  "Get the regexps to be hidden for ENTRY."
  (analog-get-entry-property entry 'hide))

(defun analog-get-entry-keep (entry)
  "Get the regexps to be kept for ENTRY."
  (analog-get-entry-property entry 'keep))

(defun analog-get-entry-position (entry)
  "Get the position for ENTRY.
This can be head/tail for the beginning/end of the file"
  (or (analog-get-entry-property entry 'position)
      analog-default-position))

(defun analog-get-entry-highlights (entry)
  "Get the regexps to be highlighted for ENTRY."
  (analog-get-entry-property entry 'highlight))

(defun analog-init ()
  "Function used to set internal variables.
If `analog-entry-list' is nil, try to read entries from
`analog-entries-file'."
  (when (null analog-entry-list)
    (analog-load-entries))
  (let ((saved-group analog-current-group))
    ;; build list of entries
    (setq analog-entries (mapcar #'car analog-entry-list))
    ;; build the list of groups
    (analog-update-group-list)
    ;; set the current group
    (if (member saved-group analog-group-list)
        (setq analog-current-group saved-group)
      (setq analog-current-group (car analog-group-list)))
    ;; get the files in the current group
    (analog-update-entries-in-current-group)
    ;; kill existing timer; the timer frequency may have changed or
    ;; the timer may have switched on by hand
    (if analog-timer (progn (cancel-timer analog-timer)
                            (setq analog-timer nil)))
    ;; start new timer according to the default behaviour
    (if analog-use-timer
        (analog-toggle-timer))))

(defun analog-update-group-list ()
  "Update the list of groups in `analog-group-list'."
  (setq analog-group-list nil)
  (let ((entries analog-entries)
        group)
    (while entries
      (setq group (analog-get-entry-property (car entries) 'group))
      ;; Don't allow entries not associated with a group
      (when (null group)
        (error "No group associated with entry: %s" (car entries)))
      (add-to-list 'analog-group-list group)
      (setq entries (cdr entries))))
  ;; Elements added first end up at the end of the list; reverse
  (setq analog-group-list (reverse analog-group-list)))

(defun analog-update-entries-in-current-group ()
  "Update the entries in the current group.
The current group is stored in `analog-current-group'."
  (setq analog-entries-in-current-group nil)
  (let ((entries analog-entries))
    (while entries
      (if (equal
           (analog-get-entry-property (car entries) 'group)
           analog-current-group)
          (add-to-list 'analog-entries-in-current-group (car entries)))
      (setq entries (cdr entries))))
  ;; Elements added first end up at the end of the list; reverse
  (setq analog-entries-in-current-group
        (reverse analog-entries-in-current-group)))

(defun analog-entries-in-group (group)
  "Update the entries in the supplied GROUP."
  (let ((analog-entries-in-group nil)
        (entries analog-entries))
    (while entries
      (if (equal
           (analog-get-entry-property (car entries) 'group)
           group)
          (add-to-list 'analog-entries-in-group
                       (car entries))) ;;(analog-get-entry-name (car entries))))
      (setq entries (cdr entries)))
    ;; Elements added first end up at the end of the list; reverse
    (setq analog-entries-in-group
          (reverse analog-entries-in-group))))

;; Commands associated with keybindings (and related functions)

(defun analog-refresh ()
  "Rebuild the internal variables/refresh the display."
  (interactive)
  (analog-init)
  (analog-refresh-display-buffer))

(defun analog-refresh-display-buffer ()
  "Refresh the displayed information."
  (interactive)
  ;; Set up the buffer and window if necessary
  (if (not (get-buffer "*analog*"))
      (progn
        (set-buffer (get-buffer-create "*analog*"))
        ;; set buffer local variables after setting the major mode
        (analog-mode)
        (setq truncate-lines t)
        (setq buffer-read-only t))
    (set-buffer "*analog*"))
  ;; Update the displayed information
  (let ((inhibit-read-only t)
        (standard-output (current-buffer))
        saved-entry)
    ;; If we're on an entry line, preserve it
    (setq saved-entry (or (analog-entry-on-line t) ; ignore error
                          (analog-previous-entry t))) ; quieten
    (erase-buffer)
    ;; Enter group header
    (let (header)
      (setq header (format "%s%s; last updated at %s" analog-group-string
                    (or analog-current-group "none")
                    (current-time-string)))
      (cond
       ((boundp 'header-line-format)
        (setq header-line-format header)
        (put-text-property 0 (length header-line-format)
                           'face 'analog-group-header-face
                           header-line-format))
       (t
        (insert header)
        (put-text-property (analog-line-beginning-position) (analog-line-end-position)
                           'face 'analog-group-header-face)
        (terpri))))
    ;; Go through list of entries
    (let ((entries analog-entries-in-current-group)
          entry)
      (while entries
        (setq entry (car entries))
        ;; Insert entry header
        (let ((type (analog-get-entry-type entry))
              file-name-start file-name-end)
          (insert (concat analog-entry-string "\""))
          (setq file-name-start (point))
          (insert (format "%s" (analog-get-entry-name entry)))
          (setq file-name-end (point))
          (insert "\"")
          ;; Add text properties
          (put-text-property file-name-start (1+ file-name-start)
                             'analog-entry-start entry)
          (add-text-properties (analog-line-beginning-position)
                               (analog-line-end-position)
                             `(face analog-entry-header-face
                               analog-entry-type ,type))
          ;; Make clickable the associated file/command
          (put-text-property file-name-start file-name-end
                               `mouse-face 'highlight))
        (terpri)
        ;; Insert the file or output of command
        (let ((entry-start (point)))
          (analog-insert-entry entry))
        (setq entries (cdr entries))))
    ;; Move to the saved entry, if there is one
    (if (member saved-entry analog-entries-in-current-group)
        (analog-find-entry saved-entry)
      (analog-find-entry (car analog-entries-in-current-group)))
    (set-buffer-modified-p nil))
  ;; Send a message to the echo area if analog-emit-update-messages is
  ;; t and the buffer is not in the current window
  (if (and analog-emit-update-messages
           (not (eq (window-buffer) (get-buffer "*analog*"))))
      (message (format "*analog* last updated at %s"
                       (format-time-string "%H:%M:%S")))))

(defun analog-get-entry-name (entry)
  "Get the name for ENTRY.
This is usually a string, but eval the expression otherwise, and if
that is not a string, signal an error."
  (cond
   ((stringp entry)
    entry)
   ;; Assume it's a form and evaluate it
   (t
    (let ((result (eval entry)))
      (unless (stringp result)
        (error "Don't know how to deal with analog entry: %s"
               (prin1 entry)))
      result))))

(defun analog-insert-entry (entry)
  "Insert the output from ENTRY into the current buffer."
  (let ((entry-name (analog-get-entry-name entry))
        (type (analog-get-entry-type entry))
        (entry-string)
        problem)
    ;; We can run into problems if default-directory doesn't exist
    (cd (expand-file-name "~/"))
    (with-temp-buffer
      ;; Deal with entry depending on type, inserting into the
      ;; temporary buffer
      (cond
       ((and (eq type 'file) (file-readable-p entry-name)) ; insert file
        (insert-file-contents entry-name))
       ((eq type 'file)
        (setq problem t)                ; Don't do any post-processing
        (setq entry-string "File does not exist")
	(put-text-property 0 (length entry-string)
			   'face 'analog-error-face entry-string))
       ((and (eq type 'directory) (file-readable-p entry-name))
        ;; Insert directory
        (insert-directory entry-name dired-listing-switches))
       ((eq type 'directory)
        (setq problem t)                ; Don't do any post-processing
        (setq entry-string "Directory does not exist")
	(put-text-property 0 (length entry-string)
			   'face 'analog-error-face entry-string))
       ((eq type 'command)              ; insert process output
        (let (command args)
          (setq command (car (split-string entry-name)))
          (setq args (cdr (split-string entry-name)))
          (apply 'call-process command nil t nil args)))
       (t
        (error "Unknown entry type: %s" (symbol-name type))))
      (when (not problem)
        ;; Flush any regexps not wanted
        (goto-char (point-min))
        (let ((regexps (analog-get-entry-hide entry)))
          (cond
           ((null regexps))             ; do nothing)
           ((stringp regexps)
            (flush-lines regexps))
           ((listp regexps)
            (let ((list regexps))
              (while list
                (if (stringp (car list))
                    (flush-lines (car list)))
                (setq list (cdr list)))))
           (t
            (error "Unrecognized hide property for %s" entry))))
        ;; Keep any specified regexps
        (goto-char (point-min))
        (let ((regexps (analog-get-entry-keep entry)))
          (cond
           ((null regexps))             ; do nothing)
           ((stringp regexps)
            (keep-lines regexps))
           ((listp regexps)
            (let ((list regexps))
              (while list
                (if (stringp (car list))
                    (keep-lines (car list)))
                (setq list (cdr list)))))
           (t
            (error "Unrecognized keep property for %s" entry))))
        ;; Limit the output according to how many lines are required;
        ;; take into account whether we want the head or tail of the
        ;; file
        (let ((line-prop (analog-get-entry-lines entry))
              (position (analog-get-entry-position entry))
              extreme)
          ;; Move to beginning or end of input
          (cond
           ((equal position 'head)
            (goto-char (point-min)))
           ((equal position 'tail)
            (goto-char (point-max)))
           (t
            (error "Unrecognized position property for %s" entry)))
          (setq extreme (point))
          ;; keep the required number of lines
          (cond
           ((integerp line-prop)
            (cond
             ((equal position 'head)
              (forward-line line-prop))
             ((equal position 'tail)
              (forward-line (- line-prop)))))
           ((eq line-prop 'all)
            (cond
             ((equal position 'head)
              (goto-char (point-max)))
             ((equal position 'tail)
              (goto-char (point-min)))))
           (t
            (error "Unknown line type: %s" (symbol-name line-prop))))
          ;; Narrow to region we're interested in
          (narrow-to-region (point) extreme)
          ;; Add default face
          (put-text-property (point-min) (point-max) 'face 'analog-entry-face)
          ;; Highlighted regexps
          (analog-highlight-regexps (analog-get-entry-highlights entry))
          ;; Make entry-string
          (setq entry-string
                (buffer-substring (point-min) (point-max))))))
    (insert entry-string)
    ;; Insert newline if needed
    (unless (bolp)
      (terpri))))

(defun analog-highlight-regexps (regexps)
  "Highlight occurances of REGEXPS in current buffer.
REGEXPS can be a string or a list of strings, each of which is a
regular expression."
  (let ((list (cond ((stringp regexps)
                     (list regexps))
                    ((listp regexps)
                     regexps)
                    (t
                     nil))))
    (while list
      (when (stringp (car list))
        (goto-char (point-min))
        (while (re-search-forward (car list)
                                  (point-max) t)
          (put-text-property (analog-line-beginning-position)
                             (analog-line-end-position)
                             'face
                             'analog-highlight-face)))
      (setq list (cdr list)))))


(defun analog-next-group ()
  "Choose the next group of entries.
A list of groups is kept internally in `analog-group-list'. The
current group is kept internally in `analog-current-group'."
  (interactive)
  (let* ((length (length analog-group-list))
         (position (- length
                      (length (member analog-current-group
                                      analog-group-list)))))
    (setq analog-current-group
          (nth
           (if (eq position (1- length))
               0
             (1+ position))
           analog-group-list)))
  (analog-update-entries-in-current-group)
  (analog-refresh-display-buffer))

(defun analog-previous-group ()
  "Choose the previous group of entries.
A list of groups is kept internally in `analog-group-list'. The
current group is kept internally in `analog-current-group'."
  (interactive)
  (let* ((length (length analog-group-list))
         (position (- length
                      (length (member analog-current-group
                                      analog-group-list)))))
    (setq analog-current-group
          (nth
           (if (eq position 0)
               (1- (length analog-group-list))
             (1- position))
           analog-group-list)))
  (analog-update-entries-in-current-group)
  (analog-refresh-display-buffer))

(defun analog-find-entry (name)
  "Find the entry named NAME."
  (setq name name) ;; (analog-get-entry-name name))
  (if name
      (let (result)
        (goto-char (point-min))
        (while (not result)
          (cond
           ((null (analog-next-entry))
            (setq result 'not-found))
           ((if (equal name (get-text-property (point) 'analog-entry-start))
                (setq result 'found)))))
        (cond
         ((eq result 'not-found)
          (error "Entry %s not found" name))))))

(defun analog-goto-entry ()
  "Goto entry chosen from a list."
  (interactive)
  (let ((choice (completing-read "Choose entry: "
                                 (mapcar (lambda (elt)
                                           (cons elt elt))
                                         analog-entries-in-current-group)
                                 nil    ; no predicate
                                 t)))   ; require match
    (analog-find-entry choice)))

(defun analog-next-entry (&optional quiet)
  "Move point to the next group entry.
No messages if argument QUIET is given."
  (interactive)
  ;; Check if we are already on an entry
  (let (on-entry result)
    (when (get-text-property (point) 'analog-entry-start)
      (goto-char (1+ (point)))
      (setq on-entry t))
    ;; Move to next entry
    (setq result (next-single-property-change (point) 'analog-entry-start))
    (if result
        (goto-char result)
      (if on-entry
          (goto-char (1- (point))))
      (when (not quiet) (message "No more entries")))
    (setq result (get-text-property (point) 'analog-entry-start))))

(defun analog-previous-entry (&optional quiet)
  "Move point to the previous group entry.
No messages if argument QUIET is given."
  (interactive)
  (cond
   ((bobp)
    (when (not quiet) (message "No more entries")))
   ;; We're one char after the start of the entry
   ((get-text-property (1- (point)) 'analog-entry-start)
    (goto-char (1- (point))))
   (t
    ;; Check if we are already on an entry
    (let (on-entry result)
      (when (get-text-property (point) 'analog-entry-start)
        (goto-char (1- (point)))
        (setq on-entry t))
      ;; Move to next entry
      (setq result (previous-single-property-change (point) 'analog-entry-start))
      (if result
          (goto-char (1- result))
        (if on-entry
            (goto-char (1+ (point))))
        (when (not quiet) (message "No more entries")))
      (setq result (get-text-property (point) 'analog-entry-start))))))

(defun analog-bury-buffer ()
  "Bury the *analog* buffer."
  (interactive)
  (if (eq (window-buffer) (get-buffer "*analog*"))
      (quit-window)))

(defun analog-quit ()
  "Quit analog.
Kill the *analog* buffer and destroy the timer if present."
  (interactive)
  ;; Cancel the timer
  (if analog-timer
      (analog-toggle-timer))
  (if (buffer-live-p (get-buffer "*analog*"))
      (kill-buffer "*analog*")))

(defun analog-toggle-timer ()
  "Toggle analog timer."
  (interactive)
  (if analog-timer
      (progn (cancel-timer analog-timer)
             (setq analog-timer nil)
             (message "Analog timer cancelled"))
    (setq analog-timer (run-with-timer analog-timer-period
                                       analog-timer-period
                                       'analog-timer-refresh-display-buffer))
    (message "Analog timer started")))

(defun analog-timer-refresh-display-buffer ()
  "Called by the timer to refresh the *analog* buffer.
This function will cancel any existing timer if the *analog* buffer is
dead."
  ;; We must make sure that the selected buffer is restored, otherwise
  ;; it will be left as *analog* with confusing side-effects
  (let ((buffer (current-buffer)))
    (if (buffer-live-p (get-buffer "*analog*"))
        (analog-refresh-display-buffer)
      ;; Timer must be non-nil; cancel it
      (analog-toggle-timer))
    (set-buffer buffer)))

(defun analog-kill-other-window-buffers ()
  "Kill buffers in other windows.
Also make sure beginning of *analog* buffer is subsequently shown."
  (interactive)
  (let ((analog-buffer (get-buffer "*analog*"))
        buffer-list
        buffer)
    (when (eq (current-buffer) analog-buffer)
      (setq buffer-list
            (delq analog-buffer
                  (mapcar #'window-buffer (window-list))))
      (while buffer-list
        (setq buffer (car buffer-list))
        (if (buffer-live-p buffer)
            (kill-buffer buffer))
        (setq buffer-list (cdr buffer-list)))
      (delete-other-windows)
      (set-window-start (selected-window) (point-min)))))

(defun analog-entry-on-line (&optional ignore-error)
  "Find the entry on the current line.
Ignore errors if IGNORE-ERROR argument given."
  (let (entry result)
    (setq result (next-single-property-change (analog-line-beginning-position)
                                              'analog-entry-start
                                              nil
                                              (analog-line-end-position)))
    (if (and result (not (eq result (analog-line-end-position))))
        (setq entry (get-text-property result 'analog-entry-start))
      (if (not ignore-error)
          (error "Cannot find analog entry on current line"))
      entry)))

(defun analog-show-entry ()
  "Show entry at point."
  (interactive)
  (let ((entry (analog-entry-on-line t))
        (type (get-text-property (analog-line-beginning-position)
                                 'analog-entry-type)))
    (save-selected-window
      (cond
       ((null type)
        (message "Not on analog entry"))
       ((eq type 'file)
        (view-file-other-window entry)
        (if (equal (analog-get-entry-position entry) 'tail)
            (goto-char (point-max))))
       ((eq type 'directory)
        (dired-other-window entry)
        (if (equal (analog-get-entry-position entry) 'tail)
            (goto-char (point-max))))
       ((eq type 'command)
        (let ((resize-mini-windows nil))
          (shell-command entry)
          (when (equal (analog-get-entry-position entry) 'tail)
            (walk-windows
             (lambda (w)
               (when (equal (buffer-name (window-buffer w))
                            "*Shell Command Output*")
                 (select-window w)
                 (goto-char (point-max))))))))))))

(defun analog-mouse-show-entry (event)
  "Find the entry associated with the entry at mouse.
Argument EVENT is a mouse event."
  (interactive "e")
  (let ((mouse-buffer (buffer-name))
        entry type)
    (save-selected-window
      (set-buffer "*analog*")
      (goto-char
       (cond
        ((and (fboundp 'posn-point)
              (posn-point (event-start event))))
        ((and (fboundp 'event-point)
              (event-point event)))
        (t
         (error "Cannot determine event position"))))
      (setq entry (analog-entry-on-line t))
      (setq type (get-text-property (analog-line-beginning-position)
                                    'analog-entry-type))
      (cond
       ((null type)
        (message "Not on analog entry"))
       ((eq type 'file)
        (if (equal mouse-buffer "*analog*")
            (view-file-other-window entry)
          (view-file entry))
        (if (equal (analog-get-entry-position entry) 'tail)
            (goto-char (point-max))))
       ((eq type 'directory)
        (if (equal mouse-buffer "*analog*")
            (dired-other-window entry)
          (dired entry))        
        (if (equal (analog-get-entry-position entry) 'tail)
            (goto-char (point-max))))
       ;; FIXME: preservation of windows isn't quite right here
       ((eq type 'command)
        (let ((resize-mini-windows nil))
          (save-window-excursion
            (shell-command entry))
          (set-window-buffer (selected-window) "*Shell Command Output*")
          (when (equal (analog-get-entry-position entry) 'tail)
            (goto-char (point-max)))))))))

;; Commands to interactively modify analog-entry-list

(defun analog-add-entry-to-list ()
  "Add an entry to `analog-entry-list'."
  (interactive)
  (let ((completion-ignore-case t)
        entry group lines name position type)
    ;; Get new entry (take name of current file buffer is associated
    ;; with one)
    (setq name (read-from-minibuffer
                "New entry: "
                (cond
                 (buffer-file-name
                  buffer-file-name)
                 (dired-directory
                  dired-directory)
                 (t
                  ""))))
    ;; Offer list of groups
    (setq group (completing-read
                 "Choose group: "
                 (mapcar (lambda (elt)
                           (cons elt elt))
                         analog-group-list) nil nil))
    ;; Properties
    (cond
     ((file-directory-p name)
      (setq type 'directory))
     ((file-exists-p name)              ; exists, but not directory
      (setq type 'file))
     (t
      (setq type 'command)))

    (setq position (completing-read
                    "Choose position: "
                    (mapcar (lambda (elt)
                              (cons elt elt))
                            '("head" "tail")) nil t "tail"))

    (if (> (length position) 0)
        (setq position (intern position))
      (setq position nil))

    (setq lines (read-from-minibuffer
                 "Number of lines: "
                 (int-to-string analog-default-no-lines)))

    (if (string-equal lines "all")
        (setq lines (intern "all"))
      (progn
        (setq lines (string-to-number lines))
        (unless (and (integerp lines)
                   (> lines 0))
        (error
         "Invalid value for lines (must be a positive integer or \"all\")"))))

    (setq entry (list name
                      (cons 'group group)
                      (cons 'type type)
                      (cons 'lines lines)))

    (if position
        (add-to-list 'entry (cons 'position position) t))

    (add-to-list 'analog-entry-list entry t)
    ;; Rebuild internal variables (we don't want to do everything that
    ;; analog-init does)
    (setq analog-entries (mapcar #'car analog-entry-list))
    (analog-update-group-list)
    (if (equal group analog-current-group)
        (analog-update-entries-in-current-group)))
    (analog-refresh-display-buffer))

(defun analog-remove-entry-from-list ()
  "Remove an entry from `analog-entry-list'."
  (interactive)
  (let ((completion-ignore-case t)
        entry-completion-table entry group)
    ;; Offer list of groups
    (setq group (completing-read
                 "Choose group: "
                 (mapcar (lambda (elt)
                           (cons elt elt))
                         analog-group-list) nil t analog-current-group))
    ;; Offer list of entries for the chosen group
    (setq entry-completion-table
          (mapcar (lambda (elt)
                    (cons (analog-get-entry-name elt) elt))
                  (analog-entries-in-group group)))

    (setq entry (cdr (assoc
                      (completing-read "Choose entry: " entry-completion-table
                                       nil t)
                      entry-completion-table)))
    ;; Delete the selected entry
    (setq analog-entry-list (delete
                (assoc entry analog-entry-list)
                analog-entry-list))
    ;; Rebuild internal variables (we don't want to do everything that
    ;; analog-init does)
    (setq analog-entries (mapcar #'car analog-entry-list))
    (analog-update-group-list)
    (if (equal group analog-current-group)
        (unless (analog-update-entries-in-current-group)
          (setq analog-current-group (car analog-group-list))
          (analog-update-entries-in-current-group))))
  (analog-refresh-display-buffer))

(defun analog-insert-entry-details (entry)
  "Insert the details for ENTRY into current buffer."
  (let ((list (cdr (assoc entry analog-entry-list)))
        (standard-output (current-buffer))
        (string (concat (make-string (1- (window-width)) ?\=) "\n")))
    (insert string (format "%-10s \"%s\"\n" "Entry:" entry))
    (insert string)
    (mapcar
     (lambda (elt)
       (insert (format "%-10s %s%s"
                       (concat (capitalize (symbol-name (car elt))) ":")
                       (pp-to-string (cdr elt))
                       (if (listp (cdr elt)) "" "\n"))))
     list)
    (insert string)))

(defun analog-show-entry-details ()
  "Display info for analog entry at point."
  (interactive)
  (let ((entry (analog-entry-on-line t))
        (inhibit-read-only t))
    (cond
     ((null entry)
      (message "Not on analog entry"))
     (t
      (set-buffer (get-buffer-create "*analog entry*"))
      (setq buffer-read-only t)
      (erase-buffer)
      (analog-insert-entry-details entry)
      (set-buffer-modified-p nil)
      (goto-char (point-min))
      (display-buffer (get-buffer "*analog entry*"))
      (let ((window (display-buffer "*analog entry*")))
        (save-selected-window
          (select-window window)
          (shrink-window (- (window-height) 10))))))))

(defun analog-save-entries ()
  "Save entries to the file given by `analog-entries-file'."
  (interactive)
  ;; Basic checks
  (cond
   ((not (stringp analog-entries-file))
    (error "Variable not a string: analog-entries-file"))
   ((not (file-writable-p analog-entries-file))
    (error "Cannot write to %s" analog-entries-file)))
  ;; Write entries to file
  (if (file-exists-p analog-entries-file)
      (delete-file analog-entries-file))
  (with-temp-file analog-entries-file
    (insert (concat "(setq analog-entry-list '"
                    (pp-to-string analog-entry-list)
                    ")"))))

(defun analog-load-entries ()
  "Load entries from the file given by `analog-entries-file'."
  (interactive)
  (cond
   ((not (stringp analog-entries-file))
    (error "Variable not a string: analog-entries-file"))
   ((not (file-readable-p analog-entries-file))
    (error "Cannot read from %s" analog-entries-file)))
  ;; Read entries from file
  (with-temp-buffer
    (insert-file-contents analog-entries-file)
    (eval-buffer))
  (analog-refresh))

;; Define the major mode and keymap

(defvar analog-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "+") 'analog-add-entry-to-list)
    (define-key map (kbd "-") 'analog-remove-entry-from-list)
    (define-key map (kbd "1") 'delete-other-windows)
    (define-key map (kbd "<") 'analog-previous-group)
    (define-key map (kbd ">") 'analog-next-group)
    (define-key map (kbd "?") 'describe-mode)
    (define-key map (kbd "b") 'analog-bury-buffer)
    (define-key map (kbd "g") 'analog-goto-entry)
    (define-key map (kbd "i") 'analog-refresh)
    (when (fboundp 'window-list)
      (define-key map (kbd "k") 'analog-kill-other-window-buffers))
    (define-key map (kbd "n") 'analog-next-entry)
    (define-key map (kbd "o") 'other-window)
    (define-key map (kbd "p") 'analog-previous-entry)
    (define-key map (kbd "q") 'analog-quit)
    (define-key map (kbd "r") 'analog-refresh-display-buffer)
    (define-key map (kbd "t") 'analog-toggle-timer)
    (define-key map (kbd "RET") 'analog-show-entry)
    (define-key map
      (if analog-xemacs-p '(button2) (kbd "<mouse-2>"))
      'analog-mouse-show-entry)
    (define-key map (kbd "ESC RET") 'analog-show-entry-details)
    map)
  "Keymap for analog mode.")

;; Menus

(defvar analog-menu nil
  "Menu to use for `analog-mode'.")

(when (fboundp 'easy-menu-define)

  (easy-menu-define analog-menu analog-mode-map "Analog Menu"
    '("Analog"
      "---"
      ["Next Group"         analog-next-group t]
      ["Previous Group"     analog-previous-group t]
      ["Next Entry"         analog-next-entry t]
      ["Previous Entry"     analog-previous-entry t]
      ["Show Entry"         analog-show-entry t]
      ["Show Entry Details" analog-show-entry-details t]
      ["Goto Entry"         analog-goto-entry t]
      "---"
      ["Toggle Timer"       analog-toggle-timer t]
      ["Refresh"            analog-refresh t]
      "---"
      ["Bury Buffer"        analog-bury-buffer t]
      ["Quit"               analog-quit t])))

(defun analog-mode ()
  "Major mode for controlling the *analog* buffer.

\\{analog-mode-map}"
  (kill-all-local-variables)
  (use-local-map analog-mode-map)
  (setq major-mode 'analog-mode)
  (setq mode-name "Analog")
  (setq buffer-undo-list t)
  ;; XEmacs
  (when (and (fboundp 'easy-menu-add)
             analog-menu)
    (easy-menu-add analog-menu))
  (run-hooks 'analog-mode-hook))

(provide 'analog)

;;; analog.el ends here
