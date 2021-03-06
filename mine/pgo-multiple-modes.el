;;; pgo-multiple-modes.el --- Setup Multiple Modes in Same Buffer.
;;
;; Filename: pgo-multiple-modes.el
;; Description:
;; Author: Per Nordlöw
;; Maintainer:
;; Created: tor jun 11 16:05:51 2009 (+0200)
;; Version:
;; Last-Updated:
;;           By:
;;     Update #: 10
;; URL:
;; Keywords:
;; Compatibility:
;;
;; Features that might be required by this library:
;;
;;   `lp-elisp', `mumamo-fun', `two-mode-mode'.
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

;;; http://www.emacswiki.org/emacs/MultipleModes

;; multi-mode.el --- support for multiple major modes
(when (and nil (require 'multi-mode nil t))
  )

;; mumamo.el --- Multiple major modes in a buffer
(when (require 'mumamo-fun nil t)
  ;; How to add support for a new mix of major modes This is done by
  ;; creating a new function using `define-mumamo-multi-major-mode'.
  ;; See that function for more information.
  )
;; Note: Has given errors:
;; Debugger entered--Lisp error: (void-variable whitespace)
;; message("\nFinished loading %s\n" "~/elisp/nxhtml/util/mumamo.elc")
;; byte-code("\302\303!\210\304\303\305\306#\210\307\310\311\312\313$\210\314\310\306\"\210\307\315\316\312\313$\210\314\315\306\"\210\307\317\320\312\313$\210\314\317\306\"\210\307\321\322\312\313$\210\314\321\306\"\210\307\323\324\312\313$\210\314\323\306\"\210\307\325\326\312\313$\210\314\325\306\"\210\327\330\312\331#\210\327\332\312\333#\210\327\334\312\335#\210\327\315\312\336#\210\327\310\312\337#\210\327\317\312\340#\210\327\321\312\341#\210\327\323\312\342#\210\327\325\312\343#\210\344\345\346\"\210\203\226 \347\350\"\210	\203\237 \347\351	\"\210\352\353!\207" [buffer-file-name load-file-name make-variable-buffer-local rng-end-major-mode-chunk-function put permanent-local t ad-add-advice rng-mark-error (mumamo-ad-rng-mark-error nil t (advice lambda nil "Adjust range for error to chunks." ...)) around nil ad-activate rng-do-some-validation-1 (mumamo-ad-rng-do-some-validation-1 nil t (advice lambda nil "Adjust validation to chunks." ...)) rng-after-change-function (mumamo-ad-rng-after-change-function nil t (advice lambda nil ...)) rng-validate-while-idle (mumamo-ad-rng-validate-while-idle nil t (advice lambda nil ...)) rng-validate-quick-while-idle (mumamo-ad-rng-validate-quick-while-idle nil t (advice lambda nil ...)) xmltok-add-error (mumamo-ad-xmltok-add-error nil t (advice lambda nil "Prevent rng validation errors in non-xml chunks.\nThis advice only prevents adding nxml/rng-valid errors in non-xml\nchunks.  Doing more seems like a very big job - unless Emacs gets\na narrow-to-multiple-regions function!" ...)) ad-enable-advice syntax-ppss mumamo-ad-syntax-ppss syntax-ppss-flush-cache mumamo-ad-syntax-ppss-flush-cache syntax-ppss-stats mumamo-ad-syntax-ppss-stats mumamo-ad-rng-do-some-validation-1 mumamo-ad-rng-mark-error mumamo-ad-rng-after-change-function mumamo-ad-rng-validate-while-idle mumamo-ad-rng-validate-quick-while-idle mumamo-ad-xmltok-add-error font-lock-add-keywords emacs-lisp-mode (("\\<define-mumamo-multi-major-mode\\>" . font-lock-keyword-face)) message "\nFinished evaluating %s\n" "\nFinished loading %s\n" provide mumamo] 5)
;; require(mumamo)

;; Once MMM Mode is installed, it has to be configured correctly.  This
;; can be done in a site-start file or in user's initialization files ;
;; usually the latter is preferable, except possibly for autoloads.
;; First the package needs to be loaded, with either
(when (and nil (require 'mmm-mode nil t))

  ;; or instead, to save time during emacs startup,

  (require 'mmm-auto nil t)

  ;; Then you will probably want to set something like this:

  (setq mmm-global-mode 'maybe)
  (mmm-add-mode-ext-class 'html-mode "\\.php\\'" 'html-php)

  ;; The first line tells MMM Mode to load itself whenever you open an
  ;; appropriate file, and the second is an example which says to notice
  ;; PHP regions in html-mode files having a `.php' extension.  Both
  ;; lines are necessary.

  ;; You will, of course, want to change and duplicate the second line
  ;; according to your needs. either of the first two parameters can be
  ;; `nil', meaning not to consider that criterion.  For example, if all
  ;; your html files, regardless of extension, are Mason components, you
  ;; will want something like:

  (mmm-add-mode-ext-class 'html-mode nil 'mason)

  ;; whereas if all your files with a `.nw' extension, regardless of
  ;; primary mode (some may be LaTeX, others HTML, say) are Noweb, you
  ;; will prefer

  (mmm-add-mode-ext-class nil "\\.nw\\'" 'noweb)

  ;;(mmm-add-mode-ext-class 'org-mode "\\.org\\'" 'org-emacs-lisp)
  )

;; See the info file for more extensive documentation, and for other
;; configuration options.

(require 'lp-elisp nil t) ;Literate Programming in Emacs Lisp

(provide 'pgo-multiple-modes)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; pgo-multiple-modes.el ends here
