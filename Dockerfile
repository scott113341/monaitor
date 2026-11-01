FROM ruby:4.0.9 AS build

ENV BUNDLE_WITHOUT=test

WORKDIR /usr/src/app

COPY Gemfile Gemfile.lock .ruby-version ./
RUN bundle install \
  && rm -rf /usr/local/bundle/cache \
  && find /usr/local/bundle/gems -type f \( -name '*.o' -o -name '*.c' -o -name '*.h' \) -delete

RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /nodesource.gpg


FROM ruby:4.0.9-slim

ENV BUNDLE_WITHOUT=test

WORKDIR /usr/src/app

COPY --from=build /nodesource.gpg /etc/apt/keyrings/nodesource.gpg
COPY .node-version ./
RUN printf 'Package: nodejs\nPin: origin deb.nodesource.com\nPin-Priority: 1001' > /etc/apt/preferences.d/nodesource \
  && NODE_VERSION=$(cat .node-version) \
  && NODE_MAJOR=$(cat .node-version | cut -d '.' -f 1) \
  && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list \
  && apt-get update -qq \
  && apt-get install -qq --no-install-recommends libpq5 nodejs=$NODE_VERSION-* \
  && apt-get upgrade -qq \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

COPY package.json package-lock.json ./
RUN npm ci --omit=dev \
  && npx playwright install --with-deps --only-shell chromium \
  && npm cache clean --force \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

COPY --from=build /usr/local/bundle /usr/local/bundle

COPY ./ ./

# The empty CMD allows for arguments to be added
ENTRYPOINT ["bundle", "exec", "ruby", "main.rb"]
CMD []
