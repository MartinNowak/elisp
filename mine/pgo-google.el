;;; pgo-google.el --- Setup Interfaces to Google's Services.
;;
;; Filename: pgo-google.el
;; Description:
;; Author: Per Nordlöw
;; Maintainer:
;; Created: fre okt 16 11:58:14 2009 (+0200)
;; Version:
;; Last-Updated:
;;           By:
;;     Update #: 11
;; URL:
;; Keywords:
;; Compatibility:
;;
;; Features that might be required by this library:
;;
;;   Required feature `pgo-google' was not provided.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Commentary:
;;
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Change log:
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Code:

;; google.el --- Emacs interface to the Google API
(when (require 'google nil t)
  ;; (setq google-license-key "my license key" ; optional
  ;;       google-referer "my url")            ; required!
  ;; (google-search-video "rickroll")
  )

;; googleaccount.el --- Google Accounts login from Emacs
(when (require 'googleaccount nil t)
  ;;   (setq auth-header
  ;;      (googleaccount-login service email passwd))
  ;;   (if auth-header
  ;;     (let ((url-request-extra-headers (list auth-headers)))
  ;;        (url-retrieve ...some Google service URL...)
  ;;        ))
  )

;; gcalc.el --- A Google calculator interface
;; To use the Google calculator, enter `M-x gcalc RET expression RET'.
;; See <http://www.google.com/help/calculator.html> for instructions
;; on how to formulate expressions for the calculator.
;; See also <http://www.google.com/help/features.html#currency> for
;; help with currency conversion.
(when (require 'gcalc nil t)
  (defalias 'google-calculator 'gcalc)
  ;;(global-set-key [(control c) (C)] 'gcalc)
  )

;; google-region
(defun google-search-on-region (&optional flags)
  "Google the selected region"
  (interactive)
  (let ((query (buffer-substring (region-beginning) (region-end))))
    (browse-url (concat "http://www.google.com/search?ie=utf-8&oe=utf-8&q=" query))))

;; Pulls definitions from google and displays them in a buffer.
(when (require 'google-define nil t)
  ;;(global-set-key [(control c) (D)] 'google-define)
  )
(defun google-define-word-or-phrase (query)
  (interactive "sInsert word or phrase to search: ")
  (let* ((url (concat "http://www.google.com.pe/search?hl=en&q=define%3A"
                      (replace-regexp-in-string " " "+" query)))
         (definition
           (save-excursion
             (with-temp-buffer
               (mm-url-insert url)
               (goto-char (point-min))
               (if (search-forward "No definitions found of " nil t)
                   "No definitions found"
                 (buffer-substring (search-forward "<li>") (- (search-forward "") 1)))))))
    (message "%s: %s" query definition)))

(provide 'pgo-google)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; pgo-google.el ends here
