SET PROJECT_DIR=dd-agent-omnibus
SET PROJECT_NAME=datadog-agent
IF NOT DEFINED LOG_LEVEL (SET LOG_LEVEL="info")
IF NOT DEFINED OMNIBUS_BRANCH (SET OMNIBUS_BRANCH="etienne/windows")
IF NOT DEFINED OMNIBUS_SOFTWARE_BRANCH (SET OMNIBUS_SOFTWARE_BRANCH="etienne/windows")

REM Clean up omnibus artifacts in pkg dir as well as what we installed

cd %PROJECT_DIR%
REM Allow to use a different dd-agent-omnibus branch
git fetch --all
git checkout %OMNIBUS_BRANCH%
git reset --hard origin/%OMNIBUS_BRANCH%

REM Take care of passing necessary information to sign the MSI over there

REM Same dirty git cache trick as on Unix to always rebuild gohai and datadog-agent
bash -c "git --git-dir=C:/omnibus-ruby/cache/git_cache/datadog-agent tag -d `git --git-dir=C:/omnibus-ruby/cache/git_cache/datadog-agent tag -l | grep datadog-gohai`"
bash -c "git --git-dir=C:/omnibus-ruby/cache/git_cache/datadog-agent tag -d `git --git-dir=C:/omnibus-ruby/cache/git_cache/datadog-agent tag -l | grep datadog-agent`"

REM Ok kids, let grandpa tell you a story... there's this guy named Bill, who thought
REM it would be relevant that, when you call a script, let's call him B, from another
REM (batch) script (that guy's name's A)... well if B calls exit to... exit... it
REM will also stop the execution from A. Since bundle is a batch script... that's what
REM happened :( Wrapping the call in CALL prevents this behaviour... theoretically at
REM least :)

CALL bundle install --binstubs
CALL bundle update

echo Our environment is all set, let's start building things !

ruby bin\omnibus build -l=%LOG_LEVEL% %PROJECT_NAME%

echo Build complete, have fun with your freshly baked .msi file...
echo ... oh, and don't spend to much time on Windows ;-)

exit /B 0
