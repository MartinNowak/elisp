;;; gutenberg-coding.el --- coding system for Project Gutenberg EBooks.

;; Copyright 2005, 2006, 2007 Kevin Ryde
;;
;; Author: Kevin Ryde <user42@zip.com.au>
;; Version: 8
;; Keywords: i18n
;; URL: http://www.geocities.com/user42_kevin/gutenberg-coding/index.html
;;
;; gutenberg-coding.el is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as published
;; by the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; gutenberg-coding.el is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
;; Public License for more details.
;;
;; You can get a copy of the GNU General Public License online at
;; http://www.gnu.org/licenses.


;;; Commentary:

;; This is a spot of code for getting the right coding system when visiting
;; an EBook or Etext from Project Gutenberg,
;;
;;     http://www.gutenberg.org      PG
;;     http://gutenberg.net.au       PG Australia
;;     http://www.gutenberg.nl       PG EU
;;
;; Gutenberg files come in various encodings.  Most have a "Character set
;; encoding" in the file, the code here looks for that.
;;
;; The code works both for a plain .txt file and for a .txt visited from a
;; .zip file (via `archive-mode').

;;; Emacsen:

;; Designed for Emacs 21 and up.
;;
;; In Emacs 22 gutenberg-coding.el is not needed for utf-8 ebook files which
;; start with the utf-8 marker sequence, but it is needed for other files.


;;; Install:

;; Put gutenberg-coding.el somewhere in your `load-path', and in your .emacs
;; put
;;
;;     (require 'gutenberg-coding)

;;; Bugs:

;; Doesn't work for an `insert-file-contents' of some middle portion of a
;; file.  But that's probably unusual.  Plain `find-file' is fine.


;;; History:

;; Version 1 - the first version.
;; Version 2 - support CP-nnnn style.
;; Version 3 - more charset matching.
;; Version 4 - support PG Australia, and yet more charset matching.
;; Version 5 - support PG EU.
;; Version 6 - format matching for a few more files.
;; Version 7 - cope with emacs 22 style codepage-setup.
;; Version 8 - use display-warning for better error report.


;;; Code:

(defun gutenberg-auto-coding-function (size)
  "Return the coding system for a Project Gutenberg text, or nil.
At point there should be an `insert-file-contents-literally' of
the first part of a file.  SIZE is the number of bytes to
examine.  If it's Project Gutenberg format and it has a character
set indicator, then an Emacs coding system is returned.  If the
encoding is unrecognised, nil is returned.

A Gutenberg file has first line containing \"Project Gutenberg\"
and a subsequent \"Character set encoding:\" in the header
information.  The latter gives the coding system.

Some early Gutenberg files don't have a \"Character set
encoding:\", for those you have to use other Emacs
mechanisms (eg. \\[universal-coding-system-argument]).

See http://www.gutenberg.org for more about Project Gutenberg,
and see http://gutenberg.net.au for Project Gutenberg Australia."

  (save-excursion
    (save-restriction
      ;; look at first SIZE, or first 200 lines, whichever is less
      (narrow-to-region (point) (+ (point) size))
      (forward-line 200)
      (narrow-to-region (point-min) (point))
      (goto-char (point-min))

      ;; skip UTF-8 encoding marker
      (when (looking-at (string #xEF #xBB #xBF))
        (forward-char 3))

      ;; skip "IMPORTANT NOTE" about long lines in some PG Aust
      (when (looking-at "IMPORTANT NOTE\r?\n==============")
        (re-search-forward "===================\r?\n"))

      ;; skip "Complete" in PG Aust 0500911.txt
      (when (looking-at "[\r\n]*Complete[\r\n]*")
        (goto-char (match-end 0)))

      ;; skip initial blank line or two in PG Aust
      (skip-chars-forward "\r\n")

      ;; "Project Gutenberg" in first line,
      ;; or first line starting "Author: " in various PG EU texts
      ;; or first line starting "Title: " in a few recent PG Aust texts
      (and
       (looking-at "\\([\r\n]*.*Project Gutenberg\\|Author: \\|Title: \\)")

       (and (or
             ;; this in PG Aust 0301561.txt
             (re-search-forward "^Character set\\( encoding\\):\r
The following etext is formatted so that it may be used to generate\r
LaTeX, html or Palm ebook format output. The program etset, available\r
in source and Windows executable here:\r
<http://www.fourmilab.ch/etexts/etset/> performs the translation.\r
The text contains a few extended ASCII characters encoded as \r
\\(ISO-85599-1\\)." nil t)

             ;; "Chatacter" is a typo, in about 100 files as of 2005.
             ;; "Character Set" in a few files, eg. 7dgry10.txt
             ;; Allow \r line ending, a few files are Mac encoding
             ;; (eg. PG-Aust 0300911.txt).
             (re-search-forward "[\r\n]Cha[rt]acter [sS]et\\( encoding\\)?:[ \t]*\\(\\([ \t]*[^ \r\n\t]+\\)*\\)" nil t))

            ;; Character set names are fairly free-form.  All perfectly
            ;; understandable to a human, but needing some massaging to get
            ;; to emacs coding system names.
            ;;
            ;; The following transformations were based on grepping all
            ;; .txt files from PG and PG Aust in 2005.
            ;;
            (let* ((orig-charset (match-string 2))
                   (charset      (downcase orig-charset)))

              ;; "ascii, with a few iso-8859-1 characters" etc -> "iso-8859-1"
              ;; "acii, with some iso-8859-1 characters"       -> "iso-8859-1"
              ;; the "acii" typo here is in dvptn10.txt, easy enough to allow it
              (setq charset (replace-regexp-in-string
                             "^as?cii[ (,]*with.* \\(iso-8859-[0-9]+\\).*"
                             "\\1" charset t))

              ;; "big-5" -> "big5"
              ;; "big 5" -> "big5"
              (setq charset (replace-regexp-in-string "^big[- ]5" "big5"
                                                      charset t t))

              (setq charset (replace-regexp-in-string "^utf8" "utf-8"
                                                      charset t t))

              ;; "unicode utf-8" -> "utf-8"
              (setq charset (replace-regexp-in-string "^unicode utf" "utf"
                                                      charset t t))

              ;; "unicode (utf-8)" -> "utf-8"
              (setq charset (replace-regexp-in-string
                             "^unicode (\\(.*\\))$" "\\1"
                             charset t))

              ;; "unicode" -> "utf-8", found in 10752-8.txt
              (setq charset (replace-regexp-in-string "^unicode\r?$" "utf-8"
                                                      charset t))

              ;; "iso-8858-1" -> "iso-8859-1", found in 10439-8.txt
              (setq charset (replace-regexp-in-string "8858" "8859"
                                                      charset t t))

              ;; "ido-8859-1" -> "iso-8859-1", found in 10549-8.txt
              (setq charset (replace-regexp-in-string "^ido-" "iso-"
                                                      charset t t))

              ;; "iso-85599-1" -> "iso-8859-1", found in PG Aust 0301561.txt
              (setq charset (replace-regexp-in-string "^iso-85599-" "iso-8859-"
                                                      charset t t))

              ;; "8-bit iso-8859-1" -> "iso-8859-1", eg. 8dgry10.txt
              (setq charset (replace-regexp-in-string
                             "^8-bit iso-8859-" "iso-8859-" charset t t))

              ;; "ascii--7 bit  or  latin-1(iso-8859-1)--8 bit"
              ;; "(latin-1(iso-8859-1)--8 bit)"
              ;; "latin-1(iso-8859-1)--8 bit"
              ;; all of these -> "latin-1"
              (setq charset (replace-regexp-in-string
                             "^\\(ascii--7 bit *or *\\)?(?\\(latin-\\([0-9]\\)\\)(iso-8859-\\3)--8 bit)?"
                             "\\2" charset t))

              ;; "iso 8859-1 (latin-1)" -> "latin-1"
              (setq charset (replace-regexp-in-string
                             "^iso 8859-\\([0-9]+\\) (\\(latin-\\1\\))$"
                             "\\2" charset t))

              ;; "iso=8859-1"  -> "iso-8859-1"
              ;; "iso latin-1" -> "iso-latin-1"
              ;; "iso8859_1"   -> "iso8859-1"
              (setq charset (replace-regexp-in-string "[= _]" "-"
                                                      charset t t))

              ;; "iso8859-1" -> "iso-8859-1"
              ;; "latin1"    -> "latin-1"
              (setq charset (replace-regexp-in-string
                             "^\\(iso\\|latin\\)\\(\\)[0-9]" "-"
                             charset t t 2))

              (or (and (member charset
                               '("ascii"
                                 "us-ascii"

                                 ;; "ISO-646-US (US-ASCII)" in 107.txt
                                 "iso-646-us-(us-ascii)"

                                 ;; "7-bit ASCII" in 7dgry10.txt
                                 "7-bit-ascii"

                                 ;; "ASCII--7 bit" in PG Aust
                                 "ascii--7-bit"

                                 ;; "US-ASCII, MIDI, Lilypond, MP3 and TeX"
                                 ;; in 10535.txt
                                 "us-ascii,-midi,-lilypond,-mp3-and-tex"))
                       'undecided)

                  (and (string-match "^\\(windows\\(-code-?page\\)?\\|codepage\\|cp\\)-*\\([0-9]+\\)$" charset)
                       ;; load codepage, guard against unknown
                       ;; in emacs 21 codepage-setup returns the coding
                       ;; system symbol, in emacs 22 you have to make it
                       ;; yourself
                       (condition-case nil
                           (let ((pagestr (match-string 3 charset)))
                             (codepage-setup pagestr)
                             (intern (concat "cp" pagestr)))
                         (error nil)))

                  (let ((coding (intern charset)))
                    (and (coding-system-p coding)
                         coding))

                  (progn
                    (if (fboundp 'display-warning) ;; not in emacs 21
                        (display-warning
                         'i18n
                         (format "Unknown Project Gutenberg charset: %s"
                                 orig-charset)
                         :warning)
                      (message "Unknown Project Gutenberg charset: %s"
                               orig-charset))
                    nil))))))))

(defadvice set-auto-coding (around gutenberg-coding activate)
  "Find the coding system for a Project Gutenberg EBook file.
See `gutenberg-auto-coding-function' for details."

  ;; `set-auto-coding' moves point to the end of the buffer.  Don't use
  ;; save-excursion in case something depends on it working that way, but do
  ;; remember where we're supposed to start looking from.
  ;;
  (let ((gutenberg-coding-save-point (point)))
    (unless ad-do-it
      (when (string-match "\\.txt\\'" filename)
        (save-excursion
          (goto-char gutenberg-coding-save-point)
          (setq ad-return-value (gutenberg-auto-coding-function size)))))))

(provide 'gutenberg-coding)

;;; gutenberg-coding.el ends here
