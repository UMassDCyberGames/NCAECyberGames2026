FROM alpine:latest

LABEL maintainer="yourname@example.com"

# Install Samba and its dependencies
RUN apk --no-cache add samba samba-common-tools bash

# Create a directory to be shared
RUN mkdir -p /mnt/files && chmod ugo+w,+t /mnt/files

RUN touch /mnt/files/addict_with_a_pen.data && \
touch /mnt/files/air_catcher.data && \
touch /mnt/files/anathema.data  && \
touch /mnt/files/at_the_risk_of_feeling_dumb.data  && \
touch /mnt/files/backslide.data  && \
touch /mnt/files/.bandito.data  && \
touch /mnt/files/be_concerned.data  && \
touch /mnt/files/before_you_start_your_day.data  && \
touch /mnt/files/bounce_man.data  && \
touch /mnt/files/doubt.data  && \
touch /mnt/files/car_radio.data  && \
touch /mnt/files/center_mass.data  && \
touch /mnt/files/chlorine.data  && \
touch /mnt/files/choker.data  && \
touch /mnt/files/christmas_saves_the_year.data  && \
touch /mnt/files/city_walls.data  && \
touch /mnt/files/the_contract.data  && \
touch /mnt/files/cottonwood.data


RUN chown -R root:root /mnt/files/*
RUN chmod 444 /mnt/files/*

# Copy a basic smb.conf file into the container
COPY smb.conf /etc/samba/smb.conf

# Expose the necessary ports for SMB/CIFS
EXPOSE 137/udp 138/udp 139 445

# Command to run Samba when the container starts
CMD ["smbd", "--no-process-group", "--foreground"]