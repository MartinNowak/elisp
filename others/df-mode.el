;;; df-mode.el --- Minor mode to show space left on devices in the mode line 

;; Copyright (C) 1999 by Association April
;; Copyright (C) 2004 by Frederik Fouvry

;; Author: Benjamin Drieu <bdrieu@april.org>
;;         Frederik Fouvry <Frederik.Fouvry@coli.uni-saarland.de>
;; Keywords: unix, tools

;; This file is NOT part of GNU Emacs.

;; GNU Emacs as this program are free software; you can redistribute
;; them and/or modify them under the terms of the GNU General Public
;; License as published by the Free Software Foundation; either
;; version 2, or (at your option) any later version.

;; They are both distributed in the hope that they will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.


;;; Commentary:

;;  This is an extension to display disk usage in the mode line.  Disk
;;  space remaining is updated every `df-interval' seconds.
;; 
;;  If you work with a lot of users sharing the same partition, it
;;  sometimes happens that you have no place left to save your work,
;;  which can be extremely annoying, and might lead to loss of work.
;;  This package allows you to have disk space available and buffer
;;  size displayed in the mode line, so you know when you can save
;;  your file or when it is time to do some tidying up.
;;
;;  Comments and suggestions are welcome.
;;
;;  df is simple to use:
;;  - Make sure this file is in your load-path
;;  - Put in ~/.emacs:
;;      (autoload 'df-mode "df-mode" nil t)
;;      (df-mode 1)
;;    The minor mode can be toggled with M-x df-mode.
;;
;;  Version: 2004-08-23

;;; Code:

(require 'timer)

(defgroup df nil
  "Disk space monitoring"
  :group 'environment
  :version 21.3)

;;;###autoload
(defcustom df-mode nil
  "Toggle df-mode.
Setting this variable directly does not take effect;
use either \\[customize] or the function `df-mode'."
  :set (lambda (symbol value) (df-mode (or value 0)))
  :initialize 'custom-initialize-default
  :type    'boolean
  :group   'df
  :require 'df-mode)

