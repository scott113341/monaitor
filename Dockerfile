FROM timbru31/ruby-node:3.4-24

WORKDIR /usr/src/app

COPY package.json package-lock.json ./
RUN npm install
RUN npx playwright install --with-deps --only-shell chromium

COPY Gemfile Gemfile.lock .ruby-version ./
RUN bundle install

COPY ./ ./

# The empty CMD allows for arguments to be added
ENTRYPOINT ["ruby", "main.rb"]
CMD []
