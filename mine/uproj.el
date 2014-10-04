;;; uproj.el --- Unified Interface to Project Target Building, Debugging, Running and Installing.
;; Author: Per Nordlöw

;;; TODO: Do something with -fsignaling-nans.

;;; TODO: -march=native for GCC/Clang Builds
;;; TODO: Auto generate doc if "-D" is part of dmd flags and open it automatically with browse-url.

;;; TODO: Support ~/alt/bin/clang -x c++ -I~/alt/include/c++/v1 -L~/alt/lib64 -L~/alt/lib -std=gnu++0x -g -Wall t_poly.cpp -lm -lc++ -lstdc++ -lpthread -larmadillo -o t_poly.out

;; TODO: Suport Clang Fixits: http://clang.llvm.org/diagnostics.html

;; TODO: Temporary modify CC, CXX etc using "CC=gcc make TARGET" or "export
;; CC=gcc; make TARGET" or (setenv "CC" "gcc") instead of current and test on
;; hispui and hispui.exe targets in "~/FOI/HISP".

;; TODO: Support ccache and distcc
;; (y-or-n-p "Distribute Build (using distcc)?")
;; (y-or-n-p "Use Compiler Cache (ccache)?")
;;  apt-get install ccache distcc pump distcc-pump distccmon-gnome
;; https://code.google.com/p/distcc/
;; Requires changing compiler to a list ("gcc" 'distributed 'cached)
(when nil
  (setenv "CACHE_PREFIX" "distcc")   ;export CCACHE_PREFIX=distcc
  (setenv "CACHE_COMPRESS" "always")  ;export CCACHE_COMPRESS=alwaysx
  ;; export DISTCC_HOSTS='--randomize localhost red,cpp,lzo green,cpp,lzo blue,cpp,lzo'
  )

;; 1 On each of the servers, run distccd --daemon, with --allow options to restrict access.
;; Put the names of the servers in your environment: export DISTCC_POTENTIAL_HOSTS='localhost red green blue'
;; Build: pump make -j8 CC=distcc

;; TODO: Merge with auto-build.el.
;; TODO: Use GHC's `-fforce-recomp' for now and optionally activate `-fglasgow-exts'.
;;
;; TODO: GH 7.4.1: The recompilation checker now takes into account what flags
;; were used when compiling. For example, if you first run ghc -c Foo.hs, and
;; then ghc -DBAR -c Foo.hs, then GHC will now recompile Foo.hs.
;;
;; TODO: Ask Each GCC Version for Compiler Flags upon loading of uproj.el using the flag
;; --help=X where X can be either
;; - optimizers
;; This will display all of the optimization options supported by the compiler.
;; - warnings
;; This will display all of the options controlling warning messages produced by the compiler.
;; - target
;; This will display target-specific options.  Unlike the --target-help option however, target-specific options of the linker and
;; assembler will not be displayed.  This is because those tools do not currently support the extended --help= syntax.
;; - params
;; This will display the values recognized by the --param option.
;; - language
;; This will display the options supported for language, where language is the name of one of the languages supported in this version of
;; GCC.
;; - common
;; This will display the options that are common to all languages.
;; These are the supported qualifiers:
;; - undocumented
;; Display only those options which are undocumented.
;; - joined
;; Display options which take an argument that appears after an equal sign in the same continuous piece of text, such as: --help=target.
;; - separate
;; Display options which take an argument that appears as a separate word following the original option, such as: -o output-file.

(require 'desktop)
(require 'power-utils)
(require 'elisp-utils)
(require 'file-utils)
(require 'makefile-utils)
(require 'scons-utils)
(require 'multi-dir)
(require 'gcc-options)
(require 'auto-deb)
(require 'file-dwim)
(require 'icicles nil t)
(require 'elk-test nil t)
(require 'memoize)
(require 'faze)
(require 'compiler-version)

;; Note: Compile with lowest nicenessrity using given number of jobs.
;; Note: Add flag "-k" if we should continue with next file if error
;; occurs.
(defcustom compilation-niceness 10
  "Nicenessrity of build process. From -20 (highest nicenessrity) to
  19 (lowest nicenessrity.). TODO: Should we pick a higher nicenessrity?"
  :group 'compilation)
(defcustom compilation-jobs-count (round (1+ cpus-online-count)) ;either *1.5 or +1
  "Number of jobs (commands) builds should run simultaneously.
1.5 factor is to prevent hard disk access from being limiting factor."
  :group 'compilation)

(defcustom compilation-compilers-spec
  `((c :compilers ("gcc"
                   "clang"
                   "icc"                ;Intel C/C++ Compiler
                   "winegcc")           ;APT: wine1.3-dev
       )

    (c++ :compilers ("gcc"
                     "clang"
                     "icc"                ;Intel C/C++ Compiler
                     "wineg++")           ;APT: wine1.3-dev
         )

    (objective-c :compilers ("gcc"
                             "clang")
                 )

    (fortran :compilers ("f95"
                         )
             )

    (d :compilers (
                   "dmd"               ;Official
                   "gdc"               ;GCC Frontend
                   "gdmd"              ;Wrapper script for GDC that emulates DMD
                   "ldc"                ;LLVM Frontend
                   "ldc2"               ;LLVM Frontend
                   "ldmd2"              ;LLVM Frontend with DMD-like interface
                   )
       )

    (java :compilers (
                   "gcj"               ;GCC Frontend
       ))

    (haskell :compilers ("ghc"
                         "hugs")
             )
    )
  "Association List Mapping Programming Languages to Compilers
and their Supported Standards."
  :group 'compilation)

;; C Standards
(defcustom c-std-types `("ansi" "c89" "c90" "iso9899:1990"
                         "c99" "c9x" "iso9899:1999" "iso9899:199x")
  "C Language Standards."
  :group 'compilation)
(defcustom gcc-c-std-types (append c-std-types `("gnu89" "gnu90"
                                                 "gnu99" "gnu9x"
                                                 "gnu1x"))
  "GCC C Language Standards."
  :group 'compilation)
