;;; pgo-compression.el --- Setup Compression Interfaces.
;;
;; Filename: pgo-compression.el
;; Description:
;; Author: Per Nordlöw
;; Maintainer:
;; Created: lör jul  4 22:08:57 2009 (+0200)
;; Version:
;; Last-Updated: fre dec 18 21:16:57 2009 (+0100)
;;     Update #: 10
;; URL:
;; Keywords:
;; Compatibility:
;;
;; Features that might be required by this library:
;;
;;   `jka-cmpr-hook', `jka-compr'.
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

(when (require 'jka-compr nil t)      ;Handle compressed files transparently
  (auto-compression-mode 1)

  ;; Automatic (un)compression on loading/saving files (gzip(1) and similar)
  ;; We start it in the off state, so that bzip2(1) support can be added.
  ;; Code thrown together by Ulrik Dickow for ~/.emacs with Emacs 19.34.
  ;; Should work with many older and newer Emacsen too.  No warranty though.

  (when nil
    (setq jka-compr-compression-info-list
          '(["\\.Z\\(~\\|\\.~[0-9]+~\\)?\\'"
             "compressing"    "compress"     ("-c")
             "uncompressing"  "uncompress"   ("-c")
             nil t]
            ["\\.tgz\\'"
             "zipping"        "gzip"         ("-c" "-q")
             "unzipping"      "gzip"         ("-c" "-q" "-d")
             t nil]
            ["\\.gz\\(~\\|\\.~[0-9]+~\\)?\\'"
             "zipping"        "gzip"         ("-c" "-q")
             "unzipping"      "gzip"         ("-c" "-q" "-d")
             t t]
            ["\\.bz2\\(~\\|\\.~[0-9]+~\\)?\\'"
             "bzipping"      "bzip2"        ()
             "bunzipping"    "bzip2"        ("-d")
             nil t]))

    ;; See: http://groups.google.com/group/gnu.emacs.help/browse_thread/thread/56c63f6f8ea9d9f1#
    '(jka-compr-compression-info-list
      (quote
       (["\\.Z\\(~\\|\\.~[0-9]+~\\)?\\'"
         "compressing" "compress" ("-c")
         "uncompressing" "gzip" ("-c" "-q" "-d")
         nil t " \x9d"]

        ["\\.bz2\\(~\\|\\.~[0-9]+~\\)?\\'"
         "bzip2ing"  "bzip2" nil
         "bunzip2ing" "bzip2" ("-d")
         nil t "BZh"]

        ["\\.tbz\\(\\|2\\)\\'"
         "bzip2ing" "bzip2" nil
         "bunzip2ing" "bzip2" ("-d")
         nil nil "BZh"]

        ["\\.\\(?:tgz\\|svgz\\)\\'"
         "compressing" "gzip" ("-c" "-q")
         "uncompressing" "gzip" ("-c" "-q" "-d")
         t nil " \x8b"]

        ["\\.g?z\\(~\\|\\.~[0-9]+~\\)?\\'"
         "compressing" "gzip" ("-c" "-q")
         "uncompressing" "gzip" ("-c" "-q" "-d")
         t t " \x8b"]

        ["\\.dz\\'" nil nil nil
         "uncompressing" "gzip" ("-c" "-q" "-d")
         nil t " \x8b"]
        )))
    )
  )

(provide 'pgo-compression)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; pgo-compression.el ends here
