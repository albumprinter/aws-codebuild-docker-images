FROM albelli/aws-codebuild-docker-images:java-openjdk-11

RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
      && echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list \
      && apt-get update -qqy \
      && apt-get -qqy install google-chrome-stable \
      && rm /etc/apt/sources.list.d/google-chrome.list \
      && rm -rf /var/lib/apt/lists/* /var/cache/apt/* \
      && sed -i 's/"$HERE\/chrome"/"$HERE\/chrome" --no-sandbox/g' /opt/google/chrome/google-chrome

RUN CHROME_VERSION=`google-chrome --version | awk -F '[ .]' '{print $3"."$4"."$5}'` \
      && CHROME_DRIVER_VERSION=`wget -qO- chromedriver.storage.googleapis.com/LATEST_RELEASE_$CHROME_VERSION` \
      && wget --no-verbose -O /tmp/chromedriver_linux64.zip https://chromedriver.storage.googleapis.com/$CHROME_DRIVER_VERSION/chromedriver_linux64.zip \
      && rm -rf /opt/chromedriver \
      && unzip /tmp/chromedriver_linux64.zip -d /opt \
      && rm /tmp/chromedriver_linux64.zip \
      && mv /opt/chromedriver /opt/chromedriver-$CHROME_DRIVER_VERSION \
      && chmod 755 /opt/chromedriver-$CHROME_DRIVER_VERSION \
      && ln -fs /opt/chromedriver-$CHROME_DRIVER_VERSION /usr/bin/chromedriver