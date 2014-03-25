;; phonebook.el: a mode to keep a phone/address book
;; Copyright (C) 2000 Jay Belanger
;; Copyright (C) 1989 Paul Davis
;;
;; To run the phonebook, load this file, and enter M-x phonebook.
;; Instructions on how to use the phonebook are in the phonebook-mode
;; description.
;;
;; This is based on Paul Davis's rolo.el
;; From the original file:

  ;;;; rolo.el
  ;;;; An e-lisp version of Ron Hitchins rolo program
  ;;;; Paul Davis <davis%...@sdr.slb.com> Feb & Apr 1989
  ;;;;
  ;;;;-----------------------------------------------------------------
  ;;;; This file is subject to the same copyright conditions as
  ;;;; GNU Emacs.

;;
;;    This program is free software; you can redistribute it and/or modify
;;    it under the terms of the GNU General Public License as published by
;;    the Free Software Foundation; either version 2 of the License, or
;;    (at your option) any later version.
;;
;;    This program is distributed in the hope that it will be useful,
;;    but WITHOUT ANY WARRANTY; without even the implied warranty of
;;    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;    GNU General Public License for more details.
;;
;;    You should have received a copy of the GNU General Public License
;;    along with this program; if not, write to the Free Software
;;    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

(defvar phonebook-entry-delimiter ""
  "Regexp used to delimit entries in a Phonebook buffer")

(defvar phonebook-latex-prefixes '(
         ("email:" . ( "\\textbf{email:}\\texttt{" "}\\\\\n")))
  "List of lines to be specially formatted in the LaTeX buffer.")

(defvar phonebook-entry-delimiter-regexp phonebook-entry-delimiter
  ;;(concat "^" phonebook-entry-delimiter)
  "Regexp used to locate start and end of entries in a Phonebook buffer")

(defvar phonebook-entry-total nil
  "Total number of phonebook entries in current phonebook-mode buffer")

(defconst phonebook-default-directory "~/.phonebook/"
  "The default directory to keep the phonebooks in.")

(defconst phonebook-default-file (user-login-name)
  "The default file where the addresses are kept")

(defvar phonebook-buffer nil
  "The buffer with the phonebook.")

