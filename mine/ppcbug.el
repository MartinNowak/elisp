(require 'term)

(defvar ppcbug-commands
  '("as"	 ; One Line Assembler
    "bc"	 ; Block of Memory Compare
    "bf"	 ; Block of Memory Fill
    "bi"	 ; Block of Memory Initialize
    "bm"	 ; Block of Memory Move
    "br"	 ; Breakpoint Insert
    "nobr"	 ; Breakpoint Delete
    "bs"	 ; Block of Memory Search
    "bv"	 ; Block of Memory Verify
    "cache"	 ; Modify Cache State
    "cm"	 ; Concurrent Mode
    "nocm"	 ; No Concurrent Mode
    "cnfg"	 ; Configure Board Information Block
    "cs"	 ; Checksum
    "csar"	 ; PCI Configuration Space READ Access (NOTE 2)
    "csaw"	 ; PCI Configuration Space WRITE Access (NOTE 2)
    "dc"	 ; Data Conversion
    "dma"	 ; Move Block of Memory
    "ds"	 ; One Line Disassembler
    "du"	 ; Dump S-Records
    "echo"	 ; Echo String
    "env"	 ; Set Environment
    "fork"	 ; Fork Idle MPU at Address (NOTE 2)
    "forkwr"	 ; Fork Idle MPU with Registers (NOTE 2)
    "gd"	 ; Go Direct (Ignore Breakpoints)
    "gevboot"	 ; Global Environment Variable Boot (NOTE 1)
    "gevdel"	 ; Global Environment Variable Delete (NOTE 1)
    "gevdump"	 ; Global Environment Variable(s) Dump (NOTE 1)
    "gevedit"	 ; Global Environment Variable Edit (NOTE 1)
    "gevinit"	 ; Global Environment Variable Initialization (NOTE 1)
    "gevshow"	 ; Global Environment Variable(s) Display (NOTE 1)
    "gn"	 ; Go to Next Instruction
    "g"		 ; Go Execute User Program
    "go"	 ; Go Execute User Program
    "gt"	 ; Go to Temporary Breakpoint
    "he"	 ; Help
    "ibm"	 ; Indirect Block Move
    "idle"	 ; Idle Master MPU (NOTE 2)
    "ioc"	 ; I/O Control for Disk
    "ioi"	 ; I/O Inquiry
    "iop"	 ; I/O Physical (Direct Disk Access)
    "iot"	 ; I/O Teach for Configuring Disk Controller
    "ird"	 ; Idle MPU Register Display (NOTE 2)
    "irm"	 ; Idle MPU Register Modify (NOTE 2)
    "irs"	 ; Idle MPU Register Set (NOTE 2)
    "lo"	 ; Load S-Records from Host
    "ma"	 ; Macro Define/Display
    "noma"	 ; Macro Delete
    "mae"	 ; Macro Edit
    "mal"	 ; Enable Macro Listing
    "nomal"	 ; Disable Macro Listing
    "mar"	 ; Load Macros
    "maw"	 ; Save Macros
    "md"	 ; Memory Display
    "mds"	 ; Memory Display
    "menu"	 ; System Menu
    "m"		 ; Memory Modify
    "mm"	 ; Memory Modify
    "mmd"	 ; Memory Map Diagnostic
    "mmgr"	 ; Memory Manager
    "ms"	 ; Memory Set
    "mw"	 ; Memory Write
    "nab"	 ; Automatic Network Boot
    "nap"	 ; Nap MPU (NOTE 2)
    "nbh"	 ; Network Boot Operating System, Halt
    "nbo"	 ; Network Boot Operating System
    "nioc"	 ; Network I/O Control
    "niop"	 ; Network I/O Physical
    "niot"	 ; Network I/O Teach (Configuration)
    "nping"	 ; Network Ping
    "of"	 ; Offset Registers Display/Modify
    "pa"	 ; Printer Attach
    "nopa"	 ; Printer Detach
    "pboot"	 ; Bootstrap Operating System
    "pf"	 ; Port Format
    "nopf"	 ; Port Detach
    "pflash"	 ; Program FLASH Memory
    "ps"	 ; Put RTC into Power Save Mode
    "rb"	 ; ROMboot Enable
    "norb"	 ; ROMboot Disable
    "rd"	 ; Register Display
    "remote"	 ; Remote
    "reset"	 ; Cold/Warm Reset
    "rl"	 ; Read Loop
    "rm"	 ; Register Modify
    "rs"	 ; Register Set
    "run"	 ; MPU Execution/Status (NOTE 2)
    "sd"	 ; Switch Directories
    "set"	 ; Set Time and Date
    "srom"	 ; SROM Examine/Modify (NOTE 2)
    "sym"	 ; Symbol Table Attach
    "nosym"	 ; Symbol Table Detach
    "syms"	 ; Symbol Table Display/Search
    "t"		 ; Trace
    "ta"	 ; Terminal Attach
    "time"	 ; Display Time and Date
    "tm"	 ; Transparent Mode
    "tt"	 ; Trace to Temporary Breakpoint
    "ve"	 ; Verify S-Records Against Memory
    "ver"	 ; Revision/Version Display
    "wl"	 ; Write Loop
    )
  "PPCBug Builtin Commands.")

(defvar ppcbug-error-strings
  '("^Error Status"
    "^Invalid Command"
    "^Boot Logic Error"
    "^Autoboot Failed"
    "^\\*\\*\\* Missing Argument \\*\\*\\*"
    )
  "PPCBug Error Strings.")

(defvar ppcbug-prompt
  "PPC6-Bug>"
  "PPCBug Prompt String")

(defvar ppcbug-font-lock-keywords
  (list
   ;; Fontify all builtin keywords.
   (cons (concat "\\<\\("
		 (regexp-opt ppcbug-commands)
		 "\\)\\>")
	 'font-lock-function-name-face)
   (cons (concat "\\("
		 (regexp-opt ppcbug-error-strings)
		 "\\)")
	 '(1 compilation-error-face))
   (cons (concat "\\("
		 "^" ppcbug-prompt
		 "\\)")
	 'minibuffer-prompt)
   (cons (concat "\\("
		 "[ 0-9a-zA-Z/()-]+"
		 "\\)" "[=:]")
	 '(1 font-lock-variable-name-face))
   )
  "Additional PPCBug expressions to highlight.")

(provide 'ppcbug)
