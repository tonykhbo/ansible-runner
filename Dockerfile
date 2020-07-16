FROM centos:8

ADD https://github.com/krallin/tini/releases/download/v0.18.0/tini /bin/tini
ADD utils/entrypoint.sh /bin/entrypoint
ADD demo/project /runner/project
ADD demo/env /runner/env
ADD demo/inventory /runner/inventory

# Install Ansible and Runner
ADD https://releases.ansible.com/ansible-runner/ansible-runner.el8.repo /etc/yum.repos.d/ansible-runner.repo
RUN dnf install -y epel-release && \
    dnf install -y ansible-runner python3-pip sudo rsync openssh-clients sshpass glibc-langpack-en && \
    alternatives --set python /usr/bin/python3 && \
    pip3 install ansible==2.7.10 pysphere && \
    chmod +x /bin/tini /bin/entrypoint && \
    rm -rf /var/cache/dnf

RUN curl -s -o /tmp/oc.tar.gz https://mirror.openshift.com/pub/openshift-v4/clients/oc/4.3/linux/oc.tar.gz && \
    tar -C /usr/local/bin -zxf /tmp/oc.tar.gz oc && \
    ln -s /usr/local/bin/oc /usr/local/bin/kubectl && \
    rm /tmp/oc.tar.gz

# In OpenShift, container will run as a random uid number and gid 0. Make sure things
# are writeable by the root group.
RUN mkdir -p /runner/inventory /runner/project /runner/artifacts /runner/.ansible/tmp && \
	chmod -R g+w /runner && chgrp -R root /runner && \
	chmod g+w /etc/passwd

VOLUME /runner/inventory
VOLUME /runner/project
VOLUME /runner/artifacts

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8
ENV RUNNER_BASE_COMMAND=ansible-playbook
ENV HOME=/runner

WORKDIR /runner

ENTRYPOINT ["entrypoint"]
CMD ["ansible-runner", "run", "/runner"]
