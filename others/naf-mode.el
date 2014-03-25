;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; -*- mode: EMACS-LISP; -*-
;;; this is naf-mode.el
;;; ================================================================
;;; DESCRIPTION:
;;; Major mode for editing Name Authority Files.
;;;
;;; CUSTOMS:
;;; `naf-mode-comment-prefix'
;;;
;;; GROUPS:
;;; `naf-mode', `naf-mode-faces', `highlight-symbol'
;;;
;;; FUNCTIONS:►►►
;;; `new-naf'
;;; FUNCTIONS:◄◄◄
;;;
;;; MACROS:
;;;
;;; CONSTANTS:
;;; `naf-mode-version'
;;;
;;; VARIABLES:
;;; `naf-font-lock-keywords', `naf-mode-syntax-table', `naf-mode-map',
;;; `naf-mode-hook', `*naf-mode-xref-of-xrefs*'
;;;
;;;
;;; ALIASED/ADVISED/SUBST'D:
;;;
;;; DEPRECATED:
;;;
;;; RENAMED:
;;;
;;; MOVED:
;;;
;;; REQUIRES:
;;; mon-dir-utils
;;; mon-dir-locals-alist
;;; mon-regexp-symbols
;;; naf-mode-replacements
;;; naf-skeletons
;;; naf-mode-insertion-utils
;;; mon-url-utils
;;; naf-name-utils
;;; naf-mode-faces
;;; naf-mode-institution
;;; naf-mode-db-fields
;;; naf-mode-db-flags
;;; naf-mode-ulan-utils
;;; naf-mode-publications-periodicals-french
;;; naf-mode-publications-periodicals-english
;;; naf-mode-publications-periodicals-intnl
;;; naf-mode-dates
;;; naf-mode-english-roles
;;; naf-mode-french-roles
;;; naf-mode-nation-english
;;; naf-mode-nation-french
;;; naf-mode-nationality-french
;;; naf-mode-nationality-english
;;; naf-mode-state-names
;;; naf-mode-city-names-us
;;; naf-mode-intnl-city-names
;;; naf-mode-regions
;;; naf-mode-art-keywords
;;; naf-mode-events
;;; naf-mode-group-period-styles
;;; naf-mode-benezit-flags
;;; naf-mode-sql-skeletons
;;; naf-mode-awards-prizes, 
;;; easymenu
;;;
;;; TODO:
;;;
;;; NOTES:
;;;
;;; SNIPPETS:
;;;
;;; THIRD PARTY CODE:
;;;
;;; AUTHOR: MON KEY
;;; MAINTAINER: MON KEY
;;;
;;; PUBLIC-LINK: (URL `http://www.emacswiki.org/emacs/naf-mode.el')
;;; FIRST-PUBLISHED: <Timestamp: #{2009-09-22T18:04:57-04:00Z}#{09392} - by MON KEY>
;;;
;;; FILE CREATED: SPRING 2008
;;; HEADER-ADDED: <Timestamp: #{2009-08-13T11:05:02-04:00Z}#{09334} - by MON KEY>
;;; ================================================================
;;; This file is not part of GNU Emacs.
;;;
;;; This program is free software; you can redistribute it and/or
;;; modify it under the terms of the GNU General Public License as
;;; published by the Free Software Foundation; either version 3, or
;;; (at your option) any later version.
;;;
;;; This program is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;; General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with this program; see the file COPYING.  If not, write to
;;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;;; Floor, Boston, MA 02110-1301, USA.
;;; ================================================================
;;; Copyright (C) 2009 MON KEY
;;; ==========================
;;; CODE:

;;; ==============================
(require 'mon-dir-utils)
(require 'mon-dir-locals-alist)
(require 'mon-regexp-symbols)
(require 'naf-mode-replacements) ;; :before insertion-utils
(require 'naf-skeletons)
(require 'naf-mode-insertion-utils)
(require 'mon-url-utils)
(require 'naf-name-utils)
;; trying this: <Timestamp: #{2009-09-17T15:29:44-04:00Z}#{09384} - by MON KEY>
(require 'naf-mode-faces)
(require 'naf-mode-institution) ;; :after naf-mode-faces
;;;
(require 'naf-mode-db-fields)
(require 'naf-mode-db-flags)
(require 'naf-mode-ulan-utils)
(require 'naf-mode-publications-periodicals-french)
(require 'naf-mode-publications-periodicals-english)
(require 'naf-mode-publications-periodicals-intnl)
(require 'naf-mode-dates)
(require 'naf-mode-english-roles)
(require 'naf-mode-french-roles)
(require 'naf-mode-nation-english)
(require 'naf-mode-nation-french)
(require 'naf-mode-nationality-french)
(require 'naf-mode-nationality-english)
(require 'naf-mode-state-names)
(require 'naf-mode-city-names-us)
(require 'naf-mode-intnl-city-names)
(require 'naf-mode-regions)
(require 'naf-mode-art-keywords)
(require 'naf-mode-events)
(require 'naf-mode-group-period-styles)
(require 'naf-mode-benezit-flags)
(require 'naf-mode-sql-skeletons)
(require 'naf-mode-awards-prizes)
(require 'easymenu)
;;; COMMENTED: <Timestamp: #{2009-09-17T15:30:05-04:00Z}#{09384} - by MON KEY>
;; (require 'naf-mode-faces)
;; (require 'naf-mode-institution) ;; naf-mode-institution should come _after_ naf-mode-faces
;;
(require 'mon-time-utils)
;;; ==============================

;;; ==============================
(defgroup naf-mode 'nil
  "Customization of `naf-mode'."
  :link  '(url-link "http://www.emacswiki.org/emacs/naf-mode.el")
  :group 'local)

(defgroup naf-mode-faces 'nil
  "Customization of `naf-mode' font-locking faces."
  ;; :link (url-link URL)
  :link '(file-link "./naf-mode-faces.el")
  :group 'faces
  :group 'naf-mode)

;;; ==============================
(defconst naf-mode-version "September 2009"
  "Return current version of `naf-mode'.")

;;; ==============================
(defcustom naf-comment-prefix ";;;"
  "*String used by `comment-region' to comment out region in a NAF buffer.
Used in `naf-mode'."
  :type 'string
  :group 'naf-mode)

;;; ==============================
;;; CREATED: <Timestamp: #{2009-09-14T18:45:10-04:00Z}#{09381} - by MON KEY>
(defvar *naf-mode-xref-of-xrefs*
  '(*naf-mode-art-keywords-xrefs* 
    *naf-mode-institution-xrefs*
    *naf-mode-city-names-us-xrefs*
    *naf-mode-awards-prizes-xrefs*
    *naf-mode-benezit-flags-xrefs*
    *naf-mode-group-period-styles-xrefs*
    *naf-mode-dates-xrefs*
    *naf-mode-events-xrefs*)
"*List of symbol names of variables holding package level xrefs lists.")

;;;test-me; *naf-mode-xref-of-xrefs*
;;;test-me; (member '*naf-mode-events-xrefs* *naf-mode-xref-of-xrefs*)
;;;test-me; (symbol-value (car (member '*naf-mode-events-xrefs* *naf-mode-xref-of-xrefs*)))
;;
;;;(progn (makunbound '*naf-mode-xref-of-xrefs*) (unintern '*naf-mode-xref-of-xrefs*))

;;; ==============================
(defvar naf-font-lock-keywords
  `((,naf-mode-delim                     0 naf-mode-delim-fface t)
    (,naf-mode-comment-delim             0 naf-mode-delim-fface t)
    (,naf-mode-db-entry                  0 naf-mode-db-entry-fface t)
    (,naf-mode-timestamp-flag            0 naf-mode-timestamp-fface t)
    ;;working??? <Timestamp: Wednesday July 29, 2009 @ 04:35.53 PM - by MON KEY>
    ;;`(,(concat naf-mode-accessed-by-flag) 0 naf-mode-accessed-by-fface t)
    (,naf-mode-accessed-by-flag          0 naf-mode-accessed-by-fface t)
    (,naf-mode-db-numbers-flag           0 naf-mode-db-field-entry-fface t)
    (,naf-mode-field-names               0 naf-mode-field-fface t)
    (,naf-mode-db-field-flags            0 naf-mode-db-field-entry-fface t)
    (,naf-mode-db-field-flags-bnf        0 naf-mode-db-field-entry-bnf-fface t)
    (,naf-mode-db-field-flags-ulan-paren 0 naf-mode-db-field-entry-ulan-fface t)
    (,*naf-mode-ulan-rltd-ppl-corp*      0 naf-mode-ulan-ppl-corp-fface t)
    (,*naf-mode-x-of-ulan-bol*           0 naf-mode-ulan-ppl-corp-fface t)
    (,naf-mode-field-names-bnf           0 naf-mode-field-bnf-fface t)
    ;;
    ;; COMMENTED: <Timestamp: #{2009-08-07T15:16:32-04:00Z}#{09325} - by MON KEY>
    ;; The identical version below should work fine... we'll see.
    ;; (,naf-mode-url-flag 0 naf-mode-field-url-flag-fface t)
    ;; (,naf-mode-url-wrapper-flag
    ;;  (2 naf-mode-delimit-url-flag-fface)
    ;;  (3 naf-mode-field-url-flag-fface)
    ;;  (4 naf-mode-delimit-url-flag-fface))
    ;;
    (,naf-mode-url-flag                  0 naf-mode-field-url-flag-fface t)
    (,naf-mode-url-wrapper-flag
     ;;....1..2...........3.......4....................
     ;;"^\\(\\((URL `\\)\\(.*\\)\\(')\\)\\)[[:space:]]?$"
     (2 naf-mode-delimit-url-flag-fface)
     (3 naf-mode-field-url-flag-fface)
     (4 naf-mode-delimit-url-flag-fface))
    ;;
    (,naf-mode-english-roles-primary     0 naf-mode-primary-role-fface keep)
    (,naf-mode-french-roles-primary      0 naf-mode-primary-role-fface keep)
    ;; =====ENTITY NAME RELATED========
    (,naf-mode-publications-periodicals-english          0 naf-mode-publication-periodical-fface)
    (,naf-mode-publications-periodicals-english-one-word 0 naf-mode-publication-periodical-fface)
    (,naf-mode-publications-periodicals-french           0 naf-mode-publication-periodical-fface)
    (,naf-mode-publications-periodicals-intnl            0 naf-mode-publication-periodical-fface)
    ;; ==============================
    ;;("|" 0 naf-mode-name-divider-fface)
    (,naf-mode-name-divider               0 naf-mode-name-divider-fface) 
    (,naf-mode-alternate-name-flags       0 naf-mode-alternate-name-fface)
    (,*naf-mode-x-of*                     0 naf-mode-alternate-name-fface)
    (,naf-mode-group-period-styles        0 naf-mode-group-period-style-fface)
    (,naf-mode-world-events               0 naf-mode-event-fface) ;; keep?
    (,naf-mode-art-events-generic         0 naf-mode-event-fface) ;; keep?
    (,naf-mode-art-events-generic-english 0 naf-mode-event-fface) ;; keep?
    (,naf-mode-art-events-generic-french  0 naf-mode-event-fface) ;; keep?
    (,naf-mode-art-events-french          0 naf-mode-event-fface) ;; keep?
    (,naf-mode-art-events-english         0 naf-mode-event-fface) ;; keep?
    ;; ======= INSITITUIONS =========
    (,naf-mode-institution-museum-names   0 naf-mode-institution-fface keep)
    (,naf-mode-academy-names              0 naf-mode-institution-fface keep)
    (,naf-mode-school-names-intnl         0 naf-mode-institution-fface keep)
    (,naf-mode-school-names-english       0 naf-mode-institution-fface keep)
    (,naf-mode-institution-names-generic  0 naf-mode-institution-fface keep)
    (,naf-mode-benezit-museum-short       0 naf-mode-institution-fface keep)
    (,naf-mode-inst-names-anchored        0 naf-mode-institution-fface keep)
    (,naf-mode-awards-prizes-names        0 naf-mode-awards-prizes-fface)
    ;; == 2ND ROLE & ART KEYWORD FLAGS|SEPERATE FACE ==
    (,naf-mode-english-roles-secondary    0 naf-mode-secondary-role-fface)
    (,naf-mode-french-roles-secondary     0 naf-mode-secondary-role-fface)
    (,naf-mode-art-keywords               0 naf-mode-art-keywords-role-fface)
    ;; ==== DATE AND TEMPORAL RELATED ====
    (,naf-mode-lifespan                   0 naf-mode-date-fface)
    (,naf-mode-date-string                0 naf-mode-date-fface)
    (,naf-mode-english-dates              0 naf-mode-date-fface)
    (,naf-mode-french-dates               0 naf-mode-date-fface)
    (,naf-mode-benezit-date               0 naf-mode-date-fface)
    (,naf-mode-circa-dates                0 naf-mode-date-fface)
    (,naf-mode-year-range                 0 naf-mode-date-fface)
    (,naf-mode-english-days               0 naf-mode-date-fface)
    (,naf-mode-french-days                0 naf-mode-date-fface)
    (,naf-mode-simple-date                0 naf-mode-date-fface)
    ;; ==============================
    ;; ONCE ALL PLISTS AND EXTRA PROPS ARE FINALIZED:
    ;; ((,@(concat naf-mode-active-date
    ;; 		 naf-mode-active-date-flags-paren
    ;; 		 naf-mode-active-date-flags-solo))
    ;;  ;;     (1 naf-mode-date-active-fface :naf-date-type active)
    ;;  ;;     (2 naf-mode-date-active-fface t :naf-date-type active)
    ;;  ;;     (3 naf-mode-date-active-fface :naf-date-type active))
    ;;  (1 naf-mode-date-active-fface)
    ;;  (2 naf-mode-date-active-fface)
    ;;  (3 naf-mode-date-active-fface))
    ;; ==============================
    (,naf-mode-active-date                0 naf-mode-date-active-fface)
    (,naf-mode-active-date-flags-paren    0 naf-mode-date-active-fface t)
    (,naf-mode-active-date-flags-solo     0 naf-mode-date-active-fface)
    ;; ========= BENEZIT FLAGS ===========
    (,naf-mode-benezit-currency-acronym   0 naf-mode-benezit-fface)
    (,naf-mode-benezit-section-flag       0  naf-mode-benezit-fface)
    ;; == LOCATION AND PLACE NAME RELATED ==
    (,naf-mode-nation-english             0 naf-mode-place-fface)
    (,naf-mode-nation-french              0 naf-mode-place-fface)
    (,naf-mode-nationality-english        0 naf-mode-nationality-fface)
    (,naf-mode-nationality-french         0 naf-mode-nationality-fface)
    (,naf-mode-state-names                0 naf-mode-place-fface)
    (,naf-mode-city-names-us              0 naf-mode-place-fface)
    (,naf-mode-intnl-city-names           0 naf-mode-place-fface)
    (,naf-mode-region-names-french        0 naf-mode-place-fface)
    (,naf-mode-region-names-other         0 naf-mode-place-fface)
    (,naf-mode-intnl-auction-city-names   0 naf-mode-place-fface))
  "*Collect `naf-mode-keywords' into a single place.
Variables and Constants of this list loaded by `naf-mode' require statments.
They are encapsulated here for easy modification.")

;;;test-me; naf-font-lock-keywords
;;
;;;(progn (makunbound 'naf-font-lock-keywords) (unintern 'naf-font-lock-keywords))

;;; ==============================

;;; ==============================
(defvar naf-mode-syntax-table
  (let ((st (make-syntax-table)))
    (modify-syntax-entry ?\" ".   " st)
    (modify-syntax-entry ?\\ ".   " st)
    ;; Add `p' so M-c on `hello' givs to `Hello', not `hello'.
    (modify-syntax-entry ?' "W p" st)
    st)
  "Syntax table used while in `naf-mode'.")

