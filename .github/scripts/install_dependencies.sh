#! /bin/bash

CPANM=cpanm
if [[ $GITHUB_WORKFLOW == *"windows"* ]] ; then
    # NOTE: MSYS2 shell does not recognize the new PATH, see
    #      https://github.com/msys2/setup-msys2/issues/106
    #   so we will use an absolute path on MSYS2
    CPANM="$PERL_LOCAL_LIB_ROOT"/bin/cpanm
fi
# NOTE: Alien Build currently has test failures, see
# - https://github.com/PerlAlien/Alien-Build/pull/247
# - https://github.com/PerlAlien/Alien-Build/pull/246
# - https://github.com/PerlAlien/Alien-Build/pull/245
# So we will install without testing until the above pull requests has been merged.
$CPANM -n Alien::Build
$CPANM -v --installdeps .
