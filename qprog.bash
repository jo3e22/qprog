#! /bin/bash
## Script to generate object-oriented Fortran programa
# -l option to work as far as possible with files in directory
# Example where
# set program, program object and one other object
# contents of qprog.txt used to generate namelist
# contents of bigobj.txt merely define data structure
# runs in local directory, ie. not TEST
sw=global
if [ $# -gt 0 ] ;  then
  test=$1
  if [ ${test#-} != $test ] ; then
    if [ ${1#-} = l ] ;  then sw=local ; fi
    shift
  fi
fi
QPROG=xpc
# shorthand for QPROG
Q=xp
STR="transport_coefficients"
BIGOBJ=clcoef
# shorthand for BIGOBJ
BO=cc
BSTR="classical_coefficients"
## set variables from list key=arg
for i in $*; do
key=${i%%=*}
arg=${i##*=}
case "$key" in
  QPROG) QPROG=${arg//+/ };;
  Q) Q=${arg//+/ };;
  STR) STR=${arg//+/ };;
  BIGOBJ) BIGOBJ=${arg//+/ };;
  BO) BO=${arg//+/ };;
  BSTR) BSTR=${arg//+/ };;
  ?) echo "unknown key";exit;;
esac
done
# remove underlines from strings
STR=${STR//_/ }
BSTR=${BSTR//_/ }
#Logging
echo "program name = " $QPROG
echo "program id = " $Q
echo "program description = " $STR
echo "object name = " $BIGOBJ
echo "object id = " $BO
echo "object description = " $BSTR
# other initialisation
SMPROG=$(pwd)
SMDEV=$(pwd)/develop
if [ ! -d $SMDEV ] ; then
  echo "Local directory \$SMDEV=$SMDEV does not exist - trying to use smardda/develop"
  if [[ -z "$HS" ]] ; then
    if [[ -n "$SMITER_DIR" ]] ; then HS=$SMITER_DIR; else HS=$HOME/smardda/smiter; fi
  fi 
  # SMPROG=${SMITER_DIR%/*}/qprog
   SMDEV=${SMITER_DIR%/*}/develop
fi
#
rm -f spaced.txt work.txt setvar.txt namvarinit.txt namvars.txt
rm -f namvardecl.txt include.txt copvar.txt copvar0.txt
if [ ! -e $QPROG.txt ] ; then cp $SMPROG/qprog.txt $QPROG.txt;fi
if [ ! -e $BIGOBJ.txt ] ; then cp $SMPROG/bigobj.txt $BIGOBJ.txt;fi
## process variables
#ensure program var file spaced OK
sed -e "s/ *= */ = /" -e "s/ *:: */ :: /" -e 's/ *!< */ !< /' -e "s/ *dimension/ dimension/" \
-e "s/^ */  /" < $QPROG.txt  > spaced.txt
sed \
-e "s/ /_/g" < spaced.txt | sed -e "s/^__/  /" -e "s/_::_/ :: /" \
| sed -e 's/_!<_/ !< /' | sed -e "s/_=_/ = /" | sed -e "s/,_dimension/, dimension/" > work.txt
awk '{
  if ($2 ~ /dimension/) {
    # For dimension arrays: real(kr8),dimension(3) :: varname !< comment
    print "    " $1 " " $2 " " $3 " " $4 " " $7 " " $8
  } else {
    # For regular vars: real(kr8) :: varname = value !< comment  
    print "    " $1 " " $2 " " $3 " " $6 " " $7
  }
}' < work.txt > include.txt
awk '{
  if ($2 ~ /dimension/) {
    print "  " $1 " " $2 " " $3 " " $8 " " $7 " " $8
  } else {
    print "  " $1 " " $2 " " $7 " " $6 " " $7
  }
}' < work.txt > namvardecl.txt
vim namvardecl.txt -S namvardecl.ed
awk '{
  if ($2 ~ /dimension/) {
    print " & " $8 " , " "&"
  } else {
    print " & " $7 " , " "&"
  }
}' < work.txt > namvars.txt
awk '{
  if ($2 ~ /dimension/) {
    print "  " $8 " " $5 " " $6
  } else {
    print "  " $7 " " $4 " " $5
  }
}' < work.txt > namvarinit.txt
awk '{
  if ($2 ~ /dimension/) {
    print "  selfn%" $4 " " $5 " " $8
  } else {
    print "  selfn%" $3 " " $4 " " $7
  }
}' < work.txt > setvar.txt
awk '{
  if ($2 ~ /dimension/) {
    print "  $BOnumerics%" $4 " " $5 " $Qnumerics%" $4
  } else {
    print "  $BOnumerics%" $3 " " $4 " $Qnumerics%" $3
  }
}' < work.txt > copvar0.txt
#echo "  \$BOnumerics%formula = \$Qnumerics%formula" >> copvar0.txt
echo "  \$BOnumerics%f = \$Qnumerics%f" >> copvar0.txt
sed -e "s/\$BO/$BO/" -e "s/\$Q/$Q/" < copvar0.txt > copvar.txt
#space object var file spaced OK
sed -e "s/ *= */ = /" -e "s/ *:: */ :: /" -e 's/ *!< */ !< /' -e "s/ *dimension/ dimension/" \
-e "s/^ */     /" < $BIGOBJ.txt  > spaced.txt
## process f90 files
# qprog main file (note qprog is a bigobj)
sed \
-e "s/qprog/$QPROG/g" \
-e "13a\  use "$BIGOBJ"_h" \
-e "13a\  use "$BIGOBJ"_m" \
-e "s/qcontrol_read(file,param,bigobj%n,/qcontrol_read(file,param,bigobj%n,bigobj%"$BIGOBJ"%n,/" \
-e "s/qcontrol_/"$Q"control_/g" \
-e "s/qfiles/"$Q"files/g" \
-e "s/qplots/"$Q"plots/g" \
-e "s/qparams/"$Q"params/g" \
-e "s/bigobj/$QPROG/g" \
-e "s/one-line program description/$STR/" \
< $SMPROG/qprog.f90 > $QPROG.f90
# control include file
sed \
-e "s/qprog/$QPROG/g" \
-e "s/qcontrol_/"$Q"control_/g" \
-e "s/qfiles/"$Q"files/g" \
-e "s/qplots/"$Q"plots/g" \
-e "s/qparams/"$Q"params/g" \
-e "s/bigobj/$QPROG/g" \
< $SMPROG/qcontrol_h.f90 > "$Q"control_h.f90
# control source file
sed \
-e "s/qprog/$QPROG/g" \
-e "8a\  use "$BIGOBJ"_h" \
-e "8a\  use "$BIGOBJ"_m" \
-e "76a\  type("$BO"numerics_t), intent(out) :: "$BO"numerics !< controls for $BSTR" \
-e "195a\  call "$QPROG"_readcon("$Q"numerics,nin)" \
-e "195a\  " \
-e "195a\  call "$BIGOBJ"_readcon("$BO"numerics,nin)" \
-e "195r copvar.txt" \
-e "s/qcontrol_read(file,param,bonumerics,/qcontrol_read(file,param,bonumerics,"$BO"numerics,/" \
-e "s/qcontrol_/"$Q"control_/g" \
-e "s/qfiles/"$Q"files/g" \
-e "s/qplots/"$Q"plots/g" \
-e "s/bonumerics/"$Q"numerics/g" \
-e "s/qparams/"$Q"params/g" \
-e "s/bigobj/$QPROG/g" \
< $SMPROG/qcontrol_m.f90 > "$Q"control_m.f90
# program source file
sed \
-e "191a\  call "$BIGOBJ"_solve(self%$BIGOBJ)" \
-e "s/bonumerics/"$Q"numerics/g" \
-e "s/noutbo/nout$Q/g" \
-e "s/ninbo/nin$Q/g" \
-e "s/bigobj/$QPROG/g" \
-e "7a\  use "$BIGOBJ"_h" \
-e "7a\  use "$BIGOBJ"_m" \
-e "179r setvar.txt" \
-e "108r namvarinit.txt" \
-e "96r namvars.txt" \
-e "88r namvardecl.txt" \
< $SMPROG/bigobj_m.f90 > "$QPROG"_m.f90
#program include file
sed \
-e "s/bonumerics/"$Q"numerics/g" \
-e "s/bigobj/$QPROG/g" \
-e "21a\     type("$BIGOBJ"_t) :: $BIGOBJ !< $BSTR" \
-e"/^! $Note/d" \
-e "9r include.txt" \
-e "3a\  use "$BIGOBJ"_h" \
< $SMPROG/bigobj_h.f90 > "$QPROG"_h.f90
# object source file, special edits first to tie in with QPROG_m
sed \
-e "s/bonumerics/"$BO"numerics/g" \
-e "s/noutbo/nout$BO/g" \
-e "s/ninbo/nin$BO/g" \
-e "s/bigobj/$BIGOBJ/g" \
< $SMPROG/bigobj_m.f90 > "$BIGOBJ"_m.f90
# object include file
sed \
-e "s/bonumerics/"$BO"numerics/g" \
-e "s/bigobj/$BIGOBJ/g" \
-e "20r spaced.txt" \
-e "9r include.txt" \
-e "/^! $Note/d" \
< $SMPROG/bigobj_h.f90 > "$BIGOBJ"_h.f90
##process ctl file and set links
# input file
sed \
-e "s/qprog/$QPROG/g" \
-e "s/bigobj/$BIGOBJ/g" \
< $SMPROG/qprog.ctl > "$QPROG"_case0.ctl
#
[ ! -f const_kind_m.f90 ] && ln -sf $SMALIB_DIR/f95/const_kind_m.f90
[ ! -f const_numphys_h.f90 ] && ln -sf $SMALIB_DIR/f95/const_numphys_h.f90
[ ! -f date_time_m.f90 ] && ln -sf $SMALIB_DIR/f95/date_time_m.f90
[ ! -f log_m.f90 ] && ln -sf $SMALIB_DIR/f95/log_m.f90
[ ! -f log_h.f90 ] && ln -sf $SMALIB_DIR/f95/log_h.f90
[ ! -f clock_m.f90 ] && ln -sf $SMALIB_DIR/f95/clock_m.f90
[ ! -f gfile_m.f90 ] && ln -sf $SMALIB_DIR/f95/gfile_m.f90
[ ! -f misc_m.f90 ] && ln -sf $SMALIB_DIR/f95/misc_m.f90
[ ! -f vfile_m.f90 ] && ln -sf $SMALIB_DIR/f95/vfile_m.f90
[ ! -f smitermpi_h.f90 ] && ln -sf $SMALIB_DIR/f95/smitermpi_h.f90
[ ! -d LIB ] && ln -s  $SMALIB_DIR/fortd LIB
# produce doxyfile
sed -e "s/QPROG/$QPROG/" < doxyfile.qprog > doxyfile
# configure Fortran compiler
if [ ! -f config/config.inc ] ; then
  (cd config; ln -sf config_gfortran_dbg.inc config.inc); echo "gfortran compilation with debug option"
fi
# produce Makefile
if [ $sw == local ] ; then
  pushd LIB ;make ; popd
  $SMDEV/makemakecod.bash -l $QPROG
  sed -i -e "s/LIB\/lib/LIB\/libsmarddabit/" Makefile.1
else
  (cd ..;ln -sf $SMITER_DIR/config)
  $SMDEV/makemakecod.bash  $QPROG
fi
#finalise Makefile and run program
rm -f Makefile.$QPROG
cp Makefile.1  Makefile.$QPROG
make -f Makefile.$QPROG
./$QPROG "$QPROG"_case0.ctl
# configure Fortran compiler
# make list of new files
echo $QPROG.f90 "$Q"control_h.f90 "$Q"control_m.f90 "$QPROG"_m.f90 "$QPROG"_h.f90 "$BIGOBJ"_m.f90 "$BIGOBJ"_h.f90 "$QPROG"_case0.ctl doxyfile Makefile.$QPROG "$QPROG"_case0.log "$QPROG"_case0_"$QPROG".out newfiles.txt > newfiles.txt
