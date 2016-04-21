FROM datadog/docker-dd-agent-build-deb-x64

# Install our own dd-agent-omnibus as "netsil-omnibus"
RUN git clone https://github.com/netsil/dd-agent-omnibus.git netsil-omnibus

RUN cd netsil-omnibus && \
    /bin/bash -l -c "bundle install --binstubs"

VOLUME ["/netsil-omnibus/pkg"]

ENTRYPOINT /bin/bash -l /netsil-omnibus/omnibus_build.sh