(defcustom df-program "df"
  "*The command to use to retrieve disk usage statistics."
  :type 'string
  :group 'df)

(defcustom df-interval 60 
  "*The time (in seconds) between updates of the disk usage
statistics in the mode line."
  :type 'integer
  :group 'df)

(defcustom df-block-size 1000
  "*The size of the blocks (in kilobytes) that `df-program' is asked
to count.  It must be a non-zero positive integer.  \"1k\" in the
mode-line denotes one such block.  Common values are 1000 and 1024
\(bytes) .  The POSIX value of 512 can also be used, as can other
values, but they might be confusing (in the case of the POSIX value
\"1k\" denotes 512 bytes).

`df-block-size' is not to be confused with `df-unit', which is the
factor of difference between the unit prefixes."
  :type '(choice (const 1000)
		 (const 1024)
		 (const :tag "POSIX" 512)
		 (integer :tag "Another value"))
  :group 'df)

(defcustom df-unit 1000
  "*This is the difference in order of magnitude between the
subsequent elements in `df-unit-array': `df-unit'k is 1M, and so on.
In SI, this is 1000, but elsewhere 1M (for instance) is commonly taken
to be 1024k."
  :type '(choice (const :tag "SI" 1000)
		 (const :tag "Human-readable" 1024))
  :group 'df)

(defcustom df-output-regexp
  "^\\S-+\\s-+\\(?:[0-9]+\\s-+\\)\\{2\\}\\([0-9]+\\)\\s-+[0-9]\\{1,3\\}% .+$"
;; Linux, non POSIX:
;; "\\s-+\\(?:[0-9]+\\s-*\\)\\{2\\}\\([0-9]+\\)\\s-*[0-9]\\{1,3\\}% /"
  "*Regexp describing the output of `df-program'. The amount of free
space should be in group 1.

See also `df-switches'."
  :type 'regexp
  :group 'df)

(defcustom df-switches '("-P")
  "*This is a list of strings containing command line switches for
`df-program'.  If you add or remove switches that change the format of
the output from `df-program', you need to adapt `df-output-regexp' as
well.

In GNU df, \"-P\" makes `df-program' print each result on one line."
  :type '(repeat string)
  :group 'df)

(defcustom df-block-size-switch "-B"
  "*Command line switch to `df-program' for setting the block size.
The size (see `df-block-size') will be attached directly after the
switch (without spaces)."
  :type 'string
  :group 'df)


(defvar df-string ""
  "Variable containing the string to be inserted into the mode line.")
(defvar df-free-space nil
  "Variable containing the amount of free space on the current
partition.")
(defvar df-timer nil
  "Variable containing the timer for `df-update'.")

(defvar df-buffer-weight 0)

;; The smallest unit should be the first
(defconst df-unit-array ["k" "M" "G" "T" "P" "E" "Z" "Y"]
  "Array with unit prefixes.  Every next element should be `df-unit'
times bigger than the current one.")



(defun df-reduce-number (number)
  "Takes NUMBER (assumed to be in the unit \"k\", the first element of
`df-unit-array'), and converts it to the largest unit suitable
\(i.e. where the value lies between 0 and `df-unit').  It returns a
cons with the new value and its unit."
  (if (> number 0)
      (let* ((number (float number))
	     (exponent (floor (log number df-unit))))
	(cons (/ number (expt df-unit exponent))
	      (aref df-unit-array exponent)))
    (cons 0 (aref df-unit-array 0))))


;; Sets `df-mode' to t if `df-timer' is a timer and it is in
;; `timer-list', nil otherwise.  Side effect: if `df-timer' is a
;; timer, but not in `timer-list', `df-timer' is set to nil as well.
;; (ie postcondition: (null df-mode) <=> (not (timerp df-timer)).
(defun df-mode-set-df-mode ()
  (setq df-mode (not (null (and (timerp df-timer)
				(or (member df-timer timer-list)
				    (setq df-timer nil)))))))


(defun df-update ()
  "Updates the disk usage statistics.  It is run every `df-interval'
seconds."
  (interactive)
  (setq df-buffer-weight (and (buffer-file-name)
			      (/ (buffer-size) df-unit)))
  (set-process-filter
   (apply 'start-process df-program nil df-program
	  (cons (format "%s%d" df-block-size-switch df-block-size)
		(append df-switches
			(list (or (buffer-file-name)
				  (expand-file-name default-directory))))))
   'df-filter))


;; For float values:
;; (format "%%.%df" (- (ceiling (log df-unit 10)) (ceiling (log (car res) 10))))
;; but trailing 0s should be removed
(defun df-filter (proc string)
  "Filter for the output from `df-program'.  It sets the mode-line
value."
  (setq df-string
	(format " %s/%s"
		(if df-buffer-weight
		    (let ((res (df-reduce-number df-buffer-weight)))
		      (format "%d%s" (round (car res)) (cdr res)))
		  "-")
		(if (and (string-match df-output-regexp string)
			 (match-string 1 string))
		    (progn
		      (setq df-free-space
			    (string-to-number (match-string 1 string)))
		      (let ((res (df-reduce-number df-free-space)))
			(format "%d%s" (round (car res)) (cdr res))))
		  "-"))))


;; Is used in run-hooks-with-args-until-success, so it should always return
;; nil.
(defun df-check (&rest args)
  "Check whether there is still enough space to save the file.  If not,
ask whether the file should be saved or not."
  (when (and df-buffer-weight df-free-space 
	     (> df-buffer-weight df-free-space)
	     (not (yes-or-no-p 
		   "It seems there is not enough disk space.  Save anyway? ")))
    (error "Buffer %s not saved" (buffer-name)))
  nil)


;;;###autoload
(defun df-mode (&optional arg)
  "Toggle display of space left on the filesystem on on which the
contents of the current buffer is stored.  This display is updated
every `df-interval' seconds.

With a numeric argument, enable this display if ARG is positive."
  (interactive "P")
  (if (or (and (null arg) (null df-timer))
	  (and arg (> (prefix-numeric-value arg) 0)))
      (unless df-mode
	(make-variable-buffer-local 'df-buffer-weight)
	(make-variable-buffer-local 'df-string)
	(make-variable-buffer-local 'df-free-space)
	(setq df-timer (run-with-timer 0 df-interval 'df-update))
	(add-to-list 'minor-mode-alist '(df-mode df-string) t)
	(add-hook 'write-file-hooks 'df-check)
	(add-hook 'find-file-hooks 'df-update)
	(df-update))
    (progn
      (cancel-timer df-timer)
      (setq df-timer nil)))
  (df-mode-set-df-mode))

(provide 'df-mode)

;;; df.el ends here
