# Copyright (c) 2020 Red Hat, Inc.
# This program and the accompanying materials are made
# available under the terms of the Eclipse Public License 2.0
# which is available at https://www.eclipse.org/legal/epl-2.0/
#
# SPDX-License-Identifier: EPL-2.0
#
# Contributors:
#   Red Hat, Inc. - initial API and implementation

FROM alpine:3.11.6

ENV HOME=/home/theia

RUN mkdir /projects ${HOME} && \
    # Change permissions to let any arbitrary user
    for f in "${HOME}" "/etc/passwd" "/projects"; do \
      echo "Changing permissions on ${f}" && chgrp -R 0 ${f} && \
      chmod -R g+rwX ${f}; \
    done

# odo and oc versions have to match the ones defined in https://github.com/redhat-developer/vscode-openshift-tools/blob/master/src/tools.json
ENV GLIBC_VERSION=2.31-r0 \
    ODO_VERSION=v1.2.1 \
    OC_VERSION=4.3.3 \
    KUBECTL_VERSION=v1.18.3

# plugin executes the commands relying on Bash
RUN apk add --update --no-cache bash && \
    # install glibc compatibility layer package for Alpine Linux
    # see https://github.com/openshift/origin/issues/18942 for the details
    wget -O glibc-${GLIBC_VERSION}.apk https://github.com/andyshinn/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-${GLIBC_VERSION}.apk && \
    apk --update --allow-untrusted add glibc-${GLIBC_VERSION}.apk && \
    rm -f glibc-${GLIBC_VERSION}.apk && \
    # install oc
    wget -O- https://mirror.openshift.com/pub/openshift-v4/clients/ocp/4.3.3/openshift-client-linux-${OC_VERSION}.tar.gz | tar xvz oc -C /usr/local/bin && \
    #Set the arch
    export ARCH="$(uname -m)" && if [[ ${ARCH} == "x86_64" ]]; then export ARCH="amd64"; fi && \
    # install odo
    wget -O /usr/local/bin/odo https://mirror.openshift.com/pub/openshift-v4/clients/odo/${ODO_VERSION}/odo-linux-${ARCH} && \
    chmod +x /usr/local/bin/odo && \
    # install kubectl
    wget -O /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl && \
    chmod +x /usr/local/bin/kubectl

ADD etc/entrypoint.sh /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
CMD ${PLUGIN_REMOTE_ENDPOINT_EXECUTABLE}
