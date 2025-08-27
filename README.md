**!!out of date and being updated, beware of inaccuracies in README!!**
---
<br>


# jprog - J's Program Generator
This is a Fortran 95 program generator, which can be used to set up a new
program with a skeleton module and a main program, together with a set of
input files defining the variables to be used in the program and the module.
It is designed to be used with the SMARDDA-LIB library, but can also be
used independently.

Example Fortran 95, .doc and rubric files corresponding to CCFE-R(15)34
- [scientific-publications.ukaea.uk](https://scientific-publications.ukaea.uk/wp-content/uploads/CCFE-R-1534.pdf)
- [backup at dx.doi.org](http://dx.doi.org/10.13140/RG.2.2.27018.41922)
---

## qprog.bash - Program generator script ##
The script **qprog.bash** will set up a conforming program and try to run it, it does not
need **SMARDDA-LIB** installation if the optional -l (for locally complete) appears as first argument.
The program name, its abbreviation (typically one or two letters) and description are defined using
the keys; \
*QPROG*, *Q*, and *STR*

The name of a skeleton module to be tested, its abbreviation and description are defined using the keys; \
*BIGOBJ*, *BO*, and *BSTR*, as indicated:

```bash
./qprog.bash -l \
QPROG=xpc Q=xp STR="transport_coefficients" \
BIGOBJ=clcoef BO=cc BSTR="classical_coefficients"
```

**Notes:**
1. The above are the default key values and so may be omitted.
2. The use of underscores in the descriptions instead of spaces between words.
3. The contents of qprog.txt are used to define the INSTRUCTIONS for producing the 
different module objects, of which BIGOBJ will become the first.
4. The example is that of a code xpc to calculate transport coefficients
according to different physical models of a plasma, of which the so-called classical
or Braginskii coeefficients will be the first, as object clcoef.
5. Each new code should be developed in a physically distinct repo - do not develop
more than one code in a 'qprog' repo, and do not try to push files back to the original repo.

### File input ###
Files input (note that the program-specific file will be used in preference to the generic one) \
**qprog.txt**/**xpc.txt** contains the input variables that might be used by a range of different objects/modules and the default values for these inputs. These variables form part of the top level control **QPROG_t** for the program. A human readable variable for use in a namelist will be generated using the first 3 words of the description of each variable. \
In the example, `a=...` to `lambda=...` will be copied to **QPROG.txt** (**xpc.txt**) and finish in **QPROG_h.f90** **bigobj.txt**/**clcoef.txt** contains the variables defining one object which will normally be defined using the instructions resulting from the input variables in **qprog.txt**, using additional object level controls (and of course code to be written by the user). \
In the example, `tau_e...` and `c_tau_e...` will be copied to **BIGOBJ.txt** (**clcoef.txt**) and finish in **BIGOBJ_h.f90.**

### File output
Files output and principal input functions as part of new **QPROG** (**xpc**) code
**QPROG.f90** main program, calls `QPROG_readcon` (`xpc_readcon`) in module **QPROG_m.f90** \
**QPROG_h.f90** parameters describing (at least) how to construct first object **BIGOBJ** as
 **Qnumerics_t** (**xpnumerics_t**) which is to be combined with other object data structures
 such as **BIGOBJ_t** into type **QPROG_t** \
**QPROG_m.f90** input from QPROGparameters (xpcparameters) in `QPROG_readcon`, with namelist variables as
 constructed from **qprog.txt**/**xpc.txt**, copied to  **Qnumerics_t**, *will generally need editing by hand*. \
**QPROG_case0.ctl** input file for **QPROG** containing complete list of namelists \
**Qcontrol_h.f90** data structure of generic top level controls for **QPROG** abbreviated to **Q** \
**Qcontrol_m.f90** object of generic top level controls for **QPROG**  abbreviated to **Q**, calls `BIGOBJ_readcon`
 via `Qcontrol_read`. \
**BIGOBJ_h.f90** data structure of controls for BIGOBJ in type **BOnumerics_t** combined into type **BIGOBJ_t**,
 may need editing by hand for more complex applications. \
**BIGOBJ_m.f90** reads in object level controls, *will generally need editing by hand*.
**makefile.QPROG** makefile to compile and link **QPROG** (**xpc**)

### Editing the code
In one example, edits to **QPROG_m.f90** are
1) `QPROG_dia` to call object diagnostics control routine `BIGOBJ_dia`, 
2) `QPROG_write` to list key input parameters to *.out* file
3) `QPROG_writeg` to call gnuplot output control routine `BIGOBJ_writeg`,
and edits to `BIGOBJ_m.f90`
4) add to `BIGOBJ_solve` to do new work, 
5) add to `BIGOBJ_dia` for new output to *.log* file
6) add to `BIGOBJ_writeg` to output to *.gnu* file

Outputs from execution of **QPROG**
- *QPROG_case0.log* log data such as date and time of run, cpu measured by internal clocks
- *QPROG_case0_QPROG.out* indicative output, precisely object level controls for **BIGOBJ**

---

## Subdirectories for QPROG executable production
- *./config* contains files to set compiler options, default gfortran compilation with debug option
- *./develop* for developer use, files and script to produce makefile
- *./LIB* fixed format style Fortran subroutine library

## Subdirectory
- *./srcdoc* Documentation may be accessed from *./srcdoc/html/index.html*, after executing
`doxygen doxyfshellile`
- *./doc* produce latest version of CCFE-R(15)34 from f90 files, see local README
- *./TEST* outputs to compare, plus specialist example .ctl and .dat files setting a *.dat* file as input
- *./backups* contains timestamped backup copies of overwritten files in the case of *qprog.sh* being run multiple times

## Scratch files output
- *setvar.txt* copy to internal variables from namelist variables
- *namvarinit.txt* set default values for namelist variables
- *namvars.txt* namelist variables as list, one per line
- *namvardecl.txt* declare type of namelist variables
- *include.txt* declare type of internal variables
- *spaced.txt* scratch formatted version of *qprog.txt* and *bigobj.txt* inputs
- *copvar.txt* copies (relevant) Qnumerics variables to *BOnumerics*
- *copvar0.txt* copies (relevant) Qnumerics variables to *BOnumerics*

--- 

# Updating auto-generated QPROG code
At present, there is limited scope for updating, indeed repeated use of qprog.bash should be avoided as likely to overwrite user-written code. The most likely need for new input variables can be addressed by use of the variables provided as defaults, viz. 
- `general_real_parameters`
- `number_of_real_parameters`
- `general_integer_parameters`
- `number_of_integer_parameters`

which map as follows into Qnumerics namelist variables;
- `selfn%nrpams=number_of_real_parameters`
- `selfn%nipams=number_of_integer_parameters`
- `selfn%rpar=general_real_parameters(:number_of_real_parameters)`
- `selfn%npar=general_integer_parameters(:number_of_integer_parameters)`

and will come into play when setting the namelist variable `xpc_formula='additional'`

This use is complicated by the fact that the same four "PAMS" variable names (short or long forms) together with the `bigobj_formula` variable necessarily appear in two places, as there are two big objects produced by **qprog**.bash, namely **xpc** and **clcoef**. \
It helps anyway to explain the structure for controlling input which is generic:

The split adopted in *xpc.f90* is first, to initialise the control structure (*xpcontrol_h*, methods in *xpcontrol_m*.f90), which of course now consists of an aggregate of control structures, one for each object
(referred to as a sub-object) forming *xpc_h*. Each control structure, typically *qnumerics_h* some q, is initialised as one or more namelists in a single input file, when `xpcontrol_read` calls `structure_readcon`, making use of the optional unit number argument. \
(Program nucode also has a routine xpcontrol_fix which might be used e.g. to enforce consistency on the various control structures.)

In the present example, 
1) xpc is described by a namelist xpcparameters which is used to set object xpc%n of type xpnumerics containing the PAMS variables among others.
2) clcoef is described by a namelist clcoefparameters which is used to set object xpc%clcoef%n of type ccnumerics containing the PAMS variables among others (since object clcoef is a sub-object of xpc).
*xpcontrol_m*  initialises by default 3 namelists designed to define global control variables file, **param** and **plot** for **xpc**, respectively **progfiles**, **miscparameters** and **plotselections**. (The miscellaneous parameters are a character string, an integer, a real and a logical.)

Thereafter, `xpcontrol_read` calls 
1. `xpc_readcon` to read in type **xpnumerics**, checks the validity of the inputs and assign to `xpc%n`
2. `clcoef_readcon` to read in type **ccnumerics**, checks the validity of the inputs and assign to `xpc%clcoef%n`

A special feature of the relatively simple qprog represented by **xpc** is that all the variables in the sub-object of type **ccnumerics** are set by copying their counterparts in **xpnumerics** (effectively `xpc%clcoef%n=xpc%n`), EXCEPT for the PAMS variables including `bigobj_formula`.

### backup_manager.sh
This is a new feature intended to recover mistakes made while rerunning *qprog.sh* (which is unadvisable).

When qprog.sh is run it will overwrite previously generated files.  With this new feature it will now create a backup of the file in *./backups/* with the format `%yy%mm%dd-%hh%mm%ss_<filename.f90>.bak`

```bash
user@pc:~/repositories/jprog$ ./backup_manager.sh -h

Usage: ./backup_manager.sh [OPTIONS] <current_file> [backup_file]
   or: ./backup_manager.sh [OPTIONS] <filename_pattern>

Options:
  -s, --suffix SUFFIX          Suffix for current file search (default: none)
  -b, --backup-suffix SUFFIX   Suffix for backup file search (default: .bak)
  -d, --backup-dir DIR         Directory to search for backups (default: backups)
  -h, --help                   Show this help message

Examples:
  ./backup_manager.sh testob_h.f90                           # Use exact file + search for *.bak
  ./backup_manager.sh testob                                 # Search for *testob* + *testob*.bak
  ./backup_manager.sh -s .f90 testob                         # Search for *testob*.f90 + *testob*.bak
  ./backup_manager.sh -b .backup testob                      # Search for *testob* + *testob*.backup
  ./backup_manager.sh -s .f90 -b .backup testob              # Search for *testob*.f90 + *testob*.backup
  ./backup_manager.sh -d old_backups testob                  # Search in old_backups/ directory
  ./backup_manager.sh testob_h.f90 specific_backup.bak       # Compare specific files
```

---

# Extended Workflow
Using software from the *smardda/develop* repo, it is possible to begin with variables defined as LaTeX symbols
(`script codvar.bash` below) and to set up a GUI interface to producing *qprog.ctl* input in dialog (*todia.bash*).
The file *../develop/codvar_test.txt* shows the expected format for *codvar.bash* input.
The extended workflow, with the additional commands labelled #EXTRA at end of line, follows:

```bash
git clone git@github.com:smardda/qprog.git
git clone git@github.com:smardda/develop.git #EXTRA
cd qprog
#User generates bigobj.txt or bigobj_tex.txt, bigobjtot.txt
../develop/codvar.bash bigobj_tex.txt; mv bigobj_tex.txt.cod bigobj.txt #EXTRA 
./qprog.bash -l 
mv qprog_case0.ctl qprog.ctl
../develop/todia.bash qcontrol_m.f90 qprog_m.f90 bigobj_m.f90 #EXTRA (<=5 namelists per .f90 file)
#User edits qprog_m.f90 
#User edits bigobj_m.f90 ...etc.
make -f Makefile.qprog
./qprog.dia  #EXTRA
./qprog qprog.ctl 
```