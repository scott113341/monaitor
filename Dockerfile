FROM ruby:3.4.8

WORKDIR /usr/src/app

COPY .node-version ./
RUN printf 'Package: nodejs\nPin: origin deb.nodesource.com\nPin-Priority: 1001' > /etc/apt/preferences.d/nodesource \
  && mkdir -p /etc/apt/keyrings \
  && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
  && NODE_VERSION=$(cat .node-version) \
  && NODE_MAJOR=$(cat .node-version | cut -d '.' -f 1) \
  && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list \
  && apt-get update -qq \
  && apt-get install -qq --no-install-recommends nodejs=$NODE_VERSION-* \
  && apt-get upgrade -qq \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

COPY package.json package-lock.json ./
RUN npm install
RUN npx playwright install --with-deps --only-shell chromium

COPY Gemfile Gemfile.lock .ruby-version ./
RUN bundle install

COPY ./ ./

# The empty CMD allows for arguments to be added
ENTRYPOINT ["bundle", "exec", "ruby", "main.rb"]
CMD []
