#!/usr/bin/env zsh
0=${(%):-%x}
autoload -Uz ${0:A:h}/functions/testinit && testinit
ztap_header "${0:t:r}"

# setup
ANTIDOTE_HOME=$BASEDIR/tests/fakezdotdir/antidote_home
source $BASEDIR/antidote.zsh

() {
  # test with no arg
  local actual expected exitcode
  expected="antidote: error: required argument 'bundle' not provided, try --help"
  actual=$(antidote purge 2>&1)
  exitcode=$?
  @test "'antidote purge' with no args fails" $exitcode -ne 0
  @test "'antidote purge' with no args fail message" "$expected" = "$actual"
}

() {
  # test with repo arg but repo does not exist
  local actual expected exitcode bundle bundledir
  bundle="bar/foo"
  bundledir="$ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-bar-SLASH-foo"
  expected="antidote: error: $bundle does not exist at the expected location: $bundledir"

  actual=$(antidote purge $bundle 2>&1)
  exitcode=$?
  @test "'antidote purge' missing bundle exit code" $exitcode -ne 0
  @test "'antidote purge' missing bundle fail message" "$expected" = "$actual"
}

() {
  local actual expected exitcode bundle bundledir

  # test actually purging a bundle
  # for this we just need to set up a fake ANTIDOTE_HOME so we can purge it
  ANTIDOTE_HOME=$BASEDIR/.tmp/tests/purge
  [[ -d $ANTIDOTE_HOME ]] && rm -rf $ANTIDOTE_HOME

  bundle="foo/bar"
  bundledir="$ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar"

  # we don't need to test this, but it makes for a nice test output story
  @test "purge setup: bundle directory does not exist" ! -d "$bundledir"
  mkdir -p $bundledir
  @test "purge setup: bundle directory exists" -d "$bundledir"

  # purge!
  actual=$(antidote purge $bundle 2>&1)
  exitcode=$?
  @test "'antidote purge $bundle' existing bundle succeeds" $exitcode -eq 0
  @test "'antidote purge $bundle' existing bundle correctly removed" ! -d "$bundledir"
}

# antidote purge --all
() {
  local actual expected exitcode bundle bundledir

  # to test purging all bundles, we've got to make a full fake zdotdir
  setup_fakezdotdir purge2
  pluginsfile=${ZDOTDIR:-~}/.zsh_plugins.txt

  zstyle ':antidote:purge:all' answer 'n'
  actual=$(antidote purge --all 2>&1)
  exitcode=$?
  @test "'antidote purge --all' with answer=no fails" $exitcode -ne 0


  bakfiles=($ZDOTDIR/.zsh_plugins.*.bak(N))
  @test "No backup zsh_plugins file exists" $#bakfiles -eq 0

  zstyle ':antidote:purge:all' answer 'y'
  actual=$(antidote purge --all 2>&1)
  exitcode=$?
  @test "'antidote purge --all' with answer=yes succeeds" $exitcode -eq 0
  bakfiles=($ZDOTDIR/.zsh_plugins.*.bak(N))
  @test "A backup zsh_plugins file exists" $#bakfiles -eq 1

  # clean up
  zstyle -d ':antidote:purge:all' answer
}

ztap_footer
