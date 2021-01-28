#! /bin/bash

# NOTE: We need to setup local::lib before we run cpan, see
#   https://stackoverflow.com/q/65945115/2173773
#TOP=$GITHUB_WORKSPACE
TOP=$HOME
if [[ $GITHUB_WORKFLOW == *"windows"* ]] ; then
    # The github action runner environment variables like GITHUB_WORKSPACE
    #  are using windows paths like D:\d\a\, whereas MSYS2 variables like
    #  HOME use unix paths like /d/a/, so if TOP is a windows path we need to
    #  convert it to a unix path:
    TOP=$(cygpath "$TOP")
fi
PERL_LOCAL_LIB_ROOT="$TOP/perl5"

>>"$GITHUB_ENV" echo "PERL_LOCAL_LIB_ROOT=$PERL_LOCAL_LIB_ROOT"
>>"$GITHUB_ENV" echo "PERL5LIB=$PERL_LOCAL_LIB_ROOT/lib/perl5"
>>"$GITHUB_ENV" echo "PERL_MB_OPT=--install_base \"$PERL_LOCAL_LIB_ROOT/\""
>>"$GITHUB_ENV" echo "PERL_MM_OPT=INSTALL_BASE=$PERL_LOCAL_LIB_ROOT"
>>"$GITHUB_ENV" echo "PATH=$PERL_LOCAL_LIB_ROOT/bin:$PATH"
