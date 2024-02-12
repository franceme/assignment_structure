FROM openjdk:11.0.7-jdk

RUN apt-get update \
  && apt update \
  && yes|apt-get install zip wget unzip curl p7zip \
  && apt-get install -y python3-pip \
  && python3 -m pip install --upgrade pip setuptools wheel \
  && apt-get update \
  && curl https://sh.rustup.rs -sSf | sh -s -- -y \
  && export PATH=~/.cargo/bin:$PATH \
  && ~/.cargo/bin/rustup update \
  && ~/.cargo/bin/cargo install --color=always --force evcxr_repl cargo-single \
  && cd /opt \
  && wget --output-document=android-sdk.zip --quiet https://dl.google.com/android/repository/android-22_r02.zip \
  && unzip android-sdk.zip \
  && rm -f android-sdk.zip \
  && mv android-5.1.1 android \
  && chown -R 777 android

# add requirements.txt, written this way to gracefully ignore a missing file
COPY . $HOME
RUN ([ -f requirements.txt ] \
    && pip3 install --no-cache-dir -r requirements.txt) \
        || pip3 install --no-cache-dir jupyter jupyterlab

USER root


# Download the kernel release
#RUN curl -L https://github.com/SpencerPark/IJava/releases/download/v1.3.0/ijava-1.3.0.zip > ijava-kernel.zip && unzip ijava-kernel.zip -d ijava-kernel && cd ijava-kernel && python3 install.py --sys-prefix
#RUN git clone https://github.com/franceme/IJava.git && cd IJava/ && chmod 777 gradlew && ./gradlew installKernel

# Set up the user environment
ENV NB_USER runner
ENV NB_UID 1000
ENV HOME /home/$NB_USER

RUN adduser --disabled-password \
    --gecos "Default user" \
    --uid $NB_UID \
    $NB_USER \
  && mv core /opt \
  && chmod 777 -R /opt

COPY . $HOME
RUN chown -R $NB_UID $HOME

USER $NB_USER

# Installing SDK Man
RUN curl -s "https://get.sdkman.io" | bash \
  && curl -s "https://raw.githubusercontent.com/franceme/staticpy/master/sdk.sh" >> /tmp/sdk.sh \
  && chmod 777 /tmp/sdk.sh \
  && /tmp/sdk.sh all \
  && cd /tmp/ \
  && git clone https://github.com/franceme/IJava.git \
  && cd IJava/ \
  && chmod 777 gradlew \
  && ./gradlew installKernel \
  && yes|rm -r $HOME/core

USER root

RUN mkdir -p /home/runner/.sdkman/candidates/android/22_r02 \
  && mv /opt/android /home/runner/.sdkman/candidates/android/22_r02/platforms \
  && ln -s /home/runner/.sdkman/candidates/android/22_r02/platforms /home/runner/.sdkman/candidates/android/current \
  && chmod 777 -R /home/runner/.sdkman

USER $NB_USER

RUN bash -c "echo \"jupyter lab --ip=0.0.0.0 --NotebookApp.token='' --NotebookApp.password=''\">>/home/runner/.bash_aliases"

# Launch the notebook server
WORKDIR $HOME
CMD ["jupyter", "lab", "--ip", "0.0.0.0", "--NotebookApp.token=''", "--NotebookApp.password=''"]