;;; ==============================
;;; Construct a keymap for `naf-mode'.
;;; NOTE: Bindings marked ;!! are bound in mon-keybindings.el!
;;;       They use a different key here. Typically naf-mode binds
;;;       "\C-c\M-##"
;;; If/when you fuckup and forget to escape "C-c\M-" again you wont' be able to
;;; type "C" in a naf-buffer. Reset that with (define-key naf-mode-map "C" nil)
;;; To rebind temporarily (define-key naf-mode-map "\C-c\M-" nil)
;;;
;;; Pending assignment:
;;; (define-key naf-map "\C-c\M-" ')
;;; (define-key naf-map "\C-c\M-" 'mon-save-current-directory)
;;; ==============================
(defvar naf-mode-map
  (let ((naf-map (make-sparse-keymap)))
    ;; M-c Should be Kept available for "cleaning" functions.
    (define-key naf-map "\C-c\M-ar"     'mon-append-to-register)
    (define-key naf-map "\C-c\M-cbb"    'mon-cln-bib) ;cbb ok?
    (define-key naf-map "\C-c\M-cbl"    'mon-cln-blank-lines)
    (define-key naf-map "\C-c\M-cel"    'mon-cln-spc-tab-eol)
    (define-key naf-map "\C-c\M-cer"    'mon-cln-spc-tab-at-eol-in-region)
    (define-key naf-map "\C-c\M-cul"    'mon-cln-ulan)
    (define-key naf-map "\C-c\M-cwk"    'mon-cln-wiki)
    (define-key naf-map "\C-c\M-clo"    'mon-cln-loc)
    (define-key naf-map "\C-c\M-cet"    'mon-cln-ebay-time-string)
    (define-key naf-map "\C-c\M-cht"    'mon-cln-html-tags)
    (define-key naf-map "\C-c\M-cim"    'mon-cln-imdb)
    (define-key naf-map "\C-c\M-cph"    'mon-cln-philsp)
    (define-key naf-map "\C-c\M-cpl"    'mon-cln-piped-list)
    (define-key naf-map "\C-c\M-cnq"    'mon-cln-uniq-lines)
    (define-key naf-map "\C-c\M-cwb"    'mon-clnBIG-whitespace)
    (define-key naf-map "\C-c\M-cwh"    'mon-cln-whitespace)
    (define-key naf-map "\C-c\M-ckw"    'mon-kill-whitespace)
    (define-key naf-map "\C-c\M-cwt"    'mon-cln-trail-whitespace)
    ;; M-dw			        
    (define-key naf-map "\C-c\M-dwt"    'mon-toggle-dired-dwim-target)
    ;; M-e FOR EXPLORER RELATED FUNCTIONS:
    (define-key naf-map "\C-c\M-exh"    'mon-open-explorer)
    (define-key naf-map "\C-c\M-exi"    'mon-open-images-ed-swap)
    (define-key naf-map "\C-c\M-exm"    'mon-open-moz-down)
    ;; M-f__ FOR WINDOW RELATED FUNCTIONS:
    (define-key naf-map "\C-c\M-flw"    'mon-flip-windows)
    (define-key naf-map "\C-c\M-flv"    'mon-twin-vertical)
    (define-key naf-map "\C-c\M-flh"    'mon-twin-horizontal)
    ;; M-fm FRAME RELATED:	        
    (define-key naf-map "\C-c\M-fmx"    'mon-maximize-frame)
    (define-key naf-map "\C-c\M-fmn"    'mon-minimize-frame)
    (define-key naf-map "\C-c\M-fmr"    'mon-restore-frame)
    (define-key naf-map "\C-c\M-fmb"    'mon-menu-bar)
    ;; M-fw WINDOW HEIGHT/WIDTH:        
    (define-key naf-map "\C-c\M-fwh"    'doremi-window-height)
    (define-key naf-map "\C-c\M-fww"    'doremi-window-window-width)
    ;; M-h__ FOR HELP:		        
    (define-key naf-map "\C-c\M-hky"    'mon-help-keys)        
    (define-key naf-map "\C-c\M-hdc"    'mon-help-diacritics)
    (define-key naf-map "\C-c\M-hnf"    'mon-help-naf-mode-faces)
    (define-key naf-map "\C-c\M-hfd"    'mon-insert-face-as-displayed)
    (define-key naf-map "\C-c\M-huf"    'mon-help-naf-mode-ulan-flags)
    (define-key naf-map "\C-c\M-hrs"    'mon-help-reference-sheet)
    (define-key naf-map "\C-c\M-hcl"    'mon-help-color-chart)
   ;; M-i__ FOR INSERTRION:
    (define-key naf-map "\C-c\M-inar"   'artist-naf)
    (define-key naf-map "\C-c\M-inau"   'author-naf)
    (define-key naf-map "\C-c\M-inbo"   'book-naf)
    (define-key naf-map "\C-c\M-inbr"   'brand-naf)
    (define-key naf-map "\C-c\M-inpp"   'people-naf)
    (define-key naf-map "\C-c\M-inbz"   'benezit-naf-template)
    (define-key naf-map "\C-c\M-inim"   'item-naf)
    (define-key naf-map "\C-c\M-icd"    'comment-divider) ;!!"\C-c\C-di"
    (define-key naf-map "\C-c\M-ic4"    'comment-divider-to-col-four) ;!!"\C-c\C-dn"
    (define-key naf-map "\C-c\M-icp"    'mon-insert-copyright) ;!! "\C-c\C-cp"
    (define-key naf-map "\C-c\M-idi"    'mon-help-diacritics)
    (define-key naf-map "\C-c\M-idl"    'mon-insert-dbc-link)
    (define-key naf-map "\C-c\M-idc"    'mon-insert-dbc-doc-link)
    (define-key naf-map "\C-c\M-idw"    'mon-line-drop-in-words)
    (define-key naf-map "\C-c\M-inc"    'mon-insert-string-incr)        ;!! "\C-c\C-in"
    (define-key naf-map "\C-c\M-in0"    'mon-insert-numbers-padded) ; M-i n zero
    (define-key naf-map "\C-c\M-inl"    'number-lines-region)
    ;; M-ip_ FOR NON-POSTING-*-SOURCE INSERTION:
    (define-key naf-map "\C-c\M-ipb"    'non-posting-benezit-source)
    (define-key naf-map "\C-c\M-ipe"    'non-posting-ebay-source)
    (define-key naf-map "\C-c\M-ipi"    'non-posting-internet-source)
    (define-key naf-map "\C-c\M-ipp"    'non-posting-philsp-source)
    (define-key naf-map "\C-c\M-ips"    'non-posting-source)
    (define-key naf-map "\C-c\M-ipw"    'non-posting-wiki-source)
    ;; M-is_ 
    (define-key naf-map "\C-c\M-isa"    'mon-accessed-stamp)
    (define-key naf-map "\C-c\M-isb"    'mon-insert-subdirs-in-buffer)
    (define-key naf-map "\C-c\M-isc"    'mon-rectangle-sum-column)
    (define-key naf-map "\C-c\M-isd"    'split-designator) ;!! "\C-x\C-k1"
    (define-key naf-map "\C-c\M-isf"    'mon-insert-string-n-fancy-times)
    (define-key naf-map "\C-c\M-isn"    'mon-insert-string-n-times)
    (define-key naf-map "\C-c\M-ist"    'mon-stamp)
    (define-key naf-map "\C-c\M-isu"    'mon-insert-unicode)
    ;; M-iw_ WRAPPING THE REGION:
    (define-key naf-map "\C-c\M-iwa"    'mon-wrap-all-urls)
    (define-key naf-map "\C-c\M-iw1"    'mon-wrap-one-url)
    (define-key naf-map "\C-c\M-iwc"    'mon-wrap-span)
    (define-key naf-map "\C-c\M-iws"    'mon-wrap-selection)
    (define-key naf-map "\C-c\M-iww"    'mon-wrap-with)
    (define-key naf-map "\C-c\M-iwu"    'mon-wrap-url)
    (define-key naf-map "\C-c\M-iyr"    'mon-insert-regexp-template-yyyy)
    ;; M-l__ DIRED RELATED - LS SWITCHES:
    (define-key naf-map "\C-c\M-lsa"    'mon-dired-srt-alph)      ;ls -la
    (define-key naf-map "\C-c\M-lst"    'mon-dired-srt-chrn)      ;ls -lt
    (define-key naf-map "\C-c\M-lsx"    'mon-dired-srt-type)      ;ls -lX
    (define-key naf-map "\C-c\M-lxa"    'mon-dired-srt-type-alph) ;ls -lXa
    (define-key naf-map "\C-c\M-lxt"    'mon-dired-srt-type-chrn) ;ls -lXt
    ;; M-n__ NAF DIRECTORY RELATED FUNCTIONS:
    (define-key naf-map "\C-c\M-nxa"    'naf-explorer-artist)
    (define-key naf-map "\C-c\M-nxb"    'naf-explorer-brand)
    (define-key naf-map "\C-c\M-ndf"    'mon-insert-file-in-dirs)
    (define-key naf-map "\C-c\M-ndn"    'mon-insert-naf-file-in-dirs)
    (define-key naf-map "\C-c\M-ndi"    'naf-dired-image-dir)
    (define-key naf-map "\C-c\M-nda"    'naf-dired-artist-letter) ;!! "\C-c\C-na"  NOTE: naf-drive-dired-*ARTIST|BRAND
    (define-key naf-map "\C-c\M-ndb"    'naf-dired-brand-letter)  ;!! "\C-c\C-nb"  bound globally b/c cant' set mode
                                                                                       ;binding without naf-mode-hook.Don't
                                                                                       ;remove globals frm mon-key-bindings
    (define-key naf-map "\C-c\M-nwn"    'new-naf)
    ;; M-pr_ FOR LAUNCHING EXTERNAL APPLICATIONS:
    (define-key naf-map "\C-c\M-pra"    'mon-open-abbyy)
    (define-key naf-map "\C-c\M-prc"    'mon-conkeror)
    (define-key naf-map "\C-c\M-prn"    'mon-open-notepad++)
    (define-key naf-map "\C-c\M-prp"    'mon-open-photoshop)
    (define-key naf-map "\C-c\M-prf"    'mon-firefox)
    (define-key naf-map "\C-c\M-prs"    'mon-open-fastone)
    ;; M-pt_ FOR PATH RELATED:
    (define-key naf-map "\C-c\M-pti"    'mon-insert-path)
    (define-key naf-map "\C-c\M-pth"    'mon-copy-file-path)
    ;; M-r__ FOR REPLACING FUNCTIONS:
    (define-key naf-map "\C-c\M-rnm"    'mon-num-to-month)
    (define-key naf-map "\C-c\M-rmw"    'mon-num-to-month-whitespace)
    (define-key naf-map "\C-c\M-rmn"    'mon-month-to-num)
    (define-key naf-map "\C-c\M-ram"    'mon-abr-to-month)
    (define-key naf-map "\C-c\M-rfp"    'mon-defranc-places)
    (define-key naf-map "\C-c\M-rfd"    'mon-defranc-dates)
    (define-key naf-map "\C-c\M-rfb"    'mon-defranc-benezit)
    (define-key naf-map "\C-c\M-rht"    'mon-make-html-table)
    (define-key naf-map "\C-c\M-rit"    'mon-ital-date-to-eng)
    (define-key naf-map "\C-c\M-ron"    'mon-line-string-rotate-namestrings)
    (define-key naf-map "\C-c\M-rol"    'mon-line-strings-to-list)
    (define-key naf-map "\C-c\M-rnr"    'mon-re-number-region)
    (define-key naf-map "\C-c\M-rpl"    'mon-pipe-list)
    (define-key naf-map "\C-c\M-rvw"    'mon-reverse-words)
    (define-key naf-map "\C-c\M-rvr"    'mon-region-reverse)
    (define-key naf-map "\C-c\M-rzr"    'mon-zippify-region)
    ;; M-s__ FOR SEARCHING RELATED:
    (define-key naf-map "\C-c\M-sbn"    'mon-search-bnf)
    (define-key naf-map "\C-c\M-sgg"    'google-define) ;!! "\C-c\C-gg"
    (define-key naf-map "\C-c\M-slc"    'mon-search-loc)
    (define-key naf-map "\C-c\M-sul"    'mon-search-ulan)
    (define-key naf-map "\C-c\M-sun"    'mon-search-ulan-for-name)
    (define-key naf-map "\C-c\M-swk"    'mon-search-wikipedia)
    ;; M-t__ FOR CASE RELATED FUNCTONS: 
    (define-key naf-map "\C-c\M-tcr"    'mon-region-capitalize) ;!! "\C-c\M-r"
    (define-key naf-map "\C-c\M-trc"    'mon-rectangle-capitalize)
    (define-key naf-map "\C-c\M-tdr"    'mon-rectangle-downcase)
    (define-key naf-map "\C-c\M-tur"    'mon-rectangle-upcase)
    ;;M-W__ FOR WORD/LINE COUNT RELATED:
    (define-key naf-map "\C-c\M-wca"    'mon-word-count-analysis)
    (define-key naf-map "\C-c\M-wcl"    'mon-line-count-region)
    (define-key naf-map "\C-c\M-wco"    'mon-count-word-occurences)
    (define-key naf-map "\C-c\M-wcw"    'mon-word-count-region)
    (define-key naf-map "\C-c\M-wcr"    'mon-word-count-chars-region)
    (define-key naf-map "\C-c\M-wml"    'mon-line-length-max)
    (define-key naf-map [C-S-down-mouse-3]  'naf-mode-menu)
    naf-map)
  "Keymap for `naf-mode'. Some keys bound also global in `mon-keybindings'.
