# Install the base requirements for the app.
# This stage is to support development.
FROM centos:7.8.2003 AS base
LABEL rpmbuilder_version="0.1"

# Adjust timeZone
RUN cp -f /usr/share/zoneinfo/America/Los_Angeles /etc/localtime

# Install requirements
COPY rpm_requirements.txt /tmp
# Loop through our rpm dependencies and call yum on each one
#   Yum has a bug where it returns an error 1 if packages are already installed.
#   Thus we ignore the error code, for better or for worse, by using "|| true"
RUN for pkg in $(grep -e '^\w' /tmp/rpm_requirements.txt | sed -e 's/\r//g') ; do /bin/yum -y install ${pkg} || /bin/true ; rpm -q ${pkg}; done

RUN useradd -ms /bin/bash build --home /home/build

# Copy code to container
COPY . /home/build

# The following command expects WSROOT to be set in the environment
CMD su - build -c "/home/build/rpmbuilder/bin/rpmcreate.sh -ws ${WSROOT}"

# Resulting rpm located in workspace which, for now, is mounted

# CMD [ "/bin/bash", "-c", "/bin/sleep 5000" ]
