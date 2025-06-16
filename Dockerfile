FROM ruby:3.4.4

WORKDIR /usr/src/app

COPY Gemfile Gemfile.lock ./
RUN bundle install
COPY ./ ./

# The empty CMD allows for arguments to be added
ENTRYPOINT ["ruby", "main.rb"]
CMD []
