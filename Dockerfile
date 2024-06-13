FROM archlinux:latest
LABEL authors="domped"

WORKDIR /app

COPY . .

RUN pacman-key --init && \
    pacman-key --populate archlinux
RUN pacman -Syu --noconfirm
RUN pacman -Syu cmake make gcc git --noconfirm
RUN pacman -Syu python python-pip --noconfirm
RUN pacman -Syu gnustep-base gcc-objc openexr gsl lcms2 libtiff --noconfirm


RUN cmake .
RUN make -j 32
RUN make install

#CMD ["/bin/bash"]
ENTRYPOINT ["/bin/bash" ]