(defcustom clang-c-std-types (append c-std-types `("c11" "gnu11") ;Clang 3.1
                                     )
  "Clang C Language Standards."
  :group 'compilation)
(defcustom icc-c-std-types (append c-std-types)
  "ICCC Language Standards."
  :group 'compilation)

;; C++ Standards
(defconst c++-std-types `("c++98"
                           "c++03"
                           "c++0x"
                           "c++11")
  "C++ Language Standards.")
(defcustom gcc-c++-std-types (append c++-std-types `("c++98"
                                                     "c++03"
                                                     "c++11"
                                                     "c++1y" ;The next revision of the ISO C++ standard, tentatively planned for 2017.
                                                     "c++0x-compat" ;GCC 4.7
                                                     "c++11-compat" ;GCC 4.7
                                                     "gnu++98"
                                                     "gnu++03"
                                                     "gnu++0x"
                                                     "gnu++11"
                                                     "gnu++1y" ;GNU dialect of -std=c++1y
                                                     ))
  "GCC C++ Language Standards."
  :group 'compilation)
(defcustom clang-c++-std-types (append c++-std-types `("c++11"
                                                       "c++0x-compat" ;GCC 4.7
                                                       "c++11-compat" ;GCC 4.7
                                                       "gnu++98"
                                                       "gnu++0x"
                                                       "gnu++11"))
  "Clang C++ Language Standards. See
http://stackoverflow.com/questions/13525774/clang-and-float128-bug-error"
  :group 'compilation)

;; D Standards
(defcustom d-std-types `("D-1.0" "D-2.0") "D Language Standards: http://en.wikipedia.org/wiki/D_programming_language" :group 'compilation)
(defcustom gdc-std-types `("D-1.0" "D-2.0") "D Language Standards: http://en.wikipedia.org/wiki/D_programming_language" :group 'compilation)
(defcustom gdmd-std-types `("D-1.0" "D-2.0") "D Language Standards: http://en.wikipedia.org/wiki/D_programming_language" :group 'compilation)

(defconst gdc-warn-types `(("All" ("-Wall")))
  "GDC Warn Types. First element becomes default.")
(defconst dmd-warn-types `(("Warnings-As-Message" ("-wi"))
                           ("Warnings-GC-As-Message" ("-wi" "-vgc"))
                           ("Warnings-As-Errors" ("-w")))
  "DMD Warn Types. First element becomes default.")

;; Haskell Standards
(defcustom haskell-std-types `("Haskell-1.0"
                               "Haskell-98"
                               "Haskell-Prime"
                               "Haskell-2010")
  "Haskell Language Standards:
  http://en.wikipedia.org/wiki/Haskell_(programming_language)"
  :group 'compilation)

(defcustom ada-std-types `("gnat83"     ;Ada 83
                           "gnat95"     ;Ada 05
                           "gnat05"     ;Ada 2005
                           "gnat12"     ;Ada 2012
                           "gnatX"      ;Latest
                           )
  "Haskell Language Standards:
http://gcc.gnu.org/onlinedocs/gnat_ugn_unw/Compiling-Different-Versions-of-Ada.html#Compiling-Different-Versions-of-Ada"
  :group 'compilation)

(defconst gnat-warn-types `(("Warn-Unused" ("-gnatwu"))) "GNAT Warn Types.")

(defcustom c-default-std-type "c99" "Default C Language Standard." :group 'compilation)
(defcustom gcc-c-default-std-type "gnu99" "Default GCC C Language Standard." :group 'compilation)

(defcustom c++-default-std-type "c++0x" "Default C++ Language Standard." :group 'compilation)
(defcustom gcc-c++-default-std-type "gnu++1y" "Default GCC C++ Language Standard." :group 'compilation)

(defcustom haskell-default-std-type "Haskell-2010" "Default Haskell Language Standard." :group 'compilation)

(defvar c++-std-libraries '(("GNU's" "stdc++") ;GNU's C++ Standard Library
                            ("LLVM's libc++ (libcxx)" "c++") ;LLVM's libc++ or libcxx. TODO: Check that it exists somewhere in
                            )
  "C++ Standard Library Implementations.")

;; ---------------------------------------------------------------------------

(defconst c-standard-build-options
  '("Unspecified" "Standard" "Default")
  "Standard Build Option Names.")

(defun gdb-version ()
  (replace-regexp-in-string
   (rx (: (* anything)
          "(GDB) "
          (group (+ (or digit ".")))
          (* anything)))
   "\\1"
   (shell-command-to-string-memoized "gdb --version")))
;; Use: (gdb-version)

(defun gdb-dwarf-version (&optional version)
  "Return DWARF version supported by GDB of version VERSION.
VERSION default to version of gdb"
  (if (version>= (or version
                    (gdb-version)) "7.5")
      "4"
    "2"))
(eval-when-compile (assert-equal "4" (gdb-dwarf-version "7.5")))
(eval-when-compile (assert-equal "2" (gdb-dwarf-version "7.4")))

;;; Build Flags
(defconst clang-default-build-flags '("-D__STRICT_ANSI__") "Default C++ Build flags specific to Clang.")
(defconst c-debug-build-flags '("-DDEBUG" "-DDEBUG_CHECK_ALL") "Debug Build flags common to GCC and Clang.")
(defconst c-gcc-debug-build-flags
  (append c-debug-build-flags '("-g3" "-ggdb3")) ;-ggdb is usable only by gdb, while -g produces whatever the native system uses.
  "Debug Build flags specific to GCC.")
(defconst c-clang-debug-build-flags
  (append clang-default-build-flags
          c-debug-build-flags
          '("-g3" "-ggdb3")) ;-ggdb is usable only by gdb, while -g produces whatever the native system uses.
  "Debug Build flags specific to Clang.")
(defconst c-release-build-flags '("-DNDEBUG" "-O6") "Release Build flags common to GCC and Clang.")
(defconst c-gcc-parallel-build-flags '("-D_GLIBCXX_PARALLEL" "-fopenmp" "-march=native") "Parallel Build Flags specific to GCC (using OpenMP).")

;;; Debug Link Flags
(defconst c-debug-link-flags nil "Debug Link flags common to GCC and Clang.")
(defconst c-gcc-debug-link-flags c-debug-link-flags "Debug Link flags specific to GCC.")
(defconst c-clang-debug-link-flags c-debug-link-flags "Debug Link flags specific to Clang.")

;; See: http://llvm.org/devmtg/2012-11/Serebryany-ASAN-TSAN-Poster.pdf
(defconst asan-doc "Buffer overflow in heap, stack and globals. Heap-use-after-free. Stack-use-after-return (sometimes). CPU:2x; RAM:2x-4x")
(defconst tsan-doc "Data races. CPU:4x-8x; RAM:5x")
(defconst msan-doc "Uses of uninitialized memory. CPU:3x; RAM:3x")

(defconst gcc-build-types
  `(
    ("Debug-Harmony"                          ;See http://gcc.gnu.org/gcc-4.8/changes.html
     ,(append c-gcc-debug-build-flags '("-Og"))
     ,c-gcc-debug-link-flags
     "4.8")

    ("Debug"
     ,c-gcc-debug-build-flags
     ,c-gcc-debug-link-flags)

    ("Debug-Signaling-NaNs"
     ,(append c-gcc-debug-build-flags '("-fsignaling-nans"))
     ,c-gcc-debug-link-flags)

    ("Parallel-Debug"
     ,(append c-gcc-debug-build-flags
              c-gcc-parallel-build-flags)
     ,c-gcc-debug-link-flags)
    ;; Debug and AddressSanitize: http://gcc.gnu.org/gcc-4.8/changes.html
    ;; TODO: Restrict to GCC Version 4.8
    ("AddressSanitized-Debug"
     ,(append c-gcc-debug-build-flags '("-fsanitize=address"
                                        "-fno-omit-frame-pointer"))
     ,c-gcc-debug-link-flags
     "4.8")
    ;; ("MemorySanitized-Debug"
    ;;  ,(append c-gcc-debug-build-flags '("-fsanitize=memory"
    ;;                                     "-fno-omit-frame-pointer"))
    ;;  ,c-gcc-debug-link-flags
    ;;  "4.8")
    ("ThreadSanitized-Debug" ;Instructions will be instrumented to detect data races.
     ,(append c-gcc-debug-build-flags '("-fsanitize=thread"
                                        "-fno-omit-frame-pointer"))
     ,c-gcc-debug-link-flags
     "4.8")
    ("UndefinedSanitized-Debug"
     ,(append c-gcc-debug-build-flags '("-fsanitize=undefined"
                                        "-fno-omit-frame-pointer"))
     ,c-gcc-debug-link-flags
     "4.9")
    ("Address-and-ThreadSanitized-Debug"            ;Instructions will be instrumented to detect data races.
     ,(append c-gcc-debug-build-flags '("-fsanitize=address"
                                        "-fsanitize=thread"
                                        "-fno-omit-frame-pointer"))
     ,c-gcc-debug-link-flags
     "4.8")

    ("Profile"
     ,(append c-gcc-debug-build-flags '("-pg"))
     ,c-gcc-debug-link-flags)
    ("Harmony-Profile"
     ,(append c-gcc-debug-build-flags '("-Og -pg"))
     ,c-gcc-debug-link-flags
     "4.8")
    ("Small-Profile"
     ,(append c-gcc-debug-build-flags '("-Os -pg"))
     ,c-gcc-debug-link-flags)
    ("Fast-Profile"
     ,(append c-gcc-debug-build-flags '("-O3 -pg"))
     ,c-gcc-debug-link-flags)

    ("GPerfTools-Profile"
     ,(append c-gcc-debug-build-flags)
     ,(append c-gcc-debug-link-flags '("-ltcmalloc" "-lprofiler")))
    ("Parallel-Profile"
     ,(append c-gcc-parallel-build-flags '("-pg")) ;using gprof
     ,c-gcc-debug-link-flags)
    ;; Profile Mode: See: http://gcc.gnu.org/onlinedocs/libstdc++/manual/profile_mode.html
    ;; TODO: Open libstdcxx-profile.txt upon exit.
    ("Profile-C++-STL"
     ,(append c-gcc-parallel-build-flags '("-pg" "-D_GLIBCXX_PROFILE"))
     ,c-gcc-debug-link-flags)
    ("Parallel-Profile-C++-STL"
     ,(append c-gcc-parallel-build-flags '("-pg" "-D_GLIBCXX_PROFILE"))
     ,c-gcc-debug-link-flags)

    ("Coverage"
     ,(append c-gcc-debug-build-flags '("-ftest-coverage" "-fprofile-arcs")) ;using gcov
     ,c-gcc-debug-link-flags)

    ("Small"
     ,(append c-release-build-flags '("-Os")))
    ("Small-Debug"
     ,(append c-gcc-debug-build-flags '("-Os")))

    ("Fast"
     ,(append c-release-build-flags '("-O3" "-funroll-loops" "-fomit-frame-pointer" "-ftree-vectorize")))
    ("Fast-Debug"
     ,(append c-gcc-debug-build-flags '("-funroll-loops" "-fomit-frame-pointer" "-ftree-vectorize"))
     ,c-gcc-debug-link-flags)

    ("Release"
     ,(append c-release-build-flags '("-funroll-loops" "-ftree-vectorize" "-floop-interchange" "-floop-block" "-flto" "-ftree-partial-pre")))
    ("Release-Verbose"
     ,(append c-release-build-flags '("-funroll-loops" "-ftree-vectorize" "-ftree-vectorizer-verbose=5" "-floop-interchange" "-floop-block" "-flto" "-ftree-partial-pre")))
    ("Release-Debug"
     ,(append c-gcc-debug-build-flags '("-funroll-loops" "-ftree-vectorize" "-floop-interchange" "-floop-block" "-flto")))
    ("Parallel-Release"
     ,(append c-release-build-flags '("-D_GLIBCXX_PARALLEL" "-fopenmp" "-march=native" "-funroll-loops" "-ftree-vectorize" "-floop-interchange" "-floop-block" "-flto" "-ftree-partial-pre")))
    ("Parallel-Release-Verbose"
     ,(append c-release-build-flags '("-D_GLIBCXX_PARALLEL" "-fopenmp" "-march=native" "-funroll-loops" "-ftree-vectorize" "-ftree-vectorizer-verbose=5" "-floop-interchange" "-floop-block" "-flto" "-ftree-partial-pre")))
    ("Parallel-Release-Debug"
     ,(append c-release-build-flags c-gcc-debug-build-flags '("-D_GLIBCXX_PARALLEL" "-fopenmp" "-march=native" "-funroll-loops" "-ftree-vectorize" "-floop-interchange" "-floop-block" "-flto" "-ftree-partial-pre")))
    )
  "GCC Build Types.")
;; Use: (assoc "Debug" gcc-build-types)
;; Use: (assoc "AddressSanitized-Debug" gcc-build-types)

;; ---------------------------------------------------------------------------
;;; Warning Types

;;; GCC and Clang
(defconst gcc-and-clang-common-default-warnings
  '("-Wall"
    "-Wchar-subscripts"
    "-Wpointer-arith"
    "-Wcast-align"
    "-Wsign-compare"
    "-Wmissing-braces"
    "-Wwrite-strings"
    "-Winit-self")
  "GCC and Clang Default Warnings.")

;;; GCC
(defconst gcc-default-warnings
  '("-Wall" "-Wshadow" "-Wchar-subscripts" "-Wpointer-arith" "-Wcast-align" "-Wsign-compare" "-Wmissing-braces" "-Wwrite-strings" "-Winit-self" "-Wunused-but-set-parameter" "-Wunused-but-set-variable" "-Wempty-body" "-Warray-bounds"))
(defconst gcc-warn-types
  `(("All" ,gcc-default-warnings)
    ("All-and-Unused" ,(append gcc-default-warnings
                               '("-Wunused-but-set-parameter" "-Wunused-but-set-variable")))
    ("All-Extra" ("-Wall" "-Wextra"))
    ("All-and-Old-Style-Cast" ("-Wall" "-Wextra" "-Wold-style-cast"))
    ("All-and-Conversion" ("-Wall" "-Wextra" "-Wconversion"))
    ("All-and-Conversion-no-Sign" ("-Wall" "-Wextra" "-Wconversion" "-Wno-sign-conversion"))
    )
  "GCC Warn Types. First element becomes default.")

;;; Clang
(defconst clang-specific-default-warnings
  '("-Wdangling-else"                   ;Version 3.1
    "-Wstrncat-size"                    ;Version 3.1
    "-Wsometimes-uninitialized"         ;Version 3.2
    "-Wdocumentation" ;Version 3.2: See http://www.phoronix.com/scan.php?page=news_item&px=MTIzMTE
    "-Wheader-hygiene"
    ;; "-Wheader-guard"
    )
  "Clang Specific Default Warnings.")
(defconst clang-default-warnings
  (append gcc-and-clang-common-default-warnings
          clang-specific-default-warnings)
  "Clang Default Warnings.")
(defconst clang-warn-types
  `(("All" ,clang-default-warnings)
    ("All-Extra" ("-Wall -Wextra -Wmaybe-uninitialized"))
    )
  "Clang Warn Types. First element becomes default.")

;; ---------------------------------------------------------------------------
;;; Build Types

(defconst clang-build-types
  `(
    ;; Debug
    ("Debug" ,c-clang-debug-build-flags)

    ("AddressSanitized-Debug"           ;ASan
     ,(append c-clang-debug-build-flags '("-fsanitize=address" "-fno-omit-frame-pointer"))
     ,c-gcc-debug-link-flags
     "3.1")
    ("ThreadSanitized-Debug"            ;TSan
     ,(append c-clang-debug-build-flags '("-fsanitize=thread" "-fno-omit-frame-pointer" "-fPIE" "-pie"))
     ,c-gcc-debug-link-flags
     "3.2")
    ("MemorySanitized-Debug"            ;MSan
     ,(append c-clang-debug-build-flags '("-fsanitize=memory" "-fno-omit-frame-pointer" "-fPIE" "-pie"))
     ,c-gcc-debug-link-flags
     "3.3")
    ("Address-and-ThreadSanitized-Debug" ;ASan-TSan
     ,(append c-clang-debug-build-flags '("-fsanitize=address" "-fsanitize=thread" "-fno-omit-frame-pointer"))
     ,c-gcc-debug-link-flags
     "3.1")

    ;; Clang Debug SAFECode. See: http://sva.cs.illinois.edu/docs/UsersGuide.html
    ("Debug-SAFECode"
     ,(append c-clang-debug-build-flags
              '("-fmemsafety"))
     ,(append c-clang-debug-link-flags
              '("-lsc_dbg_rt" "-lpoolalloc_bitmap")))

    ("GPerfTools-Profile"
     ,(append c-clang-debug-build-flags)
     ,(append c-clang-debug-link-flags '("-ltcmalloc" "-lprofiler")))

    ("Small" ,(append clang-default-build-flags '("-Os")))
    ("Small-Debug" ,(append c-clang-debug-build-flags '("-Os")))

    ("Fast" ,(append clang-default-build-flags '("-O3" "-DNDEBUG")))
    ("Fast-Debug" ,(append c-clang-debug-build-flags '("-O3")))
    ("Fast-Vectorized" ,(append clang-default-build-flags '("-O3" "-DNDEBUG")))

    ("Release" ,(append clang-default-build-flags
                        '("-O4")))

    ("Release-Debug" ,(append c-clang-debug-build-flags
                              '("-O4" "-DNDEBUG")))
    )
  "CLang Build Types.")
;; Use: (assoc "Debug" clang-build-types)
;; Use: (third (assoc "Debug-SAFECode" clang-build-types))

(defconst c-default-build-type "Debug" "Default Build Type, mainly for Compiled Languages such as C, C++.")

;;; GDC
(defconst gdc-build-types
  `(("Debug" ())
    ("Debug-Bounds-Check" ("-fbounds-check"))
    ("Debug-Unittest" ("-funittest"))
    ("Debug-Boundscheck-Unittest" ("-fbounds-check" "-funittest"))
    ("Release" ("-fno-bounds-check" "-frename-registers" "-frelease" "-O3"))
    ("Release-Unittest" ("-funittest" "-frelease"))
    )
  "GDC Build Types.")
(defconst gdc-default-build-type (caar gdc-build-types) "GDC Default Build Type.")

;;; DMD
(defconst dmd-documentation-flag nil "Flags that we should generate documentation using DMD.")
(defconst dmd-build-types
  `(("Debug-Unittest"
     ("-debug" "-g" "-gs" "-unittest"))
    ("Debug-Unittest-Verbose"
     ("-debug" "-g" "-gs" "-unittest" "-v"))
    ("Debug-Boundscheck-Unittest"
     ("-debug" "-g" "-gs" "-unittest")) ;-gc
    ("Debug-Boundscheck-Unittest-Verbose"
     ("-debug" "-g" "-gs" "-unittest" "-v")) ;-gc
    ("Debug"
     ("-debug" "-g" "-gs")) ;-gc
    ("Debug-ListGCAllocations"
     ("-debug" "-g" "-gs" "-vgc"))      ;DMD version >= 2.066
    ("Debug-Unittest-ListGCAllocations"
     ("-debug" "-g" "-gs" "-vgc" "-unittest"))      ;DMD version >= 2.066
    ("Debug-Unittest-ListGCAllocations-Verbose"
     ("-debug" "-g" "-gs" "-vgc" "-unittest" "-v"))      ;DMD version >= 2.066
    ("Debug-Show-Thread-Locals"
     ("-vtls" "-debug" "-g" "-gs")) ;-gc
    ("Debug-Bounds-Check"
     ("-debug" "-g" "-gs"));-gc
    ("Unittest"
     ("-unittest"))
    ("Profile"
     ("-profile"))
    ("Debug-Profile"
     ("-debug" "-g" "-gs" "-profile"))       ;-gc
    ("Release-Profile"
     ("-release" "-O" "-inline" "-w" "-wi"))
    ("Release"
     ("-release" "-O" "-inline" "-w" "-wi")) ;Do we need "-m64"?
    ("Release-NoBoundscheck"
     ("-release" "-O" "-inline" "-boundscheck=off" "-w" "-wi")) ;Do we need "-m64"?
    ("Release-Without-BoundscheckSafeOnly"
     ("-release" "-O" "-inline" "-boundscheck=safeonly" "-w" "-wi")) ;Do we need "-m64"?
    ("Debug-Release"
     ("-debug" "-release" "-O" "-inline" "-w" "-wi")) ;Do we need "-m64"?
    ("Release-Unittest"
     ("-release" "-O" "-inline" "-w" "-wi" "-unittest"))
    ("Release-NoBoundscheck-Unittest"
     ("-release" "-O" "-inline" "-boundscheck=off" "-w" "-wi" "-unittest"))
    )
  "DMD Build Types.")
(defconst dmd-default-build-type
  (caar dmd-build-types)
  "DMD Default Build Type.")

;;; GHC
(defconst ghc-build-types
  `(("Debug" ("-debug"))
    ("Profile" ("-prof"))
    ("Ticky-Ticky-Profile" ("-prof" "-ticky"))
    ("Release" ("-O2"))
    ("Release-Debug" ("-O2" "-debug"))
    ("Release-DPH" ("-O2" "-Odph"))            ;Data means Parallel Haskell
    ("Release-Profile-DPH" ("-O2" "-Odph" "-prof")) ;DPH means Data Parallel Haskell
    ("Threaded-Debug" ("-threaded" "-debug")) ;TODO: Needed?
    ("Threaded-Ticky-Ticky-Profile" ("-threaded" "-prof" "-ticky"))
    ("Threaded-Release" ("-threaded" "-O2"))
    ("Threaded-Release-Profile" ("-threaded" "-O2" "-prof"))
    ("Threaded-Release-Debug" ("-threaded" "-O2" "-debug"))
    ("Threaded-Release-DPH" ("-threaded" "-O2" "-Odph")) ;Data means Parallel Haskell
    ("Threaded-Release-DPH-Profile" ("-threaded" "-O2" "-Odph" "-prof")) ;DPH means Data Parallel Haskell
    ("Load-and-Run" ())                  ;Load via :load "~/bin/hello.hs" and run via :main in ghci
    )
  "Glasgow Haskell Compiler (GHC) Build Types.")
(defconst ghc-default-build-type
  (caar ghc-build-types)
  "GHC Default Build Type.")
(defconst ghc-code-generators
  `(("Native" ("-fasm"))
    ("C-Small" ("-fvia-C" "-optc-Os"))
    ("C-Fast" ("-fvia-C" "-optc-O3"))
    ("Byte-code" ("-fbyte-code"))
    ("Object-code" ("-fobject-code"))
    ("LLVM" ("-fllvm"))
    )
  "Glasgow Haskell Compiler (GHC) Code Generator (Backends). See:
  http://donsbot.wordpress.com/2010/02/21/smoking-fast-haskell-code-using-ghcs-new-llvm-codegen/")
(defconst ghc-warn-types
  `(("All" ("-Wall")
     ))
  "GHC Warn Types. First element becomes default.")
(defconst gccgo-build-types
  `(("Debug" ("-g"))
    ("Profile" (""))
    ("Release" ("-O"))
    )
  "GCC Go Compiler Build Types.")

;; ---------------------------------------------------------------------------

(defun compiler-executable-find (name &optional full)
  "Return List of Compiler Path of NAME."
  (let ((filename (executable-find name))) ;TODO: Use `executable-find-auto-install-on-demand'.
    (when filename
      (if full filename (file-name-sans-directory filename)))))

(defun compilation-get-compilers (&optional lang online)
  "Return List of Compilers for LANG Installed."
  (delq nil (mapcar (if online 'compiler-executable-find 'identity)
                    (plist-get (cdr (assq (intern-soft lang)
                                          compilation-compilers-spec))
                               :compilers))))
;; Use: (compilation-get-compilers "c")
;; Use: (compilation-get-compilers "d")
;; Use: (compilation-get-compilers "d" t)
;; Use: (compilation-get-compilers)

(defun compilation-default-build-compiler (&optional lang)
  "Get Default Build Compiler of language LANG."
  (car (compilation-get-compilers lang)))
;; Use: (compilation-default-build-compiler "c")
;; Use: (compilation-default-build-compiler "d")

(defun compilation-read-compiler-rx-prefixes (&optional lang)
  "Read Compiler `rx' Prefix of language LANG."
  (let ((compilers (or (compilation-get-compilers lang)
                       (compilation-get-compilers "c"))))
    (when compilers
      (cons (intern-soft "|") compilers))))
;; Use: (compilation-read-compiler-rx-prefixes "c")
;; Use: (compilation-read-compiler-rx-prefixes "objective-c")
;; Use: (compilation-read-compiler-rx-prefixes "c++")
;; Use: (compilation-read-compiler-rx-prefixes "d")
;; Use: (compilation-read-compiler-rx-prefixes "java")
;; Use: (compilation-read-compiler-rx-prefixes "haskell")
;; Use: (compilation-read-compiler-rx-prefixes)

(defun compilation-read-compiler (&optional lang default default-only)
  "Read Build Compiler for language LANG.
Picks completions from `exec-path'."
  (interactive)
  (let* ((default (or default (car c-standard-build-options)))
         (exec (compilation-read-compiler-rx-prefixes lang))
         (re (eval `(rx (: bos
                           ,exec
                           (? (: "-" (* (in ".0-9")))) ;possible versioned. TODO: Use version-...
                           eos))))
         (compiler
          (let ((icicle-default-in-prompt-format-function
                 (lambda (default) (format " (%s)" (faze default 'cmd)))))
            (multi-read-file-name "Build Compiler: "
                                  exec-path 'full-duplicates
                                  re
                                  'file-executable-p
                                  t nil nil default nil t))))
    (if (member (capitalize compiler) c-standard-build-options)
        (or (compilation-default-build-compiler lang)
            "gcc")
      compiler)))
;; Use: (compilation-read-compiler)
;; Use: (compilation-read-compiler "c")
;; Use: (compilation-read-compiler "c++")
;; Use: (compilation-read-compiler "d")
;; Use: (compilation-read-compiler "haskell")

;; ---------------------------------------------------------------------------

(defun compilation-compiler-build-types (compiler &optional lang)
  "Lookup Build Types of COMPILER with language LANG."
  (when compiler
    (let ((full-compiler (executable-find compiler))
          (compiler (file-name-sans-directory compiler)))
      (when full-compiler
        (delq nil
              (cond ((or (string-prefix-p "gcc" compiler)
                         (string-prefix-p "g++" compiler))
                     (mapcar (lambda (x)
                               (let ((ver (fourth x)))
                                 (when (or (not ver)
                                           (gcc-version-at-least ver compiler))
                                   x)))
                             gcc-build-types))
                    ((or (string-prefix-p "clang" compiler)
                         (string-prefix-p "clang++" compiler))
                     (mapcar (lambda (x)
                               (let ((ver (fourth x)))
                                 (when (or (not ver)
                                           (clang-version-at-least ver compiler))
                                   x)))
                             clang-build-types))
                    ((string-prefix-p "gdc" compiler) gdc-build-types)
                    ((string-prefix-p "gdmd" compiler) dmd-build-types)
                    ((string-prefix-p "ldmd2" compiler) dmd-build-types)
                    ((string-prefix-p "dmd" compiler) dmd-build-types)
                    ((string-prefix-p "ghc" compiler) ghc-build-types)
                    ((string-prefix-p "gccgo" compiler) gccgo-build-types)
                    (t nil)))))))
;; Use: (compilation-compiler-build-types "gcc")
;; Use: (compilation-compiler-build-types "gcc-4.7")
;; Use: (compilation-compiler-build-types "gcc-4.8")
;; Use: (compilation-compiler-build-types "gcc" "c++")
;; Use: (compilation-compiler-build-types "gcc-4.7" "c++")
;; Use: (compilation-compiler-build-types "clang" "c++")
;; Use: (compilation-compiler-build-types "gdc" "d")
;; Use: (compilation-compiler-build-types "dmd" "d")
;; Use: (compilation-compiler-build-types "ldmd2" "d")
;; Use: (compilation-compiler-build-types "/usr/bin/dmd" "d")
;; Use: (compilation-compiler-build-types "/usr/bin/dmd2" "d")
;; Use: (compilation-compiler-build-types "gdmd" "d")
;; Use: (compilation-compiler-build-types "ghc")
;; Use: (compilation-compiler-build-types "gccgo")

(defun compilation-build-type-flags (&optional compiler build-type output-dir link)
  "Lookup Build Type Flags of COMPILER and BUILD-TYPE."
  (append
   (cadr (assoc build-type (compilation-compiler-build-types compiler)))
   (when link
     (caddr (assoc build-type (compilation-compiler-build-types compiler))))
   (when (and (string-match "dmd" compiler)
              dmd-documentation-flag)
     (append
      '("-D")
      (when output-dir
        `(,(concat "-Dd" output-dir))   ;directory to write documentation
        )))))
;; Use: (compilation-build-type-flags "gcc" "Debug")
;; Use: (compilation-build-type-flags "gdc" "Debug")
;; Use: (eval (compilation-build-type-flags "gdc" "Debug"))
;; Use: (compilation-build-type-flags "gcc" "Fast")
;; Use: (compilation-build-type-flags "gcc" "Release")
;; Use: (compilation-build-type-flags "clang" "Debug")
;; Use: (compilation-build-type-flags "clang" "Debug-SAFECode")
;; Use: (compilation-build-type-flags nil "Fast-Debug")
;; Use: (compilation-build-type-flags "gdc" "Debug")
;; Use: (compilation-build-type-flags "gdc" "Release")
;; Use: (compilation-build-type-flags "ghc" "Release")
;; Use: (compilation-build-type-flags "ghc" "Threaded-Release")
;; Use: (compilation-build-type-flags "gdmd" "Debug")
;; Use: (compilation-build-type-flags "dmd" "Debug")
;; Use: (compilation-build-type-flags "dmd" "Debug" "/tmp")
;; Use: (compilation-build-type-flags "gcc" "Profile")
;; Use: (compilation-build-type-flags "gcc" "GPerfTools-Profile")
;; Use: (compilation-build-type-flags "gcc" "GPerfTools-Profile" nil t)

(defun compilation-read-build-type (&optional compiler default)
  "Read Build Type for compiler COMPILER.
COMPILER can be either `gcc', `clang', `gdc', `gdmd', `ghc', `ldc', `ldmd2'."
  (let* ((default (or default
                      (when compiler
                        (cond ((and (string-match "gcc" compiler)
                                    (gcc-version-at-least "4.8" compiler)) ;TODO: Read this from variable
                               "AddressSanitized-Debug")
                              ((and (string-match "clang" compiler)
                                    (clang-version-at-least "3.1" compiler)) ;TODO: Read this from variable
                               "AddressSanitized-Debug")
                              ((string-match "dmd" compiler)
                               dmd-default-build-type)
                              ((string-match "gdc" compiler)
                               gdc-default-build-type)
                              ((string-match "ghc" compiler)
                               ghc-default-build-type)))
                      (car c-standard-build-options)))
         (type (let ((icicle-default-in-prompt-format-function
                      (lambda (default) (format " (%s)" (faze default 'type)))))
                 (completing-read "Build Type: "
                                  (compilation-compiler-build-types compiler)
                                  nil t nil 'uproj-build-type-history default))))
    (if (member (capitalize type) c-standard-build-options)
        nil
      type)))
;; Use: (compilation-read-build-type)
;; Use: (compilation-read-build-type "gcc")
;; Use: (compilation-read-build-type "gcc-4.7")
;; Use: (compilation-read-build-type "clang")
;; Use: (compilation-read-build-type "ghc")
;; Use: (compilation-read-build-type "gdc")
;; Use: (compilation-read-build-type "gdmd")
;; Use: (compilation-read-build-type "ldmd2")
;; Use: (compilation-read-build-type "dmd")

(defun compilation-read-jobs (&optional directory bfile target compiler build-type)
  "Read Job Count for target."
  (let* ((directory (or directory default-directory))
         (tag :build-jobs-history)
         (bfile (or bfile
                    (abbreviate-file-name (compilation-read-build-file directory target))))
         (fcache (fcache-rget bfile directory))
         (hist (fcache-get-tag fcache tag))
         (jobs (read-number "Job Count, where 0 means CPU-count online: "
                            uproj-default-jobs)))
    (when jobs
      (add-to-history 'uproj-build-jobs-history jobs)
      (when fcache
        (fcache-add-to-history-tag fcache tag jobs))
      jobs)))

(defun c-make-language-variables (lang)
  "Return GNU Make Variables of LANG."
  (cond ((string-equal lang "c")
         '("CC" . "CFLAGS"))
        ((string-equal lang "c++")
         '("CXX" . "CXXFLAGS"))
        ((string-equal lang "fortran")
         '("FC" . "FFLAGS"))
        ((string-equal lang "java")
         '("GCJ" . "GCJFLAGS"))))

;; ---------------------------------------------------------------------------

(defvar uproj-local-build-flag nil "Local Build Flag.")
(make-variable-buffer-local 'uproj-local-build-flag)
(defvar uproj-local-build-dir nil "Local Build Directory.")
(make-variable-buffer-local 'uproj-local-build-dir)
(defvar uproj-local-build-target nil "Local Build Target.")
(make-variable-buffer-local ' uproj-local-build-target)
(defvar uproj-local-build-compiler nil "Local Build Compiler.")
(make-variable-buffer-local ' uproj-local-build-compiler)
(defvar uproj-local-build-type nil "Local Build Type.")
(make-variable-buffer-local ' uproj-local-build-type)

(defvar uproj-last-build-dir nil "Last Build Directory.")
(add-to-list 'desktop-globals-to-save 'uproj-last-build-dir t)

(defvar uproj-last-build-file nil "Last Build File.")
(add-to-list 'desktop-globals-to-save 'uproj-last-build-file t)

(defvar uproj-last-build-target nil "Last Build Target.")
(add-to-list 'desktop-globals-to-save 'uproj-last-build-target t)

(defvar uproj-last-build-compiler nil "Last Build Compiler.")
(add-to-list 'desktop-globals-to-save 'uproj-last-build-compiler t)
(defvar uproj-last-build-type nil "Last Build Type.")
(add-to-list 'desktop-globals-to-save 'uproj-last-build-type t)
(defvar uproj-last-build-host nil "Last Build Host.")
(add-to-list 'desktop-globals-to-save 'uproj-last-build-host t)

(defvar uproj-build-dir-history nil "Build Directory History.")
(add-to-list 'desktop-globals-to-save 'uproj-build-dir-history t)
(defvar uproj-build-compiler-history nil "Build Compiler History.")
(add-to-list 'desktop-globals-to-save 'uproj-build-compiler-history t)
(defvar uproj-build-file-history nil "Build File History.")
(add-to-list 'desktop-globals-to-save 'uproj-build-file-history t)
(defvar uproj-build-target-history nil "Build Target History.")
(add-to-list 'desktop-globals-to-save 'uproj-build-target-history t)
(defvar uproj-build-jobs-history nil "Build Jobs History.")
(add-to-list 'desktop-globals-to-save 'uproj-build-jobs-history t)
(defvar uproj-build-type-history nil "Build Type History.")
(add-to-list 'desktop-globals-to-save 'uproj-build-type-history t)

(defvar uproj-default-jobs 0 "Default number of concurrent build jobs.")

;; ---------------------------------------------------------------------------

(defun compilation-read-language-standard (&optional lang compiler default)
  "Read Language Standard for language LANG supported by COMPILER."
  (let* ((default (or default (car c-standard-build-options)
                      (cond ((string= lang "c")
                             (if (string-match "gcc" compiler) gcc-c-default-std-type c-default-std-type))
                            ((string= lang "c++")
                             (if (string-match "gcc" compiler) gcc-c++-default-std-type c++-default-std-type)))))
         (type
          (let ((icicle-default-in-prompt-format-function
                 (lambda (default) (format " (%s)" default))))
            (completing-read "Language Standard: "
                             (append
                              (cond ((string= lang "c")
                                     (if (and (stringp compiler)
                                              (string-match "gcc" compiler)) gcc-c-std-types c-std-types)
                                     (if (and (stringp compiler)
                                              (string-match "clang" compiler)) clang-c-std-types c++-std-types))
                                    ((string= lang "c++")
                                     (if (and (stringp compiler)
                                              (string-match "gcc" compiler)) gcc-c++-std-types c++-std-types)
                                     (if (and (stringp compiler)
                                              (string-match "clang" compiler)) clang-c++-std-types c++-std-types))
                                    ((string= lang "d")
                                     (if (and (stringp compiler)
                                              (string-match "gdc" compiler)) gdc-std-types d-std-types))
                                    ((string= lang "haskell")
                                     haskell-std-types)
                                    (t
                                     (append c-std-types
                                             c++-std-types))) ;C and C++
                              c-standard-build-options)
                             nil t nil 'uproj-build-type-history default))))
    (if (member (capitalize type) c-standard-build-options)
        nil
      type)))
;; Use: (compilation-read-language-standard "c")
;; Use: (compilation-read-language-standard "c" "gcc")
;; Use: (compilation-read-language-standard "c++")
;; Use: (compilation-read-language-standard "c++" "gcc")
;; Use: (compilation-read-language-standard "d")
;; Use: (compilation-read-language-standard "d" nil "D-2.0")
;; Use: (compilation-read-language-standard "haskell")

(defun c-make-compile-command (&optional dir bfile target lang compiler type jobs niceness host)
  "Construct Compile Command of Build-Type TYPE using JOBS number
of jobs running with nicenessrity NICENESS."
  (let* ((dir (or dir default-directory))
         (jobs (or jobs compilation-jobs-count))
         ;;(unless type (setq type c-default-build-type))
         (niceness (or niceness compilation-niceness))
         (lang (or lang "c"))
         (compiler (or compiler (compilation-default-build-compiler lang)))
         (cmd (concat "\\nice -n " (number-to-string niceness) " "
                      (if (file-executable-p bfile)
                          bfile
                        (funcall (file-op bfile :execute) bfile))
                      (if (string-equal "dub.json"
                                        (file-name-sans-directory bfile))
                          ""
                        (concat
                         " -j " (number-to-string jobs)
                         ;;" -C " dir
                         (when type
                           (let ((cf (expand-file-name "conf.mk" dir)))
                             (if (and (file-regular-p cf)
                                      (cscan-file cf "BUILD_TYPE"))
                                 (concat " BUILD_TYPE=" (downcase type))
                               (let ((spec (assoc type (compilation-compiler-build-types compiler lang)))) ;lookup spec
                                 (when spec
                                   (let* ((make-vars (c-make-language-variables lang))
                                          (cflags (second spec))
                                          (ldflags (third spec)))
                                     (concat
                                      (when compiler
                                        (concat
                                         " CC='" compiler "'"
                                         " CXX='" compiler "'"))
                                      (when cflags
                                        (let ((cflags-str (mapconcat 'identity cflags " ")))
                                          (concat
                                           " CFLAGS='" cflags-str "'"
                                           " CXXFLAGS='" cflags-str "'"))) ;Can we reuse $CFLAGS here?
                                      (when ldflags
                                        (let ((ldflags-str (mapconcat 'identity ldflags " ")))
                                          (concat
                                           " LDFLAGS='" ldflags-str "'")))
                                      )))))))
                         " "
                         (unless (and (string-equal target "all")
                                      (string-equal (file-name-sans-directory bfile) "SConstruct")) ;empty argument on scons is same as make all
                           target))))))
    (if host
        (concat "ssh " host " \"cd " dir "; LANG=" lang " " cmd "\"")
      cmd)))
;; Use: (c-make-compile-command nil "test" nil nil "clang" "Debug-SAFECode" 12 nil "localhost")

(defun compilation-read-root-directory (&optional directory multi halt-dir use-buffer-name)
  "Read Build Root Directory of current (working) DIRECTORY."
  (interactive "DDirectory: ")
  (directory-file-name
   (abbreviate-file-name
    (let* ((directory (or directory default-directory))
           (fcache (fcache-of directory))
           (tag :build-root)
           (hist (when fcache
                   (fcache-get-tag fcache tag)))
           (dir (when hist
                  (car hist)))
           (bdir (directory-file-name
                  (let ((icicle-default-in-prompt-format-function
                         (lambda (default) "";; (format " (%s)" (faze default 'dir))
                           )))
                    (read-directory-name "Build in directory: "
                                         (or dir
                                             (car (trace-directory-upwards
                                                   (lambda (dir)
                                                     (and
                                                      (file-project-root-directory-p dir)
                                                      (or
                                                       (not use-buffer-name) ;either don't require match
                                                       buffer-file-name
                                                       (directory-makefile-target-of-buffer dir buffer-file-name))
                                                      ))
                                                   directory multi halt-dir))
                                             (car (trace-directory-upwards 'file-build-directory-p
                                                                           directory multi halt-dir)))
                                         nil t)))))
      (when bdir
        (when fcache
          (fcache-add-to-history-tag fcache tag bdir))
        bdir)))))
;; Use: (compilation-read-root-directory "~/Work/MATLAB/EMD/EMDs/src")
;; Use: (compilation-read-root-directory "~/justcxx/semnet/")
;; Use: (fcache-get-property (fcache-of "~/justcxx/semnet/") :build-root)
;; Use: (fcache-get-property (fcache-of (expand-file-name "~/Work/MATLAB/EMD/EMDs/src")) :build-root)
;; Use: (fcache-get-properties (fcache-of (expand-file-name "~/Work/MATLAB/EMD/EMDs/src")))
;; Use: (compilation-read-root-directory "~/")

(defun compilation-read-build-file (&optional directory target default)
  "Read Build File in DIRECTORY.
If TARGETS are non-nil choose from it and require match,
otherwise choose any target."
  (let* ((directory (or directory default-directory))
         (fcache (fcache-of directory))
         (tag :build-file-history)
         (kexpr 'Build-Tool-Script) ;ftypes-build-script-file-keys, '(Makefile SConstruct)
         (hist (fcache-get-tag fcache tag))
         ;; TODO: Replace or merge with: (trace-file-upwards "~/justcxx/semnet/" 'Makefile nil nil 'name-recog)
         (bfile (abbreviate-file-name
                 (let* ((files (directory-files-of-types directory kexpr 'name-recog)))
                   (when files
                     (when (member "GNUmakefile" files)
                       (setq files (delete-dups (cons "GNUmakefile" files))))
                     (if (> (length files) 1) ;if more than on makefile to choose from
                         ;;(read-file-name-of-types "Makefile: " kexpr directory nil t nil 'name-recog)
                         (let ((default (or default
                                            (car hist)
                                            (car files))))
                           (completing-read "Build File: "
                                            files
                                            nil ;; TODO: require doesn't work so use instead: `(lambda (filename) (file-exists-p (expand-file-name filename ,directory)))
                                            t nil 'hist default))
                       (car files)))))))
    (when bfile
      (add-to-history 'uproj-build-file-history bfile)
      (when fcache
        (fcache-add-to-history-tag fcache tag bfile))
      bfile
      ;; (expand-file-name bfile directory)
      )))
;; Use: (compilation-read-build-file "/etc")
;; Use: (compilation-read-build-file "~/justcxx")

;; (directory-files-of-types "~/justcxx" 'Makefile 'name-recog)

(defun compilation-read-build-target (&optional directory bfile targets default)
  "Read Build Target. If TARGETS are non-nil choose from it and
require match, otherwise choose any target."
  (let* ((directory (or directory default-directory))
         (fcache (fcache-of directory))
         (tag :build-target-history)
         (hist (fcache-get-tag fcache tag))
         (bfile (or bfile
                    (compilation-read-build-file directory targets)))
         (target (progn (unless targets
                          (setq targets (when bfile
                                          (let ((efile (expand-file-name bfile directory)))
                                            (cond ((file-match efile 'Makefile)
                                                   (makefile-targets efile))
                                                  ((file-match efile '(SConstruct SConscript))
                                                   (sconstruct-targets efile)))))))
                        (let* ((path buffer-file-name)
                               (fn (when path (file-name-sans-directory path)))
                               (base (when fn (file-name-sans-extension fn)))
                               (defaults (when base
                                           (delq nil
                                                 ;; guess default target based on current buffer file-name (sans its extensions)
                                                 (mapcar (lambda (target)
                                                           (when (string-match (regexp-quote base) target)
                                                             target))
                                                         targets))))
                               (default (or default
                                            (car defaults)
                                            (car hist)
                                            (car (member "all" targets))))
                               )
                          (let ((icicle-default-in-prompt-format-function
                                 (lambda (default) (format " (%s)" (faze default 'type)))))
                            (completing-read "Build target: " targets
                                             nil (when targets t)
                                             nil 'hist default))))))
    (when target
      (add-to-history 'uproj-build-target-history target)
      (when fcache
        (fcache-add-to-history-tag fcache tag target))
      target)))
;; Use: (compilation-read-build-target "/tmp")
;; Use: (compilation-read-build-target "~/ware/emacs")
;; Use: (compilation-read-build-target "~/justcxx" "GNUmakefile")
;; Use: (compilation-read-build-target "~/justcxx" "SConstruct")
;; Use: (compilation-read-build-target "~/Work/phobos" "Makefile")
;; Use: (compilation-read-build-target "~/justd")

(defun compilation-read-c++-library-suffix (&optional lang path)
  "Read C++ Standard Library Suffix.
Optionally searches PATH for libraries."
  (let* ((default (car c++-std-libraries)))
    (assoc
     (let ((icicle-default-in-prompt-format-function
            (lambda (default) (format " (%s)" (faze default 'lib)))))
       (completing-read "C++ Standard Library: "
                        c++-std-libraries
                        nil t nil nil default))
     c++-std-libraries)))
;; Use: (compilation-read-c++-library-suffix)

(defun compilation-read-code-generator-type (&optional compiler)
  "Read Code Generator Type Definition. COMPILER is currently only `ghc'"
  (let ((default (caar ghc-code-generators)))
    (assoc
     (let ((icicle-default-in-prompt-format-function
            (lambda (default) (format " (%s)" (faze default 'type)))))
       (completing-read "Build Type: "
                        (cond ((string-match "ghc" compiler)
                               ghc-code-generators)
                              ((string-match "gdc" compiler)
                               gdc-build-types)
                              ((string-match "dmd" compiler)
                               dmd-build-types)
                              (t
                               gcc-build-types))
                        nil t nil nil default))
     ghc-code-generators)))
;; Use: (compilation-read-code-generator-type "ghc")
;; Use: (compilation-read-code-generator-type "gdc")
;; Use: (compilation-read-code-generator-type "dmd")
;; Use: (compilation-read-code-generator-type "ldmd2")

(defun compilation-read-warn-type-flags (&optional compiler default)
  "Read Warn Type for COMPILER."
  (let* ((compiler (or compiler "gcc"))
         (types (cond ((string-match "gcc" compiler) gcc-warn-types)
                      ((string-match "clang" compiler) clang-warn-types)
                      ((string-match "ghc" compiler) ghc-warn-types)
                      ((string-match "gdc" compiler) gdc-warn-types)
                      ((string-match "dmd" compiler) dmd-warn-types)
                      (t gcc-warn-types)))
         (default (or default (caar types)))
         (heads (mapcar (lambda (type)
                          (car type))
                        types))
         (flags (cadr (assoc
                       (let ((icicle-default-in-prompt-format-function
                              (lambda (default) (format " (%s)" (faze default 'type)))))
                         (completing-read "Warn Type: " heads nil t nil nil default))
                       types))))
    (if (string-match "gcc" compiler)
        (intersection flags
                      (mapcar (lambda (a) (car a))
                              (gcc-options "Warnings" compiler))
                      :test 'string-equal)
      flags)))
;; (eval-when-compile (assert-t (listp (compilation-read-warn-type-flags "gcc"))))
;; (eval-when-compile (assert-t (listp (compilation-read-warn-type-flags "clang"))))
;; Use: (compilation-read-warn-type-flags "clang")
;; Use: (compilation-read-warn-type-flags "ghc")
;; Use: (compilation-read-warn-type-flags "gdc")
;; Use: (compilation-read-warn-type-flags "gcc")

;; ---------------------------------------------------------------------------

;; prove.el --- Compilation mode for prove
(when (require 'prove nil t)
  )

;; ToDo: Make the logic of compile() sensitive to whats in the current
;; directory or parent-directories using trace-file-upwards-r():
;; See: http://www.emacswiki.org/cgi-bin/wiki/CompileCommand
;;
;; Reuse filedb.el:
(defun compilation-find-build-tools-at (dir)
  "Determine kinds of builds that can be used at
directory DIR."
  (completing-read "Type of build: " '("make" "bjam" "scons")))
;; Use: (compilation-find-build-tools-at "~/justcxx/")

(when nil
  (require 'compile- nil t)
  (eval-after-load "compile" '(progn (require 'compile+ nil t)))
  )

(require 'compile nil t)

;; So that we can enter do input such as passwords in the
;; compilation buffer.
(when (require 'compile-input nil t)
  )

(when nil
  (when (and window-system
             (require 'compile-frame nil t))
    ))

(defun kill-compilation-dinged ()
  "Calls `kill-compilation' and calls ding if an error occurred."
  (interactive)
  (unless (ignore-errors
            (kill-compilation))
    (message "No compilation process active")
    (ding)))
(defun make-compilation-mode-safe ()
  (local-set-key "\C-c\C-k" 'kill-compilation-dinged))
(add-hook 'compilation-mode-hook 'make-compilation-mode-safe t)

(when nil
  (defalias 'make-project 'compile)       ;to make users find it easier
  (defalias 'remake-project 'recompile)   ;to make users find it easier
  (defalias 'kill-make-project 'kill-compilation-dinged) ;to make users find it easier
  )

(define-key-after menu-bar-tools-menu [recompile]
  '(menu-item "Recompile (Current)" recompile
              :help "Restart Current Compilation (Directly), view compilation messages")
  'compile)

(define-key-after menu-bar-tools-menu [kill-compilation-dinged]
  '(menu-item "Abort Compilation" kill-compilation-dinged
              :help "Abort Current Compilation (Directly)")
  'recompile)

;; ---------------------------------------------------------------------------

;; TODO: Use: http://www.gnu.org/software/emacs/manual/html_node/emacs/Directory-Variables.html#Directory-Variables
;; TODO: Cache this in fcache.
(defvar uproj-targets
  '()
  "List that Associates Build Target with Directory, Type, Extra Flags and Shell-Command.";
  )

(defvar uproj-build-fn nil "Last function that built/made project.")
(setq uproj-build-fn nil)

(defun uproj-make-build-fn (&optional dir bfile target lang compiler type jobs niceness process-language host)
  "Construct Project Target Build Function."
  `(lambda ()
     (let* ((target (if (and (string-equal target "all")
                             (string-equal (file-name-sans-directory bfile) "SConstruct"))
                        nil         ;empty argument on scons is same as make all
                      target))
            (default-directory ,(if dir
                                    (file-name-as-directory dir) ;must end with a slash
                                  default-directory)) ;at to DIR if given
            (process-environment
             (cons (concat "LANGUAGE=" (or ,process-language "en")) ;default to english compilation language
                   process-environment)))
       (compile
        (c-make-compile-command ,dir ,bfile ,target ,lang ,compiler ,type ,jobs ,niceness ,host) t))))

(defvar uproj-local-run-flag nil
  "Local flags for running build target.")
(make-variable-buffer-local 'uproj-local-run-flag)

(defvar uproj-pending-run-flag nil
  "Flags for pending run of build target.")

;; ---------------------------------------------------------------------------

(defun read-hostname (&optional prompt hosts default)
  "Read HOSTNAME string."
  (completing-read (or prompt) hosts nil nil nil nil default))

(defun compilation-read-host (directory &optional bfile target compiler build-type)
  "Read Compilation Host for building in DIRECTORY."
  (let* ((directory (or directory default-directory))
         (fcache (fcache-of directory))
         (tag :build-host)
         (hist (when fcache (fcache-get-tag fcache tag)))
         (default (if (and hist
                           (car hist))
                      (car hist)
                    "None"))
         (hosts (delete-dups (append eshell-host-names
                                     hist
                                     `(,default))))
         (host (read-hostname "Build Host: " hosts default)))
    (when (and host
               (not (member (downcase host) '("localhost"
                                              "default"
                                              "none"))))
      (when fcache
        (fcache-add-to-history-tag fcache tag host))
      (add-to-list 'eshell-host-names host)
      host)))
;; Use: (compilation-read-host "~")

(defun read-niceness (prompt)
  "Read Process Niceness Number."
  (read-number "Build Niceness (in range -20 to 19): " 0))

(defconst process-languages
  '(("English" "en")
    ("Svenska" "sv_SE.UTF-8")
    ("Swedish" "sv_SE.UTF-8")))

(defun read-locale (&optional prompt)
  "Read Process Niceness Number."
  (let* ((default "English")
         (lang (second (assoc (completing-read (or prompt
                                                   "Process Language: ")
                                               process-languages
                                               nil nil nil nil default)
                              process-languages))))
    (when (> (length lang) 0)
      lang)))
;; Use: (read-locale)

(defun uproj-read-arguments ()
  (let* ((roots (compilation-read-root-directory))
         (directory (if (listp roots) (car roots) roots))
         (bfile (compilation-read-build-file directory))
         (target (compilation-read-build-target directory bfile))
         (clean (string-equal target "clean")) ;check if we are cleaning up
         (compiler (unless clean
                     (compilation-read-compiler)))
         (build-type (unless clean
                       (compilation-read-build-type)))
         (options (unless clean
                    (when (or (null compiler)
                              (or (string-match "gcc" compiler)))
                      (read-gcc-options "Warnings" compiler))))
         (jobs (if clean 1
                 (compilation-read-jobs directory bfile target compiler build-type)
                 ))
         (niceness (read-niceness "Build Priority (in range -20 to 19): "))
         (host (compilation-read-host directory bfile target compiler build-type))
         (process-language (read-locale "Build Language: ")))
    (list
     (setq uproj-last-build-dir directory)
     (setq uproj-last-build-file (expand-file-name bfile directory))
     (setq uproj-last-build-target target)
     (progn
       ;; TODO: (uproj-set-directory-target-compiler directory target compiler)
       (setq uproj-last-build-compiler compiler))
     (progn
       ;; TODO: Replace with (uproj-set-directory-target-build-type directory target build-type)
       (setq uproj-last-build-type build-type))
     options
     jobs
     niceness
     process-language
     (setq uproj-last-build-host host)
     )))

(defun uproj-build-target (&optional dir bfile target compiler type flags jobs niceness process-language host)
  "Build in DIR the target TARGET as build-type TYPE using JOBS
number of (concurrent) build processes."
  (interactive (uproj-read-arguments))
  (when (require 'ede nil t)
    ;;  (ede-compile-target))
    )
  (setq uproj-local-build-flag t)
  (when (<= jobs 0)
    (setq jobs compilation-jobs-count))      ;deafult number of jobs
  (let* ((fn (uproj-make-build-fn dir bfile target nil compiler type jobs niceness process-language host)))
    (funcall (setq uproj-build-fn fn))  ;premember as recent compile command
    ))
;; Use: (call-interactively 'uproj-build-target)

(defun uproj-rebuild-target (&optional dir process-language)
  "Rebuild Recently Built Target in directory DIR."
  (interactive)
  (unless dir (setq dir uproj-last-build-dir))
  (if dir
      (let* ((default-directory (or dir uproj-last-build-dir)) ;at to DIR if given
             (process-environment
              (cons (concat "LANGUAGE=" (or process-language "en")) ;default to english compilation language
                    process-environment)))
        (call-interactively 'recompile))
    (call-interactively 'uproj-build-and-maybe-run-target)))

(defun uproj-build-and-maybe-run-target (&optional dir bfile target compiler type flags jobs niceness process-language host)
  "Rebuild and Run Recent Build (Project) under DIR."
  (interactive (uproj-read-arguments))
  (setq uproj-local-build-flag t
        uproj-pending-run-flag t)       ;run upon build ok
  (uproj-build-target dir bfile target compiler type flags jobs niceness process-language host))

(defun uproj-build-and-maybe-debug-target (&optional dir bfile target compiler type flags jobs niceness process-language host)
  "Rebuild and Debug Recent Build (Project) under DIR."
  (interactive (uproj-read-arguments))
  (setq uproj-local-build-flag t
        uproj-pending-run-flag 'debug)  ;run upon build ok
  (uproj-build-target dir bfile target compiler type flags jobs niceness process-language host))

(defun eproj-abort-build (&optional dir)
  "Abort current Build in directory DIR."
  (interactive)
  (let ((default-directory (or dir default-directory))) ;at to DIR if given
    (call-interactively 'kill-compilation)))

;; ---------------------------------------------------------------------------

(defun uproj-do-target (&optional filename args build-type run-flag compilation-window cwd)
  "Debug or Execute Recent Build (Project) under DIR.
Also rebuild recent project if needed."
  (interactive (list (read-file-name "Run file: ")
                     nil nil nil nil
                     (read-directory-name "Working Directory: ")))
  ;;(when (require 'ede nil t)(ede-run-target)) ;TODO: Activate
  (when (file-regular-p filename)
    (if (file-executable-p filename)
        (let ((threaded (and build-type
                             (string-match "Threaded" build-type)))
              (cwd (if (eq cwd 'ask)
                                     (read-directory-name "Working Directory: ")
                                   cwd)))
          (cond ((eq run-flag 'debug)   ;(string-match "Debug" build-type)
                 (or (file-debug-single filename args t) ;be silent if no debugger available an
                     (file-execute filename nil args nil compilation-window nil threaded))) ;try to execute it instead
                ((and build-type
                      (string-match "Release" build-type))
                 (file-execute filename nil args nil compilation-window nil threaded nil nil cwd))
                (t ;; 'ask
                 (file-dwim filename 'ask args nil nil nil nil cwd))
                ))
      (message "Target %s built is not executable" (faze filename 'file)))))
(defalias 'uproj-exec 'uproj-do-target)

(defun uproj-rerun-target-with-last-args (&optional dir)
  "Rerun last target with last arguments."
  (interactive)
  (setq uproj-pending-run-flag 'rerun-with-last-args)
  (uproj-rebuild-target dir))

(defun uproj-rerun-target-with-new-args (&optional dir)
  "Rerun last target with queried arguments."
  (interactive)
  (setq uproj-pending-run-flag 'rerun-with-new-args)
  (uproj-rebuild-target dir))

(defun uproj-redebug-target (&optional dir)
  (interactive)
  (setq uproj-pending-run-flag 'debug)
  (uproj-rebuild-target dir))

;; ---------------------------------------------------------------------------
;; Compilation Started Handlers

(defun uproj-build-started (process)
  (setq uproj-local-build-dir uproj-last-build-dir
        uproj-local-build-target uproj-last-build-target
        uproj-local-build-compiler uproj-last-build-compiler
        uproj-local-build-type uproj-last-build-type
        uproj-local-run-flag uproj-pending-run-flag
        uproj-pending-run-flag nil
        ))
(add-hook 'compilation-start-hook 'uproj-build-started)

;; ---------------------------------------------------------------------------
;; Compilation Finish Handlers

(defun uproj-build-finished-message (buffer &optional compile-status)
  (with-current-buffer buffer
    (let ((target-flag (and (stringp uproj-local-build-target)
                            (< 0 (length uproj-local-build-target)))))
      (message (concat (if target-flag
                           (concat "Target " (faze (format "%s" uproj-local-build-target) 'file))
                         "Compilation")
                       " in directory "
                       (faze (format "%s" uproj-local-build-dir) 'dir)
                       " "
                       (concat
                        (if (string= compile-status "finished\n")
                            (concat
                             (if target-flag
                                 "built"
                               "finished")
                             " "
                             (faze "successfully" 'success))
                          (concat (faze "failed" 'error) " to build"))
                        (format (concat ". Pressing ("
                                        (faze "%s" 'font-lock-keycomb-face)
                                        ") shows first message")
                                (symbol-function-keys-string
                                 (or (when (fboundp 'first-error-safe)
                                       'first-error-safe)
                                     'first-error)))))))))

(defun filep (filename)
  "Better version of `file-exists-p' returning something usable."
  (when (file-exists-p filename) filename))
(defalias 'file? 'filep)

(defun uproj-build-finished (buffer &optional compile-status)
  "Function that runs when compilation in BUFFER has finished with COMPILE-STATUS."
  (with-current-buffer buffer
    (when (memq major-mode '(compilation-mode comint-mode)) ;only for real compilations. Or use (not (memq major-mode '(grep-mode locate-mode)))
      (if (and (string= compile-status "finished\n")
               ;; This crap is needed because we pipe DMD compilation through
               ;; ddemangle which always returns 0
               (save-excursion (goto-char (point-min))
                               (not (search-forward ": Error: " nil t)))
               )
          (progn
            (if (eq uproj-local-run-flag 'rerun-with-new-args)
                (progn
                  ;; Leave compilation window open during input of run arguments
                  )

              (when uproj-local-build-flag
                (quit-window nil (get-buffer-window buffer))))

            (uproj-build-finished-message buffer compile-status)

            (when (and dmd-documentation-flag ;if DMD generated a doc file for use open it in browser
                       uproj-local-build-target)
              (let* ((doc-full (concat (file-name-sans-extension
                                        uproj-local-build-target) ".html"))
                     (doc-file (file-name-sans-directory doc-full))
                     (the-file (or (filep doc-full)
                                   (filep doc-file)
                                   (progn (message "DMD-generated documentation file %s could not be found!"
                                                   (faze doc-full 'file))
                                          nil)))
                     (frame (first (frame-list))))
                (when the-file
                  ;; (file-newer-than-file-p the-file
                  ;;                         uproj-local-build-target)
                  (when nil
                    (browse-url the-file)
                    (sleep-for 0 300)
                    (select-frame-set-input-focus frame))
                  )))

            (when (and uproj-local-run-flag
                       uproj-local-build-target)
              (uproj-do-target (expand-file-name
                                uproj-local-build-target
                                uproj-local-build-dir)
                               (case uproj-local-run-flag
                                 ('rerun-with-last-args 'skip)
                                 ('rerun-with-new-args nil)
                                 (t nil)
                                 )
                               uproj-local-build-type
                               uproj-local-run-flag
                               (get-buffer-window buffer))

              ;; close compilation window
              (when (eq uproj-local-run-flag 'rerun-with-new-args)
                ;;(quit-window nil (get-buffer-window buffer))
                )
              ))
        (display-buffer buffer)
        (uproj-build-finished-message buffer compile-status)
        (when uproj-local-run-flag
          (message "Can't run %s because its build failed"
                   (faze uproj-last-build-target 'file)))))
    (setq uproj-local-run-flag nil)     ;don't run any more
    ))
(add-hook 'compilation-finish-functions 'uproj-build-finished)

;; ---------------------------------------------------------------------------
;; Other Compilation Finish Handlers

(when nil
  ;; activate before compilation so that `compilation-exit-stash-away' can restore
  ;; window layout upon successful compilation
  (when (require 'winner nil t) (winner-mode 1))
  (defun compilation-exit-stash-away (buffer)
    "Stash away compilation BUFFER and its windows."
    (quit-window nil (get-buffer-window buffer))
    ;; (bury-buffer buffer) ;bury *compilation* buffer, so that C-x b doesn't go there
    ;; (delete-windows-on buffer)
    ;; (if (fboundp 'winner-undo) ;no previous winner conf if not already loaded
    ;;     (winner-undo)        ;if possible go back to previous window configuration
    ;;   (delete-windows-on buffer) ;delete all windows showing compilation
    ;;   )
    )
  (defun compilation-exit-handler (process-status exit-status exit-message)
    "Close compilation buffer upon successful compilation."
    (let ((buf compilation-last-buffer))
      (unless (get-buffer-window buf)     ;if not visible
        (display-buffer buf))             ;show it
      (if (and (eq process-status 'exit)
               (zerop exit-status))        ;if success
          (progn
            (message "TODO: How do we make this work nicely?")
            (when nil
              (when buf
                (run-with-timer 5 nil 'compilation-exit-stash-away buf))))
        ;;(next-error-safe)             ;if errors go to the first one
        ))
    (cons exit-message exit-status) ;return the anticipated result
    )
  (setq compilation-exit-message-function 'compilation-exit-handler)
  (defun notify-compilation-result (buffer msg)
    "Notify that the compilation is finished,
close the *compilation* buffer if the compilation is successful,
and set the focus back to Emacs frame."
    (if (string-match "^finished" msg)
        (progn
          (delete-windows-on buffer)
          (tooltip-show "Compilation Successful"))
      (tooltip-show "Compilation Failed"))
    (let ((frame (car (car (cdr (current-frame-configuration))))))
      (select-frame-set-input-focus frame)))
  (add-hook 'compilation-finish-functions 'notify-compilation-result))

;; ---------------------------------------------------------------------------

(defun recompile-and-gud-run ()
  "ReCompile and Run."
  (interactive)
  (call-interactively 'recompile)       ;TODO: Lookup executable of current debuggee and rebuild it.
  (when (and (require 'gud nil t)
             (or (require 'gdb nil t)
                 (require 'gdb-mi nil t))
             (fboundp 'gud-run))
    (gud-run t)))

;; ---------------------------------------------------------------------------

(defun first-error-safe ()
  "Nicer variant of `first-error' that dings instead of errors beyond last hit."
  (interactive)
  (let ((buffer compilation-last-buffer))
    (when (buffer-live-p buffer)
      (display-buffer buffer)
      (shrink-window-if-larger-than-buffer (get-buffer-window buffer))
      ))
  (unless (ignore-errors (first-error) t)
    (message "At first hit") ;; (sit-for 1)
    (ding)))

(defun previous-error-safe (&rest rest)
  "Nicer variant of `previous-error' that dings instead of errors beyond first hit."
  (interactive)
  (unless (ignore-errors (previous-error rest) t)
    (message "At first hit") ;; (sit-for 1)
    (ding)))

(defun next-error-safe (&rest rest)
  "Nicer variant of `next-error' that dings instead of errors beyond last hit."
  (interactive)
  (unless (ignore-errors (next-error rest) t)
    (message "At last hit") ;; (sit-for 1)
    (ding)))

(dolist (fn '(first-error
              first-error-safe
              previous-error
              previous-error-safe
              next-error
              next-error-safe))
  (repeatable-command-advice fn))

(defun hictx-error-last-buffer (&optional line)
  (let ((window (get-buffer-window next-error-last-buffer)))
    (when window
      (hictx-line window nil hictx-new-window-timeout))))
(defadvice previous-error (after previous-error-ctx-flash activate) (when (called-interactively-p 'any) (hictx-error-last-buffer))) (ad-activate 'previous-error)
(defadvice next-error (after next-error-ctx-flash activate) (when (called-interactively-p 'any) (hictx-error-last-buffer))) (ad-activate 'next-error)
(defadvice previous-error-safe (after previous-error-safe-ctx-flash activate) (when (called-interactively-p 'any) (hictx-error-last-buffer)))  (ad-activate 'previous-error-safe)
(defadvice next-error-safe (after next-error-safe-ctx-flash activate) (when (called-interactively-p 'any) (hictx-error-last-buffer))) (ad-activate 'next-error-safe)

;; ---------------------------------------------------------------------------
;; Compilation Keys

;; (global-set-key [(control meta f9)] 'remote-compile)
(global-set-key [(control shift f9)] 'gud-run)
(global-set-key [(control x) (control a) (control c)] 'gud-cont)

(global-set-key [(f6)] 'first-error-safe)
(global-set-key [(f7)] 'previous-error-safe)
(global-set-key [(f8)] 'next-error-safe)

;;; Eclipse Style bindings
(global-set-key [(control ?,)] 'previous-error-safe)
(global-set-key [(control ?.)] 'next-error-safe)

(global-set-key [(meta g) (meta p)] 'previous-error-safe)
(global-set-key [(meta g) (meta n)] 'next-error-safe)

(global-set-key [(meta g) (p)] 'previous-error-safe)
(global-set-key [(meta g) (n)] 'next-error-safe)

(global-set-key [(meta g) (meta a)] 'first-error)
(global-set-key [(meta g) (meta e)] 'last-error)

(global-set-key [(control c) (c)] 'compile)
(global-set-key [(control c) (C)] 'recompile)

(global-unset-key [(f9)])
(global-set-key [(f9)] 'uproj-build-and-maybe-run-target)
(global-set-key [(control f9)] 'uproj-rerun-target-with-new-args)
(global-set-key [(control shift f9)] 'uproj-rerun-target-with-last-args)

;; (global-set-key [(f9)] 'uproj-build-target)
;; (global-set-key [(control f9)] 'uproj-rebuild-target)
;; (global-set-key [(shift f9)] 'eproj-abort-build)

;; (global-set-key [(f11)] 'uproj-build-and-maybe-debug-target)
;; (global-set-key [(control f11)] 'uproj-redebug-target)

;; ---------------------------------------------------------------------------

;; smart-compile.el --- an interface to `compile'
(when (require 'smart-compile nil t)
  )

;; ---------------------------------------------------------------------------

;; ---------------------------------------------------------------------------
;; Shrink Compilation Window to fit Contents

;; set to a specific height or nil if we use half of buffer height
(setq compilation-window-height nil)
(setq grep-window-height nil)
;; (setq compilation-window-height 10)
;; (setq grep-window-height 20)

(defcustom pnw/compilation-window-shrink-to-fit t
  "Define to non-nil to make compilation/grep-window shrink to fit its
  contents."
  :type 'boolean :group 'pnw-options)

(defun compilation-auto-fit-window (&optional buf compile-status)
  (unless buf (setq buf compilation-last-buffer))
  (let ((win (get-buffer-window buf)))
    ;;(message "Buffer: %s" (buffer-name))
    (balance-windows win)
    (shrink-window-if-larger-than-buffer win)
    ))

(when pnw/compilation-window-shrink-to-fit
  (add-hook 'compilation-finish-functions 'compilation-auto-fit-window)
  (add-hook 'next-error-hook 'compilation-auto-fit-window)
  )

;; ---------------------------------------------------------------------------

;; compilation-recenter-end.el --- compilation-mode window recentre
(autoload 'compilation-recenter-end-enable "compilation-recenter-end")
;; (add-hook 'compilation-finish-functions 'compilation-recenter-end-enable)
;; (add-hook 'compilation-finish-functions 'compilation-recenter-end-at-finish)
;;(setq compilation-scroll-output t) ;scroll the *compilation* buffer window as output appears.

;; ---------------------------------------------------------------------------

(defvar nuke-successful-compile nil)
(defun compilation-success-p (message)
  (not (integerp (compare-strings message 0 7 "finished" 0 7))))
(defun nuke-successful-compile-window (buffer message)
  (when (and nuke-successful-compile
             (compilation-success-p message))
    (unwind-protect
        (delete-window (display-buffer buffer t))
      (setq nuke-successful-compile nil))
    (message "Compilation finished %s" (faze "successfully" 'success))))
(defun polite-recompile ()
  (interactive)
  (setq nuke-successful-compile t)
  (recompile))
(when nil
  (add-to-list 'compilation-finish-functions 'nuke-successful-compile-window)
  )

(defvar compilation-buffer-name-function-pnw-counter 0)

(defun compilation-buffer-name-function-pnw (mode)
  (concat "*"
          (downcase mode)
          "@"
          compilation-directory
          ":"
          (cond ((and (boundp 'uproj-local-build-flag) uproj-local-build-flag
                      (boundp 'uproj-last-build-target) uproj-last-build-target)
                 uproj-last-build-target)
                ((and (stringp compile-command)
                      (> (length compile-command) 0))
                 compile-command)
                (t
                 (number-to-string (incf compilation-buffer-name-function-pnw-counter))
                 ))
          "*"))

(setq-default compilation-buffer-name-function 'compilation-buffer-name-function-pnw)

;; ---------------------------------------------------------------------------

;; compile-bookmarks.el --- bookmarks for compilation commands
;; See: http://nschum.de/src/emacs/compile-bookmarks/
;; (eload nil (elsub "others") "compile-bookmarks.el" "http://nschum.de/src/emacs/compile-bookmarks/")
(when nil
  (when (require 'compile-bookmarks nil t)
    (compile-bookmarks-mode 1)
    (setq compile-bm-save-file (elsub "compile-bm"))
    (add-to-list 'auto-mode-alist '("/compile-bm$" . emacs-lisp-mode))
    )
  )

;;; compile-command-default.el --- establish a default for M-x compile
(require 'compile-command-default)

;; ---------------------------------------------------------------------------

;; (defun qtmstr-setup-compile-mode ()
;;   ;; Support C++ better
;;   (modify-syntax-entry ?< "(")
;;   (modify-syntax-entry ?> ")")
;;   (dolist (frame (find-dedicated-frames (current-buffer)))
;;     (let ((orig (frame-parameter frame 'orig-background)))
;;       (when orig
;;         (modify-frame-parameters
;;          frame (list (cons 'background-color orig)))))))

;;(add-hook 'compilation-mode-hook #'qtmstr-setup-compile-mode)

(provide 'uproj)