(make-variable-buffer-local 'phonebook-buffer)

(defvar phonebook-summary-buffer nil
  "The buffer with the phonebook summary.")

(make-variable-buffer-local 'phonebook-summary-buffer)

(defvar phonebook-summary-p nil
  "Flag to tell whether or not there is a summary.")

(make-variable-buffer-local 'phonebook-summary-p)

(defun phonebook ()
  "Visit the phonebook-file and display as a series of sequential entries.
Numerous functions are available for locating, searching and indexing
the entries, as well as creating new ones.

The phonebook-file format is compatible with the program `rolo', and
consists of each entry terminated by the character phonebook-entry-delimiter
(^L by default). Each entry MUST be terminated in this way, and extra
white space after the last occurence of phonebook-entry-delimiter may
confuse poor phonebook-mode. If you stick to using \\[phonebook-create-entry]
and \\[phonebook-delete-entry] to add and remove entries, you'll be fine.

\{phonebook-mode-map}"
  (interactive)
  (find-file (expand-file-name
               (read-file-name "Phonebook file: "
                      phonebook-default-directory
                      nil
                      nil
                      phonebook-default-file)))
  (phonebook-mode))

;; Phonebook mode itself

(defun phonebook-mode ()
  "A mode for keeping a phonebook.
Note that by default, searching in this mode is case-insensitive. If
you wish to alter this, add a phonebook-mode-hook to your .emacs file.

To create a new entry before the current entry, use \\[phonebook-create-entry].
Giving this command an argument will put the new after before the
current entry.
To delete the current entry, use \\[phonebook-delete-entry]
(Note that the phonebook delimiter will not be put into the
kill ring, to make it easy to cut and move entries around.)
To move to the next entry, use \\[phonebook-next-entry]
To move to the previous entry, use \\[phonebook-previous-entry]
To search through the entries, use \\[phonebook-search]
To do a reverse search through the entries, use \\[phonebook-backward-search]

Additionally, the command \\[phonebook-make-book] will create a buffer
which contains LaTeX commands for printing the contents of the phonebook,
two entries across.  The first line of each entry (assumed to be the name)
will be in bold face.
The list phonebook-latex-prefixes is a list with entries of the form
(begin-line . (begin-text end-text)).  If a line in an entry begins with
begin-line, then the corresponding line in the LaTeX buffer will consist
of begin-text, followed by the rest of the line in the entry, then end-text.

Finally, the command \\[phonebook-summary] will create a summary buffer,
containing the first lines of all the entries.
This buffer can be updated by using \\[phonebook-summary], and will
be automatically updated whenever the phonebook buffer is saved or
an entry is deleted.
In the summary buffer, the command RET will display the corresponding
entry in the phonebook buffer,  the command \"n\" will move to the next
line and display the corresponding entry in the phonebook buffer, and
the command \"p\" will move to the previous line and display the
corresponding entry in the phonebook buffer. The command \"b\" will
create the LaTeX buffer mentioned above, and the command \"q\" will
kill the summary buffer.
The command C-k will delete the phonebook entry corresponding to the
entry on the summary line, and the command C-y will create a new entry before
the entry on the summary line, and yank the latest entry on the kill ring
into it.  (With an argument, the new entry will be entered after the entry
on the summary line.)"
  (interactive)
  (kill-all-local-variables)
  (widen)
  (setq major-mode 'phonebook-mode)
  (setq mode-name "Phonebook")
  (use-local-map phonebook-mode-map)
  (set-syntax-table text-mode-syntax-table)
  (setq mode-line-format '("" mode-line-modified
                           mode-line-buffer-identification
                           "   " global-mode-string "   %[("
                           mode-name "%n" mode-line-process
                           ")%]" "-%-"))
  (setq case-fold-search t)
  (setq phonebook-entry-total (1- (phonebook-count-entries-to (point-max))))
  (if (> (buffer-size) 0)
      (phonebook-show-entry 1)
    (phonebook-forward-create-entry)
    (phonebook-update-mode-line))
  (run-hooks 'phonebook-mode-hook))

;; Keymaps

(defvar phonebook-mode-map nil
  "Keymap for phonebook-mode")

(if phonebook-mode-map ()
  (let ((map (make-sparse-keymap)))
    (define-key map "\C-c\C-c" 'phonebook-create-entry)
    (define-key map "\C-c\C-d" 'phonebook-delete-entry)
    (define-key map "\C-c\C-i" 'phonebook-summary)
    (define-key map "\C-c\C-u" 'phonebook-update-summary)
    (define-key map "\C-c\C-n" 'phonebook-next-entry)
    (define-key map "\C-c\C-p" 'phonebook-previous-entry)
    (define-key map "\C-c\C-b" 'phonebook-make-book)
    (define-key map "\C-c\C-s" 'phonebook-search)
    (define-key map "\C-c\C-r" 'phonebook-backward-search)
    (define-key map "\C-x\C-s" 'phonebook-save-buffer)
    (setq phonebook-mode-map map)))

;; Displaying the entries

(defun phonebook-show-entry (&optional n)
  "Display the current entry, (that which point is currently within),
or the Nth entry if N is non-null."
  (interactive "pn")
  (if (null n)
      (phonebook-intern-display-this-entry)
    (let ((here (point)))
      (widen)
      (goto-char (point-min))
      (if (null (re-search-forward phonebook-entry-delimiter-regexp
                                   (point-max) t n))
          (progn
            (goto-char here)
            (phonebook-show-entry)
            (ding)
            (message "no such entry")))
      (previous-line 1)
      (phonebook-intern-display-this-entry))))

(defun phonebook-intern-display-this-entry ()
  (narrow-to-region (phonebook-entry-beg)
                    (max 1 (1- (phonebook-entry-end))))
  (goto-char (point-min))
  (phonebook-update-mode-line))

(defun phonebook-update-mode-line ()
  "Make sure mode-line in the current buffer reflects all changes."
  (setq mode-line-process
        (concat " "
              (phonebook-count-entries-to (point)) "/" phonebook-entry-total))
  (set-buffer-modified-p (buffer-modified-p))
  (sit-for 0))

(defun phonebook-count-entries-to (position)
  "Count the number of entries up to (and including) the current entry."
  (let ((n 1))
    (save-restriction
      (widen)
      (goto-char (point-min))
      (while (re-search-forward phonebook-entry-delimiter-regexp position t)
        (setq n (1+ n))
        (forward-line 1)))
    (max 1 n)))

;; motion control

(defun phonebook-next-entry (&optional n)
  "Show the next entry, or the Nth-next entry if N is non-null."
  (interactive "pn")
  (phonebook-forward-entry n)
  (phonebook-show-entry))

(defun phonebook-previous-entry (&optional n)
  "Show the previous entry, or the Nth-previous entry if N is non-null."
  (interactive "pn")
  (phonebook-backward-entry n)
  (phonebook-show-entry))

(defun phonebook-forward-entry (&optional n)
  "Move to next phonebook entry, or N entries forward if N is non-null."
  (let ((here (point)))
    (widen)
    (if (or (null (re-search-forward phonebook-entry-delimiter-regexp
                                     (point-max) t n))
            (eobp))
        (progn
          (ding)
          (message "no such entry")
          (goto-char here))
      (forward-line 1))))

(defun phonebook-backward-entry (&optional n)
  "Move to previous phonebook entry, or Nth previous if N is non-null."
  (let ((here (point)))
    (widen)
  (if (null (re-search-backward phonebook-entry-delimiter-regexp
                                (point-min) t n))
      (progn
        (ding)
        (message "no such entry")
        (goto-char here))
    (previous-line 1))))

;; Searching

(defvar phonebook-search-regexp nil
  "Last regexp used by phonebook-search")

(make-variable-buffer-local 'phonebook-search-regexp)

(defun phonebook-search (regexp)
  "Search for a regular expression throughout the entries."
  (interactive
   (list (read-string (concat "Phonebook Search for"
                                  (if phonebook-search-regexp
                                   (concat " ("
                                           phonebook-search-regexp
                                           ")"))
                                  ":"))))
  (if (equal "" regexp)
      (setq regexp phonebook-search-regexp
            repeat t)
    (setq repeat nil))
  (let ((start (point-min))
        (end (point-max))
        (here (point)))
    (widen)
    (if repeat
        (forward-char 1))
    (if (null (re-search-forward regexp (point-max) t))
        (progn
          (narrow-to-region start end)
          (goto-char here)
          (message (concat "\"" regexp "\" not found.")))
      (save-excursion
        (phonebook-show-entry)))
    (setq phonebook-search-regexp regexp)))

(defun phonebook-backward-search (regexp)
  "Reverse search for a regular expression throughout the entries."
  (interactive
   (list (read-string (concat "Phonebook Backward Search for"
                                  (if phonebook-search-regexp
                                   (concat " ("
                                           phonebook-search-regexp
                                           ")"))
                                  ":"))))
  (if (equal "" regexp)
      (setq regexp phonebook-search-regexp
            repeat t)
    (setq repeat nil))
  (let ((start (point-min))
        (end (point-max))
        (here (point)))
    (widen)
    (if repeat
        (forward-char -1))
    (if (null (re-search-backward regexp (point-min) t))
        (progn
          (narrow-to-region start end)
          (goto-char here)
          (message (concat "\"" regexp "\" not found.")))
      (save-excursion
        (phonebook-show-entry)))
    (setq phonebook-search-regexp regexp)))

(defun phonebook-entry-beg ()
  "Return the beginning of the current entry as point."
  (save-excursion
    (if (null (re-search-backward
               phonebook-entry-delimiter-regexp (point-min) t))
        (point-min)
      (+ 2 (point)))))

(defun phonebook-entry-end ()
  "Return the end of the current entry as point."
  (save-excursion
    (if (null (re-search-forward
               phonebook-entry-delimiter-regexp (point-max) t))
        (point-max)
      (point))))

;; miscelleania

(defun phonebook-remake-summary ()
  "Update the summary buffer."
  (interactive)
  (let ((current-point (point))
        (start (point-min))
        (end (point-max)))
    (save-excursion
      (set-buffer phonebook-summary-buffer)
      (setq current-line (1+ (count-lines (point-min) (bol))))
      (setq buffer-read-only nil)
      (erase-buffer))
    (progn
      (widen)
      (goto-char (point-min))
      (if (not (eobp))
          (progn
            (append-to-buffer phonebook-summary-buffer (bol) (eol))
            (phonebook-insert-in-buffer "\n" phonebook-summary-buffer)))
      (while (re-search-forward phonebook-entry-delimiter-regexp
                                (point-max) t)
        (if (not (eobp))
            (progn
              (forward-line 1)
              (append-to-buffer phonebook-summary-buffer (bol) (eol))
              (phonebook-insert-in-buffer "\n" phonebook-summary-buffer)))))
    (save-excursion
      (set-buffer phonebook-summary-buffer)
      (goto-char (1- (point-max)))
      (delete-char 1)
      (setq buffer-read-only t)
      (forward-line 1))
    (narrow-to-region start end)
    (goto-char current-point)
    (switch-to-buffer-other-window phonebook-summary-buffer)))

(defun phonebook-make-summary ()
  "Create the summary buffer, and set the environment."
  (interactive)
  (setq phonebook-summary-p t)
  (setq phonebook-summary-buffer
        (get-buffer-create (generate-new-buffer-name
                            (concat "*Phonebook Summary for "
                                    (buffer-name) "*"))))
  (let  ((pbook-buffer (current-buffer))
        (entry-number (phonebook-count-entries-to (point))))
    (phonebook-remake-summary)
    (setq phonebook-buffer pbook-buffer)
    (goto-line entry-number)
    (local-set-key "n" 'phonebook-summary-next-entry)
    (local-set-key "p" 'phonebook-summary-previous-entry)
    (local-set-key "q" 'phonebook-kill-summary)
    (local-set-key "\C-xk" 'phonebook-kill-summary-buffer)
    (local-set-key "\C-k" 'phonebook-summary-kill-entry)
    (local-set-key "\C-y" 'phonebook-summary-insert-entry)
    (local-set-key "b" 'phonebook-summary-make-book)
    (local-set-key "\C-m" 'phonebook-summary-current-entry)))

(defun phonebook-summary ()
  "Create or update the phonebook summary."
  (interactive)
  (if phonebook-summary-p
      (phonebook-remake-summary-save-position)
    (phonebook-make-summary)))

(defun phonebook-remake-summary-save-position ()
  "Update the summary buffer, but save the line."
  (interactive)
  (let ((line-no))
      (set-buffer phonebook-summary-buffer)
      (setq line-no (1+ (count-lines (point-min) (bol))))
      (set-buffer phonebook-buffer)
      (phonebook-remake-summary)
      (goto-line line-no)))

(defun phonebook-update-summary ()
  "Update the summary buffer."
  (interactive)
  (phonebook-remake-summary-save-position)
  (pop-to-buffer phonebook-buffer))

(defun phonebook-summary-kill-entry ()
  "Kill (in the phonebook buffer) the entry showing in the summary buffer."
  (interactive)
  (let ((entry-no)
        (line-no (1+ (count-lines (point-min) (bol)))))
    (pop-to-buffer phonebook-buffer)
    (setq entry-no (phonebook-count-entries-to (point)))
    (phonebook-show-entry line-no)
    (phonebook-delete-entry)
    (if (> entry-no line-no)
        (setq entry-no (1- entry-no)))
    (phonebook-show-entry entry-no)
    (pop-to-buffer phonebook-summary-buffer)
    (goto-line line-no)
    (beginning-of-line)))

(defun phonebook-summary-insert-entry (&optional arg)
  "Insert the entry that was recently killed."
  (interactive)
  (phonebook-summary-current-entry)
  (pop-to-buffer phonebook-buffer)
  (if arg
      (phonebook-create-entry (universal-argument))
    (phonebook-create-entry))
  (yank (universal-argument))
  (phonebook-remake-summary-save-position))

(defun phonebook-summary-make-book ()
  "Create the LaTeX phonebook."
  (interactive)
  (save-excursion
    (set-buffer phonebook-buffer)
    (phonebook-make-book)))

(defun phonebook-kill-summary ()
  "Kill the summary buffer and window."
  (interactive)
  (save-excursion
    (set-buffer phonebook-buffer)
    (setq phonebook-summary-p nil))
  (kill-this-buffer)
  (delete-window))

(defun phonebook-kill-summary-buffer ()
  "Kill the summary buffer."
  (interactive)
  (save-excursion
    (set-buffer phonebook-buffer)
    (setq phonebook-summary-p nil))
  (kill-this-buffer))

(defun phonebook-summary-current-entry ()
  "Show the phonebook entry that is being referred to in the summary."
  (interactive)
  (let ((n (1+ (count-lines (point-min) (bol)))))
(save-excursion
    (pop-to-buffer phonebook-buffer)
    (phonebook-show-entry n)
    (pop-to-buffer phonebook-summary-buffer))))

(defun phonebook-summary-next-entry ()
  "Go to the next line in the summary buffer,
and show the corresponding phonebook entry."
  (interactive)
  (forward-line 1)
  (phonebook-summary-current-entry))

(defun phonebook-summary-previous-entry ()
  "Go to the previous line in the summary buffer,
and show the corresponding phonebook entry."
  (interactive)
  (forward-line -1)
  (phonebook-summary-current-entry))

(defun phonebook-create-entry (&optional arg)
  "Create a new phonebook entry."
  (interactive "P")
  (if arg
      (phonebook-forward-create-entry)
    (phonebook-backward-create-entry)))

(defun phonebook-forward-create-entry ()
  "Create a new phonebook entry after the current entry."
  (interactive)
  (widen)
  (re-search-forward phonebook-entry-delimiter (dot-max) 1)
  (if (= (point) 1)
      (insert "\n"  phonebook-entry-delimiter)
    (insert "\n" "\n" phonebook-entry-delimiter))
  (backward-char 2)
  (narrow-to-region (point) (point))
  (setq phonebook-entry-total (1+ phonebook-entry-total))
  (phonebook-update-mode-line))

(defun phonebook-backward-create-entry ()
  "Create a new phonebook entry before the current entry."
  (interactive)
  (widen)
  (re-search-backward phonebook-entry-delimiter (dot-min) 1)
  (if (= (point) 1)
      (insert phonebook-entry-delimiter "\n")
    (end-of-line)
    (insert "\n" "\n" phonebook-entry-delimiter))
  (backward-char 2)
  (narrow-to-region (point) (point))
  (setq phonebook-entry-total (1+ phonebook-entry-total))
  (phonebook-update-mode-line))

(defun phonebook-delete-entry ()
  "Delete the current phonebook entry."
  (interactive)
  (let ((current-entry (phonebook-count-entries-to (point))))
    (widen)
    (kill-region (phonebook-entry-beg) (1- (phonebook-entry-end)))
    (delete-char 1)
    (if (looking-at "\n")
        (delete-char 1))
    (setq phonebook-entry-total (1- phonebook-entry-total))
    (if (> current-entry phonebook-entry-total)
        (progn
          (forward-char -1)
          (kill-line)
          (setq kill-ring (cdr kill-ring))
          (beginning-of-line)))
    (phonebook-show-entry)
    (if phonebook-summary-p
        (phonebook-update-summary))))

(defun phonebook-save-buffer ()
  "Save a phonebook-mode buffer,
ensuring that there is an occurence of phonebook-delimiter-regexp at
the end before actually writing back to the file."
  (interactive)
  (save-excursion
    (save-restriction
      (widen)
      (goto-char (point-max))
      (backward-char 1)
      (if (not (looking-at phonebook-entry-delimiter))
          (progn
            (backward-char 1)
            (if (looking-at phonebook-entry-delimiter)
                (progn
                  (forward-char 1)
                  (delete-char 1)))))
      (save-buffer)))
  (if phonebook-summary-p
      (phonebook-update-summary)))

(defun phonebook-insert-in-buffer (str buf)
  "Insert string str in buffer buf"
  (save-excursion
    (set-buffer buf)
    (insert str)))

(defun phonebook-insert-entry (buf)
  "Insert an entry into the buffer BUF.
Used to create the LaTeX buffer"
  (let ((in-alist nil)
        (tmp-prefixed))
    (phonebook-insert-in-buffer "\\begin{minipage}[t]{.45\\textwidth}\n" buf)
    (phonebook-insert-in-buffer "\\vspace{.05in}\n" buf)
    (phonebook-insert-in-buffer "\\textbf{" buf)
    (append-to-buffer buf (bol) (eol))
    (phonebook-insert-in-buffer "}\n\n" buf)
    (phonebook-insert-in-buffer "\\vspace{.05in}\n\n" buf)
    (phonebook-insert-in-buffer "\\noindent\n" buf)
    (forward-line 1)
    (while (not (looking-at phonebook-entry-delimiter-regexp))
      (setq in-alist nil)
      (setq tmp-prefixed phonebook-latex-prefixes)
      (while (> (length tmp-prefixed) 0)
        (if (looking-at (car (car tmp-prefixed)))
            (progn
              (setq in-alist t)
              (phonebook-insert-in-buffer (car (cdr (car tmp-prefixed))) buf)
              (forward-char (length (car (car tmp-prefixed))))
              (append-to-buffer buf (point) (eol))
              (phonebook-insert-in-buffer (car (cdr (cdr (car tmp-prefixed))))
                                          buf)))
        (setq tmp-prefixed (cdr tmp-prefixed)))
      (beginning-of-line)
      (if (not in-alist)
          (progn
            (append-to-buffer buf (bol) (eol))
            (phonebook-insert-in-buffer "\\\\\n" buf)))
      (forward-line 1))
  (save-excursion
    (set-buffer buf)
    (goto-char (point-max))
    (beginning-of-line)
    (while (or (looking-at "^ *\\\\\\\\$") (looking-at "^ *$"))
      (forward-line -1))
    (forward-line 1)
    (kill-region (point) (point-max)))
  (phonebook-insert-in-buffer "\\end{minipage}\n" buf)))

(defun phonebook-make-book ()
  "Create a LaTeX document with the phonebook entries"
  (interactive)
  (let ((parity 1)
        (output-buffer))
    (save-excursion
      (find-file (concat (buffer-file-name) ".tex"))
      (setq output-buffer (current-buffer)))
    (save-excursion
      (set-buffer output-buffer)
      (erase-buffer))
    (save-excursion
      (phonebook-insert-in-buffer "\\documentstyle[12pt]{article}\n"
                                  output-buffer)
      (phonebook-insert-in-buffer "\\begin{document}\n"
                                  output-buffer)
      (widen)
      (goto-char 1)
      (while (not (= (point) (point-max)))
        (if (= parity 1)
            (progn
              (phonebook-insert-in-buffer "\\noindent\n" output-buffer)
              (phonebook-insert-in-buffer "\\begin{tabular}{|l||l|}\n"
                                          output-buffer)
              (phonebook-insert-in-buffer "\\hline\n"
                                          output-buffer))
          (phonebook-insert-in-buffer "&\n"
                                      output-buffer))
        (phonebook-insert-entry output-buffer)
        (if (= parity 0)
            (progn
              (phonebook-insert-in-buffer "\\\\\n" output-buffer)
              (phonebook-insert-in-buffer "\\hline\n" output-buffer)
              (phonebook-insert-in-buffer "\\end{tabular}\n\n" output-buffer)))
        (setq parity (- 1 parity))
        (forward-line 1))
      (if (= parity 0)
          (progn
            (phonebook-insert-in-buffer "\\\\\n" output-buffer)
            (phonebook-insert-in-buffer "\\hline\n" output-buffer)
            (phonebook-insert-in-buffer "\\end{tabular}\n" output-buffer)))
      (phonebook-insert-in-buffer "\\end{document}\n" output-buffer)
      (set-buffer output-buffer)
      (latex-mode))
    (display-buffer output-buffer)
    (phonebook-mode)))

;; utility functions (who hasn't written these ?)

(defun eol ()
  "Return the value point at the end of the current line."
  (save-excursion
    (end-of-line)
    (point)))

(defun bol ()
  "Return the value point at the beginning of the current line."
  (save-excursion
    (beginning-of-line)
    (point)))