Globals are included here in order that `describe-mode' in `*Help*'
buffers can show the global-bindings too as they are still used most by naf-mode.
Typically naf-mode binds \"\C-c\M-##\".")

;;;(unintern 'naf-mode-map)
;;;(unintern 'naf-mode-prefix)

;;; ==============================
(easy-menu-define naf-mode-menu naf-mode-map   "Menu for NAF-mode buffers."
  ;;(defconst - used in one of the emacs libs..
  '("Naf-mode"
    ["New NAF" new-naf :help "Open a new NAF"]
    "---";)
    ("Cleaning"                         ;; M-c__ FOR CLEANING FUNCTIONS:
     ["Clean Bib" mon-cln-bib :help "Clean bibliography related cruft"]
     ["Clean Ulan" mon-cln-ulan :help "Clean Ulan Authority Scrapes"]
     ["Clean Wiki" mon-cln-wiki :help "Clean Wiki Scrapes"]
     ["Clean LOC" mon-cln-loc :help "Clean LOC Authority Scrapes"]
     ["Clean Ebay time" mon-cln-ebay-time-string :help "Clean Ebay time-string"]
     ["Clean HTML" mon-cln-html-tags :help "Clean HTML TAGS"]
     ["Clean IMDB" mon-cln-imdb :help "Clean IMDB Scrapes"]
     ["Clean Philsp" mon-cln-philsp :help "Clean Philsp Scrapes"]
     ["Clean Piped List" mon-cln-piped-list :help "Clean pipes from a piped region."]
     ["Clean Blank Lines" mon-cln-blank-lines :help "Clean blank lines if WSP@BOL or BOL=EOL"]
     ["Clean Dup. Lines" mon-cln-uniq-lines :help "Remove Duplicate Lines"]
     ["Clean WSp region (Thorough)" mon-clnBIG-whitespace :help "Clean whitespace in region TAB-SP BOL & EOL"]
     ["Clean WSp region (Safer)" mon-cln-whitespace :help "Clean whitespace between regions words only"]
     ["Clean SPC and TAB from EOL (curr. line only)" mon-cln-spc-tab-eol :help "Clean SPC and TAB from EOL of current line"]
     ["Clean SPC and TAB from EOL' is region" mon-cln-spc-tab-at-eol-in-region :help "Clean SPC and TAB from EOL in region"]
     ["Clean Trail WSp T->1Sp" mon-kill-whitespace :help "Clean whitespace Tabs to 1 Space - entire buffer"]
     ["Clean Trail WSp T->3Sp " mon-cln-trail-whitespace :help "Clean whitespace Tabs to 3 Spcs - entire buffer"])
    "---"
    ("Insertion"                        ;; M-i__ FOR INSERTION:
     ("Naf Templates"
      ["artist-naf"  artist-naf :help "Insert NAF Artist Skeleton"]
      ["author-naf"  author-naf :help "Insert NAF Author Skeleton"]
      ["book-naf"    book-naf   :help "Insert NAF Book Skeleton"]
      ["brand-naf"   brand-naf  :help "Insert NAF People Skeleton "]
      ["people-naf"  people-naf :help "Insert NAF People Skeleton"]
      ["item-naf"    item-naf   :help "Insert NAF Item Skeleton"]
      ["benezit-naf-template"  benezit-naf-template :help "Insert Benezit Skeleton"] )
     "---"
     "   Source and Stamp   "
      ["mon-accessed-stamp"    mon-accessed-stamp   :help "Insert Accessed Stamp flag"]
      ["mon-stamp"             mon-stamp            :help "Insert Posted flag - \(full stamp\)"]
      ["mon-insert-copyright"  mon-insert-copyright :help "Insert Coypright flag"]
      "   Non-Posting-*-Source    "
      ["non-posting-source"  non-posting-source                  :help "Insert Non Posting Source flag"]
      ["non-posting-benezit-source" non-posting-benezit-source   :help "Insert Non Posting Benezit Source"]
      ["non-posting-ebay-source"  non-posting-ebay-source        :help "Insert Non Posting Ebay Source flag"]
      ["non-posting-internet-source" non-posting-internet-source :help "Insert Non Posting Internet Source flag"]
      ["non-posting-philsp-source" non-posting-philsp-source     :help "Insert Non Posting Philsp Source flag"]
      ["non-posting-wiki-source"  non-posting-wiki-source        :help "Insert Non Posting Source flag"]
      "---"
      "   Insert Delimietrs   "
      ["comment-divider"              comment-divider             :help "Insert comment divider at point"]
      ["comment-divider-to-col-four"  comment-divider-to-col-four :help "Insert comment divider at column 4 (four)"]
      ["split-designator"             split-designator            :help "Insert Split Designator \"---\" "]
      "---"
      "   Insert Numbers   "
      ["Insert number - (with options)"  mon-insert-string-incr    :help "Insert Numbers \(with options\)"]
      ["Insert Padded Numbers"           mon-insert-numbers-padded :help "Insert Padded Numbers"]
      ["number-lines-region"             number-lines-region       :help "Number the lines of region"]
      ["mon-rectangle-sum-column"        mon-rectangle-sum-column  :help "Sum column of rectangle"]
      "---"
      "   Insert Strings   "
      ["mon-line-drop-in-words"  mon-line-drop-in-words :help "Split words in line put each on a new line"]
      ["mon-insert-string-n-times"  mon-insert-string-n-times :help "Simple multi string insert"]
      ["mon-insert-string-n-fancy-times" mon-insert-string-n-fancy-times :help "Fancy multi insert of a string"]
      "---"
      "   Insert Misc   "
      ["mon-apppend-to-register" mon-append-to-register :help "Append region to regiser \(w/ newline\)"]
      ["mon-insert-unicode"  mon-insert-unicode         :help "Insert Unicode character - using radix 16"]
      ["mon-insert-path"  mon-insert-path               :help "Insert file path of buffer in buffer"]
      ["mon-insert-subdirs-in-buffer"  mon-insert-subdirs-in-buffer :help "Insert subdirs buffer\'s file directory"]
      ["mon-insert-regexp-template-yyyy"  mon-insert-regexp-template-yyyy :help "Insert boilerplate YYYY regexp"]
      "---"
      "   Wrapping   "                  ;; M-iw WRAPPING THE REGION:
      ["mon-wrap-all-urls" mon-wrap-all-urls    :help "Wrap all urls with \(URL `*'\)"]
      ["mon-wrap-one-url" mon-wrap-one-url      :help "Wrap one url with \(URL `*'\)"]
      ["mon-wrap-url"  mon-wrap-url             :help "Wrap string \(a url\) at point into a proper href"]
      ["mon-wrap-span"  mon-wrap-span           :help "Wrap region with CSS class span"]
      ["mon-wrap-selection"  mon-wrap-selection :help "Wrap region with chars"]
      ["mon-wrap-with"  mon-wrap-with           :help "Wrap string at point (returns without text-props)"]
      ["mon-insert-dbc-link"  mon-insert-dbc-link :help "Insert href template at point"]
      ["mon-insert-dbc-doc-link"  mon-insert-dbc-doc-link :help "Insert doc-link at point"])
    "---"                               ;; M-r__ FOR REPLACING:
    ("Replacing"
     ("Names Rotate/Replace"
      ["Fname Lname -> Lnane (Fname)"  mon-line-string-rotate-namestrings :help ""]
      ["Lines-of-Names -> List-of-Names" mon-line-strings-to-list :help ""])
     "---"
     ("Date/Number Replace"
      ["Numbers -> Month - mon-num-to-month"  mon-num-to-month :help " "]
      ["Numbers -> Month \(WS\) - mon-num-to-month-whitespace"  mon-num-to-month-whitespace :help " "]
      ["Months -> Numbers - mon-month-to-num"  mon-month-to-num :help " "]
      ["Mon. -> Month - mon-abr-to-month"  mon-abr-to-month :help " "]
      ["mon-re-number-region" mon-re-number-region :help "Sequential renumber numbers in region"])
     "---"
     ("Translating Replace"
      ["mon-defranc-places"    mon-defranc-places   :help "French place names -> Engrish place names"]
      ["mon-defranc-dates"     mon-defranc-dates    :help "French dates -> Engrish dates"]
      ["mon-defranc-benezit"   mon-defranc-benezit  :help "Benezit French => Benezit Engrish"]
      ["mon-ital-date-to-eng"  mon-ital-date-to-eng :help "Italian dates -> Engrish dates"])
     "---"
     ["mon-make-html-table"      mon-make-html-table     :help "Convert Region -> html table"]
     ["mon-pipe-list"            mon-pipe-list           :help "Convert region -> piped list \(Used-fors\)"]
     ["mon-word-reverse-region"  mon-word-reverse-region :help "Reverse words in region"]
     ["mon-region-reverse"       mon-region-reverse      :help "Reverse chars in region"]
     ["mon-zippify-region"       mon-zippify-region      :help "Make region cogent \(oddly\)"])
    "---"                               ;M_n__ DIRECTORY RELATED:
    ("Directory"
      "Explorer Directories"
      ["Explorer Artist - naf-explorer-artist"  naf-explorer-artist :help "Open Artist name directory in naf drive with Explorer"]
      ["Explorer Brand - naf-explorer-brand"    naf-explorer-brand :help "Open Brand directory in naf drive with Explorer"]
      ["Explorer Here - mon-open-explorer"      mon-open-explorer :help "Open explorer in buffers current directory."]
      ["Images Swap - mon-open-images-ed-swap"  mon-open-images-ed-swap :help "Open explorer in MON scan directory(temp)."]
      ["Mozilla Downloads - mon-open-moz-down"  mon-open-moz-down :help "Open explorer in mozilla downloads directory."]
      "---"
      "Current Path - Buffer's File"
      ["Copy Buffer's File Path - mon-copy-file-path"  mon-copy-file-path :help "Copy file's path to kill-ring \(clipboard\)"]
      ["Insert Buffer's File Path - mon-insert-path"   mon-insert-path :help "Insert current file's path at point"]
      "---"
     "Dired NAF Drive"
      ["Artist Directory - naf-dired-artist-letter"  naf-dired-artist-letter :help "dired to Artist directory"]
      ["Brand Directory  - naf-dired-brand-letter"  naf-dired-brand-letter :help "dired to Brand directory"]
      ["Image Directories - naf-dired-image-dir" naf-dired-image-dir :help "dired to Image directory"]
      ["Insert list of dir/files - mon-insert-naf-file-in-dirs" mon-insert-file-in-dirs :help "Insert dirs and file from list"]
      ["Insert NAF list of dir/files - mon-insert-naf-file-in-dirs" mon-insert-naf-file-in-dirs :help "Insert NAF dirs and file from list"]
      "---"
      "Dired Sort Switches"
       ["ls -la  - mon-dired-srt-alph"      mon-dired-srt-alph       :help "Sort Dired Alphabetical"]
       ["ls -lt  - mon-dired-srt-chrn"      mon-dired-srt-chrn       :help "Sort Dired Chronologically"]
       ["ls -lX  - mon-dired-srt-type"      mon-dired-srt-type       :help "Sort Dired by Type"]
       ["ls -lXa - mon-dired-srt-type-alph" mon-dired-srt-type-alph  :help "Sort Dired by Type -> Alphabetical"]
       ["ls -lXt - mon-dired-srt-type-chrn" mon-dired-srt-type-chrn  :help "Sort Dired by Type -> Chronological"])
    "---"                               ;; M-w__ FOR WORD/LINE COUNT RELATED:
    ("Counting"
      ["Count Word Occurs - mon-count-word-occurences"  mon-count-word-occurences :help "Buffer's words sorted by number of occurrences"]
      ["Count Anal - mon-word-count-analysis" mon-word-count-analysis :help "Count word usage in region"]
      ["Count Lines - mon-line-count-region"  mon-line-count-region :help "Count number of lines and characters of region"]
      ["Max Line length- mon-line-length-max"  mon-line-length-max :help "Find maximum line lenght in buffer"]
      ["Count Words - mon-word-count-region"  mon-word-count-region :help "Count number of words in region"]
      ["Count Words/Chars - mon-word-count-chars-region"  mon-word-count-chars-region :help "Number of words/chars in region"])
    "---"                               ;; M-pr_ FOR PROGRAM LAUNCHING:
    ("Launch-Programs"
      ["ABBYY - mon-open-abbyy"          mon-open-abbyy :help " "]
      ["Conkeror - mon-conkeror"         mon-conkeror :help " "]
      ["Fastone - mon-open-fastone"      mon-open-fastone :help " "]
      ["Firefox - mon-firefox"           mon-firefox :help " "]
      ["Notepad++ - mon-open-notepad++"  mon-open-notepad++ :help " "]
      ["Photoshop - mon-open-photoshop"  mon-open-photoshop :help " "])
    "---"                               ;; M-t__ FOR CASE RELATED:
    ("Case and Title"
      ["Capitalize Region - mon-region-capitalize"        mon-region-capitalize :help "Capitalize The Region"]
      ["Capitalize Rectangle - mon-rectangle-capitalize"  mon-rectangle-capitalize :help "Capitalize The Rectangle"]
      ["Downcase Rectangle - mon-rectangle-downcase"      mon-rectangle-downcase :help "downcase The Rectangle"]
      ["Upcase Rectangle - mon-rectangle-upcase"          mon-rectangle-upcase :help "UPCASE the rectangle."])
    "---"                               ;; M-s__ FOR SEARCHING RELATED:
    ("Searching"
     ["Search BNF - mon-search-bnf" mon-search-bnf :help "Search BNF Authorities"]
     ["Search LOC - mon-search-loc"  mon-search-loc :help "Search LOC Authorities"]
     ["Search ULAN - mon-search-ulan"  mon-search-ulan :help "Search ULAN Authorities"]
     ["ULAN Name - mon-search-ulan-for-name"  mon-search-ulan-for-name :help "Search sepecific ULAN authority"]
     ["Search Wiki - mon-search-wikipedia"  mon-search-wikipedia :help "Search Wikipedia"]
     ["Google define words - google-define" google-define :help "Get word definition from Google"])
    "---"                               ;; M-w__ FOR FRAME RELATED:
    ("Frame and Window Adjust"
      ["Flip Windows - mon-flip-windows"  mon-flip-windows :help "Swap buffers"]
      ["Vert. Split Window - mon-twin-vertical"  mon-twin-vertical :help "Split current-buffer vertically"]
      ["Horiz. Split Window - mon-twin-horizontal" mon-twin-horizontal :help "Split current-buffer horizontally"]
      ["Max. Frame - mon-maximize-frame" mon-maximize-frame :help "Maximize Frame"]
      ["Min. Frame - mon-minimize-frame" mon-minimize-frame :help "Minimize Frame"]
      ["Restr Frame - mon-restore-frame" mon-restore-frame :help "Restore Frame"]
      ["Kbd Menu bar -mon-menu-bar" mon-menu-bar :help "Keyboard Access to Menu bar"]
      ["Window Height - doremi-window-height"  doremi-window-height :help "Adjust window heights"]
      ["Window Width - doremi-window-window-width"  doremi-window-window-width :help "Adjust window widths"])
    "---"
    ("Help"
     ["mon-help-naf-mode-faces"      mon-help-naf-mode-faces      :help "Map Faces -> fontlocks vars"]
     ["mon-insert-face-as-displayed" mon-insert-face-as-displayed :help "Insert all naf keywords w/ faces"]
     ["mon-help-diacritics"          mon-help-diacritics          :help "Insert common diacritcs and their keymaps"]
     ["mon-help-naf-mode-ulan-flags" mon-help-naf-mode-ulan-flags :help "Help with ULAN field spec"]
     ["mon-help-color-chart"         mon-help-color-chart         :help "Handy Color Chart"]
     ["mon-help-keys"                mon-help-keys                :help "Emacs key commands"]
     ["mon-help-reference-sheet"     mon-help-reference-sheet     :help "Meta Help for help"]
     )))

;;; ==============================
;;;  TODO: need a hook to (setq sort-fold-case t) when loading a .naf file
;;;  FROM DOCSTRING: Variable is safe as a **file local** variable if its value
;;;  satisfies the predicate `booleanp'.
;;;  Wrapped in unless because this _should_ already be available from "./mon-utils.el"
(unless (fboundp 'new-naf)
(defun new-naf (&optional rnm inter-p)
  "Make a new naf buffer named new-naf switch to buffer with naf-mode on.
Optional arg RNM supplies a different name for the new naf buffer.\n
Used in `naf-mode'."
  (interactive "p\np")
  (let* ((rnm-bp (cond ((and (eq 1 rnm) (eq 1 inter-p))
                        (if (yes-or-no-p "Set a name for this new buffer (defaults to: new-naf)? :")
                            (read-string "New Buffer Name :")
                          "new-naf"))
                       ((eq rnm nil)
                        "new-naf")
                       ((or rnm) rnm))))
    (switch-to-buffer
     (generate-new-buffer-name rnm-bp)))
  (naf-mode))
) ;unless

