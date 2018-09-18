# Copyright © 2018 Booz Allen Hamilton. All Rights Reserved.
# This software package is licensed under the Booz Allen Public License. The license can be found in the License file or at http://boozallen.github.io/licenses/bapl

FROM selenium/node-chrome:3.12.0
USER root
COPY entry_point.sh /opt/bin/
RUN  chgrp -R 0 /opt/bin \
  && chmod -R g=u /opt/bin \ 
  && chmod +x /opt/bin/* \
  && chgrp -R 0 /opt/selenium \
  && chmod -R g=u /opt/selenium \
  && chmod +x /opt/selenium/*
USER seluser
ENTRYPOINT [ "/opt/bin/entry_point.sh" ]