;; ;;; ==============================
;; (defgroup highlight-symbol 'nil
;;   "Automatic and manual symbols highlighting."
;;   :group 'faces
;;   :group 'matching)

;;; ==============================
(defvar naf-mode-hook nil
  "*Hook called by `naf-mode'.")

;;; ==============================
(define-derived-mode naf-mode fundamental-mode "NAF-mode"
  "A major mode for creating NAFS (Name Authority Files).
\\{naf-mode-map}."
  :group 'naf-mode
  ;; :link
  ;; (set (make-local-variable 'imenu-generic-expression)
  ;;      sample-imenu-generic-expression)
  ;;  (make-local-variable '*naf-mode-buffer-local-llm*)
  ;;
  ;; ==========FONT-LOCKS==========
  (set (make-local-variable 'font-lock-defaults)
        '(naf-font-lock-keywords))
  (set (make-local-variable 'font-lock-keywords)
       '(naf-font-lock-keywords))
  (message "Loading Naf Mode."))

  ;; ==============================
  ;; NOTE:
  ;;(set (make-local-variable 'font-lock-keywords)
  ;;       '(naf-font-lock-keywords))
  ;;
  ;;  (set (make-local-variable 'font-lock-keywords)
  ;;   naf-font-lock-keywords)
  ;;;;;;;;;;;;
  ;; Testing this: borrowed-from: spartan-wiki.el
  ;; (set (make-local-variable 'font-lock-extra-managed-props)
  ;;      some-property-list)
  ;;
  ;; (setq font-lock-extra-managed-props 'naf-mode-face-props)
  ;; ==============================
  ;; Is following needed?:
  ;; (run-hooks 'naf-mode-hook)
  ;; Docs say `derived-mode' automatically builds a `run-mode-hooks' initiates
  ;; the mode variables with this ''mode-hook''. But, the hooks docs say don't
  ;; `run-hooks' on a var set buffer-local for a mode w/ `make-local-variable'.
  ;; WTF!
  ;; ==============================

;;; ==============================
(add-hook 'naf-mode-hook (function (lambda () (longlines-mode 1))))
(add-hook 'naf-mode-hook (function (lambda () (setq local-abbrev-table naf-mode-abbrev-table))))

;;(add-hook 'naf-mode-hook (function (lambda () ;))))
;;;(add-hook hook function &optional append local)
;;
;;;(unintern 'naf-mode-hook)

;;; ==============================
;;; Following form may not be needed according to the (set (MLV 'somevar) '(idiom))
;;; in the define-derived-mode above.
;;; COMMENTED-OUT: <Timestamp: #{2009-08-15T20:54:36-04:00Z}#{09337} - by MON KEY>
;;; (font-lock-add-keywords 'naf-mode naf-font-lock-keywords)

;;; ==============================
(provide 'naf-mode)
;;; ==============================

;;; ================================================================
;;; naf-mode.el ends here
;;; EOF
